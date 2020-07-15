//
//  OguryAdsMoPubEventOptin.m
//  MoPub
//
//  Created by Hikmet Mert Kahraman on 04/05/2020.
//  Copyright © 2020 MoPub. All rights reserved.
//

#import "OguryAdsMoPubEventOptin.h"
#import "MPLogging.h"
#import "MPConstants.h"

#import "OguryAdsAdapterConfiguration.h"
#import <OguryAds/OguryAds.h>

@interface OguryAdsMoPubEventOptin() <OguryAdsOptinVideoDelegate>

@property (nonatomic,strong) OguryAdsOptinVideo * oguryAdsRewardedVideo;
@property (nonatomic, copy) NSString * oguryAdUnitId;
@property (nonatomic, copy) NSString * oguryAssetId;

@end

@implementation OguryAdsMoPubEventOptin

#pragma mark - MPRewardedVideoCustomEvent Subclass Methods

- (NSString *) getAdNetworkId {
    return _oguryAdUnitId;
}

#pragma mark - MPFullscreenAdAdapter Override

- (BOOL)isRewardExpected {
    return YES;
}

- (BOOL)hasAdAvailable {
    return (self.oguryAdsRewardedVideo && self.oguryAdsRewardedVideo.isLoaded);
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

- (void)initializeSdkWithParameters:(NSDictionary *)parameters {
    // Do not wait for the callback since this method may be run on app
    // launch on the main thread.
    [self initializeSdkWithParameters:parameters callback:^(NSError *error){
        if (error) {
            MPLogEvent([MPLogEvent error:error message:@"Ogury SDK initialization failed."]);
        } else {
            MPLogInfo(@"Ogury SDK initialization complete");
        }
    }];
}

- (void)initializeSdkWithParameters:(NSDictionary *)parameters callback:(void(^)(NSError *error))completionCallback {
    NSString * const oguryAssetId  = parameters[kOguryAssetIdKey];
    NSString * const oguryAdUnitId = parameters[kOguryAdUnitIdKey];
    
    NSError * oguryAssetIdError = [OguryAdsAdapterConfiguration validateParameter:oguryAssetId withName:kOguryAssetIdKey forOperation: @"rewarded video ad request"];
    if (oguryAssetIdError) {
        if (completionCallback) {
            completionCallback(oguryAssetIdError);
        }
        return;
    }
    
    NSError * oguryAdUnitIdError = [OguryAdsAdapterConfiguration validateParameter:oguryAdUnitId withName:kOguryAdUnitIdKey forOperation: @"rewarded video ad request"];
    if (oguryAdUnitIdError) {
        if (completionCallback) {
            completionCallback(oguryAdUnitIdError);
        }
    }
    self.oguryAdUnitId = oguryAdUnitId;
    
    if (![OguryAdsAdapterConfiguration isOgurySDKInitialized]) {
        [[OguryAds shared] setupWithAssetKey:oguryAssetId andCompletionHandler:^(NSError *oguryAdsInitializationError) {
            if (oguryAdsInitializationError) {
                if (completionCallback) {
                    completionCallback(oguryAdsInitializationError);
                }
            } else {
                [OguryAdsAdapterConfiguration setIsOgurySDKInitialized:true];
                if (completionCallback) {
                    completionCallback(nil);
                }
            }
        }];
    } else {
        if (completionCallback) {
            completionCallback(nil);
        }
    }
}

- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSMutableDictionary *oguryParameters = [NSMutableDictionary dictionaryWithDictionary:info];
    [self initializeSdkWithParameters:oguryParameters callback:^(NSError *error) {
        if (error) {
            MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class)
                                                      error:error], [self getAdNetworkId]);
            [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
            return;
        }
        [self requestOguryRewardedVideo];
    }];
}

- (void)requestOguryRewardedVideo {
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class)
                                       dspCreativeId:nil
                                             dspName:nil], [self getAdNetworkId]);
    self.oguryAdsRewardedVideo = [[OguryAdsOptinVideo alloc]initWithAdUnitID:[self getAdNetworkId]];
    self.oguryAdsRewardedVideo.optInVideoDelegate = self;
    [self.oguryAdsRewardedVideo load];
}

- (void)presentAdFromViewController:(UIViewController *)viewController {
    if ([self hasAdAvailable]) {
        MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)],
                     [self getAdNetworkId]);
        [self.delegate fullscreenAdAdapterAdWillAppear:self];
        [self.oguryAdsRewardedVideo showInViewController:viewController];
    } else {
        NSError *error = [NSError errorWithDomain:MoPubRewardedVideoAdsSDKDomain code:MPRewardedVideoAdErrorNoAdsAvailable userInfo:nil];
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class)
                                                  error:error], [self getAdNetworkId]);
        [self.delegate fullscreenAdAdapter:self didFailToShowAdWithError:error];
    }
}

- (void)handleCustomEventInvalidated{
    // Do nothing
}

#pragma mark - Ogury Rewarded Video Delegate Methods

- (void)oguryAdsOptinVideoAdAvailable {
    MPLogInfo(@"Ogury Ad Server responded with an Rewarded Video ad");
}

- (void)oguryAdsOptinVideoAdLoaded {
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterDidLoadAd:self];
}

- (void)oguryAdsOptinVideoAdDisplayed {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidAppear:self];
    [self.delegate fullscreenAdAdapterDidTrackImpression:self];

}

- (void)oguryAdsOptinVideoAdClosed {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdWillDisappear:self];
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidDisappear:self];
}

- (void)oguryAdsOptinVideoAdNotAvailable {
    [self oguryAdsRewardedVideoAdFailure:MOPUBErrorNoInventory];
}

- (void)oguryAdsOptinVideoAdNotLoaded {
    [self oguryAdsRewardedVideoAdFailure:MOPUBErrorNoInventory];
}

- (void)oguryAdsOptinVideoAdError:(OguryAdsErrorType)errorType {
    if (errorType == OguryAdsErrorAdExpired) {
        MPLogInfo(@"Ogury rewarded video has expired");
        [self.delegate fullscreenAdAdapterDidExpire:self];
    } else {
        MOPUBErrorCode mopubErrorCode = [OguryAdsAdapterConfiguration getMoPubErrorCodeFromOguryAdsError:errorType];
        [self oguryAdsRewardedVideoAdFailure:mopubErrorCode];
    }
}

- (void)oguryAdsRewardedVideoAdFailure:(MOPUBErrorCode)code {
    NSError * error = [NSError errorWithCode:code];
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:(NSError*)error],
                 [self getAdNetworkId]);
    self.oguryAdsRewardedVideo = nil;
    [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
}

- (void)oguryAdsOptinVideoAdRewarded:(OGARewardItem *)item {
    if (item) {
        MPReward *reward = [[MPReward alloc] initWithCurrencyType:item.rewardName amount:@([item.rewardValue floatValue])];
        [self.delegate fullscreenAdAdapter:self willRewardUser:reward];
        MPLogInfo(@"Ogury reward action completed with rewards: %@", [reward description]);

    } else {
        MPLogInfo(@"Ogury reward action failed, rewards object is empty");
    }
}

@end

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

@interface OguryAdsMoPubEventOptin()<OguryAdsOptinVideoDelegate>

@property (nonatomic,strong) OguryAdsOptinVideo * oguryAdsRewardedVideo;
@property (nonatomic, copy) NSString * oguryAdUnitId;
@property (nonatomic, copy) NSString * oguryAssetId;

@end

@implementation OguryAdsMoPubEventOptin

#pragma mark - MPRewardedVideoCustomEvent Subclass Methods

- (NSString *) getAdNetworkId {
    return _oguryAdUnitId;
}

- (void)requestRewardedVideoWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString * const oguryAssetId  = info[kOguryAssetIdKey];
    NSString * const oguryAdUnitId = info[kOguryAdUnitIdKey];
    
    NSError * oguryAssetIdError = [OguryAdsAdapterConfiguration validateParameter:oguryAssetId withName:kOguryAssetIdKey forOperation: @"rewarded video ad request"];
    if (oguryAssetIdError) {
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:oguryAssetIdError];
        return;
    }

    NSError * oguryAdUnitIdError = [OguryAdsAdapterConfiguration validateParameter:oguryAdUnitId withName:kOguryAdUnitIdKey forOperation: @"rewarded video ad request"];
    if (oguryAdUnitIdError) {
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:oguryAdUnitIdError];
        return;
    }
    self.oguryAdUnitId = oguryAdUnitId;

    if (![OguryAdsAdapterConfiguration isOgurySDKInitialized]) {
        [[OguryAds shared] setupWithAssetKey:oguryAssetId andCompletionHandler:^(NSError *oguryAdsInitializationError) {
            if (oguryAdsInitializationError) {
                [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:oguryAdsInitializationError];
            } else {
                [OguryAdsAdapterConfiguration setIsOgurySDKInitialized:true];
                [self requestOguryRewardedVideo];
            }
        }];
    } else {
        [self requestOguryRewardedVideo];
    }
}

- (void)requestOguryRewardedVideo {
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class)
                                       dspCreativeId:nil
                                             dspName:nil], [self getAdNetworkId]);
    self.oguryAdsRewardedVideo = [[OguryAdsOptinVideo alloc]initWithAdUnitID:[self getAdNetworkId]];
    self.oguryAdsRewardedVideo.optInVideoDelegate = self;
    [self.oguryAdsRewardedVideo load];
}

-(BOOL)hasAdAvailable {
    return (self.oguryAdsRewardedVideo && self.oguryAdsRewardedVideo.isLoaded);
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController {
    if ([self hasAdAvailable]) {
        MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)],
                     [self getAdNetworkId]);
        [self.delegate rewardedVideoWillAppearForCustomEvent:self];
        [self.oguryAdsRewardedVideo showInViewController:viewController];
    } else {
        NSError *error = [NSError errorWithDomain:MoPubRewardedVideoAdsSDKDomain code:MPRewardedVideoAdErrorNoAdsAvailable userInfo:nil];
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class)
                                                  error:error], [self getAdNetworkId]);
        [self.delegate rewardedVideoDidFailToPlayForCustomEvent:self error:error];
    }
}

- (BOOL)enableAutomaticImpressionAndClickTracking{
    return NO;
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
    [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
}

- (void)oguryAdsOptinVideoAdDisplayed {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate rewardedVideoDidAppearForCustomEvent:self];
    [self.delegate trackImpression];
}

- (void)oguryAdsOptinVideoAdClosed {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
}

- (void)oguryAdsOptinVideoAdNotAvailable {
    [self oguryAdsRewardedVideoAdFailure:MOPUBErrorNoInventory];
}

- (void)oguryAdsOptinVideoAdNotLoaded {
    [self oguryAdsRewardedVideoAdFailure:MOPUBErrorNoInventory];
}

- (void)oguryAdsOptinVideoAdError:(OguryAdsErrorType)errorType {
    if (errorType == OguryAdsErrorAdExpired) {
        MPLogInfo(@"Ogury Interstitial has expired");
        [self.delegate rewardedVideoDidExpireForCustomEvent:self];
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
    [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
}

- (void)oguryAdsOptinVideoAdRewarded:(OGARewardItem *)item {
    if (item) {
        MPRewardedVideoReward *reward = [[MPRewardedVideoReward alloc]
                                         initWithCurrencyType:item.rewardName
                                         amount:@([item.rewardValue floatValue])];
        MPLogInfo(@"Ogury reward action completed with rewards: %@", [reward description]);
        [self.delegate rewardedVideoShouldRewardUserForCustomEvent:self reward:reward];
    } else {
        MPLogInfo(@"Ogury reward action failed, rewards object is empty");
    }
}

@end

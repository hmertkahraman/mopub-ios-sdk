//
//  OguryAdsMoPubEventInterstitial.m
//  MoPub
//
//  Created by Hikmet Mert Kahraman on 04/05/2020.
//  Copyright © 2020 MoPub. All rights reserved.
//

#import "OguryAdsMoPubEventInterstitial.h"
#if __has_include("MoPub.h")
    #import "MPLogging.h"
    #import "MPConstants.h"
#endif

#import "OguryAdsAdapterConfiguration.h"

#import <OguryAds/OguryAds.h>

@interface OguryAdsMoPubEventInterstitial () <OguryAdsInterstitialDelegate>

@property (nonatomic,strong) OguryAdsInterstitial * oguryInterstitial;
@property (nonatomic, copy) NSString * oguryAdUnitId;
@property (nonatomic, copy) NSString * oguryAssetId;

@end

@implementation OguryAdsMoPubEventInterstitial

#pragma mark - MPInterstitialCustomEvent Methods

- (NSString *) getAdNetworkId {
    return _oguryAdUnitId;
}

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString * const oguryAssetId  = info[kOguryAssetIdKey];
    NSString * const oguryAdUnitId = info[kOguryAdUnitIdKey];
    
    NSError * oguryAssetIdError = [OguryAdsAdapterConfiguration validateParameter:oguryAssetId withName:kOguryAssetIdKey forOperation: @"interstitial ad request"];
    if (oguryAssetIdError) {
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:oguryAssetIdError];
        return;
    }

    NSError * oguryAdUnitIdError = [OguryAdsAdapterConfiguration validateParameter:oguryAdUnitId withName:kOguryAdUnitIdKey forOperation: @"interstitial ad request"];
    if (oguryAdUnitIdError) {
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:oguryAdUnitIdError];
        return;
    }
    self.oguryAdUnitId = oguryAdUnitId;
    
    if (![OguryAdsAdapterConfiguration isOgurySDKInitialized]) {
        [[OguryAds shared] setupWithAssetKey:oguryAssetId andCompletionHandler:^(NSError *oguryAdsInitializationError) {
            if (oguryAdsInitializationError) {
                [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:oguryAdsInitializationError];
            } else {
                [OguryAdsAdapterConfiguration setIsOgurySDKInitialized:true];
                [self requestOguryInterstitial];
            }
        }];
    } else {
        [self requestOguryInterstitial];
    }
}

- (void)requestOguryInterstitial {
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class)
                                       dspCreativeId:nil
                                             dspName:nil], [self getAdNetworkId]);
    self.oguryInterstitial = [[OguryAdsInterstitial alloc]initWithAdUnitID:[self getAdNetworkId]];
    self.oguryInterstitial.interstitialDelegate = self;
    [self.oguryInterstitial load];
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController {
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);

    
    if (self.oguryInterstitial && self.oguryInterstitial.isLoaded) {
        [self.oguryInterstitial showInViewController:rootViewController];
    } else {
        NSError *adNotAvailableError = [OguryAdsAdapterConfiguration createErrorWith:@"Failed to show Ogury Interstitial"
                                                                           andReason:@"Ad is not available"
                                                                       andSuggestion:@""];
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:adNotAvailableError],
                     [self getAdNetworkId]);
        
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:adNotAvailableError];
    }
}

// Override this method to return NO to perform impression and click tracking manually.
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO;
}

#pragma mark - Ogury Ads Interstitial Delegate Methods

- (void)oguryAdsInterstitialAdAvailable {
    MPLogInfo(@"Ogury Ad Server responded with an Interstitial ad");
}

- (void)oguryAdsInterstitialAdLoaded {
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate interstitialCustomEvent:self didLoadAd:nil];
}

- (void)oguryAdsInterstitialAdDisplayed {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate interstitialCustomEventDidAppear:self];
    [self.delegate trackImpression];
}

- (void)oguryAdsInterstitialAdClosed {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate interstitialCustomEventDidDisappear:self];
}

- (void)oguryAdsInterstitialAdNotAvailable {
    [self oguryAdsInterstitialAdFailure:MOPUBErrorNoInventory];
}

- (void)oguryAdsInterstitialAdNotLoaded {
    [self oguryAdsInterstitialAdFailure:MOPUBErrorNoInventory];
}

- (void)oguryAdsInterstitialAdError:(OguryAdsErrorType)errorType {
    if (errorType == OguryAdsErrorAdExpired) {
        MPLogInfo(@"Ogury Interstitial has expired");
        [self.delegate interstitialCustomEventDidExpire:self];
    } else {
        MOPUBErrorCode mopubErrorCode = [OguryAdsAdapterConfiguration getMoPubErrorCodeFromOguryAdsError:errorType];
        [self oguryAdsInterstitialAdFailure:mopubErrorCode];
    }
}

- (void)oguryAdsInterstitialAdFailure:(MOPUBErrorCode)code {
    NSError * error = [NSError errorWithCode:code];
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:(NSError*)error],
                 [self getAdNetworkId]);
    self.oguryInterstitial = nil;
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:(NSError *)error];
}

@end

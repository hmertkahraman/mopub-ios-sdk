//
//  InMobiRewardedCustomEvent.m
//  MoPub
//
//  Created by Hikmet Mert Kahraman on 04/05/2020.
//  Copyright © 2020 MoPub. All rights reserved.
//

#import "InMobiRewardedCustomEvent.h"

#if __has_include("MoPub.h")
    #import "MPLogging.h"
    #import "MPConstants.h"
    #import "MPReward.h"
    #import "MPRewardedVideoError.h"
#endif

#import "InMobiGDPR.h"
#import "InMobiAdapterConfiguration.h"

#import <InMobiSDK/IMSdk.h>

@interface InMobiRewardedCustomEvent ()

@property (nonatomic, strong) IMInterstitial * inMobiRewardedVideoAd;
@property (nonatomic, copy)   NSString       * placementId;
@property (nonatomic, copy)   NSString       * accountId;

@end

@implementation InMobiRewardedCustomEvent

- (NSString *) getAdNetworkId {
    return _placementId;
}

#pragma mark - MPFullscreenAdAdapter Override

- (BOOL)isRewardExpected {
    return YES;
}

- (BOOL)hasAdAvailable {
    return (self.inMobiRewardedVideoAd && [self.inMobiRewardedVideoAd isReady]);
}

- (void)handleCustomEventInvalidated{
    //Do nothing
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

- (long long) placementIdLong
{
    return [self.placementId longLongValue];
}

- (void)initializeSdkWithParameters:(NSDictionary *)parameters {
    NSString * const accountId   = parameters[kIMAccountID];
    NSString * const placementId = parameters[kIMPlacementID];

    NSError * accountIdError = [InMobiAdapterConfiguration validateAccountId:accountId forOperation:@"rewarded video ad request"];
    if (accountIdError) {
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:accountIdError];
        return;
    }
    self.accountId = accountId;

    NSError * placementIdError = [InMobiAdapterConfiguration validatePlacementId:placementId forOperation:@"rewarded video ad request"];
    if (placementIdError) {
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:placementIdError];
        return;
    }
    self.placementId = placementId;

    [InMobiAdapterConfiguration initializeInMobiSDK:accountId];
}


- (void)requestRewardedVideoWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class)
                                       dspCreativeId:nil
                                             dspName:nil], [self getAdNetworkId]);

    self.inMobiRewardedVideoAd = [[IMInterstitial alloc] initWithPlacementId:self.placementIdLong];
    self.inMobiRewardedVideoAd.delegate = self;
    
    // Mandatory params to be set by the publisher to identify the supply source type
    NSMutableDictionary * mandatoryInMobiExtrasDict = [[NSMutableDictionary alloc] init];
    [mandatoryInMobiExtrasDict setObject:@"c_mopub" forKey:@"tp"];
    [mandatoryInMobiExtrasDict setObject:MP_SDK_VERSION forKey:@"tp-ver"];

    [InMobiAdapterConfiguration setupInMobiSDKDemographicsParams:self.accountId];
    
    self.inMobiRewardedVideoAd.extras = mandatoryInMobiExtrasDict;
    
    RUN_SYNC_ON_MAIN_THREAD(
        [self.inMobiRewardedVideoAd load];
    )
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController {
    if ([self hasAdAvailable]) {
        MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
        [self.delegate fullscreenAdAdapterAdWillAppear:self];

        [self.inMobiRewardedVideoAd showFromViewController:viewController withAnimation:kIMInterstitialAnimationTypeCoverVertical];
    } else {
        NSError *error = [NSError errorWithDomain:MoPubRewardedVideoAdsSDKDomain code:MPRewardedVideoAdErrorNoAdsAvailable userInfo:nil];
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class)
                                                  error:error], [self getAdNetworkId]);
        [self.delegate fullscreenAdAdapter:self didFailToShowAdWithError:error];
    }
}

#pragma mark - InMobi Rewarded Video Delegate Methods

-(void)interstitialDidFinishLoading:(IMInterstitial*)interstitial {
    self.inMobiRewardedVideoAd = interstitial;
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterDidLoadAd:self];
}

-(void)interstitialDidReceiveAd:(IMInterstitial *)interstitial{
    MPLogInfo(@"InMobi Ad Server responded with a Rewarded Video ad");
}

-(void)interstitial:(IMInterstitial*)interstitial didFailToLoadWithError:(IMRequestStatus*)error {
    self.inMobiRewardedVideoAd = nil;
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class)
                                              error:error], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:(NSError*)error];
}

-(void)interstitialWillPresent:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdWillAppear:self];
}

-(void)interstitialDidPresent:(IMInterstitial *)interstitial {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidAppear:self];
    [self.delegate fullscreenAdAdapterDidTrackImpression:self];

}

-(void)interstitial:(IMInterstitial*)interstitial didFailToPresentWithError:(IMRequestStatus*)error {
    MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class)error:error], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapter:self didFailToShowAdWithError:(NSError *)error];
}

-(void)interstitialWillDismiss:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdWillDisappear:self];
}

-(void)interstitialDidDismiss:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidDisappear:self];
}

-(void)interstitial:(IMInterstitial*)interstitial didInteractWithParams:(NSDictionary*)params {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterDidReceiveTap:self];
    [self.delegate fullscreenAdAdapterDidTrackClick:self];
}

-(void)userWillLeaveApplicationFromInterstitial:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterWillLeaveApplication:self];
}

-(void)interstitial:(IMInterstitial*)interstitial rewardActionCompletedWithRewards:(NSDictionary*)rewards {
    if (rewards != nil && [rewards count] > 0) {
        MPReward *reward = [[MPReward alloc] initWithCurrencyType:kMPRewardCurrencyTypeUnspecified amount:[rewards allValues][0]];
        MPLogInfo(@"InMobi reward action completed with rewards: %@", [rewards description]);
        [self.delegate fullscreenAdAdapter:self willRewardUser:reward];
    } else {
        MPLogInfo(@"InMobi reward action failed, rewards object is empty");
    }
}

@end

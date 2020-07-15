//
//  InMobiInterstitialCustomEvent.m
//  MoPub
//
//  Created by Hikmet Mert Kahraman on 04/05/2020.
//  Copyright © 2020 MoPub. All rights reserved.
//

#import "InMobiInterstitialCustomEvent.h"

#if __has_include("MoPub.h")
    #import "MPLogging.h"
    #import "MPConstants.h"
#endif

#import "InMobiGDPR.h"
#import "InMobiAdapterConfiguration.h"

#import <InMobiSDK/IMSdk.h>

@interface InMobiInterstitialCustomEvent ()

@property (nonatomic, strong) IMInterstitial * interstitialAd;
@property (nonatomic, copy)   NSString       * placementId;

@end

@implementation InMobiInterstitialCustomEvent

- (NSString *) getAdNetworkId {
    return _placementId;
}

#pragma mark - MPFullscreenAdAdapter Override

- (BOOL)isRewardExpected {
    return NO;
}

- (BOOL)hasAdAvailable {
    return self.interstitialAd != nil;
}

- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO;
}

- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString * const accountId   = info[kIMAccountID];
    NSString * const placementId = info[kIMPlacementID];

    NSError * accountIdError = [InMobiAdapterConfiguration validateAccountId:accountId forOperation:@"interstitial ad request"];
    if (accountIdError) {
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:accountIdError];
        return;
    }

    NSError * placementIdError = [InMobiAdapterConfiguration validatePlacementId:placementId forOperation:@"interstitial ad request"];
    if (placementIdError) {
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:placementIdError];
        return;
    }
    
    self.placementId = placementId;
    long long placementIdLong = [placementId longLongValue];

    [InMobiAdapterConfiguration initializeInMobiSDK:accountId];

    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class)
                                       dspCreativeId:nil
                                             dspName:nil], [self getAdNetworkId]);

    self.interstitialAd = [[IMInterstitial alloc] initWithPlacementId:placementIdLong];
    self.interstitialAd.delegate = self;
    
    // Mandatory params to be set by the publisher to identify the supply source type
    NSMutableDictionary * mandatoryInMobiExtrasDict = [[NSMutableDictionary alloc] init];
    [mandatoryInMobiExtrasDict setObject:@"c_mopub" forKey:@"tp"];
    [mandatoryInMobiExtrasDict setObject:MP_SDK_VERSION forKey:@"tp-ver"];

    [InMobiAdapterConfiguration setupInMobiSDKDemographicsParams:accountId];
    
    self.interstitialAd.extras = mandatoryInMobiExtrasDict;
    
    RUN_SYNC_ON_MAIN_THREAD(
        [self.interstitialAd load];
    )
}

- (void)presentAdFromViewController:(UIViewController *)viewController {
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);

    if ([self hasAdAvailable]) {
        [self.interstitialAd showFromViewController:viewController withAnimation:kIMInterstitialAnimationTypeCoverVertical];
    } else {
        NSError *adNotAvailableError = [InMobiAdapterConfiguration createErrorWith:@"Failed to show InMobi Interstitial"
                                                                         andReason:@"Ad is not available"
                                                                     andSuggestion:@""];
        MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:adNotAvailableError],
                     [self getAdNetworkId]);
        
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:adNotAvailableError];
    }
}

#pragma mark - InMobi Interstitial Delegate Methods

-(void)interstitialDidFinishLoading:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    self.interstitialAd = interstitial;
    [self.delegate fullscreenAdAdapterDidLoadAd:self];
}

-(void)interstitial:(IMInterstitial*)interstitial didFailToLoadWithError:(IMRequestStatus*)error {
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:(NSError*)error],
                 [self getAdNetworkId]);
    self.interstitialAd = nil;
    [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:(NSError *)error];
}

-(void)interstitialWillPresent:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdWillAppear:self];
}

-(void)interstitialDidPresent:(IMInterstitial *)interstitial {
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidAppear:self];
    [self.delegate fullscreenAdAdapterDidTrackImpression:self];
}

-(void)interstitial:(IMInterstitial*)interstitial didFailToPresentWithError:(IMRequestStatus*)error {
    MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class)error:error],
                 [self getAdNetworkId]);

    [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:(NSError *)error];
}

-(void)interstitialWillDismiss:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdWillDisappear:self];
}

-(void)interstitialDidDismiss:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterAdDidDisappear:self];
}

-(void)interstitial:(IMInterstitial*)interstitial didInteractWithParams:(NSDictionary*)params {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterDidReceiveTap:self];
    [self.delegate fullscreenAdAdapterDidTrackClick:self];
}

-(void)userWillLeaveApplicationFromInterstitial:(IMInterstitial*)interstitial {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate fullscreenAdAdapterWillLeaveApplication:self];
}

// -- Unsupported by MoPub --
// No rewards on Interstitials
-(void)interstitial:(IMInterstitial*)interstitial rewardActionCompletedWithRewards:(NSDictionary*)rewards {
    if (rewards != nil) {
        MPLogInfo(@"InMobi interstitial reward action completed with rewards: %@", [rewards description]);
    }
}

@end

//
//  InMobiBannerCustomEvent.m
//  MoPub
//
//  Created by Hikmet Mert Kahraman on 04/05/2020.
//  Copyright © 2020 MoPub. All rights reserved.
//

#import "InMobiBannerCustomEvent.h"

#if __has_include("MoPub.h")
    #import "MPLogging.h"
    #import "MPConstants.h"
#endif

#import "InMobiGDPR.h"
#import "InMobiAdapterConfiguration.h"

#import <InMobiSDK/IMSdk.h>

@interface InMobiBannerCustomEvent () <CLLocationManagerDelegate>

@property (nonatomic, strong) IMBanner * bannerAd;
@property (nonatomic, copy)   NSString * placementId;
@property (nonatomic, strong) CLLocationManager * locationManager;

@end

@implementation InMobiBannerCustomEvent

#pragma mark - MPInlineAdAdapter Subclass Methods

- (NSString *) getAdNetworkId {
    return _placementId;
}

// Override this method to return NO to perform impression and click tracking manually.
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return NO;
}

- (void)requestAdWithSize:(CGSize)size adapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString * const accountId   = info[kIMAccountID];
    NSString * const placementId = info[kIMPlacementID];
    
    NSError * accountIdError = [InMobiAdapterConfiguration validateAccountId:accountId forOperation:@"banner ad request"];
    if (accountIdError) {
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:accountIdError];
        return;
    }

    NSError * placementIdError = [InMobiAdapterConfiguration validatePlacementId:placementId forOperation:@"banner ad request"];
    if (placementIdError) {
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:placementIdError];
        return;
    }
    
    self.placementId = placementId;
    long long placementIdLong = [placementId longLongValue];
       
    // InMobi supports flex banner sizes. No size standardization logic required.
    if (size, size.height == 0) {
        NSError * zeroSizeError = [InMobiAdapterConfiguration createErrorWith:@"Aborting InMobi banner ad request"
                                                                    andReason:@"Requested banner ad size (0x0) is not valid"
                                                                andSuggestion:@"Ensure requested banner ad size is not (0x0)."];
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:zeroSizeError];
        return;
    }
    CGRect bannerAdFrame = CGRectMake(0, 0, size.width, size.height);
        
    [InMobiAdapterConfiguration initializeInMobiSDK:accountId];
    
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class)
                                       dspCreativeId:nil
                                             dspName:nil], [self getAdNetworkId]);
    
    
    RUN_SYNC_ON_MAIN_THREAD(
        self.bannerAd = [[IMBanner alloc] initWithFrame:bannerAdFrame placementId:placementIdLong];
        self.bannerAd.delegate = self;
        [self.bannerAd shouldAutoRefresh:NO];
        
        // Mandatory params to be set by the publisher to identify the supply source type
        NSMutableDictionary *mandatoryInMobiExtrasDict = [[NSMutableDictionary alloc] init];
        [mandatoryInMobiExtrasDict setObject:@"c_mopub" forKey:@"tp"];
        [mandatoryInMobiExtrasDict setObject:MP_SDK_VERSION forKey:@"tp-ver"];
        
        [InMobiAdapterConfiguration setupInMobiSDKDemographicsParams:accountId];
                                
        self.bannerAd.extras = mandatoryInMobiExtrasDict;
                                
        // Request banner Ad
        [self.bannerAd load];
    )
}

#pragma mark - AdColony Banner Delegate Methods

-(void)bannerDidFinishLoading:(IMBanner*)banner {
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);

    [self.delegate inlineAdAdapter:self didLoadAdWithAdView:banner];
    [self.delegate inlineAdAdapterDidTrackImpression:self];
}

-(void)banner:(IMBanner*)banner didFailToLoadWithError:(IMRequestStatus*)error {
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error],
               [self getAdNetworkId]);
    [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:(NSError *)error];
}

-(void)banner:(IMBanner*)banner didInteractWithParams:(NSDictionary*)params {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate inlineAdAdapterDidTrackClick:self];
}

-(void)userWillLeaveApplicationFromBanner:(IMBanner*)banner {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate inlineAdAdapterWillLeaveApplication:self];
}

-(void)bannerWillPresentScreen:(IMBanner*)banner {
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate inlineAdAdapterWillBeginUserAction:self];
}

-(void)bannerDidPresentScreen:(IMBanner*)banner {
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
}

-(void)bannerWillDismissScreen:(IMBanner*)banner {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
}

-(void)bannerDidDismissScreen:(IMBanner*)banner {
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)],
                 [self getAdNetworkId]);
    [self.delegate inlineAdAdapterDidEndUserAction:self];
}

// -- Unsupported by MoPub --
// No rewards on Banners
-(void)banner:(IMBanner*)banner rewardActionCompletedWithRewards:(NSDictionary*)rewards {
    if (rewards != nil) {
        MPLogInfo(@"InMobi banner reward action completed with rewards: %@", [rewards description]);
    }
}

@end

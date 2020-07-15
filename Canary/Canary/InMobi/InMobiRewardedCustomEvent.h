//
//  InMobiRewardedCustomEvent.h
//  MoPub
//
//  Copyright © 2020 MoPub. All rights reserved.
//

#ifndef InMobiRewardedCustomEvent_h
#define InMobiRewardedCustomEvent_h


#endif /* InMobiRewardedCustomEvent_h */

#if __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
    #import <MoPubSDKFramework/MoPub.h>
#else
    #import "MPFullscreenAdAdapter.h"
#endif

#import <InMobiSDK/IMInterstitial.h>

@interface InMobiRewardedCustomEvent : MPFullscreenAdAdapter <IMInterstitialDelegate>

@end

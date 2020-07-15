//
//  InMobiInterstitialCustomEvent.h
//  MoPub
//
//  Copyright © 2020 MoPub. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
    #import <MoPubSDKFramework/MoPub.h>
#else
    #import "MPFullscreenAdAdapter.h"
#endif

#import <InMobiSDK/IMInterstitial.h>

@interface InMobiInterstitialCustomEvent : MPFullscreenAdAdapter <IMInterstitialDelegate>

@end

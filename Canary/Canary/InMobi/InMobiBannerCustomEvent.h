//
//  InMobiBannerCustomEvent.h
//  MoPub
//
//  Copyright © 2020 MoPub. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
    #import <MoPubSDKFramework/MoPub.h>
#else
    #import "MPInlineAdAdapter.h"
#endif

#import <InMobiSDK/IMBanner.h>

@interface InMobiBannerCustomEvent : MPInlineAdAdapter <IMBannerDelegate>

@end

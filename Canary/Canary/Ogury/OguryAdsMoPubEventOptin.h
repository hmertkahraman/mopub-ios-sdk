//
//  OguryAdsMoPubEventOptin.h
//  MoPub
//
//  Copyright © 2020 MoPub. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
    #import <MoPubSDKFramework/MoPub.h>
#else
    #import "MPRewardedVideoCustomEvent.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface OguryAdsMoPubEventOptin : MPRewardedVideoCustomEvent

@end

NS_ASSUME_NONNULL_END

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
    #import "MPFullscreenAdAdapter.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface OguryAdsMoPubEventOptin : MPFullscreenAdAdapter

@end

NS_ASSUME_NONNULL_END

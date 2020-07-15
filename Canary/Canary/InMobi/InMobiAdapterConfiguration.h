//
//  InMobiAdapterConfiguration.h
//  MoPub
//
//  Copyright © 2020 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
    #import <MoPubSDKFramework/MoPub.h>
#else
    #import "MPBaseAdapterConfiguration.h"
#endif

#define RUN_SYNC_ON_MAIN_THREAD(Stuff) \
if ([NSThread currentThread].isMainThread) { \
do { \
Stuff; \
} while (0); \
} \
else { \
dispatch_sync(dispatch_get_main_queue(), ^(void) { \
do { \
Stuff; \
} while (0); \
}); \
}

NS_ASSUME_NONNULL_BEGIN

@interface InMobiAdapterConfiguration : MPBaseAdapterConfiguration

@property (nonatomic, copy, readonly) NSString * adapterVersion;
@property (nonatomic, copy, readonly) NSString * biddingToken;
@property (nonatomic, copy, readonly) NSString * moPubNetworkName;
@property (nonatomic, copy, readonly) NSString * networkSdkVersion;

typedef enum {
    kIMIncorrectAccountID,
    kIMIncorrectPlacemetID
} IMErrorCode;

extern NSString * const kIMErrorDomain;
extern NSString * const kIMPlacementID;
extern NSString * const kIMAccountID;

+ (BOOL)isInMobiSDKInitialized;

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> * _Nullable)configuration
                                  complete:(void(^ _Nullable)(NSError * _Nullable))complete;

+ (void)initializeInMobiSDK:(NSString *)accountId;

+ (void)updateGDPRConsent;

+ (NSError *)validateAccountId:(NSString *)accountId forOperation:(NSString *)operation;

+ (NSError *)validatePlacementId:(NSString *)placementId forOperation:(NSString *)operation;

+ (NSError *)createErrorForOperation:(NSString *)operation forParameterName:(NSString *)parameterName;

+ (NSError *)createErrorWith:(NSString *)description andReason:(NSString *)reason andSuggestion:(NSString *)suggestion;

+ (void)setupInMobiSDKDemographicsParams:(NSString *)accountId;

@end

NS_ASSUME_NONNULL_END

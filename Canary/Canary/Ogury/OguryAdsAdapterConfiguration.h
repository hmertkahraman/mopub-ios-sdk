//
//  OguryAdsAdapterConfiguration.h
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

#import <OguryAds/OguryAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface OguryAdsAdapterConfiguration : MPBaseAdapterConfiguration

@property (nonatomic, copy, readonly) NSString * adapterVersion;
@property (nonatomic, copy, readonly) NSString * biddingToken;
@property (nonatomic, copy, readonly) NSString * moPubNetworkName;
@property (nonatomic, copy, readonly) NSString * networkSdkVersion;

extern NSString * const kOguryAdUnitIdKey;
extern NSString * const kOguryAssetIdKey;

+ (BOOL) isOgurySDKInitialized;

+ (void) setIsOgurySDKInitialized:(BOOL)value;

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> * _Nullable)configuration
                                  complete:(void(^ _Nullable)(NSError * _Nullable))complete;

+ (NSError *)validateParameter:(NSString *)parameter withName:(NSString *)parameterName forOperation:(NSString *)operation;

+ (NSError *)createErrorForOperation:(NSString *)operation forParameterName:(NSString *)parameterName;

+ (NSError *)createErrorWith:(NSString *)description andReason:(NSString *)reason andSuggestion:(NSString *)suggestion;

+ (MOPUBErrorCode)getMoPubErrorCodeFromOguryAdsError:(OguryAdsErrorType)errorType;

@end

NS_ASSUME_NONNULL_END

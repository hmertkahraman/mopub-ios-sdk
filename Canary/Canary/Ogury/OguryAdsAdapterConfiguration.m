//
//  OguryAdsAdapterConfiguration.m
//  MoPub
//
//  Created by Hikmet Mert Kahraman on 04/05/2020.
//  Copyright © 2020 MoPub. All rights reserved.
//

#import "OguryAdsAdapterConfiguration.h"
#import <OguryAds/OguryAds.h>

@implementation OguryAdsAdapterConfiguration

#pragma mark - MPAdapterConfiguration

-(NSString *)adapterVersion {
    return @"1.3.2.0";
}

-(NSString *)biddingToken {
    return nil;
}

-(NSString *)moPubNetworkName {
    return @"ogury";
}

-(NSString *)networkSdkVersion {
    return [[OguryAds shared]sdkVersion];
}

NSString * const kOguryAssetIdKey  = @"asset_key";
NSString * const kOguryAdUnitIdKey = @"ad_unit_id";

#pragma mark - OguryAdsAdapterConfiguration Initialization

static BOOL isOgurySDKInitialized = false;

+ (BOOL)isOgurySDKInitialized { return isOgurySDKInitialized; }
+ (void)setIsOgurySDKInitialized:(BOOL)isInitialized { isOgurySDKInitialized = isInitialized; }

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> * _Nullable)configuration
                                  complete:(void(^ _Nullable)(NSError * _Nullable))complete {
    NSString * const oguryAssetId = configuration[kOguryAssetIdKey];
    NSError  * oguryAssetIdError = [OguryAdsAdapterConfiguration validateParameter:oguryAssetId withName:kOguryAssetIdKey forOperation:@"initialization"];
    if (oguryAssetIdError) {
        MPLogInfo(@"Ogury adapters will attempt lazy initialization upon first ad request instead. Make sure Ogury Asset Key info is present on the MoPub UI.");
        [OguryAdsAdapterConfiguration setIsOgurySDKInitialized:false];
        complete(oguryAssetIdError);
        return;
    }
        
    [[OguryAds shared] setupWithAssetKey: oguryAssetId andCompletionHandler:^(NSError *oguryAdsInitializationError) {
        if (oguryAdsInitializationError) {
            [OguryAdsAdapterConfiguration setIsOgurySDKInitialized:false];
            complete(oguryAdsInitializationError);
        } else {
            [OguryAdsAdapterConfiguration setIsOgurySDKInitialized:true];
            complete(nil);
        }
    }];
}

#pragma mark - OguryAdapterConfiguration Error Handling Methods

+ (NSError *)validateParameter:(NSString *)parameter withName:(NSString *)parameterName forOperation:(NSString *)operation {
    if (parameter != nil && parameter.length > 0) {
        return nil;
    }
    
    NSError * error = [self createErrorForOperation:operation forParameterName:parameterName];
    return error;
}

+ (NSError *)createErrorForOperation:(NSString *)operation forParameterName:(NSString *)parameterName {
    if (parameterName == nil) {
        parameterName = @"Ogury Ad Unit Id or Asset Key";
    }
    
    NSString * description = [NSString stringWithFormat:@"Ogury adapter unable to proceed with %@", operation];
    NSString * reason      = [NSString stringWithFormat:@"%@ is nil/empty", parameterName];
    NSString * suggestion  = [NSString stringWithFormat:@"Make sure the Ogury's %@ is configured on the MoPub UI.", parameterName];
    
    return [OguryAdsAdapterConfiguration createErrorWith:description
                                               andReason:reason
                                           andSuggestion:suggestion];
}

+ (NSError *)createErrorWith:(NSString *)description andReason:(NSString *)reason andSuggestion:(NSString *)suggestion {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey            : NSLocalizedString(description, nil),
                               NSLocalizedFailureReasonErrorKey     : NSLocalizedString(reason, nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(suggestion, nil)
                               };

    MPLogDebug(@"%@. %@. %@", description, reason, suggestion);
    
    return [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
}

+ (MOPUBErrorCode)getMoPubErrorCodeFromOguryAdsError:(OguryAdsErrorType)errorType {
    switch (errorType) {
        case OguryAdsErrorNoInternetConnection:
            return MOPUBErrorNoNetworkData;
        case OguryAdsErrorLoadFailed:
            return MOPUBErrorNoInventory;
        case OguryAdsErrorAdDisable:
        case OguryAdsErrorProfigNotSynced:
        case OguryAdsErrorSdkInitNotCalled:
            return MOPUBErrorAdapterInvalid;
        case OguryAdsErrorAdExpired:
            return MOPUBErrorUnknown;
    }
    return MOPUBErrorUnknown;
}


@end

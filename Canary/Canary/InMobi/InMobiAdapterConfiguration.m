//
//  InMobiAdapterConfiguration.m
//  MoPub
//
//  Created by Hikmet Mert Kahraman on 04/05/2020.
//  Copyright © 2020 MoPub. All rights reserved.
//

#import "InMobiAdapterConfiguration.h"

#import "InMobiGDPR.h"
#if __has_include("MoPub.h")
    #import "MPLogging.h"
    #import "MPConstants.h"
#endif

#import <InMobiSDK/IMSdk.h>

#define InMobiMopubAdapterVersion @"9.0.7.0"
#define MopubNetworkName @"inmobi"
#define InMobiSDKVersion @"9.0.7"

@implementation InMobiAdapterConfiguration

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    return InMobiMopubAdapterVersion;
}

- (NSString *)biddingToken {
    return nil;
}

- (NSString *)moPubNetworkName {
    return MopubNetworkName;
}

- (NSString *)networkSdkVersion {
    return [IMSdk getVersion];
}

NSString * const kIMErrorDomain = @"com.inmobi.mopubcustomevent.iossdk";
NSString * const kIMPlacementID = @"placementid";
NSString * const kIMAccountID   = @"accountid";

static BOOL isInMobiSDKInitialized = false;

+ (BOOL)isInMobiSDKInitialized {
    return isInMobiSDKInitialized;
}

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> *)configuration
                                  complete:(void(^)(NSError *))complete {
    NSString * const accountId = configuration[kIMAccountID];
    
    NSError *accountIdError = [InMobiAdapterConfiguration validateAccountId:accountId forOperation:@"initialization"];
    if (accountIdError) {
        MPLogInfo(@"InMobi adapters will attempt lazy initialization upon first ad request instead. Make sure InMobi Account Id info is present on the MoPub UI.");
        isInMobiSDKInitialized = false;
        complete(accountIdError);
    } else {
        [InMobiAdapterConfiguration initializeInMobiSDK:accountId];
        complete(nil);
    }
}

+ (void)initializeInMobiSDK:(NSString *)accountId {
    if(!isInMobiSDKInitialized) {
        NSDictionary * gdprConsentObject = [InMobiGDPR getGDPRConsentDictionary];
        [IMSdk setLogLevel:[self getInMobiLoggingLevelFromMopubLogLevel:[[MoPub sharedInstance] logLevel]]];
        
        RUN_SYNC_ON_MAIN_THREAD(
            [IMSdk initWithAccountID:accountId consentDictionary:gdprConsentObject];
        )
        
        MPLogInfo(@"InMobi SDK initialized successfully.");
        isInMobiSDKInitialized = true;
    } else {
        MPLogInfo(@"InMobi SDK already initialized, no need to reinitialize.");
    }
}

+ (void)updateGDPRConsent {
    [IMSdk updateGDPRConsent:[InMobiGDPR getGDPRConsentDictionary]];
}

#pragma mark - InMobiAdapterConfiguration Error Handling Methods

+ (NSError *)validateAccountId:(NSString *)accountId forOperation:(NSString *)operation {
    accountId = [accountId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (accountId != nil && accountId.length > 0 && ([accountId length] == 32 || [accountId length] == 36)) {
        return nil;
    }
    
    NSError * error = [self createErrorForOperation:operation forParameterName:kIMAccountID];
    return error;
}

+ (NSError *)validatePlacementId:(NSString *)placementId forOperation:(NSString *)operation {
    Boolean hasError = false;
    if (placementId == nil || placementId.length <= 0) {
        hasError = true;
    }
    
    long long placementIdLong = [placementId longLongValue];
    if (placementIdLong <= 0) {
        hasError = true;
    }
    
    if (hasError) {
        NSError * error = [self createErrorForOperation:operation forParameterName:kIMPlacementID];
        return error;
    } else {
        return nil;
    }
}

+ (NSError *)createErrorForOperation:(NSString *)operation forParameterName:(NSString *)parameterName {
    if (parameterName == nil) {
        parameterName = @"InMobi Account Id and/or Placement Id";
    }
    
    NSString * description = [NSString stringWithFormat:@"InMobi adapter unable to proceed with %@", operation];
    NSString * reason      = [NSString stringWithFormat:@"%@ is nil/empty", parameterName];
    NSString * suggestion  = [NSString stringWithFormat:@"Make sure the InMobi's %@ is configured on the MoPub UI.", parameterName];
    
    return [InMobiAdapterConfiguration createErrorWith:description
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

+ (IMSDKLogLevel)getInMobiLoggingLevelFromMopubLogLevel:(MPBLogLevel)logLevel
{
    switch (logLevel) {
        case MPBLogLevelDebug:
            return kIMSDKLogLevelDebug;
        case MPBLogLevelInfo:
            return kIMSDKLogLevelError;
        case MPBLogLevelNone:
            return kIMSDKLogLevelNone;
    }
    return kIMSDKLogLevelNone;
}

#pragma mark - InMobiAdapterConfiguration SDK Demographics Params Setup

// Edit this method to pass custom demographic params on InMobi adapters
+ (void)setupInMobiSDKDemographicsParams:(NSString *)accountId {
    /*
    Sample for setting up the InMobi SDK Demographic params.
    Publisher need to set the values of params as they want.
    
    [IMSdk setAreaCode:@"1223"];
    [IMSdk setEducation:kIMSDKEducationHighSchoolOrLess];
    [IMSdk setGender:kIMSDKGenderMale];
    [IMSdk setAge:12];
    [IMSdk setPostalCode:@"234"];
    [IMSdk setLocationWithCity:@"BAN" state:@"KAN" country:@"IND"];
    [IMSdk setLanguage:@"ENG"];
    */
}

@end

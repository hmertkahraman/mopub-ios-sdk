//
//  InMobiGDPR.m
//  InMobiMopubSampleApp
//
//  Created by Vineet Srivastava on 18/05/18.
//
//
#import "InMobiGDPR.h"

NSDictionary* userConsentDictionary;

@implementation InMobiGDPR

+ (void)setGDPRConsentDictionary:(NSDictionary *)consentDictionary {
    userConsentDictionary = consentDictionary;
}

+ (NSDictionary *)getGDPRConsentDictionary {
    return userConsentDictionary;
}

@end

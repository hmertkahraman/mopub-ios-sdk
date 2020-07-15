//
//  InMobiGDPR.h
//  InMobiMopubSampleApp
//
//  Created by Vineet Srivastava on 18/05/18.
//
//
#import <Foundation/Foundation.h>

static const NSString * IM_MPADAPTER_GDPR_CONSENT_AVAILABLE = @"gdpr_consent_available";
static const NSString * IM_MPADAPTER_GDPR_CONSENT_APPLICABLE = @"gdpr";
static const NSString * IM_MPADAPTER_GDPR_CONSENT_IAB = @"gdpr_consent";

@interface InMobiGDPR : NSObject

/**
 * @discussion Use this method to pass the consent dictionary which has to be consumed by the InMobi SDK
 * The following keys are currently supported by the InMobi SDK and are available as a const NSStirng as part of the adapter
 * 1) IM_MPADAPTER_GDPR_CONSENT_AVAILABLE = Use this key to set the Boolean consent as given by the user
 * 2) IM_MPADAPTER_GDPR_CONSENT_APPLICABLE = Use this key to indicate whether GDPR is applicable for this user
 * 3) IM_MPADAPTER_GDPR_CONSENT_IAB = Usde this key to set the IAB GDPR Consent string
 * This method can be invoked multiple times during a session  to update the consent as required
 *
 * @param consentDictionary An NSDictionary object which contains the user's consent
 */
+ (void)setGDPRConsentDictionary:(NSDictionary*)consentDictionary;

/**
 * @discussion Use this method to read the currently set ConsentDictionary.
 * @return A NSDictionary instance which was set using setGDPRConsentDictionary: method or nil, otherwise
 */
+ (NSDictionary*)getGDPRConsentDictionary;

@end

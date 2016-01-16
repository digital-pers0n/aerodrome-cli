//
//  Apple80211Err.h
//  Wlan
//
//
//  Copyright (c) 2015. All rights reserved.
//
/*! @group CoreWLAN Error Codes */
/*!
 * @enum CWErr
 
 
 * @const kCWNoErr Success.
 
 * @const kCWEAPOLErr EAPOL-related error.
 
 * @const kCWInvalidParameterErr Parameter error.
 
 * @const kCWNoMemoryErr Memory allocation failed.
 
 * @const kCWUnknownErr Unexpected error condition encountered for which no error code exists.
 
 * @const kCWNotSupportedErr Operation not supported.
 
 * @const kCWInvalidFormatErr Invalid protocol element field detected.
 
 * @const kCWTimeoutErr Authentication/Association timed out.
 
 * @const kCWUnspecifiedFailureErr Access point did not specify a reason for authentication/association failure.
 
 * @const kCWUnsupportedCapabilitiesErr Access point cannot support all requested capabilities.
 
 * @const kCWReassociationDeniedErr Reassociation was denied because the access point was unable to determine that an association exists.
 
 * @const kCWAssociationDeniedErr Association was denied for an unspecified reason.
 
 * @const kCWAuthenticationAlgorithmUnsupportedErr Specified authentication algorithm is not supported.
 
 * @const kCWInvalidAuthenticationSequenceNumberErr Authentication frame received with an authentication sequence number out of expected sequence.
 
 * @const kCWChallengeFailureErr Authentication was rejected because of a challenge failure.
 
 * @const kCWAPFullErr Access point is unable to handle another associated station.
 
 * @const kCWUnsupportedRateSetErr Interface does not support all of the rates in the access point's basic rate set.
 
 * @const kCWShortSlotUnsupportedErr Association denied because short slot time option is not supported by requesting station.
 
 * @const kCWDSSSOFDMUnsupportedErr Association denied because DSSS-OFDM is not supported by requesting station.
 
 * @const kCWInvalidInformationElementErr Invalid information element included in association request.
 
 * @const kCWInvalidGroupCipherErr Invalid group cipher requested.
 
 * @const kCWInvalidPairwiseCipherErr Invalid pairwise cipher requested.
 
 * @const kCWInvalidAKMPErr Invalid authentication selector requested.
 
 * @const kCWUnsupportedRSNVersionErr Invalid WPA/WPA2 version specified.
 
 * @const kCWInvalidRSNCapabilitiesErr Invalid RSN capabilities specified in association request.
 
 * @const kCWCipherSuiteRejectedErr Cipher suite rejected due to network security policy.
 
 * @const kCWInvalidPMKErr PMK rejected by the access point.
 
 * @const kCWSupplicantTimeoutErr WPA/WPA2 handshake timed out.
 
 * @const kCWHTFeaturesNotSupportedErr Association was denied because the requesting station does not support HT features.
 
 * @const kCWPCOTransitionTimeNotSupportedErr Association was denied because the requesting station does not support the
 
 * PCO transition time required by the AP.
 
 * @const kCWReferenceNotBoundErr No interface is bound to the CWInterface.
 
 * @const kCWIPCFailureErr Error communicating with a separate process.
 
 * @const kCWOperationNotPermittedErr Calling process does not have permission to perform this operation.
 
 * @const kCWErr Generic error, no specific error code exists to describe the error condition.
 
 */

#ifndef Wlan_Apple80211IE_h
#define Wlan_Apple80211IE_h



#endif

enum {
	kA11NoErr                                       = 0,
	
	kA11EAPOLErr									= 1,
	
	kA1InvalidParameterErr						= -3900,
	kA11NoMemoryErr								= -3901,
	kA11UnknownErr								= -3902,
	kA11NotSupportedErr							= -3903,
	kA11InvalidFormatErr						= -3904,
	
	kA11TimeoutErr								= -3905,
	kA11UnspecifiedFailureErr					= -3906,
	kA11UnsupportedCapabilitiesErr				= -3907,
	kA11ReassociationDeniedErr					= -3908,
	kA11AssociationDeniedErr					= -3909,
	kA11AuthenticationAlgorithmUnsupportedErr	= -3910,
	kA11InvalidAuthenticationSequenceNumberErr	= -3911,
	kA11ChallengeFailureErr						= -3912,
	kA11APFullErr								= -3913,
	kA11UnsupportedRateSetErr					= -3914,
	kA11ShortSlotUnsupportedErr					= -3915,
	kA11DSSSOFDMUnsupportedErr					= -3916,
	kA11InvalidInformationElementErr			= -3917,
	kA11InvalidGroupCipherErr					= -3918,
	kA11InvalidPairwiseCipherErr				= -3919,
	kA11InvalidAKMPErr							= -3920,
	kA11UnsupportedRSNVersionErr				= -3921,
	kA11InvalidRSNCapabilitiesErr				= -3922,
	kA11CipherSuiteRejectedErr					= -3923,
	kA11InvalidPMKErr							= -3924,
	kA11SupplicantTimeoutErr					= -3925,
	kA11HTFeaturesNotSupportedErr				= -3926,
	kA11PCOTransitionTimeNotSupportedErr		= -3927,
	kA11ReferenceNotBoundErr					= -3928,
	kA11IPCFailureErr							= -3929,
	kA11OperationNotPermittedErr				= -3930,
	kA11Err										= -3931,
};
typedef int Apple80211Err;

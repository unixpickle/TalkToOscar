//
//  ANOSCARAuthorizer.h
//  OSCARAPI
//
//  Created by Alex Nichol on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// This class is for authorizing with the AOL server.
// This should always be called before using OSCAR
// directly, since it is needed for a valid connection.

// NOTE: it uses the HTTP api, not OSCAR.

#import <Foundation/Foundation.h>
#import "hmac-sha256.h"
#import "ANOSCARAuthorizationResponse.h"
// this is for URL escaping
// and unescaping.
#import "ANStringEscaper.h"
#import "ANCGIHTTPParameterReader.h"
#import "NSData+Base64.h"
// JSON parserheads101
#import "JSON.h"

@class ANOSCARAuthorizer;

@protocol ANOSCARAuthorizerDelegate<NSObject>

@optional
- (void)authorizer:(ANOSCARAuthorizer *)authorizer didFailWithError:(NSError *)error;
- (void)authorizer:(ANOSCARAuthorizer *)authorizer didSucceedLogin:(ANOSCARAuthorizationResponse *)response;

@end

// The following API key was taken directly from the libpurple source.
// Note that it is not mine, so don't think about doing anything
// bad with it.

#define kOSCARAPIKEY @"ma15d7JTxbmVG-RP"


@interface ANOSCARAuthorizer : NSObject {
	NSString * username;
	NSString * password;
	NSURLConnection * currentRequest;
	// the data that is currently
	// downloaded from the HTTP
	// server.
	NSMutableData * currentData;
	// the step we are at on the
	// authentication process.
	int stage;
	// the delegate of which to call
	// when we have our data.
	id<ANOSCARAuthorizerDelegate> delegate;
	
	// These are all AOL authorization fields that I use.
	// They should not be mutated.
	NSString * aToken;
	NSString * sessionKey;
	NSString * sessionSecret;
	NSString * hosttime;
}

// username and password need to be set before connect:
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;

// call this method to create a new authorizer with
// a delegate object.
- (id)initWithDelegate:(id<ANOSCARAuthorizerDelegate>)_delegate;

// Sends an asynchronous request to AOLs API server,
// authenticated it so that further connections
// may be estabolished.
- (BOOL)sendRequest:(NSString *)clientLogin;

// method to use to process data that came in from
// the authorization server.
- (void)handleData:(NSData *)fetched;

// This will create an authentication key
// using a nice SHA256 lib that I found.
- (NSString *)createAuthenticationKey;

// This function will generate the post data
// that needs to go to startOSCARSession.
- (NSString *)startOscarSessionPost;

// Queries the startOSCARSession WIM call.
// After this, you should tell our delegate.
- (void)commenceOscarStart;

// This is for closing down the authorizer's delegate
- (void)removeDelegate;

@end

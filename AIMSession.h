//
//  AIMSession.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANOSCARAuthorizer.h"
#import "OSCARConnection.h"
#import "AIMSessionLogin.h"

#import "TLV.h"
#import "FLAPFrame.h"
#import "SNAC.h"

#import "SNACRequest.h"

#import "AIMSessionMessages.h"

@class AIMSession;

@protocol AIMSessionDelegate <NSObject>

@optional
- (void)aimSession:(AIMSession *)session signonFailed:(NSError *)error;
- (void)aimSessionSignedOn:(AIMSession *)session;
- (void)aimSession:(AIMSession *)session gotSnac:(SNAC *)snac;
- (void)aimSessionSignedOff:(AIMSession *)session;

@end


@interface AIMSession : NSObject <ANOSCARAuthorizerDelegate, OSCARConnectionDelegate> {
	ANOSCARAuthorizer * login;
	ANOSCARAuthorizationResponse * response;
	
	NSString * login_username;
	NSString * login_password;
	
	BOOL isOnline;
	BOOL hasDied;
	
	OSCARConnection * bossConnection;
	NSMutableArray * snacRequests;
	
	id<AIMSessionDelegate> delegate;
}

@property (nonatomic, retain) id<AIMSessionDelegate> delegate;
- (ANOSCARAuthorizationResponse *)authorizationResponse;
- (NSMutableArray *)snacRequests;

- (NSString *)loginUsername;

+ (UInt32)randomRequestID;
- (void)rateLimitsSleep;

- (id)initWithScreenname:(NSString *)screenname password:(NSString *)password;
- (BOOL)signOnline;
- (BOOL)signOffline;

- (BOOL)sendSnacQuery:(SNAC *)snac;
- (BOOL)sendRegularSnac:(SNAC *)snac;

@end

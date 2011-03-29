//
//  AIMSession.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSession.h"


@implementation AIMSession

@synthesize delegate;

- (ANOSCARAuthorizationResponse *)authorizationResponse {
	return response;
}

- (NSMutableArray *)snacRequests {
	return snacRequests;
}

- (NSString *)loginUsername {
	return login_username;
}

+ (UInt32)randomRequestID {
	static UInt32 reqID = 0;
	if (!reqID) {
		reqID = arc4random();
	}
	reqID += 1;
	if (!reqID) reqID = 1;
	if (reqID >= 2147483648) reqID ^= 2147483648;
	return reqID;
}
- (void)rateLimitsSleep {
	static NSDate * previousTime = nil;
	NSTimeInterval sleepTime = 0;
	if (!previousTime) {
		sleepTime = 0.1;
	} else {
		sleepTime = 0.5 - ([[NSDate date] timeIntervalSinceDate:previousTime]);
		if (sleepTime < 0) sleepTime = 0;
	}
	
	[NSThread sleepForTimeInterval:sleepTime];
	
	[previousTime release];
	previousTime = [[NSDate date] retain];
}

- (id)initWithScreenname:(NSString *)screenname password:(NSString *)password {
	if (self = [super init]) {
		login_username = [screenname retain];
		login_password = [password retain];
	}
	return self;
}

- (BOOL)signOnline {
	if (isOnline || hasDied) return NO;
	// begin authorization
	login = [[ANOSCARAuthorizer alloc] initWithDelegate:self];
	[login setUsername:login_username];
	[login setPassword:login_password];
	// f=http is completely unsupported, lmao
	[login sendRequest:@"https://api.screenname.aol.com/auth/clientLogin?f=http"];
	return YES;
}

- (BOOL)signOffline {
	if (isOnline && !hasDied) {
		isOnline = NO;
		hasDied = YES;
		
		[bossConnection disconnect];
		[bossConnection release];
		[login release];
		login = nil;
		bossConnection = nil;
		
		if ([delegate respondsToSelector:@selector(aimSessionSignedOff:)]) {
			[delegate aimSessionSignedOff:self];
		}
		return YES;
	}
	return NO;
}

- (BOOL)sendSnacQuery:(SNAC *)snac {
	if (!snacRequests) snacRequests = [[NSMutableArray alloc] init];
	if (!bossConnection) return NO;
	[snacRequests addObject:[[[SNACRequest alloc] initWithSNAC:snac] autorelease]];
	return [self sendRegularSnac:snac];
}

- (BOOL)sendRegularSnac:(SNAC *)snac {
	FLAPFrame * flap = [bossConnection createFlapChannel:2
													data:[snac encodePacket]];
	[self rateLimitsSleep];
	return [bossConnection writeFlap:flap];
}

#pragma mark Authorization

- (void)authorizer:(ANOSCARAuthorizer *)authorizer didFailWithError:(NSError *)error {
	NSLog(@"Login error: %@", error);
	if ([delegate respondsToSelector:@selector(aimSession:signonFailed:)])
		[delegate aimSession:self signonFailed:error];
	hasDied = YES;
}

- (void)authorizer:(ANOSCARAuthorizer *)authorizer didSucceedLogin:(ANOSCARAuthorizationResponse *)_response {
	response = [_response retain];
	AIMSessionLogin * sessionLogin = [[AIMSessionLogin alloc] initWithSession:self];
	if (![sessionLogin initializeBosConnection]) {
		[self signOffline];
		[sessionLogin release];
		return;
	}
	
	bossConnection = [[sessionLogin bossConnection] retain];
	
	if (![sessionLogin sendSignon]) {
		[self signOffline];
		[sessionLogin release];
		return;
	}
	if (![sessionLogin queryFeedbag]) {
		[self signOffline];
		[sessionLogin release];
		return;
	}
	
	[bossConnection setDelegate:self];
	[sessionLogin release];
	
	if ([delegate respondsToSelector:@selector(aimSessionSignedOn:)]) {
		[delegate aimSessionSignedOn:self];
	}
	
	isOnline = YES;
}

#pragma mark Connections

- (void)oscarConnectionClosed:(OSCARConnection *)connection {
	// uh oh.
	if (connection == bossConnection) {
		[self signOffline];
	} else {
		NSLog(@"Bart connection closed.");
	}
}

- (void)oscarConnectionPacketWaiting:(OSCARConnection *)connection {
	if (connection != bossConnection) return;
	FLAPFrame * flap = [connection readFlap];
	if (flap) {
		if ([flap channel] == 2) {
			SNAC * snac = [[SNAC alloc] initWithData:[flap frameData]];
			if ([delegate respondsToSelector:@selector(aimSession:gotSnac:)]) {
				[delegate aimSession:self gotSnac:snac];
			}
			[snac release];
		}
	}
}

- (void)dealloc {
	self.delegate = nil;
	[response release];
	[snacRequests release];
	[login_username release];
	[login_password release];
	[bossConnection release];
	[super dealloc];
}

@end

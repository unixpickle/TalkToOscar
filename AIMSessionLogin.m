//
//  AIMSessionLogin.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSessionLogin.h"
#import "AIMSession.h"

@interface AIMSessionLogin ()

// this method will send the rate limits request, and acknowlege
// that data with its own.
- (BOOL)signonInitializeRateLimits;

// send a bunch of packets that are needed to initialize the connection.
// this does not await any of their responses.
- (BOOL)signonInitialQueries;

// waits for the responses from the signonInitialQueries.
- (BOOL)signonAwaitQueriesResponses;

// queries their personal info, requests a new service,
// and asks for the ICBM parameter info.
// this is called by singonInitialQueries.
- (BOOL)signonRequestServices;

// sets the ICBM parameters, and enables events.
- (BOOL)signonConfigureICBM;

@end

@implementation AIMSessionLogin

- (OSCARConnection *)bossConnection {
	return bossConnection;
}

- (id)initWithSession:(AIMSession *)_session {
	if (self = [super init]) {
		session = [_session retain];
	}
	return self;
}
- (BOOL)initializeBosConnection {
	// we have to open it, first of all.
	NSString * host = [[session authorizationResponse] hostName];
	int port = [[session authorizationResponse] port];
	bossConnection = [[OSCARConnection alloc] initWithHost:host port:port];
	[bossConnection setDelegate:self];
	NSError * error;
	return [bossConnection connectToHost:&error];
}
- (BOOL)sendSignon {
	if (![AIMSessionLogin waitForHostReady:bossConnection]) return NO;
	if (![AIMSessionLogin sendCookie:[[session authorizationResponse] cookie]
						toConnection:bossConnection]) return NO;
	
	// we are going to wait until we get a certain SNAC back.
	if (![AIMSessionLogin waitOnConnection:bossConnection forSnacID:SNAC_ID_NEW(SNAC_OSERVICE,
																		   OSERVICE__HOST_ONLINE)])
		return NO;
	
	// now we gotta do a lot of stuff!
	[bossConnection setIsNonBlocking:YES];
	
	if (![self signonInitializeRateLimits]) return NO;
	if (![self signonInitialQueries]) return NO;
	if (![self signonAwaitQueriesResponses]) return NO;
	if (![self signonRequestServices]) return NO;
	if (![AIMSessionLogin signonClientOnline:bossConnection]) return NO;
	if (![self signonConfigureICBM]) return NO;
	
	return YES;
}
- (BOOL)queryFeedbag {
	SNAC * feedbagQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__QUERY)
											 flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendSnacQuery:feedbagQuery]) {
		[feedbagQuery release];
		return NO;
	}
	[feedbagQuery release];
	return YES;
}

#pragma mark Data Transfers

+ (BOOL)waitForHostReady:(OSCARConnection *)connection {
	FLAPFrame * frame = [connection readFlap];
	if (!frame) return NO;
	else return YES;
}
+ (SNAC *)waitOnConnection:(OSCARConnection *)connection forSnacID:(SNAC_ID)snacID {
	while (YES) {
		FLAPFrame * flap = [connection readFlap];
		if (![connection isOpen]) return nil;
		SNAC * snac = [[SNAC alloc] initWithData:[flap frameData]];
		if (SNAC_ID_IS_EQUAL([snac snac_id], snacID)) return [snac autorelease];
		[snac release];
	}
}
+ (BOOL)sendCookie:(NSData *)cookieData toConnection:(OSCARConnection *)connection {
	UInt32 version = flipUInt32(1);
	UInt8 multiconFlag = 1;
	
	TLV * cookie = [[TLV alloc] initWithType:TLV_LOGIN_COOKIE
										data:cookieData];
	
	TLV * multicon = [[TLV alloc] initWithType:TLV_MULTICONN_FLAGS
										  data:[NSData dataWithBytes:&multiconFlag length:1]];
	
	// the data that contains the cookie and other
	// data the OSCAR requires.
	NSMutableData * packetData = [NSMutableData data];
	[packetData appendBytes:&version length:4];
	[packetData appendData:[cookie encodePacket]];
	[packetData appendData:[multicon encodePacket]];
	
	// free the cookie packet
	[cookie release];
	[multicon release];
	
	FLAPFrame * flap = [connection createFlapChannel:1
												data:packetData];
	
	return [connection writeFlap:flap];
}

// this method will send the rate limits request, and acknowlege
// that data with its own.
- (BOOL)signonInitializeRateLimits {
	SNAC * rateQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__RATE_PARAMS_QUERY)
										  flags:0
									  requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendSnacQuery:rateQuery]) {
		[rateQuery release];
		return NO;
	}
	
	SNAC * rateInfo = [AIMSessionLogin waitOnConnection:bossConnection forSnacID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__RATE_PARAMS_REPLY)];
	if (!rateInfo) {
		[rateQuery release];
		return NO;
	}
	
	[[session snacRequests] removeObject:[[session snacRequests] snacRequestWithID:[rateQuery requestID]]];
	
	[rateQuery release];
	
	// ackData is literally an array of UInt16 group IDs.
	// we have to get the group IDs from the data, that's all.
	
	NSMutableData * ackData = [NSMutableData data];
	NSData * actualData = [rateInfo innerContents];
	UInt16 count = flipUInt16(*((const UInt16 *)[actualData bytes]));
	// the index of the first group.
	int index = 30 * count + 2;
	while (index < [actualData length]) {
		// the ID of the group.
		UInt16 gid = *((const UInt16 *)(&((const char *)[actualData bytes])[index]));
		// the length of the group data / 4.
		UInt16 addLength = flipUInt16(*((const UInt16 *)(&((const char *)[actualData bytes])[index + 2])));
		// get the next group!
		index += (addLength * 4) + 4;
		// add the group ID to our byte array.
		[ackData appendBytes:&gid
					  length:2];
	}
	
	SNAC * ratesAccept = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__RATE_ADD_PARAM_SUB)
											flags:0 requestID:[AIMSession randomRequestID]
											 data:ackData];
	FLAPFrame * flap = [bossConnection createFlapChannel:2 data:[ratesAccept encodePacket]];
	[ratesAccept release];
	return [bossConnection writeFlap:flap];
}

// send a bunch of packets that are needed to initialize the connection.
// this does not await any of their responses.
- (BOOL)signonInitialQueries {
	// buddy rights query
	SNAC * buddyQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_BUDDY, BUDDY__RIGHTS_QUERY)
										   flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendSnacQuery:buddyQuery]) {
		[buddyQuery release];
		return NO;
	}
	[buddyQuery release];
	
	// permit/deny rights
	SNAC * pdQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_PD, PD__RIGHTS_QUERY) 
										flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendSnacQuery:pdQuery]) {
		[pdQuery release];
		return NO;
	}
	[pdQuery release];
	
	// query the LOCATE foodgroup rights.
	SNAC * locateQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_LOCATE, LOCATE__RIGHTS_QUERY) 
											flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendSnacQuery:locateQuery]) {
		[locateQuery release];
		return NO;
	}
	[locateQuery release];
	
	// get the feedbag rights, giving it our rules
	UInt16 feedbagRules = flipUInt16(0x7f);
	NSData * rulesData = [NSData dataWithBytes:&feedbagRules length:2];
	TLV * tagsFlags = [[TLV alloc] initWithType:TLV_FEEDBAG_RIGHTS_QUERY_TAGS_FLAGS data:rulesData];
	SNAC * feedbagRightsQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__RIGHTS_QUERY) 
												   flags:0 requestID:[AIMSession randomRequestID] data:[tagsFlags encodePacket]];
	[tagsFlags release];
	if (![session sendSnacQuery:feedbagRightsQuery]) {
		[feedbagRightsQuery release];
		return NO;
	}
	[feedbagRightsQuery release];
	
	return YES;
}

// waits for the responses from the signonInitialQueries.
- (BOOL)signonAwaitQueriesResponses {
	while ([[session snacRequests] count] > 0) {
		FLAPFrame * nextPacket = [bossConnection readFlap];
		if (![bossConnection isOpen]) return NO;
		if (nextPacket) {
			SNAC * snac = [[SNAC alloc] initWithData:[nextPacket frameData]];
			if (snac && [snac isLastResponse]) {
				SNACRequest * request = [session.snacRequests snacRequestWithID:[snac requestID]];
				if (request) {
					[session.snacRequests removeObject:request];
				}
			}
			[snac release];
		}
	}
	return YES;
}

// queries their personal info, requests a new service,
// and asks for the ICBM parameter info.
// this is called by singonInitialQueries.
- (BOOL)signonRequestServices {
	SNAC * infoRequest = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__NICK_INFO_QUERY)
											flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendRegularSnac:infoRequest]) {
		[infoRequest release];
		return NO;
	}
	[infoRequest release];
	
	// param query
	SNAC * paramQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__PARAMETER_QUERY) 
										   flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendSnacQuery:paramQuery]) {
		[paramQuery release];
		return NO;
	}
	[paramQuery release];
	
	return YES;
}

// sets the ICBM parameters, and enables events.
- (BOOL)signonConfigureICBM {
	NSMutableData * addParameters = [NSMutableData data];
	UInt16 channel = flipUInt16(0);
	UInt32 flags = flipUInt32(8 | 1 | 2 | 0x10 | 0x100); // EVENTS_ALLOWED
	UInt16 maxLen = flipUInt16(8000);
	UInt16 maxSourceEvil = flipUInt16(500);
	UInt16 maxDestEvil = flipUInt16(500);
	UInt32 minInterval = flipUInt32(100); // max miliseconds between IM events.
	[addParameters appendBytes:&channel length:2];
	[addParameters appendBytes:&flags length:4];
	[addParameters appendBytes:&maxLen length:2];
	[addParameters appendBytes:&maxSourceEvil length:2];
	[addParameters appendBytes:&maxDestEvil length:2];
	[addParameters appendBytes:&minInterval length:4];
	SNAC * parametersAdd = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__ADD_PARAMETERS)
											  flags:0 requestID:[AIMSession randomRequestID] data:addParameters];
	if (![session sendRegularSnac:parametersAdd]) {
		[parametersAdd release];
		return NO;
	}
	[parametersAdd release];
	
	return YES;
}

// tells the OSCAR server that the client is ready to be seen online.
// after this, we must immediatly query the feedbag.
+ (BOOL)signonClientOnline:(OSCARConnection *)connection {
	// Create a mutable data for our flags.
	NSMutableData * groupVersions = [NSMutableData data];
	// OSERVICE foodgroup
	UInt16 oservice = flipUInt16(1);
	UInt16 oservice_version = flipUInt16(4);
	UInt16 oservice_tool_id = flipUInt16(41);
	UInt16 oservice_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&oservice length:2];
	[groupVersions appendBytes:&oservice_version length:2];
	[groupVersions appendBytes:&oservice_tool_id length:2];
	[groupVersions appendBytes:&oservice_tool_version length:2];
	// FEEDBAG foodgroup
	UInt16 _feedbag = flipUInt16(19);
	UInt16 feedbag_version = flipUInt16(4);
	UInt16 feedbag_tool_id = flipUInt16(41);
	UInt16 feedbag_tool_version = flipUInt16(4);
	[groupVersions appendBytes:&_feedbag length:2];
	[groupVersions appendBytes:&feedbag_version length:2];
	[groupVersions appendBytes:&feedbag_tool_id length:2];
	[groupVersions appendBytes:&feedbag_tool_version length:2];
	
	// BUDDY foodgroup
	UInt16 buddy = flipUInt16(3);
	UInt16 buddy_version = flipUInt16(1);
	UInt16 buddy_tool_id = flipUInt16(41);
	UInt16 buddy_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&buddy length:2];
	[groupVersions appendBytes:&buddy_version length:2];
	[groupVersions appendBytes:&buddy_tool_id length:2];
	[groupVersions appendBytes:&buddy_tool_version length:2];
	
	// LOCATE foodgroup
	UInt16 locate = flipUInt16(2);
	UInt16 locate_version = flipUInt16(1);
	UInt16 locate_tool_id = flipUInt16(41);
	UInt16 locate_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&locate length:2];
	[groupVersions appendBytes:&locate_version length:2];
	[groupVersions appendBytes:&locate_tool_id length:2];
	[groupVersions appendBytes:&locate_tool_version length:2];
	
	// INVITE foodgroup
	UInt16 invite = flipUInt16(6);
	UInt16 invite_version = flipUInt16(1);
	UInt16 invite_tool_id = flipUInt16(41);
	UInt16 invite_tool_version = flipUInt16(0xAA);
	[groupVersions appendBytes:&invite length:2];
	[groupVersions appendBytes:&invite_version length:2];
	[groupVersions appendBytes:&invite_tool_id length:2];
	[groupVersions appendBytes:&invite_tool_version length:2];
	
	// ICBM foodgroup
	UInt16 icbm = flipUInt16(4);
	UInt16 icbm_version = flipUInt16(1);
	UInt16 icbm_tool_id = flipUInt16(41);
	UInt16 icbm_tool_version = flipUInt16(0xFF);
	[groupVersions appendBytes:&icbm length:2];
	[groupVersions appendBytes:&icbm_version length:2];
	[groupVersions appendBytes:&icbm_tool_id length:2];
	[groupVersions appendBytes:&icbm_tool_version length:2];
	
	// Now we create a SNAC for the OSERVICE.
	SNAC * oservice_s = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__CLIENT_ONLINE)
										   flags:0 requestID:[AIMSession randomRequestID] data:groupVersions];
	FLAPFrame * flap = [connection createFlapChannel:2 data:[oservice_s encodePacket]];
	[oservice_s release];
	if (![connection writeFlap:flap]) {
		return NO;
	}
	
	return YES;
}

- (void)oscarConnectionClosed:(OSCARConnection *)connection {
	[bossConnection release];
	bossConnection = nil;
}

- (void)dealloc {
	// we got an end.
	[bossConnection release];
	[session release];
	[super dealloc];
}

@end

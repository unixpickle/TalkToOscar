//
//  AIMBuddyArt.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBuddyArt.h"


@implementation AIMBuddyArt

@synthesize delegate;
@synthesize ourBuddyIcon;
@synthesize smallBuddyIcon;
@synthesize hasSentOSERVICERequest;
@synthesize bartQueries;
@synthesize cachedUploads;

- (BOOL)isBartAvailable {
	if (bartConnection || bartHost) return YES;
	return NO;
}

- (UInt32)connectToBArt:(AIMSession *)mainSession {
	[_username release];
	_username = [[mainSession loginUsername] retain];
	
	UInt16 oserviceFlip = flipUInt16(SNAC_BART);
	NSData * oserviceFoodgroup = [[NSData alloc] initWithBytes:&oserviceFlip length:2];
	SNAC * oserviceRequest = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__SERVICE_REQUEST)
												flags:0 requestID:[AIMSession randomRequestID] data:oserviceFoodgroup];
	[oserviceFoodgroup release];
	if (![mainSession sendSnacQuery:oserviceRequest]) {
		[oserviceRequest release];
		return 0;
	}
	
	UInt32 requestID = [oserviceRequest requestID];
	[oserviceRequest release];
	hasSentOSERVICERequest = YES;
	return requestID;
}

- (BOOL)gotOserviceResponse:(SNAC *)bartInfo {
	hasSentOSERVICERequest = NO;
	NSArray * tags = [TLV decodeTLVArray:[bartInfo innerContents]];
	for (TLV * responseTag in tags) {
		if ([responseTag type] == TLV_RECONNECT_HERE) {
			[bartHost release];
			bartHost = [[NSString alloc] initWithData:[responseTag tlvData] encoding:NSASCIIStringEncoding];
			NSArray * hostSplit = [bartHost componentsSeparatedByString:@":"];
			if ([hostSplit count] == 2) {
				[bartHost release];
				bartHost = [[hostSplit objectAtIndex:0] retain];
				bartPort = [[hostSplit objectAtIndex:1] intValue];
			} else {
				bartPort = 5190;
			}
		} else if ([responseTag type] == TLV_LOGIN_COOKIE) {
			[loginCookie release];
			loginCookie = [[responseTag tlvData] retain];
		}
	}
	
	if (!loginCookie || !bartHost) {
		return NO;
	}
	
	return [self reconnectToBArt];
}
- (BOOL)reconnectToBArt {
	NSLog(@"Connect to bart: %@:%d", bartHost, bartPort);
	if (!bartHost) return NO;
	bartConnection = [[OSCARConnection alloc] initWithHost:bartHost port:bartPort];
	[bartConnection setDelegate:self];
	NSError * error = nil;
	if (![bartConnection connectToHost:&error]) {
		[bartConnection release];
		bartConnection = nil;
		return NO;
	}
	
	if (![AIMSessionLogin waitForHostReady:bartConnection]) {
		[bartConnection release];
		bartConnection = nil;
		return NO;
	}
	
	if (![AIMSessionLogin sendCookie:loginCookie toConnection:bartConnection]) {
		[bartConnection release];
		bartConnection = nil;
		return NO;
	}
	
	if (![AIMSessionLogin waitOnConnection:bartConnection forSnacID:SNAC_ID_NEW(SNAC_OSERVICE,
																				OSERVICE__HOST_ONLINE)]) {
		[bartConnection release];
		bartConnection = nil;
		return NO;
	}
	
	if (![AIMSessionLogin signonClientOnline:bartConnection]) {
		[bartConnection release];
		bartConnection = nil;
		return NO;
	}
	
	[bartConnection setIsNonBlocking:YES];
	
	// go through cached uploads and requests,
	// sending them needed info.
	if (cachedUploads) {
		for (NSNumber * key in cachedUploads) {
			[self uploadBArtData:[cachedUploads objectForKey:key] forBArtType:[key intValue]];
		}
		self.cachedUploads = nil;
	}
	
	if (bartQueries) {
		for (SNACRequest * request in bartQueries) {
			AIMBArtRequest * bartRequest = request.userInfo;
			[self queryBArtID:[bartRequest bartID] owner:[bartRequest queryUsername]];
		}
		self.bartQueries = nil;
	}
	
	if (requests) [requests release];
	requests = [[NSMutableArray alloc] init];
	
	return YES;
}

- (BOOL)queryBArtID:(ANBArtID *)bartID owner:(NSString *)username {
	if (![bartConnection isOpen]) {
		NSLog(@"Attempted to query even though we are closed.");
		return NO;
	}
	
	
	BArtIDWithName * bid = [BArtIDWithName bartIDWithName:_username bArtID:bartID];
	SNAC * bartQuery = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_BART, BART__DOWNLOAD2) flags:0 
									  requestID:[AIMSession randomRequestID] data:[bid encodePacket]];
	
	SNACRequest * request = [[SNACRequest alloc] initWithSNAC:bartQuery];
	AIMBArtRequest * bartRequest = [[AIMBArtRequest alloc] initWithBartID:bartID username:username];
	request.userInfo = bartRequest;
	
	if (![bartConnection isOpen]) {
		if (!self.bartQueries) {
			self.bartQueries = [NSMutableArray array];
		}
		[self.bartQueries addObject:request];
		[request release];
		[bartRequest release];
		[bartQuery release];
		NSLog(@"Attempted to query even though we are closed.");
		return NO;
	}
	
	[requests addObject:request];
	[bartRequest release];
	[request release];
	
	FLAPFrame * frame = [bartConnection createFlapChannel:2 data:[bartQuery encodePacket]];
	[bartQuery release];
	
	if (![bartConnection writeFlap:frame]) {
		return NO;
	}
	
	return YES;
}
- (BOOL)uploadBArtData:(NSData *)bartData forBArtType:(UInt16)bartType {
	if (![bartConnection isOpen]) {
		if (!cachedUploads) {
			self.cachedUploads = [NSMutableDictionary dictionary];
		}
		[self.cachedUploads setObject:bartData forKey:[NSNumber numberWithInt:bartType]];
		NSLog(@"Attempted to query even though we are closed.");
		return NO;
	}
	
	UInt16 typeFlip = flipUInt16(bartType);
	UInt16 lengthFlip = flipUInt16([bartData length]);
	NSMutableData * uploadData = [[NSMutableData alloc] init];
	[uploadData appendBytes:&typeFlip length:2];
	[uploadData appendBytes:&lengthFlip length:2];
	[uploadData appendData:bartData];
	
	SNAC * bartUpload = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_BART, BART__UPLOAD) flags:0 
									   requestID:[AIMSession randomRequestID] data:uploadData];
	[uploadData release];
	
	FLAPFrame * frame = [bartConnection createFlapChannel:2 data:[bartUpload encodePacket]];
	[bartUpload release];
	
	if (![bartConnection writeFlap:frame]) {
		return NO;
	}
	
	return YES;
}

- (BOOL)setBuddyIcon:(NSData *)iconData {
	self.ourBuddyIcon = iconData;
	return [self uploadBArtData:iconData forBArtType:BUDDY_ICON];
}

- (BOOL)disconnectBArt {
	if (![bartConnection isOpen]) return NO;
	[bartConnection setDelegate:nil];
	[bartConnection disconnect];
	[bartConnection release];
	bartConnection = nil;
	return YES;
}

#pragma mark Connection Delegate

- (void)oscarConnectionClosed:(OSCARConnection *)connection {
	NSLog(@"Bart closed.");
	[bartConnection release];
	bartConnection = nil;
	if ([delegate respondsToSelector:@selector(aimBuddyArtDisconnected:)]) {
		[delegate aimBuddyArtDisconnected:self];
	}
}

- (void)oscarConnectionPacketWaiting:(OSCARConnection *)connection {
	FLAPFrame * flap = [connection readFlap];
	if (!flap) return;
	SNAC * snac = [[SNAC alloc] initWithData:[flap frameData]];
	SNACRequest * request = [requests snacRequestWithID:[snac requestID]];
	if (request) {
		if ([[request userInfo] isKindOfClass:[AIMBArtRequest class]]) {
			if ([delegate respondsToSelector:@selector(aimBuddyArt:fetched:forBArtRequest:)]) {
				BArtReply * reply = [[BArtReply alloc] initWithData:[snac innerContents]];
				NSAssert(reply != nil, @"Received invalid BART response.");
				if (![[reply replyID] wasDownloadSuccess]) {
					if ([delegate respondsToSelector:@selector(aimBuddyArt:bartDownload:failedWithError:)]) {
						[delegate aimBuddyArt:self bartDownload:[request userInfo] failedWithError:[[reply replyID] codeError]];
					}
				} else {
					if ([delegate respondsToSelector:@selector(aimBuddyArt:fetched:forBArtRequest:)]) {
						[delegate aimBuddyArt:self fetched:[reply assetData] forBArtRequest:[request userInfo]];
					}
				}
				[reply release];
			}
		}
		[requests removeObject:request];
	}
	if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BART, BART__DOWNLOAD_REPLY2), [snac snac_id])) {
		NSData * dataLength = [snac innerContents];
		if ([dataLength length] < 1) {
			if ([delegate respondsToSelector:@selector(aimBuddyArt:uploadFailed:)]) {
				NSDictionary * userInfo = [NSDictionary dictionaryWithObject:@"Invalidly short response" forKey:NSLocalizedDescriptionKey];
				[delegate aimBuddyArt:self uploadFailed:[NSError errorWithDomain:@"BArt Upload" code:0 userInfo:userInfo]];
			}
		} else {
			UInt8 code = *(const UInt8 *)[dataLength bytes];
			BArtQueryReplyID * reply = [[BArtQueryReplyID alloc] initWithCode:code];
			if (![reply wasDownloadSuccess]) {
				if ([delegate respondsToSelector:@selector(aimBuddyArt:uploadFailed:)]) {
					[delegate aimBuddyArt:self uploadFailed:[reply codeError]];
				}
				[reply release];
				[snac release];
				return;
			}
			[reply release];
			int newLength = [dataLength length] - 2;
			ANBArtID * bid = [[ANBArtID alloc] initWithPointer:&((const char *)[dataLength bytes])[2] length:&newLength];
			if ([delegate respondsToSelector:@selector(aimBuddyArt:uploadedBArtID:)]) {
				[delegate aimBuddyArt:self uploadedBArtID:bid];
			}
			[bid release];
		}
	}
	[snac release];
}

- (void)dealloc {
	[_username release];
	[bartHost release];
	[loginCookie release];
	if ([bartConnection isOpen]) [self disconnectBArt];
	if (bartConnection) [bartConnection release];
	[requests release];
	self.ourBuddyIcon = nil;
	self.smallBuddyIcon = nil;
	self.cachedUploads = nil;
	self.bartQueries = nil;
	[super dealloc];
}

@end

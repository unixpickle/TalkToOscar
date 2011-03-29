//
//  AIMStatusMessageHandler.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMStatusMessageHandler.h"
#import "AIMSessionHandler.h"

@implementation AIMStatusMessageHandler

@synthesize eventHandler;
@synthesize delegate;
@synthesize userInfo;
 
- (id)initWithEventHandler:(AIMSessionHandler *)_eventHandler {
	if (self = [super init]) {
		eventHandler = _eventHandler;
	}
	return self;
}

#pragma mark Incoming Snacs

- (BOOL)handleLocateResponse:(SNAC *)locateResponse {
	SNACRequest * request = [[[eventHandler session] snacRequests] snacRequestWithID:[locateResponse requestID]];
	if (!request) return NO;
	const char * bytes = [[locateResponse innerContents] bytes];
	int bytesLength = [[locateResponse innerContents] length];
	ANNickWInfo * nickInfo = [[ANNickWInfo alloc] initWithPointer:bytes length:&bytesLength];
	if (!nickInfo) return NO;
	[nickInfo release];
	int remainingLength = [[locateResponse innerContents] length] - bytesLength;
	NSArray * tlvs = [TLV decodeTLVArray:[NSData dataWithBytes:&bytes[bytesLength] length:remainingLength]];
	if (!tlvs) return NO;
	
	NSData * unavailableData = nil;
	for (TLV * locateTag in tlvs) {
		if ([locateTag type] == TLV_UNAVAILABLE_DATA) {
			unavailableData = [locateTag tlvData];
		}
	}
	
	if (!unavailableData) return NO;
	
	NSString * messageString = [[NSString alloc] initWithData:unavailableData encoding:NSUTF8StringEncoding];
	AIMBuddyStatus * statusMessage = [[AIMBuddyStatus alloc] initWithMessage:messageString type:kAIMBuddyStatusTypeAway];
	AIMBuddy * buddy = [request userInfo];
	[buddy setBuddyStatus:statusMessage];
	
	if ([delegate respondsToSelector:@selector(statusMessageHandler:gotBuddyStatus:)]) {
		[delegate statusMessageHandler:self gotBuddyStatus:buddy];
	}
	
	[statusMessage release];
	[messageString release];
	
	return YES;
}

- (BOOL)handleBuddyArrived:(ANNickWInfo *)_buddy {
	AIMBuddy * buddy = [[[eventHandler feedbagHandler] buddyList] buddyWithName:[_buddy username]];
	if (buddy) {
		ANNickWInfo * _buddyCopy = [_buddy copy];
		if ([buddy nickInfo]) [_buddyCopy copyBartIDsFromInfo:[buddy nickInfo]];
		[buddy setNickInfo:_buddyCopy];
		[_buddyCopy release];
		if (![self queryBuddyStatusMessage:buddy]) {
			return NO;
		}
		return YES;
	}
	return NO;
}

- (BOOL)handleBuddyDeparted:(ANNickWInfo *)_buddy {
	AIMBuddy * buddy = [[[eventHandler feedbagHandler] buddyList] buddyWithName:[_buddy username]];
	if (buddy) {
		AIMBuddyStatus * offlineStatus = [[AIMBuddyStatus alloc] initWithMessage:nil type:kAIMBuddyStatusTypeOffline];
		ANNickWInfo * _buddyCopy = [_buddy copy];
		if ([buddy nickInfo]) [_buddyCopy copyBartIDsFromInfo:[buddy nickInfo]];
		[buddy setNickInfo:_buddyCopy];
		[buddy setBuddyStatus:offlineStatus];
		[offlineStatus release];
		[_buddyCopy release];
		if ([delegate respondsToSelector:@selector(statusMessageHandler:gotBuddyStatus:)]) {
			[delegate statusMessageHandler:self gotBuddyStatus:buddy];
		}
	} else return NO;
	return YES;
}

#pragma mark Our Status Message

- (BOOL)setBuddyStatus:(AIMBuddyStatus *)status {
	if ([status statusType] == kAIMBuddyStatusTypeAway) {
		return [self setUnavailableMessage:[status statusMessage]];
	} else if ([status statusType] == kAIMBuddyStatusTypeOnline)
		return [self setStatusMessage:[status statusMessage]];
	else [[eventHandler session] signOffline];
	return YES;
}

- (BOOL)setUnavailableMessage:(NSString *)message {
	TLV * awayData = [[TLV alloc] initWithType:TLV_UNAVAILABLE_DATA data:[message dataUsingEncoding:NSUTF8StringEncoding]];
	NSData * encodedData = [awayData encodePacket];
	[awayData release];
	SNAC * setStatus = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_LOCATE, LOCATE__SET_INFO)
										  flags:0 requestID:[AIMSession randomRequestID] data:encodedData];
	if (![[eventHandler session] sendRegularSnac:setStatus]) {
		[setStatus release];
		return NO;
	}
	[setStatus release];
	return YES;
}

- (BOOL)setStatusMessage:(NSString *)regularStatus {
	// clear the away field.
	[self setUnavailableMessage:nil];
	
	ANBArtID * statusStr = [[ANBArtID alloc] init];
	statusStr.flags = 4; // DATA IS DIRECTLY IN BART_ID
	statusStr.type = STATUS_STR;
	statusStr.opaqueData = encodeString16(regularStatus);
	statusStr.length = [[statusStr opaqueData] length];
	
	NSMutableData * bartIDs = [[NSMutableData alloc] init];
	NSArray * barts = [userInfo bartIDs];
	
	for (ANBArtID * bid in barts) {
		if ([bid type] != STATUS_STR) {
			[bartIDs appendData:[bid encodePacket]];
		}
	}
	
	[bartIDs appendData:[statusStr encodePacket]];
	
	TLV * bartIDPacket = [[TLV alloc] initWithType:TLV_BART_INFO data:bartIDs];
	[statusStr release];
	[bartIDs release];
	
	SNAC * setFields = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__SET_NICKINFO_FIELDS)
										  flags:0 requestID:[AIMSession randomRequestID] data:[bartIDPacket encodePacket]];
	[bartIDPacket release];
	
	if (![[eventHandler session] sendRegularSnac:setFields]) {
		[setFields release];
		return NO;
	}
	[setFields release];
	return YES;
}

#pragma mark Searches

- (BOOL)queryBuddyStatusMessage:(AIMBuddy *)buddy {
	UInt16 flags = [[buddy nickInfo] nickFlags];
	UInt16 isAway = flags & NICKFLAGS_UNAVAILABLE;
	if (isAway != 0) {
		NSMutableData * locateQuery = [[NSMutableData alloc] init];
		UInt32 queryKind = flipUInt32(2); // UNAVAILABLE_MESSAGE
		[locateQuery appendBytes:&queryKind length:4];
		[locateQuery appendData:encodeString8([buddy username])];
		SNAC * locateSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_LOCATE, LOCATE__USER_INFO_QUERY2)
											   flags:0 requestID:[AIMSession randomRequestID] data:locateQuery];
		[locateQuery release];
		if (![[eventHandler session] sendSnacQuery:locateSnac]) {
			[locateSnac release];
			return NO;
		}
		SNACRequest * request = [[[eventHandler session] snacRequests] snacRequestWithID:[locateSnac requestID]];
		if (!request) {
			[locateSnac release];
			return NO;
		}
		[request setUserInfo:buddy];
		[locateSnac release];
		return YES;
	} else {
		ANBArtID * status = [[buddy nickInfo] extractStatus];
		if (!status) {
			AIMBuddyStatus * buddyStatus = [[AIMBuddyStatus alloc] initWithMessage:@"" type:kAIMBuddyStatusTypeOnline];
			[buddy setBuddyStatus:buddyStatus];
			[buddyStatus release];
			if ([delegate respondsToSelector:@selector(statusMessageHandler:gotBuddyStatus:)]) {
				[delegate statusMessageHandler:self gotBuddyStatus:buddy];
			}
			return YES;
		}
		NSString * contents = decodeString16([status opaqueData]);
		AIMBuddyStatus * buddyStatus = [[AIMBuddyStatus alloc] initWithMessage:contents type:kAIMBuddyStatusTypeOnline];
		[buddy setBuddyStatus:buddyStatus];
		[buddyStatus release];
		
		if ([delegate respondsToSelector:@selector(statusMessageHandler:gotBuddyStatus:)]) {
			[delegate statusMessageHandler:self gotBuddyStatus:buddy];
		}
		return YES;
	}
	return NO;
}

- (BOOL)handleUserInfo:(SNAC *)_userInfo {
	ANNickWInfo * newInfo = [[ANNickWInfo alloc] initWithData:[_userInfo innerContents]];
	if (!newInfo) return NO;
	if (userInfo) {
		[newInfo copyAttributesFromInfo:userInfo];
	}
	[userInfo release];
	userInfo = newInfo;
	return YES;
}

- (void)dealloc {
	self.delegate = nil;
	self.userInfo = nil;
	[super dealloc];
}

@end

//
//  AIMSessionEventHandler.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSessionHandler.h"


@implementation AIMSessionHandler

@synthesize delegate;
@synthesize feedbagHandler;
@synthesize statusHandler;
@synthesize buddyArt;
@synthesize session;

- (id)initWithSession:(AIMSession *)_session {
	if ((self = [super init])) {
		session = [_session retain];
		feedbagHandler = [[AIMSessionFeedbagHandler alloc] initWithSession:session];
		statusHandler = [[AIMStatusMessageHandler alloc] initWithEventHandler:self];
		[feedbagHandler setDelegate:self];
		[statusHandler setDelegate:self];
	}
	return self;
}

- (BOOL)connectToBART {
	buddyArt = [[AIMBuddyArt alloc] init];
	[buddyArt setDelegate:self];
	bartRequestID = [buddyArt connectToBArt:session];
	return YES;
}

- (BOOL)retrieveOfflineMessages {
	SNAC * requestSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__OFFLINE_RETRIEVE)
											flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendRegularSnac:requestSnac]) {
		[requestSnac release];
		return NO;
	}
	[requestSnac release];
	return YES;
}

- (AIMBuddy *)buddyWithUsername:(NSString *)username {
	AIMBuddy * buddy = [[feedbagHandler buddyList] buddyWithName:username];
	if (buddy) return buddy;
	return [AIMBuddy buddyWithUsername:username];
}

- (void)handleSessionSnac:(SNAC *)snac {
	if ([snac requestID] == bartRequestID) {
		if (![buddyArt gotOserviceResponse:snac]) {
			[session signOffline];
			[buddyArt disconnectBArt];
			[buddyArt release];
			[feedbagHandler release];
			feedbagHandler = nil;
			buddyArt = nil;
			return;
		}
	}
	if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_ICBM, ICBM__CHANNEL_MSG_TOCLIENT))) {
		ANICBMMessage * message = [[ANICBMMessage alloc] initWithIncomingSnac:snac];
		AIMMessage * delegateMessage = [[AIMMessage alloc] initWithMessage:[message message] 
																	 buddy:[self buddyWithUsername:[[message sender] username]]];
		
		if ([delegate respondsToSelector:@selector(aimSessionHandler:receivedMessage:)]) {
			[delegate aimSessionHandler:self receivedMessage:delegateMessage];
		}
		
		[message release];
		[delegateMessage release];
	} else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_ICBM, ICBM__CLIENT_EVENT))) {
		ANICBMEvent * event = [[ANICBMEvent alloc] initWithIncomingSnac:snac];
		UInt16 eventType = kTypingEventStart;
		if ([event eventType] == ICBM_EVENT_NONE) eventType = kTypingEventStop;
		else if ([event eventType] == ICBM_EVENT_CLOSED) eventType = kTypingEventWindowClosed;
		if ([delegate respondsToSelector:@selector(aimSessionHandler:receivedEvent:fromBuddy:)]) {
			[delegate aimSessionHandler:self receivedEvent:eventType fromBuddy:[self buddyWithUsername:[event username]]];
		}
		[event release];
	} else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_ICBM, ICBM__ERROR))) {
		NSData * data = [snac innerContents];
		if ([data length] < 2) {
			if ([delegate respondsToSelector:@selector(aimSessionHandler:didGetMessageSendingError:)]) {
				[delegate aimSessionHandler:self didGetMessageSendingError:[NSError errorWithDomain:@"ICBM Error" code:0 userInfo:nil]];
			}
		} else {
			UInt16 errorCode = flipUInt16(*((const UInt16 *)[data bytes]));
			NSData * tlvBytes = [NSData dataWithBytes:&((const char *)[data bytes])[2] length:([data length] - 2)];
			NSString * errorMsg = nil;
			if ([tlvBytes length] > 0) {
				NSArray * tlvTags = [TLV decodeTLVArray:tlvBytes];
				for (TLV * t in tlvTags) {
					if (t.type == TLV_ERROR_TEXT) {
						errorMsg = [[[NSString alloc] initWithData:[t tlvData] encoding:NSUTF8StringEncoding] autorelease];
					}
				}
			}
			
			NSDictionary * errorOptions = nil;
			if (errorMsg) errorOptions = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
			NSError * error = [[NSError alloc] initWithDomain:@"ICBM Error" code:errorCode userInfo:errorOptions];
			if ([delegate respondsToSelector:@selector(aimSessionHandler:didGetMessageSendingError:)]) {
				[delegate aimSessionHandler:self didGetMessageSendingError:error];
			}
			
			[error release];
		}
	} else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_BUDDY, BUDDY__ARRIVED))) {
		NSArray * nicks = [ANNickWInfo decodeArray:[snac innerContents]];
		if (nicks) {
			for (ANNickWInfo * buddy in nicks) {
				if (![buddy nickFlags]) {
					// they departed.
					[self handleNickDeparted:buddy];
				} else [self handleNickArrived:buddy];
			}
		}
	} else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_BUDDY, BUDDY__DEPARTED))) {
		NSArray * nicks = [ANNickWInfo decodeArray:[snac innerContents]];
		if (nicks) {
			for (ANNickWInfo * buddy in nicks) {
				[self handleNickDeparted:buddy];
			}
		}
	} else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_LOCATE, LOCATE__USER_INFO_REPLY))) {
		[statusHandler handleLocateResponse:snac];
	} else if ([snac snac_id].foodgroup == SNAC_FEEDBAG) {
		switch ([snac snac_id].type) {
			case FEEDBAG__REPLY:
				[feedbagHandler handleFeedbagResponse:snac];
				break;
			case FEEDBAG__START_CLUSTER:
				[feedbagHandler handleFeedbagModification:snac];
				break;
			case FEEDBAG__END_CLUSTER:
				[feedbagHandler handleFeedbagModification:snac];
				break;
			case FEEDBAG__INSERT_ITEMS:
				[feedbagHandler handleFeedbagModification:snac];
				break;
			case FEEDBAG__UPDATE_ITEMS:
				[feedbagHandler handleFeedbagModification:snac];
				break;
			case FEEDBAG__DELETE_ITEMS:
				[feedbagHandler handleFeedbagModification:snac];
				break;
			case FEEDBAG__STATUS:
				if (![feedbagHandler performNextTransaction:snac]) {
					NSLog(@"TODO: handle feedbag transaction failed.");
				}
				break;
		}
	} else if (SNAC_ID_IS_EQUAL([snac snac_id], SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__NICK_INFO_UPDATE))) {
		[statusHandler handleUserInfo:snac];
		ANBArtID * icon = [statusHandler.userInfo extractIcon];
		if (icon) {
			[buddyArt queryBArtID:icon owner:[session loginUsername]];
		} else {
			buddyArt.ourBuddyIcon = nil;
			if ([delegate respondsToSelector:@selector(aimSessionHandler:didGetOurIcon:)]) {
				[delegate aimSessionHandler:self didGetOurIcon:nil];
			}
		}
	}
	
	SNACRequest * request = [[session snacRequests] snacRequestWithID:[snac requestID]];
	if (request) {
		if ([snac isLastResponse]) {
			[[session snacRequests] removeObject:request];
		}
	}
}
- (void)handleNickDeparted:(ANNickWInfo *)nickInfo {
	// they are clearly offline.
	[statusHandler handleBuddyDeparted:nickInfo];
}
- (void)handleNickArrived:(ANNickWInfo *)nickInfo {
	// they are online, we need to query their status.
	[statusHandler handleBuddyArrived:nickInfo];
}

- (BOOL)setIdleTime:(UInt16)idleTime {
	UInt32 flipTime = flipUInt32(idleTime);
	NSData * idleData = [[NSData alloc] initWithBytes:&flipTime length:4];
	SNAC * setIdle = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_OSERVICE, OSERVICE__IDLE_NOTIFICATION)
										flags:0 requestID:[AIMSession randomRequestID] data:idleData];
	[idleData release];
	if (![session sendRegularSnac:setIdle]) {
		[setIdle release];
		return NO;
	}
	[setIdle release];
	return YES;
}
			   
#pragma mark Feedbag Handler

- (void)feedbagHandlerDidGetFeedbag:(AIMSessionFeedbagHandler *)handler {
	// we gotta acknowelege it.
	if (!buddyArt) {
		[self connectToBART];
	}
	
	[feedbagHandler sendFeedbagUse];
	
	if ([buddyArt isBartAvailable]) {
		[buddyArt setBuddyIcon:buddyArt.ourBuddyIcon];
	}
	
	if ([delegate respondsToSelector:@selector(aimSessionHandlerGotBuddyList:)]) {
		[delegate aimSessionHandlerGotBuddyList:self];
	}
}

- (void)feedbagHandler:(AIMSessionFeedbagHandler *)handler feedbagOperationFailed:(AIMFeedbagOperation *)operation {
	if ([delegate respondsToSelector:@selector(aimSessionHandler:feedbagOperationFailed:)]) {
		[delegate aimSessionHandler:self feedbagOperationFailed:operation];
	}
}

- (void)statusMessageHandler:(AIMStatusMessageHandler *)handler gotBuddyStatus:(AIMBuddy *)buddy {
	if ([buddy buddyStatus].statusType == kAIMBuddyStatusTypeOffline) {
		if ([delegate respondsToSelector:@selector(aimSessionHandler:buddyOffline:)]) {
			[delegate aimSessionHandler:self buddyOffline:buddy];
		}
	} else {
		if ([delegate respondsToSelector:@selector(aimSessionHandler:buddyOnline:)]) {
			[delegate aimSessionHandler:self buddyOnline:buddy];
		}
	}
	if ([buddyArt isBartAvailable]) {
		ANBArtID * buddyIcon = [[buddy nickInfo] extractIcon];
		if (buddyIcon) {
			if (![buddyArt queryBArtID:buddyIcon owner:[buddy username]]) {
				NSLog(@"Icon request failed.");
			}
		}
	}
}

#pragma mark BART

- (void)aimBuddyArt:(AIMBuddyArt *)_buddyArt fetched:(NSData *)bartData forBArtRequest:(AIMBArtRequest *)bartRequest {
	if ([bartRequest bartID].type == BUDDY_ICON) {
		if ([[bartRequest queryUsername] isEqual:[session loginUsername]]) {
			buddyArt.ourBuddyIcon = bartData;
			if ([delegate respondsToSelector:@selector(aimSessionHandler:didGetOurIcon:)]) {
				[delegate aimSessionHandler:self didGetOurIcon:buddyArt.ourBuddyIcon];
			}
		}
		AIMBuddy * buddy = [[feedbagHandler buddyList] buddyWithName:[bartRequest queryUsername]];
		if (!buddy) return;
		buddy.iconData = bartData;
		if ([delegate respondsToSelector:@selector(aimSessionHandler:buddyChangedIcon:)]) {
			[delegate aimSessionHandler:self buddyChangedIcon:buddy];
		}
	}
}

- (void)dealloc {
	[session release];
	[feedbagHandler release];
	self.delegate = nil;
	[super dealloc];
}

@end

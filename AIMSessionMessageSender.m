//
//  AIMSessionMessageSender.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSessionMessageSender.h"


@implementation AIMSessionMessageSender

- (id)initWithSession:(AIMSession *)_session {
	if (self = [super init]) {
		session = [_session retain];
	}
	return self;
}

- (BOOL)sendMessage:(AIMMessage *)message {
	NSString * username = [[message buddy] username];
	
	ANICBMMessage * sendMessage = [[ANICBMMessage alloc] initWithMessage:message.message to:username];
	NSData * snacData = [sendMessage encodeOutgoingMessage];
	// create and send the snac here.
	SNAC * msg = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__CHANNEL_MSG_TOHOST)
									flags:0 requestID:[AIMSession randomRequestID] data:snacData];
	[sendMessage release];
	if (![session sendRegularSnac:msg]) {
		[msg release];
		return NO;
	}
	
	[msg release];
	
	return YES;
}
- (BOOL)sendEvent:(UInt16)eventType toBuddy:(id)buddy {
	NSAssert([buddy isKindOfClass:[AIMBuddy class]] || [buddy isKindOfClass:[NSString class]], @"Invalid class used for message sending.");
	NSString * username;
	if ([buddy isKindOfClass:[NSString class]]) username = buddy;
	else username = [(AIMBuddy *)buddy username];
	
	UInt16 meventType = ICBM_EVENT_NONE;
	if (eventType == kTypingEventStart) meventType = ICBM_EVENT_TYPING;
	else if (eventType == kTypingEventWindowClosed) meventType = ICBM_EVENT_CLOSED;
	ANICBMEvent * sendEvent = [[ANICBMEvent alloc] initWithEventType:meventType
																toUser:username];
	NSData * snacData = [sendEvent encodeOutgoingEvent];
	// create and send the snac here.
	SNAC * msg = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_ICBM, ICBM__CLIENT_EVENT)
									flags:0 requestID:[AIMSession randomRequestID] data:snacData];
	[sendEvent release];
	if (![session sendRegularSnac:msg]) {
		[msg release];
		return NO;
	}
	
	[msg release];
	
	return YES;
}

- (void)dealloc {
	[session release];
	[super dealloc];
}

@end

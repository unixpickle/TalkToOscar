//
//  MainClass.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainClass.h"


@implementation MainClass

- (void)main {
	NSAssert(NO, @"Please put your username and password in MainClass.m");
	session = [[AIMSession alloc] initWithScreenname:@"AIM_USERNAME" password:@"AIM_PASSWORD"];
	[session setDelegate:self];
	[session signOnline];
}

- (void)aimSession:(AIMSession *)_session signonFailed:(NSError *)error {
	NSLog(@"Failed: %@", error);
}

- (void)aimSessionSignedOn:(AIMSession *)_session {
	NSLog(@"Online.");
	messageSender = [[AIMSessionMessageSender alloc] initWithSession:_session];
	sessionEvents = [[AIMSessionHandler alloc] initWithSession:_session];
	[sessionEvents setDelegate:self];
}

- (void)aimSession:(AIMSession *)_session gotSnac:(SNAC *)snac {
	[sessionEvents handleSessionSnac:snac];
}

- (void)aimSessionSignedOff:(AIMSession *)_session {
	NSLog(@"Offline.");
	[self release];
}

#pragma mark Events

- (void)aimSessionHandler:(AIMSessionHandler *)handler buddyOffline:(AIMBuddy *)buddy {
	NSLog(@"%@ - offline", [buddy username]);
}

- (void)aimSessionHandler:(AIMSessionHandler *)handler buddyOnline:(AIMBuddy *)buddy {
	NSLog(@"%@ - online", [buddy username]);
	NSLog(@"%@ has been idle for %d minutes.", [buddy username], [buddy idleMinutes]);
}

- (void)aimSessionHandler:(AIMSessionHandler *)handler receivedEvent:(UInt16)event fromBuddy:(AIMBuddy *)buddy {
	if (event == kTypingEventStart) {
		NSLog(@"%@ is typing", buddy);
	} else if (event == kTypingEventStop) {
		NSLog(@"%@ stopped typing", buddy);
	} else if (event == kTypingEventWindowClosed) {
		NSLog(@"%@ closed the window", buddy);
	}
}

- (void)aimSessionHandler:(AIMSessionHandler *)handler receivedMessage:(AIMMessage *)message {
	NSString * realMessage = [[message message] stringByRemovingAOLRTF];
	NSLog(@"%@: %@", [[message buddy] username], realMessage);
	if ([realMessage hasPrefix:@"add "]) {
		NSString * buddyName = [realMessage substringFromIndex:4];
		if (![[[handler feedbagHandler] buddyList] buddyWithName:buddyName]) {
			[[handler feedbagHandler] addBuddy:[AIMBuddy buddyWithUsername:buddyName]
									   toGroup:[[[handler feedbagHandler] buddyList] groupWithName:@"Buddies"]];
		}
	} else if ([realMessage hasPrefix:@"remove "]) {
		NSString * buddyName = [realMessage substringFromIndex:7];
		if ([[[handler feedbagHandler] buddyList] buddyWithName:buddyName]) {
			[[handler feedbagHandler] removeBuddy:[[[handler feedbagHandler] buddyList] buddyWithName:buddyName]];
		}
	} else if ([realMessage hasPrefix:@"addgroup "]) {
		NSString * groupName = [realMessage substringFromIndex:9];
		if (![[[handler feedbagHandler] buddyList] groupWithName:groupName]) {
			[[handler feedbagHandler] addGroup:[AIMGroup groupWithName:groupName]];
		}
	} else if ([realMessage hasPrefix:@"removegroup "]) {
		NSString * groupName = [realMessage substringFromIndex:12];
		if ([[[handler feedbagHandler] buddyList] groupWithName:groupName]) {
			[[handler feedbagHandler] removeGroup:[[[handler feedbagHandler] buddyList] groupWithName:groupName]];
		}
	} else if ([realMessage hasPrefix:@"block "]) {
		NSString * buddyName = [realMessage substringFromIndex:6];
		if (![[[[handler feedbagHandler] buddyList] denyList] containsObject:buddyName]) {
			[[handler feedbagHandler] addDenyUser:buddyName];
		}
	} else if ([realMessage hasPrefix:@"unblock "]) {
		NSString * buddyName = [realMessage substringFromIndex:8];
		if ([[[[handler feedbagHandler] buddyList] denyList] containsObject:buddyName]) {
			[[handler feedbagHandler] removeDenyUser:buddyName];
		}
	} else if ([realMessage isEqual:@"takeicon"]) {
		[[handler buddyArt] setBuddyIcon:[[message buddy] iconData]];
	} else if ([realMessage isEqual:@"bye"]) {
		[session signOffline];
	} else if ([realMessage isEqual:@"buddylist"]) {
		NSString * blist = [NSString stringWithFormat:@"%@", [[handler feedbagHandler] buddyList]];
		AIMMessage * buddyList = [[AIMMessage alloc] initWithMessage:blist buddy:[message buddy]];
		[messageSender sendMessage:buddyList];
		[buddyList release];
	} else if ([realMessage hasPrefix:@"setstatus "]) {
		NSString * status = [realMessage substringFromIndex:10];
		[[handler statusHandler] setBuddyStatus:[[[AIMBuddyStatus alloc] initWithMessage:status type:kAIMBuddyStatusTypeOnline] autorelease]];
	}
	
	NSString * addedMsg = [NSString stringWithFormat:@"Why do you say %@?", realMessage];
	AIMMessage * sendMsg = [[AIMMessage alloc] initWithMessage:addedMsg buddy:[message buddy]];
	[messageSender sendMessage:sendMsg];
	[sendMsg release];
}

- (void)aimSessionHandlerGotBuddyList:(AIMSessionHandler *)handler {
	NSLog(@"BLIST: %@", [[handler feedbagHandler] buddyList]);
	if ([[[handler feedbagHandler] buddyList] pdMode] != PD_DENY_SOME) {
		[[handler feedbagHandler] setPDMode:PD_DENY_SOME];
	}
}

- (void)aimSessionHandler:(AIMSessionHandler *)handler didGetMessageSendingError:(NSError *)icbmError {
	NSLog(@"Got a message error: %@", icbmError);
}

- (void)aimSessionHandler:(AIMSessionHandler *)handler buddyChangedIcon:(AIMBuddy *)buddy {
	NSString * ext = @"jpg";
	const char * bytes = [[buddy iconData] bytes];
	if ([[buddy iconData] length] > 3) {
		if (memcmp(bytes, "GIF", 3) == 0) {
			ext = @"gif";
		} else if (memcmp(bytes, "BM", 2) == 0) {
			ext = @"bmp";
		}
	}
	NSString * path = [NSString stringWithFormat:@"%@/Desktop/buddyicons/%@.%@", NSHomeDirectory(), [buddy username], ext];
	[[buddy iconData] writeToFile:path atomically:YES];
}

- (void)aimSessionHandler:(AIMSessionHandler *)handler didGetOurIcon:(NSData *)iconData {
	NSLog(@"Got our icon: %p", iconData);
	[iconData writeToFile:[NSString stringWithFormat:@"%@/Desktop/ouricon.jpg", NSHomeDirectory()]
			   atomically:YES];
}

- (void)dealloc {
	[session release];
	[messageSender release];
	[sessionEvents release];
	[super dealloc];
	exit(-1);
}

@end

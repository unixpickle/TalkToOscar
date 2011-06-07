//
//  MainClass.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainClass.h"


static NSString * readLine (FILE * fp) {
	NSMutableString * buffer = [[NSMutableString alloc] init];
	int character = 0;
	while ((character = fgetc(fp)) != EOF) {
		if (character == '\n') break;
		else {
			[buffer appendFormat:@"%c", character];
		}
	}
	return [buffer autorelease];
}

@implementation MainClass

- (void)main {
	// NSAssert(NO, @"Please put your username and password in MainClass.m");
	
	printf("Enter your AIM username: ");
	NSString * username = readLine(stdin);
	printf("Enter your AIM password: ");
	NSString * password = readLine(stdin);
	
	session = [[AIMSession alloc] initWithScreenname:username password:password];
	[session setDelegate:self];
	[session signOnline];
}

- (void)sendMessage:(NSString *)msg toBuddy:(AIMBuddy *)buddy {
	AIMMessage * message = [[AIMMessage alloc] initWithMessage:msg buddy:buddy];
	[messageSender sendMessage:message];
	[message release];
}

- (void)aimSession:(AIMSession *)_session signonFailed:(NSError *)error {
	NSLog(@"Failed: %@", error);
}

- (void)aimSessionSignedOn:(AIMSession *)_session {
	NSLog(@"Online.");
	messageSender = [[AIMSessionMessageSender alloc] initWithSession:_session];
	sessionEvents = [[AIMSessionHandler alloc] initWithSession:_session];
	[sessionEvents setDelegate:self];
	[sessionEvents retrieveOfflineMessages];
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
	// NSLog(@"%@ - offline", [buddy username]);
}

- (void)aimSessionHandler:(AIMSessionHandler *)handler buddyOnline:(AIMBuddy *)buddy {
	// NSLog(@"%@ - online", [buddy username]);
	// NSLog(@"%@ has been idle for %d minutes.", [buddy username], [buddy idleMinutes]);
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
	if ([[[message buddy] username] isEqual:@"allstar61997"]) {
		[messageSender sendMessage:message];
	} else return;
	NSString * realMessage = [[message message] stringByRemovingAOLRTF];
	NSLog(@"%@: %@", [[message buddy] username], realMessage);
	if ([realMessage hasPrefix:@"add "]) {
		NSString * buddyName = [realMessage substringFromIndex:4];
		if (![[[handler feedbagHandler] buddyList] buddyWithName:buddyName]) {
			[feedbagOperator addBuddy:[AIMBuddy buddyWithUsername:buddyName]
									   toGroup:[[[handler feedbagHandler] buddyList] groupWithName:@"Buddies"]];
			[self sendMessage:@"Buddy added." toBuddy:[message buddy]];
		} else {
			[self sendMessage:@"Buddy already exists on the buddy list." toBuddy:[message buddy]];
		}
	} else if ([realMessage hasPrefix:@"remove "]) {
		NSString * buddyName = [realMessage substringFromIndex:7];
		if ([[[handler feedbagHandler] buddyList] buddyWithName:buddyName]) {
			[feedbagOperator removeBuddy:[[[handler feedbagHandler] buddyList] buddyWithName:buddyName]];
			[self sendMessage:@"Buddy removed." toBuddy:[message buddy]];
		} else {
			[self sendMessage:@"Buddy is not currently on the buddy list." toBuddy:[message buddy]];
		}
	} else if ([realMessage hasPrefix:@"addgroup "]) {
		NSString * groupName = [realMessage substringFromIndex:9];
		if (![[[handler feedbagHandler] buddyList] groupWithName:groupName]) {
			[feedbagOperator addGroup:[AIMGroup groupWithName:groupName]];
			[self sendMessage:@"Group added." toBuddy:[message buddy]];
		} else {
			[self sendMessage:@"The group exists, cannot be added." toBuddy:[message buddy]];
		}
	} else if ([realMessage hasPrefix:@"removegroup "]) {
		NSString * groupName = [realMessage substringFromIndex:12];
		if ([[[handler feedbagHandler] buddyList] groupWithName:groupName]) {
			[feedbagOperator removeGroup:[[[handler feedbagHandler] buddyList] groupWithName:groupName]];
			[self sendMessage:@"Group removed." toBuddy:[message buddy]];
		} else {
			[self sendMessage:@"The group doesn't exist, and cannot be removed." toBuddy:[message buddy]];
		}
	} else if ([realMessage hasPrefix:@"block "]) {
		NSString * buddyName = [realMessage substringFromIndex:6];
		if (![[[[handler feedbagHandler] buddyList] denyList] containsObject:buddyName]) {
			[feedbagOperator addDenyUser:buddyName];
			[self sendMessage:@"User successfully blocked." toBuddy:[message buddy]];
		} else {
			[self sendMessage:@"User is already blocked." toBuddy:[message buddy]];
		}
	} else if ([realMessage hasPrefix:@"unblock "]) {
		NSString * buddyName = [realMessage substringFromIndex:8];
		if ([[[[handler feedbagHandler] buddyList] denyList] containsObject:buddyName]) {
			[feedbagOperator removeDenyUser:buddyName];
			[self sendMessage:@"The user was unblocked." toBuddy:[message buddy]];
		} else {
			[self sendMessage:@"Specified user is not currently blocked." toBuddy:[message buddy]];
		}
	} else if ([realMessage isEqual:@"takeicon"]) {
		if ([[message buddy] iconData]) {
			[[handler buddyArt] setBuddyIcon:[[message buddy] iconData]];
			[self sendMessage:@"Icon taken successfully." toBuddy:[message buddy]];
		} else {
			[self sendMessage:@"Cannot take your icon, probably because you are not on the buddy list." toBuddy:[message buddy]];
		}
	} else if ([realMessage isEqual:@"screw you"]) {
		[session signOffline];
	} else if ([realMessage isEqual:@"buddylist"]) {
		NSString * blist = [NSString stringWithFormat:@"%@", [[handler feedbagHandler] buddyList]];
		AIMMessage * buddyList = [[AIMMessage alloc] initWithMessage:[blist stringByFormattingWithAOLRTF] buddy:[message buddy]];
		[messageSender sendMessage:buddyList];
		[buddyList release];
	} else if ([realMessage hasPrefix:@"setstatus "]) {
		NSString * status = [realMessage substringFromIndex:10];
		[[handler statusHandler] setBuddyStatus:[[[AIMBuddyStatus alloc] initWithMessage:status type:kAIMBuddyStatusTypeOnline] autorelease]];
		[self sendMessage:@"Set status complete." toBuddy:[message buddy]];
	} else if ([realMessage isEqual:@"typespam"]) {
		[messageSender sendMessage:message];
		for (int i = 0; i < 5; i++) { // should block for 5 seconds at least
			[messageSender sendEvent:kTypingEventStart toBuddy:[message buddy]];
			[messageSender sendEvent:kTypingEventStop toBuddy:[message buddy]];
		}
		[self sendMessage:@"Typespam completed (successfully)." toBuddy:[message buddy]];
	} else if ([realMessage hasPrefix:@"echo "]) {
		NSString * echoMsg = [realMessage substringFromIndex:5];
		[self sendMessage:echoMsg toBuddy:[message buddy]];
	} else if ([realMessage hasPrefix:@"blocked"]) {
		NSString * blockList = [NSString stringWithFormat:@"%@", [[[handler feedbagHandler] buddyList] denyList]];
		AIMMessage * listMsg = [[AIMMessage alloc] initWithMessage:[blockList stringByFormattingWithAOLRTF] buddy:[message buddy]];
		[messageSender sendMessage:listMsg];
		[listMsg release];
	} else if ([realMessage hasPrefix:@"ping "]) {
		NSString * buddy = [realMessage substringFromIndex:5];
		NSString * personalMessage = nil;
		if ([buddy rangeOfString:@" "].location != NSNotFound) {
			personalMessage = [buddy substringFromIndex:[buddy rangeOfString:@" "].location + 1];
			buddy = [buddy substringWithRange:NSMakeRange(0, [buddy rangeOfString:@" "].location)];
		}
		AIMBuddy * buddyObj = [AIMBuddy buddyWithUsername:buddy];
		if (!personalMessage) {
			[self sendMessage:@"You are receiving this message because somebody pinged you.  Please respond with either an echo command, or a math equation." toBuddy:buddyObj];
		} else {
			[self sendMessage:personalMessage toBuddy:buddyObj];
		}
	} else {
		@try {
			float answer = [realMessage parsedExpression];
			NSString * msgString = [NSString stringWithFormat:@"%@ = %f", realMessage, answer];
			[self sendMessage:msgString toBuddy:[message buddy]];
		} @catch (NSException * ex) {
			NSLog(@"Invalid expression: %@", realMessage);
		}
	}
}

- (void)aimSessionHandlerGotBuddyList:(AIMSessionHandler *)handler {
	NSLog(@"BLIST: %@", [[handler feedbagHandler] buddyList]);
	if ([[[handler feedbagHandler] buddyList] pdMode] != PD_DENY_SOME) {
		[[handler feedbagHandler] setPDMode:PD_DENY_SOME];
	}
	if (!hasSentInitial) {
		AIMMessage * message = [[AIMMessage alloc] initWithMessage:@"I am a bot, IM me a math problem for some fun." buddy:[AIMBuddy buddyWithUsername:@"alexqnichol"]];
		[messageSender sendMessage:message];
		[message release];
		hasSentInitial = YES;
	}
	if (!feedbagOperator) {
		feedbagOperator = [[AIMSessionFeedbagOperator alloc] initWithFeedbagHandler:[handler feedbagHandler]];
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
	NSLog(@"Small icon: %p", [[handler buddyArt] smallBuddyIcon]);
	
	[iconData writeToFile:[NSString stringWithFormat:@"%@/Desktop/ouricon.jpg", NSHomeDirectory()]
			   atomically:YES];
	if ([[handler buddyArt] smallBuddyIcon]) {
		[[[handler buddyArt] smallBuddyIcon] writeToFile:[NSString stringWithFormat:@"%@/Desktop/oursmallicon.jpg", NSHomeDirectory()]
											  atomically:YES];
	}
}

- (void)dealloc {
	[session release];
	[messageSender release];
	[sessionEvents release];
	[super dealloc];
	exit(-1);
}

@end

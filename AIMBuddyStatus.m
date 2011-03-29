//
//  AIMBuddyStatus.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBuddyStatus.h"


@implementation AIMBuddyStatus

@synthesize statusType;
@synthesize statusMessage;

- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type {
	if (self = [super init]) {
		self.statusMessage = message;
		self.statusType = type;
	}
	return self;
}

- (void)dealloc {
	self.statusMessage = nil;
	[super dealloc];
}

@end

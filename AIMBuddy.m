//
//  AIMBuddy.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBuddy.h"


@implementation AIMBuddy

@synthesize username;
@synthesize nickInfo;
@synthesize feedbagItem;
@synthesize previousStatus;
@synthesize iconData;
@synthesize smallIconData;
@synthesize group;

- (void)setNickInfo:(ANNickWInfo *)_nickInfo {
	[nickInfo release];
	nickInfo = [_nickInfo retain];
}

- (ANNickWInfo *)nickInfo {
	return nickInfo;
}

- (AIMBuddyStatus *)buddyStatus {
	return buddyStatus;
}

- (void)setBuddyStatus:(AIMBuddyStatus *)_buddyStatus {
	self.previousStatus = buddyStatus;
	[buddyStatus release];
	buddyStatus = [_buddyStatus retain];
}

- (id)initWithUsername:(NSString *)_username {
	if ((self = [super init])) {
		username = [_username copy];
	}
	return self;
}

+ (id)buddyWithUsername:(NSString *)_username {
	return [[[AIMBuddy alloc] initWithUsername:_username] autorelease];
}

- (void)loadSettingsFromBuddy:(AIMBuddy *)newBuddy {
	if (newBuddy.iconData) self.iconData = [newBuddy iconData];
	if (newBuddy.smallIconData) self.smallIconData = [newBuddy smallIconData];
	if (newBuddy.group) self.group = [newBuddy group];
	if (newBuddy.nickInfo) self.nickInfo = [newBuddy nickInfo];
	if (newBuddy.previousStatus) self.previousStatus = [newBuddy previousStatus];
	if (newBuddy.feedbagItem) self.feedbagItem = [newBuddy feedbagItem];
}

- (UInt16)idleMinutes {
	for (TLV * attribute in [nickInfo userAttributes]) {
		if ([attribute type] == TLV_IDLE_TIME && [[attribute tlvData] length] == 2) {
			UInt16 idleTime = flipUInt16(*((const UInt16 *)([[attribute tlvData] bytes])));
			return idleTime;
		}
	}
	return 0;
}

- (id)description {
	return [NSString stringWithFormat:@"Buddy: %@", username];
}

- (void)dealloc {
	self.group = nil;
	self.username = nil;
	self.buddyStatus = nil;
	self.iconData = nil;
	self.smallIconData = nil;
	self.previousStatus = nil;
	[super dealloc];
}

@end

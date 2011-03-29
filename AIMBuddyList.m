//
//  AIMBuddyList.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBuddyList.h"


@implementation AIMBuddyList

@synthesize groups;
@synthesize denyList;
@synthesize permitList;
@synthesize pdMode;

- (id)initWithFeedbag:(AIMFeedbag *)feedbag {
	if (self = [super init]) {
		AIMFeedbagItem * rootGroup = [feedbag rootGroup];
		if (!rootGroup) {
			[super dealloc];
			return nil;
		}
		
		int count = 0;
		UInt16 * order = [rootGroup orderAttribute:&count];
		if (!order) {
			[super dealloc];
			return nil;
		}
		
		groups = [[NSMutableArray alloc] init];
		
		for (int i = 0; i < count; i++) {
			AIMFeedbagItem * item = [feedbag groupWithGroupID:order[i]];
			if (item) {
				AIMGroup * group = [[AIMGroup alloc] initWithItem:item inFeedbag:feedbag];
				[groups addObject:group];
				[group release];
			} else {
				NSLog(@"Root group specifies group that does not exist.");
			}
		}
		
		free(order);
		
		NSMutableArray * mutableDenyList = [[NSMutableArray alloc] init];
		for (AIMFeedbagItem * item in [feedbag items]) {
			if ([item classID] == FEEDBAG_DENY) {
				[mutableDenyList addObject:item.itemName];
			}
		}
		denyList = [[NSArray arrayWithArray:mutableDenyList] retain];
		[mutableDenyList release];
		
		NSMutableArray * mutablePermitList = [[NSMutableArray alloc] init];
		for (AIMFeedbagItem * item in [feedbag items]) {
			if ([item classID] == FEEDBAG_PERMIT) {
				[mutablePermitList addObject:item.itemName];
			}
		}
		permitList = [[NSArray arrayWithArray:mutablePermitList] retain];
		[mutablePermitList release];
		
		pdMode = [feedbag permitDenyMode];
		if (pdMode == PD_UNDEFINED) pdMode = [feedbag defaultPDMode];
	}
	return self;
}

- (AIMBuddy *)buddyWithName:(NSString *)username {
	for (AIMGroup * group in groups) {
		AIMBuddy * buddy = [group buddyWithName:username];
		if (buddy) return buddy;
	}
	return nil;
}

- (AIMGroup *)groupWithName:(NSString *)groupName {
	for (AIMGroup * group in groups) {
		if ([[group name] isEqual:groupName]) return group;
	}
	return nil;
}

- (void)updateStatusesFromBuddyList:(AIMBuddyList *)buddyList {
	for (AIMGroup * group in groups) {
		for (AIMBuddy * buddy in group.buddies) {
			AIMBuddy * otherBuddy = [buddyList buddyWithName:[buddy username]];
			if (otherBuddy) {
				buddy.buddyStatus = otherBuddy.buddyStatus;
				buddy.previousStatus = otherBuddy.previousStatus;
				buddy.nickInfo = otherBuddy.nickInfo;
				buddy.iconData = otherBuddy.iconData;
			}
		}
	}
}

- (NSString *)description {
	NSMutableString * buddyList = [NSMutableString string];
	[buddyList appendFormat:@"(\n"];
	for (AIMGroup * group in groups) {
		[buddyList appendFormat:@" %@\n", group];
	}
	[buddyList appendFormat:@")"];
	return buddyList;
}

- (void)dealloc {
	[permitList release];
	[denyList release];
	[groups release];
	[super dealloc];
}

@end

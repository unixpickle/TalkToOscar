//
//  AIMGroup.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMGroup.h"


@implementation AIMGroup

@synthesize buddies;
@synthesize name;
@synthesize feedbagItem;

+ (BOOL)isGroupRecentBuddy:(AIMFeedbagItem *)groupItem {
	for (TLV * attribute in groupItem.attributes) {
		if ([attribute type] == TLV_RECENT_BUDDY) {
			return YES;
		}
	}
	return NO;
}

- (id)initWithItem:(AIMFeedbagItem *)groupItem inFeedbag:(AIMFeedbag *)feedbag {
	if (self = [super init]) {
		self.name = groupItem.itemName;
		// create buddies.
		UInt16 * order = NULL;
		int count = 0;
		if ([AIMGroup isGroupRecentBuddy:groupItem]) {
			order = [feedbag recentBuddiesOrder:&count];
			if (!order) order = [groupItem orderAttribute:&count];
		} else {
			order = [groupItem orderAttribute:&count];
		}
		
		if (!order) {
			// we will assume that this is an empty group.
			buddies = [[NSMutableArray alloc] init];
			self.feedbagItem = groupItem;
			return self;
		}
		
		buddies = [[NSMutableArray alloc] init];
		for (int i = 0; i < count; i++) {
			AIMFeedbagItem * buddyItem = [feedbag buddyWithItemID:order[i]];
			AIMBuddy * newBuddy = [[AIMBuddy alloc] initWithUsername:[buddyItem itemName]];
			[newBuddy setGroup:self];
			[newBuddy setFeedbagItem:buddyItem];
			NSString * errorString = [NSString stringWithFormat:@"Buddy not found, feedbag corrupt (item %d)", order[i]];
			if (!buddyItem) {
				NSLog(@"%@", errorString);
			} else {
				[self.buddies addObject:newBuddy];
			}
			[newBuddy release];
		}
		
		self.feedbagItem = groupItem;
		
		free(order);
	}
	return self;
}

- (id)initWithName:(NSString *)_name {
	if (self = [super init]) {
		self.name = _name;
	}
	return self;
}

+ (AIMGroup *)groupWithName:(NSString *)groupName {
	return [[[AIMGroup alloc] initWithName:groupName] autorelease];
}

- (AIMBuddy *)buddyWithName:(NSString *)buddyName {
	for (AIMBuddy * buddy in buddies) {
		if ([[buddy username] isEqual:buddyName]) return buddy;
	}
	return nil;
}

- (id)description {
	NSString * format = [NSString stringWithFormat:@"Group (%@): %@", self.name, self.buddies];
	format = [format stringByReplacingCharactersInRange:NSMakeRange([format length] - 1, 1)
											 withString:@" )"];
	return format;
}

- (void)dealloc {
	self.feedbagItem = nil;
	self.buddies = nil;
	self.name = nil;
	[super dealloc];
}

@end

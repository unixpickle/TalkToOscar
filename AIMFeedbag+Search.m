//
//  AIMFeedbag+Search.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbag+Search.h"


@implementation AIMFeedbag (Search)

- (AIMFeedbagItem *)rootGroup {
	if ([items count] == 0) return nil;
	for (AIMFeedbagItem * item in items) {
		if ([item groupID] == 0 && [item itemID] == 0) return item;
	}
	return nil;
}
- (AIMFeedbagItem *)userItemWithName:(NSString *)name {
	for (AIMFeedbagItem * item in items) {
		if ([item classID] == FEEDBAG_BUDDY && [item itemID] != 0) {
			if ([[item itemName] isEqual:name]) return item;
		}
	}
	return nil;
}
- (AIMFeedbagItem *)groupItemWithName:(NSString *)name {
	for (AIMFeedbagItem * item in items) {
		if ([item classID] == FEEDBAG_GROUP && [item itemID] == 0) {
			if ([[item itemName] isEqual:name]) return item;
		}
	}
	return nil;
}
- (AIMFeedbagItem *)buddyWithItemID:(UInt16)itemID {
	for (AIMFeedbagItem * item in items) {
		if ([item classID] == FEEDBAG_BUDDY && [item itemID] == itemID) return item;
	}
	return nil;
}
- (AIMFeedbagItem *)groupWithGroupID:(UInt16)groupID {
	for (AIMFeedbagItem * item in items) {
		if ([item classID] == FEEDBAG_GROUP && [item groupID] == groupID) return item;
	}
	return nil;
}

- (AIMFeedbagItem *)itemWithTagsOfItem:(AIMFeedbagItem *)anItem {
	for (AIMFeedbagItem * item in items) {
		if ([item classID] == [anItem classID] && [item itemID] == [anItem itemID] && [item groupID] == [anItem groupID]) {
			return item;
		}
	}
	return nil;
}

@end

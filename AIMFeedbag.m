//
//  AIMFeedbag.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbag.h"


@implementation AIMFeedbag

@synthesize items;
@synthesize updateTime;
@synthesize numClasses;

- (id)initWithSnac:(SNAC *)feedbagReply {
	if (self = [super init]) {
		NSData * contents = [feedbagReply innerContents];
		UInt16 numItems = 0;
		const char * bytes = [contents bytes];
		int bytesLength = [contents length];
		
		if ([contents length] < 3) {
			[super dealloc];
			return nil;
		}
		
		if ([feedbagReply isLastResponse]) {
			// we can get the timestamp here.
			if ([contents length] < 7) {
				[super dealloc];
				return nil;
			}
			updateTime = flipUInt32(*(const UInt32 *)(&bytes[bytesLength - 4]));
		} else updateTime = 0;
		
		numClasses = *(const UInt8 *)bytes;
		numItems = flipUInt16(*((const UInt16 *)(&bytes[1])));
		
		bytes = &bytes[3];
		bytesLength = bytesLength - 7;
		items = [[NSMutableArray alloc] init];
		
		while (numItems > 0) {
			if (bytesLength <= 0) {
				NSLog(@"Warning: feedbag overflow, ignoring.");
				break;
			} else if (bytesLength <= 4) break;
			
			int leftOver = bytesLength;
			AIMFeedbagItem * item = [[AIMFeedbagItem alloc] initWithPointer:bytes length:&leftOver];
			if (!item) {
				NSLog(@"Warning: possible missing item.");
				break;
			}
			
			[items addObject:item];
			[item release];
			bytesLength -= leftOver;
			bytes = &bytes[leftOver];
			
			numItems -= 1;
		}
	}
	return self;
}

#pragma mark Ordering and Attributes

- (AIMFeedbagItem *)recentBuddiesOrderItem {
	for (AIMFeedbagItem * item in items) {
		if ([item classID] == FEEDBAG_RB_ORDER) {
			return item;
		}
	}
	return nil;
}

- (UInt16 *)recentBuddiesOrder:(int *)count {
	int num = 0;
	AIMFeedbagItem * item = [self recentBuddiesOrderItem];
	if (!item) return NULL;
	
	TLV * orderAttribute = [item attributeOfType:FEEDBAG_ATTRIBUTE_ORDER];
	if (!orderAttribute) return NULL;
	UInt16 * data = (UInt16 *)malloc([[orderAttribute tlvData] length]);
	for (int i = 0; i < ((int)[[orderAttribute tlvData] length]) - 1; i += 2) {
		if (![[orderAttribute tlvData] length]) break;
		UInt16 nextItem = flipUInt16(*(const UInt16 *)(&((const char *)[[orderAttribute tlvData] bytes])[i]));
		data[i / 2] = nextItem;
		num += 1;
	}
	*count = num;
	return data;
}

- (BOOL)hasBARTIDOfType:(UInt16)bartType {
	for (AIMFeedbagItem * item in items) {
		if ([item classID] == FEEDBAG_BART && [[item itemName] isEqual:[NSString stringWithFormat:@"%d", bartType]]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)hasGroupOfID:(UInt16)groupID {
	for (AIMFeedbagItem * item in items) {
		if ([item groupID] == groupID) return YES;
	}
	return NO;
}

- (BOOL)hasItemOfID:(UInt16)itemID {
	for (AIMFeedbagItem * item in items) {
		if ([item itemID] == itemID) return YES;
	}
	return NO;
}

- (UInt16)randomItemID {
	for (UInt16 i = 0; i < 1024; i++) {
		if (![self hasItemOfID:i]) return i;
	}
	return 0;
}

- (UInt16)randomGroupID {
	for (UInt16 i = 0; i < 1024; i++) {
		if (![self hasGroupOfID:i]) return i;
	}
	return 0;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		numClasses = [aDecoder decodeIntForKey:@"numClasses"];
		items = [aDecoder decodeObjectForKey:@"items"];
		updateTime = [aDecoder decodeIntForKey:@"utime"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:numClasses forKey:@"numClasses"];
	[aCoder encodeObject:items forKey:@"items"];
	[aCoder encodeInt:updateTime forKey:@"utime"];
}

- (void)dealloc {
	[items release];
	[super dealloc];
}

@end

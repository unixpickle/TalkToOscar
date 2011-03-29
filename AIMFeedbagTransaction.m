//
//  AIMFeedbagTransaction.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbagTransaction.h"


@implementation AIMFeedbagTransaction

@synthesize transactionSnac;
@synthesize effectedItem;

- (id)initInsertRootGroup {
	if (self = [super init]) {
		AIMFeedbagItem * rootGroup = [[AIMFeedbagItem alloc] init];
		TLV * attributes = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_ORDER data:[NSData data]];
		rootGroup.classID = FEEDBAG_GROUP;
		rootGroup.itemID = 0;
		rootGroup.groupID = 0;
		rootGroup.itemName = @"";
		rootGroup.attributes = [NSArray arrayWithObject:attributes];
		[attributes release];
		transactionSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__INSERT_ITEMS)
											 flags:0 requestID:[AIMSession randomRequestID] data:[rootGroup encodePacket]];
		self.effectedItem = rootGroup;
		[rootGroup release];
	}
	return self;
}

- (id)initClusterStarting:(BOOL)isStart {
	if (self = [super init]) {
		UInt16 type = FEEDBAG__START_CLUSTER;
		if (!isStart) type = FEEDBAG__END_CLUSTER;
		transactionSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, type)
											 flags:0 requestID:[AIMSession randomRequestID] data:nil];
	}
	return self;
}

- (id)initUpdate:(AIMFeedbagItem *)item removingItemID:(UInt16)_itemID {
	if (self = [super init]) {
		int orderCount = 0;
		UInt16 * oldOrder = [item orderAttribute:&orderCount];
		if (!oldOrder) orderCount = 0;
		
		int newOrderCount = 0;
		UInt16 * newOrder = (UInt16 *)malloc(orderCount * sizeof(UInt16));
		for (int i = 0; i < orderCount; i++) {
			UInt16 itemID = oldOrder[i];
			if (itemID != _itemID) newOrder[newOrderCount++] = flipUInt16(itemID);
		}
		if (oldOrder) free(oldOrder);
		
		NSData * orderData = [NSData dataWithBytesNoCopy:newOrder length:newOrderCount*sizeof(UInt16) freeWhenDone:YES];
		
		AIMFeedbagItem * newUpdateItem = [item copy];
		TLV * orderAttribute = [newUpdateItem attributeOfType:FEEDBAG_ATTRIBUTE_ORDER];
		[orderAttribute setTlvData:orderData];
		
		SNAC * updateSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS)
											   flags:0 requestID:[AIMSession randomRequestID] data:[newUpdateItem encodePacket]];
		
		transactionSnac = updateSnac;
		self.effectedItem = newUpdateItem;
		[newUpdateItem release];
	}
	return self;
}

- (id)initUpdate:(AIMFeedbagItem *)item addingItemID:(UInt16)_itemID {
	if (self = [super init]) {
		int orderCount = 0;
		UInt16 * oldOrder = [item orderAttribute:&orderCount];
		if (!oldOrder) orderCount = 0;
		
		int newOrderCount = 0;
		UInt16 * newOrder = (UInt16 *)malloc((orderCount + 1) * sizeof(UInt16));
		for (int i = 0; i < orderCount; i++) {
			UInt16 itemID = oldOrder[i];
			if (itemID != _itemID) newOrder[newOrderCount++] = flipUInt16(itemID);
		}
		
		newOrder[newOrderCount++] = flipUInt16(_itemID);
		if (oldOrder) free(oldOrder);
		
		NSData * orderData = [NSData dataWithBytesNoCopy:newOrder length:newOrderCount*sizeof(UInt16) freeWhenDone:YES];
		
		AIMFeedbagItem * newUpdateItem = [item copy];
		TLV * orderAttribute = [newUpdateItem attributeOfType:FEEDBAG_ATTRIBUTE_ORDER];
		[orderAttribute setTlvData:orderData];
		
		SNAC * updateSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS)
											   flags:0 requestID:[AIMSession randomRequestID] data:[newUpdateItem encodePacket]];
		
		transactionSnac = updateSnac;
		self.effectedItem = newUpdateItem;
		[newUpdateItem release];
	}
	return self;
}

- (id)initUpdate:(AIMFeedbagItem *)item settingPDMode:(UInt8)pdMode {
	if (self = [super init]) {
		NSData * modeData = [[NSData alloc] initWithBytes:&pdMode length:1];
		AIMFeedbagItem * newUpdateItem = [item copy];
		TLV * modeAttribute = [newUpdateItem attributeOfType:TLV_PD_MODE];
		if (!modeAttribute) {
			modeAttribute = [[TLV alloc] initWithType:TLV_PD_MODE data:modeData];
			[[newUpdateItem attributes] addObject:modeAttribute];
			[modeAttribute release];
		} else {
			[modeAttribute setTlvData:modeData];
		}
		
		[modeData release];
		
		SNAC * updateSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__UPDATE_ITEMS)
											   flags:0 requestID:[AIMSession randomRequestID] data:[newUpdateItem encodePacket]];
		
		transactionSnac = updateSnac;
		self.effectedItem = newUpdateItem;
		[newUpdateItem release];
	}
	return self;
}

- (id)initDelete:(AIMFeedbagItem *)item {
	if (self = [super init]) {
		transactionSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__DELETE_ITEMS)
											 flags:0 requestID:[AIMSession randomRequestID] data:[item encodePacket]];
		self.effectedItem = item;
	}
	return self;
}

- (id)initInsert:(AIMFeedbagItem *)item {
	if (self = [super init]) {
		transactionSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__INSERT_ITEMS)
											 flags:0 requestID:[AIMSession randomRequestID] data:[item encodePacket]];
		self.effectedItem = item;
	}
	return self;
}

- (BOOL)isClusterBracket {
	if (transactionSnac.snac_id.type == FEEDBAG__START_CLUSTER || transactionSnac.snac_id.type == FEEDBAG__END_CLUSTER) return YES;
	return NO;
}

- (BOOL)isSuccess:(SNAC *)feedbagStatus {
	NSData * statusCodes = [feedbagStatus innerContents];
	for (int i = 0; i < [statusCodes length]; i += 2) {
		UInt16 statusCode = ((UInt16 *)[statusCodes bytes])[i / 2];
		if (statusCode != 0) return NO;
	}
	return YES;
}

- (void)applyToFeedbag:(AIMFeedbag *)feedbag {
	if (transactionSnac.snac_id.type == FEEDBAG__DELETE_ITEMS) {
		AIMFeedbagItem * item = [feedbag itemWithTagsOfItem:effectedItem];
		if (item) {
			[[feedbag items] removeObject:item];
		}
	} else if (transactionSnac.snac_id.type == FEEDBAG__INSERT_ITEMS) {
		[[feedbag items] addObject:effectedItem];
	} else if (transactionSnac.snac_id.type == FEEDBAG__UPDATE_ITEMS) {
		AIMFeedbagItem * item = [feedbag itemWithTagsOfItem:effectedItem];
		if (item) {
			[item setAttributes:[effectedItem attributes]];
		}
	}
}

- (void)dealloc {
	self.effectedItem = nil;
	self.transactionSnac = nil;
	[super dealloc];
}

@end

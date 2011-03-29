//
//  AIMFeedbag+PD.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbag+PD.h"


#define PD_UNDERFINED 0
#define PD_PERMIT_ALL 1
#define PD_DENY_ALL 2
#define PD_PERMIT_SOME 3
#define PD_DENY_SOME 4
#define PD_PERMIT_ON_LIST 5

@implementation AIMFeedbag (PD)

- (UInt8)permitDenyMode {
	AIMFeedbagItem * item = [self pdInfoItem];

	for (TLV * attribute in item.attributes) {
		if ([attribute type] == TLV_PD_MODE) {
			if ([[attribute tlvData] length] != 1) return PD_UNDEFINED;
			UInt8 pdMode = *(const UInt8 *)[[attribute tlvData] bytes];
			return pdMode;
		}
	}

	return PD_UNDEFINED;
}
- (UInt8)defaultPDMode {
	return PD_PERMIT_ALL;
}

- (AIMFeedbagItem *)defaultFeedbagPDINFO:(UInt8)_pdMode {
	AIMFeedbagItem * pdinfo = [[AIMFeedbagItem alloc] init];
	[pdinfo setGroupID:0];
	[pdinfo setItemID:[self randomItemID]];
	[pdinfo setClassID:FEEDBAG_PDINFO];
	[pdinfo setItemName:@""];
	
	UInt32 pdMaskFlip = 0xffffffff;
	UInt32 pdFlagsFlip = flipUInt32(1);
	NSData * pdMode = [[NSData alloc] initWithBytes:&_pdMode length:1];
	NSData * pdMask = [[NSData alloc] initWithBytes:&pdMaskFlip length:4];
	NSData * pdFlags = [[NSData alloc] initWithBytes:&pdFlagsFlip length:4];
	TLV * pdModeAttr = [[TLV alloc] initWithType:TLV_PD_MODE data:pdMode];
	TLV * pdMaskAttr = [[TLV alloc] initWithType:TLV_PD_MASK data:pdMask];
	TLV * pdFlagsAttr = [[TLV alloc] initWithType:TLV_PD_FLAGS data:pdFlags];
	pdinfo.attributes = [NSArray arrayWithObjects:pdModeAttr, pdMaskAttr, pdFlagsAttr, nil];
	[pdMode release];
	[pdMask release];
	[pdFlags release];
	[pdModeAttr release];
	[pdMaskAttr release];
	[pdFlagsAttr release];
	
	return [pdinfo autorelease];
}

- (AIMFeedbagItem *)pdInfoItem {
	for (AIMFeedbagItem * item in self.items) {
		if ([item classID] == FEEDBAG_PDINFO) { 
			return item;
		}
	}
	return nil;
}

@end

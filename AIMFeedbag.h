//
//  AIMFeedbag.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbagItem.h"
#import "SNAC.h"
#import "TLV.h"

@interface AIMFeedbag : NSObject <NSCoding> {
	UInt8 numClasses; // always 0
	NSMutableArray * items;
	UInt32 updateTime;
}

@property (readonly) NSMutableArray * items;
@property (readwrite) UInt32 updateTime;
@property (readonly) UInt8 numClasses;

- (id)initWithSnac:(SNAC *)feedbagReply;

- (UInt16 *)recentBuddiesOrder:(int *)count;
- (AIMFeedbagItem *)recentBuddiesOrderItem;

- (BOOL)hasBARTIDOfType:(UInt16)bartType;

- (BOOL)hasItemOfID:(UInt16)itemID;
- (BOOL)hasGroupOfID:(UInt16)groupID;
- (UInt16)randomItemID;
- (UInt16)randomGroupID;

@end

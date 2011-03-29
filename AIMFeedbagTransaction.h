//
//  AIMFeedbagTransaction.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"
#import "AIMFeedbag+Search.h"
#import "AIMSession.h"
#import "SNAC.h"
#import "TLV.h"

@interface AIMFeedbagTransaction : NSObject {
	SNAC * transactionSnac;
	AIMFeedbagItem * effectedItem;
}

@property (nonatomic, retain) SNAC * transactionSnac;
@property (nonatomic, retain) AIMFeedbagItem * effectedItem;

- (id)initInsertRootGroup;
- (id)initClusterStarting:(BOOL)isStart;
- (id)initUpdate:(AIMFeedbagItem *)item removingItemID:(UInt16)itemID;
- (id)initUpdate:(AIMFeedbagItem *)item addingItemID:(UInt16)itemID;
- (id)initUpdate:(AIMFeedbagItem *)item settingPDMode:(UInt8)pdMode;
- (id)initDelete:(AIMFeedbagItem *)item;
- (id)initInsert:(AIMFeedbagItem *)item;

- (BOOL)isClusterBracket;

- (BOOL)isSuccess:(SNAC *)feedbagStatus;
- (void)applyToFeedbag:(AIMFeedbag *)feedbag;

@end

//
//  AIMFeedbag+Search.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"

@interface AIMFeedbag (Search)

- (AIMFeedbagItem *)rootGroup;
- (AIMFeedbagItem *)userItemWithName:(NSString *)name;
- (AIMFeedbagItem *)groupItemWithName:(NSString *)name;
- (AIMFeedbagItem *)buddyWithItemID:(UInt16)itemID;
- (AIMFeedbagItem *)groupWithGroupID:(UInt16)groupID;

- (AIMFeedbagItem *)itemWithTagsOfItem:(AIMFeedbagItem *)anItem;

@end

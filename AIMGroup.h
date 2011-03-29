//
//  AIMGroup.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"
#import "AIMFeedbag+Search.h"
#import "AIMFeedbagItem.h"
#import "AIMBuddy.h"
#import "TLV.h"

@interface AIMGroup : NSObject {
	NSMutableArray * buddies;
	NSString * name;
	AIMFeedbagItem * feedbagItem;
}

@property (nonatomic, retain) NSMutableArray * buddies;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) AIMFeedbagItem * feedbagItem;

+ (BOOL)isGroupRecentBuddy:(AIMFeedbagItem *)groupItem;

- (id)initWithItem:(AIMFeedbagItem *)groupItem inFeedbag:(AIMFeedbag *)feedbag;
- (id)initWithName:(NSString *)_name;

+ (AIMGroup *)groupWithName:(NSString *)groupName;

- (AIMBuddy *)buddyWithName:(NSString *)buddyName;

@end

//
//  AIMBuddyList.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"
#import "AIMFeedbag+Search.h"
#import "AIMFeedbag+PD.h"
#import "AIMGroup.h"

@interface AIMBuddyList : NSObject {
	NSMutableArray * groups;
	NSArray * denyList;
	NSArray * permitList;
	UInt8 pdMode;
}

@property (readonly) NSMutableArray * groups;
@property (readonly) NSArray * denyList;
@property (readonly) NSArray * permitList;
@property (readwrite) UInt8 pdMode;

- (id)initWithFeedbag:(AIMFeedbag *)feedbag;
- (AIMBuddy *)buddyWithName:(NSString *)username;
- (AIMGroup *)groupWithName:(NSString *)groupName;

- (void)updateStatusesFromBuddyList:(AIMBuddyList *)buddyList;

@end

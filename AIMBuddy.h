//
//  AIMBuddy.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANNickWInfo.h"
#import "AIMFeedbagItem.h"
#import "AIMBuddyStatus.h"

@class AIMGroup;

@interface AIMBuddy : NSObject {
	NSString * username;
	ANNickWInfo * nickInfo;
	AIMFeedbagItem * feedbagItem;
	AIMBuddyStatus * buddyStatus;
	AIMBuddyStatus * previousStatus;
	NSData * iconData;
	AIMGroup * group;
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) ANNickWInfo * nickInfo;
@property (nonatomic, retain) AIMFeedbagItem * feedbagItem;
@property (nonatomic, retain) AIMBuddyStatus * buddyStatus;
@property (nonatomic, retain) AIMBuddyStatus * previousStatus;
@property (nonatomic, retain) NSData * iconData;
@property (nonatomic, assign) AIMGroup * group;

- (id)initWithUsername:(NSString *)_username;
+ (id)buddyWithUsername:(NSString *)_username;

- (UInt16)idleMinutes;

@end

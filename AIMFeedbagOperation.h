//
//  AIMFeedbagOperation.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbagTransaction.h"

typedef enum {
	kAIMFeedbagOperationRootGroup,
	kAIMFeedbagOperationRemoveBuddy,
	kAIMFeedbagOperationAddBuddy,
	kAIMFeedbagOperationRemoveGroup,
	kAIMFeedbagOperationAddGroup,
	kAIMFeedbagOperationSetPDMode,
	kAIMFeedbagOperationAddDeny,
	kAIMFeedbagOperationRemoveDeny,
	kAIMFeedbagOperationRemoveBART
} AIMFeedbagOperationType;

@interface AIMFeedbagOperation : NSObject {
	AIMFeedbagOperationType operationType;
	NSString * buddyName;
	NSString * groupName;
	UInt32 integerMode;
	NSMutableArray * transactionBuffer;
}

@property (readwrite) AIMFeedbagOperationType operationType;
@property (nonatomic, retain) NSString * buddyName;
@property (nonatomic, retain) NSString * groupName;
@property (readwrite) UInt32 integerMode;
@property (nonatomic, retain) NSMutableArray * transactionBuffer;

@end

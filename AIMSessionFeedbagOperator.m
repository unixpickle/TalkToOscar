//
//  AIMSessionFeedbagOperator.m
//  TalkToOscar
//
//  Created by Alex Nichol on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSessionFeedbagOperator.h"


@implementation AIMSessionFeedbagOperator

@synthesize feedbagHandler;

- (id)initWithFeedbagHandler:(AIMSessionFeedbagHandler *)theFeedbagHandler {
	if ((self = [super init])) {
		feedbagHandler = theFeedbagHandler;
	}
	return self;
}

#pragma mark Actions

- (BOOL)removeBuddy:(AIMBuddy *)buddy {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRemoveBuddy;
	operation.buddyName = [buddy username];
	BOOL flag = [feedbagHandler pushOperation:operation];
	[operation release];
	return flag;
}
- (BOOL)addBuddy:(AIMBuddy *)buddy toGroup:(AIMGroup *)group {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationAddBuddy;
	operation.buddyName = [buddy username];
	operation.groupName = [group name];
	BOOL flag = [feedbagHandler pushOperation:operation];
	[operation release];
	return flag;
}
- (BOOL)addGroup:(AIMGroup *)group {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationAddGroup;
	operation.groupName = [group name];
	BOOL flag = [feedbagHandler pushOperation:operation];
	[operation release];
	return flag;
}
- (BOOL)removeGroup:(AIMGroup *)group {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRemoveGroup;
	operation.groupName = [group name];
	BOOL flag = [feedbagHandler pushOperation:operation];
	[operation release];
	return flag;
}
- (BOOL)addDenyUser:(NSString *)denyUsername {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationAddDeny;
	operation.buddyName = denyUsername;
	BOOL flag = [feedbagHandler pushOperation:operation];
	[operation release];
	return flag;
}
- (BOOL)removeDenyUser:(NSString *)denyUsername {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRemoveDeny;
	operation.buddyName = denyUsername;
	BOOL flag = [feedbagHandler pushOperation:operation];
	[operation release];
	return flag;
}

- (void)dealloc {
	[super dealloc];
}

@end

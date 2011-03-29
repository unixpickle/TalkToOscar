//
//  AIMSessionFeedbagHandler.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSessionFeedbagHandler.h"


@implementation AIMSessionFeedbagHandler

@synthesize feedbag;
@synthesize buddyList;
@synthesize delegate;

- (id)init {
	if (self = [super init]) {
		
	}
	return self;
}

- (id)initWithSession:(AIMSession *)_session {
	if (self = [super init]) {
		feedbagOperations = [[NSMutableArray alloc] init];
		session = [_session retain];
	}
	return self;
}

- (BOOL)handleFeedbagResponse:(SNAC *)feedbagResponse {
	// if it's the last one, use the timestamp
	AIMFeedbag * localFeedbag = [[AIMFeedbag alloc] initWithSnac:feedbagResponse];
	if (!localFeedbag) {
		return NO;
	}
	if (!feedbag) {
		feedbag = localFeedbag;
	} else {
		[[feedbag items] addObjectsFromArray:[localFeedbag items]];
		[localFeedbag release];
	}
	if ([feedbagResponse isLastResponse]) {
		if (![feedbag rootGroup]) {
			NSLog(@"Root group missing, generating.");
			[self addRootGroup];
			[self addGroup:[AIMGroup groupWithName:@"Buddies"]];
		} else {
			[self removeBARTIcon];
			[self regenerateBuddyList];
		}
	}
	return YES;
}

- (BOOL)handleFeedbagModification:(SNAC *)removeMods {
	if ([removeMods snac_id].type == FEEDBAG__START_CLUSTER) {
		isInClusterBracket = YES;
	} else if ([removeMods snac_id].type == FEEDBAG__END_CLUSTER) {
		[self regenerateBuddyList];
		isInClusterBracket = NO;
	}
	if ([removeMods snac_id].type == FEEDBAG__DELETE_ITEMS) {
		NSArray * removeItems = [AIMFeedbagItem decodeArray:[removeMods innerContents]];
		for (int i = 0; i < [removeItems count]; i++) {
			AIMFeedbagItem * localItem = [feedbag itemWithTagsOfItem:[removeItems objectAtIndex:i]];
			if (localItem) {
				[[feedbag items] removeObject:localItem];
			}
		}
		if (!isInClusterBracket) {
			[self regenerateBuddyList];
		}
	} else if ([removeMods snac_id].type == FEEDBAG__INSERT_ITEMS) {
		NSArray * items = [AIMFeedbagItem decodeArray:[removeMods innerContents]];
		for (int i = 0; i < [items count]; i++) {
			[[feedbag items] addObject:[items objectAtIndex:i]];
		}
		if (!isInClusterBracket) {
			[self regenerateBuddyList];
		}
	} else if ([removeMods snac_id].type == FEEDBAG__UPDATE_ITEMS) {
		NSArray * items = [AIMFeedbagItem decodeArray:[removeMods innerContents]];
		for (int i = 0; i < [items count]; i++) {
			AIMFeedbagItem * updateItem = [feedbag itemWithTagsOfItem:[items objectAtIndex:i]];
			[updateItem setAttributes:[(AIMFeedbagItem *)[items objectAtIndex:i] attributes]];
		}
		if (!isInClusterBracket) {
			[self regenerateBuddyList];
		}
	}
	return YES;
}

- (void)regenerateBuddyList {
	AIMBuddyList * newList = [[AIMBuddyList alloc] initWithFeedbag:feedbag];
	[newList updateStatusesFromBuddyList:buddyList];
	[buddyList release];
	buddyList = newList;
	if ([delegate respondsToSelector:@selector(feedbagHandlerDidGetFeedbag:)]) {
		[delegate feedbagHandlerDidGetFeedbag:self];
	}
	if ([feedbag hasBARTIDOfType:1]) {
		[self removeBARTIcon];
	}
}

- (BOOL)sendFeedbagUse {
	SNAC * feedbagAck = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__USE)
										   flags:0 requestID:[AIMSession randomRequestID] data:nil];
	if (![session sendSnacQuery:feedbagAck]) {
		[feedbagAck release];
		return NO;
	}
	[feedbagAck release];
	return YES;
}

#pragma mark Transactions

- (BOOL)performNextTransaction:(SNAC *)previousResponse {
	if ([feedbagOperations count] == 0) return YES;
	NSMutableArray * feedbagTransactions = [[feedbagOperations objectAtIndex:0] transactionBuffer];
	if ([feedbagTransactions count] == 0) return YES;
	AIMFeedbagTransaction * transaction = [feedbagTransactions objectAtIndex:0];
	if (![transaction isSuccess:previousResponse] && previousResponse) {
		AIMFeedbagTransaction * transactionBracket = [feedbagTransactions lastObject];
		if (![session sendRegularSnac:[transactionBracket transactionSnac]]) {
			[feedbagOperations removeAllObjects];
			return NO;
		}
		if ([delegate respondsToSelector:@selector(feedbagHandler:feedbagOperationFailed:)]) {
			[delegate feedbagHandler:self feedbagOperationFailed:[feedbagOperations objectAtIndex:0]];
		}
		[feedbagOperations removeObjectAtIndex:0];
		return [self performNextOperation];
	} else {
		[transaction applyToFeedbag:feedbag];
		[feedbagTransactions removeObjectAtIndex:0];
		
		if ([feedbagTransactions count] == 0) {
			[self regenerateBuddyList];
			
			[feedbagOperations removeObjectAtIndex:0];
			[self performNextOperation];
			return YES;
		}
		
		AIMFeedbagTransaction * nextTransaction = [feedbagTransactions objectAtIndex:0];
		if (![session sendRegularSnac:[nextTransaction transactionSnac]]) {
			[feedbagOperations removeAllObjects];
			return NO;
		}
				
		if ([nextTransaction isClusterBracket]) {
			// since this is a bracket, we should send the next packet as well,
			// if it exists.
			return [self performNextTransaction:nil];
		} else return YES;
	}
	return NO;
}

- (BOOL)performNextOperation {
	if ([feedbagOperations count] == 0) return YES;
	AIMFeedbagOperation * nextOperation = [feedbagOperations objectAtIndex:0];
	if (!nextOperation) {
		return NO;
	}
	if (![nextOperation transactionBuffer]) {
		switch ([nextOperation operationType]) {
			case kAIMFeedbagOperationRemoveBuddy:
			{
				AIMBuddy * buddy = [buddyList buddyWithName:[nextOperation buddyName]];
				if (!buddy) {
					if ([delegate respondsToSelector:@selector(feedbagHandler:feedbagOperationFailed:)]) {
						[delegate feedbagHandler:self feedbagOperationFailed:nextOperation];
					}
					[feedbagOperations removeObjectAtIndex:0];
					return [self performNextOperation];
				}
				[nextOperation setTransactionBuffer:[self buddyOperationsForRemove:buddy]];
				break;
			}
			case kAIMFeedbagOperationAddBuddy:
			{
				AIMGroup * group = [buddyList groupWithName:[nextOperation groupName]];
				AIMBuddy * buddy = [AIMBuddy buddyWithUsername:[nextOperation buddyName]];
				if (!buddy || !group) {
					if ([delegate respondsToSelector:@selector(feedbagHandler:feedbagOperationFailed:)]) {
						[delegate feedbagHandler:self feedbagOperationFailed:nextOperation];
					}
					[feedbagOperations removeObjectAtIndex:0];
					return [self performNextOperation];
				}
				[nextOperation setTransactionBuffer:[self buddyOperationsForAdd:buddy toGroup:group]];
				break;
			}
			case kAIMFeedbagOperationRootGroup:
			{
				AIMFeedbagTransaction * transaction = [[AIMFeedbagTransaction alloc] initInsertRootGroup];
				[nextOperation setTransactionBuffer:[NSMutableArray arrayWithObject:transaction]];
				[transaction release];
				break;
			}
			case kAIMFeedbagOperationAddGroup:
			{
				AIMGroup * group = [AIMGroup groupWithName:[nextOperation groupName]];
				[nextOperation setTransactionBuffer:[self buddyOperationsForAddGroup:group]];
				break;
			}
			case kAIMFeedbagOperationRemoveGroup:
			{
				AIMGroup * group = [buddyList groupWithName:[nextOperation groupName]];
				if (!group) {
					if ([delegate respondsToSelector:@selector(feedbagHandler:feedbagOperationFailed:)]) {
						[delegate feedbagHandler:self feedbagOperationFailed:nextOperation];
					}
					[feedbagOperations removeObjectAtIndex:0];
					return [self performNextOperation];
				}
				[nextOperation setTransactionBuffer:[self buddyOperationsForRemoveGroup:group]];
				break;
			}
			case kAIMFeedbagOperationSetPDMode:
				[nextOperation setTransactionBuffer:[self buddyOperationsForSetPDMode:[nextOperation integerMode]]];
				break;
			case kAIMFeedbagOperationAddDeny:
			{
				NSMutableArray * operations = [self buddyOperationsForAddDeny:[nextOperation buddyName]];
				if (!operations) {
					if ([delegate respondsToSelector:@selector(feedbagHandler:feedbagOperationFailed:)]) {
						[delegate feedbagHandler:self feedbagOperationFailed:nextOperation];
					}
					[feedbagOperations removeObjectAtIndex:0];
					return [self performNextOperation];
				}
				[nextOperation setTransactionBuffer:operations];
				break;
			}
			case kAIMFeedbagOperationRemoveDeny:
			{
				NSMutableArray * operations = [self buddyOperationsForRemoveDeny:[nextOperation buddyName]];
				if (!operations) {
					if ([delegate respondsToSelector:@selector(feedbagHandler:feedbagOperationFailed:)]) {
						[delegate feedbagHandler:self feedbagOperationFailed:nextOperation];
					}
					[feedbagOperations removeObjectAtIndex:0];
					return [self performNextOperation];
				}
				[nextOperation setTransactionBuffer:operations];
				break;
			}
			case kAIMFeedbagOperationRemoveBART:
			{
				NSMutableArray * operations = [self removeBartOperations];
				if (!operations) {
					[feedbagOperations removeObjectAtIndex:0];
					return [self performNextOperation];
				}
				[nextOperation setTransactionBuffer:operations];
			}
		}
	}
	if ([[nextOperation transactionBuffer] count] == 0) {
		[feedbagOperations removeObjectAtIndex:0];
		return [self performNextOperation];
	}
	if (![session sendRegularSnac:[[[nextOperation transactionBuffer] objectAtIndex:0] transactionSnac]]) {
		[feedbagOperations removeAllObjects];
		return NO;
	}
	if ([[[nextOperation transactionBuffer] objectAtIndex:0] isClusterBracket]) {
		return [self performNextTransaction:nil];
	} else return YES;
}

- (BOOL)pushOperation:(AIMFeedbagOperation *)operation {
	[feedbagOperations addObject:operation];
	if ([feedbagOperations count] == 1) {
		return [self performNextOperation];
	}
	return NO;
}

- (NSMutableArray *)buddyOperationsForRemove:(AIMBuddy *)buddy {
	AIMFeedbagItem * groupItem = [[buddy group] feedbagItem];
	AIMFeedbagItem * buddyItem = [buddy feedbagItem];
	if (!groupItem || !buddyItem) return nil;
	
	AIMFeedbagItem * recentGroup = nil;
	if ([AIMGroup isGroupRecentBuddy:groupItem]) {
		recentGroup = [feedbag recentBuddiesOrderItem];
	}
	
	AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
	AIMFeedbagTransaction * updateTransaction2 = nil;
	updateTransaction2 = [[[AIMFeedbagTransaction alloc] initUpdate:recentGroup removingItemID:[buddyItem itemID]] autorelease];
	AIMFeedbagTransaction * updateTransaction = [[[AIMFeedbagTransaction alloc] initUpdate:groupItem removingItemID:[buddyItem itemID]] autorelease];
	AIMFeedbagTransaction * deleteTransaction = [[[AIMFeedbagTransaction alloc] initDelete:buddyItem] autorelease];
	AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
	
	NSMutableArray * transactions = [[NSMutableArray alloc] init];
	
	[transactions addObject:startCluster];
	[transactions addObject:updateTransaction];
	if (updateTransaction2) [updateTransaction2 applyToFeedbag:feedbag];
	[transactions addObject:deleteTransaction];
	[transactions addObject:endCluster];
	
	return [transactions autorelease];
}

- (NSMutableArray *)buddyOperationsForAdd:(AIMBuddy *)buddy toGroup:(AIMGroup *)group {
	AIMFeedbagItem * groupItem = [group feedbagItem];
	AIMFeedbagItem * buddyItem = [[[AIMFeedbagItem alloc] init] autorelease];
	[buddyItem setItemName:[buddy username]];
	[buddyItem setGroupID:[groupItem groupID]];
	[buddyItem setItemID:[feedbag randomItemID]];
	[buddyItem setClassID:FEEDBAG_BUDDY];
	if (!groupItem || !buddyItem) return nil;
	if (![buddyItem itemID]) return nil;
	
	AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
	AIMFeedbagTransaction * insertTransaction = [[[AIMFeedbagTransaction alloc] initInsert:buddyItem] autorelease];
	AIMFeedbagTransaction * updateTransaction = [[[AIMFeedbagTransaction alloc] initUpdate:groupItem addingItemID:[buddyItem itemID]] autorelease];
	AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
	
	NSMutableArray * transactions = [[NSMutableArray alloc] init];
	[transactions addObject:startCluster];
	[transactions addObject:insertTransaction];
	[transactions addObject:updateTransaction];
	[transactions addObject:endCluster];
	
	return [transactions autorelease];
}

- (NSMutableArray *)buddyOperationsForAddGroup:(AIMGroup *)group {
	AIMFeedbagItem * rootGroup = [feedbag rootGroup];
	AIMFeedbagItem * groupItem = [[[AIMFeedbagItem alloc] init] autorelease];
	[groupItem setItemName:[group name]];
	[groupItem setGroupID:[feedbag randomGroupID]];
	[groupItem setItemID:0];
	[groupItem setClassID:FEEDBAG_GROUP];
	
	TLV * attributes = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_ORDER data:[NSData data]];
	groupItem.attributes = [NSArray arrayWithObject:attributes];
	[attributes release];
	
	if (!rootGroup || !groupItem) return nil;
	if (![groupItem groupID]) return nil;
	
	AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
	AIMFeedbagTransaction * insertTransaction = [[[AIMFeedbagTransaction alloc] initInsert:groupItem] autorelease];
	AIMFeedbagTransaction * updateTransaction = [[[AIMFeedbagTransaction alloc] initUpdate:rootGroup addingItemID:[groupItem groupID]] autorelease];
	AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
	
	NSMutableArray * transactions = [[NSMutableArray alloc] init];
	[transactions addObject:startCluster];
	[transactions addObject:insertTransaction];
	[transactions addObject:updateTransaction];
	[transactions addObject:endCluster];
	
	return [transactions autorelease];
}

- (NSMutableArray *)buddyOperationsForRemoveGroup:(AIMGroup *)group {
	AIMFeedbagItem * rootGroup = [feedbag rootGroup];
	AIMFeedbagItem * groupItem = [group feedbagItem];
	if (!rootGroup || !groupItem) return nil;
	
	AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
	AIMFeedbagTransaction * updateTransaction = [[[AIMFeedbagTransaction alloc] initUpdate:rootGroup removingItemID:[groupItem groupID]] autorelease];
	AIMFeedbagTransaction * deleteTransaction = [[[AIMFeedbagTransaction alloc] initDelete:groupItem] autorelease];
	AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
	
	NSMutableArray * transactions = [[NSMutableArray alloc] init];
	[transactions addObject:startCluster];
	[transactions addObject:updateTransaction];
	[transactions addObject:deleteTransaction];
	[transactions addObject:endCluster];
	
	return [transactions autorelease];
}

- (NSMutableArray *)buddyOperationsForSetPDMode:(UInt32)pdMode {
	if (![feedbag pdInfoItem]) {
		AIMFeedbagItem * item = [feedbag defaultFeedbagPDINFO:pdMode];
		AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
		AIMFeedbagTransaction * insertTransaction = [[[AIMFeedbagTransaction alloc] initInsert:item] autorelease];
		AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
		
		NSMutableArray * transactions = [[NSMutableArray alloc] init];
		[transactions addObject:startCluster];
		[transactions addObject:insertTransaction];
		[transactions addObject:endCluster];
		
		return [transactions autorelease];
	} else {
		AIMFeedbagItem * item = [feedbag pdInfoItem];
		AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
		AIMFeedbagTransaction * updateTransaction = [[[AIMFeedbagTransaction alloc] initUpdate:item settingPDMode:pdMode] autorelease];
		AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
		
		NSMutableArray * transactions = [[NSMutableArray alloc] init];
		[transactions addObject:startCluster];
		[transactions addObject:updateTransaction];
		[transactions addObject:endCluster];
		
		return [transactions autorelease];
	}
}

- (NSMutableArray *)buddyOperationsForRemoveDeny:(NSString *)denyUsername {
	AIMFeedbagItem * removeDeny = nil;
	for (AIMFeedbagItem * item in feedbag.items) {
		if ([item classID] == FEEDBAG_DENY) {
			removeDeny = item;
			break;
		}
	}
	if (!removeDeny) return nil;
	
	AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
	AIMFeedbagTransaction * deleteTransaction = [[[AIMFeedbagTransaction alloc] initDelete:removeDeny] autorelease];
	AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
	NSMutableArray * transactions = [[NSMutableArray alloc] init];
	[transactions addObject:startCluster];
	[transactions addObject:deleteTransaction];
	[transactions addObject:endCluster];
	
	return [transactions autorelease];
}

- (NSMutableArray *)buddyOperationsForAddDeny:(NSString *)denyUsername {
	AIMFeedbagItem * denyExisting = nil;
	for (AIMFeedbagItem * item in feedbag.items) {
		if ([item classID] == FEEDBAG_DENY) {
			denyExisting = item;
			break;
		}
	}
	
	if (denyExisting) return nil;
	
	AIMFeedbagItem * newDeny = [[AIMFeedbagItem alloc] init];
	newDeny.classID = FEEDBAG_DENY;
	newDeny.groupID = 0;
	newDeny.itemID = [feedbag randomItemID];
	newDeny.itemName = denyUsername;
	
	AIMFeedbagTransaction * startCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:YES] autorelease];
	AIMFeedbagTransaction * insertTransaction = [[[AIMFeedbagTransaction alloc] initInsert:newDeny] autorelease];
	AIMFeedbagTransaction * endCluster = [[[AIMFeedbagTransaction alloc] initClusterStarting:NO] autorelease];
	NSMutableArray * transactions = [[NSMutableArray alloc] init];
	[transactions addObject:startCluster];
	[transactions addObject:insertTransaction];
	[transactions addObject:endCluster];
	
	[newDeny release];
	
	return [transactions autorelease];
}

- (NSMutableArray *)removeBartOperations {
	for (int i = 0; i < [[feedbag items] count]; i++) {
		AIMFeedbagItem * item = [[feedbag items] objectAtIndex:i];
		if ([item classID] == FEEDBAG_BART && [[item itemName] isEqual:@"1"]) {
			AIMFeedbagTransaction * delete = [[AIMFeedbagTransaction alloc] initDelete:item];
			NSMutableArray * array = [NSMutableArray arrayWithObject:delete];
			[delete release];
			return array;
		}
	}
	return nil;
}

#pragma mark External Modifications
			 
- (BOOL)addRootGroup {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRootGroup;
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)removeBuddy:(AIMBuddy *)buddy {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRemoveBuddy;
	operation.buddyName = [buddy username];
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)addBuddy:(AIMBuddy *)buddy toGroup:(AIMGroup *)group {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationAddBuddy;
	operation.buddyName = [buddy username];
	operation.groupName = [group name];
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)addGroup:(AIMGroup *)group {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationAddGroup;
	operation.groupName = [group name];
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)removeGroup:(AIMGroup *)group {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRemoveGroup;
	operation.groupName = [group name];
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)setPDMode:(UInt8)pdMode {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationSetPDMode;
	operation.integerMode = pdMode;
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)addDenyUser:(NSString *)denyUsername {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationAddDeny;
	operation.buddyName = denyUsername;
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)removeDenyUser:(NSString *)denyUsername {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRemoveDeny;
	operation.buddyName = denyUsername;
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (BOOL)removeBARTIcon {
	AIMFeedbagOperation * operation = [[AIMFeedbagOperation alloc] init];
	operation.operationType = kAIMFeedbagOperationRemoveBART;
	BOOL flag = [self pushOperation:operation];
	[operation release];
	return flag;
}

- (void)dealloc {
	[feedbagOperations release];
	[feedbag release];
	[buddyList release];
	[session release];
	self.delegate = nil;
	[super dealloc];
}

@end

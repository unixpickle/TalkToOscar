//
//  AIMSessionFeedbagHandler.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"
#import "AIMFeedbag+Search.h"
#import "AIMFeedbag+PD.h"
#import "AIMBuddyList.h"
#import "ANNickWInfo.h"
#import "AIMSession.h"
#import "AIMFeedbagTransaction.h"
#import "AIMFeedbagOperation.h"

/*	Maintains the buddy list, buddy status, arrived and departed message,
	as well as managing our status message. */

@class AIMSessionFeedbagHandler;

@protocol AIMSessionFeedbagHandlerDelegate<NSObject>

@optional
- (void)feedbagHandlerDidGetFeedbag:(AIMSessionFeedbagHandler *)handler;
- (void)feedbagHandler:(AIMSessionFeedbagHandler *)handler feedbagOperationFailed:(AIMFeedbagOperation *)operation;

@end

#define LOCATE_QUERY_UNAVAILABLE 2

@interface AIMSessionFeedbagHandler : NSObject {
	AIMFeedbag * feedbag;
	AIMBuddyList * buddyList;
	AIMSession * session;
	id<AIMSessionFeedbagHandlerDelegate> delegate;
	BOOL isInClusterBracket;
	NSMutableArray * feedbagOperations;
}

@property (readonly) AIMFeedbag * feedbag;
@property (readonly) AIMBuddyList * buddyList;
@property (nonatomic, assign) id<AIMSessionFeedbagHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)_session;

- (BOOL)handleFeedbagResponse:(SNAC *)feedbagResponse;
- (BOOL)handleFeedbagModification:(SNAC *)updateInsertDeletes;

- (void)regenerateBuddyList;

- (BOOL)sendFeedbagUse;

- (BOOL)performNextTransaction:(SNAC *)previousResponse;
- (BOOL)performNextOperation;
- (BOOL)pushOperation:(AIMFeedbagOperation *)operation;

- (BOOL)addRootGroup;
- (BOOL)setPDMode:(UInt8)pdMode;
- (BOOL)removeBARTIcon;

@end

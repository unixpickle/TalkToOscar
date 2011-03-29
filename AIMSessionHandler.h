//
//  AIMSessionEventHandler.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMBuddy.h"
#import "AIMSessionMessages.h"
#import "ANICBMEvent.h"
#import "ANICBMMessage.h"
#import "AIMSessionFeedbagHandler.h"
#import "AIMStatusMessageHandler.h"
#import "AIMBuddyArt.h"

@class AIMSessionHandler;

@protocol AIMSessionHandlerDelegate<NSObject>

@optional
- (void)aimSessionHandler:(AIMSessionHandler *)handler buddyOnline:(AIMBuddy *)buddy;
- (void)aimSessionHandler:(AIMSessionHandler *)handler buddyOffline:(AIMBuddy *)buddy;
- (void)aimSessionHandler:(AIMSessionHandler *)handler buddyChangedIcon:(AIMBuddy *)buddy;
- (void)aimSessionHandler:(AIMSessionHandler *)handler receivedMessage:(AIMMessage *)message;
- (void)aimSessionHandler:(AIMSessionHandler *)handler receivedEvent:(UInt16)event fromBuddy:(AIMBuddy *)buddy;
- (void)aimSessionHandlerGotBuddyList:(AIMSessionHandler *)handler;
- (void)aimSessionHandler:(AIMSessionHandler *)handler feedbagOperationFailed:(AIMFeedbagOperation *)operation;
- (void)aimSessionHandler:(AIMSessionHandler *)handler didGetMessageSendingError:(NSError *)icbmError;
- (void)aimSessionHandler:(AIMSessionHandler *)handler didGetOurIcon:(NSData *)iconData;

@end


@interface AIMSessionHandler : NSObject <AIMSessionFeedbagHandlerDelegate, AIMStatusMessageHandlerDelegate, AIMBuddyArtDelegate> {
	AIMSession * session;
	AIMSessionFeedbagHandler * feedbagHandler;
	AIMStatusMessageHandler * statusHandler;
	AIMBuddyArt * buddyArt;
	UInt32 bartRequestID;
	id<AIMSessionHandlerDelegate> delegate;
}

@property (nonatomic, retain) id<AIMSessionHandlerDelegate> delegate;
@property (readonly) AIMSessionFeedbagHandler * feedbagHandler;
@property (readonly) AIMStatusMessageHandler * statusHandler;
@property (readonly) AIMBuddyArt * buddyArt;
@property (readonly) AIMSession * session;

- (AIMBuddy *)buddyWithUsername:(NSString *)username;
- (id)initWithSession:(AIMSession *)_session;
- (void)handleSessionSnac:(SNAC *)snac;

- (BOOL)connectToBART;

- (void)handleNickDeparted:(ANNickWInfo *)nickInfo;
- (void)handleNickArrived:(ANNickWInfo *)nickInfo;

- (BOOL)setIdleTime:(UInt16)idleTime;

@end

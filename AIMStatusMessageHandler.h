//
//  AIMStatusMessageHandler.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSessionFeedbagHandler.h"
#import "AIMBuddyStatus.h"
#import "AIMBuddyList.h"
#import "ANNickWInfo.h"


@class AIMStatusMessageHandler;
@class AIMSessionHandler;

@protocol AIMStatusMessageHandlerDelegate<NSObject>

@optional
- (void)statusMessageHandler:(AIMStatusMessageHandler *)handler gotBuddyStatus:(AIMBuddy *)buddy;

@end


@interface AIMStatusMessageHandler : NSObject {
	AIMSessionHandler * eventHandler;
	ANNickWInfo * userInfo;
	id<AIMStatusMessageHandlerDelegate> delegate;
}

@property (readonly) AIMSessionHandler * eventHandler;
@property (nonatomic, assign) id<AIMStatusMessageHandlerDelegate> delegate;
@property (nonatomic, retain) ANNickWInfo * userInfo;

- (id)initWithEventHandler:(AIMSessionHandler *)_eventHandler;

- (BOOL)handleLocateResponse:(SNAC *)locateResponse;
- (BOOL)handleBuddyArrived:(ANNickWInfo *)buddy;
- (BOOL)handleBuddyDeparted:(ANNickWInfo *)buddy;

- (BOOL)setBuddyStatus:(AIMBuddyStatus *)status;
- (BOOL)setUnavailableMessage:(NSString *)message;
- (BOOL)setStatusMessage:(NSString *)regularStatus;

- (BOOL)queryBuddyStatusMessage:(AIMBuddy *)buddy;
- (BOOL)handleUserInfo:(SNAC *)_userInfo;

@end

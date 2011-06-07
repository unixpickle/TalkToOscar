//
//  MainClass.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMSessionMessageSender.h"
#import "AIMSessionHandler.h"
#import "AIMSessionFeedbagOperator.h"
#import "AOLRTF.h"
#import "ANEP.h"

@interface MainClass : NSObject <AIMSessionDelegate, AIMSessionHandlerDelegate> {
	AIMSession * session;
	AIMSessionMessageSender * messageSender;
	AIMSessionHandler * sessionEvents;
	AIMSessionFeedbagOperator * feedbagOperator;
	BOOL hasSentInitial;
}

- (void)main;
- (void)sendMessage:(NSString *)msg toBuddy:(AIMBuddy *)buddy;

@end

//
//  AIMSessionMessages.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMMessage.h"

#define kTypingEventStop 0
#define kTypingEventStart 1
#define kTypingEventWindowClosed 2

@protocol AIMSessionMessages

- (BOOL)sendMessage:(AIMMessage *)message;
- (BOOL)sendEvent:(UInt16)eventType toBuddy:(id)buddy;

@end

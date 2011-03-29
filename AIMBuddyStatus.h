//
//  AIMBuddyStatus.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	kAIMBuddyStatusTypeOnline = 1,
	kAIMBuddyStatusTypeAway = 2,
	kAIMBuddyStatusTypeOffline = 3
} AIMBuddyStatusType;

@interface AIMBuddyStatus : NSObject {
	NSString * statusMessage;
	AIMBuddyStatusType statusType;
}

@property (nonatomic, retain) NSString * statusMessage;
@property (readwrite) AIMBuddyStatusType statusType;

- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type;

@end

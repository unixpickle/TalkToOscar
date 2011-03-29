//
//  ANICBMEvent.h
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANICBMCookie.h"
#import "SNAC.h"

/* No typing is in progress */
#define ICBM_EVENT_NONE 0
/* They have typed, but stopped for the last 2 seconds */
#define ICBM_EVENT_TYPED 1
/* They are typing */
#define ICBM_EVENT_TYPING 2
/* If you use this, you'll die */
#define ICBM_EVENT_RESERVED 3
/* They closed the window */
#define ICBM_EVENT_CLOSED 4


@interface ANICBMEvent : NSObject {
	NSString * username;
	ANICBMCookie * cookie;
	UInt16 eventType;
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) ANICBMCookie * cookie;
@property (readwrite) UInt16 eventType;

// decode the data of a SNAC.
- (id)initWithIncomingSnac:(SNAC *)snac;
// create for sending events.
- (id)initWithEventType:(UInt16)event toUser:(NSString *)_username;

// encode the data for a FLAP packet so that you can
// notify another client of the event.
- (NSData *)encodeOutgoingEvent;

@end

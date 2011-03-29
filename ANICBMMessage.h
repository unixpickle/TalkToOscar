//
//  ANICBMMessage.h
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANNickWInfo.h"
#import "SNAC.h"
#import "ANICBMCookie.h"

@interface ANICBMMessage : NSObject {
	NSString * message;
	NSString * toUser;
	ANICBMCookie * cookie;
	ANNickWInfo * sender;
}

// contains the contents of the message.
@property (nonatomic, retain) NSString * message;
// if we are sending this message, this will be set.
@property (nonatomic, retain) NSString * toUser;
// if we are sending this message, this will be set.
@property (nonatomic, retain) ANICBMCookie * cookie;
// contains the NickwInfo of the person who sent the message.
@property (nonatomic, retain) ANNickWInfo * sender;


// parse an incoming message snac.  returns nil if invalid.
- (id)initWithIncomingSnac:(SNAC *)snac;
// create an outgoing message, encode via encodeOutgoingMessage.
- (id)initWithMessage:(NSString *)_message to:(NSString *)username;

// this only works if we are encoding a message
// that was created with initWithMessage:to:
- (NSData *)encodeOutgoingMessage;

@end

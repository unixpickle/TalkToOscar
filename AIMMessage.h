//
//  AIMMessage.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIMBuddy.h"

@interface AIMMessage : NSObject {
	NSString * message;
	AIMBuddy * buddy;
}

- (id)initWithMessage:(NSString *)_message buddy:(AIMBuddy *)_buddy;

@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) AIMBuddy * buddy;

@end

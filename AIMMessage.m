//
//  AIMMessage.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMMessage.h"


@implementation AIMMessage

@synthesize message;
@synthesize buddy;

- (id)initWithMessage:(NSString *)_message buddy:(AIMBuddy *)_buddy {
	if (self = [super init]) {
		self.message = _message;
		self.buddy = _buddy;
	}
	return self;
}

- (void)dealloc {
	self.message = nil;
	self.buddy = nil;
	[super dealloc];
}

@end

//
//  AIMFeedbagOperation.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFeedbagOperation.h"


@implementation AIMFeedbagOperation

@synthesize operationType;
@synthesize buddyName;
@synthesize groupName;
@synthesize integerMode;
@synthesize transactionBuffer;

- (void)dealloc {
	self.buddyName = nil;
	self.groupName = nil;
	self.transactionBuffer = nil;
	[super dealloc];
}

@end

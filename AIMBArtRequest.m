//
//  AIMBartRequest.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBArtRequest.h"


@implementation AIMBArtRequest

@synthesize bartID;
@synthesize queryUsername;

- (id)initWithBartID:(ANBArtID *)_bartID username:(NSString *)_queryUsername {
	if (self = [super init]) {
		self.bartID = _bartID;
		self.queryUsername = _queryUsername;
	}
	return self;
}

- (void)dealloc {
	self.bartID = nil;
	self.queryUsername = nil;
	[super dealloc];
}

@end

//
//  ANOSCARAuthorizationResponse.m
//  OSCARAPI
//
//  Created by Alex Nichol on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANOSCARAuthorizationResponse.h"


@implementation ANOSCARAuthorizationResponse

@synthesize hostName;
@synthesize port;
@synthesize cookie;

- (id)description {
	return [NSString stringWithFormat:@"Authorization Response:\nHost \t=\t %@\nPort \t=\t %d\nCookie \t=\t %@", hostName, port, cookie];
}

- (void)dealloc {
	self.hostName = nil;
	self.cookie = nil;
	[super dealloc];
}

@end

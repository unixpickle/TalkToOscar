//
//  ANICBMCookie.m
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANICBMCookie.h"


@implementation ANICBMCookie

@synthesize bytes;
@synthesize userInfo;

- (BOOL)isEqualToCookie:(ANICBMCookie *)cookie {
	if ([self.bytes isEqual:cookie.bytes]) {
		return YES;
	}
	return NO;
}

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[self class]]) {
		// then use isEqualToCookie:
		return [self isEqualToCookie:(ANICBMCookie *)object];
	} else return [super isEqual:object];
}

+ (ANICBMCookie *)randomCookie {
	UInt32 randomBytes1 = arc4random();
	UInt32 randomBytes2 = arc4random();
	char randomBytes[8];
	memcpy(randomBytes, &randomBytes1, 4);
	memcpy(&randomBytes[4], &randomBytes2, 4);
	ANICBMCookie * cookie = [[ANICBMCookie alloc] init];
	cookie.bytes = [NSData dataWithBytes:randomBytes length:8];
	return [cookie autorelease];
}

- (void)dealloc {
	self.bytes = nil;
	self.userInfo = nil;
	[super dealloc];
}

@end

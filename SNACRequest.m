//
//  SNACRequest.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SNACRequest.h"


@implementation SNACRequest

@synthesize snac_id;
@synthesize requestID;
@synthesize responses;
@synthesize userInfo;

- (id)init {
	if (self = [super init]) {
		responses = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithSNAC:(SNAC *)snac {
	// im very SELFish!
	if (self = [self init]) {
		snac_id = [snac snac_id];
		requestID = [snac requestID];
	}
	return self;
}

- (void)dealloc {
	self.responses = nil;
	self.userInfo = nil;
	[super dealloc];
}

@end

@implementation NSMutableArray (SNACRequest)

- (SNACRequest *)snacRequestWithID:(UInt32)requestID {
	for (SNACRequest * request in self) {
		if ([request requestID] == requestID) return request;
	}
	return nil;
}

@end

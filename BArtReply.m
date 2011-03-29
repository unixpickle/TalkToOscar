//
//  BArtReply.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BArtReply.h"


@implementation BArtReply

@synthesize assetOwner;
@synthesize replyID;
@synthesize assetData;

- (id)initWithData:(NSData *)replyData {
	if (self = [super init]) {
		const char * bytes = [replyData bytes];
		if ([replyData length] < 2) {
			[super dealloc];
			return nil;
		}
		
		UInt8 refLength = *(const UInt8 *)([replyData bytes]);
		if (refLength + 1 > [replyData length]) {
			[super dealloc];
			return nil;
		}
		
		int index = ([replyData length] - (1 + refLength));
		int remainingLength = index;
		
		assetOwner = [[NSString alloc] initWithBytes:&bytes[1] length:refLength encoding:NSASCIIStringEncoding];
		replyID = [[BArtQueryReplyID alloc] initWithPointer:&bytes[1 + refLength] length:&remainingLength];
		
		if (!replyID) {
			self.assetOwner = nil;
			[super dealloc];
			return nil;
		}
		
		index = remainingLength + (1 + refLength);
		
		if (index + 2 > [replyData length]) {
			self.assetOwner = nil;
			self.replyID = nil;
			[super dealloc];
			return nil;
		}
		
		UInt16 dataLength = flipUInt16(*(const UInt16 *)(&bytes[index]));
		index += 2;
		if (index + dataLength > [replyData length]) {
			self.assetOwner = nil;
			self.replyID = nil;
			[super dealloc];
			return nil;
		}
		
		assetData = [[NSData alloc] initWithBytes:&bytes[index] length:dataLength];
	}
	return self;
}

- (void)dealloc {
	self.assetOwner = nil;
	self.replyID = nil;
	self.assetData = nil;
	[super dealloc];
}

@end

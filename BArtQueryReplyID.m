//
//  BArtQueryReplyID.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BArtQueryReplyID.h"


@implementation BArtQueryReplyID

@synthesize queryID;
@synthesize code;
@synthesize replyID;

- (id)initWithData:(NSData *)data {
	const char * bytes = [data bytes];
	int _length = [data length];
	self = [self initWithPointer:bytes length:&_length];
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)_length {
	if (self = [super init]) {
		if (*_length < 2) {
			[super dealloc];
			return nil;
		}
		int firstLength = *_length;
		const char * bytes = ptr;
		queryID = [[ANBArtID alloc] initWithPointer:bytes length:&firstLength];
		if (!queryID) {
			[super dealloc];
			return nil;
		}
		if (*_length - firstLength < 1) {
			self.queryID = nil;
			[super dealloc];
			return nil;
		}
		
		code = *((const UInt8 *)&bytes[firstLength]);
		int currentIndex = firstLength + 1;
		firstLength = *_length - (currentIndex);
		
		replyID = [[ANBArtID alloc] initWithPointer:&bytes[currentIndex] length:&firstLength];
		if (!replyID) {
			self.queryID = nil;
			[super dealloc];
			return nil;
		}
		*_length = firstLength + currentIndex;
	}
	return self;
}

- (id)initWithCode:(UInt8)_code {
	if (self = [super init]) {
		code = _code;
	}
	return self;
}

- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendData:[self.queryID encodePacket]];
	[encoded appendBytes:&code length:1];
	[encoded appendData:[self.replyID encodePacket]];
	
	// create an immutable version of our data
	NSData * immutableReplyID = [NSData dataWithData:encoded];
	[encoded release];
	return immutableReplyID;
}

- (NSString *)codeErrorMessage {
	switch (code) {
		case 1:
			return @"ID is malformed";
			break;
		case 2:
			return @"Custom blobs are not allowed for this type";
			break;
		case 3:
			return @"Item is too small for this type";
			break;
		case 4:
			return @"Item is too large for this type";
			break;
		case 5:
			return @"Item is the wrong type";
			break;
		case 6:
			return @"The uploaded item was banned";
			break;
		case 7:
			return @"The downloaded item was not found";
			break;
	}
	return @"An unknown error has occured";
}
- (NSError *)codeError {
	NSDictionary * userInfo = [NSDictionary dictionaryWithObject:[self codeErrorMessage] forKey:NSLocalizedDescriptionKey];
	NSError * error = [NSError errorWithDomain:@"Bart Reply" code:code userInfo:userInfo];
	return error;
}
- (BOOL)wasDownloadSuccess {
	if (code == 0) return YES;
	return NO;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[BArtQueryReplyID allocWithZone:zone] initWithData:[self encodePacket]];
}

- (id)copy {
	return [[BArtQueryReplyID alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self encodePacket]];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [self initWithData:[aDecoder decodeObject]]) {
		
	}
	return self;
}

- (void)dealloc {
	self.queryID = nil;
	self.replyID = nil;
	[super dealloc];
}

@end

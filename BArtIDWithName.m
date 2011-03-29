//
//  BArtIDWithName.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BArtIDWithName.h"


@implementation BArtIDWithName

@synthesize requesterName;
@synthesize bartIDs;

- (id)initWithData:(NSData *)data {
	const char * bytes = [data bytes];
	int byteLength = [data length];
	self = [self initWithPointer:bytes length:&byteLength];
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)_length {
	if (self = [super init]) {
		if (*_length < 1) {
			[super dealloc];
			return nil;
		}
		UInt8 strLen = *(const UInt8 *)ptr;
		if (strLen + 1 > *_length) {
			[super dealloc];
			return nil;
		}
		
		requesterName = [[NSString alloc] initWithBytes:&ptr[1] length:strLen encoding:NSUTF8StringEncoding];
		
		NSData * finalData = [[NSData alloc] initWithBytes:&ptr[1 + strLen] length:(*_length - (1 + strLen))];
		const char * bytes = [finalData bytes];
		int bartLength = [finalData length];
		
		NSArray * barts = [ANBArtID decodeBARTIDArray:bytes length:&bartLength];
		[finalData release];
		
		self.bartIDs = barts;
		if (!barts) {
			self.requesterName = nil;
			[super dealloc];
			return nil;
		}
		
		*_length = bartLength + strLen + 1;
	}
	return self;
}

- (NSData *)encodePacket {
	UInt8 countFlip = [bartIDs count];
	NSMutableData * data = [[NSMutableData alloc] init];
	NSData * requestNameData = encodeString8(requesterName);
	[data appendData:requestNameData];
	[data appendBytes:&countFlip length:1];
	for (int i = 0; i < [bartIDs count]; i++) {
		[data appendData:[[bartIDs objectAtIndex:i] encodePacket]];
	}
	
	// create an immutable data.
	NSData * immutable = [NSData dataWithData:data];
	[data release];
	return immutable;
}

+ (BArtIDWithName *)bartIDWithName:(NSString *)username bArtID:(ANBArtID *)bartID {
	BArtIDWithName * bid = [[BArtIDWithName alloc] init];
	bid.requesterName = username;
	bid.bartIDs = [NSArray arrayWithObject:bartID];
	return [bid autorelease];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[BArtIDWithName allocWithZone:zone] initWithData:[self encodePacket]];
}

- (id)copy {
	return [[BArtIDWithName alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeDataObject:[self encodePacket]];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [self initWithData:[aDecoder decodeDataObject]]) {
	}
	return self;
}

- (void)dealloc {
	self.bartIDs = nil;
	self.requesterName = nil;
	[super dealloc];
}

@end

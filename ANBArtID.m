//
//  ANBARTID.m
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANBArtID.h"


@implementation ANBArtID

@synthesize type;
@synthesize flags;
@synthesize length;
@synthesize opaqueData;

- (id)initWithData:(NSData *)data {
	int _length = [data length];
	const char * ptr = (const char *)[data bytes];
	self = [self initWithPointer:ptr length:&_length];
	return self;
}

// this function takes ptr, a pointer to the start
// of a BART_ID data.  _length must be the length
// of that data.  _length will become the length
// used in creating the bartID.
- (id)initWithPointer:(const char *)ptr length:(int *)_length {
	if (self = [super init]) {
		// create
		if (*_length < 4) {
			[super dealloc];
			return nil;
		}
		self.type = flipUInt16(*(const UInt16 *)ptr);
		self.flags = *(const UInt8 *)(&ptr[2]);
		self.length = *(const UInt8 *)(&ptr[3]);
		if (self.length + 4 > *_length) {
			[super dealloc];
			return nil;
		}
		self.opaqueData = [NSData dataWithBytes:&ptr[4]
										 length:self.length];
		*_length = self.length + 4;
	}
	return self;
}

// Encodes a BART ID to NSData.
- (NSData *)encodePacket {
	UInt16 typesFlip = flipUInt16(type);
	NSMutableData * data = [NSMutableData data];
	[data appendBytes:&typesFlip length:2];
	[data appendBytes:&flags length:1];
	[data appendBytes:&length length:1];
	[data appendData:self.opaqueData];
	return data;
}

- (BOOL)isEqual:(id)object {
	if (self == object) return YES;
	if ([object isKindOfClass:[self class]]) {
		ANBArtID * bid = (ANBArtID *)object;
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		BOOL eq = [[bid encodePacket] isEqual:[self encodePacket]];
		[pool drain];
		return eq;
	} else return NO;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[ANBArtID allocWithZone:zone] initWithData:[self encodePacket]];
}

- (id)copy {
	return [[ANBArtID alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:type forKey:@"type"];
	[aCoder encodeInt:flags forKey:@"flags"];
	[aCoder encodeObject:self.opaqueData forKey:@"data"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		type = [aDecoder decodeIntForKey:@"type"];
		flags = [aDecoder decodeIntForKey:@"flags"];
		self.opaqueData = [[aDecoder decodeObjectForKey:@"data"] copy];
	}
	return self;
}

- (void)dealloc {
	self.opaqueData = nil;
	[super dealloc];
}

// decodes as many bart ids as it can, gives you the
// length used.
+ (NSArray *)decodeBARTIDArray:(const char *)ptr length:(int *)_length {
	int index = 0;
	NSMutableArray * barts = [[NSMutableArray alloc] init];
	while (index < *_length - 4) {
		int addLength = *_length - index;
		ANBArtID * anotherBart = [[ANBArtID alloc] initWithPointer:&ptr[index]
															length:&addLength];
		if (!anotherBart) break;
		[barts addObject:anotherBart];
		[anotherBart release];
		index += addLength;
	}
	
	*_length = index;
	
	// create an immutable form of barts.
	NSArray * immutableBarts = [NSArray arrayWithArray:barts];
	[barts release];
	return immutableBarts;
}

@end

//
//  ANNickWInfo.m
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANNickWInfo.h"


@implementation ANNickWInfo

@synthesize evil;
@synthesize username;
@synthesize userAttributes;

- (id)initWithData:(NSData *)nickWInfo {
	if (!nickWInfo) {
		[super dealloc];
		return nil;
	}
	const char * ptr = (const char *)[nickWInfo bytes];
	int length = [nickWInfo length];
	if (self = [self initWithPointer:ptr length:&length]) {
		// yeah.
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)_length {
	if (self = [super init]) {
		if (*_length < 2) return nil;
		int mlength = *_length;
		NSData * nickWInfo = [NSData dataWithBytes:ptr length:mlength];
		UInt8 length = *(const UInt8 *)[nickWInfo bytes];
		if (length + 1 >= [nickWInfo length]) {
			[super dealloc];
			return nil;
		}
		
		self.username = [[[NSString alloc] initWithBytes:&((const char *)[nickWInfo bytes])[1]
												  length:length
												encoding:NSUTF8StringEncoding] autorelease];
		
		if (length + 1 + 2 >= [nickWInfo length]) {
			self.username = nil;
			[super dealloc];
			return nil;
		}
		
		evil = flipUInt16(*((const UInt16 *)(&((const char *)[nickWInfo bytes])[length + 1])));
		int index = length + 3;
		
		int addLength = ([nickWInfo length] - index);
		
		// we want a mutable version of this.
		NSArray * _userAttributes = [TLV decodeTLVBlock:&((const char *)[nickWInfo bytes])[index]
											 length:&addLength];
		if (!_userAttributes) addLength = 2;
		self.userAttributes = [NSMutableArray arrayWithArray:_userAttributes];
		
		*_length = index + addLength;
	}
	return self;
}

- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	UInt16 flippedEvil = flipUInt16(evil);
	[encoded appendData:encodeString8(username)];
	[encoded appendBytes:&flippedEvil length:2];
	[encoded appendData:[TLV encodeTLVBlock:self.userAttributes]];
	
	// create immutable version
	NSData * immutableNickInfo = [NSData dataWithData:encoded];
	[encoded release];
	return immutableNickInfo;
}

// copies fields that we might now have available
- (void)copyAttributesFromInfo:(ANNickWInfo *)nickInfo {
	// copy all attributes other than
	// bart iD
	for (TLV * t in nickInfo.userAttributes) {
		TLV * myAttribute = [self attributeOfType:t.type];
		if (!myAttribute) {
			[self.userAttributes addObject:t];
		}
	}
	
	[self copyBartIDsFromInfo:nickInfo];
}

- (void)copyBartIDsFromInfo:(ANNickWInfo *)nickInfo {
	// copy all BART IDs.
	NSArray * array = [nickInfo bartIDs];
	NSArray * myIds = [self bartIDs];
	// get BART IDs that we do not have, add them
	// to one piece of data.
	NSMutableData * addData = [NSMutableData data];
	for (ANBArtID * mId in array) {
		BOOL has = NO;
		for (ANBArtID * bid in myIds) {
			if ([bid type] == [mId type]) has = YES;
		}
		if (!has) {
			[addData appendData:[mId encodePacket]];
		}
	}
	// get our BIDs, append all of the BIDs that we don't have.
	NSData * bidData = nil;
	for (TLV * packet in self.userAttributes) {
		if ([packet type] == TLV_BART_INFO) { /*BART_INFO*/
			bidData = [packet tlvData];
		}
	}
	NSMutableData * bidDataArray = [[NSMutableData alloc] init];
	if (bidData) {
		[bidDataArray appendData:bidData];
	}
	[bidDataArray appendData:addData];
	if (!bidData) {
		TLV * packet = [[TLV alloc] initWithType:TLV_BART_INFO
											data:bidDataArray];
		[self.userAttributes addObject:packet];
		[packet release];
	} else {
		for (TLV * packet in self.userAttributes) {
			if ([packet type] == TLV_BART_INFO) { /*BART_INFO*/
				[packet setTlvData:bidDataArray];
			}
		}
	}
	[bidDataArray release];
}

+ (NSArray *)decodeArray:(NSData *)arrayOfNicks {
	NSMutableArray * list = [[NSMutableArray alloc] init];
	const char * bytes = [arrayOfNicks bytes];
	int index = 0;
	int totalLength = [arrayOfNicks length];
	while (totalLength > 0) {
		int justUsed = totalLength;
		ANNickWInfo * nick = [[ANNickWInfo alloc] initWithPointer:&bytes[index] length:&justUsed];
		if (!nick) {
			[list release];
			[nick release];
			return nil;
		}
		[list addObject:nick];
		[nick release];
		index += justUsed;
		totalLength -= justUsed;
	}
	
	// create an immutable version
	NSArray * immutableNicks = [NSArray arrayWithArray:list];
	[list release];
	return immutableNicks;
}

#pragma mark Extraction

- (ANBArtID *)extractStatus {
	ANBArtID * status = nil;
	for (TLV * packet in self.userAttributes) {
		if ([packet type] == TLV_BART_INFO) { /*BART_INFO*/
			int mLength = [[packet tlvData] length];
			NSArray * bartList = [ANBArtID decodeBARTIDArray:[[packet tlvData] bytes]
													  length:&mLength];
			for (ANBArtID * bid in bartList) {
				if ([bid type] == STATUS_STR) {
					status = bid;
				}
			}
		}
	}
	return status;
}

- (ANBArtID *)extractIcon {
	ANBArtID * icon = nil;
	NSArray * bartList = [self bartIDs];
	for (ANBArtID * bid in bartList) {
		if ([bid type] == BUDDY_ICON) {
			icon = bid;
		}
	}
	return icon;
}

- (ANBArtID *)extractSmallIcon {
	ANBArtID * icon = nil;
	NSArray * bartList = [self bartIDs];
	for (ANBArtID * bid in bartList) {
		if ([bid type] == BUDDY_ICON_SMALL) {
			icon = bid;
		}
	}
	return icon;
}

- (NSArray *)bartIDs {
	for (TLV * packet in self.userAttributes) {
		if ([packet type] == TLV_BART_INFO) { /*BART_INFO*/
			int mLength = [[packet tlvData] length];
			NSArray * bartList = [ANBArtID decodeBARTIDArray:[[packet tlvData] bytes]
													  length:&mLength];
			return bartList;
		}
	}
	return nil;
}

- (UInt16)nickFlags {
	for (TLV * attr in self.userAttributes) {
		if ([attr type] == TLV_NICK_FLAGS) {
			if ([[attr tlvData] length] != 2) return 0;
			UInt16 data = *(const UInt16 *)[[attr tlvData] bytes];
			return flipUInt16(data);
		}
	}
	return 0;
}

- (TLV *)attributeOfType:(UInt16)_attribute {
	for (TLV * attribute in self.userAttributes) {
		if ([attribute type] == _attribute) return attribute;
	}
	return nil;
}

#pragma mark NSCopying

- (ANNickWInfo *)copyWithZone:(NSZone *)zone {
	return [[ANNickWInfo allocWithZone:zone] initWithData:[self encodePacket]];
}

- (ANNickWInfo *)copy {
	return [[ANNickWInfo alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:evil forKey:@"evil"];
	[aCoder encodeObject:username forKey:@"username"];
	[aCoder encodeObject:userAttributes forKey:@"attributes"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		evil = [aDecoder decodeIntForKey:@"evil"];
		username = [[aDecoder decodeObjectForKey:@"username"] copy];
		userAttributes = [[NSMutableArray alloc] initWithArray:[aDecoder decodeObjectForKey:@"attributes"]];
	}
	return self;
}

- (BOOL)isEqual:(id)object {
	if (self == object) return YES;
	if ([object isKindOfClass:[self class]]) {
		ANNickWInfo * bid = (ANNickWInfo *)object;
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		BOOL eq = YES;
		if (![self.username isEqual:bid.username]) {
			eq = NO;
		}
		[pool drain];
		return eq;
	} else return NO;
}

- (void)dealloc {
	self.username = nil;
	self.userAttributes = nil;
	[super dealloc];
}

@end

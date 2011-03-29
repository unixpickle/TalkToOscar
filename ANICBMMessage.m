//
//  ANICBMMessage.m
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANICBMMessage.h"


@implementation ANICBMMessage

@synthesize message;
@synthesize cookie;
@synthesize sender;
@synthesize toUser;

- (id)initWithIncomingSnac:(SNAC *)snac {
	// parse the snac data.
	if (self = [super init]) {
		char cookieBytes[8];
		UInt16 channel;
		NSData * data = [snac innerContents];
		
		if ([data length] <= 10) {
			[super dealloc];
			return nil;
		}
		
		const char * bytes = (const char *)[data bytes];
		memcpy(cookieBytes, bytes, 8);
		memcpy(&channel, &bytes[8], 2);
		channel = flipUInt16(channel);
			 
		// read the NickwInfo.
		int startLength = [data length] - 10;
		ANNickWInfo * nickInfo = [[ANNickWInfo alloc] initWithPointer:&bytes[10]
															   length:&startLength];
		// update the status
		int newIndex = 10 + startLength;
		if (newIndex > [data length]) {
			[nickInfo release];
			[super dealloc];
			return nil;
		}
		
		NSData * tlvListData = [NSData dataWithBytes:&bytes[newIndex]
											  length:([data length] - newIndex)];
		NSArray * tlvList = [TLV decodeTLVArray:tlvListData];
		
		if (!tlvList) {
			[nickInfo release];
			[super dealloc];
			return nil;
		}
		
		NSData * imData = nil;
		
		for (TLV * pack in tlvList) {
			if ([pack type] == TLV_ICBM__TAGS_IM_DATA) {
				imData = [pack tlvData];
			}
		}
		
		if (!imData) {
			[nickInfo release];
			[super dealloc];
			return nil;
		}
		
		NSArray * tlvArray = [TLV decodeTLVArray:imData];
		for (TLV * pack in tlvArray) {
			if ([pack type] == TLV_ICBM__IM_DATA_TAGS_IM_TEXT) {
				// get the IM_TEXT, and read from the fourth byte.
				imData = [NSData dataWithBytes:&((const char *)[[pack tlvData] bytes])[4]
										length:([[pack tlvData] length] - 4)];
			}
		}
		
		// this is the string of the message.
		NSString * string = [[NSString alloc] initWithData:imData 
												  encoding:NSWindowsCP1252StringEncoding];

		self.sender = nickInfo;
		self.message = string;
		self.cookie = [[[ANICBMCookie alloc] init] autorelease];
		self.cookie.bytes = [NSData dataWithBytes:cookieBytes
										   length:8];
		
		[nickInfo release];
		[string release];
	}
	return self;
}
- (id)initWithMessage:(NSString *)_message to:(NSString *)username {
	if (self = [super init]) {
		self.message = _message;
		self.toUser = username;
		self.cookie = [ANICBMCookie randomCookie];
		sender = nil;
	}
	return self;
}

- (NSData *)encodeOutgoingMessage {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// used as the length of the username
	// to whom we are sending.
	UInt8 toLen = [toUser length];
	
	// used for writing byte to data, 
	// needs to be here.
	UInt8 capabilities = 1; // MESSAGE
	
	// the IM_DATA message part.
	NSMutableData * imDataDat = [NSMutableData data];
	
	UInt16 encoding = 0; // ASCII
	UInt16 language = 0; // english
	UInt16 channel = flipUInt16(1); // ICBM_CHANNELS_IM
	
	[imDataDat appendBytes:&encoding length:2];
	[imDataDat appendBytes:&language length:2];
	[imDataDat appendData:[message dataUsingEncoding:NSASCIIStringEncoding]];
	
	TLV * hostAck = [[TLV alloc] initWithType:TLV_ICBM__TAGS_REQUEST_HOST_ACK data:[NSData data]];
	TLV * imCapabilities = [[[TLV alloc] initWithType:TLV_ICBM__IM_DATA_TAGS_IM_CAPABILITIES
												 data:[NSData dataWithBytes:&capabilities length:1]] autorelease];
	TLV * imText = [[TLV alloc] initWithType:TLV_ICBM__IM_DATA_TAGS_IM_TEXT data:imDataDat];
	
	// overall packet data for the message part.
	NSMutableData * imData = [NSMutableData data];
	
	[imData appendData:[imCapabilities encodePacket]];
	[imData appendData:[imText encodePacket]];
	
	// the MESSAGE content.
	TLV * imDataPacket = [[TLV alloc] initWithType:TLV_ICBM__TAGS_IM_DATA data:imData];
	
	// create the snac which follows the message ICBM format.
	
	// COOKIE
	// CHANNEL
	// TO NAME (str8)
	// HOST ACK
	// IM_DATA
	
	NSMutableData * snacData = [[NSMutableData alloc] init];
	[snacData appendData:[cookie bytes]];
	[snacData appendBytes:&channel
				   length:2];
	[snacData appendBytes:&toLen length:1];
	[snacData appendBytes:[toUser UTF8String] length:toLen];
	[snacData appendData:[hostAck encodePacket]];
	[snacData appendData:[imDataPacket encodePacket]];
	
	// free our memory.
	[hostAck release];
	[imDataPacket release];
	[imText release];
	
	[pool drain];
	
	return [snacData autorelease];
}

- (void)dealloc {
	self.message = nil;
	self.sender = nil;
	self.toUser = nil;
	self.cookie = nil;
	[super dealloc];
}

@end

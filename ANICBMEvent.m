//
//  ANICBMEvent.m
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANICBMEvent.h"


@implementation ANICBMEvent

@synthesize username;
@synthesize cookie;
@synthesize eventType;

// decode the data of a SNAC.
- (id)initWithIncomingSnac:(SNAC *)snac {
	if (self = [super init]) {
		// this is a typing event of some sort, we have to handle it.
		NSData * d = [snac innerContents];
		// if it's less than 10 bytes, it's probably not valid.
		if ([d length] < 10) {
			[super dealloc];
			return nil;
		}
		
		// the bytes for the data, I just do this
		// for shorthand.
		const char * bytes = (const char *)[d bytes];
		// the bytes of the cookie.
		char cookieBytes[8];
		memcpy(cookieBytes, bytes, 8);
		// parse that sucker
		UInt8 loginIDLen = (*(const UInt16 *)(&bytes[10]));
		if (loginIDLen + 11 + 2 > [d length]) {
			[super dealloc];
			return nil;
		}
		
		// get the username that they were using.
		NSString * login = [[NSString alloc] initWithBytes:&bytes[11]
													length:loginIDLen
												  encoding:NSASCIIStringEncoding];
		
		// the type of event.
		UInt16 event = flipUInt16(*(const UInt16 *)(&bytes[loginIDLen + 11]));
		self.eventType = event;
		self.username = login;
		self.cookie = [[[ANICBMCookie alloc] init] autorelease];
		self.cookie.bytes = [NSData dataWithBytes:cookieBytes
										   length:8];
		
		[login release];
	}
	return self;
}

// create for sending events.
- (id)initWithEventType:(UInt16)event toUser:(NSString *)_username {
	if (self = [super init]) {
		self.eventType = event;
		self.username = _username;
		self.cookie = [ANICBMCookie randomCookie];
	}
	return self;
}

// encode the data for a FLAP packet so that you can
// notify another client of the event.
- (NSData *)encodeOutgoingEvent {
	UInt8 toLen = [username length];
	UInt16 channel = flipUInt16(1); // ICBM_CHANNELS_IM
	
	UInt16 event = flipUInt16(eventType); /* ICBM_EVENTS_TYPED */
	NSMutableData * snacData = [[NSMutableData alloc] init];
	[snacData appendBytes:[self.cookie.bytes bytes]
				   length:8];
	[snacData appendBytes:&channel
				   length:2];
	[snacData appendBytes:&toLen length:1];
	[snacData appendBytes:[username UTF8String] length:[username length]];
	[snacData appendBytes:&event
				   length:2];
	
	return [snacData autorelease];
}

- (void)dealloc {
	self.username = nil;
	self.cookie = nil;
	[super dealloc];
}

@end

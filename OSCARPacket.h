//
//  OSCARPacket.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol OSCARPacket <NSCopying, NSCoding>

// creates a packet with data.
- (id)initWithData:(NSData *)data;

// creates a packet with data at an address.
// returns length in *length of the amount
// of bytes it used.
- (id)initWithPointer:(const char *)ptr length:(int *)length;

// encodes the packet, this should work so that
// [initWithData:[self encodePacket]] returns
// a replica of the data provided.
- (NSData *)encodePacket;

@end

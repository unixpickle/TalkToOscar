//
//  ANBARTID.h
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "flipbit.h"

#define STATUS_STR 2
#define BUDDY_ICON 1
#define BUDDY_ICON_SMALL 0

@interface ANBArtID : NSObject <OSCARPacket> {
	UInt16 type;
	UInt8 flags;
	UInt8 length;
	NSData * opaqueData;
}

@property (readwrite) UInt16 type;
@property (readwrite) UInt8 flags;
@property (readwrite) UInt8 length;
@property (nonatomic, retain) NSData * opaqueData;

// decodes as many bart ids as it can, gives you the
// length used.
+ (NSArray *)decodeBARTIDArray:(const char *)ptr length:(int *)_length;

@end

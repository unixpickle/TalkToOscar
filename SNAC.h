//
//  SNAC.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "TLV.h"
#import "SNAC_Types.h"
#import "flipbit.h"

typedef struct {
	UInt16 foodgroup;
	UInt16 type;
} SNAC_ID;

// macros for snac ID
SNAC_ID SNAC_ID_NEW (UInt16 foodgroup, UInt16 type);
SNAC_ID SNAC_ID_FLIP (SNAC_ID sid);
BOOL SNAC_ID_IS_EQUAL (SNAC_ID sid, SNAC_ID sid1);
UInt32 SNAC_ID_ENCODE (SNAC_ID sid);
SNAC_ID SNAC_ID_DECODE (UInt32 buf);

// types of SNAC flags
#define OPT_TLV_PRESENT 0x8000
#define MORE_REPLIES_FOLLOW 0x0001

@interface SNAC : NSObject <OSCARPacket> {
	SNAC_ID snac_id;
	UInt16 flags;
	UInt32 requestID;
	NSData * data;
	UInt16 snac_flags;
	NSData * innerContents;
}

@property (readwrite) SNAC_ID snac_id;
@property (readwrite) UInt16 snac_flags;
@property (readwrite) UInt32 requestID;
@property (readonly) NSData * data;

- (id)initWithID:(SNAC_ID)_id flags:(UInt16)_flags requestID:(UInt32)reqID data:(NSData *)_data; 

- (UInt16)flippedFlags;
- (UInt32)flippedRequestID;

// removes a possible TLVlBlock, this should always bee used,
// rather than accessing the data property.
- (NSData *)innerContents;
- (BOOL)isLastResponse;

@end

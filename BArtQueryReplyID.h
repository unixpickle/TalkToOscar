//
//  BArtQueryReplyID.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "ANBArtID.h"

@interface BArtQueryReplyID : NSObject <OSCARPacket> {
	ANBArtID * queryID;
	UInt8 code;
	ANBArtID * replyID;
}

@property (nonatomic, retain) ANBArtID * queryID;
@property (readwrite) UInt8 code;
@property (nonatomic, retain) ANBArtID * replyID;

- (id)initWithCode:(UInt8)_code;

- (NSString *)codeErrorMessage;
- (NSError *)codeError;
- (BOOL)wasDownloadSuccess;

@end

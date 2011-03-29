//
//  BArtReply.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BArtQueryReplyID.h"

@interface BArtReply : NSObject {
	NSString * assetOwner;
	BArtQueryReplyID * replyID;
	NSData * assetData;
}

@property (nonatomic, retain) NSString * assetOwner;
@property (nonatomic, retain) BArtQueryReplyID * replyID;
@property (nonatomic, retain) NSData * assetData;

- (id)initWithData:(NSData *)replyData;

@end

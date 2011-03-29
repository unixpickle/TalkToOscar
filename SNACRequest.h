//
//  SNACRequest.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNAC.h"

@interface SNACRequest : NSObject {
	SNAC_ID snac_id;
	UInt32 requestID;
	NSMutableArray * responses;
	id userInfo;
}

@property (readwrite) SNAC_ID snac_id;
@property (readwrite) UInt32 requestID;
@property (nonatomic, retain) NSMutableArray * responses;
@property (nonatomic, retain) id userInfo;

- (id)initWithSNAC:(SNAC *)snac;

@end

@interface NSMutableArray (SNACRequest)

- (SNACRequest *)snacRequestWithID:(UInt32)requestID;

@end

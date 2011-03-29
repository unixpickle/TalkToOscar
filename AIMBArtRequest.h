//
//  AIMBartRequest.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANBArtID.h"

@interface AIMBArtRequest : NSObject {
	ANBArtID * bartID;
	NSString * queryUsername;
}

@property (nonatomic, retain) ANBArtID * bartID;
@property (nonatomic, retain) NSString * queryUsername;

- (id)initWithBartID:(ANBArtID *)_bartID username:(NSString *)_queryUsername;

@end

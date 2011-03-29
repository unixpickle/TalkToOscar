//
//  BArtIDWithName.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "ANBArtID.h"
#import "BasicStrings.h"

@interface BArtIDWithName : NSObject <OSCARPacket> {
	NSString * requesterName;
	NSArray * bartIDs;
}

@property (nonatomic, retain) NSString * requesterName;
@property (nonatomic, retain) NSArray * bartIDs;

+ (BArtIDWithName *)bartIDWithName:(NSString *)username bArtID:(ANBArtID *)bartID;

@end

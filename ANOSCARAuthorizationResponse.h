//
//  ANOSCARAuthorizationResponse.h
//  OSCARAPI
//
//  Created by Alex Nichol on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ANOSCARAuthorizationResponse : NSObject {
	NSString * hostName;
	int port;
	NSData * cookie;
}

@property (nonatomic, retain) NSString * hostName;
@property (readwrite) int port;
@property (nonatomic, retain) NSData * cookie;

@end

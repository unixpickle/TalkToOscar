//
//  ANICBMCookie.h
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ANICBMCookie : NSObject {
	NSData * bytes;
	id userInfo;
}

@property (nonatomic, retain) NSData * bytes;
@property (nonatomic, retain) id userInfo;

- (BOOL)isEqualToCookie:(ANICBMCookie *)cookie;
+ (ANICBMCookie *)randomCookie;

@end

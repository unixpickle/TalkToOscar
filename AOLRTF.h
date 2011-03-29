//
//  AOLRTF.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AOLRTF)

- (NSString *)stringByRemovingAOLRTF;
- (NSString *)stringByFormattingWithAOLRTF;

@end

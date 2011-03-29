//
//  AIMFeedbag+PD.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"

#define PD_UNDEFINED 0
#define PD_PERMIT_ALL 1
#define PD_DENY_ALL 2
#define PD_PERMIT_SOME 3
#define PD_DENY_SOME 4
#define PD_PERMIT_ON_LIST 5

@interface AIMFeedbag (PD)

- (UInt8)permitDenyMode;
- (UInt8)defaultPDMode;
- (AIMFeedbagItem *)defaultFeedbagPDINFO:(UInt8)pdMode;
- (AIMFeedbagItem *)pdInfoItem;

@end

//
//  AIMSessionFeedbagOperator.h
//  TalkToOscar
//
//  Created by Alex Nichol on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSessionFeedbagHandler.h"

/**
 * Provides a way to interact with the feedbag on a buddy
 * level, rather than dealing with the database directly.
 */
@interface AIMSessionFeedbagOperator : NSObject {
    AIMSessionFeedbagHandler * feedbagHandler;
}

@property (readonly) AIMSessionFeedbagHandler * feedbagHandler;

- (id)initWithFeedbagHandler:(AIMSessionFeedbagHandler *)theFeedbagHandler;

- (BOOL)removeBuddy:(AIMBuddy *)buddy;
- (BOOL)addBuddy:(AIMBuddy *)buddy toGroup:(AIMGroup *)group;
- (BOOL)addGroup:(AIMGroup *)group;
- (BOOL)removeGroup:(AIMGroup *)group;
- (BOOL)addDenyUser:(NSString *)denyUsername;
- (BOOL)removeDenyUser:(NSString *)denyUsername;

@end

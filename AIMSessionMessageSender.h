//
//  AIMSessionMessageSender.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANICBMMessage.h"
#import "ANICBMEvent.h"
#import "AIMBuddy.h"
#import "AIMSession.h"

@interface AIMSessionMessageSender : NSObject <AIMSessionMessages> {
	AIMSession * session;
}

- (id)initWithSession:(AIMSession *)_session;

@end

//
//  AIMSessionLogin.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARConnection.h"
#import "SNAC.h"


@class AIMSession;

@interface AIMSessionLogin : NSObject <OSCARConnectionDelegate> {
	AIMSession * session;
	OSCARConnection * bossConnection;
}

- (OSCARConnection *)bossConnection;

- (id)initWithSession:(AIMSession *)_session;
- (BOOL)initializeBosConnection;
- (BOOL)sendSignon;
- (BOOL)queryFeedbag;

+ (BOOL)waitForHostReady:(OSCARConnection *)connection;
+ (SNAC *)waitOnConnection:(OSCARConnection *)connection forSnacID:(SNAC_ID)snac;
+ (BOOL)sendCookie:(NSData *)cookieData toConnection:(OSCARConnection *)connection;
+ (BOOL)signonClientOnline:(OSCARConnection *)connection;

@end

//
//  AIMBuddyArt.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BArtQueryReplyID.h"
#import "OSCARConnection.h"
#import "AIMSessionLogin.h"
#import "BArtIDWithName.h"
#import "AIMBArtRequest.h"
#import "BasicStrings.h"
#import "SNACRequest.h"
#import "BArtReply.h"
#import "AIMSession.h"
#import "ANBArtID.h"
#import "SNAC.h"

@class AIMBuddyArt;

@protocol AIMBuddyArtDelegate <NSObject>

@optional
- (void)aimBuddyArtConnected:(AIMBuddyArt *)buddyArt;
- (void)aimBuddyArtDisconnected:(AIMBuddyArt *)buddyArt;
- (void)aimBuddyArt:(AIMBuddyArt *)buddyArt bartDownload:(AIMBArtRequest *)request failedWithError:(NSError *)error;
- (void)aimBuddyArt:(AIMBuddyArt *)buddyArt uploadedBArtID:(ANBArtID *)bartID;
- (void)aimBuddyArt:(AIMBuddyArt *)buddyArt uploadFailed:(NSError *)uploadError;
- (void)aimBuddyArt:(AIMBuddyArt *)buddyArt fetched:(NSData *)bartData forBArtRequest:(AIMBArtRequest *)bartRequest;

@end


@interface AIMBuddyArt : NSObject <OSCARConnectionDelegate> {
	NSMutableArray * requests;
	NSData * loginCookie;
	NSString * bartHost;
	UInt16 bartPort;
	NSString * _username;
	OSCARConnection * bartConnection;
	id<AIMBuddyArtDelegate> delegate;
	NSData * ourBuddyIcon;
}

@property (nonatomic, assign) id<AIMBuddyArtDelegate> delegate;
@property (nonatomic, retain) NSData * ourBuddyIcon;

- (BOOL)isBartAvailable;

// returns the requestID for our owner to notify
// us about, this is the OSERVICE_RESPONSE
- (UInt32)connectToBArt:(AIMSession *)mainSession;
- (BOOL)gotOserviceResponse:(SNAC *)bartInfo;
- (BOOL)reconnectToBArt;
- (BOOL)queryBArtID:(ANBArtID *)bartID owner:(NSString *)username;
- (BOOL)uploadBArtData:(NSData *)bartData forBArtType:(UInt16)bartType;
- (BOOL)setBuddyIcon:(NSData *)iconData;
- (BOOL)disconnectBArt;

@end

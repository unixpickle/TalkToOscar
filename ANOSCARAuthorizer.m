//
//  ANOSCARAuthorizer.m
//  OSCARAPI
//
//  Created by Alex Nichol on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ANOSCARAuthorizer.h"

@implementation ANOSCARAuthorizer

@synthesize username;
@synthesize password;

// call this method to create a new authorizer with
// a delegate object.
- (id)initWithDelegate:(id<ANOSCARAuthorizerDelegate>)_delegate {
	if (self = [super init]) {
		delegate = [_delegate retain];
		stage = 0;
	}
	return self;
}

// Sends an asynchronous request to AOLs API server,
// authenticated it so that further connections
// may be estabolished.
- (BOOL)sendRequest:(NSString *)clientLogin {
	NSURL * url = [NSURL URLWithString:clientLogin];
	// create the post string
	NSString * postString = [NSString stringWithFormat:@"k=%@&s=%@&pwd=%@&clientVersion=%@&clientName=%@",
							 [kOSCARAPIKEY stringByEscapingAllAsciiCharacters],
							 [self.username stringByEscapingAllAsciiCharacters],
							 [self.password stringByEscapingAllAsciiCharacters],
							 @"1", @"ANOSCAR"];
	// create the data for the post string
	NSData * postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	// create a mutable request
	NSMutableURLRequest * request = [[[NSMutableURLRequest alloc] initWithURL:url
																 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
															 timeoutInterval:50.0f] autorelease];
	// post our post data
	[request setHTTPBody:postData];
	// set the content type required
	// by AOL
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	// tell AOL about the content length so that way everything
	// works smoothly.
	[request setValue:[NSString stringWithFormat:@"%d", [postData length]]
   forHTTPHeaderField:@"Content-Length"];
	// request method
	[request setHTTPMethod:@"POST"];
	// send the request, and release it
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request
																 delegate:self];
	[connection start];
	currentRequest = connection;
	// now we will wait to get connection information...
	return YES;
}

// method to use to process data that came in from
// the authorization server.
- (void)handleData:(NSData *)fetched {
	// handle the data that we fetched
	// successfully.
	
	NSString * data = [[[NSString alloc] initWithData:fetched 
											encoding:NSWindowsCP1252StringEncoding] autorelease];
	switch (stage) {
		case 0:
		{
			NSDictionary * parsed = [data parseHTTPParaemters];
			// we will read the status
			NSString * content = [parsed objectForKey:@"statusCode"];
			if (![content isEqual:@"200"]) {
				NSLog(@"Login status code is not good: %@", content);
				if ([(id)delegate respondsToSelector:@selector(authorizer:didFailWithError:)]) {
					NSError * error = [NSError errorWithDomain:@"Login"
														  code:[content intValue]
													  userInfo:parsed];
					[delegate authorizer:self
						didFailWithError:error];
					break;
				}
			}
			// set the secret and token
			aToken = [[parsed objectForKey:@"token_a"] retain];
			sessionSecret = [[parsed objectForKey:@"sessionSecret"] retain];
			hosttime = [[parsed objectForKey:@"hostTime"] retain];
			sessionKey = [[self createAuthenticationKey] retain];
			// create a new URL
			[self commenceOscarStart];
			break;
		}
		case 1:
		{
			// We have a string already.
			NSString * string = data;
			NSDictionary * jsonData = [string JSONValue];
			// the response object in the JSON data.
			NSDictionary * response = [jsonData objectForKey:@"response"];
			// the return statusCode, should be 200.
			NSNumber * statusCode = [response objectForKey:@"statusCode"];
			int status = [statusCode intValue];
			if (status != 200) {
				// the request returned unsuccessful.
				NSLog(@"startOSCAR error code: %d", status);
				if ([(id)delegate respondsToSelector:@selector(authorizer:didFailWithError:)]) {
					NSError * error = [NSError errorWithDomain:@"StartOSCAR"
														  code:status userInfo:response];
					[delegate authorizer:self didFailWithError:error];
				}
			} else {
				ANOSCARAuthorizationResponse * info = [[ANOSCARAuthorizationResponse alloc] init];
				// use the JSON data to populate the info object.
				NSDictionary * data = [response objectForKey:@"data"];
				info.port = [[data objectForKey:@"port"] intValue];
				info.hostName = [data objectForKey:@"host"];
				info.cookie = [NSData dataFromBase64String:(NSString *)[data objectForKey:@"cookie"]];
				if ([(id)delegate respondsToSelector:@selector(authorizer:didSucceedLogin:)]) {
					// call back the delegate saying that we got the data.
					[delegate authorizer:self
						 didSucceedLogin:info];
				}
				// release it to save memory.
				[info release];
			}
			break;
		}
		default:
			break;
	}
}

// This is for closing down the authorizer's delegate
- (void)removeDelegate {
	delegate = nil;
}

#pragma mark API Data Creation

// This will create an authentication key
// using a nice SHA256 lib that I found.
- (NSString *)createAuthenticationKey {
	hmac_sha256 hash;
	const unsigned char * key = (const unsigned char *)[self.password UTF8String];
	const unsigned char * message = (const unsigned char *)[sessionSecret UTF8String];
	hmac_sha256_initialize(&hash, key, strlen((const char *)key));
	hmac_sha256_finalize(&hash, message, strlen((const char *)message));
	const unsigned char * digest = hash.digest;
	// base64
	NSData * d = [NSData dataWithBytes:digest length:32];
	NSString * b64 = [d base64EncodedString];
	return b64;
}

// This function will generate the post data
// that needs to go to startOSCARSession.
- (NSString *)startOscarSessionPost {
	NSString * queryString = [NSString stringWithFormat:@"a=%@&f=%@&k=%@&ts=%@&useTLS=%@",
							  [aToken stringByEscapingAllAsciiCharacters],
							  @"json",
							  [kOSCARAPIKEY stringByEscapingAllAsciiCharacters],
							  hosttime,
							  @"0"];
	NSString * uri = [NSString stringWithFormat:@"https://api.oscar.aol.com/aim/startOSCARSession"];
	NSString * hashData = [NSString stringWithFormat:@"GET&%@&%@", 
						   [uri stringByEscapingAllAsciiCharacters], 
						   [queryString stringByEscapingAllAsciiCharacters]];
	hmac_sha256 hash;
	const unsigned char * key = (const unsigned char *)[sessionKey UTF8String];
	const unsigned char * message = (const unsigned char *)[hashData UTF8String];
	hmac_sha256_initialize(&hash, key, strlen((const char *)key));
	hmac_sha256_finalize(&hash, message, strlen((const char *)message));
	const unsigned char * digest = hash.digest;
	// base64
	NSData * d = [NSData dataWithBytes:digest length:32];
	NSString * b64 = [d base64EncodedString];
	// now we compose the full URL
	NSString * url = [NSString stringWithFormat:@"%@%c%@%s%@", uri, '?',
					  queryString, "&sig_sha256=", 
					  b64];
	return url;
}

// Queries the startOSCARSession WIM call.
// After this, you should tell our delegate.
- (void)commenceOscarStart {
	// get the URL
	NSString * getURL = [self startOscarSessionPost];
	NSURL * url = [NSURL URLWithString:getURL];
	// the request for the startOSCAR url.
	NSURLRequest * request = [NSURLRequest requestWithURL:url];
	NSURLConnection * conn = [[[NSURLConnection alloc] initWithRequest:request
															 delegate:self] autorelease];
	[conn start];
	currentRequest = conn;
}

#pragma mark Connection

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	currentRequest = nil;
	if ([(id)delegate respondsToSelector:@selector(authorizer:didFailWithError:)]) {
		[delegate authorizer:self didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	// got the data from our connection
	if (!currentData) {
		currentData = [[NSMutableData alloc] init];
	}
	[currentData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	currentRequest = nil;
	[self handleData:currentData];
	stage ++;
	[currentData release];
	currentData = nil;
}

- (void)dealloc {
	[delegate release];
	if (currentData) {
		NSLog(@"Warning, connection may have a problem that could cause a crash!");
		[currentData release];
		currentData = nil;
	}
	
	[currentRequest cancel];
	[aToken release];
	[sessionKey release];
	[sessionSecret release];
	[hosttime release];
	
	aToken = nil;
	sessionKey = nil;
	sessionSecret = nil;
	hosttime = nil;
		
	[super dealloc];
}

@end

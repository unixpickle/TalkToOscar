#import <Foundation/Foundation.h>
#import "MainClass.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	MainClass * mc = [[MainClass alloc] init];
	[mc main];
	[[NSRunLoop currentRunLoop] run];
	[mc release];
	
    [pool drain];
    return 0;
}

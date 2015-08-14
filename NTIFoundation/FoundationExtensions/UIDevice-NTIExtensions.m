//
//  UIDevice+NTIExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 5/23/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "UIDevice-NTIExtensions.h"
#import <sys/sysctl.h>

@implementation UIDevice(NTIExtensions)

-(NSString*)platform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
	
	NSString* platform = nil;
	if(machine != NULL){
		platform = [NSString stringWithUTF8String: machine];
	}
    free(machine);
    return platform;
}

@end

//
//  NSURL-NTIFileSystemExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 12/14/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSURL-NTIFileSystemExtensions.h"

@implementation NSURL(NTIFileSystemExtensions)

- (BOOL)addSkipBackupAttributeToItem
{
    const char* filePath = [[self path] fileSystemRepresentation];
	
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
	
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

@end

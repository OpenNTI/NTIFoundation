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
	//We want to behave differently based on the version of the device, with the new "don't backup" flagging mechanism introduced in iOS 5.1.
	
	//Only compiles against 5.1, but no _5_1 constant defined yet.  Is this the right condition?
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_0 
	
	//If the new excluded from backup key is defined use the new way 
	if (&NSURLIsExcludedFromBackupKey) {		
		NSError *error = nil;
		BOOL success = [self setResourceValue: [NSNumber numberWithBool: YES]
									   forKey: NSURLIsExcludedFromBackupKey 
										error: &error];
		if(!success){
			NSLog(@"Error excluding %@ from backup %@", self, error);
		}
		return success;
	}
#endif

	//Else fallback to the old way of setting
	const char* filePath = [[self path] fileSystemRepresentation];
	
	const char* attrName = "com.apple.MobileBackup";
	u_int8_t attrValue = 1;
	
	int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
	return result == 0;
	
}

@end

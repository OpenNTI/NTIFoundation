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
	//FIXME: the following code is commented out because we are currently building for 5.0 not 5.1, which supports the needed constant.
	//5.1 or later
//	if (&NSURLIsExcludedFromBackupKey) {
//		assert([[NSFileManager defaultManager] fileExistsAtPath: [self path]]);
//		
//		NSError *error = nil;
//		BOOL success = [self setResourceValue: [NSNumber numberWithBool: YES]
//									  forKey: NSURLIsExcludedFromBackupKey error: &error];
//		if(!success){
//			NSLog(@"Error excluding %@ from backup %@", [self lastPathComponent], error);
//		}
//		return success;
//	}
//	else {
		const char* filePath = [[self path] fileSystemRepresentation];
		
		const char* attrName = "com.apple.MobileBackup";
		u_int8_t attrValue = 1;
		
		int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
		return result == 0;
//	}
}

@end

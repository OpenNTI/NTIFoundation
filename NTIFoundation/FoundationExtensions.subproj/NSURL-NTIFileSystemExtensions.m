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
	// https://developer.apple.com/library/ios/qa/qa1719/_index.html
	NSError *error = nil;
	BOOL success = [self setResourceValue: [NSNumber numberWithBool: YES]
								   forKey: NSURLIsExcludedFromBackupKey
									error: &error];
	if(!success){
		NSLog(@"Error excluding %@ from backup %@", self, error);
	}
	return success;
}

@end

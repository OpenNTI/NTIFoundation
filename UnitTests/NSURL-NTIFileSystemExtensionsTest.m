//
//  NSURL-NTIFileSystemExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/30/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSURL-NTIFileSystemExtensionsTest.h"
#import "NSURL-NTIFileSystemExtensions.h"

@implementation NSURL_NTIFileSystemExtensions

-(void)testDontBackupXAttr
{
	NSURL* tempFile = nil;
	{
		NSString* tempDirPath = NSTemporaryDirectory();
		NSString* template = [tempDirPath stringByAppendingString: @"archive.zip.XXXXXX"];
		const char* utfString = [template UTF8String];
		char cp[strlen(utfString) + 1]; //On the stack
		char* filled = strcpy(cp, utfString);
		filled = mktemp( filled );
		tempFile = [NSURL fileURLWithPath: [NSString stringWithUTF8String: filled]];
	}
	
	[[NSFileManager defaultManager] createFileAtPath: [tempFile path] 
											contents: [@"Hello" dataUsingEncoding: NSUTF8StringEncoding] 
										  attributes: nil];
	
	BOOL result = [tempFile addSkipBackupAttributeToItem];
	STAssertTrue(result, nil);

	const char* filePath = [[tempFile path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
	
	u_int8_t attrValue;
	int getResult = getxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
	
	STAssertTrue(getResult > 0, nil);
	STAssertEquals(attrValue, (u_int8_t)1, nil);
}

@end

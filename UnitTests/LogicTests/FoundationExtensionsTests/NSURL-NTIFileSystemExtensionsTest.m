//
//  NSURL-NTIFileSystemExtensions.m
//  NTIFoundation
//
//  Created by Christopher Utz on 1/30/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NSURL-NTIFileSystemExtensionsTest.h"
#import "NSURL-NTIFileSystemExtensions.h"

@interface NSURL_NTIFileSystemExtensions()
-(void)verifyDontBackup: (NSURL*)file;
@end

@implementation NSURL_NTIFileSystemExtensions

-(void)verifyDontBackup: (NSURL*)file
{
	NSError *error = nil;
	NSNumber* result;
	BOOL success = [file getResourceValue: &result
								   forKey: NSURLIsExcludedFromBackupKey
									error: &error];
	XCTAssertTrue(success);
	XCTAssertNil(error);
	XCTAssertTrue([result boolValue]);
}

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
	XCTAssertTrue(result);
	
	[self verifyDontBackup: tempFile];
}

@end

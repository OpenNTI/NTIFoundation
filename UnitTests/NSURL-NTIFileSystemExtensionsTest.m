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
-(void)verifyDontBackupOldStyleXAttr: (NSURL*)file;
-(void)verifyDontBackup: (NSURL*)file;
@end

@implementation NSURL_NTIFileSystemExtensions

-(void)verifyDontBackupOldStyleXAttr: (NSURL*)file
{
	
	const char* filePath = [[file path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
	
	u_int8_t attrValue;
	size_t getResult = getxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
	
	XCTAssertTrue(getResult > 0);
	XCTAssertEqual(attrValue, (u_int8_t)1);
}

-(void)verifyDontBackup: (NSURL*)file
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_0 
	//If the new excluded from backup key is defined use the new way 
	if (&NSURLIsExcludedFromBackupKey) {		
		NSError *error = nil;
		NSNumber* result;
		BOOL success = [file getResourceValue: &result
									   forKey: NSURLIsExcludedFromBackupKey 
										error: &error];
		XCTAssertTrue(success);
		XCTAssertNil(error);
		XCTAssertTrue([result boolValue]);
	}
	else{
		XCTFail(@"Excpected new style but NSURLIsExcludedFromBackupKey not defined");
	}
#else
	STFail(@"Excpected new style");
#endif
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
	
	BOOL oldStyle = YES;
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_0 
	if (&NSURLIsExcludedFromBackupKey) {
		oldStyle = NO;
	}
#endif
	
	if(oldStyle){
		[self verifyDontBackupOldStyleXAttr: tempFile];
	}
	else{
		[self verifyDontBackup: tempFile];
	}
}

@end

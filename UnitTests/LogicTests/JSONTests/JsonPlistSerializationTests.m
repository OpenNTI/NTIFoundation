//
//  JsonPlistSerializationTests.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 3/27/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "JsonPlistSerializationTests.h"
#import "NSString-NTIJSON.h"

@interface NTIBufferedDownloader(JsonPlistTest)
+(BOOL)isPlistData: (NSData *)data;
@end

@implementation JsonPlistSerializationTests
-(void)setUp
{
	NSString* content = [NSString stringWithContentsOfURL: [[NSBundle bundleForClass: [self class]] 
															URLForResource: @"jsonUserData.json" withExtension: nil]
												 encoding: NSUTF8StringEncoding error: nil];
	self->userDataObject = [content jsonObjectValue];
}

-(void)testDataReadingBasedOnTypes
{		
	//Serialize dict to json data 
	NSData* data = [NSJSONSerialization dataWithJSONObject: self->userDataObject options: NSJSONWritingPrettyPrinted error: nil];
	XCTAssertFalse( [NTIBufferedDownloader isPlistData: data], @"We expect to have json data, not plist data");
	
	//Now, we are going to serialize the same dict to plist data
	NSData* pData = [NSPropertyListSerialization dataWithPropertyList: self->userDataObject 
																   format: NSPropertyListXMLFormat_v1_0 
																  options: 0 
																	error: NULL];
	XCTAssertTrue( [NTIBufferedDownloader isPlistData: pData], @"We expect to have plist data");
	
	
	id plistDict =  [NSPropertyListSerialization propertyListWithData: pData 
														 options: NSPropertyListImmutable
														  format: nil error: NULL];
	XCTAssertTrue( [plistDict isEqualToDictionary: self->userDataObject], @"Dicts should have the same content");
}

-(void)testNilIncomingData
{
	NSData* data = nil;
	NTIBufferedDownloader* downloader = [[NTIBufferedDownloader alloc] init];
	[downloader connection: nil didReceiveResponse: nil];
	[downloader connection: nil didReceiveData: data];
	XCTAssertNil([downloader objectFromData] , @"Expected nil object");
}

-(void)testEmptyIncomingData
{
	// Init with empty dict. 
	NSData* data = [NSJSONSerialization dataWithJSONObject: [NSDictionary dictionary] options: NSJSONWritingPrettyPrinted error: nil];
	
	NTIBufferedDownloader* downloader = [[NTIBufferedDownloader alloc] init];
	[downloader connection: nil didReceiveResponse: nil];
	[downloader connection: nil didReceiveData: data];
	NSLog(@"%@", [downloader stringFromData]);
	XCTAssertTrue([[downloader objectFromData] isEqualToDictionary: [NSDictionary dictionary]] , @"Expected nil object");
}

-(void)testNonEmptyPlistData
{
	NSData* data = [NSPropertyListSerialization dataWithPropertyList: self->userDataObject 
															   format: NSPropertyListXMLFormat_v1_0 
															  options: 0 
																error: NULL];
	NTIBufferedDownloader* downloader = [[NTIBufferedDownloader alloc] init];
	[downloader connection: nil didReceiveResponse: nil];
	[downloader connection: nil didReceiveData: data];
	XCTAssertNotNil([downloader objectFromData] , @"Expected nil object");
	XCTAssertTrue( [[downloader objectFromData] isEqualToDictionary: self->userDataObject] , @"Expected to have equal objects");
}

-(void)testNonEmptyJsonData
{
	NSData* data = [NSJSONSerialization dataWithJSONObject: self->userDataObject options: NSJSONWritingPrettyPrinted error: nil];
	NTIBufferedDownloader* downloader = [[NTIBufferedDownloader alloc] init];
	[downloader connection: nil didReceiveResponse: nil];
	[downloader connection: nil didReceiveData: data];
	XCTAssertNotNil([downloader objectFromData] , @"Expected nil object");
	XCTAssertTrue( [[downloader objectFromData] isEqualToDictionary: self->userDataObject] , @"Expected to have equal objects");
}
@end

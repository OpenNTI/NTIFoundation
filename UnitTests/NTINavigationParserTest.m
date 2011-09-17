//
//  NTINavigationParserTest.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/31.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINavigationParserTest.h"
#import "NTINavigationParser.h"

@implementation NTINavigationParserTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testParser
{
    id parser = [[NTINavigationParser alloc] initWithContentsOfURL: 
				 [[NSBundle bundleForClass: [self class]] URLForResource: @"eclipse-toc.xml" withExtension: nil]];
				 // [NSURL URLWithString: @"http://localhost:8080/prealgebra/eclipse-toc.xml"]];
	STAssertNotNil( [parser root], @"root object" );
	
	NSArray* array = [[parser root] pathToHref: @"sect0002.html"];
	STAssertTrue( [array count] == 3, @"Expected length three." );
	STAssertEquals( (NSInteger)17328, [[array objectAtIndex: 2] relativeSize], @"" );

	NTINavigationItem* navItem = [array objectAtIndex: 2];
	NSArray* related = [navItem related];
	STAssertTrue( [related count] == 7, @"Expected 7 related items" );
	NTIRelatedNavigationItem* relatedItem = [related objectAtIndex: 6];
	STAssertTrue( [[relatedItem ntiid] isEqualToString: @"aops-prealgebra-9"], @"Expected page id aops-prealgebra-9" );
	STAssertTrue( [[relatedItem type] isEqualToString: @"index"], @"Expected type index" );
	STAssertTrue( [[relatedItem qualifier] isEqualToString: @"commutative property"], @"Expected qualifier commutative property" );
	
	array = [[parser root] pathToHref: @"sect0015.html"];
	navItem = [array objectAtIndex: 2];
	related = [navItem related];
	STAssertTrue( [related count] == 1, @"Expected 1 related items" );
	relatedItem = [related objectAtIndex: 0];
	STAssertTrue( [[relatedItem ntiid] isEqualToString: @"aops-prealgebra-19"], @"Expected page id aops-prealgebra-19" );
	STAssertTrue( [[relatedItem type] isEqualToString: @"link"], @"Expected type link" );
	STAssertTrue( [[relatedItem qualifier] isEqualToString: @""], @"Expected qualifier \"\"" );
	
	array = [[parser root] pathToHref: @"sec-negation.html"];
	NSArray* ids = [[array objectAtIndex: 2] related];
	STAssertEquals( (NSUInteger)0, [ids count], @"Related objects should be empty" );
	}

	

@end

//
//  NTIInspectorObjectWrapperTest.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 3/14/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIInspectorObjectWrapperTest.h"
#import "NTIGlobalInspectorMainPane.h"
#import "NTIEditableFrame.h"
@implementation NTIInspectorObjectWrapperTest

- (void)testInspectableWrapper
{
	NTIEditableFrame* editor = [[NTIEditableFrame alloc] init];
	NSAttributedString* text = [[NSAttributedString alloc] initWithString: @"<html><body>The text</body></html>"];

	NTIInspectableObjectWrapper* wrapper = [[NTIInspectableObjectWrapper alloc] initWithInspectableObject: text andOwner: editor];
	XCTAssertEqualObjects([wrapper belongsTo], editor, @"Owner object and editor obj should be equal");
	XCTAssertEqualObjects([wrapper inspectedObject], text, @"inspected objects should be equal");	
}

@end

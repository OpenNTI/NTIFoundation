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
	OUIEditableFrame* editor = [[OUIEditableFrame alloc] init];
	NSAttributedString* text = [[NSAttributedString alloc] initWithString: @"<html><body>The text</body></html>"];

	NTIInspectableObjectWrapper* wrapper = [[NTIInspectableObjectWrapper alloc] initWithInspectableObject: text andOwner: editor];
	STAssertEqualObjects([wrapper belongsTo], editor, @"Owner object and editor obj should be equal");
	STAssertEqualObjects([wrapper inspectedObject], text, @"inspected objects should be equal");	
}

@end

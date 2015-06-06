//
//  NTIGlobalInspectorPaneAndSliceAppTest.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 3/18/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

//  Application unit tests contain unit test code that must be injected into an application to run correctly.
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
@class NTIGlobalInspectorMainPane;
@class NTIAppNavigationController;
@interface NTIGlobalInspectorPaneAndSliceAppTest : SenTestCase {
	@private
	NTIGlobalInspectorMainPane* mainPane;
}
@end

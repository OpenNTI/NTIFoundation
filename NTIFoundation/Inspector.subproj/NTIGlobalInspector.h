//
//  NTIGlobalInspector.h
//  NTIFoundation
//
//  Created by Christopher Utz on 1/27/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "OmniUI/OUIInspector.h"

@interface NTIGlobalInspector : OUIInspector{
	@private
	UIResponder* shownFrom;
}

@property (nonatomic, readonly) UIResponder* shownFrom;
-(void)inspectObjectsFromBarButtonItem: (UIBarButtonItem*)item;
@end

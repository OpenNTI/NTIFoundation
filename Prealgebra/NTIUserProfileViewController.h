//
//  NTIUserProfileViewController.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/03.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTIParentViewController.h"
#import "OmniUI/OUIStackedSlicesInspectorPane.h"
@class NTINavigableInspector;
@interface NTIUserProfileViewController : OUIStackedSlicesInspectorPane {
	@private
	id nr_presenting;
	NTINavigableInspector* inspector;
}
-(id)initWithPresentingViewController: (id)presenting;
-(void)inspectFromBarButtonItem: (id)s;
@end

//
//  NTILibraryViewController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIViewController.h"
@class LibraryView;
@interface NTILibraryViewController : NTIViewController {
	@private 
	id nr_target; //weak ref
	SEL action;
	IBOutlet UILabel* synchronizingLabel;
	IBOutlet UIActivityIndicatorView* synchronizingActivity;
}
@property (nonatomic,readonly) LibraryView* libraryView;
-(id)initWithNibName: (NSString*)nibNameOrNil 
			  bundle: (NSBundle*)nibBundleOrNil
			  target: (id)target
			  action:(SEL)action;
			  
-(IBAction)infoButtonTouched:(id)sender;
@end

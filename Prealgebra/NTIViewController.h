//
//  NTIViewController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTIViewController : UIViewController {
	@private
	UIViewController* parentVC;
}
@property (nonatomic,assign) UIViewController* parentViewController;

-(id)ancestorViewControllerWithClass: (Class)c;
@end

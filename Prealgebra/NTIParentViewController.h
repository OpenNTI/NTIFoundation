//
//  NTIParentViewController.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/04.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIViewController.h"
@class NSMutableArray;
/**
 * Keeps a list of children and informs them of important events.
 */
@interface NTIParentViewController : NTIViewController /*OUIParentViewController*/ {
	//We could extend OUIParentViewController, but 
	//it keeps its children private, and we don't care about enforcing its visibility
	//concerns right now
@private 
	NSMutableArray* children;
	BOOL askingChildren; //To prevent recursion errors.
}
//TODO: In iOS 5, UIViewController exposes a addChildViewController: method.
//Use that.

/**
 * @return The child
 */
-(id)addChildViewController: (UIViewController*)child animated: (BOOL)animated;
/**
 * @return The child.
 */
-(id)removeChildViewController: (UIViewController*)child animated: (BOOL)animated;

-(NSArray*)childViewControllersWithClass: (Class)clazz;

-(BOOL)removeChildViewControllersWithClass: (Class)clazz;
@end

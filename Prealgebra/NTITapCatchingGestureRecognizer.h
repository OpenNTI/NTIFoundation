//
//  NTITapCatchingGestureRecognizer.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/05/30.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * A tap recognizer that is meant to sit on top of views and observe all
 * the taps that the view gets. It doesn't cancel touches, and by default
 * in neither prevents nor can be prevented by other recognizers. (For
 * example, the UIWebView's single-tap recognizer wants to prevent many other
 * recognizers.)
 *
 * <p>In some cases, you may want to add a specific set of recognizers
 * that can prevent this object.
 */
@interface NTITapCatchingGestureRecognizer : UITapGestureRecognizer {
	@private 
	NSMutableSet* preventingSet;
	NSMutableSet* preventedSet;
}

-(id)canBePreventedBy: (id)other;
-(id)canPrevent: (id)other;
@end


/**
 * A long-press recognizer, similar to NTITapCatchingGestureRecognizer.
*/
@interface NTILongPressCatchingGestureRecognizer : UILongPressGestureRecognizer
@end

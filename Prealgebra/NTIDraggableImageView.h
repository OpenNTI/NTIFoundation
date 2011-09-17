//
//  NTIDraggableImageView.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTIDraggableImageView : UIImageView {
	@private
	UIView* draggingProxyView;
	UIResponder* nr_dragResponder;
}

-(id)initWithImage: (UIImage*)image
	 dragResponder: (UIResponder*)dragResponder;

@end

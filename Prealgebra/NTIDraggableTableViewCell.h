//
//  NTIDraggableTableViewCell.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * You must enable user interaction on the image view
 * if you want dragging.
 */
@interface NTIDraggableTableViewCell : UITableViewCell {
	@private
	UIView* draggingProxyView;
}



@end

//
//  NTIDraggingProxyView.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/12.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NTIDraggingUtilities.h"

@interface NTIDraggingProxyView : UIImageView<NTIDraggingInfo> {
}

@property (nonatomic,readonly) UIResponder* proxyFor;
@property (nonatomic,assign) id currentDragTarget;
@property (nonatomic,assign) CGPoint currentDragLocation;

-(id)initWithImage: (UIImage*)image forObject: (UIResponder*)proxyFor;

@end

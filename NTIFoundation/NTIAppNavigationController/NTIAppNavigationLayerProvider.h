//
//  NTIAppNavigationLayerProvider.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/1/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIAppNavigationController.h"
#import "NTIAppNavigationLayerProvider.h"

@protocol NTIAppNavigationLayerDescriptor;

@protocol NTIAppNavigationLayerProvider <NSObject>
@property (nonatomic, readonly) NSString* layerProviderName; //A name for this layer provider, may be used as part of display
@property (nonatomic, readonly) NSArray* layerDescriptors; //should provide kvo on this property
@end

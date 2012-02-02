//
//  NTIAppNavigationLayerDescriptor.h
//  NTIFoundation
//
//  Created by Christopher Utz on 2/1/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIAppNavigationLayerProvider.h"
#import "NTIAppNavigationLayer.h"

/*
 * Objects implementing this protocol are used to describe layers.  Layer
 * descriptors should container enough information that their respective providers
 * can construct the actuall layer objects provided the descriptor.  Layer Descriptor
 * equality should be provided such that the app nav controller can determine whether
 * or not an existing layer on the stack can be used or a new one should be created.
 * Layer descriptors should also provide information about badge counts for background
 * changes
 */
@protocol NTIAppNavigationLayerDescriptor <NTIChangeCountTracking>
@property (nonatomic, readonly) id<NTIAppNavigationLayerProvider>provider;
@property (nonatomic, readonly) NSString* title;
@end

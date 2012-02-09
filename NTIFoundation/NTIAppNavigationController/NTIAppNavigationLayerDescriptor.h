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
 * Objects that implement this protocol are descriptors (factories) to produce layer view controllers
 * from a model. In additon to acting as a factory that creates view controllers that can be used
 * as layers the descriptor also acts a proxy for the model to get certain information.  This information is
 * things like background change counts, search information, related item information, etc.
 */
@protocol NTIAppNavigationLayerDescriptor
@property (nonatomic, readonly) NSString* title;
@property (nonatomic, readonly) UIImage* image;
-(UIViewController<NTIAppNavigationLayer>*)createLayer;
-(BOOL)wouldCreatedLayerBeTheSameAs: (UIViewController<NTIAppNavigationLayer>*)layer;
@optional
//If this message is implemented it should return a key path that is observable
//for background change counts.
@property (nonatomic, readonly) NSString* backgroundChangeCountKeyPath;

//Returns true if the layer intends to provide search results for the given term and context
-(BOOL)providesSearchForTerm: (NSString*)searchTerm withContext: (id)ctx;
//Perform a search for the given terms in the given context and call the callback with the result
-(void)searchForTerm: (NSString*)searchTerm withContext: (id)ctx callback: (NTIObjectProcBlock)callback;
//Returns true if the layer intends to provide items related to the given object for the given context
-(BOOL)providesRelatedItemsForObject: (id)object withContext: (id)ctx;
//Gathers items related to object with context and calls the callback
-(void)gatherRelatedItemsForObject: (id)object withContext: (id)ctx callback: (NTIObjectProcBlock)callback;
@end

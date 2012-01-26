//
//  NTIAppNavigationAppLayerFactory.h
//  NTIFoundation
//
//  Created by Christopher Utz on 1/25/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "OmniFoundation/OmniFoundation.h"

@protocol NTIAppNavigationApplicationLayer ;
typedef UIViewController<NTIAppNavigationApplicationLayer>*(^NTIApplicationLayerFactory)();

@interface NTIAppNavigationAppLayerFactory : OFObject{
	@private
	NSString* title;
	NTIApplicationLayerFactory factoryBlock;
}
@property (nonatomic, strong) NSString* title;

-(id)initWithTitle: (NSString*)title andFactory: (NTIApplicationLayerFactory)factory;
-(UIViewController<NTIAppNavigationApplicationLayer>*)createApplicationLayer;

@end

//
//  NTIGlobalInspectorSlice.h
//  NTIFoundation
//
//  Created by Christopher Utz on 7/31/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <OmniUI/OUIDetailInspectorSlice.h>

typedef OUIInspectorPane* (^NTIInspectorPaneMaker)(OUIDetailInspectorSlice* slice);

@interface NTIGlobalInspectorSlice : OUIDetailInspectorSlice{
	
}

-(id)initWithTitle: (NSString*)title
		 paneMaker: (NTIInspectorPaneMaker)paneMaker;

@property (nonatomic, strong) NTIInspectorPaneMaker paneMaker;
@end

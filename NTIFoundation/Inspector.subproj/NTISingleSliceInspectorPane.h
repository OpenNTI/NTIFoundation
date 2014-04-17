//
//  NTISingleSliceInspectorPane.h
//  NTIFoundation
//
//  Created by Chris Hansen on 4/17/14.
//  Copyright (c) 2014 NextThought. All rights reserved.
//

#import <OmniUI/OUIInspectorPane.h>

@interface NTISingleSliceInspectorPane : OUIInspectorPane
@property (nonatomic, strong) OUIInspectorSlice* slice;
-(id)initWithInspectorSlice: (OUIInspectorSlice*)slice;
@end

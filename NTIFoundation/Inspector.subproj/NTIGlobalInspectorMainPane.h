//
//  NTIGlobalInspectorMainPane.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 2/9/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <OmniUI/OUIInspectorPane.h>

@protocol OUIScrollNotifier;
@class OUIInspectorSlice, NTIGlobalInspector;
@interface NTIGlobalInspectorMainPane : OUIInspectorPane<UITableViewDataSource, UITableViewDelegate> {
	NSMutableArray* inspectedObjectSlicesPairs;		// pairs of inspectedObjects and their possible slices.
	UITableView* inspectorTable;	//sections = inspectableObjects, rows = slices
}

-(id)init;

@end

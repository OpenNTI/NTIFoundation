//
//  NTIGlobalInspectorMainPane.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 2/9/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <OmniUI/OUIInspectorPane.h>
#import "NTIInspectableObjectProtocol.h"

@interface NSObject(NTIInspectableObjectExtension)
-(id)belongsTo;
-(id)inspectedObject;
-(NSString *)nameOfInspectableObjectContainer;
@end

@interface NTIInspectableObjectWrapper : NSObject<NTIInspectableObjectProtocol>
@property (nonatomic, strong) id inspectableObject;
@property (nonatomic, strong) id owner;

-(id)initWithInspectableObject: (id)object andOwner: (id)p;
-(id)inspectedObject;
@end

@protocol OUIScrollNotifier;
@class OUIInspectorSlice, NTIGlobalInspector;
@interface NTIGlobalInspectorMainPane : OUIInspectorPane<UITableViewDataSource, UITableViewDelegate> {
	NSMutableArray* inspectedObjectSlicesPairs;		// pairs of inspectedObjects and their possible slices.
	UITableView* inspectorTable;	//sections = inspectableObjects, rows = slices
}

-(id)init;
-(void)addObject: (id)object withInspectorSlices: (NSArray *)slices;
@end



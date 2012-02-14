//
//  NTIGlobalInspectorMainPane.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 2/9/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIGlobalInspectorMainPane.h"
#import <OmniUI/OUIInspector.h>
#import <OmniUI/OUIInspectorSlice.h>
#import <OmniUI/OUIMinimalScrollNotifierImplementation.h>
#import "NTIGlobalInspector.h"
#import <OmniUI/OUIDetailInspectorSlice.h>
#import <OmniUI/OUIStackedSlicesInspectorPane.h>
#import "NTIInspectorSliceObjectPair.h"

@implementation NTIGlobalInspectorMainPane

-(id)init
{
	self = [super init];
	if ( self ) {
		self->inspectedObjectSlicesPairs = [NSMutableArray array];
		
		//Set up table
		self->inspectorTable = [[UITableView alloc] initWithFrame: CGRectMake(0, 0, 200, 400) style: UITableViewStyleGrouped];
		self->inspectorTable.dataSource = self;
		self->inspectorTable.delegate = self;
	}
	return self;
}

-(void)updateInterfaceFromInspectedObjects:(OUIInspectorUpdateReason)reason
{
	//Update the inspectedObjects and their slices - populate the dictionary
	NSMutableArray* slices = nil;
	
	//Empty dict
	[self->inspectedObjectSlicesPairs removeAllObjects];
	for ( id object in self.inspectedObjects ) {
		slices = [NSMutableArray array];
		for (OUIInspectorSlice* slice in [NTIGlobalInspector globalSliceRegistry] ) {
			if ( [slice isAppropriateForInspectedObject: object] ) {
				[slices addObject: slice];
			}
		}
		NTIInspectorSliceObjectPair* inspectablePair = [[NTIInspectorSliceObjectPair alloc] initWithInspectableObject: object andSlices: slices];
		[self->inspectedObjectSlicesPairs addObject: inspectablePair];
	}
	
	//Relaod the tableview
	[self->inspectorTable reloadData];
}

-(void)loadView
{
	self.view = self->inspectorTable;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self->inspectedObjectSlicesPairs count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* slices = [(NTIInspectorSliceObjectPair *)[self->inspectedObjectSlicesPairs objectAtIndex: section] slices];
    return [slices count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {	
	id inspectedObject = [(NTIInspectorSliceObjectPair *)[self->inspectedObjectSlicesPairs objectAtIndex: section] inspectableObject];
	if ( [inspectedObject respondsToSelector: @selector(nameOfInspectableObject)] ) {
		NSString* name = [inspectedObject performSelector: @selector(nameOfInspectableObject)];
		if ( name != nil ) {
			return name;
		}
	}
    return NSStringFromClass( [inspectedObject class] ); //[inspectedObject classNameForClass: [inspectedObject class]];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"MyIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
	
	NSArray* availableSlices = [(NTIInspectorSliceObjectPair *)[self->inspectedObjectSlicesPairs objectAtIndex: indexPath.section] slices];
	OUIInspectorSlice* slice = [availableSlices objectAtIndex: indexPath.row];
	cell.textLabel.text = slice.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* availableSlices = [(NTIInspectorSliceObjectPair *)[self->inspectedObjectSlicesPairs objectAtIndex: indexPath.section] slices];
	OUIInspectorSlice* slice = [availableSlices objectAtIndex: indexPath.row];
	/*OUIInspectorPane* pane = [OUIDetailInspectorSlice detailLabelWithTitle: slice.title paneMaker: ^OUIInspectorPane* (OUIDetailInspectorSlice* slice) 
							  {
								  return [[OUIStackedSlicesInspectorPane alloc] init];
							  }];
	*/
	if ( [slice respondsToSelector:@selector(paneMaker)] ){
		OUIDetailInspectorSlice* detailSlice = (OUIDetailInspectorSlice *)slice;
		OUIInspectorPane* pane = detailSlice.paneMaker(detailSlice);
		[self.inspector pushPane: pane];
	}
	else if( [slice respondsToSelector: @selector(showDetails:)] ){
		//[slice showDetails: slice];
		OUIInspectorPane* pane = slice.detailPane;
		[self.inspector pushPane: pane];
	}
}

@end

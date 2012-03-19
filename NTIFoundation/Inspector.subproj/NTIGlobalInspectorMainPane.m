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
#import <OmniUI/OUIColorInspectorPane.h>
#import "NTIInspectorSliceObjectPair.h"

//FIXME move this into a better protocol that describes the slices for our main pane
@interface NSObject()
-(UIImage*)imageForSliceCell;
@end

@implementation NSObject(NTIInspectableObjectExtension)
-(id)belongsTo
{
	return nil; 
}
-(id)inspectedObject
{
	return self;
}
-(NSString *)nameOfInspectableObjectContainer
{
	return nil;
}
@end

@implementation NTIInspectableObjectWrapper

@synthesize inspectableObject, owner;

- (id)initWithInspectableObject: (id)object andOwner: (id)p 
{
    self = [super init];
    if (self) {
        self.inspectableObject = object;
		self.owner = p;
    }
    return self;
}

-(id)belongsTo
{
	return self.owner;
}

-(id)inspectedObject
{
	return self.inspectableObject;
}
@end

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

-(NSArray *)inspectedObjects
{
	return [[super inspectedObjects] arrayByPerformingBlock:^id(id obj){
		return [obj inspectedObject];
	}];
}

-(NSArray *)rawInspectedObject
{
	return [super inspectedObjects];
}

-(void)updateInterfaceFromInspectedObjects:(OUIInspectorUpdateReason)reason
{
	//Update the inspectedObjects and their slices - populate the dictionary
	NSMutableArray* slices = nil;
	
	[self->inspectedObjectSlicesPairs removeAllObjects];
	for ( id object in [self rawInspectedObject] ) {
		// NOTE: self.inspectedObjects contains both inspectableObjects or wrappers around inspectableObjects. 
		//		By calling [object inspectedObject] will make sure we get the right inspectableObject not its wrapper.
		id inspObject = [object inspectedObject];
		slices = [NSMutableArray array];
		for (OUIInspectorSlice* slice in [NTIGlobalInspector globalSliceRegistry] ) {
			if ( [slice isAppropriateForInspectedObject: inspObject] ) {
				[slices addObject: slice];
			}
		}
		[self addObject: object withInspectorSlices: slices];
	}
	
	//Reload the tableview
	[self->inspectorTable reloadData];
}

-(void)addObject: (id)object withInspectorSlices: (NSArray *)slices
{
	//Check the owner of the object
	id inspectedObjectOwner = [object belongsTo];
	if ( !inspectedObjectOwner ) {
		NTIInspectorSliceObjectPair* inspectablePair = [[NTIInspectorSliceObjectPair alloc] initWithInspectableObject: object andSlices: slices];
		[self->inspectedObjectSlicesPairs addObject: inspectablePair];
	}
	else {
		NTIInspectorSliceObjectPair* parentPair = nil;
		for ( NTIInspectorSliceObjectPair* pair in self->inspectedObjectSlicesPairs ) {
			if ( [pair containsInspectableObject: inspectedObjectOwner] ) {
				parentPair = pair;
				break;
			}
		}
		if ( parentPair ) {
			[(NTIInspectorSliceObjectPair *)parentPair addSlices: slices];	//Group slices with the same inspectable owner
		}
		else {
			NTIInspectorSliceObjectPair* inspectablePair = [[NTIInspectorSliceObjectPair alloc] initWithInspectableObject: inspectedObjectOwner andSlices: slices];
			[self->inspectedObjectSlicesPairs addObject: inspectablePair];
		}
	}
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
	NSString* name = [inspectedObject nameOfInspectableObjectContainer];
	if (name) {
		return name;
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
	
	if( [slice respondsToSelector: @selector(imageForSliceCell)] ){
		cell.imageView.image = [slice imageForSliceCell];
	}
	else{
		cell.imageView.image = nil;
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* availableSlices = [(NTIInspectorSliceObjectPair *)[self->inspectedObjectSlicesPairs objectAtIndex: indexPath.section] slices];
	OUIInspectorSlice* slice = [availableSlices objectAtIndex: indexPath.row];
	[self addChildViewController: slice];	//Add slice to the parentViewController to maintain the hierarchy of vc and views.

	NSArray* objects = [slice appropriateObjectsForInspection];		//Get objects our slice is inspecting.
	
	if ( [slice respondsToSelector:@selector(paneMaker)] ){
		OUIDetailInspectorSlice* detailSlice = (OUIDetailInspectorSlice *)slice;
		OUIInspectorPane* pane = detailSlice.paneMaker(detailSlice);
		pane.parentSlice = detailSlice;
		[self.inspector pushPane: pane inspectingObjects: objects ];
	}
	// TODO: do it a better way, this is a hack to handle colors for now because they are not OUIDetailInspectorSlice
	else if( [slice respondsToSelector: @selector(colorForObject:)] ){
		OUIColorInspectorPane *pane = [[OUIColorInspectorPane alloc] init];
        pane.title = slice.title;
        slice.detailPane = pane;
		pane.parentSlice = slice;
		[self.inspector pushPane: pane inspectingObjects: objects];
	}
}

//For TESTING purposes only
-(NSArray *)objectSlicesPairs
{
	return [NSArray arrayWithArray: self->inspectedObjectSlicesPairs];
}
@end


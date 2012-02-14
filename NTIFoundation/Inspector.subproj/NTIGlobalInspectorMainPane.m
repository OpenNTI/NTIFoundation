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

@implementation NTIGlobalInspectorMainPane

-(id)init
{
	self = [super init];
	if ( self ) {
		//Populate the dictionary
		self->inspectObjectsDict = [NSMutableDictionary dictionary];
		
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
	[self->inspectObjectsDict removeAllObjects];
	for ( id object in self.inspectedObjects ) {
		slices = [NSMutableArray array];
		for (OUIInspectorSlice* slice in [NTIGlobalInspector globalSliceRegistry] ) {
			if ( [slice isAppropriateForInspectedObject: object] ) {
				[slices addObject: slice];
			}
		}
		[self->inspectObjectsDict setObject: slices forKey: object];
	}
	
	//Relaod the tableview
	[self->inspectorTable reloadData];
}

-(void)loadView
{
	self.view = self->inspectorTable;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self->inspectObjectsDict count];
    //return [self.inspectedObjects count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   //Get the number of slices each for inspectedObject 
	NSArray* slices = [self->inspectObjectsDict objectForKey: [self.inspectedObjects objectAtIndex: section]];
    return [slices count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index.
	id inspectedObject = [self.inspectedObjects objectAtIndex: section];
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
	
    id inspectedObject = [self.inspectedObjects objectAtIndex:indexPath.section];
    OUIInspectorSlice* slice= [[self->inspectObjectsDict objectForKey: inspectedObject] objectAtIndex: indexPath.row];
	cell.textLabel.text = slice.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id inspectedObject = [self.inspectedObjects objectAtIndex:indexPath.section];
	OUIInspectorSlice* slice= [[self->inspectObjectsDict objectForKey: inspectedObject] objectAtIndex: indexPath.row];
	OUIInspectorPane* pane = [OUIDetailInspectorSlice detailLabelWithTitle: slice.title paneMaker: ^OUIInspectorPane* (OUIDetailInspectorSlice* slice) 
							  {
								  return [[OUIStackedSlicesInspectorPane alloc] init];
							  }];
	slice.detailPane = pane;
	[slice showDetails: nil];
}

@end

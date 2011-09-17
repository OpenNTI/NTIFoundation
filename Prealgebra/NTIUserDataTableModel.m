//
//  NTIUserDataTableModel.m
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/31/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIUserDataTableViewController.h"
#import "NTIUtilities.h"
#import "WebAndToolController.h"
#import "NTIAppPreferences.h"
#import "NTIDraggableTableViewCell.h"
#import "NTIRTFDocument.h"
#import "NTIEditableNoteViewController.h"
#import "NTINavigationParser.h"
#import "NTIUserDataTableModel.h"
#import "NSArray-NTIExtensions.h"

@implementation NTIUserDataTableModel
@synthesize delegate, objects, containerId;

-(id)initWithWebController:(id)web
{
	self = [super init];
	self->objects = [[NSMutableArray arrayWithCapacity: 5] retain];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver: self
	 selector: @selector(willLoadNotification:)
	 name: WebAndToolControllerWillLoadPageId
	 object: web];
	return self;
}

-(void)willLoadNotification: (NSNotification*)not
{
	NTI_RELEASE( self->containerId );
	
	NTINavigationItem* navItem = [[not userInfo] 
								  objectForKey: WebAndToolControllerWillLoadPageIdKeyNavigationItem];
	self->containerId = [navItem.ntiid copy];
	[self clearCurrentData];
	[self loadAllDataForCurrentPage];
}

-(void)clearCurrentData
{
	[self->objects removeAllObjects];
}

//To quiet the analyzer, we call this function
static void _quiet_retain( id o NS_CONSUMED )
{
	return;
}

-(Class)dataLoaderClass
{
	return [NTIUserDataLoader class];	
}

-(NSString*)dataLoaderType
{
	return kNTIUserDataLoaderTypeGeneratedData;	
}

-(void)loadAllDataForCurrentPage
{
	if( ![NSString isEmptyString: self.containerId] ) {
		NTIAppPreferences* prefs = [NTIAppPreferences prefs];
		NTIUserDataLoader* loader = [[self dataLoaderClass] 
									 dataLoaderForDataserver: prefs.dataserverURL
									 username: prefs.username
									 password: prefs.password
									 page: self.containerId
									 type: [self dataLoaderType]
									 delegate: self];
		_quiet_retain( [loader retain] );
	}
}

//Go through our trees and find the one with that oid
-(id)findTree: (id)OID
{
	for( NTIThreadedNoteContainer* tree in self->objects ) {
		if( [tree findWithID: OID] ) {
			return tree;
		}
	}
	return nil;
}


-(BOOL)addObject: (id)object
{
	[self->objects insertObject: object atIndex: 0];
	[self->delegate model: self didAddObjects: [NSArray arrayWithObject: object]];
	return YES;
}

-(BOOL)removeObject: (id)object
{
	NSUInteger idx = [self->objects indexOfObject: object];
	if( idx != NSNotFound ){
		[self->objects removeObjectAtIndex: idx];
		[self->delegate model: self didRemoveObjects: [NSArray arrayWithObject: object]];
		return YES;
	}
	return NO;
}

-(BOOL)updateObjectAtIndex: (NSUInteger)index withObject: (id)object;
{
	[self->objects replaceObjectAtIndex: index withObject: object];
	[self->delegate model: self didUpdateObjects: [NSArray arrayWithObject: object]];
	return YES;
}

-(void)refreshDataForCurrentPage
{
	self->refreshing = YES;
	[self loadAllDataForCurrentPage];
}

-(NSDate*)ifModifiedSinceForDataLoader: (NTIUserDataLoader*)loader
{
	if( self->refreshing ) {
		return [[self->dataLoaderLastModified retain] autorelease];
	}
	return nil;
}

-(void)dataLoaderGotNotModifiedResponse: (NTIUserDataLoader*)loader
{
	//Yay, nothing changed!
	self->refreshing = NO;
}

-(id)findSameOID: (id)OID inCollection: (NSArray*)items
{
	for( id object in items ) {
		if( [[object OID] isEqual: OID] ) {
			return object;
		}
	}
	return nil;
}

-(void)refreshDataWithResults: (NSArray*)result fromLoader: (NTIUserDataLoader*) loader
{
	//If we get here, then SOMETHING has changed. We have
	//to figure out what and update accordingly.
	
	
	NSMutableArray* adds = [NSMutableArray array];
	NSMutableArray* replaces = [NSMutableArray array];
	NSMutableArray* deletes = [NSMutableArray array];
	BOOL nothingToDo = YES;
	for( id incoming in result ) {
		id existing = [self findSameOID: [incoming OID] inCollection: self->objects];
		if( !existing ) {
			nothingToDo = NO;
			[adds addObject: incoming];
		}
		else if( [incoming LastModified] > [existing LastModified] ) {
			nothingToDo = NO;
			[replaces addObject: incoming];
		}
	}
	id allIncomingOIDS = [result valueForKeyPath: @"@distinctUnionOfObjects.OID"];
	for( id object in self.objects ) {
		if( ![allIncomingOIDS containsObject: [object OID]] ) {
			[deletes addObject: object];	
			nothingToDo = NO;
		}
	}
	
	OBASSERT( !nothingToDo ); //Otherwise we should have got a 304 (?)
	
	for( id delete in deletes ) {
		//deletes contains the objects actually stored, 
		//which may have been manipulated
		[self removeObject: delete]; //TODO: may interfere with subclasses
	}
	
	if( [deletes count] > 0 ){
		[self->delegate model: self didRemoveObjects: deletes];
	}
	
	for( id updated in replaces ) {
		id modelUpdated = [self findSameOID: [updated OID] inCollection: self->objects];
		[self updateObjectAtIndex: [self->objects indexOfObject: modelUpdated] withObject: updated];
	}
	if( [replaces count] > 0 ){
		[self->delegate model: self didUpdateObjects: deletes];
	}
	
	[self->objects addObjectsFromArray: adds]; //TODO: Inserting these incrementally
	
	if( [adds count] > 0 ){
		[self->delegate model: self didAddObjects: adds];
	}
	
	[self->delegate model: self didRefreshDataForPage: self.containerId];
	
}

-(void)loadDataWithResults: (NSArray*)result fromLoader: (NTIUserDataLoader*) loader
{
	[self->objects addObjectsFromArray: result]; //TODO: Inserting these incrementally
	if( [result count] > 0 ){
		[self->delegate model: self didAddObjects: result];
	}
	
	[self->delegate model: self didRefreshDataForPage: self.containerId];
	
}




-(void)dataLoader: (NTIUserDataLoader*)loader didFinishWithResult: (NSArray*)result
{
	if( self->refreshing ) {
		self->refreshing = NO;
		[self refreshDataWithResults: result fromLoader: loader];
		NTI_RELEASE( self->dataLoaderLastModified );
		self->dataLoaderLastModified = [loader.lastModified retain];
	}
	else {
		NTI_RELEASE( self->dataLoaderLastModified );
		self->dataLoaderLastModified = [loader.lastModified retain];
		[self clearCurrentData];
		[self loadDataWithResults: result fromLoader: loader];
	}
	[loader release];
}


-(void)dataLoader: (NTIUserDataLoader*)loader didFailWithError: (NSError*)error
{
	[loader release];
}

-(BOOL)wantsResult: (id)resultObject
{
	return YES;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	NTI_RELEASE(self->delegate);
	NTI_RELEASE(self->objects);
	NTI_RELEASE(self->dataLoaderLastModified);
	NTI_RELEASE(self->containerId);
	[super dealloc];
}
@end



@implementation NTIThreadedNoteTableModel
//Go through our trees and find the one with that oid
-(id)findTree: (id)OID
{
	NTIThreadedNoteContainer* found = nil;
	for( NTIThreadedNoteContainer* tree in self->objects ) {
		found = [tree findWithID: OID];
		if( found ) {
			break;
		}
	}
	return found;
}


-(BOOL)addObject: (NTINote*)note
{
	NTIThreadedNoteContainer* threaded =  [[NTIThreadedNoteContainer threadNotes: [NSArray arrayWithObject: note]] firstObject];
	
	//First we see if it adds to an existing tree
	NTIThreadedNoteContainer* addedTo = nil;
	for( NTIThreadedNoteContainer* existingThread in self->objects )
	{
		addedTo = [existingThread addThreadedNote: threaded];
		if( addedTo != nil ){
			break;
		}
	}
	
	if( addedTo ){
		[self.delegate model: self didUpdateObjects: [NSArray arrayWithObject: addedTo.root]];
		
		return YES;
	}
	
	//If not we hope its a root object and add it as such
	if( [threaded isRoot] ){
		[self->objects insertObject: threaded atIndex: 0]; 
		[self.delegate model: self didAddObjects: [NSArray arrayWithObject: threaded]];
		
	}
	
	return NO;
}

-(BOOL)removeObject: (NTINote*)note
{
	//Look for the tree we want to remove
	NTIThreadedNoteContainer* toRemove = [self findTree: note.OID];
	if( toRemove != nil ){
		
		if([toRemove isRoot]){
			[self->objects removeObject: toRemove];
			[self.delegate model: self didRemoveObjects: [NSArray arrayWithObject: toRemove]];
			
			
		}
		else{
			[toRemove.parent removeThreadedNote: toRemove];
			[self.delegate model: self didUpdateObjects: [NSArray arrayWithObject: toRemove.root]];
		}
		
		return YES;
	}
	return NO;
}

-(BOOL)updateObjectAtIndex: (NSUInteger)index withObject: (NTINote*)object;
{
	NTIThreadedNoteContainer* toUpdate = [self findTree: object.OID];
	if( toUpdate != nil ){
		toUpdate.uan.note = object; 
		[self.delegate model: self didUpdateObjects: [NSArray arrayWithObject: toUpdate.root]];
	}
	return NO;
}

-(NSArray*)threadsFromNotes: (NSArray*)results
{
	return  [NTIThreadedNoteContainer threadNotes: results];
}

-(NSArray*)flattenTree: (NTIThreadedNoteContainer*)note
{
	NSMutableArray* flattened = [NSMutableArray arrayWithCapacity: 5];
	if( note.uan ){
		[flattened addObject: note.uan.note];
	}
	
	if( note.children.count > 0 )
	{
		for(NTIThreadedNoteContainer* child in note.children){
			[flattened addObjectsFromArray: [self flattenTree: child]];
		}
	}
	
	return flattened;
}

-(BOOL)notes: (NSArray*)theNotes contains: (NTIUserAndNote*)uan
{
	for(NTINote* note in theNotes){
		if ([note isEqual: uan.note])
		{
			return YES;
		}
	}
	return NO;
}

-(NSArray*)threadsToAdd: (NTIThreadedNoteContainer*)container
{
	if( ![container isEmptyContainer] ){
		return [NSArray arrayWithObject: container];
	}
	
	NSMutableArray* toAdd = [NSMutableArray arrayWithCapacity: 5];
	
	for( NTIThreadedNoteContainer* child in container.children ){
		[toAdd addObjectsFromArray: [self threadsToAdd: child]];
	}
	
	return toAdd;
}

//If we cheat on the refresh and just build the model from scratch an in progress views won't be
//able to update their parent vcs.
-(void)refreshDataWithResults: (NSArray*)result fromLoader: (NTIUserDataLoader*) loader
{	
	//This is a refresh.  We have preexisting data so we need to determine
	//appropriate adds/updates/deletes
	
	//Notes to add
	NSMutableArray* adds = [NSMutableArray array];
	
	//Notes to replace
	NSMutableArray* updates = [NSMutableArray array];
	
	//Notes to delete
	NSMutableArray* deletes = [NSMutableArray array];
	BOOL nothingToDo = YES;
	
	for( id incoming in result ) {
		NTIThreadedNoteContainer* existing = [self findTree: [incoming OID]];
		if( !existing ) {
			nothingToDo = NO;
			[adds addObject: incoming];
		}
		else if( [incoming LastModified] > [existing.uan.note LastModified] ) {
			nothingToDo = NO;
			[updates addObject: incoming];
		}
	}
	id allIncomingOIDS = [result valueForKeyPath: @"@distinctUnionOfObjects.OID"];
	NSMutableArray* modelsNotes = [NSMutableArray arrayWithCapacity: 5];
	for( id object in self->objects ){
		[modelsNotes addObjectsFromArray: [self flattenTree: object]];
	}
	
	for( NTINote* note in modelsNotes )
	{
		if( ![allIncomingOIDS containsObject: note.OID]){
			nothingToDo = NO;
			[deletes addObject: note];
		}
	}
	
	
	OBASSERT( !nothingToDo ); //Otherwise we should have got a 304 (?)

	
	
	//We have arrays of things that need to be added/updated/removed
	
	//we delete the whole tree
	NSMutableSet* removedObjects = [NSMutableSet setWithCapacity:5];
	NSMutableSet* updatedObjects = [NSMutableSet setWithCapacity:5];
	NSMutableSet* addedObjects = [NSMutableSet setWithCapacity:5];
	
	//For deletes we locate the container, set the note to nil and prune appropriately
	for( NTINote* delete in deletes ) {
		//Find the note tree to delete and remove it from the parent
		NTIThreadedNoteContainer* toDelete = [self findTree: delete.OID];
		if( toDelete != nil ){
			[toDelete deleteNote];
			
			//Prune the root and delete if necessary
			if( ![NTIThreadedNoteContainer pruneContainer: toDelete] ){
				//We can only ever get here once per refresh?
				[self->objects removeObject: toDelete.root];
				[removedObjects addObject: toDelete.root];
			}
			else{
				[updatedObjects addObject: toDelete.root]; 
			}
		}
		
	}
	NSArray* removedThreads = [removedObjects allObjects];
	if( [removedThreads count] > 0 ){
		[self.delegate model: self didRemoveObjects: removedThreads];
	}
	
	
	//For updates we find the tree and update the note
	//We may update multiple things in the tree so we use a set
	for( id updated in updates ) {
		//This is the root that will be updated
		NTIThreadedNoteContainer* modelUpdated = [self findTree: [updated OID]];
		
		if( modelUpdated != nil ){
			modelUpdated.uan.note = updated;
			[updatedObjects addObject: modelUpdated.root];
		}
	}

	
	//We do our adds next.  Create threads from all the new things.  These may
	//include what we think are deleted nodes but they actually have a place in our model
	NSArray* newThreads = [self threadsFromNotes: adds];
	
	NSMutableArray* newThreadsToAdd = [NSMutableArray arrayWithCapacity: 5];
	
	for(NTIThreadedNoteContainer* newThread in newThreads ){
		[newThreadsToAdd addObjectsFromArray: [self threadsToAdd: newThread]];
	}
	
	for(NTIThreadedNoteContainer* newThreadToAdd in newThreadsToAdd)
	{
		if( [newThreadToAdd isRoot]){
			[self->objects addObject: newThreadToAdd];
			[addedObjects addObject: newThreadToAdd];
		}
		else{
			NTIThreadedNoteContainer* addedTo = nil;
			for(NTIThreadedNoteContainer* possibleTree in self->objects){
				addedTo = [possibleTree addThreadedNote: newThreadToAdd];
				if( addedTo ){
					break;
				}
			}
			if( addedTo ){
				[updatedObjects addObject: addedTo.root];
			}
		}
	}
	
	NSArray* addedThreads = [addedObjects allObjects];
	
	if( [addedThreads count] > 0 ){
		[self.delegate model: self didAddObjects: addedThreads];
	}

	NSArray* updatedThreads = [updatedObjects allObjects];
	
	if( [updatedThreads count] > 0 ){
		[self.delegate model: self didUpdateObjects: [updatedObjects allObjects]];
	}
	
	if(!nothingToDo){
		[self.delegate model: self didRefreshDataForPage: self.containerId];
	}

	
}


-(void)loadDataWithResults: (NSArray*)result fromLoader: (NTIUserDataLoader*) loader
{
	
	//TODO construct our threaded note model.  This is a "fresh" load so in the simple case things get easier
	NSArray* threadedNotes = [self threadsFromNotes: result];	
	[self->objects addObjectsFromArray: threadedNotes];
	if( [threadedNotes count] > 0 ){
		[self.delegate model: self didAddObjects: threadedNotes];
	}
	[self.delegate model: self didLoadDataForPage: self.containerId];
}

-(NSString*)sortDescriptorKey
{
	return @"lastModifiedDate";	
}

#pragma mark - NTIUserDataLoader delegate/subclass
//This is disabled because highlights are enough like 
//notes that our basic display code works for them.
//Filter to only accept notes.
//-(BOOL)wantsResult: (id)resultObject
//{
//	return [resultObject isKindOfClass: [NTINote class]];
//}

@end

@implementation NTIActivityTableModel

-(Class)dataLoaderClass
{
	return [NTIUserDataLoader class];	
}

-(NSString*)dataLoaderType
{
	return kNTIUserDataLoaderTypeRecursiveStream;
}

@end


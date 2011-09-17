//
//  NTINoteSavingDelegates.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/06.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINoteSavingDelegates.h"
#import "NTINoteLoader.h"
#import "NTINoteView.h"
#import "UIWebView-NTIExtensions.h"
#import "NTIAppPreferences.h"

@interface NTINoOpNoteSaverDelegate : NSObject<NTINoteSaver> {
	
}
@property (nonatomic,copy) NTINote* note;
@property (nonatomic,retain) id<NTINoteSaverDelegateView> webView;

-(id)initWithNote: (NTINote*)note view: (id<NTINoteSaverDelegateView>)view;
@end

@interface NTINewNoteSaverDelegate : NTINoOpNoteSaverDelegate
{
	@private
	NTINoteBlock onCreated;
}
-(id)initWithView: (id<NTINoteSaverDelegateView>)view
		onCreated: (NTINoteBlock)callback;
@end

@interface NTIRealNoteSaverDelegate : NTINoOpNoteSaverDelegate
{
	@private
	NTINoteBlock callback;
}
-(id)initWithNote: (NTINote*)note 
			 view: (id<NTINoteSaverDelegateView>)view
		 callback: (NTINoteBlock)cb;
@end


@implementation NTINoteSaverDelegate
+(id)saverForNewNote: (id<NTINoteSaverDelegateView>)view
{
	return [self saverForNewNote: view onCreated: nil];
}

+(id)saverForNewNote: (id<NTINoteSaverDelegateView>)view
		   onCreated: (NTINoteBlock)callback
{
	return [[[NTINewNoteSaverDelegate alloc] initWithView: view
												onCreated: callback]
			autorelease];
}

+(id)saverForNote: (NTINote*)note 
		   inPage: (id<NTINoteSaverDelegateView>)view
	  onCompleted: (NTINoteBlock)callback
{
	return [[[NTIRealNoteSaverDelegate alloc] initWithNote: note 
													  view: view
												  callback: callback] autorelease];
}

+(id)saverForNote: (NTINote*)note inPage: (id<NTINoteSaverDelegateView>)view
{
	return [self saverForNote: note
					   inPage: view
				  onCompleted: nil];
}

+(id)sharedNoOp
{
	return [[[NTINoteSaverDelegate alloc] init] autorelease];
}
@end

@implementation NTINoOpNoteSaverDelegate
@synthesize note, webView;
-(id)initWithNote: (NTINote*)_note view: (id<NTINoteSaverDelegateView>)view
{
	self = [super init];
	self.note = _note;
	self.webView = view;
	return self;
}

-(void)dealloc
{
	self.note = nil;
	self.webView = nil;
	[super dealloc];
}

//-(NTINote*)updateNote: (NTINote*)newNote fromView: (NTINoteViewControllerManager*)manager
//{
//	newNote.text = [manager text];
//	CGPoint editOrigin = manager.editView.bounds.origin;
//	CGPoint originInWindow = [webView.window convertPoint: editOrigin
//												 fromView: view.editView];
//	CGPoint htmlPoint = CGPointZero;
//	if( [webView respondsToSelector: @selector(htmlDocumentPointFromWindowPoint:)] ) {
//		htmlPoint = [(id)webView htmlDocumentPointFromWindowPoint: originInWindow];
//	}
//	newNote.left = htmlPoint.x;
//	newNote.top = htmlPoint.y;
//
//	return note;
//}

-(void)saveNote: (NTINote*)manager {}
-(void)deleteNote: (NTINote*)manager {}

@end

static void saveNote( NTINote* note, NSString* page, void(^complete)(NTINote* created) )
{
	//FIXME: Leaking?
	[NTINoteSaver saveNote: note
			  toDataserver: [[NTIAppPreferences prefs] dataserverURL]
				  username: [[NTIAppPreferences prefs] username]
				  password: [[NTIAppPreferences prefs] password]
					  page: page
				  complete: complete];
}

static void deleteNote( NTINote* note, NSString* page, void(^complete)(NTINote* created) )
{
	//FIXME: Leaking?
	[NTINoteSaver deleteNote: note
				onDataserver: [[NTIAppPreferences prefs] dataserverURL]
					username: [[NTIAppPreferences prefs] username]
					password: [[NTIAppPreferences prefs] password]
						page: page
					complete: complete];
	
}

@implementation NTINewNoteSaverDelegate

-(id)initWithView: (id<NTINoteSaverDelegateView>)view
		onCreated: (NTINoteBlock)callback
{
	self = [super initWithNote: nil
						  view: view];
	self->onCreated = [callback copy];
	return self;
}

-(void)saveNote: (NTINote*)note
{
	if( [note hasText] ) {
		//HACKY: Our delegate reference may be the only outstanding 
		//reference. When we reassign, our deallocate method could get called.
		//Thus, we must make sure we are safe for the duration of this methad.
		[self retain];
		
		saveNote( note, [self.webView ntiPageId], ^(NTINote* created){
			if( self->onCreated ) {
				self->onCreated( created );
			}
			[self release];
		});
	}
}
@end

@implementation NTIRealNoteSaverDelegate

-(id)initWithNote: (NTINote*)note 
			 view: (id<NTINoteSaverDelegateView>)view
		 callback: (NTINoteBlock)cb
{
	self = [super initWithNote: note view: view];
	self->callback = [cb copy];
	return self;
}

-(void)dealloc
{
	[self->callback release];
	[super dealloc];
}

-(void)saveNote: (NTINote*)updatedNote
{
	if( [updatedNote hasText] ) {
		//FIXME: Detect no real changes and ignore them.
		if( ![updatedNote isEqual: self.note] ) {
			saveNote( updatedNote, [self.webView ntiPageId], self->callback );
		}
	}
	else {
		[self deleteNote: updatedNote];
	}
	
}

-(void)deleteNote: (NTINote*)manager
{
	//HACKY: Our delegate reference may be the only outstanding 
	//reference. When we reassign, our deallocate method could get called.
	//Thus, we must make sure we are safe for the duration of this methad.
	[[self retain] autorelease];
	deleteNote( self.note, [self.webView ntiPageId], self->callback );
}

@end

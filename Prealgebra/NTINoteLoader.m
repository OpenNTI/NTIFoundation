//
//  NTINoteLoader.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/14.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTINoteLoader.h"
#import "NTIUtilities.h"
#import "OmniFoundation/NSDictionary-OFExtensions.h"
#import "OmniFoundation/NSMutableDictionary-OFExtensions.h"


@implementation NTINoteLoader

-(id)initWithUsername: (NSString*)u password: (NSString*)p
{
	self = [super initWithUsername: u password: p];
	return self;
}


+(NTINoteLoader*) noteLoaderForDataserver: (NSURL*)url
								 username: (NSString*)username
								 password: (NSString*)password
									 page: (NSString*)page
								 delegate: (id)delegate
{
	
	return (NTINoteLoader*)[self dataLoaderForDataserver: url
												username: username
												password: password 
													page: page
												delegate: delegate];
}

-(BOOL)wantsResult: (id)result
{
	//Our delegate will only ever see notes, so we check
	//that before calling super.
	return [result isKindOfClass: [NTINote class]] && [super wantsResult: result];
}

@end

@implementation NTINoteSaver

-(id)initWithUsername: (NSString*)u password: (NSString*)p
{
	self = [super initWithUsername: u password: p];
	return self;
}

+(NTINoteSaver*) saveEditOrDeleteNote: (NTINote*)note 
						  deleteOrPut: (NSString*)deleteOrPut
						 onDataserver: (NSURL*)url
							 username: (NSString*)username
							 password: (NSString*)password
								 page: (NSString*)page
							 complete: (NTINoteSaveCallback)c
{
	if( !note ) {
		return nil;
	}
	NTINoteSaver* loader = [[self alloc] initWithUsername: username password: password];
	loader->complete = [c copy]; //Blocks are copied at first
	
	loader->page = [page retain];
	loader->note = [note retain];
	
	NSString* method = nil;
	NSURL* pageUrl = nil;
	if( note.OID ) {
		//update
		pageUrl = [NSURL URLWithString: 
				   [NSString stringWithFormat: @"Objects/%@?format=plist", note.OID] 
						 relativeToURL: url];
		method = deleteOrPut;
	}
	else {
		//Fresh save.
		pageUrl = [NSURL URLWithString: 
				   [NSString stringWithFormat: @"users/%@/Notes/%@?format=plist",
					username, page ] 
						 relativeToURL: url];
		method = @"POST";
	}
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: pageUrl];
	[request setHTTPMethod: method];
	[request setHTTPBody: [note toPropertyListData]];
	
	//FIXME: Even making the connection can block, right?
	NSURLConnection* conn = [NSURLConnection connectionWithRequest: request delegate: loader];
	if( !conn ) {
		[loader release];
		loader = nil;
	}
	else {
		[loader autorelease];
	}
	return loader;
}

+(NTINoteSaver*) deleteNote: (NTINote*)note 
			   onDataserver: (NSURL*)url
				   username: (NSString*)username
				   password: (NSString*)password
					   page: (NSString*)page
				   complete: (NTINoteSaveCallback)c
{
	if( !note.ID ) {
		return nil;
	}
	return [NTINoteSaver saveEditOrDeleteNote: note
								  deleteOrPut: @"DELETE"
								 onDataserver: url
									 username: username
									 password: password
										 page: page
									 complete: c];
}

+(NTINoteSaver*) saveNote: (NTINote*)note 
			 toDataserver: (NSURL*)url
				 username: (NSString*)username
				 password: (NSString*)password
					 page: (NSString*)page
				 complete: (NTINoteSaveCallback)c
{
	return [NTINoteSaver saveEditOrDeleteNote: note
								  deleteOrPut: @"PUT"
								 onDataserver: url
									 username: username
									 password: password
										 page: page
									 complete: c];
}

-(void)connectionDidFinishLoading: (NSURLConnection*)connection
{
	[super connectionDidFinishLoading: connection];
	if( self.statusCode >= 200 && self.statusCode < 300 ) {
		if( complete ) {
			NTINote* completeNote = nil;
			if( self.statusCode == 204 ) {
				//No content
				//mock up a note with the Last Modified time
				//from the server
				completeNote = [[self->note copy] autorelease];
				completeNote.LastModified = -1;
			}
			else {
				NSDictionary* dict = [self dictionaryFromData];
				completeNote = [NTINote objectFromPropertyListObject: dict];
			}
			
			complete( completeNote );
		}
	}
}

-(void)dealloc
{
	NTI_RELEASE( self->note );
	NTI_RELEASE( self->complete );
	[super dealloc];
}

@end

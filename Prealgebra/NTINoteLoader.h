//
//  NTINoteLoader.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/14.
//  Copyright 2011 NextThought. All rights reserved.
//


#import "NTIUserData.h"
#import "NTIUserDataLoader.h"


@interface NTINoteLoader : NTIUserDataLoader {
}

+(NTINoteLoader*) noteLoaderForDataserver: (NSURL*)url
								 username: (NSString*)user
								 password: (NSString*)password
									 page: (NSString*)page
								 delegate: (id)delegate;

@end

typedef void(^NTINoteSaveCallback)(NTINote*);

@interface NTINoteSaver : NTIUserDataLoaderBase {
	//TODO: Combine this with NTIUserDataMutaterBase
	NTINote* note;
	void(^complete)(NTINote*);
}

+(NTINoteSaver*) saveNote: (NTINote*)note 
			 toDataserver: (NSURL*)url
				 username: (NSString*)user
				 password: (NSString*)password
					 page: (NSString*)page
				 complete: (NTINoteSaveCallback)c;

+(NTINoteSaver*) deleteNote: (NTINote*)note 
			 onDataserver: (NSURL*)url
				 username: (NSString*)user
				 password: (NSString*)password
					 page: (NSString*)page
				 complete: (NTINoteSaveCallback)c;

@end

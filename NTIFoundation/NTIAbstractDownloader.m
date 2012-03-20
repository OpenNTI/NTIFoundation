//
//  NTIAbstractDownloader.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/28.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIAbstractDownloader.h"
#import "NSString-NTIExtensions.h"
#import "OmniUI/OUIAppController.h"

#define kHeaderLastModified @"LAST-MODIFIED"

@implementation NTIAbstractDownloader
@synthesize statusCode,expectedContentLength, lastModified;

-(void)connection: (NSURLConnection*)connection didReceiveResponse: (id)response
{
	self->expectedContentLength = [response expectedContentLength];
	if( [response isKindOfClass: [NSHTTPURLResponse class]] ) {
		self->statusCode = [response statusCode];
		
		NSDictionary* allHeaders = [response allHeaderFields];
		//TODO: Lousy way to be Case insensitive
		NSString* lastMod = nil;
		for( NSString* key in allHeaders ) {
			if( [[key uppercaseString] isEqual: kHeaderLastModified] ) {
				lastMod = [allHeaders objectForKey: key];
				break;
			}
		}
		self->lastModified = [lastMod httpHeaderDateValue];
	}
}

//In debug builds, we accept ANY self-signed certificates. See comments below.
//Later, we might make this more specific.
#ifdef DEBUG
- (BOOL)connection: (NSURLConnection*)connection 
canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace*)protectionSpace
{
	//By default (e.g., if we don't implement this), the system will
	//use the keychain for client SSL certs or server SSL cert 
	//authentication. To use self-signed certs, then, which won't be in the keypad,
	//we have to take responsibility and say we will take them. 
	if( OFISEQUAL( protectionSpace.authenticationMethod, NSURLAuthenticationMethodServerTrust ) ) {
		return YES;
	}
	if( OFISEQUAL( protectionSpace.authenticationMethod, NSURLAuthenticationMethodClientCertificate ) ) {	
		//We cannot do client certs
		return NO;
	}
	//The system defaults to returning YES for everything else
	return YES;
}
#endif

-(BOOL)statusWasSuccess
{
	return self.statusCode >= 200 && self.statusCode < 300;	
}

//We no long have the information to respond to this with.  If we don't have an auth cookie there is 
//nothing we can do.  The default implementation of this method will check the credential storage
//and use credentials if they exist, otherwise the [challenge sender] is sent a continue without authentication
//message

//-(void)connection: (NSURLConnection*)connection didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge*)challenge
//{
//	//NSURLConnection doesn't give up, it keeps calling this method
//	//even if the username and password are bad. So we have to handle bailing.
//	if( [challenge previousFailureCount] == 0 ) {	
//		[[challenge sender]
//		 useCredential: [NSURLCredential credentialWithUser: username
//												   password: password
//												persistence: NSURLCredentialPersistenceForSession]
//		 forAuthenticationChallenge: challenge];
//	}
//	else {
//		[[challenge sender] cancelAuthenticationChallenge: challenge];
//	}
//}

-(void)connection: (NSURLConnection*)connection didFailWithError: (NSError*)error
{
}

-(void)connectionDidFinishLoading: (NSURLConnection*)connection
{
	if( ![self statusWasSuccess] ){
		NSError* error = [NSError errorWithDomain: @"NTIDataserverResponseDomain" 
											 code: self.statusCode 
										 userInfo: nil];
		OUI_PRESENT_ERROR(error);
	}
}

@end

@implementation NTIBufferedDownloader

-(void)connection: (NSURLConnection*)connection didReceiveResponse: (id)response
{
	[super connection: connection didReceiveResponse: response];
	dataBuffer = [[NSMutableData alloc] init];
}

-(void)connection: (NSURLConnection*)connection didReceiveData: (NSData*)data
{
	[dataBuffer appendData: data];
}

-(void)connection: (NSURLConnection*)connection didFailWithError: (NSError*)error
{
	//TODO: Somebody needs to present this to the user.
	NSLog( @"Failed to download data: %@", error );
	dataBuffer = nil;
}

-(NSMutableData*)copyData
{
	NSMutableData* result = self->dataBuffer;
	self->dataBuffer = [[NSMutableData alloc] init];
	return result;
}

-(NSMutableData*)copyDataFinal
{
	NSMutableData* result = self->dataBuffer;
	self->dataBuffer = nil;
	return result;
}

-(id)objectFromData
{
	return [NSPropertyListSerialization 
			propertyListWithData: dataBuffer 
			options: NSPropertyListImmutable
			format: nil error: NULL];
}

-(NSDictionary*)dictionaryFromData
{
	NSDictionary* result = nil;
	id o = [self objectFromData];
	if( [o isKindOfClass: [NSDictionary class]] ) {
		result = o;
	}
	return result;
}

-(NSArray*)arrayFromData
{
	NSArray* result = nil;
	id o = [self objectFromData];
	if( [o isKindOfClass: [NSArray class]] ) {
		result = o;
	}
	return result;
}

-(NSString*)stringFromData
{
	return [NSString stringWithData: dataBuffer encoding: NSUTF8StringEncoding];
}

-(NSData*)data
{
	return [dataBuffer copy];	
}

-(void)dealloc
{
	dataBuffer = nil;
}
@end

@implementation NTIDelegatingDownloader
@synthesize nr_delegate;

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[super connection: connection didFailWithError: error];
	if( [self->nr_delegate respondsToSelector: @selector(downloader:connection:didFailWithError:)] ){
		[self->nr_delegate downloader: self connection: connection didFailWithError: error];
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[super connectionDidFinishLoading: connection];
	if( [self->nr_delegate respondsToSelector: @selector(downloader:didFinishLoading:)] ){
		[self->nr_delegate downloader: self didFinishLoading: connection];
	}
}

@end

@implementation NTIStreamDownloader

-(id)initWithUsername: (NSString*)user 
			 password: (NSString*)password
		 outputStream: (NSOutputStream*)stream
			 onFinish: (void(^)())finish
			  onError: (void(^)())error
{
	//self = [super initWithUsername: user password: password];
	self = [super init];
	self->outputStream = stream;
	[stream setDelegate: self];
	
	self->onFinish = [finish copy];
	self->onError = [error copy];
	return self;
}

-(void)closeStream
{
	[self->outputStream close];
	[self->outputStream removeFromRunLoop: [NSRunLoop currentRunLoop] 
								  forMode: NSDefaultRunLoopMode];
	
	self->outputStream = nil;
}

-(void)connection: (NSURLConnection*)connection didReceiveData: (NSData*)data
{
	[super connection: connection didReceiveData: data];
	//FIXME: For some reason, when I have both the connection and the stream
	//in a run loop, the connection appears to "starve" the stream. I get
	//many connection events, and NO stream events. There's only a stream 
	//event at the very end, when the connection finishes. This means our in-memory
	//buffer could become very, very large. To workaround this, I simulate
	//stream events here.
	if( [self->outputStream hasSpaceAvailable] ) {
		[self stream: self->outputStream handleEvent: NSStreamEventHasSpaceAvailable];
	}	
}

-(void)stream: (NSOutputStream*)theStream handleEvent: (NSStreamEvent)streamEvent
{
	if( streamEvent == NSStreamEventHasSpaceAvailable ) {
		//Fetch data if needed
		if( !self->currentDataChunk ) {
			self->currentDataChunk = [super copyData];
			currentOffset = 0;
		}
		//If we have reached the end, there will be no data object. 
		//There will always be a data object from the time we receive a response
		//until the response has finished
		if( !self->currentDataChunk ) {
			[self closeStream];
			if( self->onFinish ) {
				self->onFinish();
			}
			return;
		}
		
		//Write what we can, if we have something
		if( [self->currentDataChunk length] == 0 ) {
			//Zero byte chunk. Interesting.
			self->currentDataChunk = nil;
		}
		else {
			uint8_t* bytes = [self->currentDataChunk mutableBytes];
			bytes += currentOffset;
			NSInteger written = [theStream write: bytes
									   maxLength: [self->currentDataChunk length] - currentOffset];
			if( written > -1 ) {
				currentOffset += written;
				if( currentOffset >= [self->currentDataChunk length] ) {
					//We've written it all, let go.
					currentOffset = 0;
					self->currentDataChunk = nil;
				}
			}
			else {
				NSLog( @"Expecting error callback" );
				//If we actually close the stream now, we won't
				//get the error callback.
			}
		}
	}
	else if( streamEvent == NSStreamEventErrorOccurred ) {
		NSError* theError = [theStream streamError];
		NSLog( @"%@", theError );
		if( self->onError ) {
			self->onError();
		}
	}
}

-(void)connection: (NSURLConnection*)connection didReceiveResponse: (id)response
{
	[super connection: connection didReceiveResponse: response];
	if( self.statusCode == 200 ) {
		[self->outputStream scheduleInRunLoop: [NSRunLoop currentRunLoop]
									  forMode: NSDefaultRunLoopMode];
		[self->outputStream open];
	}
}

-(void)connection: (NSURLConnection*)connection didFailWithError: (NSError*)error
{
	[super connection: connection didFailWithError: error];
	//TODO: Delete the file?
	[self closeStream];
	if( self->onError ) {
		self->onError();
	}
}

-(void)connectionDidFinishLoading: (NSURLConnection*)connection
{
	[super connectionDidFinishLoading: connection];
	NSMutableData* lastData = [super copyDataFinal];
	if( self->currentDataChunk ) {
		[self->currentDataChunk appendData: lastData];
		//If we wrote zero bytes in a stream callback, we
		//stop getting space events until an explicit write. Therefore,
		//in case that happened, we do an explicit write here.
		[self stream: self->outputStream handleEvent: NSStreamEventHasSpaceAvailable];
	}
	else {
		self->currentDataChunk = lastData;
		if( [self->outputStream hasSpaceAvailable] ) {
			[self stream: self->outputStream handleEvent: NSStreamEventHasSpaceAvailable];
		}
	}
}

-(void)dealloc
{
	[self closeStream];
}

@end


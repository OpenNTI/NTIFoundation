//
//  NTIAbstractDownloader.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/28.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIAbstractDownloader.h"
#import "NSString-NTIExtensions.h"
#import "NSData-NTIJSON.h"
#import "OmniUI/OUIAppController.h"
#import <CFNetwork/CFNetwork.h>


@interface NSData(NTIExtensions)
-(BOOL)isPrefixedByByte:(const uint8_t *)data;
@end

@implementation NSData(NTIExtensions)
- (BOOL)isPrefixedByByte:(const uint8_t *)ptr;
{
	if ([self length] == 0) {
		return NO;
	}
	const uint8_t *selfPtr;
    selfPtr = [self bytes];
	
	//We only care about the first byte.
	if (*ptr != *selfPtr) {
		return NO;
	}
    return YES;
}

@end


#define kHeaderLastModified @"LAST-MODIFIED"
#define kHeaderETag @"ETAG"

@implementation NTIAbstractDownloader
@synthesize statusCode,expectedContentLength, lastModified;

#ifdef DEBUG

static NSMutableSet* getTrustedHosts()
{
	static NSMutableSet* result = nil;
	if( result == nil){
		result = [NSMutableSet set];
	}
	return result;
}

+(void)addTrustedHost: (NSString*)host
{
	[getTrustedHosts() addObject: host];
}

+(BOOL)isHostTrusted: (NSString*)host
{
	return [getTrustedHosts() containsObject: host];
}
#endif

-(void)connection: (NSURLConnection*)connection didReceiveResponse: (id)response
{
	self->expectedContentLength = [response expectedContentLength];
	if( [response isKindOfClass: [NSHTTPURLResponse class]] ) {
		self->statusCode = [response statusCode];
		
		NSDictionary* headers = [response allHeaderFields]; //This is a case insensitive dict
		
		self->lastModified = [[headers objectForKey: kHeaderLastModified] httpHeaderDateValue];
		self->_ETag = [headers objectForKey: kHeaderETag];
	}
}

#ifdef DEBUG

//In debug builds, we accept ANY self-signed certificates. See comments below.
//Later, we might make this more specific.

-(NSURLCredential*)credentialForContinuingWithChallenge: (NSURLAuthenticationChallenge *)challenge
{
	if ( [challenge.protectionSpace.authenticationMethod isEqualToString: NSURLAuthenticationMethodServerTrust] ){
		if ( [[self class] isHostTrusted: challenge.protectionSpace.host] ){
			return [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust];
		}
	}
	
	return nil;
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if( OFISEQUAL( challenge.protectionSpace.authenticationMethod,
				  NSURLAuthenticationMethodClientCertificate ) ){
		//We cannot do client certs
		[challenge.sender cancelAuthenticationChallenge: challenge];
		return;
	}
	
	if( OFISEQUAL( challenge.protectionSpace.authenticationMethod,
					   NSURLAuthenticationMethodServerTrust )){
		NSURLCredential* credential = [self credentialForContinuingWithChallenge: challenge];
		if(credential){
			[challenge.sender useCredential: credential forAuthenticationChallenge: challenge];
			return;
		}
	}
	
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge: challenge];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
	if( OFISEQUAL( challenge.protectionSpace.authenticationMethod,
				  NSURLAuthenticationMethodClientCertificate ) ){
		//We cannot do client certs
		completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
		return;
	}
	
	if( OFISEQUAL( challenge.protectionSpace.authenticationMethod,
				  NSURLAuthenticationMethodServerTrust )){
		NSURLCredential* credential = [self credentialForContinuingWithChallenge: challenge];
		if(credential){
			completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
			return;
		}
	}
	
	completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
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
}

#pragma mark NSURLSession delegate

//The NSURLSession callbacks happen on some background queue (using whatever NSOperationQueue the session
//was created with.  The old NSURLConnection had all its callbacks coming across the main queue.  B/c
//of this where appropriate through the work onto the main queue so that we can maintain parity with the old implementation

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))handler
{
	typedef void(^Handler)(NSURLSessionResponseDisposition);
	Handler completionHandler = [handler copy];
	dispatch_async(dispatch_get_main_queue(), ^(){
		[self connection: nil didReceiveResponse: response];
		completionHandler(NSURLSessionResponseAllow);
	});
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
	dispatch_async(dispatch_get_main_queue(), ^(){
		if(error){
			[self connection: nil didFailWithError: error];
		}
		else{
			[self connectionDidFinishLoading: nil];
		}
	});
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
	dispatch_async(dispatch_get_main_queue(), ^(){
		[self connection: [NSURLConnection new] didReceiveData: data];
	});
}

@end

@implementation NTIBufferedDownloader

+(BOOL)isPlistData: (NSData *)data
{
	//NOTE: We expect to have either json data or plist data both encoded in UTF-8 format.
	//		We detect if it's plist data or not, by checking the first character, 
	//		for plist, it is '<' or 0x3C in UTF-8 encoding.
	uint8_t	firstChar[1] = {0x3C};
#if 0
	NSString* dataString = [NSString stringWithData: data encoding: NSUTF8StringEncoding];
	NSLog(@"%@", dataString);
	NSData* fData = [NSData dataWithBytes: firstChar length: 1];
	NSLog(@"%@", [NSString stringWithData: fData encoding: NSUTF8StringEncoding]);
#endif
	BOOL stype = [data isPrefixedByByte: firstChar];
	
	if (stype) {
		return YES;
	}
	else {
		return NO;
	}
}

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
	if ( [NTIBufferedDownloader isPlistData: self->dataBuffer] ) {
		return [NSPropertyListSerialization 
				propertyListWithData: dataBuffer 
				options: NSPropertyListImmutable
				format: nil error: NULL];
	}
	else {
		return [self->dataBuffer jsonObjectValue];
	}
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
		   onProgress: (void(^)(float percentComplete)) progress
{
	//self = [super initWithUsername: user password: password];
	self = [super init];
	self->consumed = 0;
	self->outputStream = stream;
	[stream setDelegate: self];
	
	self->onFinish = [finish copy];
	self->onError = [error copy];
	self->onProgress = [progress copy];
	return self;
}

-(void)calculateAndSendProgress
{
	if(self->onProgress){
		double progress = (double)self->consumed / self.expectedContentLength;
		self->onProgress(progress * 100);
	}
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
	self->consumed += data.length;
	[self calculateAndSendProgress];
	
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
			//NSLog(@"Wrote data of length %ld", written);
			if( written > -1 ) {
				currentOffset += written;
				if( currentOffset >= [self->currentDataChunk length] ) {
					//We've written it all, let go.
					currentOffset = 0;
					self->currentDataChunk = nil;
				}
			}
			else {
				NSLog( @"Expecting error callback %@", [theStream streamError] );
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
	if( self.statusWasSuccess) {
		[self calculateAndSendProgress];
		//NSLog(@"Did recieve response expected content length %lld", [response expectedContentLength]);
		[self->outputStream scheduleInRunLoop: [NSRunLoop currentRunLoop]
									  forMode: NSDefaultRunLoopMode];
		[self->outputStream open];
	}
	else{
		NSLog(@"Encountered unsuccessful response status code of %ld", (long)self.statusCode);
		if( self->onError ) {
			self->onError();
		}
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
		if(lastData.length > 0){
			self->currentDataChunk = lastData;
		}
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


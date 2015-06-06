//
//  NTIAbstractDownloader.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/28.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniFoundation/OmniFoundation.h>

/**
 * Intended to be a base class for implementations of 
 * a NSURLConnection delegate.
 */
@interface NTIAbstractDownloader : OFObject<NSURLConnectionDataDelegate, NSURLSessionDataDelegate> {
	@private
	NSInteger statusCode;
	long long expectedContentLength;
	NSDate* lastModified;
}

#ifdef DEBUG
+(void)addTrustedHost: (NSString*)host;
+(BOOL)isHostTrusted: (NSString*)host;
#endif

@property (readonly) NSDate* lastModified;
@property (readonly) NSString* ETag;
@property (readonly) NSInteger statusCode;
@property (readonly) long long expectedContentLength;

-(BOOL)statusWasSuccess;

-(void)connection: (NSURLConnection*)connection didReceiveResponse: (id)response;
//-(void)connection: (NSURLConnection*)connection didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge;
-(void)connection: (NSURLConnection*)connection didFailWithError: (NSError*)error;
-(void)connectionDidFinishLoading: (NSURLConnection*)connection;

@end

@interface NTIBufferedDownloader : NTIAbstractDownloader {
	@package
	NSMutableData* dataBuffer;
}
-(void)connection: (NSURLConnection*)connection didReceiveResponse: (id)response;
-(void)connection: (NSURLConnection*)connection didReceiveData: (NSData*)data;
-(void)connection: (NSURLConnection*)connection didFailWithError: (NSError*)error;

/**
 * After the download has completed, this can retreive a NSDictionary
 * from PList data. May throw. If the plist does not produce a dictionary,
 * returns nil.
 */
-(NSDictionary*)dictionaryFromData;

/**
 * After the download has completed, this can retreive a NSArray
 * from PList data. May throw. If the plist does not produce a NSArray,
 * returns nil.
 */
-(NSArray*)arrayFromData;

/**
 * After the download has completed, this can retreive a property list object
 * from the data. May throw.
 */
-(id)objectFromData;

/**
 * After the download has completed this can retreive the databuffer as a string
 * in utf-8 encoding
 */
-(NSString*)stringFromData;

-(NSData*)data;

@end

@class NTIDelegatingDownloader;
@protocol NTIDownloaderDelegate <NSObject>

-(void)downloader:(NTIDelegatingDownloader *)d connection: (NSURLConnection*) c didFailWithError:(NSError *)error;
-(void)downloader:(NTIDelegatingDownloader *)d didFinishLoading:(NSURLConnection *)c;

@end

//A delegator that passes on the didFinish and didFail messages
@interface NTIDelegatingDownloader : NTIBufferedDownloader {
@private
    id __weak nr_delegate;
}
@property (nonatomic, weak) id nr_delegate;
@end

@interface NTIStreamDownloader : NTIBufferedDownloader<NSStreamDelegate> {
@private
	NSOutputStream* outputStream;
	NSMutableData* currentDataChunk;
	NSUInteger currentOffset;
	NSUInteger consumed;
	void (^onFinish)();
	void (^onError)();
	void (^onProgress)(float percentComplete);
}
/**
 * The callback methods, if given, will be called on the run loop of
 * the NSURLConnection whose delegate we are.
 */
-(id)initWithUsername: (NSString*)user 
			 password: (NSString*)password
		 outputStream: (NSOutputStream*)stream
			 onFinish: (void(^)())finish
			  onError: (void(^)())error
		   onProgress: (void(^)(float percentComplete)) progress;

@end

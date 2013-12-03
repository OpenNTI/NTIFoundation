//
//  NTIURLSessionManager.m
//  NTIFoundation
//
//  Created by Christopher Utz on 12/2/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import "NTIURLSessionManager.h"
#import "NTIAbstractDownloader.h"

@interface NTIURLSessionManager()<NSURLSessionTaskDelegate>{
	@private
	dispatch_queue_t _delegateQueue;
}
@property (nonatomic, readonly) NSMutableDictionary* taskDelegates;
@property (nonatomic, readonly) NSOperationQueue* sessionOperationQueue;
@property (nonatomic, strong) NSURLSession* session;
-(id<NSURLSessionTaskDelegate>)delegateForTask: (NSURLSessionTask*)task;
@end

@implementation NTIURLSessionManager

+(id)defaultSessionManager
{
	static NTIURLSessionManager* sm;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sm = [[NTIURLSessionManager alloc] init];
	});

	return sm;
}

-(id)init
{
	return [self initWithConfiguration: nil];
}

-(id)initWithConfiguration: (NSURLSessionConfiguration*)configuration
{
	if(configuration == nil){
		configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	}
	
	self = [super init];
	if(self){
		self->_sessionOperationQueue = [[NSOperationQueue alloc] init];
		self.sessionOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
		
		self->_session = [self createSessionWithConf: configuration];
		
		self->_delegateQueue = dispatch_queue_create("com.nextthought.sessionmanagerlock", DISPATCH_QUEUE_CONCURRENT);
		self->_taskDelegates = [NSMutableDictionary dictionary];
	}
	
	return self;
}

-(NSURLSession*)createSessionWithConf: (NSURLSessionConfiguration*)conf
{
	return [NSURLSession sessionWithConfiguration: conf
										 delegate: self
									delegateQueue: self.sessionOperationQueue];
}

-(void)updateSessionConfiguration: (NSURLSessionConfiguration*)conf
{
	self.session = [self createSessionWithConf: conf];
}

-(void)setSession: (NSURLSession *)session
{
	[self.session finishTasksAndInvalidate];
	self->_session = session;
}

-(id<NSURLSessionTaskDelegate>)delegateForTask:(NSURLSessionTask *)task
{
	__block id delegate;
	dispatch_sync(self->_delegateQueue, ^{
		delegate = [self.taskDelegates objectForKey: @(task.taskIdentifier)];
	});
	return delegate;
}

-(void)setDelegate: (id<NSURLSessionTaskDelegate>)delegate forTask: (NSURLSessionTask*)task
{
	dispatch_barrier_async(self->_delegateQueue, ^(){
		[self.taskDelegates setObject: delegate forKey: @(task.taskIdentifier)];
	});
}

-(void)removeDelegateForTask: (NSURLSessionTask*)task
{
	dispatch_barrier_async(self->_delegateQueue, ^(){
		[self.taskDelegates removeObjectForKey: @(task.taskIdentifier)];
	});
}


#pragma mark session delegate

#ifdef DEBUG

-(NSURLCredential*)credentialForContinuingWithChallenge: (NSURLAuthenticationChallenge *)challenge
{
	if ( [challenge.protectionSpace.authenticationMethod isEqualToString: NSURLAuthenticationMethodServerTrust] ){
		if ( [[NTIAbstractDownloader class] isHostTrusted: challenge.protectionSpace.host] ){
			return [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust];
		}
	}
	
	return nil;
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
	NSURLCredential* credential = [self credentialForContinuingWithChallenge: challenge];
	completionHandler(credential ? NSURLSessionAuthChallengeUseCredential : NSURLSessionAuthChallengePerformDefaultHandling, credential);
}

#endif

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
	id<NSURLSessionTaskDelegate> delegate = [self delegateForTask: dataTask];
	if([delegate respondsToSelector: _cmd]){
		[(id)delegate URLSession: session dataTask: dataTask didReceiveResponse: response completionHandler: completionHandler];
	}
	else{
		completionHandler(NSURLSessionResponseAllow);
	}
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
	id<NSURLSessionTaskDelegate> delegate = [self delegateForTask: task];
	
	if([delegate respondsToSelector: _cmd]){
		[delegate URLSession: session task: task didCompleteWithError: error];
	}
	
	[self removeDelegateForTask: task];
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
	id<NSURLSessionTaskDelegate> delegate = [self delegateForTask: dataTask];
	if([delegate respondsToSelector: _cmd]){
		[(id)delegate URLSession: session dataTask: dataTask didReceiveData: data];
	}
}


@end

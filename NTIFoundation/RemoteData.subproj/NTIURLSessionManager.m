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
		sm->_isSharedSessionManager = YES;
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
	//It's very important we throw this on the session manager lock.
	//Resume task is a dispatch barrier there so that it waits for the delegates to set.
	//We've seen crashes where a task gets created and the resume gets thrown on the barrier cue.
	//during the time the task may sit in the queue waiting to start if the session gets changed
	//you get an exec_bad_access when the block finally runs. Naturally the trace is entirely unhelpful
	//but a simple test app that creates a session and task, invalidates the session and then resumes
	//the task shows the same crash and stack.
	//you end up with a exec_bad_access at _CFURLConnectionSessionCreateConnectionWithProperties
	
	//dispatch this on the queue but make it wait for other tasks so we don't jump ahead of a resume
	dispatch_barrier_async(self->_delegateQueue, ^(){
		//Tells the old session to finish up its tasks and invalidate itself
		//existing tasks will be allowed to finish but new tasks cannot be created
		//or resumed.
		[self.session finishTasksAndInvalidate];
		
		//Assign the new session
		self->_session = session;
		self->_session.sessionDescription = self.sessionManagerDescription;
	});
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

-(void)resumeTask: (NSURLSessionTask*)task
{
	//When resuming a task we use a dispatch_barrier_async.  This is to
	//make sure that we don't resume it until any of the setDelegate calls
	//that were submitted before the task was resumed are set in the map.
	//This is crucial to ensure that the delegates are setup and are guarenteed
	//to be called by the time the task moves to states that need them.
	dispatch_barrier_async(self->_delegateQueue, ^(){
		[task resume];
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

-(void)invalidateSessionCancelTasks: (BOOL)cancel
{
	if(cancel){
		[self.session invalidateAndCancel];
	}
	else{
		[self.session finishTasksAndInvalidate];
	}
}

-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
	NSLog(@"Session %@ became invalid. %@", session.sessionDescription?:session, error);
}

-(void)dealloc
{
	[self invalidateSessionCancelTasks: YES];
	self->_session = nil;
}

@end

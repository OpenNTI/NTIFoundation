//
//  NTIURLSessionManager.h
//  NTIFoundation
//
//  Created by Christopher Utz on 12/2/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>

@interface NTIURLSessionManager : OFObject<NSURLSessionTaskDelegate>

+(id)defaultSessionManager;

-(id)initWithConfiguration: (NSURLSessionConfiguration*)configuration;

@property (nonatomic, readonly) NSURLSession* session;

@property (nonatomic, assign) BOOL isSharedSessionManager;

-(void)setDelegate: (id<NSURLSessionTaskDelegate>)delegate forTask: (NSURLSessionTask*)task;
-(void)removeDelegateForTask: (NSURLSessionTask*)task;

-(void)updateSessionConfiguration: (NSURLSessionConfiguration*)conf;

-(void)resumeTask: (NSURLSessionTask*)task;

-(void)invalidateSessionCancelTasks: (BOOL)cancel;

@property (nonatomic, copy) NSString* sessionManagerDescription;

@end

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

-(void)setDelegate: (id<NSURLSessionTaskDelegate>)delegate forTask: (NSURLSessionTask*)task;
-(void)removeDelegateForTask: (NSURLSessionTask*)task;

-(void)updateSessionConfiguration: (NSURLSessionConfiguration*)conf;

@end

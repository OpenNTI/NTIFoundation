//
//  NTIOSCompat.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/22.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Things to help ease the burden of porting between releases
 */
#if __IPHONE_5_0 < __IPHONE_OS_VERSION_MAX_ALLOWED

@interface NSObject(NTI5Compatibility)
-(void)removeObserver: (NSObject*)observer 
		   forKeyPath: (NSString*)keyPath
			  context: (void*)context;
@end


@interface NSURL(NTI5Compatibility)
-(NSURL*)URLByAppendingPathComponent: (id)path isDirectory: (BOOL)b;
@end

#endif


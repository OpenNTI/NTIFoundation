//
//  NTIOSCompat.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/22.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Things to help ease the burden of porting between releases
 */
#if __IPHONE_5_0 < __IPHONE_OS_VERSION_MAX_ALLOWED

@interface NSObject(NTI5Compatibility)
-(void)removeObserver: (NSObject*)observer 
		   forKeyPath: (NSString*)keyPath
			  context: (void*)context;
@end

@interface UIReferenceLibraryViewController: NSObject
+(BOOL)dictionaryHasDefinitionForTerm: (NSString*)_;
-(id)initWithTerm: (NSString*)_;
@end


@interface UIViewController(NTI5Compatibility)
-(void)removeFromParentViewController;
-(void)addChildViewController: (UIViewController*)child;
@end

@interface UIWebView(NTI5Compatibility)
-(UIScrollView*)scrollView;
@end


@interface NSURL(NTI5Compatibility)
-(NSURL*)URLByAppendingPathComponent: (id)path isDirectory: (BOOL)b;
@end


enum {
    NSJSONReadingMutableContainers = (1UL << 0),
    NSJSONReadingMutableLeaves = (1UL << 1),
    NSJSONReadingAllowFragments = (1UL << 2)
};
typedef NSUInteger NSJSONReadingOptions;

typedef NSUInteger NSJSONWritingOptions;

@interface NSJSONSerialization : NSObject {
}
+ (BOOL)isValidJSONObject:(id)obj;
+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error;
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error;
+ (NSInteger)writeJSONObject:(id)obj toStream:(NSOutputStream *)stream options:(NSJSONWritingOptions)opt error:(NSError **)error;
+ (id)JSONObjectWithStream:(NSInputStream *)stream options:(NSJSONReadingOptions)opt error:(NSError **)error;
@end


#endif

//Notice these are declared outside of the if/endif block. We always
//implement them.

//Returns the class, or nil if not available.
id getClass_NSJSONSerialization(void);
id getClass_UIReferenceLibraryViewController(void);


#define NTI_RETURN_SELF_TO_JSON() do { \
id jsonClass = getClass_NSJSONSerialization(); \
if( jsonClass ) { \
	NSData* data = [jsonClass dataWithJSONObject: self \
										 options: 0 \
										   error: nil]; \
	return [NSString stringWithData: data \
						   encoding: NSUTF8StringEncoding]; \
} \
} while(0)


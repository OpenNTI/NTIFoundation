//
//  NTINavigationHistory.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/07.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTINavigationHistoryItem;
@class NTINavigationItem;

@interface NTINavigationHistory : NSObject {
	@private
	NSMutableArray* backHistory;
	NSMutableArray* forwardHistory;
}


/**
 * An array of the NTINavigationHistoryItems, or empty.
 */
@property(nonatomic,readonly) NSArray* backHistory;


/**
 * An array of the NTINavigationHistoryItems, or empty.
 */
@property(nonatomic,readonly) NSArray* forwardHistory;

/**
 * How far it's possible to go back.
 */
@property(nonatomic,readonly) NSInteger backDepth;

/**
 * How far it's possible to go forward.
 */
@property(nonatomic,readonly) NSInteger forwardDepth;

@property(nonatomic,readonly,getter=isBackEmpty) BOOL backEmpty;
@property(nonatomic,readonly,getter=isForwardEmpty) BOOL forwardEmpty;

/**
 * Will not duplicate items on top of the stack; returns nil
 * in that case.
 */
-(id)pushBackItem: (NTINavigationItem*)item;

/**
 * Pops and removes the last item and returns it, or nil.
 */
-(NTINavigationHistoryItem*)popBackItem;

/**
 * Will not duplicate items on top of the stack; returns nil
 * in that case.
 */
-(id)pushForwardItem: (NTINavigationItem*)item;

/**
 * Pops and removes the last item and returns it, or nil.
 */
-(NTINavigationHistoryItem*)popForwardItem;

@end



@interface NTINavigationHistoryItem: NSObject {
}

@property (nonatomic,readonly) NSString* name;
@property (nonatomic,readonly) id href;
@property (nonatomic,readonly) NTINavigationItem* navigationItem;

-(id)initWithItem: (NTINavigationItem*)item;

@end

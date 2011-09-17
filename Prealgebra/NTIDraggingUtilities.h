//
//  NTIDraggingUtilities.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OUIDragGestureRecognizer;

//TODO: Fix these names

void trackDragging(	UIResponder* self,
				   	OUIDragGestureRecognizer* drager, 
					UIView** draggingProxyView );

void enableDragTracking( UIView* view, id target, SEL sel );
@protocol NTIDraggingInfo;
void NTIDraggingShowTooltipInView( id<NTIDraggingInfo>info, NSString* action, UIView* view );
void NTIDraggingShowTooltipInViewAboveTouch( id<NTIDraggingInfo>info, NSString* action, UIView* view );
//This is all based on NSDragging, modified for a single process


typedef enum {
	NTIDragOperationNone    = 0,
	NTIDragOperationCopy    = 1,
	NTIDragOperationLink    = 2,
	NTIDragOperationGeneric = 4,
	NTIDragOperationPrivate = 8,
	NTIDragOperationAll_Obsolete  = 15,
	NTIDragOperationMove    = 16,
	NTIDragOperationDelete  = 32,
	NTIDragOperationEvery   = NSUIntegerMax
} NTIDragOperation;
//typedef NSUInteger NTIDragOperation;


/* protocol for the sender argument of the messages sent to a drag destination.  The view or
 window that registered dragging types sends these messages as dragging is
 happening to find out details about that session of dragging.
 */
@protocol NTIDraggingInfo
//- (NSWindow *)draggingDestinationWindow;
/**
 * The operations the source would like to allow.
 */
-(NTIDragOperation)draggingSourceOperationMask;
/**
 * The current drag point in the Window's coordinates.
 */
-(CGPoint)draggingLocation;

/**
 * The image being dragged.
 */
-(UIImage*)draggedImage;
//- (NSPoint)draggedImageLocation;
//- (NSImage *)draggedImage;
//- (NSPasteboard *)draggingPasteboard;
/**
 * The source view of dragging.
 */
@property (nonatomic, readonly)  id draggingSource;

/**
 * The data object being dragged.
 */
@property (nonatomic, readonly) id objectUnderDrag;

/**
 * The view being considered for dropping on.
 */
@property (nonatomic, readonly) id draggingDestination;
//- (NSInteger)draggingSequenceNumber;
//- (void)slideDraggedImageTo:(NSPoint)screenPoint;
//#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
//- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination;
//#endif
@end


/**
 * An informal protocol describing the methods that objects
 * wishing to be drop targets must support.
*/


/*
 * Methods implemented by an object that receives dragged images.  The
 destination view or window is sent these messages during dragging if it
 responds to them.
 */
@interface NSObject(NTIDraggingDestination)
/**
 * Returns YES if this object would like to be considered 
 * as a possible drag destination for the given object.
 */
-(BOOL)wantsDragOperation: (id<NTIDraggingInfo>)sender;

/**
 * If this wants the drag operation, then it will be informed when
 * the object is within its bounds and it should highlight itself. If this
 * message is not respected, default highlighting will occur.
 */
-(void)draggingEntered: (id<NTIDraggingInfo>)sender;

-(void)draggingUpdated: (id<NTIDraggingInfo>)sender;

/**
 * If this wants the drag operation, then it will be informed when
 * the object is leaving its bounds and it should unhighlight itself. If this
 * message is not respected, default highlighting will occur. The prepare
 * methods will not be called if this method is called (until another
 * draggingEntered method is called.)
 */
-(void)draggingExited: (id<NTIDraggingInfo>)sender;


/**
 * Returns YES if this object will want to accept the drag. Will
 * only be invoked if a YES response to a wantsDragOperation
 * has been received.
 */
- (BOOL)prepareForDragOperation: (id<NTIDraggingInfo>)sender;
/**
 * Called after prepareForDragOperation returns YES to actually handle
 * the drag. Returns YES if successful, NO otherwise.
 */
- (BOOL)performDragOperation: (id<NTIDraggingInfo>)sender;
/**
 * Called after prepareForDragOperation (and, if necessary) performDragOperation
 * have been called, for cleanup. draggingExited will not be called.
 */
- (void)concludeDragOperation: (id<NTIDraggingInfo>)sender;
///* draggingEnded: is implemented as of Mac OS 10.5 */
//- (void)draggingEnded:(id <NTIDraggingInfo>)sender;
//#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
///* the receiver of -wantsPeriodicDraggingUpdates should return NO if it does not require periodic -draggingUpdated messages (eg. not autoscrolling or otherwise dependent on draggingUpdated: sent while mouse is stationary) */
//- (BOOL)wantsPeriodicDraggingUpdates;
//#endif
@end


/* Methods implemented by an object that initiates a drag session.  The
 source app is sent these messages during dragging.  The first must be
 implemented, the others are sent if the source responds to them.
 */
@interface NSObject(NTIDraggingSource)
-(NTIDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag;
/**
 * The data to drag, otherwise this object will be used. Note
 * that this must NOT query for the objectUnderDrag from the drag info.
 */
-(id)dragOperation: (id<NTIDraggingInfo>)drag objectForDestination: (id)destination;
//#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
//- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination;
//#endif
//- (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint;
//- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NTIDragOperation)operation;
//- (void)draggedImage:(NSImage *)image movedTo:(NSPoint)screenPoint;
//- (BOOL)ignoreModifierKeysWhileDragging;
@end

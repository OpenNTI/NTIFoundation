//
//  NTIDraggingUtilities.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIDraggingUtilities.h"
#import "OmniUI/OUIDragGestureRecognizer.h"
#import "NTIDraggingProxyView.h"
#import <QuartzCore/QuartzCore.h>

#import "OmniUI/OUIOverlayView.h"

/**
 * Starting at the responder, see if there is some object in the responder chain
 * of that object that will accept a drop from the given object.
 * If so, return it. Otherwise, return nil. This object will respond
 * to prepareForDragOperation.
 */
static id findAcceptableDropTarget( NTIDraggingProxyView* proxy, UIResponder* above );

/**
 * Starting at the responder, see if there is some object in the responder
 * chain that wants to be a drop target. This object responded YES
 * to wantsDragOperation.
 */
static id findPossibleDropTarget( NTIDraggingProxyView* proxy, UIResponder* above );

void trackDragging( UIResponder* self, OUIDragGestureRecognizer* dragger, UIView** draggingProxyView )
{
	UIImage* image;
	CGSize imageSize;
	CGSize origSize;
	if( [self isKindOfClass: [UIImageView class]] ) {
		image = [(id)self image];
		origSize = image.size;
		imageSize = CGSizeMake( 44, 44 );
	}
	else if( [self isKindOfClass: [UITableViewCell class]] ) {
		image = [[(id)self imageView] image];
		imageSize = image.size;
		origSize = imageSize;
	}
	else {
		return;
	}
	NTIDraggingProxyView* ntiDPV = (NTIDraggingProxyView*)*draggingProxyView;
	UIView* source = dragger.view;
	UIWindow* window = ntiDPV.window;
	CGPoint dragLoc = [dragger locationInView: window];
	ntiDPV.currentDragLocation = dragLoc;
	if(		dragger.state == UIGestureRecognizerStateBegan
	   &&	dragger.overcameHysteresis ) {
		*draggingProxyView = [[NTIDraggingProxyView alloc] 
							  initWithImage: image
							  forObject: self];
		ntiDPV = (NTIDraggingProxyView*)*draggingProxyView;
		//Float it over the entire screen
		[source.window addSubview: ntiDPV];
		CGRect frame = source.frame;
		frame.size = imageSize;
		ntiDPV.frame = [[source window] convertRect: frame
										   fromView: source];
		//Use a large shadow area because the user's finger will cover
		//the normal small shadow.
		ntiDPV.layer.shadowOpacity = 0.7;
		ntiDPV.layer.shadowRadius = 20;
		ntiDPV.layer.shadowOffset = CGSizeZero;

		
		//Since we are directly a child of the window, we want to 
		//copy its transform so that interface orientation rotation works
		ntiDPV.transform = source.window.rootViewController.view.transform;
		
		//Make the source look "disabled"
		source.alpha = 0.4;
		//TODO: Highlight possible drop targets.
	}
	else if( dragger.state == UIGestureRecognizerStateChanged ) {
		ntiDPV.center = dragLoc;
		UIView* above = [window hitTest: dragLoc withEvent: nil];
		id wantsDrop = findPossibleDropTarget( ntiDPV, above );
		id oldTarget = ntiDPV.currentDragTarget;
		if(		oldTarget != wantsDrop 
			&&	[wantsDrop respondsToSelector: @selector(draggingEntered:)] ) {
			ntiDPV.currentDragTarget = wantsDrop;
			[wantsDrop draggingEntered: ntiDPV];
		}
		if(		oldTarget != wantsDrop 
		   &&	[oldTarget respondsToSelector: @selector(draggingExited:)] ) {
			ntiDPV.currentDragTarget = oldTarget;
			[oldTarget draggingExited: ntiDPV];
		}
		else if( [wantsDrop respondsToSelector: @selector(draggingUpdated:)] ) {
			ntiDPV.currentDragTarget = wantsDrop;
			[wantsDrop draggingUpdated: ntiDPV];
		}
		ntiDPV.currentDragTarget = wantsDrop;
	}
	else if(	dragger.state == UIGestureRecognizerStateCancelled //TODO
			||	dragger.state == UIGestureRecognizerStateEnded ) {
		UIView* above = [window hitTest: dragLoc withEvent: nil];
		id dropTarget = findAcceptableDropTarget( ntiDPV, above);
		BOOL sendHome = YES;
		if( dropTarget ) {
			//Yea, found one! Will it really take us?
			ntiDPV.currentDragTarget = dropTarget;
			BOOL didDrop = [dropTarget performDragOperation: ntiDPV];
			sendHome = !didDrop;
		}
		id completion = ^(BOOL _){
			[ntiDPV removeFromSuperview];
			[ntiDPV release];
			*draggingProxyView = nil;
		};
		if( sendHome ) {
			//Snap back to where we came from.
			[UIView animateWithDuration: 0.4
						 animations: ^{
							 ntiDPV.center 
							 = [source.window convertPoint: source.center
												  fromView: source];
							 CGRect bounds = ntiDPV.bounds;
							 bounds.size = origSize;
							 ntiDPV.bounds = bounds;
							 source.alpha = 1.0;
							 
						 }
						 completion: completion];
		}
		else {
			//Zoom us into the recipient. Yay us! Also reset the sender.
			[UIView animateWithDuration: 0.4
							 animations: ^{
								 CGRect bounds = ntiDPV.bounds;
								 bounds.size = CGSizeZero;
								 ntiDPV.bounds = bounds;
								 ntiDPV.alpha = 0.0;
								 source.alpha = 1.0;
							 }
							 completion: completion];
		}
	}
}


void enableDragTracking( UIView* view, id target, SEL sel )
{
	OUIDragGestureRecognizer* dragMe = [[OUIDragGestureRecognizer alloc]
										initWithTarget: target
										action: sel];
	[dragMe autorelease];
	dragMe.delaysTouchesBegan = YES;
	dragMe.enabled = YES;
	[view addGestureRecognizer: dragMe];
}

static id findPossibleDropTarget( NTIDraggingProxyView* proxy, UIResponder* above )
{
	id result = nil;
	id toCheck = above;
	while( toCheck != nil ) {
		if(		[toCheck respondsToSelector: @selector(wantsDragOperation:)]
		   &&	[toCheck wantsDragOperation: proxy] ) {
			result = toCheck;
			break;
		}
		toCheck = [toCheck nextResponder];
	}
	
	return result;
}

static id findAcceptableDropTarget( NTIDraggingProxyView* proxy, UIResponder* above )
{
	id result = nil;
	id toCheck = above;
	while( toCheck != nil ) {
		if(		[toCheck respondsToSelector: @selector(wantsDragOperation:)]
			&&	[toCheck wantsDragOperation: proxy] ) {
				if( [toCheck respondsToSelector: @selector(prepareForDragOperation:)] ) {
					if( [toCheck prepareForDragOperation: proxy] ) {
						result = toCheck;
						break;
					}
				}
		}
		toCheck = [toCheck nextResponder];
	}
	
	return result;
}

void NTIDraggingShowTooltipInView( id<NTIDraggingInfo>info, NSString* action, UIView* view )
{	
	if( !action ) {
		return;
	}
		
	CGPoint cellPoint = [view convertPoint: [info draggingLocation] 
								  fromView: view.window];
	[OUIOverlayView displayTemporaryOverlayInView: view
									   withString: action
							   avoidingTouchPoint: cellPoint];
}

void NTIDraggingShowTooltipInViewAboveTouch( id<NTIDraggingInfo>info, NSString* action, UIView* view )
{	
	if( !action ) {
		return;
	}
	
	CGPoint cellPoint = [view convertPoint: [info draggingLocation] 
								  fromView: view.window];
	[OUIOverlayView displayTemporaryOverlayInView: view
									   withString: action
									   centeredAbovePoint: cellPoint
									    displayInterval: 0];
}


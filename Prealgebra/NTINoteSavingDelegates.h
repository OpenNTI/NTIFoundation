//
//  NTINoteSavingDelegates.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/06.
//  Copyright 2011 NextThought. All rights reserved.
//
#import <Foundation/Foundation.h>

@class UIView, UIWindow;
@class NTINote;

@protocol NTINoteSaverDelegateView<NSObject>
@property (nonatomic,readonly) NSString* ntiPageId;

@optional
@property (nonatomic,readonly) UIWindow* window;
//Return the absolute coordinates
-(CGPoint)htmlDocumentPointFromWindowPoint: (CGPoint)p;

@end

@class NTINoteViewControllerManager;
@protocol NTINoteSaver<NSObject>
-(void)saveNote: (NTINote*)note;
-(void)deleteNote: (NTINote*)note;
@end


typedef void(^NTINoteBlock)(NTINote*);


@interface NTINoteSaverDelegate : OFObject
+(id<NTINoteSaver>)saverForNewNote: (id<NTINoteSaverDelegateView>)page;
+(id<NTINoteSaver>)saverForNewNote: (id<NTINoteSaverDelegateView>)page
								onCreated: (NTINoteBlock)callback;
//+(id<NTINoteSaver>)saverForNewNote: (NTINote*)unsaved
//								   inPage: (id<NTINoteSaverDelegateView>)page
//								onCreated: (NTINoteBlock)callback;


+(id<NTINoteSaver>)saverForNote: (NTINote*)note
								inPage: (id<NTINoteSaverDelegateView>)page;
+(id<NTINoteSaver>)saverForNote: (NTINote*)note
								inPage: (id<NTINoteSaverDelegateView>)page
						   onCompleted: (NTINoteBlock)callback;

+(id<NTINoteSaver>)sharedNoOp;
@end




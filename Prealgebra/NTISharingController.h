//
//  NTISharingController.h
//  NextThoughtApp
//
//  Created by Christopher Utz on 8/9/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NTIViewController.h"
#import "NTIUserData.h"
#import "NTISelectedObjectsStackedSubviewViewController.h"
#import "NTIRemoteSearchControllers.h"


@interface NTIThreePaneSharingTargetEditor : NTISelectedObjectsStackedSubviewViewController<UISearchBarDelegate>{
@private
}

-(id)initWithSelectedObjects: (NSArray*)selectedObjects
				 controllers: (NSArray*)headerControllers;

@end

@protocol NTISharingControllerDelegate <NSObject>
-(void)sharingTargetsChanged: (NSArray*)targets;
@end

@interface NTISharingController: NTIThreePaneSharingTargetEditor
@property (nonatomic, retain) id <NTISharingControllerDelegate> delegate;
-(id)initWithSharableObject: (NTIShareableUserData*)sharableObject;
-(id)initWithSharingTargets: (NSArray*)sharingTargets;

-(NSArray*)sharingTargets;

@end

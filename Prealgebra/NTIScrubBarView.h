//
//  NTIScrubBarView.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/18.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NTINavigationItem, WebAndToolController;
@protocol NTIScrubBarViewDelegate
-(void)navigationItemSelected: (NTINavigationItem*)item percent: (CGFloat)f;
@end

@class NTINavigationItem;

@interface NTIScrubBarView : UIView {
	@private
	UIView* accView;
	UILabel* accLabel;
	BOOL ignoreScrollsUntilNextDisplay;
	NTINavigationItem* currentItem;
	volatile BOOL displayForced;
}

@property(nonatomic,retain) id delegate;
@property(nonatomic,retain) IBOutlet WebAndToolController* controller;

-(void)displayItem: (NTINavigationItem*)item;
-(void)scrollSelectedToPercent: (CGFloat)percent maxPercent: (CGFloat)maxPercent;
-(void)setNeedsRedisplay;
@end


@interface NTIScrubBarSectionView: UIView {
@private 
	NSInteger selectedPage;
	CGFloat scrollPercent;
}

+(CGFloat)heightForDotDisplayOfPages: (CGFloat)numPages;

@property(nonatomic,retain) NTINavigationItem* navItem;
@property(nonatomic,assign) BOOL selected;
@property(nonatomic,assign) CGFloat thumbHeight, pageSize, pageCount;
@property(nonatomic,retain) IBOutlet WebAndToolController* controller;

-(void)scrollToPercent: (CGFloat)percent maxPercent: (CGFloat)maxPercent;
@end

@interface NTIScrubBarAccessoryPointerView : UIView

@end


@interface NTIScrubBarAccessoryView : UIView
@end

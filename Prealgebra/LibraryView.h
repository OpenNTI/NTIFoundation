//
//  LibraryView.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/10.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTILabeledGridListView.h"

@class NTINavigationItem;

@interface LibraryView : NTILabeledGridListView {
    
}

@end

@interface LibraryEntryView : UIView {
}

@property(nonatomic,retain) id navData; 
@end

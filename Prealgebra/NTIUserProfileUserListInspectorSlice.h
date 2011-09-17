//
//  NTIUserProfileUserListInspectorPane.h
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/04.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIInspector.h"


@interface NTIUserProfileUserListInspectorSlice : OUIDetailInspectorSlice {
	@private
	NSString* key;
	BOOL editable;
}
-(id)initWithTitle: (NSString*)title key: (NSString*)key;
-(id)initWithTitle: (NSString*)title key: (NSString*)key editable: (BOOL)editable;
@end

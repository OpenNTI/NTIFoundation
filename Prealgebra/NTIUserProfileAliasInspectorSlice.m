//
//  NTIUserProfileAliasInspectorSlice.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/04.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NTIUserProfileAliasInspectorSlice.h"
#import "NTIAppUser.h"
#import "NSArray-NTIExtensions.h"

@interface NTIUserProfileAliasTextWell : OUIInspectorTextWell
@end

@implementation NTIUserProfileAliasTextWell

-(NSString*)willCommitEditingText: (NSString*)editedText
{
	NSString* result = self.text;
	if( ![NSString isEmptyString: editedText] ) {
		result = editedText;
	}
	return result;
}

@end

@implementation NTIUserProfileAliasInspectorSlice

+(Class)textWellClass
{
	return [NTIUserProfileAliasTextWell class];
}

-(id)initWithTitle: (NSString*)title
{
	self = [super initWithTitle: title action: @selector(aliasAction:)];
	return self;
}

-(BOOL)isAppropriateForInspectedObject: (id)o
{
	return [o isKindOfClass: [NTIAppUser class]];
}

-(void)updateInterfaceFromInspectedObjects: (OUIInspectorUpdateReason)reason
{
	NTIAppUser* user = [self.containingPane inspectedObjects].firstObject;

	self.textWell.text = user.alias;
}

-(void)aliasAction: (OUIInspectorTextWell*)s
{
	NTIAppUser* user = [self.containingPane inspectedObjects].firstObject;
	if( OFNOTEQUAL( s.text, user.alias ) ) {
		user.alias = s.text;
	}
}

@end

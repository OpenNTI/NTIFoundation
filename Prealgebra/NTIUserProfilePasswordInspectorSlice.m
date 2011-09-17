//
//  NTIUserProfilePasswordInspectorSlice.m
//  NextThoughtApp
//
//  Created by Jason Madden on 2011/09/04.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import "NSArray-NTIExtensions.h"

#import "NTIUserProfilePasswordInspectorSlice.h"
#import "NTIAppUser.h"

@interface NTIUserPasswordAliasTextWell : OUIInspectorTextWell
@end

@implementation NTIUserPasswordAliasTextWell

-(NSString*)willCommitEditingText: (NSString*)editedText
{
	NSString* result = self.text;
	if( ![NSString isEmptyString: editedText] ) {
		result = editedText;
	}
	return result;
}

@end


@implementation NTIUserProfilePasswordInspectorSlice

+(Class)textWellClass
{
	return [NTIUserPasswordAliasTextWell class];
}

-(id)initWithTitle: (NSString*)title
{
	self = [super initWithTitle: title action: @selector(passwordAction:)];
	return self;
}

-(BOOL)isAppropriateForInspectedObject: (id)o
{
	return [o isKindOfClass: [NTIAppUser class]];
}

-(void)updateInterfaceFromInspectedObjects: (OUIInspectorUpdateReason)reason
{
	NTIAppUser* user = [self.containingPane inspectedObjects].firstObject;
	self.textWell.text = user.password;
	OBASSERT( user );
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.textWell.keyboardType = UIKeyboardTypeASCIICapable;
	self.textWell.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.textWell.autocorrectionType = UITextAutocorrectionTypeNo;
	//TODO: When typing the password, we need to show placeholder characters.
	//I think we can do this with a custom cell (by implementing the class method)
	//and overriding the delegate method "contents did change".
	self.textWell.placeholderText = @"********";
}

-(void)passwordAction: (OUIInspectorTextWell*)s
{
	NTIAppUser* user = [self.containingPane inspectedObjects].firstObject;
	if( OFNOTEQUAL( s.text, user.password ) ) {
		user.alias = s.text;
	}
}

@end

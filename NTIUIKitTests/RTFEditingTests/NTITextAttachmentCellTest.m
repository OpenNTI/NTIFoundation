//
//  NTITextAttachmentCellTest.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTITextAttachmentCellTest.h"
#import "NTITextAttachmentCell.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@interface NTITextAttachmentCell(PRIVATE_TEST)
-(NSSet*)editableFrames;
@end

@implementation NTITextAttachmentCellTest

-(void)testEqualityAndHashIsOk
{
	NTITextAttachmentCell* cell = [[NTITextAttachmentCell alloc] init];
	
	id frame1 = [[OFObject alloc] init];
	
	[cell attachEditableFrame: frame1];
	
	NSSet* editableFrames = [cell editableFrames];
	
	assertThat(@(editableFrames.count), equalTo(@(1)));
	assertThat([editableFrames anyObject], equalTo(frame1));
	
	//Adding the same one does nothing
	
	[cell attachEditableFrame: frame1];
	editableFrames = [cell editableFrames];
	assertThat(@(editableFrames.count), equalTo(@(1)));
	
	//We can add another
	id frame2 = [[OFObject alloc] init];
	
	[cell attachEditableFrame: frame2];
	editableFrames = [cell editableFrames];
	assertThat(@(editableFrames.count), equalTo(@(2)));
	
	[cell removeEditableFrame: frame1];
	[cell removeEditableFrame: frame2];
	
	editableFrames = [cell editableFrames];
	assertThat(@(editableFrames.count), equalTo(@(0)));
	
}


-(void)testWeakReferencesGetRemoved
{
	NTITextAttachmentCell* cell = [[NTITextAttachmentCell alloc] init];
	
	@autoreleasepool {
		id frame1 = [[OFObject alloc] init];
		[cell attachEditableFrame: frame1];
	}
	
	NSSet* editableFrames = [cell editableFrames];
	
	assertThat(@(editableFrames.count), equalTo(@(0)));
	
}

@end

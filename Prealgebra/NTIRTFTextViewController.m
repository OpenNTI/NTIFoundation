//Originally bosed on code by:
// Copyright 2010-2011 The Omni Group.	All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NTIRTFTextViewController.h"

#import <OmniUI/OUIEditableFrame.h>
#import <OmniUI/OUIAppController.h>

#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <OmniFoundation/OFFileWrapper.h>
#import <OmniAppKit/OATextAttachment.h>
#import <OmniAppKit/OATextStorage.h>
#import <OmniAppKit/OATextAttributes.h>

#import "NTIRTFDocument.h"
#import "NTIEditableFrame.h"
#import "NTIImageAttachmentCell.h"

#import "NTIUtilities.h"
#import "NTIDraggingUtilities.h"

@interface NTIRTFTextViewController () <UINavigationControllerDelegate>
-(UITextRange*)addAttachmentFromImage: (UIImage*)image
								 size: (CGSize)size
								   at: (CGPoint)point;
@end

@implementation NTIRTFTextViewController

@synthesize editor, document;

-(id)initWithDocument: (NTIRTFDocument*)theDocument
{
	self = [super initWithNibName: @"TextViewController" bundle: nil];
	self->document = [theDocument retain];
	return self;
}

-(void)dealloc;
{
	NTI_RELEASE( self->document );
	NTI_RELEASE( editor );
	NTI_RELEASE( undoManager );
	[super dealloc];
}

#pragma mark -
#pragma mark UIResponder subclass

-(NSUndoManager*)undoManager;
{
	if( !self->undoManager ) {
		self->undoManager = [[NSUndoManager alloc] init];
	}
	return self->undoManager;
}

#pragma mark -
#pragma mark UIViewController subclass

- (void)viewDidLoad;
{
	[super viewDidLoad];

#if 0
	self.view.layer.borderColor = [[UIColor blueColor] CGColor];
	self.view.layer.borderWidth = 2;

	self->editor.layer.borderColor = [[UIColor colorWithRed:0.33 green:1.0 blue:0.33 alpha:1.0] CGColor];
	self->editor.layer.borderWidth = 4;
#endif

	self->editor.textInset = UIEdgeInsetsMake(4, 4, 4, 4);
	self->editor.delegate = self;

	self->editor.attributedText = self->document.text;
	[self textViewContentsChanged: self->editor];

	[self adjustScaleTo: 1];
	[self adjustContentInset];
}

- (void)viewDidUnload;
{
	self.editor = nil;
	[super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
{
	[super shouldAutorotateToInterfaceOrientation: toInterfaceOrientation];
	return YES;	
}

#pragma mark OUIEditableFrameDelegate

static CGFloat kPageWidth = (72*8.5); // Vaguely something like 8.5x11 width.

-(void)textViewContentsChanged: (OUIEditableFrame*)textView;
{
	CGFloat usedHeight = self->editor.viewUsedSize.height;
	self->editor.frame = CGRectMake(0, 0, self->editor.frame.size.width, usedHeight);
}

-(void)textViewDidEndEditing: (OUIEditableFrame*)textView;
{
	//We need more of a text storage model so that selection changes can
	//participate in undo.
	self->document.text = textView.attributedText;
}

-(void)documentContentsDidChange
{
	self->editor.attributedText = self->document.text;	
}

#pragma mark -
#pragma mark OUIScalingViewController subclass

-(CGSize)canvasSize;
{
	if( !self->editor) {
		return CGSizeZero;
		// Don't know our canvas size yet. 
		//We'll set up initial scaling in -viewDidLoad.
	}

	CGSize size;
	size.width = kPageWidth;
	size.height = self->editor.textUsedSize.height;

	return size;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

-(UIView*)viewForZoomingInScrollView: (UIScrollView*)scrollView;
{
	return self->editor;
}

#pragma mark -
#pragma mark Drop Target
-(BOOL)wantsDragOperation: (id<NTIDraggingInfo>)info
{
	return [[info objectUnderDrag] isKindOfClass: [NSURL class]];
}

-(BOOL)prepareForDragOperation: (id<NTIDraggingInfo>)info
{
	return [self wantsDragOperation: info];	
}

//TODO: Make drag tracking prettier

-(void)draggingEntered: (id<NTIDraggingInfo>)info
{
	self->editor.backgroundColor = [UIColor lightGrayColor];
	self->selectedBeforeDrag = [[self->editor selectedTextRange] retain];
}

-(void)draggingUpdated: (id<NTIDraggingInfo>)info
{
	CGPoint point = [self->editor.window convertPoint: [info draggingLocation]
											   toView: self->editor];
	UITextPosition*  closest = [self->editor closestPositionToPoint: point];
	//A zero size range moves the cursor
	self->editor.selectedTextRange = [self->editor textRangeFromPosition: closest
															  toPosition: closest];
}

-(void)draggingExited: (id<NTIDraggingInfo>)info
{
	self->editor.backgroundColor = [UIColor clearColor];
	if( self->selectedBeforeDrag ) {
		self->editor.selectedTextRange = self->selectedBeforeDrag;	
	}
	NTI_RELEASE(self->selectedBeforeDrag);
}


-(BOOL)performDragOperation: (id<NTIDraggingInfo>)info
{
	NTI_RELEASE(self->selectedBeforeDrag);
	[self draggingExited: info];
	[self->editor becomeFirstResponder];
	UIImage* image = [info draggedImage];
	CGSize size = image.size;
	if( image.size.width > 44 || image.size.height > 44 ) {
		image = [[image copy] autorelease];
		CGFloat scale = 44 / image.size.height;
		
		size = CGSizeMake( image.size.width * scale, image.size.height * scale );
	}
	//Make our image also a link.
	UITextRange* selectedTextRange = [self addAttachmentFromImage: image
															 size: size
															   at: 
									  [self->editor.window convertPoint: [info draggingLocation]
																 toView: self->editor]];

	NSString* urlString = [[info objectUnderDrag] absoluteString];
	
	//TODO: We actually want an internal URL. Also, 
	//we need to provide storage for this. On the mac, the NSLink
	//attribute is used for this, and links are written to RTF as "fields"
	//Likewise for images.
	[self->editor setValue: urlString 
			  forAttribute: OALinkAttributeName
				   inRange: selectedTextRange];

	//We don't call this, this is called by external parties.
	//[self documentContentsDidChange];
	return YES;
}

-(UITextRange*)addAttachmentFromImage: (UIImage*)image
								 size: (CGSize)size
								   at: (CGPoint)point
{

	//a real implementation would really check that the 
	//UTI inherits from public.image here (we could get movies any
	//maybe PDFs in the future) and would provide an appropriate cell
	//class for the type (or punt and not create an attachment).
	OATextAttachment* attachment = [[[OATextAttachment alloc]
									 initWithFileWrapper: nil] autorelease];
	NTIImageAttachmentCell* cell = [[NTIImageAttachmentCell alloc]
									initWithImage: image
									size: size ];
	attachment.attachmentCell = cell;
	OBASSERT(cell.attachment == attachment); // sets the backpointer
	[cell release];

	//We drop it where the user put it. 
	//TODO: If that was within selected text, replace the selection?
	UITextPosition*  closest = [self->editor closestPositionToPoint: point];
	UITextRange* selectedTextRange = [self->editor textRangeFromPosition: closest
															  toPosition: closest];
	//hold onto this since the edit will drop the -selectedTextRange
	UITextPosition* startPosition = [[[selectedTextRange start] copy] autorelease]; 

	// TODO: Clone attributes of the beginning of the selected range?
	unichar attachmentCharacter = OAAttachmentCharacter;
	[self->editor replaceRange: selectedTextRange
					  withText: [NSString stringWithCharacters: &attachmentCharacter
														length: 1]];

	//This will have changed the selection
	UITextPosition* endPosition = [self->editor positionFromPosition: startPosition
															  offset: 1];
	selectedTextRange = [self->editor textRangeFromPosition: startPosition
												 toPosition: endPosition];

	[self->editor setValue: attachment 
			  forAttribute: OAAttachmentAttributeName
				   inRange: selectedTextRange];
	return selectedTextRange;
}


@end

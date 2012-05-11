//
//  NTIHTMLReader.h
//  NTIFoundation
//
//  Created by Christopher Utz on 10/7/11.
//  Copyright 2011 NextThought. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>


@interface NTIHTMLReader : OFObject<NSXMLParserDelegate> {
@private
	NSMutableAttributedString* attrBuffer;
	NSMutableArray* nsattrStack;
	//Assuming only one link, as per writer
	NSString* currentHref;
	NSString* currentAudioURL;
	BOOL parsingAudio;
	CGImageRef currentImage;
	BOOL inError;
	BOOL unparsableFormat;
}
@property(nonatomic, readonly) NSAttributedString* attributedString;

+(void)registerReaderClass: (Class)clazz;
+(Class)readerClass;

-(id)initWithHTML: (NSString*)string;

//For subclasses
-(void)handleAnchorTag: (NSMutableAttributedString*)attrBuffer
		   currentHref: (NSString*)currentHref 
		  currentImage: (CGImageRef) currentImage;

-(void)handleAudioTag: (NSMutableAttributedString*)attrBuffer
		 currentAudio: (NSString*)currentAudio ;
@end




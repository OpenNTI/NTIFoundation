
/**
 * Capable of dealing with the subset of HTML produced by our 
 * corresponding writer.
 */
#import <QuartzCore/QuartzCore.h>

@interface NSAttributedString(HTMLReadingExtensions)
+ (NSAttributedString*)stringFromHTML: (NSString*)htmlString;
@end

@interface NTIHTMLReader : OFObject<NSXMLParserDelegate> {
@private
	NSMutableAttributedString* attrBuffer;
	NSMutableArray* nsattrStack;
	//Assuming only one link, as per writer
	NSString* currentHref;
	CGImageRef currentImage;
	BOOL inError;
}
@property(nonatomic, readonly) NSAttributedString* attributedString;

+(void)registerReaderClass: (Class)clazz;

//For subclasses
-(void)handleAnchorTag: (NSMutableAttributedString*)attrBuffer
		   currentHref: (NSString*)currentHref 
		  currentImage: (CGImageRef) currentImage;
@end

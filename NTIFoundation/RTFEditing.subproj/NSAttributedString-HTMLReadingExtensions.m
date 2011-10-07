
#import "NSAttributedString-HTMLReadingExtensions.h"
#import "NTIHTMLReader.h"

@implementation NSAttributedString(HTMLReadingExtensions)
+ (NSAttributedString*)stringFromHTML: (NSString*)htmlString
{
	NTIHTMLReader* r = [[[NTIHTMLReader readerClass] alloc] initWithHTML: htmlString];	
	NSAttributedString* result = r.attributedString;
	[r release];
	return result;
}
@end


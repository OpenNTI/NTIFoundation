
/**
 * Capable of dealing with the subset of HTML produced by our 
 * corresponding writer.
 */
@interface NSAttributedString(HTMLReadingExtensions)
+ (NSAttributedString*)stringFromHTML: (NSString*)htmlString;
@end

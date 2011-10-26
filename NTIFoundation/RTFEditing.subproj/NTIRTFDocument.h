//Initially based on code copyright 2010 by the omni group. 

#import <OmniFoundation/OmniFoundation.h>

@interface NTIRTFDocument : OFObject
{
@private
    NSMutableAttributedString* text;
}

@property (nonatomic,copy) NSAttributedString* text;
@property (weak, nonatomic,readonly) NSString* rtfString;
@property (weak, nonatomic,readonly) NSString* htmlString;
@property (weak, nonatomic,readonly) NSString* plainString;
/**
 * The preferred string for external storage. 
 */
@property (weak, nonatomic,readonly) NSString* externalString;

/**
 * Parses HTML, RTF, or plain text.
 */
+(NSAttributedString*)attributedStringWithString: (NSString*)rtfString;
+(NSString*)stringFromString: (NSString*)rtfOrPlain;

-(id)initWithString: (NSString*)string;
/**
 * Designated initializer.
 */
-(id)initWithAttributedString: (NSAttributedString*)string;

-(NSString*)htmlStringWrappedIn: (NSString*)element;

@end

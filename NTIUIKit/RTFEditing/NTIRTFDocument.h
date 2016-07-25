//Initially based on code copyright 2010 by the omni group. 

#import <Foundation/Foundation.h>

@interface NTIRTFDocument : NSObject
{
@private
    
    NSMutableAttributedString *text;
}

@property (nonatomic, copy) NSAttributedString *text;

@property (nonatomic, readonly) NSString *rtfString __attribute__((deprecated));

@property (nonatomic, readonly) NSString *htmlString;

@property (nonatomic, readonly) NSString *plainString;

/**
 * The preferred string for external storage. 
 */
@property (nonatomic, readonly) NSString* externalString;

/**
 * Parses HTML, RTF, or plain text.
 */
+ (NSAttributedString *)attributedStringWithString:(NSString *)rtfString;

+ (NSString *)stringFromString:(NSString *)rtfOrPlain;

- (id)initWithString:(NSString *)string;

/**
 * Designated initializer.
 */
- (id)initWithAttributedString:(NSAttributedString *)string;

- (NSString *)htmlStringWrappedIn:(NSString *)element;

@end

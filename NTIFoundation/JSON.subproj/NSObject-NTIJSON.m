#import "NSObject-NTIJSON.h"

@implementation NSObject(NTIJSON)


-(NSString*)stringWithJsonRepresentation
{
	NSData* jsonData = [self dataWithJsonRepresentation];
	return [NSString stringWithData: jsonData encoding: NSUTF8StringEncoding];
}

-(NSData *)dataWithJsonRepresentation
{
	if(![NSJSONSerialization isValidJSONObject: self]){
		return nil;
	}
	
	NSError* error=nil;
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject: self
													   options: 0
														 error: &error];
	
	if(!jsonData && error){
		NSLog(@"An error occurred when serializing %@. %@", self, error);
		return nil;
	}
	return  jsonData;
}

-(id)jsonObjectUnwrap
{
	return [self isNull] ? nil : self;	
}

@end
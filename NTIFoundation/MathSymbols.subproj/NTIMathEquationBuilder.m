//
//  NTIMathEquationBuilder.m
//  NTIMathAccessory
//
//  Created by  on 4/25/12.
//  Copyright (c) 2012 Apple Inc. All rights reserved.
//

#import "NTIMathEquationBuilder.h"
#import "NTIMathAlphaNumericSymbol.h"
#import "NTIMathInputExpressionModel.h"

@implementation NTIMathEquationBuilder
@synthesize mathModel;

+(NTIMathInputExpressionModel*)modelFromString: (NSString*)string
{
	NTIMathInputExpressionModel* model = [[NTIMathInputExpressionModel alloc] initWithMathSymbol: nil];
	NTIMathEquationBuilder* builder = [[NTIMathEquationBuilder alloc] initWithMathModel: model];
	[builder buildModelFromEquationString: string];
	return model;
}

-(id)initWithMathModel: (NTIMathInputExpressionModel *)aModel
{
	self = [super init];
	if (self) {
		self.mathModel = aModel;
	}
	return self;
}

-(void)buildModelFromEquationString: (NSString *)stringValue
{
	if(!stringValue){
		return;
	}
	
	// could be one string with one char or even more. 
	for (NSUInteger i= 0; i<stringValue.length; i++) {
		NSString* symbolString = [stringValue substringWithRange: NSMakeRange(i, 1)];
		//Add the mathSymbol to the equation
		[self.mathModel addMathSymbolForString: symbolString fromSenderType: kNTIMathTextfieldInput];
	}
	
	if( ![[self.mathModel generateEquationString] isEqualToString: stringValue] ){
		NSLog(@"WARN Unable to build consistent model for %@.  Falling back to literal", stringValue);
		[self clearModelEquation];
		NTIMathAlphaNumericSymbol* literal = [[NTIMathAlphaNumericSymbol alloc] initWithValue: stringValue];
		[self.mathModel addMathExpression: literal senderType: kNTIMathTextfieldInput];
		
		//If we can't even roundtrip it as a literal we are in trouble
		OBASSERT([[self.mathModel generateEquationString] isEqualToString: stringValue]);
	}
}

-(NSString *)equationString
{
	return [self.mathModel generateEquationString];
}

-(void)clearModelEquation
{
	if ([self.mathModel respondsToSelector:@selector(clearEquation)]) {
		[self.mathModel performSelector:@selector(clearEquation)];
	}
}

@end

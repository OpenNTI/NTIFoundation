//
//  NTIMathEquationBuilder.m
//  NTIMathAccessory
//
//  Created by  on 4/25/12.
//  Copyright (c) 2012 Apple Inc. All rights reserved.
//

#import "NTIMathEquationBuilder.h"
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
	// could be one string with one char or even more. 
	for (NSUInteger i= 0; i<stringValue.length; i++) {
		NSString* symbolString = [stringValue substringWithRange: NSMakeRange(i, 1)];
		//Add the mathSymbol to the equation
		[self.mathModel addMathSymbolForString: symbolString fromSenderType: kNTIMathTextfieldInput];
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

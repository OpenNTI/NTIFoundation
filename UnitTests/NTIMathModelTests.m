//
//  NTIToStringTest.m
//  NTIFoundation
//
//  Created by Logan Testi on 5/21/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathModelTests.h"
#import "NTIMathInputExpressionModel.h"
#import "NTIMathSymbol.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@implementation NTIMathModelTests

-(void)setUp
{
	self->mathModel = [[NTIMathInputExpressionModel alloc] initWithMathSymbol: nil];
}

// -------------builder method---------------

-(void)buildEquationFromString: (NSString *)equationString
{
	for (NSUInteger i= 0; i<equationString.length; i++) {
		NSString* symbolString = [equationString substringWithRange: NSMakeRange(i, 1)];
		
		//Add the mathSymbol to the equation
		[self->mathModel addMathSymbolForString: symbolString];
	}
}

// -------------checker methods---------------

#define mathmodel_assertThatOutputIsInput(str) \
			[self buildEquationFromString: str]; \
			assertThat([[self->mathModel fullEquation] toString], is(str));

-(void)toLatexChecker: (NSString*) userInput: (NSString*) expectedOutPut
{
	[self buildEquationFromString: userInput];
	assertThat([[self->mathModel fullEquation] latexValue], is(expectedOutPut));
}

// -----------data retention test------------

// tests if the model will store data
-(void)testModelDataStorage
{
	NSString* latexToString = @"0";
	[self buildEquationFromString: latexToString];
	assertThat([self->mathModel fullEquation], isNot(nil));
}

// ---------------string tests----------------

// tests if we can get a string from the model
-(void)testModelBasicToString
{
	mathmodel_assertThatOutputIsInput(@"55")
}

// tests if the model will return symbols as string correctly
-(void)testModelSymbolToString
{
	mathmodel_assertThatOutputIsInput(@"4+5-6*7^8");
}

// tests if the model stores parentheses as string correctly
-(void)testModelParenthesesToString
{
	mathmodel_assertThatOutputIsInput(@"(4+5)");
}

// tests if the model will return square roots as string correctly
-(void)testModelSurdToString
{
	mathmodel_assertThatOutputIsInput(@"4√3");
}

// tests if the model will return decimals as string correctly
-(void)testModelDecimalToString
{
	mathmodel_assertThatOutputIsInput(@"20.5");
}

// tests if the model will return fractions as string correctly
-(void)testModelFractionToString
{
	mathmodel_assertThatOutputIsInput(@"3/4");
}

// tests if the model will return negative numbers as string correctly
-(void)testModelNegativeToString
{
	mathmodel_assertThatOutputIsInput(@"-1");
}

// tests if the model will return a pi value as a string correctly
-(void)testModelPiToString
{
	mathmodel_assertThatOutputIsInput(@"π");
}

// tests if the model will return a Scientific Notation value as a string correctly
-(void)testModelScientificNotationToString
{
	mathmodel_assertThatOutputIsInput(@"2.16 × 10^5");
}

// tests if the model will return a graph point value as a string correctly
-(void)testModelGraphPointToString
{
	mathmodel_assertThatOutputIsInput(@"(0.5, 0.5)");
}

// tests if the model will return a string value as a string correctly
-(void)testModelStringToString
{
	mathmodel_assertThatOutputIsInput(@"triangle");
}

// -----------------latex tests-----------------------

// tests if we can get the latex value from the model
-(void)testModelBasicLatexValue
{
	[self toLatexChecker: @"45": @"45"];
}

// tests if the model will return symbols with the latex value correctly
-(void)testModelSymbolLatexValue
{
	[self toLatexChecker: @"4+5-6*7^8": @"4+5-6*7^8"];
}

// tests if the model stores parentheses with the latex value correctly
-(void)testModelParenthesesLatexValue
{
	[self toLatexChecker: @"(4+5)": @"(4+5)"];
}

// tests if the model will return square roots with the latex value correctly
-(void)testModelSurdLatexValue
{
	[self toLatexChecker: @"4√3": @"4\\surd{3}"];
}

// tests if the model will return decimals with the latex value correctly
-(void)testModelDecimalLatexValue
{
	[self toLatexChecker: @"20.5": @"20.5"];
}

// tests if the model will return fractions with the latex value correctly
-(void)testModelFractionLatexValue
{
	[self toLatexChecker: @"3/4": @"3\\frac{4}{}"];
}

// tests if the model will return negative numbers with the latex value correctly
-(void)testModelNegativeLatexValue
{
	[self toLatexChecker: @"-1": @"-1"];
}

// tests if the model will return a pi value with the latex value correctly
-(void)testModelPiLatexValue
{
	[self toLatexChecker: @"π": @"\\pi"];
}

// tests if the model will return a Scientific Notation value with the latex value correctly
-(void)testModelScientificNotationLatexValue
{
	[self toLatexChecker:  @"2.16 × 10^5": @"2.16 × 10^5"]; //not the same value as if typed in
}

// tests if the model will return a graph point value with the latex value correctly
-(void)testModelGraphPointLatexValue
{
	[self toLatexChecker: @"(0.5, 0.5)": @"(0.5, 0.5)"];
}

// tests if the model will return a string value with the latex value correctly
-(void)testModelStringLatexValue
{
	[self toLatexChecker: @"triangle": @"triangle"];
}

@end

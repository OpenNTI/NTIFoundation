//
//  NTIMathSymbolsExternalizationTests.m
//  NTIFoundation
//
//  Created by  on 4/29/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathSymbolsExternalizationTests.h"
#import "NTIMathInputExpressionModel.h"
#import "NTIMathSymbol.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@implementation NTIMathSymbolsExternalizationTests
-(void)setUp
{
	self->mathModel = [[NTIMathInputExpressionModel alloc] initWithMathSymbol: nil];
}

//mainly for testing purposes, not used anywhere else, now
-(void)buildEquationFromString: (NSString *)equationString
{
	for (NSUInteger i= 0; i<equationString.length; i++) {
		NSString* symbolString = [equationString substringWithRange: NSMakeRange(i, 1)];
			
		//Add the mathSymbol to the equation
		[self->mathModel addMathSymbolForString: symbolString fromSenderType: kNTIMathTextfieldInput];
	}
}

- (void)testSimpleEquation
{
	NSString* eq = [NSString stringWithFormat:@"4+5"];
	[self buildEquationFromString: eq];
	STAssertNotNil([self->mathModel fullEquation], @"It should contain a valid eq");
	STAssertTrue([[[self->mathModel fullEquation] toString] isEqualToString: eq], @"Equations string should be similar");
	STAssertTrue([[[self->mathModel fullEquation] latexValue]isEqualToString: @"4+5"], @"Equations laTex should be similar");
}

-(void)testSimplePrecedenceLogic
{
	NSString* eq = [NSString stringWithFormat:@"4+5*6"];
	[self buildEquationFromString:eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	STAssertTrue([[eqMath toString] isEqualToString: eq], @"Equations string should be equal");
	STAssertTrue([[[self->mathModel fullEquation] latexValue]isEqualToString: eq], @"Equations laTex should be similar");
}

-(void)testSimpleParanthesisEquation
{
	NSString* eq = [NSString stringWithFormat:@"(4+8)*2"];
	[self buildEquationFromString:eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	STAssertTrue([[eqMath toString] isEqualToString: eq], @"Equations string should be similar");
	STAssertTrue([[eqMath latexValue] isEqualToString: @"(4+8)*2"], @"Equations laTex should be similar");
}

-(void)testFractionEquation
{
	NSString* eq = [NSString stringWithFormat:@"4*((1-5)/(3+2))"];
	[self buildEquationFromString:eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	assertThat([eqMath toString], is(eq));
	assertThat([eqMath latexValue], is(@"4*(\\frac{(1-5)}{(3+2)})"));
}

-(void)testSquareRootEquation
{
	NSString* eq = [NSString stringWithFormat:@"4+√(2+7)"];
	[self buildEquationFromString:eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	assertThat([eqMath toString], is(eq));
	assertThat([eqMath latexValue], is(@"4+\\surd(2+7)"));
}

-(void)testImplicitMultiplication
{
	NSString* eq = [NSString stringWithFormat:@"4√3"];
	[self buildEquationFromString: eq];
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	assertThat([eqMath toString], is(eq));
	assertThat([eqMath latexValue], is( @"4\\surd3"));
}

//More tests cases: 
//For testing, we pass an arbitrary string
//succeeds: 1-5*4/2, 4+(1-5), (4+8)*2, 4*((1-5)/(3+2)), √(2+7)+2
//Fails: 4*√(2+7)-3, 2*√(2+7)
@end

#undef HC_SHORTHAND
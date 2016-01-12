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
#import "NTIMathEquationBuilder.h"

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@implementation NTIMathSymbolsExternalizationTests
-(void)setUp
{
	self->mathModel = [[NTIMathInputExpressionModel alloc] initWithMathSymbol: nil];
}

- (void)testSimpleEquation
{
	
	NSString* eq = [NSString stringWithFormat:@"4+5"];
	self->mathModel = [NTIMathEquationBuilder modelFromString: eq];
	XCTAssertNotNil([self->mathModel fullEquation], @"It should contain a valid eq");
	XCTAssertTrue([[[self->mathModel fullEquation] toString] isEqualToString: eq], @"Equations string should be similar");
	XCTAssertTrue([[[self->mathModel fullEquation] latexValue]isEqualToString: @"4+5"], @"Equations laTex should be similar");
}

-(void)testSimplePrecedenceLogic
{
	NSString* eq = [NSString stringWithFormat:@"4+5*6"];
	self->mathModel = [NTIMathEquationBuilder modelFromString: eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	XCTAssertTrue([[eqMath toString] isEqualToString: eq], @"Equations string should be equal");
	XCTAssertTrue([[[self->mathModel fullEquation] latexValue]isEqualToString: eq], @"Equations laTex should be similar");
}

-(void)testSimpleParanthesisEquation
{
	NSString* eq = [NSString stringWithFormat:@"(4+8)*2"];
	self->mathModel = [NTIMathEquationBuilder modelFromString: eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	XCTAssertTrue([[eqMath toString] isEqualToString: eq], @"Equations string should be similar");
	XCTAssertTrue([[eqMath latexValue] isEqualToString: @"(4+8)*2"], @"Equations laTex should be similar");
}

-(void)testFractionEquation
{
	NSString* eq = [NSString stringWithFormat:@"4*((1-5)/(3+2))"];
	self->mathModel = [NTIMathEquationBuilder modelFromString: eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	assertThat([eqMath toString], is(eq));
	assertThat([eqMath latexValue], is(@"4*(\\frac{(1-5)}{(3+2)})"));
}

-(void)testSquareRootEquation
{
	NSString* eq = [NSString stringWithFormat:@"4+√(2+7)"];
	self->mathModel = [NTIMathEquationBuilder modelFromString: eq];
	
	NTIMathSymbol* eqMath = [self->mathModel fullEquation];
	assertThat([eqMath toString], is(eq));
	assertThat([eqMath latexValue], is(@"4+\\surd(2+7)"));
}

-(void)testImplicitMultiplication
{
	NSString* eq = [NSString stringWithFormat:@"4√3"];
	self->mathModel = [NTIMathEquationBuilder modelFromString: eq];
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

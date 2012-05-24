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
#import "NTIMathEquationBuilder.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@interface NTIMathInputExpressionModel(NTIMathInputExpressionTest)
-(NTIMathSymbol *)findRootOfMathNode: (NTIMathSymbol *)mathSymbol;
-(NTIMathSymbol *)removeMathExpression: (NTIMathSymbol *)mathNode;
-(NSString *)tolaTex;
@end

@implementation NTIMathModelTests

-(void)setUp
{
	self->baseModel = [[NTIMathInputExpressionModel alloc] initWithMathSymbol: nil];
	self->mathModel = [[NTIMathInputExpressionModel alloc] initWithMathSymbol: nil];
}

// -------------checker methods---------------

#define mathmodel_assertThatOutputIsInput(str) \
			self->mathModel = [NTIMathEquationBuilder modelFromString: str]; \
			assertThat([self->mathModel generateEquationString], is(str));

#define mathModel_assertThatIsValidLatex(userInput, expectedOutPut) \
	self->mathModel = [NTIMathEquationBuilder modelFromString: userInput]; \
	assertThat([self->mathModel tolaTex], is(expectedOutPut));

// -----------data retention test------------

// tests if the model will store data
-(void)testModelDataStorage
{
	NSString* latexToString = @"0";
	self->mathModel = [NTIMathEquationBuilder modelFromString: latexToString];
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

-(void)testMixedNumber
{
	mathmodel_assertThatOutputIsInput(@"1 1/2");
}

-(void)testColon
{
	mathmodel_assertThatOutputIsInput(@"3:45");
}

-(void)testComma
{
	mathmodel_assertThatOutputIsInput(@"B2, E5");
}

-(void)testUnaryApprox
{
	mathmodel_assertThatOutputIsInput(@"≈6.2");
}

-(void)testApprox
{
	mathmodel_assertThatOutputIsInput(@"x ≈ 6.2");
}

-(void)testEquals
{
	mathmodel_assertThatOutputIsInput(@"x = 6.2");
}

-(void)testHandlesJunkValue
{
	mathmodel_assertThatOutputIsInput(@"x--6+/*3#-");
}

// -----------------latex tests-----------------------

// tests if we can get the latex value from the model
-(void)testModelBasicLatexValue
{
	mathModel_assertThatIsValidLatex(@"45", @"45");
}

// tests if the model will return symbols with the latex value correctly
-(void)testModelSymbolLatexValue
{
	mathModel_assertThatIsValidLatex(@"4+5-6*7^8", @"4+5-6*7^8");
}

// tests if the model stores parentheses with the latex value correctly
-(void)testModelParenthesesLatexValue
{
	mathModel_assertThatIsValidLatex(@"(4+5)", @"(4+5)");
}

// tests if the model will return square roots with the latex value correctly
-(void)testModelSurdLatexValue
{
	mathModel_assertThatIsValidLatex(@"4√3", @"4\\surd3");
}

// tests if the model will return decimals with the latex value correctly
-(void)testModelDecimalLatexValue
{
	mathModel_assertThatIsValidLatex(@"20.5", @"20.5");
}

// tests if the model will return fractions with the latex value correctly
-(void)testModelFractionLatexValue
{
	mathModel_assertThatIsValidLatex(@"3/4", @"\\frac{3}{4}");
}

// tests if the model will return negative numbers with the latex value correctly
-(void)testModelNegativeLatexValue
{
	mathModel_assertThatIsValidLatex(@"-1", @"-1");
}

// tests if the model will return a pi value with the latex value correctly
-(void)testModelPiLatexValue
{
	mathModel_assertThatIsValidLatex(@"π", @"\\pi");
}

// tests if the model will return a Scientific Notation value with the latex value correctly
-(void)testModelScientificNotationLatexValue
{
	mathModel_assertThatIsValidLatex(@"2.16 × 10^5", @"2.16 × 10^5"); //not the same value as if typed in
}

// tests if the model will return a graph point value with the latex value correctly
-(void)testModelGraphPointLatexValue
{
	mathModel_assertThatIsValidLatex(@"(0.5, 0.5)", @"(0.5, 0.5)");
}

// tests if the model will return a string value with the latex value correctly
-(void)testModelStringLatexValue
{
	mathModel_assertThatIsValidLatex(@"triangle", @"triangle");
}

-(void)testMixedNumberLatexValue
{
	mathModel_assertThatIsValidLatex(@"1 1/2", @"1\\frac{1}{2}");
}

-(void)testColonLatexValue
{
	mathModel_assertThatIsValidLatex(@"3:45", @"3:45");
}

-(void)testCommaLatexValue
{
	mathModel_assertThatIsValidLatex(@"B2, E5", @"B2, E5");
}

-(void)testApproxLatexValue
{
	mathModel_assertThatIsValidLatex(@"x ≈ 6.2", @"x \\approx 6.2");
}

-(void)testEqualsLatexValue
{
	mathModel_assertThatIsValidLatex(@"x = 6.2", @"x = 6.2");
}

// -------------find root tests--------------------

// tests finding the root of a nil expression
-(void)testFindRootOfMathNodeNil
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: nil];
	NTIMathSymbol* parent = [self->mathModel rootMathSymbol];
	assertThat([self->mathModel findRootOfMathNode: parent], is(parent));
}

// test finding the root of the root expression
-(void)testFindRootOfMathNodeRoot
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4+5"];
	NTIMathSymbol* parent = [self->mathModel rootMathSymbol];
	assertThat([self->mathModel findRootOfMathNode: parent], is(parent));
}

// test finding the root of the child expression
-(void)testFindFootOfMathNodeChild
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4+5*6"];
	NTIMathSymbol* parent = [self->mathModel rootMathSymbol];
	for(NTIMathSymbol* child in parent.children){
		assertThat([self->mathModel findRootOfMathNode: child], is(parent));
	}
}

-(void)testFindFootOfMathNodeGrandchildPlus
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4+5*6^7"];
	NTIMathSymbol* parent = [self->mathModel rootMathSymbol];
	for(NTIMathSymbol* child in parent.children){
		if(child.children != nil){
			for(NTIMathSymbol* grandChild in child.children){
				assertThat([self->mathModel findRootOfMathNode: grandChild], is(parent));
			}
		}
	}
}

// --------------modify current symbol-----------------

-(void)testCurrentMathSymbolNil
{
	assertThat([[self->mathModel currentMathSymbol] toString], is(@""));
}

-(void)testCurrentMathSymbolBasic
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4+5"];
	assertThat([[self->mathModel currentMathSymbol] toString], is(@"5"));
}

-(void)testCurrentMathSymbolNilDiv
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"*"];
	NTIMathSymbol* parent = [self->mathModel rootMathSymbol];
	NTIMathSymbol* leftChild = [parent.children objectAtIndex:0];
	NTIMathSymbol* rightChild = [parent.children objectAtIndex:1];
	assertThat([self->mathModel currentMathSymbol], is(equalTo(leftChild)));
	[self->mathModel setCurrentSymbolTo: rightChild];
	assertThat([self->mathModel currentMathSymbol], is(equalTo(rightChild)));
	[self->mathModel addMathSymbolForString: @"7" fromSenderType: kNTIMathTextfieldInput];
	assertThat([self->mathModel generateEquationString], is(@"*7"));
}

-(void)testSetMathSymbolNil
{
	self->baseModel = [NTIMathEquationBuilder modelFromString: nil];
	[self->mathModel setCurrentSymbolTo: [self->baseModel rootMathSymbol]];
	assertThat([[self->mathModel currentMathSymbol] toString], is(@""));
}

//-(void)testSetMathSymbolBasic
//{
//	[self buildEquationFromString: @"4": self->baseModel];
//	NTIMathSymbol* changeSymbol = [self->mathModel rootMathSymbol];
//	[self buildEquationFromString: @"4+5": self->mathModel];
//	[self->mathModel setCurrentSymbolTo: changeSymbol];
//	assertThat([[self->mathModel currentMathSymbol] toString], is(@"4"));
//}
//
//-(void)testSetMathSymbolOutside
//{
//	[self buildEquationFromString: @"4": self->baseModel];
//	[self buildEquationFromString: @"4+5": self->mathModel];
//	[self->mathModel setCurrentSymbolTo: [self->baseModel rootMathSymbol]];
//	assertThat([[self->mathModel currentMathSymbol] toString], isNot(@"4"));
//}
//
//-(void)testRemoveMathExpressionNil
//{
//	[self buildEquationFromString: @"" : self->baseModel];
//	[self->mathModel removeMathExpression: [self->baseModel rootMathSymbol]];
//	assertThat([[self->mathModel fullEquation] toString], is(@""));
//}
//
//-(void)testRemoveMathExpressionBasic
//{
//	[self buildEquationFromString: @"4" : self->baseModel];
//	NTIMathSymbol* changeSymbol = [self->mathModel rootMathSymbol];
//	[self buildEquationFromString: @"+5" : self->mathModel];
//	[self->mathModel removeMathExpression: changeSymbol];
//	assertThat([self->mathModel generateEquationString], is(@"+5"));
//}
//
//-(void)testDeleteMathExpressionNil
//{
//	NTIMathSymbol* removeSymbol = [[NTIMathEquationBuilder modelFromString: @"4"] rootMathSymbol];
//	[self->mathModel deleteMathExpression: removeSymbol];
//	assertThat([[self->mathModel rootMathSymbol] toString], is(@""));
//}
//
//-(void)testDeleteMathExpressionBasic
//{
//	NTIMathSymbol* removeSymbol = [[NTIMathEquationBuilder modelFromString: @"4"] rootMathSymbol];
//	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4+5"];
//	[self->mathModel deleteMathExpression: removeSymbol];
//	assertThat([[self->mathModel rootMathSymbol] toString], is(@"+5"));
//}

-(void)testRemoveMathSymbolOutside
{
	self->baseModel = [NTIMathEquationBuilder modelFromString: @"4"];
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4+5"];
	[self->mathModel removeMathExpression: [self->baseModel rootMathSymbol]];
	assertThat([[self->mathModel currentMathSymbol] toString], isNot(@"4"));
}

// ---------------find leaf node tests-----------------

-(void)testfindFirstLeafNodFromNil
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @""];
	NTIMathSymbol* eq = [self->mathModel fullEquation];
	assertThat([[self->mathModel findFirstLeafNodeFrom: eq] toString], is(@""));
}

-(void)testfindFirstLeafNodFromBasic
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4^5*6+7"];
	NTIMathSymbol* eq = [self->mathModel fullEquation];
	assertThat([[self->mathModel findFirstLeafNodeFrom: eq] toString], is(@"4"));
}

-(void)testfindLastLeafNodFromNil
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @""];
	NTIMathSymbol* eq = [self->mathModel fullEquation];
	assertThat([[self->mathModel findLastLeafNodeFrom: eq] toString], is(@""));
}

-(void)testfindLastLeafNodFromBasic
{
	self->mathModel = [NTIMathEquationBuilder modelFromString: @"4^5*6+7"];
	NTIMathSymbol* eq = [self->mathModel fullEquation];
	assertThat([[self->mathModel findLastLeafNodeFrom: eq] toString], is(@"7"));
}

@end

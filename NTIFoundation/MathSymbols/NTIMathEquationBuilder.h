//
//  NTIMathEquationBuilder.h
//  NTIMathAccessory
//
//  Created by  on 4/25/12.
//  Copyright (c) 2012 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTIMathInputExpressionModel;
@interface NTIMathEquationBuilder : NSObject 
@property(nonatomic, strong)NTIMathInputExpressionModel* mathModel;

+(NTIMathInputExpressionModel*)modelFromString: (NSString*)string;

-(id)initWithMathModel: (NTIMathInputExpressionModel *)aModel;
-(void)buildModelFromEquationString: (NSString *)stringValue;
-(NSString *)equationString;
-(void)clearModelEquation;
@end

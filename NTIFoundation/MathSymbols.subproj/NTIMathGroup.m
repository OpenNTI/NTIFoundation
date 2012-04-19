//
//  NTIMathGroup.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathGroup.h"

@implementation NTIMathGroup
-(id)initWithMathSymbol: (NTIMathSymbol *)aSymbol
{
	self = [super init];
	if (self) {
		if (aSymbol) {
			_components = [NSMutableArray arrayWithObject: aSymbol];
			aSymbol.parentMathSymbol = self;
		}
	}
	return self;
}

-(id)initWithMathGroupSymbol: (NTIMathGroup *)aSymbol
{
	self = [super init];
	if (self) {
		if (aSymbol) {
			_components = [NSMutableArray arrayWithArray: [aSymbol components]];
			for ( NTIMathSymbol* m in _components ) {
				m.parentMathSymbol = self;
			}
		}
	}
	return self;
}

-(NSArray *)components
{
	return (NSArray *)_components;
}

-(void)removeAllMathSymbols
{
	[_components removeAllObjects];
}

-(BOOL)requiresGraphicKeyboard
{
	if (!_components || [_components count] == 0) {
		return NO;
	}
	return YES;
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	
	if (!_components) {
		_components = [[NSMutableArray alloc] initWithObjects: newSymbol, nil];
		newSymbol.parentMathSymbol = self;
		return newSymbol;
	}
	
	//We ask the last element if it can add the newSymbol. FIXME: could cause some issues on our tree? 
	if ( [(NTIMathSymbol *)[_components lastObject] addSymbol: newSymbol] ) {
		return [_components lastObject];
	}
	
	[_components addObject: newSymbol];
	newSymbol.parentMathSymbol = self;
	return newSymbol;
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)aMathSymbol
{
	//NOTE: If it's only one thing in the array, it will be deleted with the parent. Is this reasonable in all cases?
	if ([_components count] <= 0) {
		return nil;
	}
	
	if ([_components containsObject: aMathSymbol]) {
		[_components removeObject: aMathSymbol];
		if ([_components count] > 0)
			return [_components lastObject];
		else 
			return self;
	}		
	return nil;
}

-(NSString *)latexValue
{
	NSString* lValue = [NSString stringWithFormat: @""];
	for (NTIMathSymbol* ms in _components) {
		lValue = [NSString stringWithFormat: @"%@%@", lValue, [ms latexValue]];
	}
	return [NSString stringWithFormat: @"( %@ )", lValue];
}

@end

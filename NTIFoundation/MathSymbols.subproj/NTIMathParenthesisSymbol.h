//
//  NTIMathParenthesisSymbol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathGroup.h"

@interface NTIMathParenthesisSymbol : NTIMathGroup
@property(nonatomic)BOOL openQueueSymbol;	//This will help determine when we can add things or not. Help to move out of the paranthesis;
@end

//
//  NTIMathExpressionSymbolProtocol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIMathSymbol.h"
@class NTIMathSymbol;
@protocol NTIMathExpressionSymbolProtocol <NSObject>
@required

// Ask if it can handle adding math symbol, if it ends up combining math symbols( e.g. alphanumeric ),
// it will return a pointer to the new composed symbol, otherwise a pointer to the newSymbol that's added.
// The main idea, is that we want the head of tree to point to where the new symbol is added. If it cannot add it, it will return nil.
-(NTIMathSymbol *)addSymbol: (id)mathSym;	

//Delete a given math symbol if it can, and returns a pointer to the symbol that becomes the head of the tree.
-(NTIMathSymbol *)deleteSymbol: (NTIMathSymbol *)mathSymbol;
//This will inform the renderer how it can be rendered, either as print text or it requires a graphic math kb.
-(BOOL)requiresGraphicKeyboard;	
@end

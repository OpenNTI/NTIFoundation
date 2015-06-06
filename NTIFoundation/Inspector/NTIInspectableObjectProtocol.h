//
//  NTIInspectableObjectProtocol.h
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 2/15/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NTIInspectableObjectProtocol <NSObject>
@optional
-(id)belongsTo;		//Returns the owner of an inspected object
-(NSString *)nameOfInspectableObjectContainer;
@end

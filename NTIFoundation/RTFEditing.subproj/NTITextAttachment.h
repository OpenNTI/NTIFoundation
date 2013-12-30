//
//  NTITextAttachment.h
//  NTIFoundation
//
//  Created by Christopher Utz on 10/17/13.
//  Copyright (c) 2013 NextThought. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OATextAttachmentCell;
@interface NTITextAttachment : NSTextAttachment

+(instancetype)attachmentWithRenderer: (id<OATextAttachmentCell>)renderer;

//Designated initalizer
-(id)init;

@property (nonatomic, strong) id<OATextAttachmentCell> attachmentRenderer;
@end

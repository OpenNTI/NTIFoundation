//
//  NSURL-NTIFileSystemExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 12/14/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/xattr.h>

@interface NSURL(NTIFileSystemExtensions)

//Adds the skip backup xattr to the item at this url.  The file or folder should already exist.
- (BOOL)addSkipBackupAttributeToItem;

@end

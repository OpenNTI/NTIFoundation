//
//  OUUnzipArchive-NTIExtensions.h
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/29.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniUnzip/OUUnzipArchive.h>

NSString* pathFromUrl( NSURL* url );
typedef void(^NTIUnzipArchiveProgress)(NSInteger worked, NSUInteger count);
@interface OUUnzipArchive (NTIExtensions)

/**
 * @return The complete URL to the extracted directory, or nil on error.
 */
+(NSURL*)extract: (NSURL*)archiveFile
			to: (NSString*)name
		within: (NSURL*)libraryDir
		progress: (NTIUnzipArchiveProgress)progresscb
		 error: (NSError**)error;

@end

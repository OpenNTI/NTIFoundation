//
//  NTIFoundation.h
//  NTIFoundation
//
//  Created by Christopher Utz on 10/26/15.
//  Copyright © 2015 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for NTIFoundation.
FOUNDATION_EXPORT double NTIFoundationVersionNumber;

//! Project version string for NTIFoundation.
FOUNDATION_EXPORT const unsigned char NTIFoundationVersionString[];

#import <NTIFoundation/NTIUtilities.h>

//Foundation Extensions
#import <NTIFoundation/NSDate-NTIExtensions.h>
#import <NTIFoundation/NSURL-NTIExtensions.h>
#import <NTIFoundation/NSData+NTIExtensions.h>
#import <NTIFoundation/NSData-NTIJSON.h>
#import <NTIFoundation/NSArray-NTIExtensions.h>
#import <NTIFoundation/NSMutableArray-NTIExtensions.h>
#import <NTIFoundation/NSNotification-NTIExtensions.h>
#import <NTIFoundation/NSString-NTIExtensions.h>
#import <NTIFoundation/NSString-NTIJSON.h>
#import <NTIFoundation/NSMutableDictionary-NTIExtensions.h>
#import <NTIFoundation/NSURL-NTIFileSystemExtensions.h>
#import <NTIFoundation/NSObject-NTIJSON.h>

//Formatting
#import <NTIFoundation/NTIDuration.h>
#import <NTIFoundation/NTIISO8601DurationFormatter.h>

//Omni Extensions
#import <NTIFoundation/OUUnzipArchive-NTIExtensions.h>

//UIKit Extensions
#import <NTIFoundation/UIDevice-NTIExtensions.h>
#import <NTIFoundation/UIColor+NTIExtensions.h>

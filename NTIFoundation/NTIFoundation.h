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

// In this header, you should import all the public headers of your framework using statements like #import <NTIFoundation/PublicHeader.h>

#import <NTIFoundation/NTIUtilities.h>

//Foundation Extensions
#import <NTIFoundation/UIDevice-NTIExtensions.h>
#import <NTIFoundation/NSDate-NTIExtensions.h>
#import <NTIFoundation/NSURL-NTIExtensions.h>
#import <NTIFoundation/NSData+NTIExtensions.h>
#import <NTIFoundation/NSArray-NTIExtensions.h>
#import <NTIFoundation/NSMutableArray-NTIExtensions.h>
#import <NTIFoundation/NSNotification-NTIExtensions.h>
#import <NTIFoundation/NSString-NTIExtensions.h>
#import <NTIFoundation/NSMutableDictionary-NTIExtensions.h>
#import <NTIFoundation/NTIAbstractDownloader.h>
#import <NTIFoundation/NSURL-NTIFileSystemExtensions.h>

//JSON Extensions
#import <NTIFoundation/NSData-NTIJSON.h>
#import <NTIFoundation/NSString-NTIJSON.h>
#import <NTIFoundation/NSObject-NTIJSON.h>

//Socket Extensions
#import <NTIFoundation/SocketIOPacket.h>
#import <NTIFoundation/SocketIOSocket.h>
#import <NTIFoundation/SocketIOTransport.h>

//HTML Extensions
#import <NTIFoundation/NSAttributedString-HTMLReadingExtensions.h>
#import <NTIFoundation/NSAttributedString-HTMLWritingExtensions.h>
#import <NTIFoundation/NSAttributedString-NTIExtensions.h>
#import <NTIFoundation/NTIRTFDocument.h>
#import <NTIFoundation/NTIHTMLWriter.h>
#import <NTIFoundation/NTIHTMLReader.h>

//Omni Extensions
#import <NTIFoundation/OAColor-NTIExtensions.h>
#import <NTIFoundation/NTIEditableFrame.h>
#import <NTIFoundation/NTITextAttachment.h>
#import <NTIFoundation/NTITextAttachmentCell.h>
#import <NTIFoundation/OUUnzipArchive-NTIExtensions.h>

//Formatting
#import <NTIFoundation/NTIDuration.h>
#import <NTIFoundation/NTIISO8601DurationFormatter.h>


//UI Utilities
#import <NTIFoundation/NTIBadgeView.h>
#import <NTIFoundation/UIColor+NTIExtensions.h>
#import	<NTIFoundation/NTIKeyboardAdjustmentListener.h>
#import <NTIFoundation/NTIInspectableController.h>
#import <NTIFoundation/NTIGlobalInspector.h>
#import <NTIFoundation/NTIInspectableObjectProtocol.h>
#import <NTIFoundation/NTIGlobalInspectorMainPane.h>
#import <NTIFoundation/NTIGlobalInspectorSlice.h>
//
//
//
//

//
//#import <NTIFoundation/NTIMathSymbol.h>
//#import <NTIFoundation/NTIMathAlphaNumericSymbol.h>
//#import <NTIFoundation/NTIMathOperatorSymbol.h>
//#import <NTIFoundation/NTIMathPlaceholderSymbol.h>
//#import <NTIFoundation/NTIMathParenthesisSymbol.h>
//#import <NTIFoundation/NTIMathUnaryExpression.h>
//#import <NTIFoundation/NTIMathBinaryExpression.h>
//#import <NTIFoundation/NTIMathFractionBinaryExpression.h>
//#import <NTIFoundation/NTIMathExponentBinaryExpression.h>
//#import <NTIFoundation/NTIMathEquationBuilder.h>
//#import <NTIFoundation/NTIMathInputExpressionModel.h>


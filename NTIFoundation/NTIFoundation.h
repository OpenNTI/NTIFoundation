//
//  NTIFoundation.h
//  NTIFoundation
//
//  Created by Jason Madden on 2011/09/17.
//  Copyright (c) 2011-2013 NextThought. All rights reserved.
//

#ifndef NTIFoundation_NTIFoundation_h
#define NTIFoundation_NTIFoundation_h

#if ! __has_feature(objc_arc)
	#define NTIDispatchQueueRelease(__v) (dispatch_release(__v));
#else
	#if TARGET_OS_IPHONE
		// Compiling for iOS
		#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
			// iOS 6.0 or later
			#define NTIDispatchQueueRelease(__v)
		#else
			// iOS 5.X or earlier
			#define NTIDispatchQueueRelease(__v) (dispatch_release(__v));
		#endif
	#endif
#endif


#import "UIDevice-NTIExtensions.h"
#import "NSDate-NTIExtensions.h"
#import "NSURL-NTIExtensions.h"
#import "NSData-NTIJSON.h"
#import "NSString-NTIJSON.h"
#import "NSObject-NTIJSON.h"
#import "NSArray-NTIExtensions.h"
#import "NSMutableArray-NTIExtensions.h"
#import "NSNotification-NTIExtensions.h"
#import "NSString-NTIExtensions.h"
#import "NSMutableDictionary-NTIExtensions.h"
#import "OUUnzipArchive-NTIExtensions.h"
#import "NTIAbstractDownloader.h"
#import "NTIUtilities.h"
#import "SocketIOPacket.h"
#import "SocketIOSocket.h"
#import "SocketIOTransport.h"
#import "WebSockets.h"
#import "SendRecieveQueue.h"
#import "NSAttributedString-HTMLReadingExtensions.h"
#import "NSAttributedString-HTMLWritingExtensions.h"
#import "NSAttributedString-NTIExtensions.h"
#import "NTIRTFDocument.h"
#import "NTIHTMLWriter.h"
#import "NTIHTMLReader.h"
#import "OQColor-NTIExtensions.h"
#import "NTIEditableFrame.h"
#import "NTITextAttachment.h"
#import "NTITextAttachmentCell.h"
#import "NSURL-NTIFileSystemExtensions.h"
#import "NTIAppNavigationController.h"
#import "NTIInspectableController.h"
#import "NTIGlobalInspector.h"
#import "NTIAppNavigationLayerProvider.h"
#import "NTIAppNavigationLayerDescriptor.h"
#import "NTIAppNavigationLayer.h"
#import "NTIInspectableObjectProtocol.h"
#import "NTIGlobalInspectorMainPane.h"
#import "NTIGlobalInspectorSlice.h"
#import "NTIBadgeCountView.h"
#import	"NTIKeyboardAdjustmentListener.h"

#import "NTIDuration.h"
#import "NTIISO8601DurationFormatter.h"

#import "NTIMathSymbol.h"
#import "NTIMathAlphaNumericSymbol.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathParenthesisSymbol.h"
#import "NTIMathUnaryExpression.h"
#import "NTIMathBinaryExpression.h"
#import "NTIMathFractionBinaryExpression.h"
#import "NTIMathExponentBinaryExpression.h"
#import "NTIMathEquationBuilder.h"
#import "NTIMathInputExpressionModel.h"

#endif

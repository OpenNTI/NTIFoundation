
#import <Foundation/Foundation.h>
#import "NTINavigationParser.h"

#define NTI_URL_SCHEME @"x-nti-cid"

BOOL NTIUrlCanHandleScheme( NSURL* url );

NTINavigationItem* NTIUrlFindNavigationItem( NSURL* url, NTINavigationItem* root );

NSURL* NTIUrlFromNavigationItem( NTINavigationItem* item );

NSURL* NTIUrlFromContentID( NSString* cid );


#import "NTIUrlScheme.h"
#import "NSArray-NTIExtensions.h"

BOOL NTIUrlCanHandleScheme( NSURL* url )
{
	return [NTI_URL_SCHEME isEqual: [url scheme]];
}

NTINavigationItem* NTIUrlFindNavigationItem( NSURL* url, NTINavigationItem* root )
{
	if( !NTIUrlCanHandleScheme( url ) ) {
		return nil;
	}
	
	NSString* cid = [url resourceSpecifier];
	NSArray* path = [root pathToID: cid];
	if( [NSArray isEmptyArray: path] ) {
		return nil;
	}
	
	return path.lastObject;
}

NSURL* NTIUrlFromNavigationItem( NTINavigationItem* item )
{
	return NTIUrlFromContentID( item.ntiid );
}

NSURL* NTIUrlFromContentID( NSString* cid )
{
	return [NSURL URLWithString: [NSString stringWithFormat: @"x-nti-cid:%@", cid]];
}


#import "NTIWebContextRelatedController.h"
#import "WebAndToolController.h"
#import "NTIDraggableTableViewCell.h"
#import "NTINavigationParser.h"
#import "NTINavigation.h"
#import "NSArray-NTIExtensions.h"
#import "NTIOSCompat.h"
#import "NTITapCatchingGestureRecognizer.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NTIAppPreferences.h"

@implementation NTIWebContextRelatedController
@synthesize miniView, presentsModalInsteadOfZooming, miniViewTitle, miniCreationAction, supportsZooming;
@synthesize miniViewHidden;
@synthesize  webController;

-(id)initWithStyle: (UITableViewStyle)style
			   web: (WebAndToolController*)web
{
	self = [super initWithStyle: style];
	self.webController = web;
	self->miniViewTitle = @"Related";
	self->presentsModalInsteadOfZooming = NO;
	self->supportsZooming = NO;
	self.collapseWhenEmpty = YES;
	self.predicate = [NSPredicate predicateWithFormat: @"type CONTAINS[cd] $VALUE OR qualifier CONTAINS[cd] $VALUE"];
	[self.webController addObserver: self
						 forKeyPath: @"ntiPageId"
							options: NSKeyValueObservingOptionNew
							context: nil];
	return self;
}


-(void)observeValueForKeyPath: (NSString*)key 
					 ofObject: (id)object 
					   change: (NSDictionary*)change
					  context: (void*)ctx
{
	id page = [change objectForKey: NSKeyValueChangeNewKey];
	if( ![page isNull] ) {
		[super setAllObjectsAndFilter: [self.webController selectedNavigationItem].related
						  reloadTable: self.isViewLoaded];
	}
}

-(id)relatedNavigationItemForId: (NTIRelatedNavigationItem*)relatedId
{
	id navItem = nil;
	NTINavigationItem* rootNav = [self.webController.navHeaderController root];
	//Resolve the id
	NSArray* pathToNav = [rootNav pathToID: relatedId.ntiid];
	navItem = [pathToNav lastObjectOrNil];

	return navItem;
}

-(void)subset: (id)me
configureCell: (UITableViewCell*)cell
	forObject: (id)object
{
	NTIRelatedNavigationItem* relatedId = object;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	NTINavigationItem* navItem = [self relatedNavigationItemForId: relatedId];
	if( navItem ) {
		[NTINavigationTableViewController configureTableViewCell: cell
											   forNavigationItem: navItem
													actionTarget: nil];
		
		[[cell detailTextLabel] setText: [NSString stringWithFormat:@"type: %@, qualifier: %@", 
										  relatedId.type, relatedId.qualifier]];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else if( [NSURL URLWithString: relatedId.href] ) {
		[NTINavigationTableViewController configureTableViewCell: cell
											   forNavigationItem: relatedId
													actionTarget: nil];
		cell.detailTextLabel.text = relatedId.qualifier;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}


-(void)subset: (id)me didSelectObject: (id)object
{
	id navItem = [self relatedNavigationItemForId: object];
	if( navItem ) {
		[self.webController navigateToItem: navItem];
	}
	else if(	[[(NTIRelatedNavigationItem*)object type] isEqual: @"video"] 
			&&	[object href]) {
		//The content may be local or remote. Try to check locally 
		//first (if we appear to be local to start with) and if that's 
		//not found, then assume remote.		
		NSURL* url = nil;
		//TODO: This logic is similar to what WebAndToolController does.
		//extract all this to a common place.
		if(	OFISEQUAL( @"file", [[object objectForKey: kNTINavigationPropertyOverrideRoot] scheme] ) ) {
			//We're loading content locally. Can we resolve this href
			//locally?
			NSURL* overrideRoot = [object objectForKey: kNTINavigationPropertyOverrideRoot];
			NSString* href = [object href];
			if( [href characterAtIndex: 0] != '/' ) {
				//We have a relative path to resolve. This will only 
				//work if we start from a directory.
			
				if( OFISEQUAL( @"index.html", [overrideRoot lastPathComponent] ) ) {
					overrideRoot = [overrideRoot URLByDeletingLastPathComponent];
				}
			}
			url = [overrideRoot URLByAppendingPathComponent: [object href] 
												isDirectory: NO];
			if( ![[NSFileManager defaultManager] fileExistsAtPath: [url path]] ) {
				NSLog( @"No local file %@", url );
				url = nil;
			}
		}
		
		if( url == nil && [object objectForKey: @"remoteRootUrl"] ) {
			//Nothing local. Do we have a preferred remote location?
			url = [[object objectForKey: @"remoteRootUrl"] 
				   URLByAppendingPathComponent: [object href]];
		}
		
		if( url == nil ) {
			//Nothing local, no preferred remote location. Try 
			//simply relative to the root.
			
			//URLByAppendingPathComponent seems to stick in an extra slash even 
			//if the component begins with a slash
			NSString* href = [object href];
			if( [href firstCharacter] == '/' ){
				href = [href substringFromIndex: 1];
			}
			url = [[[NTIAppPreferences prefs] rootURL] URLByAppendingPathComponent: href];
		}
		
		if( url ) {
			MPMoviePlayerController* theMovie = [[MPMoviePlayerController alloc] 
												  initWithContentURL: url];
			theMovie.fullscreen = NO;
			theMovie.controlStyle = MPMovieControlStyleEmbedded;
			theMovie.useApplicationAudioSession = NO; //Crashes in simulator if YES
			theMovie.movieSourceType = MPMovieSourceTypeFile;

			[[NSNotificationCenter defaultCenter]
			 addObserver: self
			 selector: @selector(movieFinishedPlaying:)
			 name: MPMoviePlayerPlaybackDidFinishNotification
			 object: theMovie];
			[[NSNotificationCenter defaultCenter]
			 addObserver: self
			 selector: @selector(movieLoadState:)
			 name: MPMoviePlayerLoadStateDidChangeNotification
			 object: theMovie];
			[[NSNotificationCenter defaultCenter]
			 addObserver: self
			 selector: @selector(moviePlaybackState:)
			 name: MPMoviePlayerPlaybackStateDidChangeNotification
			 object: theMovie];
			
			[self.tableView addSubview: theMovie.view];
			
			UIToolbar* tb = [[UIToolbar alloc] init]; mtb = tb;
			[tb autorelease];
			tb.barStyle = UIBarStyleBlack;
			tb.translucent = YES;
			UIBarButtonItem* done = [[UIBarButtonItem alloc] 
									 initWithBarButtonSystemItem: UIBarButtonSystemItemDone
									 target: self
									 action: @selector(moviePlaybackDone:)];
			tb.items = [NSArray arrayWithObject: done];
			tb.frame = CGRectMake( 0, 0, self.tableView.frame.size.width, 44 );
			
			m = theMovie;
			

			//TODO: Handling the toolbar correctly probably means we need a 
			//custom overlay view. Until then, the collection of hacks
			//below suffices.
			UITapGestureRecognizer* gr = [[NTITapCatchingGestureRecognizer alloc]
										  initWithTarget: self
										  action: @selector(tapForControls:)];
			[gr autorelease];
			[theMovie.view addGestureRecognizer: gr];
			NSIndexPath* path = [self indexPathForObject: object];
			if( path ) {
				UITableViewCell* cell = [self.tableView cellForRowAtIndexPath: path];
				CGRect frame = cell.imageView.frame;
				mendRect = [self.tableView convertRect: frame fromView: cell.imageView.superview];
			}
			mitem = object;
			NSNumber* playbackPos = [object objectForKey: @"moviePlaybackTime"];
			if( playbackPos ) {
				//NOTE: If we call prepareToPlay, setting this is
				//for naught.
				theMovie.initialPlaybackTime = [playbackPos doubleValue];
			}
			[theMovie.view setFrame: mendRect];

			[UIView animateWithDuration: 0.4
							 animations: ^{ [theMovie.view setFrame: self.tableView.bounds]; }
							 completion: ^(BOOL _){ [theMovie.view addSubview: tb]; } ];
			[theMovie play];
		}
	}
}


static void beginTimer( NTIWebContextRelatedController* self )
{
	NTI_RELEASE( self->mtimer );
	//Timer starts out hidden, but when movie pauses, we
	//want to invalidate the timer too? How does that work?
	self->mtimer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow: 5]
									  interval: 0 
										target: self 
									  selector: @selector(hideControls:)
									  userInfo: nil
									   repeats: NO];
	[[NSRunLoop currentRunLoop] addTimer: self->mtimer 
								 forMode: NSRunLoopCommonModes];									   
}

-(void)movieLoadState: (NSNotification*)notification
{
	MPMoviePlayerController* o = [notification object];
	NSLog( @"Load State: %ld", [o loadState] );	
	if( o.loadState == MPMovieLoadStatePlayable || o.loadState == MPMovieLoadStatePlaythroughOK ) {
		if( !mtimer && o.playbackState == MPMoviePlaybackStatePlaying ) {
			beginTimer( self );
		}
	}
}

-(void)moviePlaybackState: (NSNotification*)notification
{
	MPMoviePlayerController* o = [notification object];
	NSLog( @"State: %ld", [o playbackState] );	
	if( o.playbackState == MPMoviePlaybackStateStopped ) {
		beginTimer( self );
	}
	else if( o.playbackState == MPMoviePlaybackStatePaused ) {
		[mtimer invalidate];
		NTI_RELEASE(mtimer);
	}
	else if( o.playbackState == MPMoviePlaybackStatePlaying ) {
		if( !mtimer && o.loadState != MPMovieLoadStateUnknown ) {
			beginTimer( self );
		}
	}
}

static void showToolbar( NTIWebContextRelatedController* self )
{
	self->mtb.hidden = NO;
	[UIView animateWithDuration: 0.2
					 animations: ^{
						self->mtb.alpha = 1.0;
					 }];
}

static void hideToolbar( NTIWebContextRelatedController* self )
{
	[UIView animateWithDuration: 0.2
					 animations: ^{ self->mtb.alpha = 0.0; }
					 completion: ^(BOOL _){ self->mtb.hidden = YES; }];
}

-(void)movieFinishedPlaying: (NSNotification*)notification
{
	showToolbar( self );
	[mtimer invalidate];
	[mtimer release];
	mtimer = nil;
}

-(void)tapForControls: (id)s
{
	if( mtb.hidden ) {
		beginTimer( self );
		showToolbar( self );
	}
	else {
		hideToolbar( self );
	}
}

-(void)hideControls:(id)s
{
	hideToolbar( self );
}

-(void)moviePlaybackDone: (id)sender
{
	UIImage* image = [m thumbnailImageAtTime: [m currentPlaybackTime]
								  timeOption: MPMovieTimeOptionNearestKeyFrame];
	if( image ) {								  
		[mitem setObject: image forKey: kNTINavigationPropertyIcon];
		[self.tableView cellForRowAtIndexPath: [self indexPathForObject: mitem]].imageView.image = image;
	}
	[self->mitem setObject: [NSNumber numberWithDouble: [m currentPlaybackTime]]
			  forKey: @"moviePlaybackTime"];
	self->mitem = nil;
	[m stop];
	mtb.hidden = YES;
	[UIView animateWithDuration: 0.4
					 animations: ^{ [[[self.tableView subviews] lastObject] setFrame: mendRect]; }
					 completion: ^(BOOL _) {
						 [[[self.tableView subviews] lastObject] removeFromSuperview];
					 }];

	[m release];
	m = nil;
	[mtimer invalidate];
	[mtimer release];
	mtimer = nil;
	mtb = nil;
}

-(BOOL)doesObject: (id)target matchString: (NSString*)string
{
	BOOL result = [super doesObject: target matchString: string];
	if( result == NO ) {
		//OK, see about the nav item itself
		result = [[[self relatedNavigationItemForId: target] name]
				  containsString: string
				  options: NSCaseInsensitiveSearch];
	}
	
	return result;
}

//#pragma mark -
//#pragma mark NTIWebContextViewController
//
-(UIView*)view
{
	return [super view];	
}

-(UIView*)miniView
{
	//Nil to force the full view to be used and sized correctly
	return nil;
}

-(void)dealloc
{
	[self.webController removeObserver: self forKeyPath: @"ntiPageId"];
	self.webController = nil;
	[super dealloc];
}
@end

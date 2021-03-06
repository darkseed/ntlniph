#import "NTLNFavoriteViewController.h"
#import "NTLNAccount.h"
#import "NTLNConfiguration.h"
#import "NTLNHttpClientPool.h"

@implementation NTLNFavoriteViewController

@synthesize screenName;

- (id)init {
	if (self = [super init]) {
		timeline = [[NTLNTimeline alloc] initWithDelegate:self 
									  withArchiveFilename:@"favorites.plist"];
	}
	return self;
}

- (void)dealloc {
	LOG(@"NTLNFavoriteViewController#dealloc");
	[screenName release];
	[screenNameInternal release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated]; //with reload

	[screenNameInternal release];
	if (screenName == nil) {
		screenNameInternal = [[[NTLNAccount instance] username] retain];
		[self.navigationItem setTitle:@"Favorites"];
	} else {
		screenNameInternal = [screenName retain];
		[self.navigationItem setTitle:[NSString stringWithFormat:@"%@'s fav", screenNameInternal]];
	}
}

- (void)setupNavigationBar {
	[super setupNavigationBar];
	[super setupPostButton];
}

- (void)timeline:(NTLNTimeline*)tl requestForPage:(int)page since_id:(NSString*)since_id {
	NTLNTwitterClient *tc = [[NTLNHttpClientPool sharedInstance] 
							 idleClientWithType:NTLNHttpClientPoolClientType_TwitterClient];
	tc.delegate = tl;
	[tc getFavoriteWithScreenName:screenNameInternal page:page since_id:since_id];
}

@end


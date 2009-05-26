#import "NTLNAppDelegate.h"
#import "NTLNAccount.h"
#import "NTLNTweetPostViewController.h"
#import "NTLNFriendsViewController.h"
#import "NTLNReplysViewController.h"
#import "NTLNSentsViewController.h"
#import "NTLNUnreadsViewController.h"
#import "NTLNSettingViewController.h"
#import "NTLNCacheCleaner.h"
#import "NTLNTwitterAccountViewController.h"
#import "NTLNFavoriteViewController.h"
#import "NTLNDirectMessageViewController.h"
#import "NTLNRateLimit.h"
#import "GTMRegex.h"
#import "NTLNTwitterPost.h"

@implementation UITabBarController(EnableRotate)
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}
@end

@implementation NTLNAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize applicationActive;

#define NTLN_PREFERENCE_TABORDER		@"tabItemTitlesForTabOrder"

- (void)setTabOrderIfSaved {
	NSArray *tabItemTitles = [[NSUserDefaults standardUserDefaults] arrayForKey:NTLN_PREFERENCE_TABORDER];
	NSMutableArray *views = [NSMutableArray array];
	if ([tabItemTitles count] > 0) {
		for (int i = 0; i < [tabItemTitles count]; i++){
			for (UIViewController *vc in tabBarController.viewControllers) {
				if ([vc.tabBarItem.title isEqualToString:[tabItemTitles objectAtIndex:i]]) {
					[views addObject:vc];
				}
			}
		}
		tabBarController.viewControllers = views;
	}
}

- (void)saveTabOrder {
	NSMutableArray *tabItemTitles = [NSMutableArray array];
	for (UIViewController *v in tabBarController.viewControllers) {
		[tabItemTitles addObject:v.tabBarItem.title];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:tabItemTitles forKey:NTLN_PREFERENCE_TABORDER];
}

- (void)createViews {
	tabBarController = [[UITabBarController alloc] init];
		
	friendsViewController = [[NTLNFriendsViewController alloc] init];
	replysViewController = [[NTLNReplysViewController alloc] init];
	friendsViewController.replysViewController = replysViewController;
	replysViewController.friendsViewController = friendsViewController;
	
	directMessageViewController	= [[NTLNDirectMessageViewController alloc] init];
	sentsViewController = [[NTLNSentsViewController alloc] init];
	unreadsViewController = [[NTLNUnreadsViewController alloc] init];
	
	unreadsViewController.friendsViewController = friendsViewController;
	unreadsViewController.replysViewController = replysViewController;
	unreadsViewController.directMessageViewController = directMessageViewController;
		
	settingViewController = [[NTLNSettingViewController alloc] initWithStyle:UITableViewStyleGrouped];
	
	favoriteViewController  = [[NTLNFavoriteViewController alloc] init];
	
	
	UINavigationController *nfri = [[[UINavigationController alloc] 
										initWithRootViewController:friendsViewController] autorelease];
	
	[[NTLNRateLimit shardInstance] updateNavigationBarColor:nfri.navigationBar];
	
	UINavigationController *nrep = [[[UINavigationController alloc] 
										initWithRootViewController:replysViewController] autorelease];
	UINavigationController *nsen = [[[UINavigationController alloc] 
										initWithRootViewController:sentsViewController] autorelease];
	UINavigationController *nunr = [[[UINavigationController alloc] 
										initWithRootViewController:unreadsViewController] autorelease];
	UINavigationController *nset = [[[UINavigationController alloc] 
										initWithRootViewController:settingViewController] autorelease];
	UINavigationController *nsfv = [[[UINavigationController alloc]
										initWithRootViewController:favoriteViewController] autorelease];
	UINavigationController *nsdm = [[[UINavigationController alloc]
									 initWithRootViewController:directMessageViewController] autorelease];
	
	[nfri.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[nfri.tabBarItem setTitle:@"Friends"];
	[nfri.tabBarItem setImage:[UIImage imageNamed:@"friends.png"]];
	friendsViewController.tabBarItem = nfri.tabBarItem; // is it need (to show badge)?
	
	[nrep.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[nrep.tabBarItem setTitle:@"Mentions"];
	[nrep.tabBarItem setImage:[UIImage imageNamed:@"replies.png"]];
	replysViewController.tabBarItem  = nrep.tabBarItem; // is it need (to show badge)?

	[nsdm.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[nsdm.tabBarItem setTitle:@"DM"];
	[nsdm.tabBarItem setImage:[UIImage imageNamed:@"dm.png"]];
	directMessageViewController.tabBarItem  = nsdm.tabBarItem; // is it need (to show badge)?
	
	[nsen.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[nsen.tabBarItem setTitle:@"Sents"];
	[nsen.tabBarItem setImage:[UIImage imageNamed:@"sent.png"]];

	[nunr.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[nunr.tabBarItem setTitle:@"Unreads"];
	[nunr.tabBarItem setImage:[UIImage imageNamed:@"unread.png"]];
	
	[nset.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[nset.tabBarItem setTitle:@"Settings"];
	[nset.tabBarItem setImage:[UIImage imageNamed:@"setting.png"]];

	[nsfv.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[nsfv.tabBarItem setTitle:@"Favorites"];
	[nsfv.tabBarItem setImage:[UIImage imageNamed:@"favorites.png"]];

	[[NTLNRateLimit shardInstance] updateNavigationBarColor:tabBarController.moreNavigationController.navigationBar];

	[tabBarController setViewControllers:
		[NSArray arrayWithObjects:nfri, nrep, nsdm, nsfv, nsen, nunr, nset, nil]];

	[self setTabOrderIfSaved];
}

- (void)startup {
	[self createViews];
	
	NSString *user_id = [[NTLNAccount instance] userId];
	if (user_id == nil || [user_id length] == 0) {
		[[NTLNAccount instance] getUserId];
	}
	
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window addSubview:tabBarController.view];
	[window makeKeyAndVisible];
	

	if (![[NTLNAccount instance] valid]) {		
		[self presentTwitterAccountSettingView];
	}
	
	applicationActive = TRUE;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	NTLNCacheCleaner *cc = [NTLNCacheCleaner sharedCacheCleaner];
	cc.delegate = self;
	BOOL alertShown = [cc bootup];
	if (!alertShown) {
		[self startup];
	}
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	LOG(@"handleOpenURL:%@", url);
	if ([[url path] isEqualToString:@"/post"]) {
		NSString *query = [url query];
		NSString *text = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
																				 (CFStringRef)query,
																				 CFSTR(""),
																				 kCFStringEncodingUTF8);
		[[NTLNTwitterPost shardInstance] updateText:text];
	}
	return YES;
}


- (void)cacheCleanerAlertClosed {
	[self startup];
}

- (void)dealloc {
	[friendsViewController release];
	[replysViewController release];
	[sentsViewController release];
	[unreadsViewController release];
	[settingViewController release];
	[favoriteViewController release];
	[directMessageViewController release];
	
	[tabBarController release];
	[window release];
	[super dealloc];
}

- (void)tabBarController:(UITabBarController *)tabBarController 
			didSelectViewController:(UIViewController *)viewController {
	LOG(@"view selected: %@", [[viewController tabBarItem] title]);
}

- (void)applicationWillResignActive:(UIApplication *)application {
	LOG(@"applicationWillResignActive");
	applicationActive = FALSE;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	LOG(@"applicationDidBecomeActive");
	applicationActive = TRUE;

	[friendsViewController.timeline prefetch];
	[replysViewController.timeline prefetch];
	[directMessageViewController.timeline prefetch];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	LOG(@"applicationWillTerminate");
	[self saveTabOrder];
	
	[replysViewController.timeline disactivate];
	[directMessageViewController.timeline disactivate];
	[friendsViewController.timeline disactivate];
	[sentsViewController.timeline disactivate];
	[favoriteViewController.timeline disactivate];
	
	[[NTLNTwitterPost shardInstance] backupText];
	
	[[NTLNCacheCleaner sharedCacheCleaner] shutdown];
}

- (void)presentTwitterAccountSettingView {
	UITableViewController *vc = [[[NTLNTwitterAccountViewController alloc] 
								  initWithStyle:UITableViewStyleGrouped] autorelease];
	UINavigationController *nc = [[[UINavigationController alloc] 
								   initWithRootViewController:vc] autorelease];
	[nc.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	[tabBarController presentModalViewController:nc animated:YES];
}

- (BOOL)isInMoreTab:(UIViewController*)vc {
	int cnt = 0;
	for (UINavigationController *v in tabBarController.viewControllers) {
		if (v.viewControllers.count > 0 && [v.viewControllers objectAtIndex:0] == vc) {
			if (cnt < 4) {
				return NO;
			} else {
				return YES;
			}
		}
		cnt++;
	}
	return YES;
}

@end

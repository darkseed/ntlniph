#import "NTLNTimelineViewController.h"
#import "NTLNTweetPostViewController.h"
#import "NTLNAppDelegate.h"

@implementation NTLNTimelineViewController(Accerlerometer)

#pragma mark Private

- (void)fullScreenTimeline {
	if (tableViewSuperView == nil) {
		if ([NTLNTweetPostViewController active]) {
			[NTLNTweetPostViewController dismiss];
		}
		tableViewSuperView = self.tableView.superview;
		[self.tableView removeFromSuperview];
		[[self tabBarController].view addSubview:self.tableView];
		CGSize s = [self tabBarController].view.frame.size;
		tableViewOriginalFrame = self.tableView.frame;
		self.tableView.frame = CGRectMake(0, 0, s.width, s.height);
	}
}

- (void)normalScreenTimeline {
	if (tableViewSuperView) {
		[self.tableView removeFromSuperview];
		self.tableView.frame = tableViewOriginalFrame;
		[tableViewSuperView addSubview:self.tableView];
		tableViewSuperView = nil;
	}
}

- (void)toggleFullScreenTimeline {
	if (tableViewSuperView) {
		[self normalScreenTimeline];
	} else {
		[self fullScreenTimeline];
	}
	
	//	[NTLNSoundEffects playShakeSound];
}

#pragma mark NTLNAccelerometerSensorDelegate

- (void)accelerometerSensorDetected {
	[self toggleFullScreenTimeline];
}

- (void)accelerometerScrollDetected:(float)coef {
   static NSUInteger y = 0;
   
   if (y >= self.tableView.contentSize.height) {
      [self autopagerize];
      return;
   } else
      y += 4 * coef;

   CGPoint offset = CGPointMake(0, y);
   [self.tableView setContentOffset:offset animated:YES];
}

@end

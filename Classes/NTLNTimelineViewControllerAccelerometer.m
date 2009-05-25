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

- (void)accelerometerScrollDetected {
   static NSUInteger index = 0;
   
   if (index == [self.tableView numberOfRowsInSection:0]-1)
      [self autopagerize];
   else
      index++;
   NSUInteger indexes[] = {0, index};
   NSIndexPath *ip = [NSIndexPath indexPathWithIndexes:indexes length:2];

   [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

@end

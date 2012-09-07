#import "AppDelegate.h"

#import "NRViewController.h"


@interface AppDelegate ()
@property (nonatomic, retain) NRViewController *viewController;
@end


@implementation AppDelegate

@synthesize viewController = _viewController;
@synthesize window = _window;

- (BOOL)application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[[UIWindow alloc]
		initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

	self.viewController = [[NRViewController new] autorelease];
	if ([self.window respondsToSelector:@selector(setRootViewController:)])
		self.window.rootViewController = self.viewController;
	else
		[self.window addSubview:self.viewController.view];
	[self.window makeKeyAndVisible];

	return YES;
}

- (void)dealloc
{
	[_window release];
	[_viewController release];
	[super dealloc];
}

@end

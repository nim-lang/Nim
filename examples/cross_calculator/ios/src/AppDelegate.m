#import "AppDelegate.h"

#import "backend.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
	[_window release];
	[super dealloc];
}

- (BOOL)application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen]
		bounds]] autorelease];
	// Override point for customization after application launch.
	self.window.backgroundColor = [UIColor whiteColor];
	[self.window makeKeyAndVisible];

	// Call nimrod code and store the result.
	const int a = 3;
	const int b = 12;
	const int c = myAdd(a, b);

	// Add a label to show the results of the computation made by nimrod.
	UILabel *label = [[UILabel alloc] initWithFrame:self.window.bounds];
	label.textAlignment = UITextAlignmentCenter;
	label.text = [NSString stringWithFormat:@"myAdd(%d, %d) = %d", a, b, c];
	[self.window addSubview:label];
	[label release];

	return YES;
}

@end

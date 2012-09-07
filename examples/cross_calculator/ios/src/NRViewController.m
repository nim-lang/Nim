#import "NRViewController.h"

#import "backend.h"


@implementation NRViewController

@synthesize aText = _aText;
@synthesize bText = _bText;
@synthesize calculateButton = _calculateButton;
@synthesize resultLabel = _resultLabel;

/** We need no special custom initialization for this example.
 * Note that this example project has been made to deploy only on iOS 4.x
 * upwards because the currently available Xcode tools are incapable of
 * generating iOS 3.x backwards compatible NIB files. If your device is 3.x
 * only you can replace the NIM with UI construction in code and everything
 * else should be fine.
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)dealloc
{
	[_aText release];
	[_bText release];
	[_calculateButton release];
	[_resultLabel release];
	[super dealloc];
}

- (void)viewDidUnload
{
	self.calculateButton = nil;
	self.aText = nil;
	self.bText = nil;
	self.resultLabel = nil;
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/// User wants to calculate the inputs. Well, do it!
- (IBAction)calculateButtonTouched
{
	// Dismiss all keyboards.
	[self backgroundTouched];

	// Call nimrod code, store the result and display it.
	const int a = [self.aText.text intValue];
	const int b = [self.bText.text intValue];
	const int c = myAdd(a, b);
	self.resultLabel.text = [NSString stringWithFormat:@"%d + %d = %d",
		a, b, c];
}

/// If the user touches the background, dismiss any visible keyboard.
- (IBAction)backgroundTouched
{
	[self.aText resignFirstResponder];
	[self.bText resignFirstResponder];
}

@end

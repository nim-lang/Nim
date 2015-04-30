#import "NRViewController.h"

#import "backend.h"


@implementation NRViewController

@synthesize aText = _aText;
@synthesize bText = _bText;
@synthesize calculateButton = _calculateButton;
@synthesize resultLabel = _resultLabel;

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

	// Call Nim code, store the result and display it.
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

/** Custom loadView method for backwards compatibility.
 * Unfortunately I've been unable to coerce Xcode 4.4 to generate nib files
 * which are compatible with my trusty iOS 3.0 ipod touch so in order to be
 * fully compatible for all devices we have to build the interface manually in
 * code rather than through the keyed archivers provided by the interface
 * builder.
 *
 * Rather than recreating the user interface manually in code the tool nib2obj
 * was used on the xib file and slightly modified to fit the original property
 * names. Which means here is a lot of garbage you would never write in real
 * life. Please ignore the following "wall of code" for the purposes of
 * learning Nim, this is all just because Apple can't be bothered to
 * maintain backwards compatibility properly.
 */
- (void)loadView
{
	[super loadView];

	self.calculateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	self.calculateButton.autoresizesSubviews = YES;
	self.calculateButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	self.calculateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	self.calculateButton.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	self.calculateButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.calculateButton.frame = CGRectMake(193.0, 124.0, 107.0, 37.0);
	self.calculateButton.tag = 5;
	[self.calculateButton setTitle:@"Add!" forState:UIControlStateNormal];
	[self.calculateButton addTarget:self
		action:@selector(calculateButtonTouched)
		forControlEvents:UIControlEventTouchUpInside];

	UILabel *label11 = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 124.0, 60.0, 37.0)];
	label11.adjustsFontSizeToFitWidth = YES;
	label11.autoresizesSubviews = YES;
	label11.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	label11.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	label11.frame = CGRectMake(20.0, 124.0, 60.0, 37.0);
	label11.tag = 6;
	label11.text = @"Result:";

	UILabel *label4 = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 34.0)];
	label4.adjustsFontSizeToFitWidth = YES;
	label4.autoresizesSubviews = YES;
	label4.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
	label4.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	label4.frame = CGRectMake(0.0, 0.0, 320.0, 34.0);
	label4.tag = 2;
	label4.text = @"Nim Crossplatform Calculator";
	label4.textAlignment = UITextAlignmentCenter;

	UIButton *background_button = [UIButton buttonWithType:UIButtonTypeCustom];
	background_button.autoresizesSubviews = YES;
	background_button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	background_button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	background_button.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	background_button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	background_button.frame = CGRectMake(0.0, -10.0, 320.0, 480.0);
	background_button.tag = 1;
	[background_button addTarget:self action:@selector(backgroundTouched)
		forControlEvents:UIControlEventTouchDown];

	self.resultLabel = [[[UILabel alloc] initWithFrame:CGRectMake(88.0, 124.0, 97.0, 37.0)] autorelease];
	self.resultLabel.adjustsFontSizeToFitWidth = YES;
	self.resultLabel.autoresizesSubviews = YES;
	self.resultLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	self.resultLabel.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	self.resultLabel.frame = CGRectMake(88.0, 124.0, 97.0, 37.0);
	self.resultLabel.tag = 7;
	self.resultLabel.text = @"";

	self.aText = [[[UITextField alloc] initWithFrame:CGRectMake(193.0, 42.0, 107.0, 31.0)] autorelease];
	self.aText.adjustsFontSizeToFitWidth = YES;
	self.aText.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.aText.autocorrectionType = UITextAutocorrectionTypeDefault;
	self.aText.autoresizesSubviews = YES;
	self.aText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	self.aText.borderStyle = UITextBorderStyleRoundedRect;
	self.aText.clearButtonMode = UITextFieldViewModeWhileEditing;
	self.aText.clearsOnBeginEditing = NO;
	self.aText.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	self.aText.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	self.aText.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.aText.enablesReturnKeyAutomatically = NO;
	self.aText.frame = CGRectMake(193.0, 42.0, 107.0, 31.0);
	self.aText.keyboardAppearance = UIKeyboardAppearanceDefault;
	self.aText.keyboardType = UIKeyboardTypeNumberPad;
	self.aText.placeholder = @"Integer";
	self.aText.returnKeyType = UIReturnKeyDefault;
	self.aText.tag = 8;
	self.aText.text = @"";
	self.aText.textAlignment = UITextAlignmentCenter;

	UILabel *label7 = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 42.0, 165.0, 31.0)];
	label7.adjustsFontSizeToFitWidth = YES;
	label7.autoresizesSubviews = YES;
	label7.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	label7.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	label7.frame = CGRectMake(20.0, 42.0, 165.0, 31.0);
	label7.tag = 3;
	label7.text = @"Value A:";

	UILabel *label8 = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 81.0, 165.0, 31.0)];
	label8.adjustsFontSizeToFitWidth = YES;
	label8.autoresizesSubviews = YES;
	label8.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	label8.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	label8.frame = CGRectMake(20.0, 81.0, 165.0, 31.0);
	label8.tag = 4;
	label8.text = @"Value B:";

	self.bText = [[[UITextField alloc]
		initWithFrame:CGRectMake(193.0, 81.0, 107.0, 31.0)] autorelease];
	self.bText.adjustsFontSizeToFitWidth = YES;
	self.bText.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.bText.autocorrectionType = UITextAutocorrectionTypeDefault;
	self.bText.autoresizesSubviews = YES;
	self.bText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	self.bText.borderStyle = UITextBorderStyleRoundedRect;
	self.bText.clearButtonMode = UITextFieldViewModeWhileEditing;
	self.bText.clearsOnBeginEditing = NO;
	self.bText.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	self.bText.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	self.bText.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.bText.enablesReturnKeyAutomatically = NO;
	self.bText.frame = CGRectMake(193.0, 81.0, 107.0, 31.0);
	self.bText.keyboardAppearance = UIKeyboardAppearanceDefault;
	self.bText.keyboardType = UIKeyboardTypeNumberPad;
	self.bText.placeholder = @"Integer";
	self.bText.returnKeyType = UIReturnKeyDefault;
	self.bText.tag = 9;
	self.bText.text = @"";
	self.bText.textAlignment = UITextAlignmentCenter;

	self.view.frame = CGRectMake(0.0, 20.0, 320.0, 460.0);
	self.view.autoresizesSubviews = YES;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor colorWithWhite:1.000 alpha:1.000];
	self.view.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	self.view.frame = CGRectMake(0.0, 20.0, 320.0, 460.0);
	self.view.tag = 0;

	[self.view addSubview:background_button];
	[self.view addSubview:label4];
	[self.view addSubview:label7];
	[self.view addSubview:label8];
	[self.view addSubview:self.calculateButton];
	[self.view addSubview:label11];
	[self.view addSubview:self.resultLabel];
	[self.view addSubview:self.aText];
	[self.view addSubview:self.bText];
}

@end

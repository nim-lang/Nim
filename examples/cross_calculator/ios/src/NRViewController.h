@interface NRViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton *calculateButton;
@property (nonatomic, retain) IBOutlet UITextField *aText;
@property (nonatomic, retain) IBOutlet UITextField *bText;
@property (nonatomic, retain) IBOutlet UILabel *resultLabel;

- (IBAction)calculateButtonTouched;
- (IBAction)backgroundTouched;

@end
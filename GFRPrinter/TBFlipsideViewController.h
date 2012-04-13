#import <UIKit/UIKit.h>

@class TBFlipsideViewController;

@protocol TBFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(TBFlipsideViewController *)controller;
@end

@interface TBFlipsideViewController : UIViewController

@property (weak, nonatomic) id <TBFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *printerId;
@property (weak, nonatomic) IBOutlet UITextField *host;
@property (weak, nonatomic) IBOutlet UITextField *checkInterval;

@end

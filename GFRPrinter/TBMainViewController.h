#import "TBFlipsideViewController.h"
#import "TBImageFetcher.h"

@interface TBMainViewController : UIViewController <TBFlipsideViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, TBImageFetcherDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIImageView *greenLED;

- (IBAction)linefeed:(id)sender;
@end

#import "TBFlipsideViewController.h"
#import "TBImageFetcher.h"

@interface TBMainViewController : UIViewController <TBFlipsideViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, TBImageFetcherDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)linefeed:(id)sender;
@end

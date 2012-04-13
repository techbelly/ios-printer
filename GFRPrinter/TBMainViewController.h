#import "TBFlipsideViewController.h"

@interface TBMainViewController : UIViewController <TBFlipsideViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *messages;
- (IBAction)linefeed:(id)sender;
@end

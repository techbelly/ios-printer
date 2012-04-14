#import "TBMainViewController.h"
#import "TBDefaults.h"
#import "TBTableViewCell.h"
#import "TBImageFetcher.h"

@interface TBMainViewController ()

@property NSTimer *poller;
@property (strong, nonatomic) UIAlertView *alert;
@property (strong, nonatomic) NSMutableSet *fetchers;
@property (strong, nonatomic) NSMutableArray *messages;

@end

@implementation TBMainViewController

@synthesize tableView = _tableView;
@synthesize greenLED = _greenLED;
@synthesize messages = _messages;
@synthesize poller = _poller;
@synthesize alert = _alert;
@synthesize fetchers = _fetchers;

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.messages = [NSMutableArray array];
    self.fetchers = [NSMutableSet set];
    self.greenLED.animationImages = [NSArray arrayWithObjects:
                                     [UIImage imageNamed:@"green-on-128.png"],
                                     [UIImage imageNamed:@"green-off-128.png"],
                                     nil];
    self.greenLED.animationDuration = 0.8;
                                     
    [self startPolling];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setGreenLED:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark - UITableView delegate/datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    TBTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"];
    if (cell == nil) {
        cell = [[TBTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MessageCell"];
    }
    cell.image.image = [self.messages objectAtIndex:indexPath.row];    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *image = [self.messages objectAtIndex:indexPath.row];
    return (300.0/image.size.width)*image.size.height;
}

#pragma mark - TBImageFetcherDelegate

- (void)loadingStopped:(TBImageFetcher *)fetcher
{
    [self.greenLED stopAnimating];
    [self.fetchers removeObject:fetcher];
}

- (void)imageFetcher:(TBImageFetcher *)fetcher didSucceedWithImage:(UIImage *)image
{
    [self loadingStopped:fetcher];
    [self.messages insertObject:image atIndex:0];
    NSArray *array = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationTop];
}

- (void)imageFetcher:(TBImageFetcher *)fetcher didFailWithError:(NSError *)error
{
    [self loadingStopped:fetcher];

    NSString *message = [NSString stringWithFormat:@"Connection failed! Error - %@ %@",
                         [error localizedDescription],
                         [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
    self.alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [self.alert show];
}

- (void)imageFetcherDidSucceed:(TBImageFetcher *)fetcher
{
    [self loadingStopped:fetcher];
}

#pragma mark - TBFlipsideViewControllerDelegate

- (void)flipsideViewControllerDidFinish:(TBFlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
    [self startPolling];
}

#pragma mark - IBActions

- (IBAction)linefeed:(id)sender {
    [self.messages insertObject:[UIImage imageNamed:@"noise"] atIndex:0];
    NSArray *array = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationTop];       
}

#pragma mark - 
- (void)startPolling
{
    TBDefaults *defaults = [TBDefaults sharedDefaults];
    if (defaults.printerId && defaults.printerId.length > 0) {
        [self.poller invalidate];
        [self poll];
        NSTimeInterval interval = defaults.checkInterval;
        self.poller = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(poll) userInfo:nil repeats:YES];
    }
}

- (void)poll 
{
    TBDefaults *defaults = [TBDefaults sharedDefaults];
    TBImageFetcher *fetcher = [[TBImageFetcher alloc] init];
    fetcher.delegate = self;
    [self.greenLED startAnimating];
    [fetcher fetchImageForPrinter:defaults.printerId fromHost:defaults.host];
    [self.fetchers addObject:fetcher];
}


@end

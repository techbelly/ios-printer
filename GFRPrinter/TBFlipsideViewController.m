#import "TBFlipsideViewController.h"
#import "TBDefaults.h"

@interface TBFlipsideViewController ()

@end

@implementation TBFlipsideViewController
@synthesize printerId = _printerId;
@synthesize host = _host;
@synthesize checkInterval = _checkInterval;

@synthesize delegate = _delegate;



- (void)viewDidLoad
{
    [super viewDidLoad];
    TBDefaults *defaults = [TBDefaults sharedDefaults];
    self.host.text = defaults.host;
    self.printerId.text = defaults.printerId;
    int checkinterval = defaults.checkInterval;
    NSString *interval = [NSString stringWithFormat:@"%d",checkinterval];
    self.checkInterval.text = interval;
}

- (void)viewDidUnload
{
    [self setPrinterId:nil];
    [self setHost:nil];
    [self setCheckInterval:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)randomizeId:(id)sender {
    
    char printerId[17];
    for(int i = 0; i < 16; i += 2) {
        printerId[i] =  (arc4random()%10)+48;  // 0-9
        printerId[i+1] = (arc4random()%26)+97; // a-z
    }
    printerId[16] = '\0';
    NSString *str = [NSString stringWithCString:printerId encoding:NSASCIIStringEncoding];
    self.printerId.text = str;
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    TBDefaults *defaults = [TBDefaults sharedDefaults];
    defaults.host = self.host.text;
    defaults.printerId = self.printerId.text;
    defaults.checkInterval = [self.checkInterval.text intValue];
    
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end

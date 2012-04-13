#import "TBMainViewController.h"
#import "TBDefaults.h"
#import "TBTableViewCell.h"

@interface TBMainViewController ()

@property NSTimer *poller;
@property NSMutableData *download;
@property BOOL loading;
@property (strong, nonatomic) UIAlertView * alert;
@end

@implementation TBMainViewController

@synthesize tableView = _tableView;
@synthesize messages = _messages;
@synthesize poller = _poller;
@synthesize loading = _loading;
@synthesize download = _download;
@synthesize alert = _alert;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *image = [self.messages objectAtIndex:indexPath.row];
    return (300.0/image.size.width)*image.size.height;
}

- (UIImage *)imageFromData:(NSData *)data
{
    union {
        char   c [4];
        uint16_t  d[2];
    } unpack;
    const char * bytes = [data bytes];
    memcpy(unpack.c, bytes, sizeof unpack.c);
    
    uint16_t width = unpack.d[0];
    uint16_t height = unpack.d[1];
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger pixelsNeeded = height * bytesPerRow;
    
    unsigned char *rawData = malloc(pixelsNeeded);
    memset(rawData,255,pixelsNeeded);
    
    NSUInteger bitsPerComponent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(rawData, (float) width, (float) height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    
    int count = [data length];
    int rawDataIdx; 
    char byte;
    int rawBitIdx;
    
    for (int i = 0; i < count-4; ++i) {
        rawDataIdx = i*bytesPerPixel*bitsPerComponent;
        byte = bytes[i+4];
        for (int bit = 0; bit < 8; ++bit) {
            rawBitIdx = bit * bytesPerPixel;
            if ((byte & (1 << (7 - bit))) > 0) {
                rawData[rawDataIdx+rawBitIdx] =   0;
                rawData[rawDataIdx+rawBitIdx+1] = 0;
                rawData[rawDataIdx+rawBitIdx+2] = 0;
                rawData[rawDataIdx+rawBitIdx+3] = 255;
            }
        }
    }
    
    CGImageRef cgimage = CGBitmapContextCreateImage(context); 
    UIImage *image =  [UIImage imageWithCGImage:cgimage scale:1.0 orientation:UIImageOrientationDown];
    free(rawData);
    return image;
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

- (void) pollIfConfigured
{
    TBDefaults *defaults = [TBDefaults sharedDefaults];
    if (defaults.printerId && defaults.printerId.length > 0) {
        [self.poller invalidate];
        [self poll];
        NSTimeInterval interval = defaults.checkInterval;
        self.poller = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(poll) userInfo:nil repeats:YES];
    }
}

- (void) poll 
{
    if (!self.loading) {
        self.loading = YES;
        TBDefaults *defaults = [TBDefaults sharedDefaults];
        NSString *url = [NSString stringWithFormat:@"%@/printer/%@",defaults.host,defaults.printerId];
    
        NSMutableURLRequest *theRequest= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        [theRequest setValue:@"application/vnd.freerange.printer.A2-bitmap" forHTTPHeaderField:@"Accept"];
    
        NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
        if (theConnection) {
            self.download = [NSMutableData data];
        } else {
            self.loading = NO;
            self.alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.download appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    self.loading = NO;
    NSString *message = [NSString stringWithFormat:@"Connection failed! Error - %@ %@",
                         [error localizedDescription],
                         [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
    self.alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.download length] > 0) {
        UIImage *image = [self imageFromData:self.download];
        [self.messages insertObject:image atIndex:0];
        [self.tableView reloadData];
    }
    self.loading = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.messages = [NSMutableArray array];
    [self pollIfConfigured];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void)flipsideViewControllerDidFinish:(TBFlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
    [self pollIfConfigured];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

@end

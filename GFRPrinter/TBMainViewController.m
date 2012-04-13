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

- (void)lightpixel:(unsigned char *)data at:(int)start
{
    data[start] =   255 -  (arc4random()%20);
    data[start+1] = 255 -  (arc4random()%20);
    data[start+2] = 255 -  (arc4random()%20);
    data[start+3] = 255;
}

- (void)darkpixel:(unsigned char *)data at:(int)start
{
    data[start]   =   (arc4random()%20);
    data[start+1] =   (arc4random()%20);
    data[start+2] =   (arc4random()%20);
    data[start+3] = 255;
}

- (UIImage *)imageFromData:(NSData *)data
{
    union {
        char      bytes [4];
        uint16_t  values[2];
    } header;
    
    const char * bytes = [data bytes];
    int src_headerSize = sizeof header.bytes;
    memcpy(header.bytes, bytes, src_headerSize);
    uint16_t src_width  = header.values[0];
    uint16_t src_height = header.values[1];
    
    int src_bitsPerPixel = 8;
    
    int dest_padding = 40;
    
    int dest_width =  (src_width  + dest_padding);
    int dest_height = (src_height + dest_padding);
    
    int dest_bytesPerPixel = 4;
    int dest_bytesPerRow = dest_bytesPerPixel * dest_width;
    int dest_bytesNeeded = dest_height * dest_bytesPerRow;

    unsigned char *dest = malloc(dest_bytesNeeded);

    // make the background all papery.
    for(int i = 0; i < dest_bytesNeeded; i += 4) {
        [self lightpixel:dest at:i];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    int dest_bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(dest, 
                                                 (float) dest_width, 
                                                 (float) dest_height,
                                                 dest_bitsPerComponent,
                                                 dest_bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    
    char byte;
    int padded_column, padded_row, src_index, dest_index;
    
    // next two lines are the crux of it. src has many pixels per byte,
    // and dest has many bytes per pixel. Ho hum.
    int src_rowsize =  (src_width/src_bitsPerPixel);
    int dest_rowsize = dest_width * dest_bytesPerPixel;

    int dest_src_offset = dest_padding/2;
    
    for (int row = 0; row < src_height; row ++) {
        for (int column = 0; column < src_width; column ++) {

            src_index = (column/src_bitsPerPixel) + (row * src_rowsize) + src_headerSize;
            byte = bytes[src_index];

            padded_column = column + dest_src_offset;
            padded_row    = row    + dest_src_offset;
            
            dest_index = padded_column * dest_bytesPerPixel + padded_row * dest_rowsize;
                        
            int bit = (column % 8);
            if ((byte & (1 << (7 - bit))) > 0) {
                [self darkpixel:dest at:dest_index];
            } 
        }
    }
    
    CGImageRef cgimage = CGBitmapContextCreateImage(context); 
    UIImage *image =  [UIImage imageWithCGImage:cgimage scale:1.0 orientation:UIImageOrientationDown];
    free(dest);
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

- (IBAction) pollIfConfigured
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
        NSArray *array = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationTop];       
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

- (IBAction)linefeed:(id)sender {
    [self.messages insertObject:[UIImage imageNamed:@"noise"] atIndex:0];
    NSArray *array = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationTop];       
}
@end

#import "TBImageFetcher.h"

@interface TBImageFetcher ()
    @property NSMutableData *download;
@end

@implementation TBImageFetcher

@synthesize download = _download;
@synthesize delegate = _delegate;

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
    
    // Parse the header to get height and width
    union {
        char      bytes [4];
        uint16_t  values[2];
    } header;
    
    const char * bytes = [data bytes];
    int src_headerSize = sizeof header.bytes;
    memcpy(header.bytes, bytes, src_headerSize);
    
    uint16_t src_width  = header.values[0];
    uint16_t src_height = header.values[1];
    
    int src_pixelsPerByte = 8;
    
    // Create the destination byte array
    
    int dest_padding = 40;
    
    int dest_width =  src_width  + dest_padding;
    int dest_height = src_height + dest_padding;
    
    int dest_bytesPerPixel = 4;
    
    // (next two lines are the crux of it. src has many pixels per byte,
    // and dest has many bytes per pixel. Ho hum.)
    int src_bytesPerRow =  src_width  / src_pixelsPerByte;
    int dest_bytesPerRow = dest_bytesPerPixel * dest_width;
    
    int dest_bytesNeeded = dest_bytesPerRow   * dest_height;
    
    unsigned char *dest = malloc(dest_bytesNeeded);
    
    // make the background all papery.
    for(int i = 0; i < dest_bytesNeeded; i += 4) {
        [self lightpixel:dest at:i];
    }
    
    
    // write the src bits into the dest array
    
    char byte;
    int src_bytesAcross, dest_bytesAcross, src_bytesDown , dest_bytesDown;
    
    int dest_topPadding = dest_padding/2;
    int dest_leftPadding = dest_padding/2;
    
    for (int pixelsDown = 0; pixelsDown < src_height; pixelsDown ++) {
        
        src_bytesDown  = pixelsDown * src_bytesPerRow + src_headerSize;
        dest_bytesDown = (pixelsDown + dest_topPadding) * dest_bytesPerRow;
        
        for (int pixelsAcross = 0; pixelsAcross < src_width; pixelsAcross ++) {
            
            src_bytesAcross = pixelsAcross / src_pixelsPerByte;
            byte = bytes[src_bytesDown + src_bytesAcross];
            
            int bit = (pixelsAcross % 8);
            if ((byte & (1 << (7 - bit))) > 0) {            
                dest_bytesAcross = (pixelsAcross + dest_leftPadding) * dest_bytesPerPixel;
                [self darkpixel:dest at:dest_bytesDown + dest_bytesAcross];
            } 
        }
    }
    
    // make a UIImage out of it.
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    int dest_bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(dest, 
                                                 (float) dest_width, 
                                                 (float) dest_height,
                                                 dest_bitsPerComponent,
                                                 dest_bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    
    CGImageRef cgimage = CGBitmapContextCreateImage(context); 
    UIImage *image =  [UIImage imageWithCGImage:cgimage scale:1.0 orientation:UIImageOrientationDown];
    
    // tidy up and go home.
    CGImageRelease(cgimage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(dest);
    
    return image;
}


- (void)fetchImageForPrinter:(NSString *)printerId fromHost:(NSString *)host
{
    NSString *url = [NSString stringWithFormat:@"%@/printer/%@",host,printerId];
    
    NSMutableURLRequest *theRequest= [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [theRequest setValue:@"application/vnd.freerange.printer.A2-bitmap" forHTTPHeaderField:@"Accept"];
    
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    if (theConnection) {
        self.download = [NSMutableData data];
    } else {
        NSError *error = [NSError errorWithDomain:@"ConnectionFailed" code:0 userInfo:nil];
        [self.delegate imageFetcher:self didFailWithError:error];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.download appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    [self.delegate imageFetcher:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.download length] > 0) {
        UIImage *image = [self imageFromData:self.download];
        [self.delegate imageFetcher:self didSucceedWithImage:image];
    }
}

@end

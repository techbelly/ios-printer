#import "TBDefaults.h"

@implementation TBDefaults

static TBDefaults* sharedTB;

+ (id)sharedDefaults {
    @synchronized(self) {
        if (sharedTB == nil)
            sharedTB = [[self alloc] init];
    }
    return sharedTB;
}

- (NSString *)printerId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"printerId"];
}

- (NSString *)host
{
    NSString *host = [[NSUserDefaults standardUserDefaults] objectForKey:@"host"];
    if (host) {
        return host;
    } else {
        return @"http://printer.gofreerange.com";
    }
}

- (NSTimeInterval)checkInterval
{
    int checkInterval =  [[NSUserDefaults standardUserDefaults] integerForKey:@"checkinterval"];
    if (checkInterval < 10) {
        return 10;
    } else {
        return checkInterval;
    }
}

- (void)setPrinterId:(NSString *)printerId
{
    [[NSUserDefaults standardUserDefaults] setValue:printerId forKey:@"printerId"];
}

- (void)setHost:(NSString *)host
{
     [[NSUserDefaults standardUserDefaults] setValue:host forKey:@"host"];
}


- (void)setCheckInterval:(NSTimeInterval)checkinterval
{
    [[NSUserDefaults standardUserDefaults] setInteger:checkinterval forKey:@"checkinterval"];
}
@end

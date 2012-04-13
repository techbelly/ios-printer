#import <Foundation/Foundation.h>

@interface TBDefaults : NSObject

+ (id)sharedDefaults;

@property (nonatomic,retain) NSString *printerId;
@property (nonatomic,retain) NSString *host;
@property NSTimeInterval checkInterval;

@end

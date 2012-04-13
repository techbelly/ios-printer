#import <Foundation/Foundation.h>

@protocol TBImageFetcherDelegate;

@interface TBImageFetcher : NSObject <NSURLConnectionDelegate>

@property (weak, nonatomic) id<TBImageFetcherDelegate> delegate;

- (void)fetchImageForPrinter:(NSString *)printerId fromHost:(NSString *)host;
@end

@protocol TBImageFetcherDelegate
- (void)imageFetcher:(TBImageFetcher *)fetcher didSucceedWithImage:(UIImage *)image;
- (void)imageFetcher:(TBImageFetcher *)fetcher didFailWithError:(NSError *)error;
@end
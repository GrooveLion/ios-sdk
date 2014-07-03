#import "GLETest_faketp.h"

static void (^startLoadingBlock)(NSURLProtocol *);
static void (^stopLoadingBlock)(NSURLProtocol *);

@implementation GLETest_faketp

+(void)setStartLoadingBlock:(void (^)(NSURLProtocol *))_startLoadingBLock
{
    startLoadingBlock = [_startLoadingBLock copy];
}

+(void)setStopLoadingBlock:(void (^)(NSURLProtocol *))_stopLoadingBLock
{
    stopLoadingBlock = [_stopLoadingBLock copy];
}

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [request.URL.scheme isEqualToString:@"faketp"];
}

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

-(void)startLoading
{
    if (startLoadingBlock)
        startLoadingBlock(self);
}

-(void)stopLoading
{
    if (stopLoadingBlock)
        stopLoadingBlock(self);
}

@end

#import <Foundation/Foundation.h>

@interface GLETest_faketp : NSURLProtocol

+(void)setStartLoadingBlock:(void (^)(NSURLProtocol *))startLoadingBLock;
+(void)setStopLoadingBlock:(void (^)(NSURLProtocol *))stopLoadingBLock;

@end

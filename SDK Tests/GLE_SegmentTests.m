#import "GLE_Tests.h"

@interface GLE_SegmentTests : GLE_Tests

@end

@implementation GLE_SegmentTests

- (void)testRegistrationWithSegment
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    NSDictionary __block *sentDictionary = nil;
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         NSError *error = nil;
         NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:protocol.request.HTTPBody options:0 error:&error];
         if (error || !dictionary)
         {
             if (!error)
                 error = [NSError errorWithDomain:@"Testing" code:0 userInfo:nil];
             [protocol.client URLProtocol:protocol didFailWithError:error];
         }
         else
         {
             sentDictionary = dictionary;
             [protocol.client URLProtocol:protocol didReceiveResponse:[[NSURLResponse alloc] initWithURL:protocol.request.URL MIMEType:@"text/plain" expectedContentLength:0 textEncodingName:@"utf-8"] cacheStoragePolicy:NSURLCacheStorageNotAllowed];
             [protocol.client URLProtocolDidFinishLoading:protocol];
         }
         dispatch_semaphore_signal(sem);
     }
     ];
    [push setSegmentSubscription:[[GLESegment alloc] initWithName:@"segment" tags:@[@"tag"]]];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [self checkRegistration:sentDictionary];
    [self checkRegistration:sentDictionary containsSegment:@"segment" tags:@[@"tag"]];
    
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testReRegistrationForChangedSegment
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    NSDictionary __block *sentDictionary = nil;
    
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         NSError *error = nil;
         NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:protocol.request.HTTPBody options:0 error:&error];
         if (error || !dictionary)
         {
             if (!error)
                 error = [NSError errorWithDomain:@"Testing" code:0 userInfo:nil];
             [protocol.client URLProtocol:protocol didFailWithError:error];
         }
         else
         {
             sentDictionary = dictionary;
             [protocol.client URLProtocol:protocol didReceiveResponse:[[NSURLResponse alloc] initWithURL:protocol.request.URL MIMEType:@"text/plain" expectedContentLength:0 textEncodingName:@"utf-8"] cacheStoragePolicy:NSURLCacheStorageNotAllowed];
             [protocol.client URLProtocolDidFinishLoading:protocol];
         }
         dispatch_semaphore_signal(sem);
     }
     ];        [push setSegmentSubscription:[[GLESegment alloc] initWithName:@"segment" tags:@[@"oldtag"]]];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [self checkRegistration:sentDictionary];
    [self checkRegistration:sentDictionary containsSegment:@"segment" tags:@[@"oldtag"]];
    
    [push setSegmentSubscription:[[GLESegment alloc] initWithName:@"segment" tags:@[@"tag"]]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    
    [self checkRegistration:sentDictionary];
    [self checkRegistration:sentDictionary containsSegment:@"segment" tags:@[@"tag"]];
    [GLETest_faketp setStartLoadingBlock:nil];
}
@end

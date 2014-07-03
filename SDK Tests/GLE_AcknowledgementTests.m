#import "GLE_Tests.h"

@interface GLE_AcknowledgementTests : GLE_Tests

@end

@implementation GLE_AcknowledgementTests

-(void)checkAcknowledgement:(NSDictionary *)sentDictionary
{
    XCTAssertEqualObjects(sentDictionary[@"id"], @"1337", @"Wrong message Id");
    XCTAssertEqualObjects(sentDictionary[@"appBundleId"], @"test.bundle", @"Wrong bundle id");
    XCTAssertEqualObjects(sentDictionary[@"environment"], @"production", @"Wrong environment code");
    XCTAssertEqualObjects(sentDictionary[@"appPlatform"], @"iOS", @"Wrong platform");
    XCTAssertEqualObjects(sentDictionary[@"token"], @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", @"Wrong token");
    XCTAssertTrue([sentDictionary[@"time"] isKindOfClass:[NSNumber class]], @"Time not present or not a number");
}

- (void)testAcknowledgeMessageWhileRunning
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    NSDictionary __block *sentDictionary = nil;
    NSURL __block *toURL = nil;
    
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         NSError *error = nil;
         NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:protocol.request.HTTPBody options:0 error:&error];
         toURL = [protocol.request.URL copy];
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
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [push application:[UIApplication sharedApplication] didReceiveRemoteNotification:@{@"m":@"1337"}];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    [self checkAcknowledgement:sentDictionary];
    XCTAssertEqualObjects(toURL, [NSURL URLWithString:@"faketp://fake.com/fake/opened/"], @"Wrong acknowledgement URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testDoesntAcknowledgeWithMissingMessageIdWhileRunning
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         [protocol.client URLProtocol:protocol didReceiveResponse:[[NSURLResponse alloc] initWithURL:protocol.request.URL MIMEType:@"text/plain" expectedContentLength:0 textEncodingName:@"utf-8"] cacheStoragePolicy:NSURLCacheStorageNotAllowed];
         [protocol.client URLProtocolDidFinishLoading:protocol];
         dispatch_semaphore_signal(sem);
     }
     ];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [push application:[UIApplication sharedApplication] didReceiveRemoteNotification:@{}];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV != 0, @"Semaphore should have timed out; didn't");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testAcknowledgeMessageWithHandler
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    NSDictionary __block *sentDictionary = nil;
    NSURL __block *toURL = nil;
    
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         NSError *error = nil;
         NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:protocol.request.HTTPBody options:0 error:&error];
         toURL = [protocol.request.URL copy];
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
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [push application:[UIApplication sharedApplication] didReceiveRemoteNotification:@{@"m":@"1337"} fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    [self checkAcknowledgement:sentDictionary];
    XCTAssertEqualObjects(toURL, [NSURL URLWithString:@"faketp://fake.com/fake/opened/"], @"Wrong acknowledgement URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testDoesntAcknowledgeWithMissingMessageIdWithHandler
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         [protocol.client URLProtocol:protocol didReceiveResponse:[[NSURLResponse alloc] initWithURL:protocol.request.URL MIMEType:@"text/plain" expectedContentLength:0 textEncodingName:@"utf-8"] cacheStoragePolicy:NSURLCacheStorageNotAllowed];
         [protocol.client URLProtocolDidFinishLoading:protocol];
         dispatch_semaphore_signal(sem);
     }
     ];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [push application:[UIApplication sharedApplication] didReceiveRemoteNotification:@{} fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV != 0, @"Semaphore should have timed out; didn't");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testAcknowledgeMessageAtStartup
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    NSDictionary __block *sentDictionary = nil;
    NSURL __block *toURL = nil;
    
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         NSError *error = nil;
         NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:protocol.request.HTTPBody options:0 error:&error];
         toURL = [protocol.request.URL copy];
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
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [push application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:@{UIApplicationLaunchOptionsRemoteNotificationKey: @{@"m":@"1337"}}];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    [self checkAcknowledgement:sentDictionary];
    XCTAssertEqualObjects(toURL, [NSURL URLWithString:@"faketp://fake.com/fake/opened/"], @"Wrong acknowledgement URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testDoesntAcknowledgeWithMissingMessageIdAtStartup
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         [protocol.client URLProtocol:protocol didReceiveResponse:[[NSURLResponse alloc] initWithURL:protocol.request.URL MIMEType:@"text/plain" expectedContentLength:0 textEncodingName:@"utf-8"] cacheStoragePolicy:NSURLCacheStorageNotAllowed];
         [protocol.client URLProtocolDidFinishLoading:protocol];
         dispatch_semaphore_signal(sem);
     }
     ];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [push application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:@{UIApplicationLaunchOptionsRemoteNotificationKey: @{}}];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV != 0, @"Semaphore should have timed out; didn't");
    [GLETest_faketp setStartLoadingBlock:nil];
}

@end

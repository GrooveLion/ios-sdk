#import "GLE_Tests.h"

@interface GLE_CustomerIdTests : GLE_Tests

@end

@implementation GLE_CustomerIdTests

- (void)testCustomerIdNotPresent
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    NSDictionary __block *sentDictionary = nil;
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
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
    [GLETest_faketp setStartLoadingBlock:nil];
    [self checkRegistration:sentDictionary];
    XCTAssertNil(sentDictionary[@"customerId"], @"Unexpected customerId present");
    XCTAssertEqualObjects(toURL, [NSURL URLWithString:@"faketp://fake.com/fake/register"], @"Wrong registration URL");
}

- (void)testCustomerIdSentWhenSpecified
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    NSDictionary __block *sentDictionary = nil;
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
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
    [push setCustomerId:@"tinky-winky"];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [GLETest_faketp setStartLoadingBlock:nil];
    [self checkRegistration:sentDictionary];
    XCTAssertEqualObjects(sentDictionary[@"customerId"], @"tinky-winky", @"Expected customerId not present");
    XCTAssertEqualObjects(toURL, [NSURL URLWithString:@"faketp://fake.com/fake/register"], @"Wrong registration URL");
}

- (void)testSingleRegistrationForUnchangedCustomerId
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
    [push setCustomerId:@"tinky-winky"];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [push setCustomerId:@"tinky-winky"];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV != 0, @"Semaphore should have timed out; didn't");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testReRegistrationForChangedCustomerId
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    long semRV;
    static dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(1);
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    NSURL __block *toURL = nil;
    
    [GLETest_faketp setStartLoadingBlock:^(NSURLProtocol *protocol)
     {
         toURL = [protocol.request.URL copy];
         [protocol.client URLProtocol:protocol didReceiveResponse:[[NSURLResponse alloc] initWithURL:protocol.request.URL MIMEType:@"text/plain" expectedContentLength:0 textEncodingName:@"utf-8"] cacheStoragePolicy:NSURLCacheStorageNotAllowed];
         [protocol.client URLProtocolDidFinishLoading:protocol];
         dispatch_semaphore_signal(sem);
     }
     ];
    [push setCustomerId:@"tinky-winky"];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    XCTAssertEqualObjects(toURL, [NSURL URLWithString:@"faketp://fake.com/fake/register"], @"Wrong registration URL");
    [push setCustomerId:@"dipsy"];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    XCTAssertEqualObjects(toURL, [NSURL URLWithString:@"faketp://fake.com/fake/register"], @"Wrong registration URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}


@end

#import "GLE_Tests.h"

@interface GLE_LocationTests : GLE_Tests

@end

@implementation GLE_LocationTests

-(void)checkLocation:(NSDictionary *)sentDictionary matches:(CLLocationCoordinate2D)coordinate
{
    XCTAssertEqualObjects(sentDictionary[@"lat"], @(coordinate.latitude), @"Wrong latitude");
    XCTAssertEqualObjects(sentDictionary[@"lon"], @(coordinate.longitude), @"Wrong longitude");
    XCTAssertEqualObjects(sentDictionary[@"appBundleId"], @"test.bundle", @"Wrong bundle id");
    XCTAssertEqualObjects(sentDictionary[@"environment"], @"production", @"Wrong environment code");
    XCTAssertEqualObjects(sentDictionary[@"appPlatform"], @"iOS", @"Wrong platform");
    XCTAssertEqualObjects(sentDictionary[@"token"], @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", @"Wrong token");
    XCTAssertTrue([sentDictionary[@"time"] isKindOfClass:[NSNumber class]], @"Time not present or not a number");
}

- (void)testSendLocationNE
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
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(51.01, 29.95);
    [push locationManager:nil didUpdateLocations:@[[[CLLocation alloc] initWithCoordinate:coord altitude:.0 horizontalAccuracy:1.0 verticalAccuracy:-1.0 course:.0 speed:.0 timestamp:[NSDate date]]]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    [self checkLocation:sentDictionary matches:coord];
    XCTAssertEqualObjects(toURL, [[NSURL alloc] initWithString:@"faketp://fake.com/fake/registergeo"], @"Wrong URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testSendLocationNW
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
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(51.01, -29.95);
    [push locationManager:nil didUpdateLocations:@[[[CLLocation alloc] initWithCoordinate:coord altitude:.0 horizontalAccuracy:1.0 verticalAccuracy:-1.0 course:.0 speed:.0 timestamp:[NSDate date]]]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    [self checkLocation:sentDictionary matches:coord];
    XCTAssertEqualObjects(toURL, [[NSURL alloc] initWithString:@"faketp://fake.com/fake/registergeo"], @"Wrong URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testSendLocationSE
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
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(-51.01, 29.95);
    [push locationManager:nil didUpdateLocations:@[[[CLLocation alloc] initWithCoordinate:coord altitude:.0 horizontalAccuracy:1.0 verticalAccuracy:-1.0 course:.0 speed:.0 timestamp:[NSDate date]]]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    [self checkLocation:sentDictionary matches:coord];
    XCTAssertEqualObjects(toURL, [[NSURL alloc] initWithString:@"faketp://fake.com/fake/registergeo"], @"Wrong URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testSendLocationSW
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
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(-51.01, -29.95);
    [push locationManager:nil didUpdateLocations:@[[[CLLocation alloc] initWithCoordinate:coord altitude:.0 horizontalAccuracy:1.0 verticalAccuracy:-1.0 course:.0 speed:.0 timestamp:[NSDate date]]]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    [self checkLocation:sentDictionary matches:coord];
    XCTAssertEqualObjects(toURL, [[NSURL alloc] initWithString:@"faketp://fake.com/fake/registergeo"], @"Wrong URL");
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testInvalidLocationNotSent
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
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(51.01, 29.95);
    [push locationManager:nil didUpdateLocations:@[[[CLLocation alloc] initWithCoordinate:coord altitude:.0 horizontalAccuracy:-1.0 verticalAccuracy:-1.0 course:.0 speed:.0 timestamp:[NSDate date]]]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV != 0, @"Semaphore should have timed out; didn't");
    [GLETest_faketp setStartLoadingBlock:nil];
}


@end

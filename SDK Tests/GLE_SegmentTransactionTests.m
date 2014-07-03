#import "GLE_Tests.h"

@interface GLE_SegmentTransactionTests : GLE_Tests

@end

@implementation GLE_SegmentTransactionTests

- (void)testSinglePushSegmentTransactionCommit
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    GLESegmentTransaction *transaction = [[GLESegmentTransaction alloc] initWithGLECentral:push];
    XCTAssertNotNil(transaction, @"Could not get a transaction object");
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
    [push setSegmentSubscription:[[GLESegment alloc] initWithName:@"segment" tags:@[@"oldtag"]]];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [self checkRegistration:sentDictionary];
    [self checkRegistration:sentDictionary containsSegment:@"segment" tags:@[@"oldtag"]];
    
    [transaction setSegmentSubscriptions:@[[[GLESegment alloc] initWithName:@"segment1" tags:@[@"tag1"]],[[GLESegment alloc] initWithName:@"segment3" tags:@[@"tag3"]]]];
    [transaction setSegmentSubscription:[[GLESegment alloc] initWithName:@"segment2" tags:@[@"tag2"]]];
    [transaction setSingleTag:@"tag" forSegment:@"newsegment"];
    [transaction addTag:@"tag" toSegment:@"newersegment"];
    [transaction addTag:@"newtag" toSegment:@"newersegment"];
    [transaction addTag:@"newertag" toSegment:@"newersegment"];
    [transaction removeTag:@"newtag" fromSegment:@"newersegment"];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV != 0, @"Semaphore failure %ld",semRV);
    [transaction commitChanges];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    
    [self checkRegistration:sentDictionary];
    [self checkRegistration:sentDictionary omitsSegment:@"segment"];
    [self checkRegistration:sentDictionary containsSegment:@"segment1" tags:@[@"tag1"]];
    [self checkRegistration:sentDictionary containsSegment:@"segment2" tags:@[@"tag2"]];
    [self checkRegistration:sentDictionary containsSegment:@"segment3" tags:@[@"tag3"]];
    [self checkRegistration:sentDictionary containsSegment:@"newsegment" tags:@[@"tag"]];
    [self checkRegistration:sentDictionary containsSegment:@"newersegment" tags:@[@"tag",@"newertag"]];
    [GLETest_faketp setStartLoadingBlock:nil];
}

- (void)testSinglePushSegmentTransactionDiscardThenCommit
{
    GLECentral *push = [GLECentral sharedGrooveLion];
    XCTAssertNotNil(push, @"Could not get a GLECentral object");
    GLESegmentTransaction *transaction = [[GLESegmentTransaction alloc] initWithGLECentral:push];
    XCTAssertNotNil(transaction, @"Could not get a transaction object");
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
    [push setSegmentSubscription:[[GLESegment alloc] initWithName:@"segment" tags:@[@"oldtag"]]];
    [push application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:[[NSMutableData alloc] initWithLength:64]];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV == 0, @"Semaphore failure %ld",semRV);
    [self checkRegistration:sentDictionary];
    [self checkRegistration:sentDictionary containsSegment:@"segment" tags:@[@"oldtag"]];
    
    [transaction setSegmentSubscriptions:@[[[GLESegment alloc] initWithName:@"segment1" tags:@[@"tag1"]],[[GLESegment alloc] initWithName:@"segment3" tags:@[@"tag3"]]]];
    [transaction setSegmentSubscription:[[GLESegment alloc] initWithName:@"segment2" tags:@[@"tag2"]]];
    [transaction setSingleTag:@"tag" forSegment:@"newsegment"];
    [transaction addTag:@"tag" toSegment:@"newersegment"];
    [transaction addTag:@"newtag" toSegment:@"newersegment"];
    [transaction addTag:@"newertag" toSegment:@"newersegment"];
    [transaction removeTag:@"newtag" fromSegment:@"newersegment"];
    [transaction discardChanges];
    [transaction commitChanges];
    semRV = dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    XCTAssertTrue(semRV != 0, @"Semaphore failure %ld",semRV);
    [self checkRegistration:sentDictionary];
    [self checkRegistration:sentDictionary containsSegment:@"segment" tags:@[@"oldtag"]];
    [GLETest_faketp setStartLoadingBlock:nil];
}

@end

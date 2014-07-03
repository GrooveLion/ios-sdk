#import "GLE_Tests.h"

NSString * const kGLEDeferredOpensKey = @"GLEDeferredOpens";
NSString * const kGLEMetaKey = @"GLEMeta";
NSString * const kGLEMetaRegisteredKey = @"GLEMetaDone";

@implementation GLE_Tests

-(void)tearDown
{
    [super tearDown];
    [NSURLProtocol unregisterClass:[GLETest_faketp class]];
}

-(void)setUp
{
    [super setUp];
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs removeObjectForKey:kGLEDeferredOpensKey];
    [defs removeObjectForKey:kGLEMetaKey];
    [defs removeObjectForKey:kGLEMetaRegisteredKey];
    [defs synchronize];
    [NSURLProtocol registerClass:[GLETest_faketp class]];
    [GLETest_faketp setStartLoadingBlock:nil];
    [GLETest_faketp setStopLoadingBlock:nil];
    [GLECentral setDebugLoggingEnabled:NO];
    [GLECentral setTestingEnabled:YES];
    [GLECentral resetSharedObject];
}


-(void)checkRegistration:(NSDictionary *)sentDictionary
{
    XCTAssertEqualObjects(sentDictionary[@"apiVersion"], @(2), @"Wrong API version");
    XCTAssertEqualObjects(sentDictionary[@"appBundleBuild"], @"1970.01.01", @"Wrong bundle build");
    XCTAssertEqualObjects(sentDictionary[@"appBundleId"], @"test.bundle", @"Wrong bundle id");
    XCTAssertEqualObjects(sentDictionary[@"appBundleVersion"], @"3.1415927", @"Wrong bundle version");
    XCTAssertEqualObjects(sentDictionary[@"appPlatform"], @"iOS", @"Wrong platform");
    XCTAssertEqualObjects(sentDictionary[@"environment"], @"production", @"Wrong environment");
    XCTAssertEqualObjects(sentDictionary[@"token"], @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", @"Wrong token");
    [self checkRegistration:sentDictionary containsSegment:@"_AppVersion" tags:@[@"3.1415927"]];
    [self checkRegistration:sentDictionary containsSegment:@"_AppBuild" tags:@[@"1970.01.01"]];
    [self checkRegistration:sentDictionary containsSegment:@"_Locale" tags:@[[[NSLocale currentLocale] localeIdentifier]]];
}

-(void)checkRegistration:(NSDictionary *)sentDictionary containsSegment:(NSString *)segmentName tags:(NSArray *)tags
{
    BOOL segmentFound = NO;
    for (NSDictionary *segment in sentDictionary[@"segments"])
    {
        if ([segment[@"name"] isEqualToString:segmentName])
        {
            XCTAssertFalse(segmentFound, @"Duplicate segment \"%@\"",segment);
            segmentFound = YES;
            NSMutableArray *sentTags = [segment[@"tags"] mutableCopy];
            for (NSString *tag in tags)
            {
                XCTAssertTrue([sentTags containsObject:tag], @"Missing tag \"%@\"",tag);
                [sentTags removeObject:tag];
            }
            NSUInteger count = [sentTags count];
            XCTAssertEqual(count, 0, @"Segment contains unexpected tags [ %@ ]",sentTags);
        }
    }
    XCTAssertTrue(segmentFound, @"Expected segment missing");
}

-(void)checkRegistration:(NSDictionary *)sentDictionary omitsSegment:(NSString *)segmentName
{
    BOOL segmentFound = NO;
    for (NSDictionary *segment in sentDictionary[@"segments"])
    {
        if ([segment[@"name"] isEqualToString:segmentName])
        {
            segmentFound = YES;
        }
    }
    XCTAssertFalse(segmentFound, @"Unexpected segment present");
}

@end

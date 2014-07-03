#import <XCTest/XCTest.h>

@interface GLE_Tests : XCTestCase

-(void)checkRegistration:(NSDictionary *)sentDictionaryl;
-(void)checkRegistration:(NSDictionary *)sentDictionary containsSegment:(NSString *)segmentName tags:(NSArray *)tags;
-(void)checkRegistration:(NSDictionary *)sentDictionary omitsSegment:(NSString *)segmentName;

@end

#import "GrooveLion.h"

@interface GLESegment ()

-(NSDictionary *)dictionaryRepresentation;
-(instancetype)initWithDictionaryRepresentation:(NSDictionary *)representation;

@end

@interface GLEURLConnection : NSURLConnection

@property(readwrite,nonatomic,strong)NSDictionary *associatedRegistrationData;
@property(readwrite,nonatomic,strong)NSString *associatedMessageId;
#if DEBUG
@property(readwrite,nonatomic,strong)NSMutableData *associatedResponseData;
@property(readwrite,nonatomic,strong)NSHTTPURLResponse *associatedResponse;
#endif
@end

#if DEBUG && TARGET_IPHONE_SIMULATOR
@interface GLECentral ()

+(BOOL)testingEnabled;
+(void)setTestingEnabled:(BOOL)enabled;
+(void)resetSharedObject;

@end
#endif

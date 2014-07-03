#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface GLESegment : NSObject <NSCopying,NSMutableCopying>

-(instancetype)initWithName:(NSString *)name tags:(NSArray *)tags;
@property(readonly,nonatomic,copy)NSString *name;
@property(readonly,nonatomic,copy)NSArray *tags;

@end

@interface GLEMutableSegment : GLESegment

@property(readwrite,nonatomic,copy)NSString *name;
@property(readwrite,nonatomic,copy)NSArray *tags;

@end

@interface GLECentral : NSObject <CLLocationManagerDelegate>

+(BOOL)debugLoggingEnabled;
+(void)setDebugLoggingEnabled:(BOOL)enabled;

@property(readwrite,nonatomic,copy)NSString *customerId;

+(instancetype)sharedGrooveLion;
+(instancetype)sharedGrooveLionWithServerURL:(NSURL *)url;

// Just pass through the arguments from your app delegate into these methods
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler;

// Raw segment-manipulation methods. It is easier and more efficient to use GLESegmentTransaction

-(void)setSegmentSubscription:(GLESegment *)segment;
-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName;
-(void)setSegmentSubscriptions:(NSArray *)segments;
-(NSArray *)segmentSubscriptions;

// Location manager delegate methods which we implement

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

@end

@interface GLESegmentTransaction : NSObject
    
-(instancetype)initWithGLECentral:(GLECentral *)push;
    
-(void)setSegmentSubscription:(GLESegment *)segment;
-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName;
-(void)setSegmentSubscriptions:(NSArray *)segments;
-(NSArray *)segmentSubscriptions;
    
- (void)addTag:(NSString *)tag toSegment:(NSString *)segmentName;
- (void)removeTag:(NSString *)tag fromSegment:(NSString *)segmentName;
- (void)setSingleTag:(NSString *)tag forSegment:(NSString *)segmentName;
    
-(void)discardChanges;
-(void)commitChanges;
    
@end

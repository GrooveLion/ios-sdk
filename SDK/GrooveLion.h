#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

/** This class represents a segment (also known as a Tag Group)
 
 GLEMutableSegment is the mutable subclass of this class
 */
@interface GLESegment : NSObject <NSCopying,NSMutableCopying>

/** Create a segment object
 
 @param name the application-defined segment name
 @param tags an array of strings representing the application-defined tags within that segment
 */
-(instancetype)initWithName:(NSString *)name tags:(NSArray *)tags;
/** Application-defined segment name */
@property(readonly,nonatomic,copy)NSString *name;
/** An array of strings representing the application-defined tags within this segment */
@property(readonly,nonatomic,copy)NSArray *tags;

@end

/** This class represents a mutable segment
 
 */
@interface GLEMutableSegment : GLESegment

/** Application-defined segment name */
@property(readwrite,nonatomic,copy)NSString *name;
/** An array of strings representing the application-defined tags within this segment */
@property(readwrite,nonatomic,copy)NSArray *tags;

@end

/** This class is the primary interface to Groove Lion from Objective C
 
 */
@interface GLECentral : NSObject <CLLocationManagerDelegate>

/** @name Debugging */
/** Query whether debug logging is enabled
 
 The default is YES iff the DEBUG preprocessor macro is defined true at compile time.
 
 @return YES iff debug logging is enabled
 */
+(BOOL)debugLoggingEnabled;

/** Set whether debug logging is enabled
 
 The default is YES iff the DEBUG preprocessor macro is defined true at compile time.
 
 @param enabled YES iff debug logging is required
 */
+(void)setDebugLoggingEnabled:(BOOL)enabled;

/** @name Identifying the Customer */
/** Application-defined identifier for the customer whose device this is.
 */
@property(readwrite,nonatomic,copy)NSString *customerId;

/** @name Getting an instance */
/** Access the shared GLECentral instance
 
Iff the first call is to sharedGrooveLionWithServerURL the server URL of the shared instance can be overridden from the default. The default is suitable for customers using the cloud service at https://engage.groovelion.com
 
 @return the shared GLECentral instance
 */
+(instancetype)sharedGrooveLion;

/** Access the shared GLECentral instance
 
 Iff the first call is to sharedGrooveLionWithServerURL the server URL of the shared instance can be overridden from the default. The default is suitable for customers using the cloud service at https://engage.groovelion.com
 
 @param url the URL of the Groove Lion installation
 @return the shared GLECentral instance
 */
+(instancetype)sharedGrooveLionWithServerURL:(NSURL *)url;

/** @name Pass-through methods from the application delegate */
/** Refer to the documentation for the UIApplicationDelegate protocol
 
 @param application the shared UIApplication instance
 @param deviceToken the device token given by the system
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
/** Refer to the documentation for the UIApplicationDelegate protocol
 
 @param application the shared UIApplication instance
 @param error the error given by the system
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
/** Refer to the documentation for the UIApplicationDelegate protocol
 
 @param application the shared UIApplication instance
 @param launchOptions the launch options given by the system
 @return YES
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
/** Refer to the documentation for the UIApplicationDelegate protocol
 
 @param application the shared UIApplication instance
 @param userInfo the user info given by the system
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
/** Refer to the documentation for the UIApplicationDelegate protocol
 
 @param application the shared UIApplication instance
 @param userInfo the user info given by the system
 @param handler the handler given by the system
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler;


/** @name Raw segment-manipulation methods */
/** Install (or replace) a single segment subscription
 
 This replaces any existing segment with the same name
 
 @warning Groove Lion recommends that you use the methods in GLESegmentTransaction instead of this method.
 @param segment a segment subscription to replace any existing segment subscription with the same name */
-(void)setSegmentSubscription:(GLESegment *)segment;
/** Retrieve a single segment subscription
 
 @warning Groove Lion recommends that you use the methods in GLESegmentTransaction instead of this method.
 @param segmentName the name of the segment to find
 @return the current segment subscription for that segment name */
-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName;
/** Install (or replace) all segment subscriptions
 
 Any existing segments are removed and replaced by the contents of the segments array
 
 @warning Groove Lion recommends that you use the methods in GLESegmentTransaction instead of this method.
 @param segments Array of GLESegment objects which replace all existing segment subscriptions */
-(void)setSegmentSubscriptions:(NSArray *)segments;
/** Retrieve all segment subscriptions
 
 @warning Groove Lion recommends that you use the methods in GLESegmentTransaction instead of this method.
 @return Array of GLESegment objects representing all existing segment subscriptions */
-(NSArray *)segmentSubscriptions;

/** @name Pass-through methods from the location manager delegate */
/** Refer to the documentation for the CLLocationManagerDelegate protocol
 
 @param manager the CLLocationManager
 @param locations the locations given by the system
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
/** Refer to the documentation for the CLLocationManagerDelegate protocol
 
 @param manager the CLLocationManager
 @param error the error given by the system
 */
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

@end

/** This class enables transactional manipulation of the application's segment subscriptions
 
 */
@interface GLESegmentTransaction : NSObject
/** @name Starting a transaction */
/** Create a segment-manipulation transaction
 
 @return a new segment-manipulation transaction object
 @param push the GLECentral instance to manipulate
 */
-(instancetype)initWithGLECentral:(GLECentral *)push;

/** @name Fundamental tag manipulation */
/** Install (or replace) a single segment subscription
 
 This replaces any existing segment with the same name
 
 @param segment the segment object
 */
-(void)setSegmentSubscription:(GLESegment *)segment;
/** Retrieve a single segment subscription
 
 @param segmentName the application-defined segment name
 @return the segment object
 */
-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName;
/** Install (or replace) all segments
 
 Any existing segments are removed and replaced by the contents of the segments array
 
 @param segments the application-defined segment subscriptions as an array of GLESegment objects
 */
-(void)setSegmentSubscriptions:(NSArray *)segments;
/** Retrieve all segment subscriptions
 
 @return an array of GLESegment objects representing all the segment subscriptions
 */
-(NSArray *)segmentSubscriptions;

/** @name Easy tag manipulation */
/** Ensure a tag is set within the given segment
 
 If the tag is not set, this adds it; if it is set, it does nothing.
 
 @param tag the application-defined tag name
 @param segmentName the application-defined segment name
 */
- (void)addTag:(NSString *)tag toSegment:(NSString *)segmentName;
/** Ensure a tag is not set within the given segment
 
 If the tag is set, this removes it; if it is not set, it does nothing.
 
 @param tag the application-defined tag name
 @param segmentName the application-defined segment name
 */
- (void)removeTag:(NSString *)tag fromSegment:(NSString *)segmentName;
/** Ensure there is exactly one tag set within the given segment
 
 @param tag the application-defined tag name
 @param segmentName the application-defined segment name
 */
- (void)setSingleTag:(NSString *)tag forSegment:(NSString *)segmentName;

/** @name Ending a transaction */
/** Discard the changes made in this transaction
 
 Any further changes after this point are a new transaction which can be committed or discarded independently.
  */
-(void)discardChanges;

/** Commit the changes made in this transaction
 
 Any further changes after this point are a new transaction which can be committed or discarded independently.
 */
-(void)commitChanges;
    
@end

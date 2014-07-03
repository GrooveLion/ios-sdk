#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

/** This class represents a segment (also known as a Tag Group)
 
 */
@interface GLESegment : NSObject <NSCopying,NSMutableCopying>

/** Create a segment object
 
 @param name the application-defined segment name
 @param tags an array of strings representing the application-defined tags within that segment
 */
-(instancetype)initWithName:(NSString *)name tags:(NSArray *)tags;
/// Application-defined segment name
@property(readonly,nonatomic,copy)NSString *name;
/// An array of strings representing the application-defined tags within this segment
@property(readonly,nonatomic,copy)NSArray *tags;

@end

/** This class represents a mutable segment
 
 */
@interface GLEMutableSegment : GLESegment

/// Application-defined segment name
@property(readwrite,nonatomic,copy)NSString *name;
/// An array of strings representing the application-defined tags within this segment
@property(readwrite,nonatomic,copy)NSArray *tags;

@end

/** This class is the primary interface to Groove Lion from Objective C
 
 */
@interface GLECentral : NSObject <CLLocationManagerDelegate>

/** Query whether debug logging is enabled
 
 The default is YES iff the DEBUG preprocessor macro is defined true at compile time.
 
 @return YES iff debug logging is enabled
 @name Debugging
 */
+(BOOL)debugLoggingEnabled;

/** Set whether debug logging is enabled
 
 The default is YES iff the DEBUG preprocessor macro is defined true at compile time.
 
 @param enabled YES iff debug logging is required
 @name Debugging
 */
+(void)setDebugLoggingEnabled:(BOOL)enabled;

/** Application-defined identifier for the customer whose device this is.
 */
@property(readwrite,nonatomic,copy)NSString *customerId;

/** Access the shared GLECentral instance
 
Iff the first call is to sharedGrooveLionWithServerURL the server URL of the shared instance can be overridden from the default. The default is suitable for customers using the cloud service at https://engage.groovelion.com
 
 @return the shared GLECentral instance
 @name Getting an instance
 */
+(instancetype)sharedGrooveLion;

/** Access the shared GLECentral instance
 
 Iff the first call is to sharedGrooveLionWithServerURL the server URL of the shared instance can be overridden from the default. The default is suitable for customers using the cloud service at https://engage.groovelion.com
 
 @param url the URL of the Groove Lion installation
 @return the shared GLECentral instance
 @name Getting an instance
 */
+(instancetype)sharedGrooveLionWithServerURL:(NSURL *)url;

/// @name Pass-through methods from the application delegate
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
/// @name Pass-through methods from the application delegate
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
/// @name Pass-through methods from the application delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
/// @name Pass-through methods from the application delegate
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
/// @name Pass-through methods from the application delegate
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler;


/// @name Raw segment-manipulation methods
-(void)setSegmentSubscription:(GLESegment *)segment;
/// @name Raw segment-manipulation methods
-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName;
/// @name Raw segment-manipulation methods
-(void)setSegmentSubscriptions:(NSArray *)segments;
/// @name Raw segment-manipulation methods
-(NSArray *)segmentSubscriptions;

/// @name Pass-through methods from the location manager delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
/// @name Pass-through methods from the location manager delegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

@end

@interface GLESegmentTransaction : NSObject
    
/** Create a segment-manipulation transaction
 
 @return a new segment-manipulation transaction object
 @param push the GLECentral instance to manipulate
 @name Starting a transaction
 */
-(instancetype)initWithGLECentral:(GLECentral *)push;

/** Install (or replace) a single segment subscription
 
 This replaces any existing segment with the same name
 
 @param segment the segment object
 @name Fundamental tag manipulation
 */
-(void)setSegmentSubscription:(GLESegment *)segment;
/** Retrieve a single segment subscription
 
 @param name the application-defined segment name 
 @return the segment object
 @name Fundamental tag manipulation
 */
-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName;
/** Install (or replace) all segments
 
 Any existing segments are removed and replaced by the contents of the segments array
 
 @param segments the application-defined segment subscriptions
 @name Fundamental tag manipulation
 */
-(void)setSegmentSubscriptions:(NSArray *)segments;
/** Retrieve all segment subscriptions
 
 @return an array of segment objects representing all the segment subscriptions
 @name Fundamental tag manipulation
 */
-(NSArray *)segmentSubscriptions;
    
/** Ensure a tag is set within the given segment
 
 If the tag is not set, this adds it; if it is set, it does nothing.
 
 @param tag the application-defined tag name
 @param segmentName the application-defined segment name
 @name Easy tag manipulation
 */
- (void)addTag:(NSString *)tag toSegment:(NSString *)segmentName;
/** Ensure a tag is not set within the given segment
 
 If the tag is set, this removes it; if it is not set, it does nothing.
 
 @param tag the application-defined tag name
 @param segmentName the application-defined segment name
 @name Easy tag manipulation
 */
- (void)removeTag:(NSString *)tag fromSegment:(NSString *)segmentName;
/** Ensure there is exactly one tag set within the given segment
 
 @param tag the application-defined tag name
 @param segmentName the application-defined segment name
 @name Easy tag manipulation
 */
- (void)setSingleTag:(NSString *)tag forSegment:(NSString *)segmentName;
    
/** Discard the changes made in this transaction
 
 Any further changes after this point are a new transaction which can be committed or discarded independently.
 
 @name Ending a transaction
 */
-(void)discardChanges;

/** Commit the changes made in this transaction
 
 Any further changes after this point are a new transaction which can be committed or discarded independently.
 
 @name Ending a transaction
 */
-(void)commitChanges;
    
@end

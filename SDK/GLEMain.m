#import "GLEInternals.h"

#if DEBUG && TARGET_IPHONE_SIMULATOR
static BOOL isTesting = NO;
#endif

static BOOL debugLogging
#if DEBUG
= YES
#else
= NO
#endif
;

#undef DLog
#define DLog(...) do { if (debugLogging) NSLog(__VA_ARGS__); } while (0)

static NSString * const kGLEDeferredOpensKey = @"GLEDeferredOpens";
static NSString * const kGLEMetaKey = @"GLEMeta";
static NSString * const kGLEMetaRegisteredKey = @"GLEMetaDone";

static NSString * const kGLEMeta_DeviceToken = @"deviceToken";
static NSString * const kGLEMeta_AppPlatform = @"appPlatform";
static NSString * const kGLEMeta_BundleID = @"bundleID";
static NSString * const kGLEMeta_BundleVersion = @"bundleVersion";
static NSString * const kGLEMeta_BundleBuild = @"bundleBuild";
static NSString * const kGLEMeta_ApsEnvironment = @"apsEnvironment";
static NSString * const kGLEMeta_Segments = @"selectedSegments";
static NSString * const kGLEMeta_CustomerId = @"customerId";

@interface GLECentral () <NSURLConnectionDataDelegate>
-(void)deferAcknowledgingMessage:(NSString *)messageId;
-(void)acknowledgeRemoteNotification:(NSDictionary *)userInfo;
-(void)saveMetaData;
@end

@implementation GLECentral
{
    NSMutableDictionary *meta;
    BOOL dirty;
    GLEURLConnection *registerConnection;
    NSURL *registerURL;
    NSURL *locationURL;
    NSURL *messageRecieptURL;
    NSMutableOrderedSet *connections;
    NSMutableOrderedSet *deferredMessagesToAcknowledge;
    dispatch_queue_t netQueue;
    NSOperationQueue *connectionQueue;
    NSString *customerId;
}

-(NSString *)customerId
{
    return meta[kGLEMeta_CustomerId];
}

-(void)setCustomerId:(NSString *)_customerId
{
    meta[kGLEMeta_CustomerId] = [_customerId copy];
    [self saveMetaData];
    [self compareMetaToLastSuccessfulMeta];
}

+(BOOL)debugLoggingEnabled
{
    return debugLogging;
}

+(void)setDebugLoggingEnabled:(BOOL)enabled
{
    debugLogging = enabled;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

-(NSDictionary *)currentRegistrationDictionary
{
    NSString *token = meta[kGLEMeta_DeviceToken];
    if (!token)
        return nil;
    NSMutableDictionary *registration = [[NSMutableDictionary alloc] initWithCapacity:7];
    NSMutableArray *segments = [[NSMutableArray alloc] init];
    registration[@"appBundleId"] = meta[kGLEMeta_BundleID];
    registration[@"appBundleVersion"] = meta[kGLEMeta_BundleVersion];
    [segments addObject:@{@"name": @"_AppVersion", @"tags" : @[meta[kGLEMeta_BundleVersion]]}];
    registration[@"environment"]= meta[kGLEMeta_ApsEnvironment];
    registration[@"token"] = token;
    registration[@"appPlatform"] = meta[kGLEMeta_AppPlatform];
    registration[@"apiVersion"] = @(2);
    registration[@"time"] = @((long)[[NSDate date] timeIntervalSince1970]);
    id a = meta[kGLEMeta_BundleBuild];
    if (a)
    {
        registration[@"appBundleBuild"] = a;
        [segments addObject:@{@"name": @"_AppBuild", @"tags" : @[a]}];
    }
    a = meta[kGLEMeta_CustomerId];
    if (a)
    {
        registration[@"customerId"] = a;
    }
    a = [[NSLocale currentLocale] localeIdentifier];
    if (a)
    {
        [segments addObject:@{@"name": @"_Locale", @"tags" : @[a]}];
    }
    a = meta[kGLEMeta_Segments];
    if (a)
        [segments addObjectsFromArray:a];
    registration[@"segments"] = segments;
    return [registration copy];
}

-(void)compareMetaToLastSuccessfulMeta
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSMutableDictionary *oldRegistration = [[defaults objectForKey:kGLEMetaRegisteredKey] mutableCopy];
    NSMutableDictionary *newRegistration = [[self currentRegistrationDictionary] mutableCopy];
    NSUInteger oldTime = [oldRegistration[@"time"] unsignedIntegerValue];
    NSUInteger newTime = [newRegistration[@"time"] unsignedIntegerValue];
    [oldRegistration removeObjectForKey:@"time"];
    [newRegistration removeObjectForKey:@"time"];
    dirty = !oldTime || !newTime || (newTime < oldTime) || ((newTime - 3600*24) > oldTime) || ![oldRegistration isEqual:newRegistration];
    [self sendRegistration];
}

-(void)deferAcknowledgingMessage:(NSString *)messageId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    NSMutableArray *deferredMessages = [[defaults objectForKey:kGLEDeferredOpensKey] mutableCopy];
    if (!deferredMessages)
        deferredMessages = [[NSMutableArray alloc] initWithCapacity:1];
    if ([deferredMessages containsObject:messageId])
        return;
    [deferredMessages addObject:messageId];
    [defaults setObject:[deferredMessages copy] forKey:kGLEDeferredOpensKey];
    [defaults synchronize];
}

-(void)acknowledgeMessageId:(NSString *)messageID
{
    NSString *deviceTokenString = meta[kGLEMeta_DeviceToken];
    NSString *bundleIdString = meta[kGLEMeta_BundleID];
    NSString *environment = meta[kGLEMeta_ApsEnvironment];
    NSString *platform = meta[kGLEMeta_AppPlatform];
    if (deviceTokenString && messageID && bundleIdString && environment && platform)
    {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:messageRecieptURL
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                           timeoutInterval:60.0];
        [request setHTTPMethod:@"POST"];
        NSDictionary *bodyObject = @{@"id": messageID,
                                     @"appBundleId":bundleIdString,
                                     @"token":deviceTokenString,
                                     @"environment":environment,
                                     @"appPlatform":platform,
                                     @"time":@((long)[[NSDate date] timeIntervalSince1970]),
                                     };
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyObject
                                                           options:0
                                                             error:NULL];
        if (!bodyData)
            return;
        [request setHTTPBody:bodyData];
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [request setValue:[[NSString alloc] initWithFormat:@"%lu",(unsigned long)bodyData.length]
       forHTTPHeaderField:@"content-length"];
        
        GLEURLConnection *conn = [[GLEURLConnection alloc] initWithRequest:request
                                                                  delegate:self
                                                          startImmediately:NO];
        [connections addObject:conn];
        conn.associatedMessageId = messageID;
        DLog(@"Sending open %@",bodyObject);
        [conn start];
        
        DLog(@"Receipt sent for message '%@' - %p", messageID,conn);
    }
    else
    {
        [deferredMessagesToAcknowledge addObject:messageID];
        DLog(@"Receipt deferred for message '%@'", messageID);
    }
}

-(void)saveMetaData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:meta forKey:kGLEMetaKey];
    [defaults synchronize];
}

static GLECentral *sharedGrooveLionObject;
static dispatch_once_t sharedGrooveLionOnceToken;

+(instancetype)sharedGrooveLion
{
    return [self sharedGrooveLionWithServerURL:nil];
}

+(instancetype)sharedGrooveLionWithServerURL:(NSURL *)url
{
    dispatch_once(&sharedGrooveLionOnceToken, ^
                  {
                      sharedGrooveLionObject = [[self alloc] init753951456258:url];
                  });
    return sharedGrooveLionObject;
}

#if TARGET_IPHONE_SIMULATOR && DEBUG
+(void)resetSharedObject
{
    sharedGrooveLionObject = 0;
    sharedGrooveLionOnceToken = 0;
}
#endif

-(instancetype)init753951456258:(NSURL *)url
{
#if TARGET_IPHONE_SIMULATOR
#if DEBUG
    if (!isTesting)
#endif
        return nil;
#endif
    NSURL *baseURL = url;
    if (!baseURL)
    {
        baseURL =
#if TARGET_IPHONE_SIMULATOR && DEBUG
        [NSURL URLWithString:@"faketp://fake.com/fake/"];
#else
        [NSURL URLWithString:@"https://engage.groovelion.com/notifications/api/"];
#endif
    }
    if (!baseURL)
        @throw [NSException exceptionWithName:self.class.description reason:@"Must provide an API base" userInfo:nil];
    
    self = [super init];
    if (self)
    {
        netQueue = dispatch_queue_create("GLE", DISPATCH_QUEUE_SERIAL);
        connectionQueue = [[NSOperationQueue alloc] init];
        connectionQueue.name = @"GLE";
        connectionQueue.maxConcurrentOperationCount = 2;
        deferredMessagesToAcknowledge = [[NSMutableOrderedSet alloc] init];
        connections = [[NSMutableOrderedSet alloc] init];
        registerURL = [[NSURL alloc] initWithString:@"register" relativeToURL:baseURL];
        while ([[registerURL path] rangeOfString:@"//"].location != NSNotFound)
        {
            registerURL = [[NSURL alloc] initWithScheme:registerURL.scheme host:registerURL.host path:[registerURL.path stringByReplacingOccurrencesOfString:@"//" withString:@"/"]];
        }
        if (!registerURL)
        {
            @throw [NSException exceptionWithName:self.class.description
                                           reason:@"Could not create valid got token URL"
                                         userInfo:nil];
            
        }
        messageRecieptURL = [[NSURL alloc] initWithString:@"opened/" relativeToURL:baseURL];
        while ([[messageRecieptURL path] rangeOfString:@"//"].location != NSNotFound)
        {
            messageRecieptURL = [[NSURL alloc] initWithScheme:messageRecieptURL.scheme host:messageRecieptURL.host path:[messageRecieptURL.path stringByReplacingOccurrencesOfString:@"//" withString:@"/"]];
        }
        if (!messageRecieptURL)
        {
            @throw [NSException exceptionWithName:self.class.description
                                           reason:@"Could not create valid message receipt URL"
                                         userInfo:nil];
        }
        locationURL = [[NSURL alloc] initWithString:@"registergeo" relativeToURL:baseURL];
        while ([[locationURL path] rangeOfString:@"//"].location != NSNotFound)
        {
            locationURL = [[NSURL alloc] initWithScheme:locationURL.scheme host:locationURL.host path:[locationURL.path stringByReplacingOccurrencesOfString:@"//" withString:@"/"]];
        }
        if (!locationURL)
        {
            @throw [NSException exceptionWithName:self.class.description
                                           reason:@"Could not create valid location URL"
                                         userInfo:nil];
            
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults synchronize];
        
        NSDictionary *oldMeta = [defaults objectForKey:kGLEMetaKey];
        meta = [[NSMutableDictionary alloc] init];
        NSBundle *mainBundle = nil;
#if DEBUG && TARGET_IPHONE_SIMULATOR
        if (isTesting)
            mainBundle = [NSBundle bundleForClass:NSClassFromString(@"GLE_Tests")];
        else
#endif
            mainBundle = [NSBundle mainBundle];
        NSDictionary *mainKeys = mainBundle.infoDictionary;
        meta[kGLEMeta_AppPlatform] = @"iOS";
        DLog(@"App platform is iOS");
        NSString *str;
        str = mainKeys[(__bridge NSString *)kCFBundleIdentifierKey];
        if (str)
        {
            DLog(@"App bundle identifier is %@",str);
            meta[kGLEMeta_BundleID] = str;
        }
        else
        {
            NSLog(@"If you are wondering why push messaging isn't working it is because this app somehow doesn't have a value for kCFBundleIdentifierKey in the main bundle.");
            return nil;
        }
        
        str = mainKeys[@"CFBundleShortVersionString"];
        if (str)
        {
            DLog(@"App bundle version is %@",str);
            meta[kGLEMeta_BundleVersion] = str;
        }
        else
        {
            NSLog(@"If you are wondering why push messaging isn't working it is because this app somehow doesn't have a value for \"CFBundleShortVersionString\" in the main bundle.");
            return nil;
        }
        
        str = mainKeys[(__bridge NSString *)kCFBundleVersionKey];
        if (str)
        {
            DLog(@"App bundle build is %@",str);
            meta[kGLEMeta_BundleBuild] = str;
        }
        else
        {
            DLog(@"App bundle build is missing; continuing");
        }
        
        {
            meta[kGLEMeta_ApsEnvironment] = @"production";
            NSURL *provisioningURL = [[NSBundle mainBundle] URLForResource:@"embedded" withExtension:@"mobileprovision"];
            if (provisioningURL)
            {
                NSData *data = [NSData dataWithContentsOfURL:provisioningURL];
                if (data)
                {
                    NSRange startRange = [data rangeOfData:[@"<?xml " dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, data.length)];
                    NSRange endRange = [data rangeOfData:[@"</plist>" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, data.length)];
                    if ((startRange.location != NSNotFound) && (endRange.location != NSNotFound) && (startRange.location < endRange.location))
                    {
                        NSRange pListRange = startRange;
                        pListRange.length = endRange.location + endRange.length - startRange.location;
                        NSData *plistData = [data subdataWithRange:pListRange];
                        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:0 error:0];
                        NSString *env = plist[@"Entitlements"][@"aps-environment"];
                        if (env)
                            meta[kGLEMeta_ApsEnvironment] = env;
                        else
                            NSLog(@"If you are wondering why push messaging isn't working it is because it has been provisioned with a wildcard provisioning profile.");
                    }
                }
            }
        }
        
        str = meta[kGLEMeta_ApsEnvironment];
        if (str)
        {
            DLog(@"APS Environment is %@",str);
        }
        else
        {
            NSLog(@"If you are wondering why push messaging isn't working it is because it has been provisioned with a wildcard provisioning profile.");
            return nil;
        }
        
        str = oldMeta[kGLEMeta_DeviceToken];
        if (str)
        {
            DLog(@"Cached device token is %@",str);
            meta[kGLEMeta_DeviceToken] = str;
        }
        else
        {
            DLog(@"No cached device token; registration will be deferred until a device token is supplied");
        }
        
        NSDictionary *oldSegments = oldMeta[kGLEMeta_Segments];
        if (oldSegments)
            meta[kGLEMeta_Segments] = oldSegments;
        
        {
            NSString *oldBundleId = oldMeta[kGLEMeta_BundleID];
            if (![oldBundleId isEqualToString:meta[kGLEMeta_BundleID]])
            {
                DLog(@"Bundle ID has changed; re-registration with a new token is required");
                dirty = YES;
                [meta removeObjectForKey:kGLEMeta_DeviceToken];
            }
        }
        
        {
            NSString *oldEnvironment = oldMeta[kGLEMeta_ApsEnvironment];
            if (![oldEnvironment isEqualToString:meta[kGLEMeta_ApsEnvironment]])
            {
                DLog(@"APS Environment has changed; re-registration with a new token is required");
                dirty = YES;
                [meta removeObjectForKey:kGLEMeta_DeviceToken];
            }
        }
        [self saveMetaData];
        if (!dirty)
            [self compareMetaToLastSuccessfulMeta];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeChanged:) name:NSCurrentLocaleDidChangeNotification object:nil];
        NSArray *deferredMessages = [defaults objectForKey:kGLEDeferredOpensKey];
        [defaults removeObjectForKey:kGLEDeferredOpensKey];
        [defaults synchronize];
        DLog(@"Re-queuing %lu deferred opens",(unsigned long)deferredMessages.count);
        for (NSString *messageId in deferredMessages)
            [self acknowledgeMessageId:messageId];
        
    }
    return self;
}

- (void)immediateSendRegistration
{
    if (!dirty)
        return;
    dirty = NO;
    DLog(@"Sending registration");
    [registerConnection cancel];
    registerConnection = nil;
    NSDictionary *registration = [self currentRegistrationDictionary];
    if (!registration)
        return;
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:registerURL
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                        timeoutInterval:60.0];
    [req setHTTPMethod:@"POST"];
    [req setHTTPShouldHandleCookies:YES];
    [req setHTTPShouldUsePipelining:YES];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:registration options:0 error:0];
    [req setHTTPBody:jsonData];
    [req setValue:[NSString stringWithFormat:@"%ld",(long)jsonData.length] forHTTPHeaderField:@"Content-Length"];
    GLEURLConnection *conn = [[GLEURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [conn setDelegateQueue:connectionQueue];
    conn.associatedRegistrationData = registration;
    registerConnection = conn;
    DLog(@"Sending registration object\n%@",registration);
    [conn start];
}

- (void)sendRegistration
{
    DLog(@"Enqueuing registration");
    dispatch_async(netQueue, ^
                   {
                       [self immediateSendRegistration];
                   });
}

- (void)acknowledgeRemoteNotification:(NSDictionary *)userInfo
{
    DLog(@"Received message\n%@", userInfo);
    NSString *messageID = userInfo[@"m"];
    if (messageID && ![messageID isKindOfClass:[NSString class]])
    {
        DLog(@"Received a message but the message ID is not a string!");
        return;
    }
    if (!messageID.length)
        return;
    [self acknowledgeMessageId:messageID];
}

#pragma mark - Application delegate passthrough

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)_deviceToken
{
    DLog(@"Push token found : %@", _deviceToken);
    NSUInteger count = _deviceToken.length;
    NSMutableString *str = [[NSMutableString alloc] initWithCapacity:count * 2];
    const unsigned char *bytes = _deviceToken.bytes;
    for (NSUInteger i = 0; i < count; ++i)
        [str appendFormat:@"%02hhx",bytes[i]];
    NSString *oldToken = meta[kGLEMeta_DeviceToken];
    if ([oldToken isEqualToString:str])
    {
        DLog(@"Push token not changed");
        return;
    }
    meta[kGLEMeta_DeviceToken] = [str copy];
    [self saveMetaData];
    [self compareMetaToLastSuccessfulMeta];
    NSOrderedSet *acks = [deferredMessagesToAcknowledge copy];
    [deferredMessagesToAcknowledge removeAllObjects];
    for (NSString *str in acks)
        [self acknowledgeRemoteNotification:@{@"m":str}];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DLog(@"Failed to get token with error %@", error);
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *message = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (message)
        [self acknowledgeRemoteNotification:message];
    return YES;
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self acknowledgeRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    [self acknowledgeRemoteNotification:userInfo];
}

#pragma mark - Locations

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"Failed to get location with error %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation __block *latestLocation = nil;
    [locations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         CLLocation *location = obj;
         if (location.horizontalAccuracy > 0)
         {
             *stop = YES;
             latestLocation = location;
         }
     }];
    if (!latestLocation)
    {
        DLog(@"No location included a valid latitude & longitude");
        return;
    }
    CLLocationCoordinate2D coordinate  = latestLocation.coordinate;
    NSString *deviceTokenString = meta[kGLEMeta_DeviceToken];
    NSString *bundleIdString = meta[kGLEMeta_BundleID];
    NSString *environment = meta[kGLEMeta_ApsEnvironment];
    NSString *platform = meta[kGLEMeta_AppPlatform];
    if (!(deviceTokenString && bundleIdString && environment && platform))
    {
        DLog(@"Missing some required information, not sending location");
        return;
    }
    NSDictionary *location = @{@"appBundleId": bundleIdString,
                               @"token": deviceTokenString,
                               @"environment": environment,
                               @"appPlatform": platform,
                               @"lat": @(coordinate.latitude),
                               @"lon": @(coordinate.longitude),
                               @"time" : @((long)[[NSDate date] timeIntervalSince1970])
                               };
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:locationURL
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                        timeoutInterval:60.0];
    [req setHTTPMethod:@"POST"];
    [req setHTTPShouldHandleCookies:YES];
    [req setHTTPShouldUsePipelining:YES];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:location options:0 error:0];
    [req setHTTPBody:jsonData];
    [req setValue:[NSString stringWithFormat:@"%lu",(unsigned long)jsonData.length] forHTTPHeaderField:@"Content-Length"];
    GLEURLConnection *conn = [[GLEURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [conn setDelegateQueue:connectionQueue];
    DLog(@"Sending location %@",location);
    [connections addObject:conn];
    [conn start];
}

#pragma mark - Segment manipulation

-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName
{
    for (NSDictionary *segmentDict in meta[kGLEMeta_Segments])
    {
        if ([segmentDict[@"name"] isEqualToString:segmentName])
            return [[GLESegment alloc] initWithDictionaryRepresentation:segmentDict];
    }
    return [[GLESegment alloc] initWithName:segmentName tags:@[]];
}

-(NSArray *)segmentSubscriptions
{
    NSArray *segmentDictionaries = meta[kGLEMeta_Segments];
    NSMutableArray *rv = [[NSMutableArray alloc] initWithCapacity:segmentDictionaries.count];
    for (NSDictionary *segmentDict in segmentDictionaries)
    {
        [rv addObject:[[GLESegment alloc] initWithDictionaryRepresentation:segmentDict]];
    }
    return [rv copy];
}

-(void)setSegmentSubscription:(GLESegment *)segment
{
    NSArray *segmentDictionaries = meta[kGLEMeta_Segments];
    NSInteger idx = NSNotFound;
    if (segmentDictionaries)
        idx = [segmentDictionaries indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
               {
                   NSDictionary *segmentDict = obj;
                   if ([segmentDict[@"name"] isEqualToString:segment.name])
                   {
                       *stop = YES;
                       return YES;
                   }
                   return NO;
               }];
    NSDictionary *newDict = segment.dictionaryRepresentation;
    if (idx == NSNotFound)
    {
        if (newDict)
        {
            if (segmentDictionaries)
                meta[kGLEMeta_Segments] = [segmentDictionaries arrayByAddingObject:newDict];
            else
                meta[kGLEMeta_Segments] = @[newDict];
        }
    }
    else
    {
        NSMutableArray *newSegmentDictionaries = [segmentDictionaries mutableCopy];
        if (newDict)
        {
            if ([segmentDictionaries[idx] isEqualToDictionary:newDict])
                return;
            [newSegmentDictionaries replaceObjectAtIndex:idx withObject:newDict];
        }
        else
        {
            [newSegmentDictionaries removeObjectAtIndex:idx];
        }
        if (newSegmentDictionaries.count)
            meta[kGLEMeta_Segments] = [newSegmentDictionaries copy];
        else
            [meta removeObjectForKey:kGLEMeta_Segments];
    }
    [self saveMetaData];
    [self compareMetaToLastSuccessfulMeta];
}

-(void)setSegmentSubscriptions:(NSArray *)segments
{
    NSMutableArray *newSegmentDictionaries = [[NSMutableArray alloc] initWithCapacity:segments.count];
    for (GLESegment *segment in segments)
    {
        NSDictionary *newDict = [segment dictionaryRepresentation];
        if (newDict)
            [newSegmentDictionaries addObject:newDict];
    }
    if (newSegmentDictionaries.count)
        meta[kGLEMeta_Segments] = [newSegmentDictionaries copy];
    else
        [meta removeObjectForKey:kGLEMeta_Segments];
    [self saveMetaData];
    [self compareMetaToLastSuccessfulMeta];
}

#pragma mark - Connection delegate

-(void)connectionDidFinishLoading:(NSURLConnection *)_connection
{
    GLEURLConnection *connection = (GLEURLConnection *)_connection;
    DLog(@"Communications completed successfully - %p", connection);
#if DEBUG
    {
        NSData *responseData = connection.associatedResponseData;
        if (responseData)
        {
            NSString *type = connection.associatedResponse.MIMEType;
            if (type && ([type compare:@"application/json" options:NSCaseInsensitiveSearch] == 0))
            {
                NSError *error = nil;
                id parsed = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                if (error)
                    DLog(@"JSON reading error - %p\n%@",connection,error);
                else
                    DLog(@"Response json object - %p\n%@",connection,parsed);
            }
            else
            {
                NSString *bodyString = nil;
                NSString *encodingString = connection.associatedResponse.textEncodingName;
                NSStringEncoding encoding = NSUTF8StringEncoding;
                if (encodingString)
                    encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)encodingString));
                bodyString = [[NSString alloc] initWithData:responseData encoding:encoding];
                DLog(@"Response as string - %p\n%@",connection,bodyString);
            }
        }
    }
#endif
    if (connection == registerConnection)
    {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        [defs setObject:connection.associatedRegistrationData forKey:kGLEMetaRegisteredKey];
        [defs synchronize];
        registerConnection = nil;
    }
    else
    {
        [connections removeObject:connection];
    }
}

-(void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error
{
    GLEURLConnection *connection = (GLEURLConnection *)_connection;
    DLog(@"Communications failed - %p", connection);
    DLog(@"Communications error detail\n%@", error);
    if (connection == registerConnection)
    {
        dirty = YES;
        registerConnection = nil;
        [self performSelector:@selector(sendRegistration) withObject:nil afterDelay:300.0];
    }
    else
    {
        if (connection.associatedMessageId)
            [self deferAcknowledgingMessage:connection.associatedMessageId];
        [connections removeObject:connection];
    }
}

-(void)connection:(NSURLConnection *)_connection didReceiveResponse:(NSURLResponse *)response
{
    GLEURLConnection *connection = (GLEURLConnection *)_connection;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]])
    {
#if DEBUG
        connection.associatedResponse = httpResponse;
#endif
        DLog(@"Received response code %ld - %p", (long)httpResponse.statusCode, connection);
        DLog(@"Original URL was %@",connection.originalRequest.URL.absoluteString);
        DLog(@"Current URL is %@",connection.currentRequest.URL.absoluteString);
        DLog(@"Response headers are %@", httpResponse.allHeaderFields);
        if (httpResponse.statusCode != 200)
        {
            DLog(@"Received response code %ld - %p", (long)httpResponse.statusCode, connection);
            DLog(@"Original URL was %@",connection.originalRequest.URL.absoluteString);
        }
    }
}

-(void)connection:(NSURLConnection *)_connection didReceiveData:(NSData *)data
{
    GLEURLConnection *connection = (GLEURLConnection *)_connection;
#if DEBUG
    NSMutableData *gotData = connection.associatedResponseData;
    if (gotData)
        [gotData appendData:data];
    else
        connection.associatedResponseData = [data mutableCopy];
#else
    (void)connection;
#endif
}

-(void)localeChanged:(NSNotification *)note
{
    [self saveMetaData];
    [self compareMetaToLastSuccessfulMeta];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSCurrentLocaleDidChangeNotification object:nil];
    for (GLEURLConnection *conn in connections)
    {
        if (conn.associatedMessageId)
            [self deferAcknowledgingMessage:conn.associatedMessageId];
        [conn cancel];
    }
}

#if DEBUG && TARGET_IPHONE_SIMULATOR
+(BOOL)testingEnabled
{
    return isTesting;
}

+(void)setTestingEnabled:(BOOL)enabled
{
    isTesting = enabled;
}
#endif

@end

@implementation GLEURLConnection

@synthesize associatedRegistrationData;
@synthesize associatedMessageId;
#if DEBUG
@synthesize associatedResponseData;
@synthesize associatedResponse;
#endif

@end
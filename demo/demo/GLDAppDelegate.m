//
//  GLDAppDelegate.m
//  demo
//
//  Created by Philip Willoughby on 03/07/2014.
//  Copyright (c) 2014 Groove Lion. All rights reserved.
//

#import "GLDAppDelegate.h"
#import <GrooveLion/GrooveLion.h>
#import "GLDLocationTracker.h"
#import "GLDMessageList.h"

@implementation GLDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    GLECentral *groovelion = [GLECentral sharedGrooveLion];
    [groovelion application:application didFinishLaunchingWithOptions:launchOptions];
    GLDLocationTracker *tracker = [GLDLocationTracker sharedLocationTracker];
    if (groovelion)
        [tracker addMonitoringDelegate:groovelion];
    if (launchOptions[UIApplicationLaunchOptionsLocationKey])
    {
        [tracker.locationManager startMonitoringSignificantLocationChanges];
    }
    NSDictionary *message = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (message)
    {
        [[GLDMessageList sharedMessageList] addMessage:message];
    }
    return YES;
}
							
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Notification \n%@",userInfo);
    [[GLECentral sharedGrooveLion] application:application didReceiveRemoteNotification:userInfo];
    [[GLDMessageList sharedMessageList] addMessage:userInfo];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[GLECentral sharedGrooveLion] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    [[GLDMessageList sharedMessageList] addMessage:userInfo];
    completionHandler(UIBackgroundFetchResultNoData);
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[GLECentral sharedGrooveLion] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[GLECentral sharedGrooveLion] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

@end

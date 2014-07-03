//
//  GLDLocationTracker.m
//  demo
//
//  Created by Philip Willoughby on 03/07/2014.
//  Copyright (c) 2014 Groove Lion. All rights reserved.
//

#import "GLDLocationTracker.h"

@interface GLDLocationTracker () <CLLocationManagerDelegate>

@end

@implementation GLDLocationTracker
{
    NSMutableSet *monitors;
}
@synthesize locationManager;

-(id)init
{
    self = [super init];
    if (!self)
        return nil;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    monitors = [[NSMutableSet alloc] init];
    return self;
}

+(instancetype)sharedLocationTracker
{
    static GLDLocationTracker *tracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        tracker = [[self alloc] init];
    });
    return tracker;
}

-(void)addMonitoringDelegate:(id<CLLocationManagerDelegate>)monitor
{
    [monitors addObject:monitor];
}

-(void)removeMonitoringDelegate:(id<CLLocationManagerDelegate>)monitor
{
    [monitors removeObject:monitor];
}

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didUpdateLocations:locations];
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didUpdateHeading:newHeading];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    BOOL result = NO;
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            result = result || [monitor locationManagerShouldDisplayHeadingCalibration:manager];
    return result;
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didDetermineState:state forRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didRangeBeacons:beacons inRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager rangingBeaconsDidFailForRegion:region withError:error];
}

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didEnterRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didExitRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didFailWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager monitoringDidFailForRegion:region withError:error];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didChangeAuthorizationStatus:status];
}

- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didStartMonitoringForRegion:region];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManagerDidPauseLocationUpdates:manager];
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManagerDidResumeLocationUpdates:manager];
}

- (void)locationManager:(CLLocationManager *)manager
didFinishDeferredUpdatesWithError:(NSError *)error
{
    for (id <CLLocationManagerDelegate> monitor in monitors)
        if ([monitor respondsToSelector:_cmd])
            [monitor locationManager:manager didFinishDeferredUpdatesWithError:error];
}

@end

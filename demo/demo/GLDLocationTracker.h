//
//  GLDLocationTracker.h
//  demo
//
//  Created by Philip Willoughby on 03/07/2014.
//  Copyright (c) 2014 Groove Lion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GLDLocationTracker : NSObject

@property(readonly,nonatomic,strong)CLLocationManager *locationManager;
+(instancetype)sharedLocationTracker;
-(void)addMonitoringDelegate:(id <CLLocationManagerDelegate>)monitor;
-(void)removeMonitoringDelegate:(id <CLLocationManagerDelegate>)monitor;

@end

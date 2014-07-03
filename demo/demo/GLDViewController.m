//
//  GLDViewController.m
//  demo
//
//  Created by Philip Willoughby on 03/07/2014.
//  Copyright (c) 2014 Groove Lion. All rights reserved.
//

#import "GLDViewController.h"
#import <GrooveLion/GrooveLion.h>
#import <CoreLocation/CoreLocation.h>
#import "GLDLocationTracker.h"
#import "GLDMessageList.h"

@interface GLDViewController () <CLLocationManagerDelegate,UITableViewDataSource>

@property(readwrite,nonatomic,weak)IBOutlet UIButton *locationStartButton;
@property(readwrite,nonatomic,weak)IBOutlet UILabel *locationStatusLabel;
@property(readwrite,nonatomic,weak)IBOutlet UITableView *messageTableView;
-(IBAction)requestPermissionForNotifications:(UIButton *)sender;
-(IBAction)requestPermissionForLocationUpdates:(UIButton *)sender;

@end

@implementation GLDViewController

@synthesize locationStartButton;
@synthesize locationStatusLabel;
@synthesize messageTableView;

-(void)requestPermissionForLocationUpdates:(UIButton *)sender
{
    [[GLDLocationTracker sharedLocationTracker].locationManager startMonitoringSignificantLocationChanges];
}

-(void)requestPermissionForNotifications:(UIButton *)sender
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status)
    {
        case kCLAuthorizationStatusAuthorized:
            locationStartButton.enabled = NO;
            locationStatusLabel.text = @"Location updates enabled";
            [[GLDLocationTracker sharedLocationTracker].locationManager startMonitoringSignificantLocationChanges];
            break;
        case kCLAuthorizationStatusDenied:
            locationStartButton.enabled = NO;
            locationStatusLabel.text = @"Location updates denied";
            break;
        case kCLAuthorizationStatusRestricted:
            locationStartButton.enabled = NO;
            locationStatusLabel.text = @"Location updates denied by parental controls";
            break;
        case kCLAuthorizationStatusNotDetermined:
            locationStartButton.enabled = YES;
            locationStatusLabel.text = @"Location updates unknown";
            break;
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    GLDLocationTracker *tracker = [GLDLocationTracker sharedLocationTracker];
    [tracker addMonitoringDelegate:self];
    [self locationManager:tracker.locationManager didChangeAuthorizationStatus:CLLocationManager.authorizationStatus];
    [[GLDMessageList sharedMessageList] addObserver:self forKeyPath:@"messageCount" options:0 context:NULL];
}

-(void)dealloc
{
    [[GLDLocationTracker sharedLocationTracker] removeMonitoringDelegate:self];
    [[GLDMessageList sharedMessageList] removeObserver:self forKeyPath:@"messageCount"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"messageCount"])
    {
        [messageTableView reloadData];
    }
}

#pragma mark - Message table

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [GLDMessageList sharedMessageList].messageCount;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"message" forIndexPath:indexPath];
    NSDictionary *message = [[GLDMessageList sharedMessageList] messageAtIndex:indexPath.row];
    NSString *alert = message[@"aps"][@"alert"];
    if ([alert isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *alertDict = (NSDictionary *)alert;
        NSString *locKey = alertDict[@"loc-key"];
        if (locKey)
        {
            alert = NSLocalizedString(locKey, @"APS localized key");
            NSArray *locArgs = alertDict[@"loc-args"];
            for (NSString *arg in locArgs)
                alert = [alert stringByAppendingFormat:@":: %@ ",arg];
        }
        else
            alert = alertDict[@"body"];
    }
    cell.textLabel.text = alert;
    return cell;
}
@end

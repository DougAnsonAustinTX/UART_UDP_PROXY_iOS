//
//  Location.m
//  UART_UDP_PROXY
//
//  Created by Doug Anson on 7/25/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "Location.h"

@implementation Location
 
@synthesize location;
@synthesize enabled;

// Send Format - "latitude:longitude:altitude:speed"
    
-(id)init {
    self = [super init];
    [self checkEnabled];
    haveLocation = NO;
    [self initLocationManager];
    return self;
}

-(void)initLocationManager {
    if (self.enabled) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
            [locationManager requestAlwaysAuthorization];
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
                self.enabled = NO;
                locationManager = nil;
            }
            else {
                NSLog(@"Location: Starting Update...");
                [locationManager startUpdatingLocation];
            }
        }
    }
}

-(BOOL)checkEnabled {
    self.enabled = [CLLocationManager locationServicesEnabled];
    if (self.enabled == YES && !([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
        self.enabled = NO;
    }
    
    if (self.enabled) {
        // location reporting is enabled...
        NSLog(@"Location Services are ENABLED");
        self.enabled = YES;
        self.location = @"0.0:0.0:0.0:0.0";
    }
    else {
        // location reporting is disabled...
        NSLog(@"Location Services are DISABLED");
        self.enabled = NO;
        self.location = @"0.0:0.0:-1.0:-1.0";
    }
    return self.enabled;
}
    
-(void)updateLocation {
    if (self.enabled) {
        self.location = [NSString stringWithFormat:@"%.5f:%.5f:%.1f:%.1f",
                            self.myLocation.coordinate.latitude,self.myLocation.coordinate.longitude,
                            self.myLocation.altitude,self.myLocation.speed];
    }
}
    
-(NSString *)getLocation {
    return self.location;
}

// CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    haveLocation = NO;
    if (locations != nil && locations.count > 0) {
        self.myLocation = [locations lastObject];
        haveLocation = YES;
        [self updateLocation];
    }
    
    // DEBUG
    //if (haveLocation == YES) {
    //    NSLog(@"Location: latitude: %.5f  longitude: %.5f  altitude: %.1f  speed: %.1f", self.myLocation.coordinate.latitude,self.myLocation.coordinate.longitude, self.myLocation.altitude,self.myLocation.speed);
    //}
}

@end

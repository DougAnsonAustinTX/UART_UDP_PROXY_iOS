//
//  Location.h
//
//  Created by Doug Anson on 7/25/15.
//  Copyright (c) 2015 Doug Anson. All rights reserved.
//

#ifndef UART_UDP_PROXY_Location_h
#define UART_UDP_PROXY_Location_h

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Location : NSObject <CLLocationManagerDelegate> {
    BOOL                haveLocation;
    CLLocationManager  *locationManager;
}

@property (nonatomic,retain) NSString           *location;
@property (nonatomic,assign) BOOL                enabled;
@property (nonatomic, retain) CLLocation        *myLocation;

// Location Reporting
- (id)init;
- (BOOL)checkEnabled;
- (void)updateLocation;
- (NSString *)getLocation;

// CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;

@end


#endif

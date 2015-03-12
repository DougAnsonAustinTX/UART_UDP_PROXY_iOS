//
//  ScannedPeripheral.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ScannedPeripheral.h"

@implementation ScannedPeripheral

@synthesize peripheral;
@synthesize advertisements;
@synthesize RSSI;

- (id) initWithPeripheral:(CBPeripheral*)p rssi:(int)r advertisement:(NSDictionary *)a {
    self = [super self];
    self.peripheral = p;
    self.advertisements = a;
    self.RSSI = r;
    return self;
}

- (NSString*) name {
    NSString* name = [peripheral name];
    if (name == nil)
        return @"No name";
    return name;
}

- (BOOL)isEqual:(id)object {
    if(object != nil) {
        CBPeripheral *other = (CBPeripheral*) object;
        return (self.peripheral == other);
    }
    return NO;
}

@end

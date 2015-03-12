//
//  ScannedPeripheral.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ScannedPeripheral : NSObject {
}

@property (strong, nonatomic) CBPeripheral* peripheral;
@property (strong, nonatomic) NSDictionary* advertisements;
@property (assign) int RSSI;

- (id)initWithPeripheral:(CBPeripheral*)p rssi:(int)r advertisement:(NSDictionary *)a;
- (NSString*) name;

@end

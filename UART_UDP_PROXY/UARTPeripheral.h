//
//  UARTPeripheral.h
//  nRF UART
//
//  Created by Ole Morten on 1/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UARTPeripheralDelegate.h"
#import "ScannedPeripheral.h"

@interface UARTPeripheral : NSObject <CBPeripheralDelegate> {
}

@property (strong, nonatomic) ScannedPeripheral *peripheral;
@property (strong, nonatomic) id<UARTPeripheralDelegate> delegate;

+ (CBUUID *) uartServiceUUID;
- (UARTPeripheral *) initWithPeripheral:(ScannedPeripheral*)peripheral delegate:(id<UARTPeripheralDelegate>) delegate;
- (void) writeString:(NSString *) string;
- (void) didConnect;
- (void) didDisconnect;

@end

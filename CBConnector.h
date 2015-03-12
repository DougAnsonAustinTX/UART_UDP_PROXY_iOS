//
//  CBConnector.h
//  UART_UDP_PROXY
//
//  Created by Doug Anson on 2/21/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#ifndef UART_UDP_PROXY_CBConnector_h
#define UART_UDP_PROXY_CBConnector_h

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannedPeripheral.h"

@interface CBConnector : NSObject <CBCentralManagerDelegate> {
}

@property (retain, nonatomic) CBCentralManager            *m_cm;
@property (retain, nonatomic) id<CBCentralManagerDelegate> m_delegate;
@property (retain, nonatomic) dispatch_queue_t             m_queue;
@property (retain, nonatomic) NSString                    *m_queue_name;

- (id) init:(id<CBCentralManagerDelegate>)delegate  queueName:(NSString *)queue_name;

- (void) startScan;
- (void) stopScan;
- (BOOL) poweredOn;

// CBCentralManagerDelegate
- (void) centralManagerDidUpdateState:(CBCentralManager *)central;
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@end

#endif

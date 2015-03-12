//
//  CBConnector.m
//  UART_UDP_PROXY
//
//  Created by Doug Anson on 2/21/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "CBConnector.h"

@implementation CBConnector

@synthesize m_delegate;
@synthesize m_cm;
@synthesize m_queue;
@synthesize m_queue_name;

- (id) init:(id<CBCentralManagerDelegate>)delegate queueName:(NSString *)queue_name {
    self = [super init];
    self.m_delegate = delegate;
    self.m_queue_name = queue_name;
    [self initCM];
    return self;
}

- (void) initCM {
    // We want the scanner to scan with dupliate keys (to refresh RRSI every second) so it has to be done using non-main queue
    self.m_queue = dispatch_queue_create([self.m_queue_name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    self.m_cm = [[CBCentralManager alloc]initWithDelegate:self queue:self.m_queue];
}

- (void) startScan {
    [self.m_cm scanForPeripheralsWithServices:nil options:nil];
}

- (void) stopScan {
    [self.m_cm stopScan];
}

- (BOOL) poweredOn {
    if (self.m_cm.state == CBCentralManagerStatePoweredOn) return YES;
    return NO;
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
    [self.m_delegate centralManagerDidUpdateState:central];
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    [self.m_delegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self.m_delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self.m_delegate centralManager:central didConnectPeripheral:peripheral];
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self.m_delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
}

@end

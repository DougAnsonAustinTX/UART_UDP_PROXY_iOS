//
//  UARTPeripheralDelegate.h
//  UART_UDP_PROXY
//
//  Created by Doug Anson on 2/19/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#include <UIKit/UIKit.h>

@protocol UARTPeripheralDelegate
- (void) didReceiveData:(NSString *) string;
@optional
- (void) didReadHardwareRevisionString:(NSString *) string;
- (void)beginConnection:(int)index UARTDelegate:(id<UARTPeripheralDelegate>)uart_delegate withPeripherals:(NSMutableArray *)peripherals;
@end

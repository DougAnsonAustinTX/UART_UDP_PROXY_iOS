//
//  UartRPCProtocol.h
//  nRF UART
//
//  Created by Doug Anson on 2/19/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UartRPCProtocol <NSObject>
    -(BOOL)sendOverUART:(NSData *)data;
    -(void)ackSocketOpen:(BOOL)open_ok;
    -(void)onDataReceived:(NSString *)data;
    -(void)sendData:(NSString *)data;
    -(BOOL)splitAndSendData:(NSString *)data;
    -(void)disconnectSocket;
@end

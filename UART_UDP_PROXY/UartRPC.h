//
//  UartRPC.h
//  nRF UART
//
//  Created by Doug Anson on 2/19/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#ifndef nRF_UART_UartRPC_h
#define nRF_UART_UartRPC_h

#import <Foundation/Foundation.h>
#import "UartRPCProtocol.h"
#import "GCDAsyncUdpSocket.h"
#import "Location.h"

typedef enum
{
    SOCKET_OPEN_FN  = 0x01,
    SOCKET_CLOSE_FN = 0x02,
    SEND_DATA_FN    = 0x04,
    RECV_DATA_FN    = 0x08,
    GET_LOCATION_FN = 0x16
} FunctionIDs;

@interface UartRPC : NSObject <GCDAsyncUdpSocketDelegate> {
    NSString    *_DELIMITER;
    NSString    *_HEAD;
    NSString    *_TAIL;
    
    int         m_port;
    BOOL        m_send_status;
    int         m_timeout;
    int         m_tag;
    int         m_receive_buffer_size;
    int         m_send_length;
}

@property (retain, nonatomic) id<UartRPCProtocol> m_handler;
@property (retain, nonatomic)           NSString *m_args;
@property (assign)                            int m_fn_id;
@property (retain, nonatomic)           NSString *m_accumulator;
@property (retain, nonatomic)           NSString *m_address;
@property (retain, nonatomic)  GCDAsyncUdpSocket *m_udp_socket;
@property (retain, nonatomic)  Location          *m_location;

-(id)init:(id<UartRPCProtocol>)handler;
-(void)stopListener;
-(void)reset;
-(BOOL)accumulate:(NSString *)data;
-(NSString *)getAccumulation;
-(BOOL)dispatch;
-(NSArray *)parse:(NSString *)data;
-(BOOL)dispatch:(NSArray *)rpc_call;
-(BOOL)rpc_socket_open:(NSString *)data;
-(void)close;
-(BOOL)rpc_socket_close:(NSString *)args;
-(void)createListener;
-(void)closeSocket;
-(NSString *)rpc_recv_data:(NSData *)data withLength:(int)length;
-(BOOL)rpc_send_data:(NSString *)data;
-(NSData *)decode:(NSString *)data;
-(NSString *)encode:(NSData *)data withLength:(int)length;
-(NSString *)trimData:(NSString *)data;

// GCDAsyncUdpSocketDelegate
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address;
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error;
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag;
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error;
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext;
-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error;

@end

#endif

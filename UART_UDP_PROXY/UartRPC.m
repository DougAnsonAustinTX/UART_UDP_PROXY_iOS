//
//  UartRPC.m
//  nRF UART
//
//  Created by Doug Anson on 2/19/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "UartRPC.h"

@implementation UartRPC

@synthesize m_handler;
@synthesize m_fn_id;
@synthesize m_accumulator;
@synthesize m_args;
@synthesize m_address;
@synthesize m_udp_socket;

-(id)init:(id<UartRPCProtocol>)handler {
    self = [super init];
    
    [self reset];

    // caller
    self.m_handler = handler;
    
    // socket handles
    self.m_udp_socket = nil;
    
    // framing delimiters...
    _HEAD       = @"[";
    _TAIL       = @"]";
    _DELIMITER  = @"|";
    
    m_send_status = NO;
    
    // AsyncUdpSocket configuration
    m_timeout = 15;                 // 15 second timeout
    m_receive_buffer_size = 8192;   // UDP socket buffer size
    m_tag = 0;                      // our TAG
    m_send_length = 0;
    
    return self;
}

-(void)reset {
    self.m_fn_id = 0;
    self.m_args = @"";
    self.m_accumulator = @"";
}

-(BOOL)accumulate:(NSString *)data {
    BOOL do_dispatch = NO;
    
    if (data != nil && data.length > 0) {
        // accumulate...
        self.m_accumulator = [self.m_accumulator stringByAppendingFormat:@"%@",data];
        
        // see if we have everything...
        if ([self.m_accumulator rangeOfString:_HEAD options:NSCaseInsensitiveSearch].location != NSNotFound && [self.m_accumulator rangeOfString:_TAIL options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // ready to dispatch
            NSLog(@"accumulate(): packet ready for dispatch...");
            do_dispatch = YES;
        }
        else {
            // continue accumulating
            NSLog(@"accumulate(): continue accumulating...");
        }
    }
    else if (data != nil) {
        NSLog(@"accumulate(): data length is 0... ignoring...");
    }
    else {
        NSLog(@"accumulate(): data is NULL... ignoring...");
    }
    
    return do_dispatch;
}

-(NSString *)getAccumulation {
    return self.m_accumulator;
}

-(BOOL)dispatch {
    return [self dispatch:[self parse:self.m_accumulator]];
}

-(NSArray *)parse:(NSString *)data {
    //NSLog(@"parse() raw: {%@}",data);
    NSString *tmp1 = [data stringByReplacingOccurrencesOfString:_HEAD withString:@""];
    NSString *tmp2 = [tmp1 stringByReplacingOccurrencesOfString:_TAIL withString:@""];
    //NSLog(@"parse() parsed: {%@}",tmp2);
    return [tmp2 componentsSeparatedByString:_DELIMITER];
}

-(BOOL)dispatch:(NSArray *)rpc_call {
    BOOL success = NO;
    
    // slot 0 is the RPC command fn id, slot 1 is the RPC args...
    @try {
        self.m_fn_id = [rpc_call[0] intValue];
        self.m_args = rpc_call[1];
        //NSLog(@"dispatch(): fn_id=%d rpc_call: {%@} args: [%@]",self.m_fn_id,rpc_call,self.m_args);
        
        // dispatch to appropriate function for processing
        switch (self.m_fn_id) {
            case SOCKET_OPEN_FN:
                success = [self rpc_socket_open:self.m_args];
                [self.m_handler ackSocketOpen:success];
                break;
            case SOCKET_CLOSE_FN:
                success = [self rpc_socket_close:self.m_args];
                break;
            case SEND_DATA_FN:
                success = [self rpc_send_data:self.m_args];
                break;
            default:
                NSLog(@"dispatch(): IMPROPER fn_id=%d args: [%@]... ignoring...",self.m_fn_id,self.m_args);
                break;
        }
    }
    @catch (NSException *ex) {
        NSLog(@"dispatch(): Exception in dispatch(): %@",ex.reason);
    }
    
    // reset if successful...
    [self reset];
    
    // return our status
    return success;
}

-(BOOL)rpc_socket_open:(NSString *)data {
    @try {
        NSArray *args = [data componentsSeparatedByString:@" "];
        
        // parse args
        self.m_address = args[0];
        m_port = [args[1] intValue];
        
        // open the socket...
        NSLog(@"rpc_open_socket(): opening UDP Socket: %@@%d",args[0],m_port);
        if (self.m_udp_socket == nil) {
            // create our sockets
            self.m_udp_socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
            [self.m_udp_socket setPreferIPv4];
            
            // create our listener
            [self createListener];
            
            // success
            return YES;
        }
    }
    @catch(NSException *ex) {
        NSLog(@"rpc_open_socket(): openSocket() failed: %@... closing...",ex.reason);
        [self rpc_socket_close:nil];
    }
    
    return NO;
}

-(void)close {
    [self stopListener];
    [self rpc_socket_close:nil];
}

-(BOOL)rpc_socket_close:(NSString *)args {
    NSLog(@"close(): closing socket...");
    [self closeSocket];
    NSLog(@"close(): resetting to default...");
    [self reset];
    NSLog(@"close(): completed.");
    return YES;
}

-(void)stopListener {
    
}

-(void)createListener {
    // launch the listener thread
    dispatch_async(dispatch_get_main_queue(), ^{
        // Listener Thread dispatch
        NSError *error = nil;
        
        // DEBUG
        NSLog(@"createListener: listening on UDP port %d...",m_port);
        
        // bind to the UDP port
        if ([self.m_udp_socket bindToPort:m_port error:&error] == YES) {
            // enable broadcast
            if ([self.m_udp_socket enableBroadcast:YES error:&error] == YES) {
                // register and schedule our listener
                [self.m_udp_socket beginReceiving:&error];
            }
            else {
                // we had an error
                NSLog(@"error in enabling broadcast on UDP port %d",m_port);
            }
        }
        else {
            // we had an error
            NSLog(@"error in binding to UDP port %d",m_port);
        }
    });

}

-(void)closeSocket {
    if (self.m_udp_socket != nil) [self.m_udp_socket close];
    self.m_udp_socket = nil;
}

-(NSString *)rpc_recv_data:(NSData *)data withLength:(int)length {
    // encode the data
    NSLog(@"rpc_recv_data: Base64 encoding payload...");
    NSString *encoded_data = [self encode:data withLength:length];
    if (encoded_data != nil) {
        // create the header and frame
        NSLog(@"rpc_recv_data: creating frame...");
        return [NSString stringWithFormat:@"%@%d%@%@%@",_HEAD,RECV_DATA_FN,_DELIMITER,encoded_data,_TAIL];
    }
    return nil;
}

-(BOOL)rpc_send_data:(NSString *)data {
    m_send_status = NO;
    
    // decode out of Base64...
    NSData *raw_bytes = [self decode:data];
    if (self.m_udp_socket != nil && raw_bytes != nil) {
        // send the data over UDP
        NSLog(@"rpc_send_data(): sending %d bytes to %@@%d...",(int)data.length,self.m_address,m_port);
        m_send_length = (int)raw_bytes.length;
        [self.m_udp_socket sendData:raw_bytes toHost:self.m_address port:m_port withTimeout:m_timeout tag:m_tag];
        m_send_status = YES;
    }
    else if (self.m_udp_socket != nil) {
        NSLog(@"send() failed: as data was null or had zero length");
    }
    else {
        NSLog(@"send() failed: as socket was null");
    }
    return m_send_status;
}

-(NSData *)decode:(NSString *)data {
    return [[NSData alloc] initWithBase64EncodedString:data options:0];
}

-(NSString *)encode:(NSData *)data withLength:(int)length {
    return [data base64EncodedStringWithOptions:0];
}

-(NSString *)trimData:(NSString *)data {
    if (data != nil)
        return [data stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    else
        return nil;
}

// GCDAsyncUdpSocketDelegate
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSString *host = nil;
    uint16_t port = 0;
    
    // Get our Host and port
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
     NSLog(@"rpc_sock_open(): connected to %@@%hu",host,port);
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    NSLog(@"rpc_sock_open(): unable to connect");
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"rpc_send_data() send of %d bytes successful.",m_send_length);
    m_send_length = 0;
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"rpc_send_data() send of %d bytes FAILED.",m_send_length);
    m_send_length = 0;
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    int tag = 0;
    NSString *host = nil;
    uint16_t port = 0;
    
    // Get our Host and port
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    
    // received packet... so process it...
    NSLog(@"didReceiveData: received data from %@@%d %d bytes (tag: %d our tag: %d)...",host,port,(int)data.length,(int)tag,m_tag);
    if (tag == m_tag && data != nil) {
        // process the data...
        NSLog(@"didRecieveData: calling sendOverUART to send frame with length: %d bytes...",(int)data.length);
        [self.m_handler sendOverUART:data];
    }
    else if (tag == m_tag) {
        // no data!  so ignore
        NSLog(@"UartRPC: UDP socket received but without data... ignoring...");
    }
    else {
        // wrong tag...
        NSLog(@"UartRPC: UDP socket received data but for wrong tag: %d  my tag: %d... ignoring...",(int)tag,m_tag);
    }
}

-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    if (sock == self.m_udp_socket)
        NSLog(@"onUdpSocketDidClose: UDP socket closed...");
}

@end
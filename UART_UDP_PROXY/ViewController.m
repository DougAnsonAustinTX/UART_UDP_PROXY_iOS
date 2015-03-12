//
//  ViewController.m
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ViewController.h"

typedef enum
{
    IDLE = 0,
    CANCELLED,
    SCANNING,
    CONNECTED,
} ConnectionState;

@interface ViewController ()
@property ConnectionState state;
@property UARTPeripheral *currentPeripheral;
@end

@implementation ViewController
@synthesize currentPeripheral = _currentPeripheral;
@synthesize m_uart_rpc;
@synthesize m_scanner;
@synthesize m_connector;
@synthesize m_preferences;

// DA
-(void)logAction:(NSData *)data from:(NSString *)from to:(NSString *)to {
    NSString *log_text = [NSString stringWithFormat:@"(%@->%@): %d bytes...",from,to,(int)data.length];
    [self addTextToConsole:log_text];
}

// DA
-(void)ackSocketOpen:(BOOL)open_ok {
    int opened = 0;
    if (open_ok) opened = 1;
    NSString *socket_open_ack = [NSString stringWithFormat:@"[1|%d]",opened];
    
    NSLog(@"ackSocketOpen(): ack: %@ being sent for socket() open status...",socket_open_ack);
    [self sendData:socket_open_ack];
}

// DA
-(void)disconnectSocket {
    if (self.m_uart_rpc != nil) [self.m_uart_rpc close];
}

// DA
-(void)sendData:(NSString *)str_data {
    NSData *data = [str_data dataUsingEncoding:NSUTF8StringEncoding];
    [self logAction:data from:@"UDP" to:@"UART"];
    [self.currentPeripheral writeString:str_data];
}

// DA
-(NSArray *)splitEqually:(NSString *)text splitLength:(int)size {
    NSMutableArray* split_string = [[NSMutableArray alloc] init];
    while (text.length > 0) {
        NSString* substring = [text substringWithRange:NSMakeRange(0, MIN(size, text.length))];
        [split_string addObject:substring];
        text = [text stringByReplacingCharactersInRange:NSMakeRange(0, MIN(size, text.length)) withString:@""];
    }
    return split_string;
}

// DA
-(BOOL)sendOverUART:(NSData *)data {
    NSString *packet = [self.m_uart_rpc rpc_recv_data:data withLength:(int)data.length];
    if (packet != nil) {
        NSLog(@"sendOverUART(): encoded_data=[%@] length: %d... splitting...",packet,(int)packet.length);
        NSArray *list = [self splitEqually:packet splitLength:(int)20];
        for(int i=0;i<list.count;++i) {
            [self sendData:list[i]];
        }
    }
    else {
        NSLog(@"sendOverUART(): dropping null packet. Base64 encoding failed..");
    }
    return YES;
}

// DA
-(void)onDataReceived:(NSString *)data {
    if (data != nil && data.length > 0) {
        NSString *trimmed_data = [self.m_uart_rpc trimData:data];
        // if we received an ACK... we will ignore it...
        if ([trimmed_data rangeOfString:@"ACK" options:NSCaseInsensitiveSearch].location == NSNotFound) {
            NSLog(@"onDataReceived(): data=[%@] length: %d",trimmed_data,(int)trimmed_data.length);
            if ([self.m_uart_rpc accumulate:trimmed_data] == YES) {
                NSData *tmp = [[self.m_uart_rpc getAccumulation] dataUsingEncoding:NSUTF8StringEncoding];
                [self logAction:tmp from:@"UART" to:@"UDP"];
                BOOL success = [self.m_uart_rpc dispatch];
                if (success == YES)
                    NSLog(@"onDataRecieved: dispatch() succeeded (UART->UDP)");
                else
                    NSLog(@"onDataRecieved: dispatch() FAILED (UART->UDP).");
            }
            
            // send back an ACK byte... this will reset the notifications and will allow the peer to continue...
            [self sendData:@"ACK"];
        }
        else {
            // just received an ACK... so no need to reply with another...
            NSLog(@"onDataReceived(): recevied ACK (OK)... continuing...");
        }
    }
}

-(void)beginConnection:(int)index UARTDelegate:(id<UARTPeripheralDelegate>)uart_delegate withPeripherals:(NSMutableArray *)peripherals {
    UARTPeripheral *uart_peripheral = [[UARTPeripheral alloc] initWithPeripheral:[peripherals objectAtIndex:index] delegate:uart_delegate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self beginConnection:uart_peripheral];
    });
    
}

- (void) beginConnection:(UARTPeripheral *)peripheral {
    self.m_connector.m_delegate = self;
    self.currentPeripheral = peripheral;
    [self.m_connector.m_cm connectPeripheral:self.currentPeripheral.peripheral.peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.consoleTextView.delegate = self;
    self.m_preferences = [[PreferenceManager alloc] init:@"UART_UDP_PROXY"];
    self.m_connector = [[CBConnector alloc] init:self queueName:@"UART_UDP_PROXY"];
    self.m_scanner = [[ScannerViewController alloc] initWithNibName:@"ScannerView" bundle:nil parent:self connector:self.m_connector prefManager:self.m_preferences];
    
    [self addTextToConsole:@"Ready..."];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self writeLog:@"Device: <not connected> - Ready."];
    
    // create our RPC handler
    self.m_uart_rpc = [[UartRPC alloc] init:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) writeLog:(NSString *)log {
    self.logTextView.text = log;
}

- (void) centralManager:(CBCentralManager*) manager didPeripheralSelected:(ScannedPeripheral*)mysp {
    // do nothing
    ;
}

- (IBAction) connectButtonPressed:(id)sender
{
    switch (self.state) {
        case IDLE: {
            [self invokeScanner];
            break;
        }
        case SCANNING: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Connect request stopped... ");
                self.state = IDLE;
                [self writeLog:@"Connect request stopped. Ready..."];
                [self addTextToConsole:@"Connect request stopped. Ready..."];
                [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
                [self.view setNeedsDisplay];
                [self.view setNeedsLayout];
                [self.m_connector stopScan];
                if (self.currentPeripheral.peripheral != nil) [self.m_connector.m_cm cancelPeripheralConnection:self.currentPeripheral.peripheral.peripheral];
                [self disconnectSocket];
            });
            break;
        }
        case CONNECTED: {
            [self disconnect];
            break;
        }
        default: {
            break;
        }
    }
}

- (void) invokeScanner {
    self.state = SCANNING;
    
    NSLog(@"Started scan ...");
    [self writeLog:@"Scanning for device..."];
    [self addTextToConsole:@"Scanning for device..."];
    [self.connectButton setTitle:@"Scanning ..." forState:UIControlStateNormal];
    
    // switch to the scanner view
    dispatch_async(dispatch_get_main_queue(), ^{
        self.m_connector.m_delegate = self.m_scanner;
        [self.m_scanner switchViews:self];
    });
}

- (void) viewWillAppear:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (self.state) {
            case CANCELLED: {
                NSLog(@"Stopped scan");
                self.state = IDLE;
                [self writeLog:@"Scan stopped. Ready..."];
                [self addTextToConsole:@"Scan stopped. Ready..."];
                [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
                [self.view setNeedsDisplay];
                [self.view setNeedsLayout];
                if (self.currentPeripheral.peripheral != nil) [self.m_connector.m_cm cancelPeripheralConnection:self.currentPeripheral.peripheral.peripheral];
                break;
            }
            case SCANNING: {
                [self.connectButton setTitle:@"Cancel Connect..." forState:UIControlStateNormal];
                [self.view setNeedsDisplay];
                [self.view setNeedsLayout];
                break;
            }
            default: {
                
                break;
            }
        }
    });
}

- (void) disconnect {
    NSLog(@"Disconnecting socket...");
    [self disconnectSocket];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Disconnecting BLE peripheral %@", self.currentPeripheral.peripheral.name);
        [self.m_connector.m_cm cancelPeripheralConnection:self.currentPeripheral.peripheral.peripheral];
        
        [self addTextToConsole:@"Ready..."];
        [self addTextToConsole:@"Disconnected. Ready..."];
    });
}


- (void) didReadHardwareRevisionString:(NSString *)string
{
    [self addTextToConsole:[NSString stringWithFormat:@"Hardware revision: %@", string]];
}

- (void) didReceiveData:(NSString *)myString
{
    NSString *displayString = [[myString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    NSLog(@"Received data RX: [%@]",displayString);
    [self logAction:[displayString dataUsingEncoding:NSUTF8StringEncoding] from:@"UART" to:@"UDP"];
    [self onDataReceived:displayString];
}

-(IBAction) clearConsole:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"clearing console");
        self.consoleTextView.text = @"Log cleared";
        [self.consoleTextView setScrollEnabled:NO];
        NSRange bottom = NSMakeRange(self.consoleTextView.text.length-1, self.consoleTextView.text.length);
        [self.consoleTextView scrollRangeToVisible:bottom];
        [self.consoleTextView setScrollEnabled:YES];
        [self.consoleTextView setNeedsLayout];
        [self.consoleTextView setNeedsDisplay];
    });
}

- (void) cancelledScan {
    self.state = CANCELLED;
    [self writeLog:@"Scan stopped. Ready..."];
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
}

- (void) addTextToConsole:(NSString *) string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *formatter;
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm:ss"];

        self.consoleTextView.text = [self.consoleTextView.text stringByAppendingFormat:@"[%@]: %@\n",[formatter stringFromDate:[NSDate date]],string];
        
        [self.consoleTextView setScrollEnabled:NO];
        NSRange bottom = NSMakeRange(self.consoleTextView.text.length-1, self.consoleTextView.text.length);
        [self.consoleTextView scrollRangeToVisible:bottom];
        [self.consoleTextView setScrollEnabled:YES];
        [self.consoleTextView setNeedsLayout];
        [self.consoleTextView setNeedsDisplay];
    });
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [textView scrollRangeToVisible:textView.selectedRange];
        [self.view setNeedsLayout];
        [self.view setNeedsDisplay];
    });
    
}

- (BOOL)textView:(UITextView *)tView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    CGRect textRect = [tView.layoutManager usedRectForTextContainer:tView.textContainer];
    CGFloat sizeAdjustment = tView.font.lineHeight * [UIScreen mainScreen].scale;
    
    // if (textRect.size.height >= tView.frame.size.height - sizeAdjustment) {
    if (textRect.size.height >= tView.frame.size.height - tView.contentInset.bottom - sizeAdjustment) {
        [UIView animateWithDuration:0.2 animations:^{
            [tView setContentOffset:CGPointMake(tView.contentOffset.x, tView.contentOffset.y + sizeAdjustment)];
        }];
    }
    
    return YES;
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"ViewController in centralManagerDidUpdateState...");
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [self.connectButton setEnabled:YES];
    }
    
}

#pragma mark CBCentralManagerDelegate methods

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)data RSSI:(NSNumber *)RSSI {
    // not used
    ;
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSString *text = [NSString stringWithFormat:@"Connect failed: %@: %@",peripheral.name,[error localizedDescription]];
    [self addTextToConsole:text];
    [self writeLog:text];
    NSLog(@"Connect failed: %@: %@",peripheral.name,[error localizedDescription]);
    [self disconnect];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSString *text = [NSString stringWithFormat:@"Connected to %@",peripheral.name];
    [self addTextToConsole:text];
    [self writeLog:text];
    NSLog(@"Connected to %@",peripheral.name);
    
    self.state = CONNECTED;
    
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    if ([self.currentPeripheral.peripheral.peripheral isEqual:peripheral]) {
        [self.currentPeripheral didConnect];
    }
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSString *text = [NSString stringWithFormat:@"Disconnected from %@. Ready...",peripheral.name];
    [self addTextToConsole:text];
    [self writeLog:text];
    NSLog(@"Disconnected from %@", peripheral.name);
    
    self.state = IDLE;
    
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral]) {
        NSLog(@"Disconnect: cleaning up BLE peripheral...");
        [self.currentPeripheral didDisconnect];
    }
    [self clearConsole:self.consoleTextView];
    [self addTextToConsole:@"Ready..."];
}

@end

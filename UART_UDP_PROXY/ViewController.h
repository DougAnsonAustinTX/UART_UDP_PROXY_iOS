//
//  ViewController.h
//  nRF UART
//
//  Created by Ole Morten on 1/11/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UARTPeripheral.h"
#import "UARTPeripheralDelegate.h"
#import "UartRPC.h"
#import "UartRPCProtocol.h"
#import "ScannerDelegate.h"
#import "ScannerViewController.h"
#import "PreferenceManager.h"

@interface ViewController : UITableViewController <UITextViewDelegate, CBCentralManagerDelegate, UARTPeripheralDelegate, UartRPCProtocol, ScannerDelegate> {
    int m_max_num_lines;
    int m_num_lines;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *clearAutoButton;
@property (weak, nonatomic) IBOutlet UITextView *consoleTextView;
@property (weak, nonatomic) IBOutlet UILabel *logTextView;
@property (retain, nonatomic) UartRPC *m_uart_rpc;
@property (retain, nonatomic) ScannerViewController *m_scanner;
@property (retain, nonatomic) CBConnector *m_connector;
@property (retain, nonatomic) PreferenceManager *m_preferences;

- (IBAction)connectButtonPressed:(id)sender;
- (IBAction)clearAutoButtonPressed:(id)sender;
- (IBAction)clearConsole:(id)sender;
- (void) writeLog:(NSString *)log;

- (void) didReceiveData:(NSString *) string;

// DA
- (void) cancelledScan;
- (void) invokeScanner;
- (void)viewWillAppear:(BOOL)animated;
- (void) disconnect;

- (void) beginConnection:(UARTPeripheral *)peripheral;

// DA
- (void)textViewDidChangeSelection:(UITextView *)textView;
- (BOOL)textView:(UITextView *)tView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

// DA - CBCentralManagerDelegate
- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

// DA
-(void)logAction:(NSData *)data from:(NSString *)from to:(NSString *)to;
-(NSArray *)splitEqually:(NSString *)text splitLength:(int)size;

// DA - UartRPCProtocol
-(BOOL)sendOverUART:(NSData *)data;
-(void)ackSocketOpen:(BOOL)open_ok;
-(void)onDataReceived:(NSString *)data;
-(void)sendData:(NSString *)data;
-(void)disconnectSocket;

// DA - handle connection to BLE peripheral
-(void)beginConnection:(int)index UARTDelegate:(id<UARTPeripheralDelegate>)uart_delegate withPeripherals:(NSMutableArray *)peripherals;

@end

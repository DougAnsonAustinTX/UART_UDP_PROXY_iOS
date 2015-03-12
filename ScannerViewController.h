//
//  ScannerViewController.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"
#import "CBConnector.h"
#import "PreferenceManager.h"

@interface ScannerViewController : UIViewController <CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource, UARTPeripheralDelegate>

@property (retain, nonatomic) IBOutlet UITableView *devicesTable;
@property (retain, nonatomic) IBOutlet UIButton *closeButton;
@property (retain, nonatomic) id <ScannerDelegate> delegate;
@property (retain, nonatomic) CBUUID *filterUUID;
@property (retain, nonatomic) id<CBCentralManagerDelegate> m_parent;
@property (retain, nonatomic) CBConnector *m_connector;
@property (retain, nonatomic) PreferenceManager *m_preferences;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil parent:(id<CBCentralManagerDelegate>) parent connector:(CBConnector *) connector prefManager:(PreferenceManager *)preferences;
- (IBAction)didCancelClicked:(id)sender;
- (void) switchViews:(UIViewController *)parent_vc;
- (void) viewWillAppear:(BOOL)animated;

- (void) didReceiveData:(NSString *) string;
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void) reset;

@end

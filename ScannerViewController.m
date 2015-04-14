//
//  ScannerViewController.m
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 16/12/13.
//  Copyright (c) 2013 Nordic Semiconductor. All rights reserved.
//

#import "ViewController.h"
#import "ScannerTableViewCell.h"
#import "ScannedPeripheral.h"
#import "UARTPeripheralDelegate.h"

@interface ScannerViewController ()

@property (retain, nonatomic) NSMutableArray *peripherals;
@property (retain, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UARTPeripheral *currentPeripheral;

- (void)timerFireMethod:(NSTimer *)timer;

@end

@implementation ScannerViewController

@synthesize devicesTable;
@synthesize filterUUID;
@synthesize peripherals;
@synthesize timer;
@synthesize closeButton;
@synthesize m_parent;
@synthesize m_connector;
@synthesize currentPeripheral;
@synthesize m_preferences;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil parent:(id<CBCentralManagerDelegate>) parent connector:(CBConnector *)connector prefManager:(PreferenceManager *)preferences {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.filterUUID = nil;
        self.m_parent = parent;
        self.m_connector = connector;
        connector.m_delegate = self;
        self.m_preferences = preferences;
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    self.peripherals = [[NSMutableArray alloc] init];
    self.devicesTable.delegate = self;
    self.devicesTable.dataSource = self;
}

- (void) viewWillAppear:(BOOL)animated {
    if (self.m_connector.m_cm.state == CBCentralManagerStatePoweredOn) {
        [self scanForPeripherals:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self scanForPeripherals:NO];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) didCancelClicked:(id)sender {
    [self.m_connector stopScan];
    ViewController *vc = (ViewController *)self.m_parent;
    [vc cancelledScan];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Central Manager delegate methods

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    if (self.m_parent != nil)
        [self.m_parent centralManagerDidUpdateState:central];
}

- (int) scanForPeripherals:(BOOL)enable {
    if (![self.m_connector poweredOn]) return -1;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if (enable) {
            [self.m_connector startScan];
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
        }
        else {
            [timer invalidate];
            timer = nil;
            [self.m_connector stopScan];
        }
    });
    return 0;
}

-(void)timerFireMethod:(NSTimer *)timer {
    [devicesTable reloadData];
}

-(void)switchViews:(UIViewController *)parent_vc {
    [parent_vc presentViewController:self animated:YES completion:nil];
}

-(BOOL)hasValidName:(CBPeripheral *)peripheral {
    BOOL named = NO;
    
    if (peripheral.name != nil && peripheral.name.length > 0 ) {
        named = ([peripheral.name isEqualToString:@"No name"] == NO) &&
                ([peripheral.name isEqualToString:@"Apple TV"] == NO);
    }
    
    return named;
}

-(BOOL)peripheralMatchesAutoJoin {
    BOOL matched = NO;
    
    ViewController *vc = (ViewController *)self.m_parent;
    NSString *name = [vc.m_preferences getPreference:@"DEFAULT_JOIN"];
    
    @synchronized(self) {
        for(int i=0;name != nil && name.length > 0 && i<self.peripherals.count && !matched;++i) {
            ScannedPeripheral *peripheral = (ScannedPeripheral *)[self.peripherals objectAtIndex:i];
            if ([name isEqualToString:peripheral.name]) {
                [vc.m_preferences setPreference:@"DEFAULT_JOIN_INDEX" withIntValue:i];
                matched = YES;
            }
        }
    }
    
    return matched;
}

-(void)bindToPeripheral:(int)index {
    id<UARTPeripheralDelegate> parent = (id<UARTPeripheralDelegate>)self.m_parent;
    [self dismissViewControllerAnimated:NO completion:nil];
    [parent beginConnection:index UARTDelegate:parent withPeripherals:peripherals];
}

-(int)getAutoJoinIndex {
    ViewController *vc = (ViewController *)self.m_parent;
    return [vc.m_preferences getIntPreference:@"DEFAULT_JOIN_INDEX"];
}

-(void)reset {
    [peripherals removeAllObjects];
    ViewController *vc = (ViewController *)self.m_parent;
    [vc disconnect];
    if (self.m_connector.m_cm.state == CBCentralManagerStatePoweredOn) {
        [self scanForPeripherals:YES];
    }
}

#pragma mark CBCentralManagerDelegate methods

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    // Scanner uses other queue to send events. We must edit UI in the main queue
    // Add the sensor to the list and reload deta set
    ScannedPeripheral *sensor = [[ScannedPeripheral alloc] initWithPeripheral:peripheral rssi:RSSI.intValue advertisement:advertisementData];
    if (![peripherals containsObject:sensor])
    {
        @synchronized(self) {
            if ([self hasValidName:peripheral])
                [peripherals addObject:sensor];
        }
    }
    else
    {
        @synchronized(self) {
            sensor = [peripherals objectAtIndex:[peripherals indexOfObject:sensor]];
            sensor.advertisements = advertisementData;
            sensor.RSSI = RSSI.intValue;
        }
    }
    
    // if we find an auto-join defaulted, go ahead and bind
    if ([self peripheralMatchesAutoJoin]) {
        @synchronized(self) {
            [self bindToPeripheral:[self getAutoJoinIndex]];
        }
    }
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // do nothing
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // do nothing
    ;
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // do nothing
    ;
}

#pragma mark UARTPeripheralDelegate methods
- (void) didReceiveData:(NSString *) string {
    // do nothing
    ;
}

#pragma mark Table View delegate methods

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self bindToPeripheral:(int)indexPath.row];
}

#pragma mark Table View Data Source delegate methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return peripherals.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ScannerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        NSArray *nib=[[NSBundle mainBundle] loadNibNamed:@"ScannerCellView" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.preferences = self.m_preferences;
        cell.indexPath = indexPath;
    }
    
    // Update sensor name
    if (peripherals != nil && peripherals.count > indexPath.row) {
        @synchronized(self) {
            ScannedPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
            cell.title.text = [peripheral name];
            [cell setAutoJoinStatus];
        
            // Update RSSI indicator
            int RSSI = peripheral.RSSI;
            UIImage* image;
            if (RSSI < -90) {
                image = [UIImage imageNamed: @"Signal_0"];
            }
            else if (RSSI < -70) {
                image = [UIImage imageNamed: @"Signal_1"];
            }
            else if (RSSI < -50) {
                image = [UIImage imageNamed: @"Signal_2"];
            }
            else {
                image = [UIImage imageNamed: @"Signal_3"];
            }
            cell.signal.image = image;
        }
    }
    return cell;
}

@end

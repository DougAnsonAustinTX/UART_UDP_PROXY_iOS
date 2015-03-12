//
//  ScannerTableViewCell.h
//  UART_UDP_PROXY
//
//  Created by Doug Anson on 2/20/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#ifndef UART_UDP_PROXY_ScannerTableViewCell_h
#define UART_UDP_PROXY_ScannerTableViewCell_h

#import <UIKit/UIKit.h>
#import "PreferenceManager.h"

@interface ScannerTableViewCell : UITableViewCell {
    IBOutlet UIButton *setAsAutoJoinDefaultButton;
}

@property (retain,nonatomic) IBOutlet UIImageView *signal;
@property (retain,nonatomic) IBOutlet UILabel     *title;
@property (retain,nonatomic) PreferenceManager    *preferences;
@property (assign) BOOL                            isDefault;
@property (retain,nonatomic) NSIndexPath          *indexPath;

-(IBAction)setAsAutoJoinDefault:(id)button;
-(void) setAutoJoinStatus;

@end

#endif

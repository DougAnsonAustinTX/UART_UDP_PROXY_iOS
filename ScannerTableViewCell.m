//
//  ScannerTableViewCell.m
//  UART_UDP_PROXY
//
//  Created by Doug Anson on 2/20/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "ScannerTableViewCell.h"

@implementation ScannerTableViewCell

@synthesize signal;
@synthesize title;
@synthesize preferences;
@synthesize isDefault;
@synthesize indexPath;

-(IBAction)setAsAutoJoinDefault:(id)button {
    if (self.isDefault) {
        NSLog(@"Removing as default: %@",title.text);
        [button setTitle: @"Auto" forState: UIControlStateNormal];
        self.isDefault = NO;
        [self.preferences setPreference:@"DEFAULT_JOIN" withValue:@""];
        [self.preferences setPreference:@"DEFAULT_JOIN_INDEX" withIntValue:-1];

    }
    else {
        NSLog(@"Setting as default: %@",title.text);
        [button setTitle: @"Default" forState: UIControlStateNormal];
        self.isDefault = YES;
        [self.preferences setPreference:@"DEFAULT_JOIN" withValue:title.text];
        [self.preferences setPreference:@"DEFAULT_JOIN_INDEX" withIntValue:(int)indexPath.row];
    }
}

-(void)setAutoJoinStatus {
    NSString *tmp = [self.preferences getPreference:@"DEFAULT_JOIN"];
    if (tmp != nil && [tmp isEqualToString:title.text]) {
        self.isDefault = YES;
        [setAsAutoJoinDefaultButton setTitle: @"Default" forState: UIControlStateNormal];
    }
    else {
        [setAsAutoJoinDefaultButton setTitle: @"Auto" forState: UIControlStateNormal];
        self.isDefault = NO;
    }
}

@end

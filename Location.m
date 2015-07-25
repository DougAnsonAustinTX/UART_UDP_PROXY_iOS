//
//  Location.m
//  UART_UDP_PROXY
//
//  Created by Doug Anson on 7/25/15.
//  Copyright (c) 2015 Nordic Semiconductor. All rights reserved.
//

#import "Location.h"

@implementation Location
 
@synthesize location;
@synthesize enabled;

// Send Format - "latitude:longitude:altitude:speed"
    
-(id)init {
    self = [super init];
    [self checkEnabled];
    return self;
}

-(BOOL)checkEnabled {
    BOOL is_enabled = YES;
    
    if (is_enabled) {
        // location reporting is enabled...
        self.enabled = YES;
        self.location = @"0.0:0.0:0.0:0.0";
    }
    else {
        // location reporting is disabled...
        self.enabled = NO;
        self.location = @"0.0:0.0:-1.0:-1.0";
    }
    return self.enabled;
}
    
-(void)updateLocation {
    
    // can the response for now...
    self.location = @"-123.45678:-111.11111:99999.9:12345.0";
}
    
-(NSString *)getLocation {
    return self.location;
}

@end

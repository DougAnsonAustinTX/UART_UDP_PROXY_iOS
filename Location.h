//
//  Location.h
//
//  Created by Doug Anson on 7/25/15.
//  Copyright (c) 2015 Doug Anson. All rights reserved.
//

#ifndef UART_UDP_PROXY_Location_h
#define UART_UDP_PROXY_Location_h

@interface Location : NSObject {
    
}

@property (nonatomic,retain) NSString *location;
@property (nonatomic,assign) BOOL      enabled;

- (id)init;
- (BOOL)checkEnabled;
- (void)updateLocation;
- (NSString *)getLocation;

@end


#endif

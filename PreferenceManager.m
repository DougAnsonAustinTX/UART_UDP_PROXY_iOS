//
//  PreferenceManager.m
//
//  Created by Doug Anson.
//  Copyright 2010 AnsonWorks.com. All rights reserved.
//

#import "PreferenceManager.h"

@implementation PreferenceManager

@synthesize mAppName;
@synthesize mPrefMgr;

- (id) init:(NSString *)appName {
    self = [super init];
    
    // setup ourselves
    self.mAppName = [[NSString alloc] initWithString:appName];
    self.mPrefMgr = [NSUserDefaults standardUserDefaults];
    
    // return self
    return self;
}

- (void) setPreference:(NSString *)name withIntValue:(int)value {
    NSString *sval = [[NSString alloc] initWithFormat:@"%d",value];
    [self setPreference:name withValue:sval];
}

- (void) setPreference:(NSString *)name withBooleanValue:(BOOL)value {
    NSString *sval = @"NO";
    if (value) sval = @"YES";
    [self setPreference:name withValue:sval];
}

- (void) setPreference:(NSString *)name withValue:(NSString *)value {
    @try{
        if (name != nil && [name length] > 0 && value != nil && [value length] > 0) {
            // store the value
            [self.mPrefMgr setObject:value forKey:name];
            
            // make sure that the value is written out
            for (int i=0;i<2;++i)
                [self.mPrefMgr synchronize];
        }
        else if (name != nil && [name length] > 0) {
            // we just store a blank string
            [self.mPrefMgr setObject:@"" forKey:name];
            
            // make sure that the value is written out
            for (int i=0;i<2;++i)
                [self.mPrefMgr synchronize];
        }
        else  {
            // Invalid parameters - ignore
            ;
        }
        
    }
    @catch (NSException *ex) {
        NSLog(@"%@: PrefMgr Exception(SET) %@ Message: %@",self.mAppName,ex.name, ex.reason);
    }
}

- (int) getIntPreference:(NSString *)name {
    return [self getIntPreference:name withDefault:0];
}

- (int) getIntPreference:(NSString *)name withDefault:(int)def {
    int ival = 0;
    NSString *sdef = [[NSString alloc] initWithFormat:@"%d",def];
    NSString *sval = [self getPreference:name withDefault:sdef];
    if (sval != nil)
        ival = [sval intValue];
    return ival;
}

- (BOOL) getBooleanPreference:(NSString *)name {
    return [self getBooleanPreference:name withDefault:NO];
}

- (BOOL) getBooleanPreference:(NSString *)name withDefault:(BOOL)def {
    BOOL bval = NO;
    NSString *sdef = @"NO";
    
    if (def == YES) sdef = @"YES";
    
    NSString *sval = [self getPreference:name withDefault:sdef];
    
    @try {
        if (sval != nil) bval = [sval boolValue];
    }
    @catch (NSException *ex) {
        NSLog(@"%@: PrefMgr Exception(GET) %@ Message: %@",self.mAppName, ex.name, ex.reason);
    }
    return bval;
    
}

- (NSString *) getPreference:(NSString *)name {
    return [self getPreference:name withDefault:@""];
}

- (NSString *) getPreference:(NSString *)name withDefault:(NSString *)def {
    NSString *value = nil;
    @try {
        if (name != nil && [name length] > 4) {
            value = [self.mPrefMgr stringForKey:name];
            if (value != nil)
                value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (value == nil || [value length] == 0) {
                value = [def stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
    }
    @catch (NSException *ex) {
        NSLog(@"%@: PrefMgr Exception(GET) %@ Message: %@",self.mAppName,ex.name, ex.reason);
    }
    
    return value;
}

- (NSString *) getPreference:(NSString *)name withDefaultInt:(int)def {
    NSString *sdef = [[NSString alloc] initWithFormat:@"%d",def];
    NSString *result = [self getPreference:name withDefault:sdef];
    if (result == nil) result = sdef;
    return result;
}

@end

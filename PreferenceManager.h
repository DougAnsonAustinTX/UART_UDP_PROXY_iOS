//
//  PreferenceManager.h
//
//  Created by Doug Anson
//  Copyright 2010 AnsonWorks.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PreferenceManager : NSObject

@property (nonatomic,retain) NSString *mAppName;
@property (nonatomic,retain) NSUserDefaults *mPrefMgr;

- (id) init:(NSString *)appName;
- (void) setPreference:(NSString *)name withValue:(NSString *)value;
- (void) setPreference:(NSString *)name withIntValue:(int)value;
- (void) setPreference:(NSString *)name withBooleanValue:(BOOL)value;
- (NSString *) getPreference:(NSString *)name;
- (int) getIntPreference:(NSString *)name;
- (int) getIntPreference:(NSString *)name withDefault:(int)def;
- (BOOL) getBooleanPreference:(NSString *)name;
- (BOOL) getBooleanPreference:(NSString *)name withDefault:(BOOL) def;
- (NSString *) getPreference:(NSString *)name withDefault:(NSString *)def;
- (NSString *) getPreference:(NSString *)name withDefaultInt:(int)def;

@end

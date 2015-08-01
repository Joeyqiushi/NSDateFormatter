//
//  ViewController.m
//  NSDateFormatterEfficiency
//
//  Created by Joeyxu on 7/30/15.
//  Copyright (c) 2015 com.joeyxu. All rights reserved.
//

#import "ViewController.h"

#define ITERATIONS (1024*10)

static double then, now;

@interface ViewController ()
@property (nonatomic, strong) NSTimeZone *timeZone;
@property (nonatomic, strong) NSString *dateAsString;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation ViewController

- (NSTimeZone *)timeZone
{
    if (!_timeZone) {
        _timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8*60*60];
    }
    return _timeZone;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeZone:self.timeZone];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _dateFormatter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self convertDateToStringUsingNewDateFormatter];
    
    [self convertDateToStringUsingSingletonFormatter];
    
    [self convertDateToStringUsingCLocaltime];
}

- (void)convertDateToStringUsingNewDateFormatter
{
    then = CFAbsoluteTimeGetCurrent();
    for (NSUInteger i = 0; i < ITERATIONS; i++) {
        NSDateFormatter *newDateForMatter = [[NSDateFormatter alloc] init];
        [newDateForMatter setTimeZone:self.timeZone];
        [newDateForMatter setDateFormat:@"yyyy-MM-dd"];
        self.dateAsString = [newDateForMatter stringFromDate:[NSDate date]];
    }
    now = CFAbsoluteTimeGetCurrent();
    NSLog(@"Convert date to string using NSDateFormatter costs time: %f seconds!\n", now - then);
}

- (void)convertDateToStringUsingSingletonFormatter
{
    then = CFAbsoluteTimeGetCurrent();
    for (NSUInteger i = 0; i < ITERATIONS; i++) {
        self.dateAsString = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    now = CFAbsoluteTimeGetCurrent();
    NSLog(@"Convert date to string using Singleton Formatter costs time: %f seconds!\n", now - then);
}

- (void)convertDateToStringUsingCLocaltime
{
    then = CFAbsoluteTimeGetCurrent();
    for (NSUInteger i = 0; i < ITERATIONS; i++) {
        time_t timeInterval = [NSDate date].timeIntervalSince1970;
        struct tm *cTime = localtime(&timeInterval);
        self.dateAsString = [NSString stringWithFormat:@"%d-%02d-%02d", cTime->tm_year + 1900, cTime->tm_mon + 1, cTime->tm_mday];
    }
    now = CFAbsoluteTimeGetCurrent();
    NSLog(@"Convert date to string using C localtime costs time: %f seconds!\n", now - then);
}

@end

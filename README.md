# NSDateFormatter最佳实践

本文介绍NSDateFormatter的性能瓶颈，以及如何解决性能问题。

分别用NSDateFormatter和C的localtime()方法去将时间转化成一个可读的字符串。转化1024*10次，然后对比时间。
注：localtime()有不可重入和线程安全的问题，可用localtime_r替换。
```
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self convertDateToStringUsingNewDateFormatter];
    
    [self convertDateToStringUsingCLocaltime];
}
    
- (void)convertDateToStringUsingNewDateFormatter {
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
    
- (void)convertDateToStringUsingCLocaltime {
    then = CFAbsoluteTimeGetCurrent();
    for (NSUInteger i = 0; i < ITERATIONS; i++) {
        time_t timeInterval = [NSDate date].timeIntervalSince1970;
        struct tm *cTime = localtime(&timeInterval);
        self.dateAsString = [NSString stringWithFormat:@"%d-%02d-%02d", cTime->tm_year + 1900, cTime->tm_mon + 1, cTime->tm_mday];
    }
    now = CFAbsoluteTimeGetCurrent();
    NSLog(@"Convert date to string using C localtime costs time: %f seconds!\n", now - then);
}
```
在控制台可以看到输出结果：
```
Convert date to string using NSDateFormatter costs time: 4.289286 seconds!
Convert date to string using C localtime() costs time: 0.038355 seconds!
```

使用NSDateFormatter耗时4.289286秒，
使用localtime耗时0.038355秒。
也就是说，NSDateFormatter要比localtime慢**100倍+**！

用instruments跑了一下time profile，
![time profile](http://upload-images.jianshu.io/upload_images/595974-07a7bb28d30b8aa8.png?imageMogr2/auto-orient/strip|imageView2/2/w/1240)
可以看到这性能差距之大。

为啥NSDateFormatter这么耗时呢？

苹果官方文档中写到：
> “Creating a date formatter is not a cheap operation. If you are likely to use a formatter frequently, it is typically more efficient to cache a single instance than to create and dispose of multiple instances. One approach is to use a static
 variable.”

也就是说，创建NSDateFormatter的过程开销很大！建议使用时保持一个单例，而不是每次去重新创建
NSDateFormatter对象。

demo中加入一个单例NSDateFormatter的实现方法，
```
- (void)convertDateToStringUsingSingletonFormatter {
    then = CFAbsoluteTimeGetCurrent();
    for (NSUInteger i = 0; i < ITERATIONS; i++) {
        self.dateAsString = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    now = CFAbsoluteTimeGetCurrent();
    NSLog(@"Convert date to string using Singleton Formatter costs time: %f seconds!\n", now - then);
}
```
    
控制台输出，
```
Convert date to string using NSDateFormatter costs time: 4.231905 seconds!
Convert date to string using Singleton Formatter costs time: 0.031584 seconds!
Convert date to string using C localtime() costs time: 0.039877 seconds!
```

嗯，若使用单例，NSDateFormatter开销和localtime()的开销差不多，甚至会稍快一些。

综上，最佳实践应该是，在工程中添加一个NSDateFormatter的单例对象供全工程使用，需要注意的是，NSDateFormatter在iOS7之后(包括iOS7)才是线程安全的。

[NSDateFormatter文档](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html)

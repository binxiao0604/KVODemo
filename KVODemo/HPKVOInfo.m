//
//  HPKVOInfo.m
//  KVODemo
//
//  Created by ZP on 2021/8/2.
//

#import "HPKVOInfo.h"

@implementation HPKVOInfo

- (instancetype)initWitObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(HPKeyValueObservingOptions)options context:(nullable void *)context {
    self = [super init];
    if (self) {
        self.observer = observer;
        self.keyPath  = keyPath;
        self.options  = options;
        self.context = (__bridge id _Nonnull)(context);
    }
    return self;
}

@end

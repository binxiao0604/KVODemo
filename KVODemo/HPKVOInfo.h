//
//  HPKVOInfo.h
//  KVODemo
//
//  Created by ZP on 2021/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, HPKeyValueObservingOptions) {
    HPKeyValueObservingOptionNew = 0x01,
    HPKeyValueObservingOptionOld = 0x02,
};

@interface HPKVOInfo : NSObject

@property (nonatomic, weak) id observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, assign) HPKeyValueObservingOptions options;
@property (nonatomic, strong) id context;

- (instancetype)initWitObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(HPKeyValueObservingOptions)options context:(nullable void *)context;

@end

NS_ASSUME_NONNULL_END

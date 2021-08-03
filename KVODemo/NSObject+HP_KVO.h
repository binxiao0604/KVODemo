//
//  NSObject+HP_KVO.h
//  KVODemo
//
//  Created by ZP on 2021/8/2.
//

#import <Foundation/Foundation.h>
#import "HPKVOInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (HP_KVO)

- (void)hp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(HPKeyValueObservingOptions)options context:(nullable void *)context;
- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context;
- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

- (void)hp_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;

//block实现


@end

NS_ASSUME_NONNULL_END

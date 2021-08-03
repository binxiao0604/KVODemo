//
//  NSObject+HP_KVO_Block.h
//  KVODemo
//
//  Created by ZP on 2021/8/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^HPKVOBlock)(id observer,NSString *keyPath,id oldValue,id newValue);

@interface NSObject (HP_KVO_Block)

- (void)hp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(HPKVOBlock)block;

- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END

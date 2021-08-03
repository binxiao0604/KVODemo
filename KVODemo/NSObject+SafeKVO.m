//
//  NSObject+SafeKVO.m
//  KVODemo
//
//  Created by ZP on 2021/8/3.
//

#import "NSObject+SafeKVO.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

static NSString *const kHPSafeKVOObserverdAssiociateKey = @"HPSafeKVOObserverdAssiociateKey";

@interface HPSafeKVOObservedInfo : NSObject

@property (nonatomic, weak) id observerd;
@property (nonatomic, copy) NSString  *keyPath;
@property (nonatomic, strong) id context;

@end

@implementation HPSafeKVOObservedInfo

- (instancetype)initWitObserverd:(NSObject *)observerd forKeyPath:(NSString *)keyPath context:(nullable void *)context {
    if (self=[super init]) {
        _observerd = observerd;
        _keyPath = keyPath;
        _context = (__bridge id)(context);
    }
    return self;
}

@end


@implementation NSObject (SafeKVO)

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
////        id cls = [UIScreen class];//为了处理UIScreen 监听 crash 问题
//        [self hp_methodSwizzleWithClass:self oriSEL:@selector(addObserver:forKeyPath:options:context:) swizzledSEL:@selector(hp_addObserver:forKeyPath:options:context:) isClassMethod:NO];
//        [self hp_methodSwizzleWithClass:self oriSEL:@selector(removeObserver:forKeyPath:context:) swizzledSEL:@selector(hp_removeObserver:forKeyPath:context:)isClassMethod:NO];
//        [self hp_methodSwizzleWithClass:self oriSEL:@selector(removeObserver:forKeyPath:) swizzledSEL:@selector(hp_removeObserver:forKeyPath:)isClassMethod:NO];
//    });
//}

- (void)hp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context {
    if ([self keyPathIsExist:keyPath observer:observer]) {//observer 观察者已经添加了对应key的观察，再次添加不做处理。
        return;
    }
    /*//容错处理  `UIScreen` 观察了 `CADisplay` 的 `cloned`，非必现。
     方式一：+load 中调用 UIScreen的方法
     方式二：进行过滤处理
        2.1只有自己的类才走hook逻辑。
        2.2排除某些系统类。
        2.3只排除UIScreen
    */
    
    NSString *observerClassName = NSStringFromClass([observer class]);
    if (![observerClassName hasPrefix:@"HP"]) { //排除某些系统类。
        [self hp_addObserver:observer forKeyPath:keyPath options:options context:context];
        return;
    }

//    NSString *className = NSStringFromClass([observer class]);
//    if ([className hasPrefix:@"NS"] || [className hasPrefix:@"UI"]) { //排除某些系统类。
//        [self hp_addObserver:observer forKeyPath:keyPath options:options context:context];
//        return;
//    }
    
    
//    if ([observer isKindOfClass:[UIScreen class]]) { //只排除UIScreen
//        [self hp_addObserver:observer forKeyPath:keyPath options:options context:context];
//        return;
//    }
    
    NSString *className = NSStringFromClass([self class]);
    NSString *newClassName = [NSString stringWithFormat:@"NSKVONotifying_%@",className];
    Class newClass = NSClassFromString(newClassName);
    if (!newClass) {//类不存在的时候进行 hook 观察者 dealloc
        //hook dealloc
        [[observer class] hp_methodSwizzleWithClass:[observer class] oriSEL:NSSelectorFromString(@"dealloc") swizzledSEL:@selector(hp_dealloc) isClassMethod:NO];
    }
    //保存被观察者信息
    HPSafeKVOObservedInfo *kvoObservedInfo = [[HPSafeKVOObservedInfo alloc] initWitObserverd:self forKeyPath:keyPath context:context];
    NSMutableArray *observerdArray = objc_getAssociatedObject(observer, (__bridge const void * _Nonnull)(kHPSafeKVOObserverdAssiociateKey));
    if (!observerdArray) {
        observerdArray = [NSMutableArray arrayWithCapacity:1];
    }
    [observerdArray addObject:kvoObservedInfo];
    objc_setAssociatedObject(observer, (__bridge const void * _Nonnull)(kHPSafeKVOObserverdAssiociateKey), observerdArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //调用原始方法
    [self hp_addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context {
    if ([self keyPathIsExist:keyPath observer:observer]) {//key存在才移除
        [self hp_removeObserver:observer forKeyPath:keyPath context:context];
    }
}

- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    if ([self keyPathIsExist:keyPath observer:observer]) {//key存在才移除
        [self hp_removeObserver:observer forKeyPath:keyPath];
    }
}
 
- (BOOL)keyPathIsExist:(NSString *)sarchKeyPath observer:(id)observer {
    BOOL findKey = NO;
    id info = self.observationInfo;
    if (info) {
        NSArray *observances = [info valueForKeyPath:@"_observances"];
        for (id observance in observances) {
            id tempObserver = [observance valueForKey:@"_observer"];
            if (tempObserver == observer) {
                NSString *keyPath = [observance valueForKeyPath:@"_property._keyPath"];
                if ([keyPath isEqualToString:sarchKeyPath]) {
                    findKey = YES;
                    break;
                }
            }
        }
    }
    return findKey;
}

- (void)hp_dealloc {
    [self hp_removeSelfAllObserverd];
    [self hp_dealloc];
}

- (void)hp_removeSelfAllObserverd {
    NSMutableArray *observerdArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPSafeKVOObserverdAssiociateKey));
    for (HPSafeKVOObservedInfo *info in observerdArray) {
        if (info.observerd) {
            //调用系统方法，已经hook了，走hook逻辑。
            if (info.context) {
                [info.observerd removeObserver:self forKeyPath:info.keyPath context:(__bridge void * _Nullable)(info.context)];
            } else {
                [info.observerd removeObserver:self forKeyPath:info.keyPath];
            }
        }
    }
}


+ (void)hp_methodSwizzleWithClass:(Class)cls oriSEL:(SEL)oriSEL swizzledSEL:(SEL)swizzledSEL isClassMethod:(BOOL)isClassMethod {
    if (!cls) {
        NSLog(@"class is nil");
        return;
    }
    if (!swizzledSEL) {
        NSLog(@"swizzledSEL is nil");
        return;
    }
    //类/元类
    Class swizzleClass = isClassMethod ? object_getClass(cls) : cls;
    Method oriMethod = class_getInstanceMethod(swizzleClass, oriSEL);
    Method swiMethod = class_getInstanceMethod(swizzleClass, swizzledSEL);
    if (!oriMethod) {//原始方法没有实现
        // 在oriMethod为nil时，替换后将swizzledSEL复制一个空实现
        class_addMethod(swizzleClass, oriSEL, method_getImplementation(swiMethod), method_getTypeEncoding(swiMethod));
        //添加一个空的实现
        method_setImplementation(swiMethod, imp_implementationWithBlock(^(id self, SEL _cmd){
           NSLog(@"imp default null implementation");
        }));
    }
    //自己没有则会添加成功，自己有添加失败
    BOOL success = class_addMethod(swizzleClass, oriSEL, method_getImplementation(swiMethod), method_getTypeEncoding(oriMethod));
    if (success) {//自己没有方法添加一个，添加成功则证明自己没有。
       class_replaceMethod(swizzleClass, swizzledSEL, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else { //自己有直接进行交换
       method_exchangeImplementations(oriMethod, swiMethod);
    }
}

@end


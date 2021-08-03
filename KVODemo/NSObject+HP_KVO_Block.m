//
//  NSObject+HP_KVO_Block.m
//  KVODemo
//
//  Created by ZP on 2021/8/3.
//

#import "NSObject+HP_KVO_Block.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "HPKVOInfo.h"

static NSString *const kHPBlockKVOClassPrefix = @"HPKVONotifying_";
static NSString *const kHPBlockKVOAssiociateKey = @"HPKVOAssiociateKey";

static NSString *const kHPBlockKVOObserverdAssiociateKey = @"HPKVOObserverdAssiociateKey";

@interface HPKVOBlockInfo : NSObject

@property (nonatomic, weak) id observer;
@property (nonatomic, copy) NSString  *keyPath;
@property (nonatomic, copy) HPKVOBlock  handleBlock;

@end

@implementation HPKVOBlockInfo

- (instancetype)initWitObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath handleBlock:(HPKVOBlock)block {
    if (self=[super init]) {
        _observer = observer;
        _keyPath  = keyPath;
        _handleBlock = block;
    }
    return self;
}

@end

@interface HPKVOObservedInfo : NSObject

@property (nonatomic, weak) id observerd;
@property (nonatomic, copy) NSString  *keyPath;

@end

@implementation HPKVOObservedInfo

- (instancetype)initWitObserverd:(NSObject *)observerd forKeyPath:(NSString *)keyPath {
    if (self=[super init]) {
        _observerd = observerd;
        _keyPath  = keyPath;
    }
    return self;
}

@end

@implementation NSObject (HP_KVO_Block)


- (void)hp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(HPKVOBlock)block {
    //1.参数判断 以及 setter检查
    if (!observer || !keyPath) return;
    BOOL result = [self _handleSetterMethodFromKeyPath:keyPath];
    if (!result) return;
    
    //2.isa_swizzle 申请类-注册类-添加方法
    Class newClass = [self _creatKVOClassWithKeyPath:keyPath observer:observer];
    
    //3.isa 指向子类
    object_setClass(self, newClass);
    //4.setter逻辑处理
    //保存观察者信息-数组
    HPKVOBlockInfo *kvoInfo = [[HPKVOBlockInfo alloc] initWitObserver:observer forKeyPath:keyPath handleBlock:block];
    NSMutableArray *observerArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPBlockKVOAssiociateKey));
    if (!observerArray) {
        observerArray = [NSMutableArray arrayWithCapacity:1];
    }
    [observerArray addObject:kvoInfo];
    objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kHPBlockKVOAssiociateKey), observerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //保存被观察者信息
    HPKVOObservedInfo *kvoObservedInfo = [[HPKVOObservedInfo alloc] initWitObserverd:self forKeyPath:keyPath];
    NSMutableArray *observerdArray = objc_getAssociatedObject(observer, (__bridge const void * _Nonnull)(kHPBlockKVOObserverdAssiociateKey));
    if (!observerdArray) {
        observerdArray = [NSMutableArray arrayWithCapacity:1];
    }
    [observerdArray addObject:kvoObservedInfo];
    objc_setAssociatedObject(observer, (__bridge const void * _Nonnull)(kHPBlockKVOObserverdAssiociateKey), observerdArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    NSMutableArray *observerArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPBlockKVOAssiociateKey));
    if (observerArray.count <= 0) {
        return;
    }
    
    NSMutableArray *tempArray = [observerArray mutableCopy];
    for (HPKVOInfo *info in tempArray) {
        if ([info.keyPath isEqualToString:keyPath]) {
            if (info.observer) {
                if (info.observer == observer) {
                    [observerArray removeObject:info];
                }
            } else {
                [observerArray removeObject:info];
            }
        }
    }
    objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kHPBlockKVOAssiociateKey), observerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    //已经全部移除了
    if (observerArray.count <= 0) {
        //isa指回给父类
        Class superClass = [self class];
        object_setClass(self, superClass);
    }
}

- (BOOL)_handleSetterMethodFromKeyPath:(NSString *)keyPath {
    SEL setterSeletor = NSSelectorFromString(_setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod(object_getClass(self), setterSeletor);
    NSAssert(setterMethod, @"%@ setter is not exist",keyPath);
    return setterMethod ? YES : NO;
}

// 从get方法获取set方法的名称 key -> setKey
static NSString *_setterForGetter(NSString *getter) {
    if (getter.length <= 0) { return nil;}
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *otherString = [getter substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:",firstString,otherString];
}

//申请类-注册类-添加方法
- (Class)_creatKVOClassWithKeyPath:(NSString *)keyPath observer:(NSObject *)observer {
    //这里重写class后kvo子类也返回的是父类的名字
    NSString *superClassName = NSStringFromClass([self class]);
    NSString *newClassName = [NSString stringWithFormat:@"%@%@",kHPBlockKVOClassPrefix,superClassName];
    Class newClass = NSClassFromString(newClassName);
    //类是否存在
    if (!newClass)  {//不存在需要创建类
        //1：申请类 父类、新类名称、额外空间
        newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
        //2：注册类
        objc_registerClassPair(newClass);
        //3：添加class方法，class返回父类信息 这里是`-class`
        SEL classSEL = NSSelectorFromString(@"class");
        Method classMethod = class_getInstanceMethod([self class], classSEL);
        const char *classTypes = method_getTypeEncoding(classMethod);
        class_addMethod(newClass, classSEL, (IMP)_hp_class, classTypes);
        
        //hook dealloc
        [[observer class] hp_methodSwizzleWithClass:[observer class] oriSEL:NSSelectorFromString(@"dealloc") swizzledSEL:@selector(hp_dealloc) isClassMethod:NO];
    }
    //4：添加setter方法
    SEL setterSEL = NSSelectorFromString(_setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod([self class], setterSEL);
    const char *setterTypes = method_getTypeEncoding(setterMethod);
    class_addMethod(newClass, setterSEL, (IMP)_hp_setter, setterTypes);
    
    return newClass;
}

//返回父类信息
Class _hp_class(id self,SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

static void _hp_setter(id self,SEL _cmd,id newValue) {
    //自动开关判断，省略
    //保存旧值
    NSString *keyPath = _getterForSetter(NSStringFromSelector(_cmd));
    id oldValue = [self valueForKey:keyPath];
    //1.调用父类的setter(也可以通过performSelector调用)
    void (*hp_msgSendSuper)(void *,SEL , id) = (void *)objc_msgSendSuper;
    struct objc_super super_struct = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };
    hp_msgSendSuper(&super_struct,_cmd,newValue);
    
    //2.通知观察者
    NSMutableArray *observerArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPBlockKVOAssiociateKey));
    for (HPKVOBlockInfo *info in observerArray) {//循环调用,可能添加多次。
        if ([info.keyPath isEqualToString:keyPath] && info.handleBlock && info.observer) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                info.handleBlock(info.observer, keyPath, oldValue, newValue);
            });
        }
    }
}

//获取getter
static NSString *_getterForSetter(NSString *setter){
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;}
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    return  [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
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

- (void)hp_dealloc {
    NSMutableArray *observerdArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPBlockKVOObserverdAssiociateKey));
    for (HPKVOObservedInfo *info in observerdArray) {
        if (info.observerd) {
            [info.observerd hp_removeObserver:self forKeyPath:info.keyPath];
        }
    }
    [self hp_dealloc];
}

@end

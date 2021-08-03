//
//  NSObject+HP_KVO.m
//  KVODemo
//
//  Created by ZP on 2021/8/2.
//

#import "NSObject+HP_KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kHPKVOClassPrefix = @"HPKVONotifying_";
static NSString *const kHPKVOAssiociateKey = @"HPKVOAssiociateKey";

@implementation NSObject (HP_KVO)

- (void)hp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(HPKeyValueObservingOptions)options context:(nullable void *)context {
    //1.参数判断 以及 setter检查
    if (!observer || !keyPath) return;
    BOOL result = [self handleSetterMethodFromKeyPath:keyPath];
    if (!result) return;
    
    //2.isa_swizzle 申请类-注册类-添加方法
    Class newClass = [self creatKVOClassWithKeyPath:keyPath];
    
    //3.isa 指向子类
    object_setClass(self, newClass);
    //4.setter逻辑处理
    //保存观察者信息-数组
    HPKVOInfo *kvoInfo = [[HPKVOInfo alloc] initWitObserver:observer forKeyPath:keyPath options:options context:context];
    NSMutableArray *observerArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPKVOAssiociateKey));
    if (!observerArray) {
        observerArray = [NSMutableArray arrayWithCapacity:1];
    }
    [observerArray addObject:kvoInfo];
    objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kHPKVOAssiociateKey), observerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    [self hp_removeObserver:observer forKeyPath:keyPath context:NULL];
}

- (void)hp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    NSMutableArray *observerArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPKVOAssiociateKey));
    if (observerArray.count <= 0) {
        return;
    }
    
    NSMutableArray *tempArray = [observerArray mutableCopy];
    for (HPKVOInfo *info in tempArray) {
        if ([info.keyPath isEqualToString:keyPath]) {
            if (info.observer) {
                if (info.observer == observer) {
                    if (context != NULL) {
                        if (info.context == context) {
                            [observerArray removeObject:info];
                        }
                    } else {
                        [observerArray removeObject:info];
                    }
                }
            } else {
                if (context != NULL) {
                    if (info.context == context) {
                        [observerArray removeObject:info];
                    }
                } else {
                    [observerArray removeObject:info];
                }
            }
        }
    }
    objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kHPKVOAssiociateKey), observerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    //已经全部移除了
    if (observerArray.count <= 0) {
        //isa指回给父类
        Class superClass = [self class];
        object_setClass(self, superClass);
    }
}

- (BOOL)handleSetterMethodFromKeyPath:(NSString *)keyPath {
    SEL setterSeletor = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod(object_getClass(self), setterSeletor);
    NSAssert(setterMethod, @"%@ setter is not exist",keyPath);
    return setterMethod ? YES : NO;
}

// 从get方法获取set方法的名称 key -> setKey
static NSString *setterForGetter(NSString *getter) {
    if (getter.length <= 0) { return nil;}
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *otherString = [getter substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:",firstString,otherString];
}

//申请类-注册类-添加方法
- (Class)creatKVOClassWithKeyPath:(NSString *)keyPath {
    //这里重写class后kvo子类也返回的是父类的名字
    NSString *superClassName = NSStringFromClass([self class]);
    NSString *newClassName = [NSString stringWithFormat:@"%@%@",kHPKVOClassPrefix,superClassName];
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
        class_addMethod(newClass, classSEL, (IMP)hp_class, classTypes);
    }
    //4：添加setter方法
    SEL setterSEL = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod([self class], setterSEL);
    const char *setterTypes = method_getTypeEncoding(setterMethod);
    class_addMethod(newClass, setterSEL, (IMP)hp_setter, setterTypes);
    
    return newClass;
}

//返回父类信息
Class hp_class(id self,SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

static void hp_setter(id self,SEL _cmd,id newValue) {
    //自动开关判断，省略
    //保存旧值
    NSString *keyPath = getterForSetter(NSStringFromSelector(_cmd));
    id oldValue = [self valueForKey:keyPath];
    //1.调用父类的setter(也可以通过performSelector调用)
    void (*hp_msgSendSuper)(void *,SEL , id) = (void *)objc_msgSendSuper;
    struct objc_super super_struct = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };
    hp_msgSendSuper(&super_struct,_cmd,newValue);
    
    //2.通知观察者
    NSMutableArray *observerArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kHPKVOAssiociateKey));
    for (HPKVOInfo *info in observerArray) {//循环调用,可能添加多次。
        if ([info.keyPath isEqualToString:keyPath]) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSMutableDictionary<NSKeyValueChangeKey,id> *change = [NSMutableDictionary dictionaryWithCapacity:1];
                //对新旧值进行处理
                if (info.options & HPKeyValueObservingOptionNew) {
                    [change setObject:newValue forKey:NSKeyValueChangeNewKey];
                }
                if (info.options & HPKeyValueObservingOptionOld) {
                    if (oldValue) {
                        [change setObject:oldValue forKey:NSKeyValueChangeOldKey];
                    } else {
                        [change setObject:@"" forKey:NSKeyValueChangeOldKey];
                    }
                }
                [change setObject:@1 forKey:@"kind"];
                //消息发送给观察者
                [info.observer hp_observeValueForKeyPath:keyPath ofObject:self change:change context:(__bridge void * _Nullable)(info.context)];
            });
        }
    }
}

//获取getter
static NSString *getterForSetter(NSString *setter){
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;}
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    return  [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}

@end

//
//  HPDetailViewController.m
//  KVODemo
//
//  Created by ZP on 2021/7/30.
//

#import "HPDetailViewController.h"
#import <objc/runtime.h>
#import "NSObject+HP_KVO.h"
#import "NSObject+HP_KVO_Block.h"

#import <KVOController/KVOController.h>

@interface HPDetailViewController ()

@property (nonatomic, strong) HPObject *obj;

@property (nonatomic, strong) NSMutableArray <HPObject *>*array;

@end

@implementation HPDetailViewController

+ (instancetype)getInstance:(HPObject *)obj {
//    static dispatch_once_t onceToken;
    HPDetailViewController *instance;
//    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.obj = obj;
//    });
    return  instance;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.KVOController = [FBKVOController controllerWithObserver:self];
    [self.KVOController observe:self.obj keyPath:@"name" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        NSLog(@"change:%@",change);
    }];
    
    [self.KVOController observe:self.obj keyPath:@"name" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        NSLog(@"change:%@",change);
    }];

    [self.KVOController observe:self.obj keyPath:@"nickName" options:NSKeyValueObservingOptionNew action:@selector(hp_NickNameChange:object:)];
    
//    self.obj = [HPObject alloc];
//    [self.obj hp_addObserver:self forKeyPath:@"name" block:^(id  _Nonnull observer, NSString * _Nonnull keyPath, id  _Nonnull oldValue, id  _Nonnull newValue) {
//        NSLog(@"block: oldValue:%@,newValue:%@",oldValue,newValue);
//    }];
//    [self.obj addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
//    [self.obj addObserver:self forKeyPath:@"nickName" options:NSKeyValueObservingOptionNew context:NULL];
//    [self.obj addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];
//    NSLog(@"observed after %@",self.obj.observationInfo);
//    id info = self.obj.observationInfo;
//    NSLog(@"observed after %@",info);
}

- (void)hp_NickNameChange:(NSDictionary *)change object:(id)object {
    NSLog(@"change:%@ object:%@",change,object);
}


//- (void)hp_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    NSLog(@"change:%@",change);
//}
//
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    NSLog(@"change:%@",change);
//}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.obj.name = @"HP111";
    self.obj.nickName = @"cat111";
}

- (void)dealloc {
//    [self.obj hp_removeObserver:self forKeyPath:@"nickName"];
//    [self.obj hp_removeObserver:self forKeyPath:@"name"];
//    [self.obj removeObserver:self forKeyPath:@"name"];
//    [self.obj removeObserver:self forKeyPath:@"name"];
//    [self.obj removeObserver:self forKeyPath:@"name" context:NULL];
//    [self.obj removeObserver:self forKeyPath:@"name" context:NULL];
}

//- (void)_invalidate {
//    NSLog(@"12121");
//}

//- (void)printClassAllMethod:(Class)cls {
//    unsigned int count = 0;
//    Method *methodList = class_copyMethodList(cls, &count);
//    for (int i = 0; i < count; i++) {
//        Method method = methodList[i];
//        SEL sel = method_getName(method);
//        IMP imp = class_getMethodImplementation(cls, sel);
//        NSLog(@"%@-%p",NSStringFromSelector(sel),imp);
//    }
//    free(methodList);
//}
//
//- (void)printClassAllProtocol:(Class)cls {
//    unsigned int count = 0;
//    Protocol * __unsafe_unretained _Nonnull * _Nullable protocolList = class_copyProtocolList(cls, &count);
//    for (int i = 0; i < count; i++) {
//        Protocol *proto = protocolList[i];
//        NSLog(@"%s",protocol_getName(proto));
//    }
//    free(protocolList);
//}
//
//- (void)printClassAllProprerty:(Class)cls {
//    unsigned int count = 0;
//    objc_property_t *propertyList = class_copyPropertyList(cls, &count);
//    for (int i = 0; i < count; i++) {
//        objc_property_t property = propertyList[i];
//        NSLog(@"%s", property_getName(property));
//    }
//    free(propertyList);
//}
//
//- (void)printClassAllIvars:(Class)cls {
//    unsigned int count = 0;
//    Ivar *ivarList = class_copyIvarList(cls, &count);
//    for (int i = 0; i < count; i++) {
//        Ivar ivar = ivarList[i];
//        NSLog(@"%s-%s",ivar_getName(ivar),ivar_getTypeEncoding(ivar));
//    }
//    free(ivarList);
//}
//
//
//- (void)printClasses:(Class)cls {
//    //注册类总个数
//    int count = objc_getClassList(NULL, 0);
//    //先将类本身放入数组中
//    NSMutableArray *array = [NSMutableArray arrayWithObject:cls];
//    //开辟空间
//    Class *classes = (Class *)malloc(sizeof(Class)*count);
//    //获取已经注册的类
//    objc_getClassList(classes, count);
//    for (int i = 0; i < count; i++) {
//        //获取cls的子类，一层。
//        if (cls == class_getSuperclass(classes[i])) {
//            [array addObject:classes[i]];
//        }
//    }
//    free(classes);
//    NSLog(@"classes = %@",array);
//}


@end

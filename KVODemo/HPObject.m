//
//  HPObject.m
//  KVODemo
//
//  Created by ZP on 2021/7/30.
//

#import "HPObject.h"

@implementation HPObject

- (void)setName:(NSString *)name {
    _name = name;
    NSLog(@"%s,name:%@",__func__,name);
}

//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
//    NSLog(@"%s key:%@",__func__,key);
//    return NO;
//}

//- (void)setName:(NSString *)name {
//    [self willChangeValueForKey:@"name_test"];
//    _name = name;
//    [self didChangeValueForKey:@"name_test"];
//}

//+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
//    NSLog(@"%s key:%@",__func__,key);
//    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
//    if ([key isEqualToString:@"downloadProgress"]) {
//        NSArray *affectingKeys = @[@"totalData", @"writtenData"];
//        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
//    }
//    return keyPaths;
//}
//
//- (NSString *)downloadProgress {
//    if (self.writtenData == 0) {
//        self.writtenData = 10;
//    }
//    if (self.totalData == 0) {
//        self.totalData = 100;
//    }
//    return [[NSString alloc] initWithFormat:@"%f",1.0f*self.writtenData/self.totalData];
//}

@end

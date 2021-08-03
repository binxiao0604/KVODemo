//
//  HPObject.h
//  KVODemo
//
//  Created by ZP on 2021/7/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HPCat;

@interface HPObject : NSObject {
    @public
    int age;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *downloadProgress;
@property (nonatomic, assign) double writtenData;
@property (nonatomic, assign) double totalData;
@property (nonatomic, strong) NSMutableArray *dateArray;
@property (nonatomic, strong) HPCat *cat;

@end

NS_ASSUME_NONNULL_END

//
//  HPDetailViewController.h
//  KVODemo
//
//  Created by ZP on 2021/7/30.
//

#import <UIKit/UIKit.h>
#import "HPObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HPDetailViewController : UIViewController

+ (instancetype)getInstance:(HPObject *)obj;

@end

NS_ASSUME_NONNULL_END

//
//  ViewController.m
//  KVODemo
//
//  Created by ZP on 2021/7/30.
//

#import "ViewController.h"
#import "HPDetailViewController.h"
#import "HPObject.h"

@interface ViewController ()

@property (nonatomic, strong) HPObject *obj;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.obj = [HPObject alloc];
//    self.obj.name = @"hp1";
    //NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionPrior
//    [self.obj addObserver:self forKeyPath:@"name" options: NSKeyValueObservingOptionOld context:NULL];
//    self.obj.name = @"hp2";
//    self.obj.name = @"hp3";
}


//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    NSLog(@"change:%@",change);
//}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.obj.name = [NSString stringWithFormat:@"%@_",self.obj.name];
}

- (IBAction)didClickPushButtonAction:(id)sender {
    HPDetailViewController *detailVC = [HPDetailViewController getInstance:self.obj];
    [self.navigationController pushViewController:detailVC animated:YES];
}

@end

//
//  IMHomeVc.m
//  NSURLSessionDemo
//
//  Created by Wu on 17/5/9.
//  Copyright © 2017年 Wu. All rights reserved.
//

#import "IMHomeVc.h"
#import "IMUrlRequestHandle.h"

@interface IMHomeVc ()

@end

@implementation IMHomeVc

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [[IMUrlRequestHandle shareHandle] test];
    
//    [self im_test_dispatch_set_target_queue];
    
    size_t const objectCount = 1000;
    uint64_t n = dispatch_benchmark(100000, ^{
        @autoreleasepool {
            id obj = @42;
            NSMutableArray *array = [NSMutableArray array];
            for (size_t i = 0; i < objectCount; ++i) {
                [array addObject:obj];
            }
        }
        
        
    });
    NSLog(@"-[NSMutableArray addObject:] : %llu ns", n);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}


// dispacth_queue_t 管理 task 执行
// 记住，当一个队列里面的 task 为空了之后，后面的队列就会开始分派 task
- (void) im_test_dispatch_set_target_queue {
    
    dispatch_queue_t aQueue = dispatch_queue_create("a", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t bQueue = dispatch_queue_create("b", DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(aQueue , bQueue); // 将 aQueue 依附在 bQueue 上
    
    dispatch_async(aQueue, ^{
        for (int i = 0; i < 5; i ++) {
            NSLog(@"a queue");
        }
    });
    dispatch_suspend(aQueue);
    
    
    dispatch_async(bQueue, ^{
        for (int i = 0; i < 5; i ++) {
            NSLog(@"b queue");
        }
        dispatch_resume(aQueue);
    });
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

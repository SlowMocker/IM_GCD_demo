//
//  IMUrlRequestHandle.m
//  NSURLSessionDemo
//
//  Created by Wu on 17/5/9.
//  Copyright © 2017年 Wu. All rights reserved.
//

#import "IMUrlRequestHandle.h"
#import <UIKit/UIKit.h>


@interface IMUrlRequestHandle()

@end


@implementation IMUrlRequestHandle
{
    dispatch_group_t _im_group;
}

- (id) init {
    self = [super init];
    if (self) {
        _im_group = dispatch_group_create();
    }
    return self;
}

+ (id) shareHandle {
    static IMUrlRequestHandle *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[IMUrlRequestHandle alloc]init];
    });
    return obj;
}

- (void) test {
//    [self im_dispatch_group_sync];
    
    [self im_dispatch_group_async];
}

/*
 混淆点:
 
 队列用来管理块，也就是管理任务，先进先出。块执行是由线程来做的。
 dispatch_async 并不会执行队列中的块，只是将块放入队列中。
 
 事实上只有全局队列（dispatch_get_global_queue() 获取）才会被调度运行。这些队列是并行的，有优先级。
 
	DISPATCH_QUEUE_PRIORITY_HIGH
	DISPATCH_QUEUE_PRIORITY_DEFAULT
	DISPATCH_QUEUE_PRIORITY_LOW
	DISPATCH_QUEUE_PRIORITY_BACKGROUND
	
 GCD 会根据可用线程尽可能从高优先级的队列中调度块，等优先级高的队列空了就会调度优先级相对低的队列。
 
 开发者自己创建的队列（dispatch_queue_create()）实际是依附在全局队列上的（默认是 DEFAULT 优先级），这时候被依附的全局队列就叫做目标队列。GCD 提供了一个函数 dispatch_set_target_queue(aQueue , bQueue) 来将 aQueue 依附到 bQueue 上去。
 
 依附: 就是把队列排到目标队列后面去，当目标队列中的 block 全部调度给对应的 thread 去执行之后，依附队列中的块才开始被调度。
 
 
 dispatch_async 将块放入队列后，会开启新线程来执行该队列中的块。同理 dispatch_group_async 也一样。
 
 dispatch_group_async(group, queue, ^{
    NSLog(@"GROUP1");
 });
 
 等效
 
 dispatch_async(queue, ^{
    dispatch_group_enter(group);
    NSLog(@"GROUP1");
    dispatch_group_leave(group);
 });
 
 队列A <- 队列B <- 队列C 。比如: 队列A 是 DISPATCH_QUEUE_PRIORITY_DEFAULT 的全局队列，队列B 是开发者创建的依附在 队列A 上的队列 队列C 依附队列B。
 当队列A B C 执行线程都不一样的时候，队列A 开始执行，队列B 开始，马上队列C 也开始。这个还需要好好理解一下
 
 // 开启 4 条线程
 dispatch_async(queue_CONCURRENT , ^{1});并发队列 会开启新线程
 dispatch_async(queue_CONCURRENT , ^{2});并发队列 会开启新线程
 dispatch_async(queue_CONCURRENT , ^{3});并发队列 会开启新线程
 dispatch_async(queue_CONCURRENT , ^{4});并发队列 会开启新线程、
 
 // 开启 1 条线程
 dispatch_async(queue_SERIAL , ^{1});串行队列
 dispatch_async(queue_SERIAL , ^{2});
 dispatch_async(queue_SERIAL , ^{3});
 dispatch_async(queue_SERIAL , ^{4});
 
 dispatch_sync(...); 不会开启新线程
 
 */



// 普通的 dispatch_group_t 使用 块是同步的
- (void) im_dispatch_group_sync {
    
    dispatch_group_t group = dispatch_group_create();
    // 串行队列， 只会创建一个线程，不符合并行执行要求，并且会阻塞线程: group_async 会并发执行，结果所有的 block 争夺同一条线程
//    dispatch_queue_t queue = dispatch_queue_create("iMock", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue = dispatch_queue_create("iMock", DISPATCH_QUEUE_CONCURRENT); // 并行队列
    
    NSLog(@"主线程: %@",[NSThread currentThread]);
    dispatch_group_async(group, queue, ^{
        NSLog(@"GROUP1 当前线程: %@",[NSThread currentThread]);
        for (int i = 0; i < 5; i ++) {
            NSLog(@"GROUP1");
        }
    });

    dispatch_group_async(group, queue, ^{
        NSLog(@"GROUP2 当前线程: %@",[NSThread currentThread]);
        for (int i = 0; i < 5; i ++) {
            NSLog(@"GROUP2");
        }
    });
    
    dispatch_group_async(group, queue, ^{
        NSLog(@"GROUP3 当前线程: %@",[NSThread currentThread]);
        for (int i = 0; i < 5; i ++) {
            NSLog(@"GROUP3");
        }
    });
    
    dispatch_group_wait(group, 4 * NSEC_PER_SEC); // 设置超时 4s
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"group 执行完毕");
    });
    
}

// 使用 dispatch_group_t  和 dispatch_group_enter 和 dispatch_group_leave 来并发请求数据后，全部结束后再做处理

// 另外的处理方式:
// 1. 申明一个变量 _count 来监听所有的一步接口是否执行完毕，_count 初始值为需要请求的接口数，每结束一个请求，_count 减一，再使用 kvo 监听 _count 如果 _count == 0 那么代表所有请求结束，这时就可以做下一步操作了
// 2. 使用 NSOperationQueue 来做
- (void) im_dispatch_group_async {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("iMock", DISPATCH_QUEUE_CONCURRENT); // 并行队列
    
    NSLog(@"主线程: %@",[NSThread currentThread]);
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group); // 因为 dispatch_group_async 的块是异步实现（任务秒完，实际没完），所以这里手动给 group 添加一个任务
        NSLog(@"GROUP1 当前线程: %@",[NSThread currentThread]);
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        dispatch_after(when, queue, ^{
            NSLog(@"GROUP1 after 当前线程: %@",[NSThread currentThread]);
            for (int i = 0; i < 10; i ++) {
                NSLog(@"GROUP1");
            }
            dispatch_group_leave(group); // 真正完成后手动移除 group 的一个任务标记
        });
    });
    
    dispatch_group_async(group, queue, ^{
        dispatch_group_enter(group);
        NSLog(@"GROUP2 当前线程: %@",[NSThread currentThread]);
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        dispatch_after(when, queue, ^{
            NSLog(@"GROUP2 after 当前线程: %@",[NSThread currentThread]);
            for (int i = 0; i < 10; i ++) {
                NSLog(@"GROUP2");
            }
            dispatch_group_leave(group);
        });
    });
    
    dispatch_queue_t queue3 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_group_async(group, queue3, ^{
        dispatch_group_enter(group);
        NSLog(@"GROUP3 当前线程: %@",[NSThread currentThread]);
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        dispatch_after(when, queue3, ^{
            NSLog(@"GROUP3 after 当前线程: %@",[NSThread currentThread]);
            for (int i = 0; i < 5; i ++) {
                NSLog(@"GROUP3");
            }
            dispatch_group_leave(group);
        });
    });
    
    dispatch_group_wait(group, 4 * NSEC_PER_SEC); // 设置超时 4s
    
    // 监听的还是 group 中的块全部执行完
    dispatch_group_notify(group, queue3, ^{
        NSLog(@"group3 执行完毕");
    });

    // 监听的还是 group 中的块全部执行完
    dispatch_group_notify(group, queue, ^{
        NSLog(@"group 执行完毕");
    });
}


#define kUrl1 @"http://omfcs27a3.bkt.clouddn.com/APNs1.jpg"
#define kUrl2 @"http://omfcs27a3.bkt.clouddn.com/APNs2.jpg"
#define kUrl3 @"http://omfcs27a3.bkt.clouddn.com/UINavigationController.jpg"

// 使用 dispatch_group_t  和 dispatch_group_enter 和 dispatch_group_leave 来并发请求数据后，全部结束后再做处理
- (void) im_get {
    
    
    NSLog(@"任务执行前 -> 当前线程: %@",[NSThread currentThread]);
    
    // 使用 dispatch_group 需要 dispatch_group_async 回调中的代码是在 dispatch_group_async 开辟的线程执行（不能再开辟线程）也就是说 回调不能是异步的
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    
    dispatch_group_async(_im_group, queue, ^{
        NSLog(@"GROUP1 -> 当前线程: %@",[NSThread currentThread]);
        dispatch_group_enter(_im_group);
        [self downloadTask:kUrl1];
    });
    
    dispatch_group_async(_im_group, queue, ^{
        NSLog(@"GROUP2 -> 当前线程: %@",[NSThread currentThread]);
        dispatch_group_enter(_im_group);
        [self downloadTask:kUrl2];
    });
    
    dispatch_group_async(_im_group, queue, ^{
        NSLog(@"GROUP3 -> 当前线程: %@",[NSThread currentThread]);
        dispatch_group_enter(_im_group);
        [self downloadTask:kUrl3];
    });
    
    dispatch_group_async(_im_group, queue, ^{
        NSLog(@"GROUP3 -> 当前线程: %@",[NSThread currentThread]);
        dispatch_group_enter(_im_group);
        [self downloadTask:kUrl3];
    });
    
    dispatch_group_async(_im_group, queue, ^{
        NSLog(@"GROUP3 -> 当前线程: %@",[NSThread currentThread]);
        dispatch_group_enter(_im_group);
        [self downloadTask:kUrl3];
    });
    
    dispatch_group_async(_im_group, queue, ^{
        NSLog(@"GROUP3 -> 当前线程: %@",[NSThread currentThread]);
        dispatch_group_enter(_im_group);
        [self downloadTask:kUrl3];
    });
    
    dispatch_group_async(_im_group, queue, ^{
        NSLog(@"GROUP3 -> 当前线程: %@",[NSThread currentThread]);
        dispatch_group_enter(_im_group);
        [self downloadTask:kUrl3];
    });

    dispatch_group_wait(_im_group, 1 * NSEC_PER_SEC);// 超时
    
    dispatch_group_notify(_im_group, queue, ^{
        NSLog(@"hello, gcd!");
    });
    
}

- (void) downloadTask:(NSString *)str {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:str] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"任务执行完成 -> 当前线程: %@",[NSThread currentThread]);
        UIImage *img = [UIImage imageWithData:data];
        NSLog(@"get -> 下载下来的图片: %@",img);
        
       dispatch_group_leave(_im_group);
        
    }];
    [dataTask resume];
}

- (void) im_post {
    NSURL *url = [NSURL URLWithString:@"http://www.daka.com/login"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [@"username=daka&pwd=123" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSession *session = [NSURLSession sharedSession];
    // 由于要先对request先行处理,我们通过request初始化task
    NSURLSessionTask *task = [session dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            if (!error) {
                                                NSLog(@"post -> 登录信息: %@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
                                            }
                                        }];
    [task resume];
}

@end

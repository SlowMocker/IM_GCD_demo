//
//  IMUrlRequestHandle.h
//  NSURLSessionDemo
//
//  Created by Wu on 17/5/9.
//  Copyright © 2017年 Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMUrlRequestHandle : NSObject

+ (id) shareHandle;

- (void) im_get;
- (void) im_post;

- (void) test;

@end

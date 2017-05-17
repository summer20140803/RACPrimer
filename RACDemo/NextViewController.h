//
//  NextViewController.h
//  RACDemo
//
//  Created by 开不了口的猫 on 17/5/11.
//  Copyright © 2017年 TDF. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RACSubject;


/**
  待跳转的控制器
 */
@interface NextViewController : UIViewController

// RAC代理 == 传统的delegate
@property (nonatomic, strong) RACSubject *delegate;

@end

//
//  NextViewController.m
//  RACDemo
//
//  Created by 开不了口的猫 on 17/5/11.
//  Copyright © 2017年 TDF. All rights reserved.
//

#import "NextViewController.h"
#import "RACSubject.h"

@interface NextViewController ()

@end

@implementation NextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor yellowColor]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.delegate) {
        [self.delegate sendNext:@"收到消息了"];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end

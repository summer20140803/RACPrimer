//
//  UserService.m
//  RACDemo
//
//  Created by 开不了口的猫 on 17/5/15.
//  Copyright © 2017年 TDF. All rights reserved.
//

#import "UserService.h"
#import "ReactiveObjC.h"

@interface UserService ()

@property (nonatomic, strong) RACCommand *command;

@end

@implementation UserService

- (void)simulationRequest:(void (^)())successBlock simulationDelay:(unsigned int)delay {
    [self simulationRequest:successBlock finish:nil simulationDelay:delay];
}

- (void)simulationRequest:(void (^)())successBlock finish:(void (^)())finish simulationDelay:(unsigned int)delay {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        !finish ? : finish();
        sleep(delay);
        dispatch_async(dispatch_get_main_queue(), ^{
            !successBlock ? : successBlock();
        });
    });
}

- (RACCommand *)rac_simulationRequestWithSuccess:(void (^)(id))successBlock failure:(void (^)(NSError *))failureBlock {
    @weakify(self)
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        @strongify(self)
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            [self simulationRequest:^{
                [subscriber sendNext:@"请求数据返回"];
                [subscriber sendCompleted];
            } simulationDelay:2];
            return [RACDisposable disposableWithBlock:^{
                // 这里可以取消网络请求
//                [task cancel];
            }];
        }];
    }];
    [command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        !successBlock ? : successBlock(x);
    }];
    [command.errors subscribeNext:^(NSError * _Nullable x) {
        !failureBlock ? : failureBlock(x);
    }];
    [[command.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        if ([x boolValue]) {
            NSLog(@"正在执行命令");
        } else {
            NSLog(@"命令执行完毕");
        }
    }];
    self.command = command;
    return command;
}

@end

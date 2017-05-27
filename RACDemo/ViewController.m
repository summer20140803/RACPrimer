//
//  ViewController.m
//  RACDemo
//
//  Created by 开不了口的猫 on 17/5/9.
//  Copyright © 2017年 TDF. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveObjC.h"
#import "UserModel.h"
#import "UserViewModel.h"
#import "UserService.h"
#import "NextViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *presentButton;
@property (weak, nonatomic) IBOutlet UIButton *receiveCodeBtn;

@property (nonatomic, strong) UserModel *user;
@property (nonatomic, strong) UserViewModel *viewModel;
@property (nonatomic, strong) UserService *service;

@property (nonatomic, strong) RACCommand *command;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self syntax_filter];
}





// 测试RAC代理用
- (IBAction)presentNextVC:(id)sender {
    [self syntax_RACSubject];
}

#pragma mark - Basic Syntax -
// RAC中的sequence -> OC中的array
- (void)syntax_transferSequenceToArrayOrDict {
    NSDictionary *dict = @{@"key1":@"value1", @"key2":@"value2", @"key3":@"value3"};
    NSArray *array = @[@1, @2, @3];
    
    /// dict定制成Array
    NSArray *result_array = [[dict.rac_sequence map:^id _Nullable(RACTuple *tuple) {
        // 返回result_array中的元素
        RACTupleUnpack(id key, id value) = tuple;
        return [NSString stringWithFormat:@"%@-%@", key, value];
    }] array];
    NSLog(@"转换后的oc-array : %@", result_array);
    
    /// array定制成Array
    NSArray *result_array2 = [[array.rac_sequence map:^id _Nullable(id element) {
        // 返回result_array2中的元素
        return [NSString stringWithFormat:@"custom element-%@", element];
    }] array];
    NSLog(@"转换后的oc-array2 : %@", result_array2);
}

// RAC的遍历
- (void)syntax_traverse {
    
    // 这里需要注意的是，RAC的遍历是异步延时执行，会有一点延迟
    
    ///// oc数组的遍历 /////
    NSArray *numbers = @[@1, @2, @3];
    // 这里其实是三步
    // 第一步: 把数组转换成集合RACSequence numbers.rac_sequence
    // 第二步: 把集合RACSequence转换RACSignal信号类,numbers.rac_sequence.signal
    // 第三步: 订阅信号，激活信号，会自动把集合中的所有值，遍历出来。
    [numbers.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        NSLog(@"%@",x);
    }];
    
    ///// oc字典的遍历 /////
    NSDictionary *dict = @{@"key1":@1, @"key2":@2};
    // 遍历出来的键值对会包装成RACTuple(元组对象)
    [dict.rac_sequence.signal subscribeNext:^(RACTuple *tuple) {
        NSLog(@"当前线程：%@", [NSThread currentThread]);
        //解包元组，会把元组的值，按顺序给参数里面的变量赋值
        RACTupleUnpack(id key, id value) = tuple;
        NSLog(@"key : `%@`  -  value : `%@`", key, value);
    }];
    
    NSLog(@"这是主线程执行的代码");
}

- (void)syntax_collect {
    // collect
    // 会将所有next发送的数据收集到一个NSArray中，然后一次性通过next发送到订阅者
    // @log
    /*
     2017-05-17 16:29:07.839 RACDemo[42113:8527460] (
         1,
         2,
         3
     )
    */
    NSArray *numbers = @[@1, @2, @3];
    [[numbers.rac_sequence.signal collect] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@", x);
    }];
}

- (void)syntax_RACSubject {
    NextViewController *next = [[NextViewController alloc] init];
    next.delegate = [RACSubject subject];
    [next.delegate subscribeNext:^(id  _Nullable x) {
        NSLog(@"返回的消息 : `%@`", x);
    }];
    [self presentViewController:next animated:YES completion:nil];
}

- (void)syntax_skip {
    // skip
    // 从开始跳过N次的next值
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"第一个消息"];
        [subscriber sendNext:@"第二个消息"];
        [subscriber sendNext:@"第三个消息"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"信号被销毁");
        }];
        // skip:1 跳过前面一个消息
    }] skip:1] subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收到 %@", x);
    }];
}

- (void)syntax_takeUntil {
    // takeUntil:(RACSignal *)
    // 当给定的signal完成前一直取值。最简单的栗子就是UITextField的rac_textSignal的实现（删减版本）
    /*
         - (RACSignal *)rac_textSignal {
            @weakify(self);
            return [[[[[RACSignal
                    concat:[self rac_signalForControlEvents:UIControlEventEditingChanged]]
                    map:^(UITextField *x) {
                        return x.text;
                    }]
                    takeUntil:self.rac_willDeallocSignal] // bingo!
        }
    */
    // 也就是这个Signal一直到textField执行dealloc时才停止
}

- (void)syntax_takeLast {
    // takeLast
    // 取最后N次的next值，注意，由于一开始不能知道这个Signal将有多少个next值，所以RAC实现它的方法是将所有next值都存起来，然后原Signal完成时再将后N个依次发送给接收者，但Error发生时依然是立刻发送的。
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"第一个消息"];
        [subscriber sendNext:@"第二个消息"];
        [subscriber sendNext:@"第三个消息"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"信号被销毁");
        }];
        // takeLast:2 就是说限制只接收最后2次被订阅的消息，前面的消息就接收不到了
    }] takeLast:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收到 %@", x);
    }];
}

- (void)syntax_take {
    // take
    // 从开始一共取N次的next值，不包括Competion和Error
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"第一个消息"];
        [subscriber sendNext:@"第二个消息"];
        [subscriber sendNext:@"第三个消息"];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"信号被销毁");
        }];
    // take:2 就是说限制只接收2次被订阅的消息，第三个消息就接收不到了
    }] take:2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收到 %@", x);
    }];
}

- (void)syntax_distinctUntilChanged {
    // distinctUntilChanged
    // 它将这一次的值与上一次做比较，当相同时（也包括- isEqual:）被忽略掉
    RAC(self.nameLabel, text) = [RACObserve(self.user, name) distinctUntilChanged];
    RAC(self.user, name) = [self.textField.rac_textSignal filter:^BOOL(NSString * _Nullable value) {
        return value.length >= 3;
    }];
    [[RACObserve(self.user, name) filter:^BOOL(NSString *value) {
        return value.length;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"user的name改变了 : %@", x);
    }];
}

- (void)syntax_throttle {
    // throttle
    // 假设一个搜索的场景，如果每次文本发生变化就去发送一个搜索请求，那搜索请求将非常频繁，使用throttle可以等待间隔上一次sendNext如果大于等于1秒才会执行下一次sendNext，否则将抛弃
    [[[self.textField.rac_textSignal skip:2] throttle:1] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"模拟发送一次搜索请求");
    }];
}

- (void)syntax_ignore {
    // ignore
    [[self.textField.rac_textSignal ignore:@"fuck"] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"no word 'fuck'");
    }];
}

- (void)syntax_filter {
    // filter
    __block NSMutableArray *array = @[].mutableCopy;
    __block BOOL lock = YES;
    [[@[@1,@2,@3].rac_sequence.signal filter:^BOOL(NSNumber * _Nullable value) {
        NSLog(@"filter");
        return (value.integerValue != 1);
    }]
    subscribeNext:^(NSNumber * _Nullable x) {
        [array addObject:x];
        NSLog(@"经过过滤的元素:%@", x);
    } completed:^{
        //唤醒主线程
        lock = NO;
    }];
    do {} while (lock);
    NSLog(@"主线程 - result : %@", array);
}

- (void)syntax_combineLatest {
    // combineLatest(组合消息)
    // 将一组事件组合为一个输出最新事件的signal，往往用来做组合的条件校验
    // 与merge最大的区别是combineLastest必须是所有的信号都要至少执行一次sendNext才能触发订阅的回调block
    
    RACSignal *signal_text = [self.textField.rac_textSignal skip:2];
    RACSignal *signal_length = [[RACObserve(self.user, name) skip:1] map:^id _Nullable(NSString * _Nullable value) {
        return @(value.length);
    }];
    [[RACSignal combineLatest:@[signal_text, signal_length] reduce:^id _Nullable(NSString *value, NSNumber *lengthNumber) {
        // 返回组合后的新信号的消息
        return @([value containsString:@"szy"]);
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"是否符合规范：%d", [x boolValue]);
    }];
    self.user.name = @"szyandjxl";
}

- (void)syntax_merge {
    // merge(合并消息)
    // 主要用来实现同时发起多个请求，将多个消息合并成一个消息，会调用所有被合并的消息的sendNext方法(只要有任何一个消息发送sendNext，就会触发订阅回调，区别于combineLastest)，最后再sendCompelete
    // 场景：分别请求N个不同的接口，然后分别渲染各自的UI
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求1成功！"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求2成功！"];
            [subscriber sendCompleted];
        } simulationDelay:5];
        return nil;
    }];
    [[RACSignal merge:@[signal1, signal2]] subscribeNext:^(id  _Nullable x) {
        NSLog(@"获取到的网络数据：%@", x);
    }];
}

- (void)syntax_zip {
    // zip
    // 等待多个消息都执行一次sendNext，才执行一次订阅回调，返回tuple类型的数据
    // 场景：多个接口都返回后统一渲染UI
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"request-1 success!"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"request-2 success!"];
            [subscriber sendCompleted];
        } simulationDelay:3];
        return nil;
    }];
    [[RACSignal zip:@[signal1, signal2]] subscribeNext:^(id  _Nullable x) {
        /* log:
         2017-05-17 18:16:10.090 RACDemo[43123:8589320] fetch data：<RACTuple: 0x6080000063d0> (
             "request-1 success!",
             "request-2 success!"
         )
         */
        NSLog(@"fetch data：%@", x);
    }];
}

- (void)syntax_zipWith {
    // zipWith ≈ combineLastest
    // 将两个信号压缩成一个新信号，当两个被压缩的信号都发送一次sendNext，才会收到订阅回调(RACTwoTuple类型的回调数据)
    // @log
    /* 2017-05-16 16:08:00.919 RACDemo[38208:8235663] fetch data：<RACTwoTuple: 0x608000011380> (
         "request-1 success",
         "request-2 success"
     )
    2017-05-16 16:08:03.200 RACDemo[38208:8235663] fetch data：<RACTwoTuple: 0x600000019bd0> (
         "request-1 success",
         "request-2 success"
     )
    */
    @weakify(self)
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self)
        [self.service simulationRequest:^{
            [subscriber sendNext:@"request-1 success"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [subscriber sendNext:@"request-1 success"];
                [subscriber sendCompleted];
            });
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self)
        [self.service simulationRequest:^{
            [subscriber sendNext:@"request-2 success"];
            [subscriber sendNext:@"request-2 success"];
            [subscriber sendCompleted];
        } simulationDelay:3];
        return nil;
    }];
    // 无论是signal1和signal2哪个信号先执行的sendNext，只要是signal1 zipWith的 signal2，则返回的Tuple顺序就是signal1、signal2
    [[signal1 zipWith:signal2] subscribeNext:^(id  _Nullable x) {
        NSLog(@"fetch data：%@", x);
    } completed:^{
        // 如果被压缩的信号没有一个发送sendCompleted，则不会执行这个block
        NSLog(@"zip信号被kill");
    }];
}

- (void)syntax_flatten {
    // flatten(合并)
    // 解决signals of signal，将几个signal放到一个容器中，哪一个先sendNext，就先执行订阅block
    RACSignal *signal_text = [self.textField.rac_textSignal filter:^BOOL(NSString * _Nullable value) {
        return [value containsString:@"szy"];
    }];
    RACSignal *signal_length = [[self.textField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return @(value.length);
    }] filter:^BOOL(id  _Nullable value) {
        return [value integerValue] == 3;
    }];
    [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:signal_text];
        [subscriber sendNext:signal_length];
        [subscriber sendCompleted];
        return nil;
    }] flatten] subscribeNext:^(id  _Nullable x) {
        NSLog(@"内容含有`szy`或者内容刚好三个字符 - 具体内容:%@", x);
    }];
}

- (void)syntax_flattenMap {
    // flattenMap ≈ map + flatten
    // 事件完成block后有可能会返回signal的实例，这个时候外部信号中就会包含一个内部信号，这个时候使用map去将信号转换为另一种信号，造成了嵌套的麻烦。所以说通过flattenMap将事件从内部信号发送到外部信号，并且映射到另外一个信号上去，这样这个过程就变得扁平化。Signal被按序的链接起来执行异步操作，而且不用嵌套block
    // 场景：N个接口串联，上一个请求完成继续下一个请求，一旦前面的请求失败，则中断信号
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求1成功！"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求2成功！"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal3 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求3成功！"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    // 1.如果不用flattenMap，则会出现block嵌套的现象
//    [signal1 subscribeNext:^(__kindof UIControl * _Nullable x) {
//            NSLog(@"接收到的消息：%@", x);
    //        [signal2 subscribeNext:^(id  _Nullable x) {
    //            NSLog(@"接收到的消息：%@", x);
//                [signal3 subscribeNext:^(id  _Nullable x) {
//                    NSLog(@"接收到的消息：%@", x);
//                }];
    //        }];
//    }];
    // 2.如果用flattenMap，就可以避免block嵌套
    [[[signal1 flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable requestResult) {
        NSLog(@"接收到请求1的消息：%@", requestResult);
        return signal2;
    }] flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable requestResult) {
        NSLog(@"接收到请求2的消息：%@", requestResult);
        return signal3;
    }] subscribeNext:^(id  _Nullable requestResult) {
        NSLog(@"接收到请求3的消息：%@", requestResult);
    }];
}

- (void)syntax_concat {
    // concat
    // 主要解决回调的block发生嵌套的问题，通过concat会在第一个信号 sendNext 之后，才会激活第二个信号，从而达到有序触发的目的。
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求1成功！"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求2成功！"];
            [subscriber sendCompleted];
        } simulationDelay:1];
        return nil;
    }];
    RACSignal *signal3 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求3成功！"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    [[[signal1 concat:signal2] concat:signal3] subscribeNext:^(id  _Nullable x) {
        NSLog(@"获取到的网络数据：%@", x);
    }];
}

- (void)syntax_then {
    // then
    // 跟concat类似，但是concat是在前一个信号的 sendNext 之后就会激活第二个信号，而then则是等待前一个信号发送 sendCompleted 才会激活下一个
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求1成功！"];
            // 这里特意制作了一个长时间的延迟，证明是在sendCompleted后激活下一个信号
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [subscriber sendCompleted];
            });
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求2成功！"];
            [subscriber sendCompleted];
        } simulationDelay:1];
        return nil;
    }];
    [signal1 subscribeNext:^(id  _Nullable x) {
        NSLog(@"获取到的网络数据：%@", x);
    }];
    [[signal1 then:^RACSignal * _Nonnull{
        return signal2;
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"获取到的网络数据：%@", x);
    }];
}

- (void)syntax_tryAndCatch {
    // error传递链(配合try和catch)
    // FRP具备这样一个特点，信号因为进行组合从而得到了一个数据链，而数据链的任一节点发出错误信号，都可以顺着这个链条最终交付给订阅者。这就正好解决了异常处理的问题
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 模拟一下异步请求
        [self.service simulationRequest:^{
            [subscriber sendNext:@"网络请求2成功！"];
            [subscriber sendCompleted];
        } simulationDelay:2];
        return nil;
    }];
    
    // 串联N个请求，生成请求依赖，一旦其中有请求响应报错，则产生的error会顺着请求链，最终被catch捕获，然后return给最终的订阅者
    [[[[[signal1 try:^BOOL(id  _Nullable requestData, NSError * _Nullable __autoreleasing * _Nullable errorPtr) {
        if (requestData) {
            NSLog(@"接收到请求1返回数据：%@", requestData);
            return YES;
        } else {
            *errorPtr = [NSError errorWithDomain:@"RACDemo" code:0 userInfo:@{NSLocalizedDescriptionKey : @"请求1返回数据异常!"}];
            return NO;
        }
    }] flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable requestData) {
        return signal2;
    }] try:^BOOL(id  _Nullable requestData, NSError * _Nullable __autoreleasing * _Nullable errorPtr) {
        if (requestData) {
            return YES;
        } else {
            *errorPtr = [NSError errorWithDomain:@"RACDemo" code:0 userInfo:@{NSLocalizedDescriptionKey : @"请求2返回数据异常!"}];
            return NO;
        }
    }] catch:^RACSignal * _Nonnull(NSError * _Nonnull error) {
        return [RACSignal error:error];
    }] subscribeNext:^(id  _Nullable requestData) {
        NSLog(@"接收到请求2返回数据：%@", requestData);
    } error:^(NSError * _Nullable error) {
        NSLog(@"error:%@", error.localizedDescription);
    }];
}

- (void)syntax_createSignal {
    // RACSignal使用步骤：
    // 1.创建信号 + (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe
    // 2.订阅信号,才会激活信号. - (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock
    // 3.发送信号 - (void)sendNext:(id)value
    
    
    // RACSignal底层实现：
    // 1.创建信号，首先把didSubscribe保存到信号中，还不会触发。
    // 2.当信号被订阅，也就是调用signal的subscribeNext:nextBlock
    // 2.2 subscribeNext内部会创建订阅者subscriber，并且把nextBlock保存到subscriber中。
    // 2.1 subscribeNext内部会调用siganl的didSubscribe
    // 3.siganl的didSubscribe中调用[subscriber sendNext:@1];
    // 3.1 sendNext底层其实就是执行subscriber的nextBlock
    
    // 1.创建信号
    RACSignal *siganl = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // block调用时刻：每当有订阅者订阅信号，就会调用block。
        // 3.发送信号
        [subscriber sendNext:@1];
        
        // 如果不在发送数据，最好发送信号完成，内部会自动调用[RACDisposable disposable]取消订阅信号。
        [subscriber sendCompleted];
        
        return [RACDisposable disposableWithBlock:^{
            
            // block调用时刻：当信号发送完成或者发送错误，就会自动执行这个block,取消订阅信号。
            // 执行完Block后，当前信号就不在被订阅了。
            NSLog(@"信号被销毁");
        }];
    }];
    
    // 2.订阅信号,才会激活信号.
    [siganl subscribeNext:^(id x) {
        // 4.接收并处理数据
        // block调用时刻：每当有信号发出数据，就会调用block.
        NSLog(@"接收到数据:%@",x);
    } error:^(NSError * _Nullable error) {
        NSLog(@"失败:%@", error.localizedDescription);
    }];
}

- (void)syntax_RACCommand {
    // 一、RACCommand使用步骤:
    // 1.创建命令 initWithSignalBlock:(RACSignal * (^)(id input))signalBlock
    // 2.在signalBlock中，创建RACSignal，并且作为signalBlock的返回值
    // 3.执行命令 - (RACSignal *)execute:(id)input
    
    // 二、RACCommand使用注意:
    // 1.signalBlock必须要返回一个信号，不能传nil.
    // 2.如果不想要传递信号，直接创建空的信号[RACSignal empty];
    // 3.RACCommand中信号如果数据传递完，必须调用[subscriber sendCompleted]，这时命令才会执行完毕，否则永远处于执行中。
    // 4.RACCommand需要被强引用，否则接收不到RACCommand中的信号，因此RACCommand中的信号是延迟发送的。
    
    // 三、RACCommand设计思想：内部signalBlock为什么要返回一个信号，这个信号有什么用。
    // 1.在RAC开发中，通常会把网络请求封装到RACCommand，直接执行某个RACCommand就能发送请求。
    // 2.当RACCommand内部请求到数据的时候，需要把请求的数据传递给外界，这时候就需要通过signalBlock返回的信号传递了。
    
    // 四、如何拿到RACCommand中返回信号发出的数据。
    // 1.RACCommand有个执行信号源executionSignals，这个是signal of signals(信号的信号),意思是信号发出的数据是信号，不是普通的类型。
    // 2.订阅executionSignals就能拿到RACCommand中返回的信号，然后订阅signalBlock返回的信号，就能获取发出的值。
    
    // 五、监听当前命令是否正在执行executing
    
    // 六、使用场景,监听按钮点击，网络请求
    
    self.command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        NSLog(@"执行命令");
        // 创建信号，用来传递数据
        @weakify(self)
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            @strongify(self)
            [self.service simulationRequest:^{
                [subscriber sendNext:@"XXXXX"];
                //传递完数据，要调用sendCompleted，这时命令才执行完毕
                [subscriber sendCompleted];
            } simulationDelay:2];
            return nil;
        }];
    }];
    
    [self.command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"获取的数据：%@", x);
    }];
    
    // 监听命令是否执行完毕，默认会接收一次消息，可以直接跳过
    [[self.command.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        if ([x boolValue]) {
            // 正在执行
            NSLog(@"正在执行命令");
        } else {
            // 执行完毕
            NSLog(@"命令执行完成");
        }
    }];
    
    // 开始执行命令
    [self.command execute:nil];
    
    // 外界的代码(用来佐证RACCommand的信号是延迟发送的，但是是在主线程)
    NSLog(@"外面执行的代码");
}

- (void)syntax_RACMulticastConnection {
    // RACMulticastConnection使用步骤:
    // 1.创建信号 + (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe
    // 2.创建连接 RACMulticastConnection *connect = [signal publish];
    // 3.订阅信号,注意：订阅的不在是之前的信号，而是连接的信号。 [connect.signal subscribeNext:nextBlock]
    // 4.连接 [connect connect]
    
    // RACMulticastConnection底层原理:
    // 1.创建connect，connect.sourceSignal -> RACSignal(原始信号)  connect.signal -> RACSubject
    // 2.订阅connect.signal，会调用RACSubject的subscribeNext，创建订阅者，而且把订阅者保存起来，不会执行block。
    // 3.[connect connect]内部会订阅RACSignal(原始信号)，并且订阅者是RACSubject
    // 3.1.订阅原始信号，就会调用原始信号中的didSubscribe
    // 3.2 didSubscribe，拿到订阅者调用sendNext，其实是调用RACSubject的sendNext
    // 4.RACSubject的sendNext,会遍历RACSubject所有订阅者发送信号。
    // 4.1 因为刚刚第二步，都是在订阅RACSubject，因此会拿到第二步所有的订阅者，调用他们的nextBlock
    
    
    // 需求：假设在一个信号中发送请求，每次订阅一次都会发送请求，这样就会导致多次请求。
    // 解决：使用RACMulticastConnection就能解决.
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"信号被订阅了");
        // 发送数据
        // 注意！在哪里发送的数据，接收订阅数据的block就在哪个线程执行，除非在subscribeNext时用deliverOn指定执行线程
        [subscriber sendNext:@"XXXX"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    // 创建连接
    RACMulticastConnection *connect = [signal publish];
    
    // 订阅信号，也不能激活信号，只是保存订阅者到内部数组中，必须通过连接操作，当调用连接，就会一次性向所有订阅者调用sendNext:
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者1，接收到数据：%@", x);
    }];
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者2，接收到数据：%@", x);
    }];
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者3，接收到数据：%@", x);
    }];
    
    // 激活信号
    [connect connect];
}

- (void)syntax_replace {
    /*
        // 1.代替代理
        // 需求：自定义redView,监听红色view中按钮点击
        // 之前都是需要通过代理监听，给红色View添加一个代理属性，点击按钮的时候，通知代理做事情
        // rac_signalForSelector:把调用某个对象的方法的信息转换成信号，就要调用这个方法，就会发送信号。
        // 这里表示只要redV调用btnClick:,就会发出信号，订阅就好了。
        [[redV rac_signalForSelector:@selector(btnClick:)] subscribeNext:^(id x) {
            NSLog(@"点击红色按钮");
        }];
        
        // 2.KVO
        // 把监听redV的center属性改变转换成信号，只要值改变就会发送信号
        // observer:可以传入nil
        [[redV rac_valuesAndChangesForKeyPath:@"center" options:NSKeyValueObservingOptionNew observer:nil] subscribeNext:^(id x) {
            NSLog(@"%@",x);
        }];
        
        // 3.监听事件
        // 把按钮点击事件转换为信号，点击按钮，就会发送信号
        [[self.btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            NSLog(@"按钮被点击了");
        }];
        
        // 4.代替通知
        // 把监听到的通知转换信号
        [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(id x) {
            NSLog(@"键盘弹出");
        }];
        
        // 5.监听文本框的文字改变
        [_textField.rac_textSignal subscribeNext:^(id x) {
            NSLog(@"文字改变了%@",x);
        }];
     */
}

// 适用于`多请求依赖`的场景
// 处理多个请求，都返回结果的时候，统一做处理
- (void)syntax_signalDependence {
    RACSignal *request_1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 发送数据
        NSLog(@"开始请求1");
        [self.service simulationRequest:^{
            [subscriber sendNext:@"数据1"];
            [subscriber sendCompleted];
        } finish:^{
            NSLog(@"返回请求1的响应");
        } simulationDelay:2];
        return nil;
    }];
    RACSignal *request_2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 发送数据
        NSLog(@"开始请求2");
        [self.service simulationRequest:^{
            [subscriber sendNext:@"数据2"];
            [subscriber sendCompleted];
        } finish:^{
            NSLog(@"返回请求2的响应");
        } simulationDelay:4];
        return nil;
    }];
    // 使用注意：几个信号，参数一的方法就几个参数，每个参数对应信号发出的数据
    [self rac_liftSelector:@selector(refreshUIWithReceivedata1:data2:) withSignalsFromArray:@[request_1, request_2]];
}

// 更新UI的方法
- (void)refreshUIWithReceivedata1:(id)data1 data2:(id)data2 {
    NSLog(@"接收到的数据 - data1：`%@`， data2：`%@`", data1, data2);
}


#pragma mark - MVVM Operations -
// 数据绑定的规则
- (void)mvvm_bindRules {
    // 单向绑定
    RAC(self.viewModel, title) = RACObserve(self.user, name);
    // 双向绑定
    RACChannelTo(self.nameLabel, text) = RACChannelTo(self.viewModel, title);
    RACChannelTo(self.viewModel, title) = self.textField.rac_newTextChannel;
    // 命令绑定
    self.presentButton.rac_command = [self.service rac_simulationRequestWithSuccess:^(id data) {
        NSLog(@"成功：%@", data);
    } failure:^(NSError *error) {
        NSLog(@"失败：%@", error.localizedDescription);
    }];
    // 模拟赋值
    self.user.name = @"szy";
}

#pragma mark - Demo -
#pragma mark 点击发送验证码
- (void)demo_receiveCode {
    @weakify(self)
    [[[[self.receiveCodeBtn rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^__kindof RACSignal * _Nullable(__kindof UIControl * _Nullable value) {
        @strongify(self)
        return [self timerLogic];
    }]
    takeUntil:[self rac_willDeallocSignal]]
    subscribeNext:^(RACTuple *  _Nullable tuple) {
        @strongify(self)
        NSString *title = tuple.first;
        UIColor *color = tuple.second;
        BOOL enable = [tuple.third boolValue];
        [self.receiveCodeBtn setTitle:title forState:UIControlStateNormal];
        [self.receiveCodeBtn setTitleColor:color forState:UIControlStateNormal];
        self.receiveCodeBtn.enabled = enable;
    } error:^(NSError * _Nullable error) {
        NSLog(@"error: %@", [error localizedDescription]);
    } completed:^{
        NSLog(@"completed");
    }];
}

#pragma mark 函数式编程举例
// 需求：实现一个每秒发送值为0、1、2、3...10的递增整数信号
// 比较常规实现和函数式实现(即无变量)
- (void)demo_frpCode {
    // 常规实现(掺杂着太多中间变量)
//    [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
//        __block int i = 0;
//        __block void (^increaseBlock)();
//        increaseBlock = ^{
//            if (i > 10) {
//                increaseBlock = nil;
//                return;
//            }
//            [subscriber sendNext:@(i)];
//            i ++;
//            [[RACScheduler mainThreadScheduler] afterDelay:1 schedule:^{
//                !increaseBlock ? : increaseBlock();
//            }];
//        };
//        increaseBlock();
//        return nil;
//    }] subscribeNext:^(id  _Nullable x) {
//        NSLog(@"数据：%@", x);
//    }];
    
    // FRP编程实现(无状态变量)
    [[[[[[[RACSignal return:@1] repeat] take:10] scanWithStart:@0 reduce:^id _Nullable(NSNumber *  _Nullable running, NSNumber *  _Nullable next) {
        return @(running.integerValue + next.integerValue);
    }] map:^id _Nullable(id  _Nullable value) {
        return [[RACSignal return:value] delay:1];
    }] concat]
    subscribeNext:^(id  _Nullable x) {
        NSLog(@"数据：%@", x);
    }];
}


#pragma mark - Getter -
- (UserModel *)user {
    if (!_user) {
        _user = [[UserModel alloc] init];
    }
    return _user;
}

- (UserViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[UserViewModel alloc] init];
    }
    return _viewModel;
}

- (UserService *)service {
    if (!_service) {
        _service = [[UserService alloc] init];
    }
    return _service;
}

- (RACSignal *)timerLogic {
    static int t = 60;
    RACSignal *timer = [[RACSignal interval:1.f onScheduler:[RACScheduler mainThreadScheduler]] startWith:nil];
    
    NSMutableArray *numbers = @[].mutableCopy;
    for (int i = t; i >= 0; i --) {
        [numbers addObject:@(i)];
    }
    
    return [[[[[[numbers.rac_sequence.signal zipWith:timer] map:^id _Nullable(RACTuple * _Nullable tuple) {
        NSNumber *t_count = tuple.first;
        NSString *btnTitle;
        UIColor *titleColor;
        NSNumber *enable;
        if ([t_count integerValue]) {
            btnTitle = [NSString stringWithFormat:@"重试(%lds)", [t_count integerValue]];
            titleColor = [UIColor lightGrayColor];
            enable = @NO;
        } else {
            btnTitle = @"重试";
            titleColor = [UIColor darkGrayColor];
            enable = @YES;
        }
        return RACTuplePack(btnTitle, titleColor, enable);
    }]
    startWith:RACTuplePack(@"重试(60s)", [UIColor lightGrayColor], @NO)]
    takeUntil:[self rac_willDeallocSignal]]
    setNameWithFormat:@"%s retryButtonTitleAndEnable signal", __PRETTY_FUNCTION__]
    logCompleted];
}

@end

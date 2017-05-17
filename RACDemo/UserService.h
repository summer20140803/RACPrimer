//
//  UserService.h
//  RACDemo
//
//  Created by 开不了口的猫 on 17/5/15.
//  Copyright © 2017年 TDF. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RACCommand;

@interface UserService : NSObject

- (void)simulationRequest:(void (^)())successBlock simulationDelay:(unsigned int)delay;
- (void)simulationRequest:(void (^)())successBlock finish:(void (^)())finish simulationDelay:(unsigned int)delay;

- (RACCommand *)rac_simulationRequestWithSuccess:(void (^)(id data))successBlock failure:(void (^)(NSError *error))failureBlock;

@end

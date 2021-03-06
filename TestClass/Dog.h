//
//  Dog.h
//  KeyPathExtensionSample
//
//  Created by NOVO on 2018/11/1.
//  Copyright © 2018 NOVO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyPathExtensionConst.h"

@class Person;
@class Food;
NS_ASSUME_NONNULL_BEGIN

@interface Dog : NSObject
@property (nonatomic,strong) Person* master;
@property (nonatomic,copy) NSString* name;
@property (nonatomic,copy) NSString* nickName;
@property (nonatomic,assign) NSInteger age;
@property (nonatomic,assign) NSInteger number;
@property (nonatomic,assign) CGRect frame;
@property (nonatomic,strong) Food* food;
@property (nonatomic,strong) Food* food0;
@property (nonatomic,strong) Food* food1;
@property (nonatomic,strong) Food* food2;
@property (nonatomic,strong,readonly) Food* readOnlyFood;

@end

NS_ASSUME_NONNULL_END

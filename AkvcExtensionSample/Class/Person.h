//
//  Person.h
//  AKVCExtensionSample
//
//  Created by NOVO on 2018/11/1.
//  Copyright © 2018 NOVO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Dog;

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject
@property (nonatomic,assign) NSUInteger age;
@property (nonatomic,copy) NSString* name;
@property (nonatomic,copy) NSString* nickName;
@property (nonatomic,assign) CGRect frame;
@property (nonatomic,strong) Person* spouse;
@property (nonatomic,strong) NSMutableArray<Person*>* firends;
@property (nonatomic,strong) NSMutableArray<Dog*>* dogs;
@end

NS_ASSUME_NONNULL_END

//
//  NSObject+KeyPathExtension.h
//  KVCExtensionProgram
//
//  Created by NOVO on 2018/10/19.
//  Copyright © 2018 NOVO. All rights reserved.
//  https://github.com/qddnovo/KeyPathExtension
//

#import <Foundation/Foundation.h>


@interface NSObject(NSObjectKeyPathExtension)


/**
 Get value by FullPath that can access the structure.
 FullPath adds the ability to access the structure on the basis of NSKeyPath.
 Accessing properties in a structure using the accessor '->'.
 
 Example -
 :
 'view.frame->size->width'
 
 fullPath在NSkeyPath的基础上增加了访问结构体的功能
 使用访问器'->'访问结构体中的属性

 @return The return values are boxed.返回值都是装箱的
 */
- (id _Nullable)kpe_valueForFullPath:(NSString* _Nonnull)fullPath;
/** Refer to : kpe_valueForFullPath: . */
- (void)kpe_setValue:(id _Nullable)value forFullPath:(NSString* _Nonnull)fullPath;


/**
 Get values by sub string of property key.属性名模糊匹配
 `Subkey` can be used as a sub string to match properties.(Case insensitive/不区分大小写)
 This method is invalid for the `base type` propertys.It works for custom propertys.Because the Foundation Class is a black box.
 
 Example -
 :
 `time` can match 'createTime' and 'modifyTime'.
 
 通过键的子字符串获取值
 subkey可以作为字符串进行属性的匹配，但是该方法对基础类型的属性无效
 
 @param subkey substring of key.Search is ignoring Case.
 @return The properties that match to are unordered.匹配到的属性是无序的
 */
- (NSArray* _Nonnull)kpe_valuesForSubkey:(NSString* _Nonnull)subkey;
/** Refer to kpe_valuesForSubkey: */
- (void)kpe_setValue:(id _Nullable)value forSubkey:(NSString* _Nonnull)subkey;


/**
 Get values by regular expressions of property key.属性名正则匹配
 `regkey` is regular expressions to match properties.
 This method is invalid for the `base type` propertys.It works for custom propertys.Because the Foundation Class is a black box.
 
 
 Example -
 :
 `lable\d+` can match 'lable0' and 'lable1'.
 
 通过键的正则表达式获取值。
 regkey是用于匹配属性名的正则表达式，但是该方法对基础类型的属性无效
 
 @param regkey Regular expressions to match properties.
 @return The properties that match to are unordered.匹配到的属性是无序的
 */
- (NSArray* _Nonnull)kpe_valuesForRegkey:(NSString* _Nonnull)regkey;
/** Refer to kpe_valuesForRegkey: */
- (void)kpe_setValue:(id _Nullable)value forRegkey:(NSString* _Nonnull)regkey;


/**
 ExtensionPath is a versatile key path.
 扩展路径
 
 Name                   Representation
 -------------------------------------
 StructPath         :   NSKeyPath->StructPath->StructPath->...
 Indexer            :   @[...]
 PathFunction       :   @PathFunction
 Subkey             :   <...>
 Regkey             :   <$...$>
 SELInspector       :   SEL(...)?
 ClassInspector     :   Class(...)?
 KeysAccessor       :   {KeyPath,KeyPath, ...}
 PredicateFilter    :   @:...!
 PredicateEvaluate  :   @:...?
 -------------------------------------
 
 StructPath -
 :
 Refer to kpe_valueForFullPath:
 
 Indexer -
 :
 Provides a simple way to access array elements in key path.
 @[0] , @[0,1]
 Use the index symbol 'i' to find elements within the array range.
 @[i <= 3 , i > 5]
 Use the index symbol '!' You can exclude elements from an array.
 @[!0,!1] , @[i != 0 , i != 1]
 Or combine them.
 @[i<5 , 9] , @[i<5 , !3]
 Confirm elements and deny elements cannot exist at the same time.
 It's wrong:
 @[0,!1]
 
 PathFunction -
 :
 Defining some special function to enable Extensionpath to handle more complex things.
 [KeyPathExtension registFunction:@"sortFriends" withBlock:^id(id  _Nullable target) {
 
    ... ...
    return result;
 }];
 Use PathFunction like : `...user.friendList.@sortFriends...`
 
 Subkey -
 :
 Refer to kpe_valuesForSubkey:
 
 Regkey -
 :
 Refer to kpe_valuesForRegkey:
 
 SELInspector -
 :
 SELInspector equates to respondsToSelector:
 `SEL(addObject:)?`
 
 ClassInspector -
 :
 ClassInspector equates to isKindOfClass:
 `Class(NSString)?`
 
 KeysAccessor -
 :
 Use Keysaccessor to access multiple paths at once.The returned results are placed sequentially in the array
 "{tody.food.name,yesterday.food.name}.@isAllEqual"
 Discussion : Predicate, Subkey, Regkey are disable in KeysAccessor!In addition,and the nil value will be replaced by NSNull.
 
 PredicateFilter -
 :
 PredicateFilter equates to  filteredArrayUsingPredicate:
 Expressions : `@:...!`; Using predicate at the symbol `...`
 `...users.@: age >= 18 && sex == 1 !...`
 Discussion : Symbol `!.` or `?.` is forbidden to use, but `?`, `!` , `.` are available.
 
 PredicateEvaluate -
 :
 PredicateEvaluate equates to  evaluateWithObject:
 Expressions : `@:...?`; Using predicate at the symbol `...`
 `...user.@: age >= 18 && sex == 1 !...`
 Discussion : Symbol `!.` or `?.` is forbidden to use, but `?`, `!` , `.` are available.
 
 @return All return values are boxed,except nil.除nil,所有返回值都是装箱的.
 */
- (id _Nullable)kpe_valueForExtensionPath:(NSString* _Nonnull)extensionPath;

/**
 Refer to kpe_valueForExtensionPath:
 
 KeysAccessor -
 :
 Discussion : In current method ,you can only use KeysAccessor for mutable object.Like NSMutableArray, NSMutableOrderedSet.
 */
- (void)kpe_setValue:(id _Nullable)value forExtensionPath:(NSString* _Nonnull)extensionPath;


/**
 This method provides a convenient ability to use placeholders in ExtensionPath.提供便捷的参数化路径
 
 Example -
 :
 [anyObject kpe_valueForExtensionPathWithFormat:@"...@[%d]...",index];
 */
- (id _Nullable)kpe_valueForExtensionPathWithFormat:(NSString* _Nonnull)extensionPathWithFormat, ... NS_FORMAT_FUNCTION(1,2);

/**
 Refer to kpe_valueForExtensionPathWithFormat:
 */
- (void)kpe_setValue:(id _Nullable)value forExtensionPathWithFormat:(NSString* _Nonnull)extensionPathWithFormat, ... NS_FORMAT_FUNCTION(2,3);


/**
 This method provides a convenient ability to use predicate placeholders in ExtensionPath.提供参数化的谓词
 
 Example -
 :
 [anObject kpe_valueForExtensionPathWithPredicateFormat:@"...@:SELF != %@!...", anyObject];
 
 Discussion :
 The parameter list accepts only boxed values.
 Format and Predicateformat can't be used at the same time.
 If you need to do this, please call these two different methods separately.
 Format和Predicateformat不能同时在一条路径中使用，请拆成两个方法实现.
 
 @param extendPathWithPredicateFormat Please note that : This format is limited to accepting `id` type or boxed  value.Use `KPEBoxValue(...)` to wrap scalar or struct.只接受装箱参数不接受基础值类型
 */
- (id _Nullable)kpe_valueForExtensionPathWithPredicateFormat:(NSString* _Nonnull)extendPathWithPredicateFormat,...NS_REQUIRES_NIL_TERMINATION;

/**
 Refer to : kpe_valueForExtensionPathWithPredicateFormat:
 */
- (void)kpe_setValue:(id _Nullable)value forExtensionPathWithPredicateFormat:(NSString* _Nonnull)extendPathWithPredicateFormat, ...NS_REQUIRES_NIL_TERMINATION;

/**
 Refer to : kpe_valueForExtensionPathWithPredicateFormat:
 */
- (id _Nullable)kpe_valueForExtensionPathWithPredicateFormat:(NSString *_Nonnull)extendPathWithPredicateFormat arguments:(va_list)arguments NS_FORMAT_FUNCTION(1,0);

/**
 Refer to : kpe_valueForExtensionPathWithPredicateFormat:
 */
- (void)kpe_setValue:(id _Nonnull )value forExtensionPathWithPredicateFormat:(NSString * _Nonnull)extendPathWithPredicateFormat arguments:(va_list)arguments NS_FORMAT_FUNCTION(2,0);
@end

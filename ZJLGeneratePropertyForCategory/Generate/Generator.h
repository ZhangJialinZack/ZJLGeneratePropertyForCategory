//
//  Generator.h
//  TestMX
//
//  Created by Zack on 16/7/7.
//  Copyright © 2016年 zhangjialin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Generator : NSObject

+ (Generator *)sharedInstance;

// 获取所有属性名字
- (NSArray *) getAllPropertyNames: (Class)className;
// 获取所有属性类型
- (NSArray *) getAllPropertyTypes: (Class)className;
// 获取所有一一对应的属性类型和名字
- (NSArray *) getAllPropertyNamesAndTypes: (Class)className;
// 判断是否是OC类型
- (BOOL) isOCType: (NSString *)type;
// 属性attrbute 转换成 实际类型
- (NSString *)convertToOCType:(NSString *)attribute;

// 生成Category中.m文件内容
- (NSString *)generateText: (Class)classname;

@end

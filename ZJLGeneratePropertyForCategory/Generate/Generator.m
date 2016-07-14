//
//  Generator.m
//  TestMX
//
//  Created by Zack on 16/7/7.
//  Copyright © 2016年 zhangjialin. All rights reserved.
//

#import "Generator.h"
#import <objc/runtime.h>

@implementation Generator

+ (Generator *)sharedInstance
{
    static dispatch_once_t pred = 0;
    static Generator *sharedObject = nil;
    _dispatch_once(&pred, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (NSArray *) getAllPropertyNames: (Class)className
{
    NSMutableArray *properties = @[].mutableCopy;
    
    unsigned int numPro;
    objc_property_t *pps = class_copyPropertyList(className, &numPro);
    for (int i = 0; i < numPro; i++) {
        objc_property_t pp = pps[i];
        [properties addObject:[NSString stringWithUTF8String:property_getName(pp)]];
    }
    free(pps);
    
    return properties;
}

- (NSArray *) getAllPropertyTypes: (Class)className
{
    NSMutableArray *properties = @[].mutableCopy;
    
    unsigned int numType;
    objc_property_t *pps = class_copyPropertyList(className, &numType);
    for (int i = 0; i < numType; i++) {
        objc_property_t pp = pps[i];
        NSString *attribute = [NSString stringWithUTF8String:property_getAttributes(pp)];
        NSLog(@"att: %@",attribute);
        [properties addObject:[self convertToOCType:attribute]];
    }
    free(pps);
    
    return properties;
}

- (NSArray *) getAllPropertyNamesAndTypes: (Class)className
{
    NSMutableArray *arr = @[].mutableCopy;
    
    NSArray *properties = [self getAllPropertyNames:className];
    NSArray *types = [self getAllPropertyTypes:className];
    
    for (int i = 0; i < properties.count; i++) {
        NSDictionary *dict = @{properties[i]:types[i]};
        [arr addObject:dict];
    }
    
    return arr;
}

- (BOOL) isOCType: (NSString *)type
{
    char ch = [type characterAtIndex:0];
    return (ch >= 'A' && ch <= 'Z');
}

- (NSString *)convertToOCType:(NSString *)attribute
{
    NSString *str = @"";
    char ch = [attribute characterAtIndex:1];
    
    
    switch (ch) {
        case '@':
            str = (NSString *)[[attribute componentsSeparatedByString:@","] firstObject];
            str = [str substringFromIndex:3];
            str = [str substringToIndex:str.length-1];
            break;
        case 'q':
            str = @"NSInteger";
            break;
        case 'd':
            str = @"float";
            break;
        case 'B':
            str = @"bool";
            break;
        case 'i':
            str = @"int";
            break;
        default:
            break;
    }
    
    return str;
}

- (NSString *)generateText: (Class)classname
{
    NSMutableString *text = @"".mutableCopy;
    NSArray *properties = [self getAllPropertyNamesAndTypes:classname];
    if (!properties || properties.count == 0) {
        return nil;
    }
    
    // #import
    NSString *importStr = [NSString stringWithFormat:@"#import \"%@.h\"\n\n", classname];
    [text appendString:importStr];
    
    // 输出类似static const void *cinemaNameKey; 的语句
    NSArray *names = [self getAllPropertyNames:classname];
    for (int i = 0; i < names.count; i++) {
        NSString *str = [NSString stringWithFormat:@"static const void *%@Key;\n", names[i]];
        [text appendString:str];
    }
    [text appendString:@"\n"];
    
    // @implementation
    NSString *implentStr = [NSString stringWithFormat:@"@implementation %@\n\n", classname];
    [text appendString:implentStr];
    
    // body
    NSArray *types = [self getAllPropertyTypes:classname];
    for (int i =  0 ; i < names.count; i++) {
        [text appendString:[self generateGetMethodWithName:names[i] Type:types[i]]];;
        [text appendString:[self generateSetMethodWithName:names[i] Type:types[i]]];
    }
    
    // @end
    NSString *endStr = [NSString stringWithFormat:@"@end"];
    [text appendString:endStr];
    
    return text;
}

- (NSString *) generateSetMethodWithName:(NSString *)name Type:(NSString *)type
{
    NSString *cappitalName = [name capitalizedString];
    NSString *typeStr = [self isOCType:type] ? [NSString stringWithFormat:@"%@ *",type] : [self convertAssignedTypeToCorrectReturnType:type];
    NSString *associationPolicy = [self isOCType:type] ? @"OBJC_ASSOCIATION_COPY_NONATOMIC" : @"OBJC_ASSOCIATION_RETAIN_NONATOMIC";
    
    
    if ([self isOCType:type]) {
        return [NSString stringWithFormat:@"- (void)set%@:(%@)%@\n{\n\tobjc_setAssociatedObject(self, &%@Key, %@, %@);\n}\n\n", cappitalName, typeStr, name, name, name, associationPolicy];
    }
    else
    {
        return [NSString stringWithFormat:@"- (void)set%@:(%@)%@\n{\n\tobjc_setAssociatedObject(self, &%@Key, [NSNumber numberWith%@:%@], %@);\n}\n\n", cappitalName, typeStr, name, name, [type capitalizedString], name, associationPolicy];
    }
}

- (NSString *) generateGetMethodWithName:(NSString *)name Type:(NSString *)type
{
    NSString *typeStr = [self isOCType:type] ? [NSString stringWithFormat:@"%@ *",type] : [self convertAssignedTypeToCorrectReturnType:type];
    if ([self isOCType:type]) {
        return [NSString stringWithFormat:@"- (%@)%@\n{\n\treturn objc_getAssociatedObject(self, &%@Key);\n}\n\n", typeStr, name, name];
    }
    else
    {
        return [NSString stringWithFormat:@"- (%@)%@\n{\n\treturn [objc_getAssociatedObject(self, &%@Key) %@Value];\n}\n\n", typeStr, name, name, [self convertAssignedTypeToValueType:type]];
    }
}

- (NSString *)convertAssignedTypeToCorrectReturnType:(NSString *)type
{
    NSString *str = type;
    if ([type isEqualToString:@"bool"]) {
        str = @"BOOL";
    }
    else if([type isEqualToString:@"double"] || [type isEqualToString:@"float"])
    {
        str = @"CGFloat";
    }
    else if([type isEqualToString:@"int"])
    {
        str = @"SInt32";
    }
    
    return str;
}


- (NSString *)convertAssignedTypeToValueType:(NSString *)type
{
    NSString *str = type;
    if([type isEqualToString:@"double"] || [type isEqualToString:@"float"])
    {
        str = @"float";
    }
    
    return str;
}

@end

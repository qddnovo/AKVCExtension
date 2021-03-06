//
//  NSValue+KVCExtension.m
//  KVCExtensionProgram
//
//  Created by NOVO on 2018/10/19.
//  Copyright © 2018 NOVO. All rights reserved.
//  https://github.com/qddnovo/KeyPathExtension
//

#import "NSValue+KeyPathExtension.h"
#import "KeyPathExtensionConst.h"



#define Block_GetStructValueForPath_ReValue(from,path,to)   \
\
^(NSValue* value){\
    \
    return [NSValue valueWith##to:[value from##Value].path];\
}



#define Block_GetStructValueForPath_ReNumber(from,path,to)  \
\
^(NSValue* value){\
    \
    return [NSNumber numberWith##to:[value from##Value].path];\
}



#define Block_SetStructValueForPath(type,path,vType)    \
\
^(NSValue* _self,id value){\
    \
    type identify = [_self type##Value];        \
    identify.path = [value vType##Value];       \
    return [NSValue valueWith##type:identify];  \
}


@implementation NSValue(NSValueKeyPathExtension)

- (BOOL)kpe_valueIsNumberRepresentation
{
    if([self isKindOfClass:[NSNumber class]]){
        return YES;
    }
    const char* objcType = self.objCType;
    
    if(strcmp(objcType, @encode(double)) == 0 ||
       strcmp(objcType, @encode(float)) == 0 ||
       strcmp(objcType, @encode(unsigned long)) == 0 ||
       strcmp(objcType, @encode(unsigned long long)) == 0 ||
       strcmp(objcType, @encode(long)) == 0 ||
       strcmp(objcType, @encode(long long)) == 0 ||
       strcmp(objcType, @encode(int)) == 0 ||
       strcmp(objcType, @encode(unsigned int)) == 0 ||
       strcmp(objcType, @encode(BOOL)) == 0 ||
       strcmp(objcType, @encode(bool)) == 0 ||
       strcmp(objcType, @encode(char)) == 0 ||
       strcmp(objcType, @encode(short)) == 0 ||
       strcmp(objcType, @encode(unsigned char)) == 0 ||
       strcmp(objcType, @encode(unsigned short)) == 0
       ){
        return YES;
    }
    
    return NO;
}
- (BOOL)kpe_valueIsStructRepresentation
{
    if([self isKindOfClass:[NSNumber class]]){
        return NO;
    }
    
    //{structName=typeOfContents}
    const char* objcType = self.objCType;
    unsigned long len = strlen(objcType);
    
    //Class = #
    if(len==1 && objcType[0]=='#') return YES;
    //limit {*=*}
    if(len<5) return NO;
    //check {*}
    if(objcType[0]!='{' || objcType[len-1]!='}') return NO;
    //check *=*
    unsigned long idxOfEq = 0;
    for (unsigned long i=1; i<len-1; i++) {
        
        if(objcType[i] == '='){
            idxOfEq = i;
            break;
        }
    }
    return (idxOfEq>1 && idxOfEq<len-2);
}

- (__kindof NSValue* _Nullable)kpe_structValueForKey:(NSString* _Nonnull)key
{
    if(!key) {//only key
        
        return nil;
    }
    
    NSDictionary* pathMap = [self.class pathMapForGetStructValue_AKVC];
    
    NSDictionary* currentMap = pathMap[@(self.objCType)];
    
    if(!currentMap) return nil;//wrong path
    
    NSValue*(^worker)(NSValue* value)  = currentMap[key];
    
    return worker(self);
}


- (__kindof NSValue* _Nullable)kpe_structValueForKeyPath:(NSString* _Nonnull)keyPath
{
    NSArray* pathNodes = [keyPath componentsSeparatedByString:@"."];
    
    if(pathNodes.count == 0) {//only key
        
        return nil;
    }
    
    NSDictionary* pathMap = [self.class pathMapForGetStructValue_AKVC];
    NSDictionary* currentMap = pathMap[@(self.objCType)];
    
    if(!currentMap) return nil;//wrong path
    
    NSString* currentPath = pathNodes.firstObject;
    
    NSValue*(^worker)(NSValue* value)  = currentMap[currentPath];
    
    NSValue* newValue = worker(self);
    
    if(pathNodes.count == 1)    return newValue;
    
    NSUInteger dotIdx = [keyPath rangeOfString:@"."].location + 1;
    
    if(dotIdx >= keyPath.length) return nil;///next path wrong
    
    NSString* nextPath = [keyPath substringFromIndex:dotIdx];
    return [newValue kpe_structValueForKeyPath:nextPath];
}

- (NSValue* _Nonnull)setStructValue:(id _Nullable)value forKey:(NSString* _Nonnull)key
{
    if(!key) return self;
    
    NSDictionary* pathMapOfSet = [self.class pathMapForSetStructValue_AKVC];
    NSDictionary* currentMapOfSet = pathMapOfSet[@(self.objCType)];
    if(!currentMapOfSet) return self;
    
    NSValue*(^workerOfSet)(NSValue* _self,id value)  = currentMapOfSet[key];

    return workerOfSet(self,value);
}

- (NSValue* _Nonnull)setStructValue:(id _Nullable)value forKeyPath:(NSString* _Nonnull)keyPath
{
    NSArray* pathNodes = [keyPath componentsSeparatedByString:@"."];
    if(pathNodes.count == 0) return self;
    
    NSString* currentPath = pathNodes.firstObject;
    NSDictionary* pathMapOfGet = [self.class pathMapForGetStructValue_AKVC];
    NSDictionary* currentMapOfGet = pathMapOfGet[@(self.objCType)];
    
    if(!currentMapOfGet) return self;//next path is wrong
    ///worker of get current path value
    NSValue*(^workerOfGet)(NSValue* value)  = currentMapOfGet[currentPath];
    NSValue* currentPathValue = workerOfGet(self);
    
    ///worker of modify value for self
    NSDictionary* pathMapOfSet = [self.class pathMapForSetStructValue_AKVC];
    NSDictionary* currentMapOfSet = pathMapOfSet[@(self.objCType)];
    NSValue*(^workerOfSet)(NSValue* _self,id value)  = currentMapOfSet[currentPath];
    
    NSUInteger dotIdx = [keyPath rangeOfString:@"."].location;
    if(dotIdx == NSNotFound){
        ///It means in the last.
        return workerOfSet(self,value);
    }
    
    ///Need modify struct value,will modify by traversal
    if(dotIdx >= keyPath.length-1) return self;///next path wrong like
    
    NSString* nextPath = [keyPath substringFromIndex:dotIdx + 1];
    NSValue* newValue = [currentPathValue setStructValue:value forKeyPath:nextPath];
    return workerOfSet(self,newValue);
}


+ (void)kpe_registStruct:(NSString*)encode getterMap:(NSDictionary*)getterMap
{
    static dispatch_semaphore_t signalSemaphore;
    static dispatch_once_t onceTokenSemaphore;
    dispatch_once(&onceTokenSemaphore, ^{
        signalSemaphore = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(signalSemaphore, DISPATCH_TIME_FOREVER);
    
    id map = [[self pathMapForGetStructValue_AKVC] mutableCopy];
    map[encode] = getterMap;
    
    _kpe_struct_getmap = [map copy];
    
    dispatch_semaphore_signal(signalSemaphore);
}

+ (void)kpe_registStruct:(NSString*)encode setterMap:(NSDictionary*)setterMap
{
    static dispatch_semaphore_t signalSemaphore;
    static dispatch_once_t onceTokenSemaphore;
    dispatch_once(&onceTokenSemaphore, ^{
        signalSemaphore = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(signalSemaphore, DISPATCH_TIME_FOREVER);
    
    id map = [[self pathMapForSetStructValue_AKVC] mutableCopy];
    map[encode] = setterMap;
    
    _kpe_struct_setmap = [map copy];
    
    dispatch_semaphore_signal(signalSemaphore);
}



static NSDictionary* _kpe_struct_getmap;
+ (NSDictionary*)pathMapForGetStructValue_AKVC
{
    if(!_kpe_struct_getmap){
        
#if TARGET_OS_IPHONE || TARGET_OS_TV
        _kpe_struct_getmap =
        @{
          @(@encode(CGRect))    :   @{
                  @"size":Block_GetStructValueForPath_ReValue(CGRect,size,CGSize),
                  @"origin":Block_GetStructValueForPath_ReValue(CGRect,origin,CGPoint)
                  }
          ,
          @(@encode(CGSize))    :   @{
                  @"width":Block_GetStructValueForPath_ReNumber(CGSize,width,Double),
                  @"height":Block_GetStructValueForPath_ReNumber(CGSize,height,Double)
                  }
          ,
          @(@encode(CGPoint))    :   @{
                  @"x":Block_GetStructValueForPath_ReNumber(CGPoint,x,Double),
                  @"y":Block_GetStructValueForPath_ReNumber(CGPoint,y,Double)
                  }
          ,
          @(@encode(NSRange))    :   @{
                  @"location":Block_GetStructValueForPath_ReNumber(range,location,UnsignedInteger),
                  @"length":Block_GetStructValueForPath_ReNumber(range,length,UnsignedInteger)
                  }
          ,@(@encode(UIEdgeInsets))    :   @{
                  @"top":Block_GetStructValueForPath_ReNumber(UIEdgeInsets,top,Double),
                  @"left":Block_GetStructValueForPath_ReNumber(UIEdgeInsets,left,Double),
                  @"bottom":Block_GetStructValueForPath_ReNumber(UIEdgeInsets,bottom,Double),
                  @"right":Block_GetStructValueForPath_ReNumber(UIEdgeInsets,right,Double),
                  }
          ,@(@encode(UIOffset))    :   @{
                  @"horizontal":Block_GetStructValueForPath_ReNumber(UIOffset,horizontal,Double),
                  @"vertical":Block_GetStructValueForPath_ReNumber(UIOffset,vertical,Double)
                  }
          ,@(@encode(CGVector))    :   @{
                  @"dx":Block_GetStructValueForPath_ReNumber(CGVector,dx,Double),
                  @"dy":Block_GetStructValueForPath_ReNumber(CGVector,dy,Double)
                  }
          ,@(@encode(CATransform3D))    :   @{
                  @"m11":Block_GetStructValueForPath_ReNumber(CATransform3D,m11,Double),
                  @"m12":Block_GetStructValueForPath_ReNumber(CATransform3D,m12,Double),
                  @"m13":Block_GetStructValueForPath_ReNumber(CATransform3D,m13,Double),
                  @"m14":Block_GetStructValueForPath_ReNumber(CATransform3D,m14,Double),
                  @"m21":Block_GetStructValueForPath_ReNumber(CATransform3D,m21,Double),
                  @"m22":Block_GetStructValueForPath_ReNumber(CATransform3D,m22,Double),
                  @"m23":Block_GetStructValueForPath_ReNumber(CATransform3D,m23,Double),
                  @"m24":Block_GetStructValueForPath_ReNumber(CATransform3D,m24,Double),
                  @"m31":Block_GetStructValueForPath_ReNumber(CATransform3D,m31,Double),
                  @"m32":Block_GetStructValueForPath_ReNumber(CATransform3D,m32,Double),
                  @"m33":Block_GetStructValueForPath_ReNumber(CATransform3D,m33,Double),
                  @"m34":Block_GetStructValueForPath_ReNumber(CATransform3D,m34,Double),
                  @"m41":Block_GetStructValueForPath_ReNumber(CATransform3D,m41,Double),
                  @"m42":Block_GetStructValueForPath_ReNumber(CATransform3D,m42,Double),
                  @"m43":Block_GetStructValueForPath_ReNumber(CATransform3D,m43,Double),
                  @"m44":Block_GetStructValueForPath_ReNumber(CATransform3D,m44,Double),
                  }
          ,@(@encode(CGAffineTransform))    :   @{
                  @"a":Block_GetStructValueForPath_ReNumber(CGAffineTransform,a,Double),
                  @"b":Block_GetStructValueForPath_ReNumber(CGAffineTransform,b,Double),
                  @"c":Block_GetStructValueForPath_ReNumber(CGAffineTransform,c,Double),
                  @"d":Block_GetStructValueForPath_ReNumber(CGAffineTransform,d,Double),
                  @"tx":Block_GetStructValueForPath_ReNumber(CGAffineTransform,tx,Double),
                  @"ty":Block_GetStructValueForPath_ReNumber(CGAffineTransform,ty,Double),
                  }
          };
        
        if (@available(iOS 11.0, *)) {
            
            NSMutableDictionary* map = _kpe_struct_getmap.mutableCopy;
            map[@(@encode(NSDirectionalEdgeInsets))] =
            @{
              @"top"     :Block_GetStructValueForPath_ReNumber(directionalEdgeInsets,top,Double),
              @"leading" :Block_GetStructValueForPath_ReNumber(directionalEdgeInsets,leading,Double),
              @"bottom"  :Block_GetStructValueForPath_ReNumber(directionalEdgeInsets,bottom,Double),
              @"trailing":Block_GetStructValueForPath_ReNumber(directionalEdgeInsets,trailing,Double),
              };
            _kpe_struct_getmap = map.copy;
        }
        
#elif TARGET_OS_MAC
        _kpe_struct_getmap =
        @{
          @(@encode(NSRect))   :   @{
                  @"size":^(NSValue* value){
                      return [NSValue valueWithSize:[value rectValue].size];
                  } ,
                  @"origin":^(NSValue* value){
                      return [NSValue valueWithPoint:[value rectValue].origin];
                  }
                  }
          ,
          @(@encode(NSPoint))   :   @{
                  @"x":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value pointValue].x];
                  } ,
                  @"y":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value pointValue].y];
                  }
                  }
          ,
          @(@encode(NSSize))   :   @{
                  @"width":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value sizeValue].width];
                  } ,
                  @"height":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value sizeValue].height];
                  }
                  }
          ,
          @(@encode(NSRange))   :   @{
                  @"location":^(NSValue* value){
                      return [NSNumber numberWithUnsignedInteger:[value rangeValue].location];
                  } ,
                  @"length":^(NSValue* value){
                      return [NSNumber numberWithUnsignedInteger:[value rangeValue].length];
                  }
                  }
          ,
          @(@encode(NSEdgeInsets))   :   @{
                  @"top":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value edgeInsetsValue].top];
                  } ,
                  @"left":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value edgeInsetsValue].left];
                  } ,
                  @"bottom":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value edgeInsetsValue].bottom];
                  } ,
                  @"right":^(NSValue* value){
                      return [NSNumber numberWithDouble:[value edgeInsetsValue].right];
                  }
                  }
          ,@(@encode(CATransform3D))    :   @{
                  @"m11":Block_GetStructValueForPath_ReNumber(CATransform3D,m11,Double),
                  @"m12":Block_GetStructValueForPath_ReNumber(CATransform3D,m12,Double),
                  @"m13":Block_GetStructValueForPath_ReNumber(CATransform3D,m13,Double),
                  @"m14":Block_GetStructValueForPath_ReNumber(CATransform3D,m14,Double),
                  @"m21":Block_GetStructValueForPath_ReNumber(CATransform3D,m21,Double),
                  @"m22":Block_GetStructValueForPath_ReNumber(CATransform3D,m22,Double),
                  @"m23":Block_GetStructValueForPath_ReNumber(CATransform3D,m23,Double),
                  @"m24":Block_GetStructValueForPath_ReNumber(CATransform3D,m24,Double),
                  @"m31":Block_GetStructValueForPath_ReNumber(CATransform3D,m31,Double),
                  @"m32":Block_GetStructValueForPath_ReNumber(CATransform3D,m32,Double),
                  @"m33":Block_GetStructValueForPath_ReNumber(CATransform3D,m33,Double),
                  @"m34":Block_GetStructValueForPath_ReNumber(CATransform3D,m34,Double),
                  @"m41":Block_GetStructValueForPath_ReNumber(CATransform3D,m41,Double),
                  @"m42":Block_GetStructValueForPath_ReNumber(CATransform3D,m42,Double),
                  @"m43":Block_GetStructValueForPath_ReNumber(CATransform3D,m43,Double),
                  @"m44":Block_GetStructValueForPath_ReNumber(CATransform3D,m44,Double),
                  }
          
          };
#endif
    }
    return _kpe_struct_getmap;
}

static NSDictionary* _kpe_struct_setmap;
+ (NSDictionary*)pathMapForSetStructValue_AKVC
{
    if(!_kpe_struct_setmap){
        
#if TARGET_OS_IPHONE || TARGET_OS_TV
        
        _kpe_struct_setmap =
        @{
          @(@encode(CGRect))    :   @{
                  @"size":Block_SetStructValueForPath(CGRect,size,CGSize),
                  @"origin":Block_SetStructValueForPath(CGRect,origin,CGPoint)
                  },
          @(@encode(CGSize))    :   @{
                  @"width":Block_SetStructValueForPath(CGSize,width,unsignedInteger),
                  @"height":Block_SetStructValueForPath(CGSize,height,unsignedInteger)
                  },
          @(@encode(CGPoint))    :   @{
                  @"x":Block_SetStructValueForPath(CGPoint,x,double),
                  @"y":Block_SetStructValueForPath(CGPoint,y,double)
                  },
          @(@encode(NSRange))    :   @{
                  @"location":^(NSValue* _self,id value){
                      NSRange identify = [_self rangeValue];
                      identify.location = [value unsignedIntegerValue];
                      return [NSValue valueWithRange:identify];
                  },
                  @"length":^(NSValue* _self,id value){
                      NSRange identify = [_self rangeValue];
                      identify.length = [value unsignedIntegerValue];
                      return [NSValue valueWithRange:identify];
                  }
                  },
          @(@encode(UIEdgeInsets))    :   @{
                  @"top":Block_SetStructValueForPath(UIEdgeInsets,top,double),
                  @"left":Block_SetStructValueForPath(UIEdgeInsets,left,double),
                  @"bottom":Block_SetStructValueForPath(UIEdgeInsets,bottom,double),
                  @"right":Block_SetStructValueForPath(UIEdgeInsets,right,double),
                  },
          @(@encode(UIOffset))    :   @{
                  @"horizontal":Block_SetStructValueForPath(UIOffset,horizontal,double),
                  @"vertical":Block_SetStructValueForPath(UIOffset,vertical,double),
                  },
          @(@encode(CGVector))    :   @{
                  @"dx":Block_SetStructValueForPath(CGVector,dx,double),
                  @"dy":Block_SetStructValueForPath(CGVector,dy,double),
                  },
          @(@encode(CATransform3D))    :   @{
                  @"m11":Block_SetStructValueForPath(CATransform3D,m11,double),
                  @"m12":Block_SetStructValueForPath(CATransform3D,m12,double),
                  @"m13":Block_SetStructValueForPath(CATransform3D,m13,double),
                  @"m14":Block_SetStructValueForPath(CATransform3D,m14,double),
                  @"m21":Block_SetStructValueForPath(CATransform3D,m21,double),
                  @"m22":Block_SetStructValueForPath(CATransform3D,m22,double),
                  @"m23":Block_SetStructValueForPath(CATransform3D,m23,double),
                  @"m24":Block_SetStructValueForPath(CATransform3D,m24,double),
                  @"m31":Block_SetStructValueForPath(CATransform3D,m31,double),
                  @"m32":Block_SetStructValueForPath(CATransform3D,m32,double),
                  @"m33":Block_SetStructValueForPath(CATransform3D,m33,double),
                  @"m34":Block_SetStructValueForPath(CATransform3D,m34,double),
                  @"m41":Block_SetStructValueForPath(CATransform3D,m41,double),
                  @"m42":Block_SetStructValueForPath(CATransform3D,m42,double),
                  @"m43":Block_SetStructValueForPath(CATransform3D,m43,double),
                  @"m44":Block_SetStructValueForPath(CATransform3D,m44,double),
                  },
          @(@encode(CGAffineTransform))    :   @{
                  @"a":Block_SetStructValueForPath(CGAffineTransform,a,double),
                  @"b":Block_SetStructValueForPath(CGAffineTransform,b,double),
                  @"c":Block_SetStructValueForPath(CGAffineTransform,c,double),
                  @"d":Block_SetStructValueForPath(CGAffineTransform,d,double),
                  @"tx":Block_SetStructValueForPath(CGAffineTransform,tx,double),
                  @"ty":Block_SetStructValueForPath(CGAffineTransform,ty,double),
                  },
          };
        
        if (@available(iOS 11.0, *)) {
            
            NSMutableDictionary* map = _kpe_struct_setmap.mutableCopy;
            map[@(@encode(NSDirectionalEdgeInsets))] =
            @{
              @"top":^(NSValue* _self,id value){
                  NSDirectionalEdgeInsets identify = [_self directionalEdgeInsetsValue];
                  identify.top = [value doubleValue];
                  return [NSValue valueWithDirectionalEdgeInsets:identify];
              },
              @"leading":^(NSValue* _self,id value){
                  NSDirectionalEdgeInsets identify = [_self directionalEdgeInsetsValue];
                  identify.leading = [value doubleValue];
                  return [NSValue valueWithDirectionalEdgeInsets:identify];
              },
              @"bottom":^(NSValue* _self,id value){
                  NSDirectionalEdgeInsets identify = [_self directionalEdgeInsetsValue];
                  identify.bottom = [value doubleValue];
                  return [NSValue valueWithDirectionalEdgeInsets:identify];
              },
              @"trailing":^(NSValue* _self,id value){
                  NSDirectionalEdgeInsets identify = [_self directionalEdgeInsetsValue];
                  identify.trailing = [value doubleValue];
                  return [NSValue valueWithDirectionalEdgeInsets:identify];
              },
              };
            _kpe_struct_setmap = map.copy;
        }
        
#elif TARGET_OS_MAC
        
        _kpe_struct_setmap =
        @{
          @(@encode(NSRect))   :   @{
                  @"size":^(NSValue* value, NSValue* newValue){
                      
                      NSRect aValue = [value rectValue];
                      aValue.size = [newValue sizeValue];
                      return [NSValue valueWithRect:aValue];
                  } ,
                  @"origin":^(NSValue* value, NSValue* newValue){
                      
                      NSRect aValue = [value rectValue];
                      aValue.origin = [newValue pointValue];
                      return [NSValue valueWithRect:aValue];
                  }
                  }
          ,
          @(@encode(NSPoint))   :   @{
                  @"x":^(NSValue* value, NSNumber* newValue){
                      
                      NSPoint aValue = [value pointValue];
                      aValue.x = [newValue doubleValue];
                      return [NSValue valueWithPoint:aValue];
                  } ,
                  @"y":^(NSValue* value, NSNumber* newValue){
                      
                      NSPoint aValue = [value pointValue];
                      aValue.y = [newValue doubleValue];
                      return [NSValue valueWithPoint:aValue];
                  }
                  }
          ,
          @(@encode(NSSize))   :   @{
                  @"width":^(NSValue* value, NSNumber* newValue){
                      
                      NSSize aValue = [value sizeValue];
                      aValue.width = [newValue doubleValue];
                      return [NSValue valueWithSize:aValue];
                  } ,
                  @"height":^(NSValue* value, NSNumber* newValue){
                      
                      NSSize aValue = [value sizeValue];
                      aValue.height = [newValue doubleValue];
                      return [NSValue valueWithSize:aValue];
                  }
                  }
          ,
          @(@encode(NSRange))   :   @{
                  @"location":^(NSValue* value, NSNumber* newValue){
                      
                      NSRange aValue = [value rangeValue];
                      aValue.location = [newValue doubleValue];
                      return [NSValue valueWithRange:aValue];
                  } ,
                  @"length":^(NSValue* value, NSNumber* newValue){
                      
                      NSRange aValue = [value rangeValue];
                      aValue.length = [newValue doubleValue];
                      return [NSValue valueWithRange:aValue];
                  }
                  }
          ,
          @(@encode(NSEdgeInsets))   :   @{
                  @"top":^(NSValue* value, NSNumber* newValue){
                      
                      NSEdgeInsets aValue = [value edgeInsetsValue];
                      aValue.top = [newValue doubleValue];
                      return [NSValue valueWithEdgeInsets:aValue];
                  } ,
                  @"left":^(NSValue* value, NSNumber* newValue){
                      
                      NSEdgeInsets aValue = [value edgeInsetsValue];
                      aValue.left = [newValue doubleValue];
                      return [NSValue valueWithEdgeInsets:aValue];
                  } ,
                  @"bottom":^(NSValue* value, NSNumber* newValue){
                      
                      NSEdgeInsets aValue = [value edgeInsetsValue];
                      aValue.bottom = [newValue doubleValue];
                      return [NSValue valueWithEdgeInsets:aValue];
                  } ,
                  @"right":^(NSValue* value, NSNumber* newValue){
                      
                      NSEdgeInsets aValue = [value edgeInsetsValue];
                      aValue.right = [newValue doubleValue];
                      return [NSValue valueWithEdgeInsets:aValue];
                  }
                  }
          ,
          @(@encode(CATransform3D))    :   @{
                  @"m11":Block_SetStructValueForPath(CATransform3D,m11,double),
                  @"m12":Block_SetStructValueForPath(CATransform3D,m12,double),
                  @"m13":Block_SetStructValueForPath(CATransform3D,m13,double),
                  @"m14":Block_SetStructValueForPath(CATransform3D,m14,double),
                  @"m21":Block_SetStructValueForPath(CATransform3D,m21,double),
                  @"m22":Block_SetStructValueForPath(CATransform3D,m22,double),
                  @"m23":Block_SetStructValueForPath(CATransform3D,m23,double),
                  @"m24":Block_SetStructValueForPath(CATransform3D,m24,double),
                  @"m31":Block_SetStructValueForPath(CATransform3D,m31,double),
                  @"m32":Block_SetStructValueForPath(CATransform3D,m32,double),
                  @"m33":Block_SetStructValueForPath(CATransform3D,m33,double),
                  @"m34":Block_SetStructValueForPath(CATransform3D,m34,double),
                  @"m41":Block_SetStructValueForPath(CATransform3D,m41,double),
                  @"m42":Block_SetStructValueForPath(CATransform3D,m42,double),
                  @"m43":Block_SetStructValueForPath(CATransform3D,m43,double),
                  @"m44":Block_SetStructValueForPath(CATransform3D,m44,double),
                  }
          };
        
#endif
    }
    return _kpe_struct_setmap;
}
@end

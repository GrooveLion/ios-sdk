//
//  GLDMessageList.h
//  demo
//
//  Created by Philip Willoughby on 03/07/2014.
//  Copyright (c) 2014 Groove Lion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLDMessageList : NSObject

@property(readonly,nonatomic,assign)NSUInteger messageCount;
-(NSDictionary *)messageAtIndex:(NSUInteger)index;

+(instancetype)sharedMessageList;

-(void)addMessage:(NSDictionary *)message;
@end

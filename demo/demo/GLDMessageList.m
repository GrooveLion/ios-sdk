//
//  GLDMessageList.m
//  demo
//
//  Created by Philip Willoughby on 03/07/2014.
//  Copyright (c) 2014 Groove Lion. All rights reserved.
//

#import "GLDMessageList.h"

@implementation GLDMessageList
{
    NSMutableArray *messages;
}

+(instancetype)sharedMessageList
{
    static GLDMessageList *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        shared = [[self alloc] init];
    });
    return shared;
}

-(id)init
{
    self = [super init];
    if (!self)
        return nil;
    messages = [[NSMutableArray alloc] init];
    return self;
}

-(void)addMessage:(NSDictionary *)message
{
    NSLog(@"Received\n%@",message);
    [self willChangeValueForKey:@"messageCount"];
    [messages addObject:message];
    [self didChangeValueForKey:@"messageCount"];
}

-(NSDictionary *)messageAtIndex:(NSUInteger)index
{
    return messages[index];
}

-(NSUInteger)messageCount
{
    return messages.count;
}
@end

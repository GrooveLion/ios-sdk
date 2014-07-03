#import "GLEInternals.h"

@interface GLETagStateCommand : NSObject

-(void)applyToSegmentSubscriptions:(NSMutableArray *)segmentSubscriptions;

@end

@interface GLETagStateCommandAddTagToSegment : GLETagStateCommand

-(id)initWithTag:(NSString *)tag inSegment:(NSString *)segment;

@end

@interface GLETagStateCommandRemoveTagFromSegment : GLETagStateCommand

-(id)initWithTag:(NSString *)tag inSegment:(NSString *)segment;

@end

@interface GLETagStateCommandSetSingleTagForSegment : GLETagStateCommand

-(id)initWithTag:(NSString *)tag inSegment:(NSString *)segment;

@end

@interface GLETagStateCommandSetSegmentSubscription : GLETagStateCommand

-(id)initWithSegmentSubscription:(GLESegment *)segmentSubscription;

@end

@interface GLETagStateCommandSetSegmentSubscriptions : GLETagStateCommand

-(id)initWithSegmentSubscriptions:(NSArray *)segmentSubscriptions;

@end

@implementation GLESegmentTransaction
{
    GLECentral *pushSDKObject;
    NSMutableArray *tagStateCommands;
}

-(instancetype)initWithGLECentral:(GLECentral *)_push
{
    if (!_push)
        return nil;
    self = [super init];
    if (self)
    {
        pushSDKObject = _push;
        tagStateCommands = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"You must use the designated initializer -initWithGLECentralObject: and not -init"
                                 userInfo:nil];
}

-(void)commitChanges
{
    if (tagStateCommands.count < 1)
        return;
    @synchronized(pushSDKObject)
    {
        NSMutableArray *segmentSubscriptions = [[pushSDKObject segmentSubscriptions] mutableCopy];
        for (GLETagStateCommand *command in tagStateCommands)
            [command applyToSegmentSubscriptions:segmentSubscriptions];
        [tagStateCommands removeAllObjects];
        [pushSDKObject setSegmentSubscriptions:segmentSubscriptions];
    }
}

-(void)discardChanges
{
    [tagStateCommands removeAllObjects];
}

#pragma mark - NAP wanted these methods

- (void)addTag:(NSString *)tag toSegment:(NSString *)segmentName
{
    [tagStateCommands addObject:[[GLETagStateCommandAddTagToSegment alloc] initWithTag:tag inSegment:segmentName]];
}

- (void)removeTag:(NSString *)tag fromSegment:(NSString *)segmentName
{
    [tagStateCommands addObject:[[GLETagStateCommandRemoveTagFromSegment alloc] initWithTag:tag inSegment:segmentName]];
}

- (void)setSingleTag:(NSString *)tag forSegment:(NSString *)segmentName
{
    [tagStateCommands addObject:[[GLETagStateCommandSetSingleTagForSegment alloc] initWithTag:tag inSegment:segmentName]];
}

#pragma mark - Shadow of GLECentral methods - setters

-(void)setSegmentSubscription:(GLESegment *)newSegment
{
    [tagStateCommands addObject:[[GLETagStateCommandSetSegmentSubscription alloc] initWithSegmentSubscription:newSegment]];
}

-(void)setSegmentSubscriptions:(NSArray *)segments
{
    [tagStateCommands addObject:[[GLETagStateCommandSetSegmentSubscriptions alloc] initWithSegmentSubscriptions:segments]];
}

#pragma mark - Shadow of GLECentral methods - getters

-(GLESegment *)segmentSubscriptionForName:(NSString *)segmentName
{
    NSMutableArray *segmentSubscriptions = [[pushSDKObject segmentSubscriptions] mutableCopy];
    for (GLETagStateCommand *command in tagStateCommands)
        [command applyToSegmentSubscriptions:segmentSubscriptions];
    GLESegment __block *segment = nil;
    [segmentSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         GLESegment *candidate = obj;
         if ([candidate.name isEqualToString:segmentName])
         {
             segment = candidate;
             *stop = YES;
         }
     }];
    if (!segment)
        segment = [[GLESegment alloc] initWithName:segmentName tags:@[]];
    return segment;
}

-(NSArray *)segmentSubscriptions
{
    NSMutableArray *segmentSubscriptions = [[pushSDKObject segmentSubscriptions] mutableCopy];
    for (GLETagStateCommand *command in tagStateCommands)
        [command applyToSegmentSubscriptions:segmentSubscriptions];
    return [segmentSubscriptions copy];
}

@end

@implementation GLETagStateCommandAddTagToSegment
{
    NSString *tag, *segmentName;
}

-(id)initWithTag:(NSString *)_tag inSegment:(NSString *)_segment
{
    self = [super init];
    if (self)
    {
        tag = _tag;
        segmentName = _segment;
    }
    return self;
}

-(void)applyToSegmentSubscriptions:(NSMutableArray *)segmentSubscriptions
{
    GLESegment __block *segment = nil;
    [segmentSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         GLESegment *candidate = obj;
         if ([candidate.name isEqualToString:segmentName])
         {
             segment = candidate;
             *stop = YES;
         }
     }];
    
    if (!segment)
    {
        [segmentSubscriptions addObject:[[GLESegment alloc] initWithName:segmentName
                                                                    tags:@[ tag ]]];
        return;
    }
    
    NSArray *tags = segment.tags;
    if ([tags containsObject:tag])
        return;
    
    [segmentSubscriptions removeObject:segment];
    [segmentSubscriptions addObject:[[GLESegment alloc] initWithName:segmentName
                                                                tags:[tags arrayByAddingObject:tag]]];
}

@end

@implementation GLETagStateCommandRemoveTagFromSegment
{
    NSString *tag, *segmentName;
}

-(id)initWithTag:(NSString *)_tag inSegment:(NSString *)_segment
{
    self = [super init];
    if (self)
    {
        tag = _tag;
        segmentName = _segment;
    }
    return self;
}

-(void)applyToSegmentSubscriptions:(NSMutableArray *)segmentSubscriptions
{
    GLESegment __block *segment = nil;
    [segmentSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         GLESegment *candidate = obj;
         if ([candidate.name isEqualToString:segmentName])
         {
             segment = candidate;
             *stop = YES;
         }
     }];
    
    if (!segment)
        return;
    
    NSArray *tags = segment.tags;
    NSUInteger tagIndex = [tags indexOfObject:tag];
    if (tagIndex == NSNotFound)
        return;
    
    NSMutableArray *newTags = [tags mutableCopy];
    do
        [newTags removeObjectAtIndex:tagIndex];
    while ((tagIndex = [newTags indexOfObject:tag]) != NSNotFound);
    
    [segmentSubscriptions removeObject:segment];
    
    if (newTags.count)
        [segmentSubscriptions addObject:[[GLESegment alloc] initWithName:segmentName
                                                                    tags:newTags]];
}

@end

@implementation GLETagStateCommandSetSingleTagForSegment
{
    NSString *tag, *segmentName;
}

-(id)initWithTag:(NSString *)_tag inSegment:(NSString *)_segment
{
    self = [super init];
    if (self)
    {
        tag = _tag;
        segmentName = _segment;
    }
    return self;
}

-(void)applyToSegmentSubscriptions:(NSMutableArray *)segmentSubscriptions
{
    NSUInteger __block segmentIndex = NSNotFound;
    [segmentSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         GLESegment *candidate = obj;
         if ([candidate.name isEqualToString:segmentName])
         {
             segmentIndex = idx;
             *stop = YES;
         }
     }];
    
    if (segmentIndex != NSNotFound)
        [segmentSubscriptions removeObjectAtIndex:segmentIndex];
    [segmentSubscriptions addObject:[[GLESegment alloc] initWithName:segmentName
                                                                tags:@[ tag ]]];
}

@end

@implementation GLETagStateCommandSetSegmentSubscription
{
    GLESegment *newSegment;
}

-(id)initWithSegmentSubscription:(GLESegment *)segmentSubscription
{
    self = [super init];
    if (self)
    {
        newSegment = segmentSubscription;
    }
    return self;
}

-(void)applyToSegmentSubscriptions:(NSMutableArray *)segmentSubscriptions
{
    GLESegment __block *segment = nil;
    [segmentSubscriptions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         GLESegment *candidate = obj;
         if ([candidate.name isEqualToString:newSegment.name])
         {
             segment = candidate;
             *stop = YES;
         }
     }];
    if (segment)
        [segmentSubscriptions removeObject:segment];
    if (newSegment.tags.count)
        [segmentSubscriptions addObject:[newSegment copy]];
}

@end

@implementation GLETagStateCommandSetSegmentSubscriptions
{
    NSArray *newSubscriptions;
}

-(id)initWithSegmentSubscriptions:(NSArray *)segmentSubscriptions
{
    self = [super init];
    if (self)
    {
        newSubscriptions = [segmentSubscriptions copy];
    }
    return self;
}

-(void)applyToSegmentSubscriptions:(NSMutableArray *)segmentSubscriptions
{
    [segmentSubscriptions removeAllObjects];
    [segmentSubscriptions addObjectsFromArray:newSubscriptions];
}
@end

@implementation GLETagStateCommand

-(void)applyToSegmentSubscriptions:(NSMutableArray *)segmentSubscriptions
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Abstract method invoked" userInfo:@{}];
}

@end
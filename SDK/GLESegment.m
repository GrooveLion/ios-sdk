#import "GLEInternals.h"

@implementation GLESegment
{
@protected
    NSString *name;
    NSArray *tags;
}

-(NSString *)name
{
    return name;
}

-(NSArray *)tags
{
    return tags;
}

-(NSDictionary *)dictionaryRepresentation
{
    if (name.length && tags.count)
        return @{@"name":name, @"tags": tags };
    return nil;
}

-(instancetype)initWithDictionaryRepresentation:(NSDictionary *)representation
{
    return [self initWithName:representation[@"name"] tags:representation[@"tags"]];
}

-(instancetype)initWithName:(NSString *)_name tags:(NSArray *)_tags
{
    if (_name.length < 1)
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Segment names of zero length are not permitted"
                                     userInfo:nil];
    if ([_name characterAtIndex:0] == '_')
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Segment names beginning _ (underscore) are reserved"
                                     userInfo:nil];
    self = [super init];
    if (self)
    {
        name = [_name copy];
        tags = [_tags copy];
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    return [[GLESegment allocWithZone:zone] initWithName:name tags:tags];
}

-(id)mutableCopyWithZone:(NSZone *)zone
{
    return [[GLEMutableSegment allocWithZone:zone] initWithName:name tags:tags];
}

@end

@implementation GLEMutableSegment

-(void)setName:(NSString *)_name
{
    if (name.length < 1)
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Segment names of zero length are not permitted"
                                     userInfo:nil];
    if ([name characterAtIndex:0] == '_')
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Segment names beginning _ (underscore) are reserved"
                                     userInfo:nil];
    name = [_name copy];
}

-(void)setTags:(NSArray *)_tags
{
    tags = [_tags copy];
}

@end

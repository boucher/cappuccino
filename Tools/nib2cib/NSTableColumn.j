
@import <AppKit/CPTableColumn.j>

@implementation CPTableColumn (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [self init];
    
    if (self)
    {
        _identifier = [aCoder decodeObjectForKey:@"NSIdentifier"];
        
        //_headerView = [aCoder decodeObjectForKey:@"NSHeaderCell"];
        //_dataView = [aCoder decodeObjectForKey:@"NSDataCell"];
        
        _width = [aCoder decodeFloatForKey:@"NSWidth"];
        _minWidth = [aCoder decodeFloatForKey:@"NSMinWidth"];
        _maxWidth = [aCoder decodeFloatForKey:@"NSMaxWidth"];
        
        _resizingMask  = [aCoder decodeBoolForKey:@"NSIsResizable"];
    }
    
    return self;
}

@end

@implementation NSTableColumn : CPTableColumn
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTableColumn class];
}


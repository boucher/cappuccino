
@import <AppKit/CPTableView.j>

@implementation CPTableView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        var flags = [aCoder decodeIntForKey:@"NSTvFlags"];
        
        //_dataSource = [aCoder decodeObjectForKey:CPTableViewDataSourceKey];
        //_delegate = [aCoder decodeObjectForKey:CPTableViewDelegateKey];
        
        _headerView = [aCoder decodeObjectForKey:@"NSHeaderView"];
        [_headerView setTableView:self];
    
        _tableColumns = [aCoder decodeObjectForKey:@"NSTableColumns"];
        [_tableColumns makeObjectsPerformSelector:@selector(setTableView:) withObject:self];

        _rowHeight = [aCoder decodeFloatForKey:@"NSRowHeight"];
        _intercellSpacing = CGSizeMake([aCoder decodeFloatForKey:@"NSIntercellSpacingWidth"], [aCoder decodeFloatForKey:@"NSIntercellSpacingHeight"]);
        
        _allowsMultipleSelection = (flags & 0x08000000) ? YES : NO;
        _allowsEmptySelection = (flags & 0x10000000) ? YES : NO;
    }
    
    return self;
}

@end

@implementation NSTableView : CPTableView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTableView class];
}


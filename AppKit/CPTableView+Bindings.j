
@import "CPKeyValueBinding.j"
@import "CPTableView.j"

@implementation CPTableViewKeyValueBinding : CPKeyValueBinding
{
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [[[_info objectForKey:CPObservedObjectKey] valueForKeyPath:[_info objectForKey:CPObservedKeyPathKey]] count];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    [super observeValueForKeyPath:aKeyPath ofObject:anObject change:changes context:context];
    [_source reloadData];
}

@end

@implementation CPTableView (Bindings)

+ (CPSet)keyPathsForValuesAffectingValueForSelectionIndexes
{
    return [CPSet setWithObject:"selectedRowIndexes"];
}

+ (Class)classForBinding:(CPString)aBinding
{
    if ([aBinding isEqual:"content"])
        return CPTableViewKeyValueBinding;

    return [[super class] classForBinding:aBinding];
}

- (void)_establishBindingsWithDestination:(id)destination
{
    if (![self infoForBinding:"content"])
    {
        [self bind:@"content" toObject:destination withKeyPath:@"arrangedObjects" options:nil];
        [self bind:@"sortDescriptors" toObject:destination withKeyPath:@"sortDescriptors" options:nil];
        [self bind:@"selectionIndexes" toObject:destination withKeyPath:@"selectionIndexes" options:nil];
        alert("did bind");
    }

    [self reloadData];
}

@end

@implementation CPTableColumn (Bindings)

- (void)bind:(CPString)binding toObject:(id)anObject withKeyPath:(CPString)keyPath options:(CPDictionary)options
{
    if ([binding isEqual:CPValueBinding])
        [[self tableView] _establishBindingsWithDestination:anObject];

    [super bind:binding toObject:anObject withKeyPath:keyPath options:options];
}

- (void)prepareDataView:(id)dataView inRow:(int)aRow
{
    var binding = [CPKeyValueBinding getBinding:CPValueBinding forObject:self];

    if (!binding)
        return;

    var keyPath = [binding._info objectForKey:CPObservedKeyPathKey],
        destination = [binding._info objectForKey:CPObservedObjectKey],
        dotIndex = keyPath.indexOf("."),
        firstKey = dotIndex === CPNotFound ? "arrangedObjects" : keyPath.substring(0, dotIndex),
        secondKey = dotIndex === CPNotFound ? keyPath : keyPath.substring(dotIndex+1);
    //alert(dataView+" "+keyPath+" "+destination+" "+firstKey+" "+secondKey+" "+[destination valueForKeyPath:firstKey]+" "+[[destination valueForKeyPath:firstKey] objectAtIndex:aRow]+" "+[[[destination valueForKeyPath:firstKey] objectAtIndex:aRow] valueForKeyPath:secondKey]);
    [dataView setObjectValue:[[[destination valueForKeyPath:firstKey] objectAtIndex:aRow] valueForKeyPath:secondKey]];
}

@end
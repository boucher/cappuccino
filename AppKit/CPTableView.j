/*
 * CPTableView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPArray.j>

@import "CPControl.j"
@import "CPTableColumn.j"
@import "_CPCornerView.j"
@import "CPScroller.j"


CPTableViewColumnDidMoveNotification        = @"CPTableViewColumnDidMoveNotification";
CPTableViewColumnDidResizeNotification      = @"CPTableViewColumnDidResizeNotification";
CPTableViewSelectionDidChangeNotification   = @"CPTableViewSelectionDidChangeNotification";
CPTableViewSelectionIsChangingNotification  = @"CPTableViewSelectionIsChangingNotification";

#include "CoreGraphics/CGGeometry.h"

var CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_                                  = 1 << 2,

    CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_                                       = 1 << 3,
    CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_ = 1 << 4,
    CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_                     = 1 << 5,
    CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_                                  = 1 << 6,

    CPTableViewDataSource_tableView_sortDescriptorsDidChange_                                           = 1 << 7;

var CPTableViewDelegate_selectionShouldChangeInTableView_                                               = 1 << 0,
    CPTableViewDelegate_tableView_dataViewForTableColumn_row_                                           = 1 << 1,
    CPTableViewDelegate_tableView_didClickTableColumn_                                                  = 1 << 2,
    CPTableViewDelegate_tableView_didDragTableColumn_                                                   = 1 << 3,
    CPTableViewDelegate_tableView_heightOfRow_                                                          = 1 << 4,
    CPTableViewDelegate_tableView_isGroupRow_                                                           = 1 << 5,
    CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_                                       = 1 << 6,
    CPTableViewDelegate_tableView_nextTypeSelectMatchFromRow_toRow_forString_                           = 1 << 7,
    CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_                                 = 1 << 8,
    CPTableViewDelegate_tableView_shouldEditTableColumn_row_                                            = 1 << 9,
    CPTableViewDelegate_tableView_shouldSelectRow_                                                      = 1 << 10,
    CPTableViewDelegate_tableView_shouldSelectTableColumn_                                              = 1 << 11,
    CPTableViewDelegate_tableView_shouldShowViewExpansionForTableColumn_row_                            = 1 << 12,
    CPTableViewDelegate_tableView_shouldTrackView_forTableColumn_row_                                   = 1 << 13,
    CPTableViewDelegate_tableView_shouldTypeSelectForEvent_withCurrentSearchString_                     = 1 << 14,
    CPTableViewDelegate_tableView_toolTipForView_rect_tableColumn_row_mouseLocation_                    = 1 << 15,
    CPTableViewDelegate_tableView_typeSelectStringForTableColumn_row_                                   = 1 << 16,
    CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_                                   = 1 << 17,
    CPTableViewDelegate_tableViewSelectionDidChange_                                                    = 1 << 18,
    CPTableViewDelegate_tableViewSelectionIsChanging_                                                   = 1 << 19;

//CPTableViewDraggingDestinationFeedbackStyles
CPTableViewDraggingDestinationFeedbackStyleNone = -1,
CPTableViewDraggingDestinationFeedbackStyleRegular = 0,
CPTableViewDraggingDestinationFeedbackStyleSourceList = 1;

//CPTableViewDropOperations
CPTableViewDropOn = 0,
CPTableViewDropAbove = 1;

// TODO: add docs

CPTableViewSelectionHighlightStyleNone = -1,
CPTableViewSelectionHighlightStyleRegular = 0,
CPTableViewSelectionHighlightStyleSourceList = 1;

CPTableViewGridNone                    = 0;
CPTableViewSolidVerticalGridLineMask   = 1 << 0;
CPTableViewSolidHorizontalGridLineMask = 1 << 1;

CPTableViewNoColumnAutoresizing = 0,
CPTableViewUniformColumnAutoresizingStyle = 1,
CPTableViewSequentialColumnAutoresizingStyle = 2,
CPTableViewReverseSequentialColumnAutoresizingStyle = 3,
CPTableViewLastColumnOnlyAutoresizingStyle = 4,
CPTableViewFirstColumnOnlyAutoresizingStyle = 5;


#define NUMBER_OF_COLUMNS() (_tableColumns.length)
#define UPDATE_COLUMN_RANGES_IF_NECESSARY() if (_dirtyTableColumnRangeIndex !== CPNotFound) [self _recalculateTableColumnRanges];

@implementation _CPTableDrawView : CPView
{
    CPTableView _tableView;
}

- (id)initWithTableView:(CPTableView)aTableView
{
    self = [super init];

    if (self)
        _tableView = aTableView;

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var frame = [self frame],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextTranslateCTM(context, -_CGRectGetMinX(frame), -_CGRectGetMinY(frame));

    [_tableView _drawRect:aRect];
}

@end

@implementation CPTableView : CPControl
{
    id          _dataSource;
    CPInteger   _implementedDataSourceMethods;

    id          _delegate;
    CPInteger   _implementedDelegateMethods;

    CPArray     _tableColumns;
    CPArray     _tableColumnRanges;
    CPInteger   _dirtyTableColumnRangeIndex;
    CPInteger   _numberOfHiddenColumns;

    BOOL        _reloadAllRows;
    Object      _objectValues;
    CPIndexSet  _exposedRows;
    CPIndexSet  _exposedColumns;

    Object      _dataViewsForTableColumns;
    Object      _cachedDataViews;

    //Configuring Behavior
    BOOL        _allowsColumnReordering;
    BOOL        _allowsColumnResizing;
    BOOL        _allowsMultipleSelection;
    BOOL        _allowsEmptySelection;

    //Setting Display Attributes
    CGSize      _intercellSpacing;
    float       _rowHeight;

    BOOL        _usesAlternatingRowBackgroundColors;
    CPArray     _alternatingRowBackgroundColors;

    unsigned    _selectionHighlightMask;
    CPColor     _selectionHightlightColor;
    unsigned    _currentHighlightedTableColumn;
    unsigned    _gridStyleMask;
    CPColor     _gridColor;

    unsigned    _numberOfRows;


    CPTableHeaderView _headerView;
    _CPCornerView     _cornerView;

    CPIndexSet  _selectedColumnIndexes;
    CPIndexSet  _selectedRowIndexes;
    CPInteger   _selectionAnchorRow;
    CPIndexSet  _previouslySelectedRowIndexes;
    CGPoint     _startTrackingPoint;
    CPDate      _startTrackingTimestamp;
    BOOL        _trackingPointMovedOutOfClickSlop;
    CGPoint     _editingCellIndex;

    _CPTableDrawView _tableDrawView;

    SEL         _doubleAction;
    unsigned    _columnAutoResizingStyle;

//    BOOL        _verticalMotionCanDrag;
//    unsigned    _destinationDragStyle;
//    BOOL        _isSelectingSession;
//    CPIndexSet  _draggedRowIndexes;
//    _dropOperationDrawingView _dropOperationFeedbackView;
//    CPDragOperation _dragOperationDefaultMask;
//    int         _retargetedDropRow;
//    CPDragOperation _retargetedDropOperation;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        //Configuring Behavior
        _allowsColumnReordering = YES;
        _allowsColumnResizing = YES;
        _allowsMultipleSelection = NO;
        _allowsEmptySelection = YES;
        _allowsColumnSelection = NO;

        _tableViewFlags = 0;

        //Setting Display Attributes
        _selectionHighlightMask = CPTableViewSelectionHighlightStyleRegular;

        [self setUsesAlternatingRowBackgroundColors:NO];
        [self setAlternatingRowBackgroundColors:[[CPColor whiteColor], [CPColor colorWithHexString:@"e4e7ff"]]];

        _tableColumns = [];
        _tableColumnRanges = [];
        _dirtyTableColumnRangeIndex = CPNotFound;
        _numberOfHiddenColumns = 0;

        _objectValues = { };
        _dataViewsForTableColumns = { };
        _dataViews=  [];
        _numberOfRows = 0;
        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];
        _cachedDataViews = { };
        _intercellSpacing = _CGSizeMake(0.0, 0.0);
        _rowHeight = 23.0;

        [self setSelectionHightlightColor:[CPColor selectionColor]];
        [self setGridColor:[CPColor grayColor]];
        [self setGridStyleMask:CPTableViewGridNone];

        _headerView = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, _rowHeight)];

        [_headerView setTableView:self];

        _cornerView = [[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([_headerView frame]))];


        _selectedColumnIndexes = [CPIndexSet indexSet];
        _selectedRowIndexes = [CPIndexSet indexSet];
window.setTimeout(function(){
        self._draggedRowIndexes = [CPIndexSet indexSet];
        self._verticalMotionCanDrag = YES;
        self._isSelectingSession = NO;
        self._retargetedDropRow = nil;
        self._retargetedDropOperation = nil;
        self._dragOperationDefaultMask = nil;
        self._destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;
        self._dropOperationFeedbackView = [[_dropOperationDrawingView alloc] initWithFrame:_CGRectMakeZero()];
        [self addSubview:_dropOperationFeedbackView];
        [_dropOperationFeedbackView setHidden:YES];
        [_dropOperationFeedbackView setTableView:self];
},0);

        _tableDrawView = [[_CPTableDrawView alloc] initWithTableView:self];
        [_tableDrawView setBackgroundColor:[CPColor clearColor]];
        [self addSubview:_tableDrawView];

    }

    return self;
}

- (void)setDataSource:(id)aDataSource
{
    if (_dataSource === aDataSource)
        return;

    _dataSource = aDataSource;
    _implementedDataSourceMethods = 0;

    if (!_dataSource)
        return;

    if (![_dataSource respondsToSelector:@selector(numberOfRowsInTableView:)])
        [CPException raise:CPInternalInconsistencyException
                reason:[aDataSource description] + " does not implement numberOfRowsInTableView:."];

    if (![_dataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)])
        [CPException raise:CPInternalInconsistencyException
                reason:[aDataSource description] + " does not implement tableView:objectValueForTableColumn:row:"];

    if ([_dataSource respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_;

    if ([_dataSource respondsToSelector:@selector(tableView:acceptDrop:row:dropOperation:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_acceptDrop_row_dropOperation_;

    if ([_dataSource respondsToSelector:@selector(tableView:namesOfPromisedFilesDroppedAtDestination:forDraggedRowsWithIndexes:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes_;

    if ([_dataSource respondsToSelector:@selector(tableView:validateDrop:proposedRow:proposedDropOperation:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_;

    if ([_dataSource respondsToSelector:@selector(tableView:writeRowsWithIndexes:toPasteboard:)])
        _implementedDataSourceMethods |= CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_;

    [self reloadData];
}

- (id)dataSource
{
    return _dataSource;
}

//Loading Data

- (void)reloadDataForRowIndexes:(CPIndexSet)rowIndexes columnIndexes:(CPIndexSet)columnIndexes
{
    [self reloadData];
//    [_previouslyExposedRows removeIndexes:rowIndexes];
//    [_previouslyExposedColumns removeIndexes:columnIndexes];
}


- (void)reloadData
{
    if (!_dataSource)
        return;

    _reloadAllRows = YES;
    _objectValues = { };

    // This updates the size too.
    [self noteNumberOfRowsChanged];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

//Target-action Behavior

- (void)setDoubleAction:(SEL)anAction
{
    _doubleAction = anAction;
}

- (SEL)doubleAction
{
    return _doubleAction;
}

/*
    * - clickedColumn
    * - clickedRow
*/
//Configuring Behavior

- (void)setAllowsColumnReordering:(BOOL)shouldAllowColumnReordering
{
    _allowsColumnReordering = !!shouldAllowColumnReordering;
}

- (BOOL)allowsColumnReordering
{
    return _allowsColumnReordering;
}

- (void)setAllowsColumnResizing:(BOOL)shouldAllowColumnResizing
{
    _allowsColumnResizing = !!shouldAllowColumnResizing;
}

- (BOOL)allowsColumnResizing
{
    return _allowsColumnResizing;
}

- (void)setAllowsMultipleSelection:(BOOL)shouldAllowMultipleSelection
{
    _allowsMultipleSelection = !!shouldAllowMultipleSelection;
}

- (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

- (void)setAllowsEmptySelection:(BOOL)shouldAllowEmptySelection
{
    _allowsEmptySelection = !!shouldAllowEmptySelection;
}

- (BOOL)allowsEmptySelection
{
    return _allowsEmptySelection;
}

- (void)setAllowsColumnSelection:(BOOL)shouldAllowColumnSelection
{
    _allowsColumnSelection = !!shouldAllowColumnSelection;
}

- (BOOL)allowsColumnSelection
{
    return _allowsColumnSelection;
}

//Setting Display Attributes

- (void)setIntercellSpacing:(CGSize)aSize
{
    if (_CGSizeEqualToSize(_intercellSpacing, aSize))
        return;

    _intercellSpacing = _CGSizeMakeCopy(aSize);

    [self setNeedsLayout];
}

- (void)setThemeState:(int)astae
{
}

- (CGSize)intercellSpacing
{
    return _CGSizeMakeCopy(_intercellSpacing);
}

- (void)setRowHeight:(unsigned)aRowHeight
{
    aRowHeight = +aRowHeight;

    if (_rowHeight === aRowHeight)
        return;

    _rowHeight = MAX(0.0, aRowHeight);

    [self setNeedsLayout];
}

- (unsigned)rowHeight
{
    return _rowHeight;
}

- (void)setUsesAlternatingRowBackgroundColors:(BOOL)shouldUseAlternatingRowBackgroundColors
{
    // TODO:need to look at how one actually sets the alternating row, a tip at:
    // http://forums.macnn.com/79/developer-center/228347/nstableview-alternating-row-colors/
    // otherwise this may not be feasible or may introduce an additional change req'd in CP
    // we'd probably need to iterate through rowId % 2 == 0 and setBackgroundColor with
    // whatever the alternating row color is.
    _usesAlternatingRowBackgroundColors = shouldUseAlternatingRowBackgroundColors;
}

- (BOOL)usesAlternatingRowBackgroundColors
{
    return _usesAlternatingRowBackgroundColors;
}

- (void)setAlternatingRowBackgroundColors:(CPArray)alternatingRowBackgroundColors
{
    if ([_alternatingRowBackgroundColors isEqual:alternatingRowBackgroundColors])
        return;

    _alternatingRowBackgroundColors = alternatingRowBackgroundColors;

    [self setNeedsDisplay:YES];
}

- (CPArray)alternatingRowBackgroundColors
{
    return _alternatingRowBackgroundColors;
}

- (unsigned)selectionHighlightStyle
{
    return _selectionHighlightMask;
}

- (void)setSelectionHighlightStyle:(unsigned)aSelectionHighlightStyle
{
    _selectionHighlightMask = aSelectionHighlightStyle;

    if ([self selectionHighlightStyle] === CPTableViewSelectionHighlightStyleSourceList)
    {
        [self setSelectionHightlightColor:[CPColor selectionColorSourceView]];
        _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleSourceList;
    }
	else
	{
	    [self setSelectionHightlightColor:[CPColor selectionColor]];
	    _destinationDragStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;
    }
}

- (void)setSelectionHightlightColor:(CPColor)aColor
{
    _selectionHightlightColor = aColor;
}

- (CPColor)selectionHightlightColor
{
    return _selectionHightlightColor;
}

/*
    * - indicatorImageInTableColumn:
    * - setIndicatorImage:inTableColumn:
*/

- (void)setGridColor:(CPColor)aColor
{
    if (_gridColor === aColor)
        return;

    _gridColor = aColor;

    [self setNeedsDisplay:YES];
}

- (CPColor)gridColor
{
    return _gridColor;
}

- (void)setGridStyleMask:(unsigned)aGrideStyleMask
{
    if (_gridStyleMask === aGrideStyleMask)
        return;

    _gridStyleMask = aGrideStyleMask;

    [self setNeedsDisplay:YES];
}

- (unsigned)gridStyleMask
{
    return _gridStyleMask;
}

//Column Management

- (void)addTableColumn:(CPTableColumn)aTableColumn
{
    [_tableColumns addObject:aTableColumn];
    [aTableColumn setTableView:self];

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = NUMBER_OF_COLUMNS() - 1;
    else
        _dirtyTableColumnRangeIndex = MIN(NUMBER_OF_COLUMNS() - 1, _dirtyTableColumnRangeIndex);

    [self setNeedsLayout];
}

- (void)removeTableColumn:(CPTableColumn)aTableColumn
{
    if ([aTableColumn tableView] !== self)
        return;

    var index = [_tableColumns indexOfObjectIdenticalTo:aTableColumn];

    if (index === CPNotFound)
        return;

    [aTableColumn setTableView:nil];
    [_tableColumns removeObjectAtIndex:index];

    var tableColumnUID = [aTableColumn UID];

    if (_objectValues[tableColumnUID])
        _objectValues[tableColumnUID] = nil;

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = index;
    else
        _dirtyTableColumnRangeIndex = MIN(index, _dirtyTableColumnRangeIndex);

    [self setNeedsLayout];
}

- (void)moveColumn:(unsigned)fromIndex toColumn:(unsigned)toIndex
{
    fromIndex = +fromIndex;
    toIndex = +toIndex;

    if (fromIndex === toIndex)
        return;

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = MIN(fromIndex, toIndex);
    else
        _dirtyTableColumnRangeIndex = MIN(fromIndex, toIndex, _dirtyTableColumnRangeIndex);

    if (toIndex > fromIndex)
        --toIndex;

    var tableColumn = _tableColumns[fromIndex];

    [_tableColumns removeObjectAtIndex:fromIndex];
    [_tableColumns insertObject:tableColumn atIndex:toIndex];

    [self setNeedsLayout];
}

- (CPArray)tableColumns
{
    return _tableColumns;
}

- (CPInteger)columnWithIdentifier:(CPString)anIdentifier
{
    var index = 0,
        count = NUMBER_OF_COLUMNS();

    for (; index < count; ++index)
        if ([_tableColumns[index] identifier] === anIdentifier)
            return index;

    return CPNotFound;
}

- (CPTableColumn)tableColumnWithIdentifier:(CPString)anIdentifier
{
    var index = [self columnWithIdentifier:anIdentifier];

    if (index === CPNotFound)
        return nil;

    return _tableColumns[index];
}

//Selecting Columns and Rows
- (void)selectColumnIndexes:(CPIndexSet)columns byExtendingSelection:(BOOL)shouldExtendSelection
{
    // If we're out of range, just return
    if (([columns firstIndex] != CPNotFound && [columns firstIndex] < 0) || [columns lastIndex] >= [self numberOfColumns])
        return;

    // We deselect all rows when selecting columns.
    if ([_selectedRowIndexes count] > 0)
    {
        [self _updateHighlightWithOldRows:_selectedRowIndexes newRows:[CPIndexSet indexSet]];
        _selectedRowIndexes = [CPIndexSet indexSet];
    }

    var previousSelectedIndexes = [_selectedColumnIndexes copy];

    if (shouldExtendSelection)
        [_selectedColumnIndexes addIndexes:columns];
    else
        _selectedColumnIndexes = [columns copy];

    [self _updateHighlightWithOldColumns:previousSelectedIndexes newColumns:_selectedColumnIndexes];
    [_tableDrawView display]; // FIXME: should be setNeedsDisplayInRect:enclosing rect of new (de)selected columns
                              // but currently -drawRect: is not implemented here
    [_headerView setNeedsDisplay:YES];

    [self _noteSelectionDidChange];
}

- (void)selectRowIndexes:(CPIndexSet)rows byExtendingSelection:(BOOL)shouldExtendSelection
{
    if (([rows firstIndex] != CPNotFound && [rows firstIndex] < 0) || [rows lastIndex] >= [self numberOfRows])
        return;

    // We deselect all columns when selecting rows.
    if ([_selectedColumnIndexes count] > 0)
    {
        [self _updateHighlightWithOldColumns:_selectedColumnIndexes newColumns:[CPIndexSet indexSet]];
        _selectedColumnIndexes = [CPIndexSet indexSet];
        [_headerView setNeedsDisplay:YES];
    }

    var previousSelectedIndexes = [_selectedRowIndexes copy];

    if (shouldExtendSelection)
        [_selectedRowIndexes addIndexes:rows];
    else
        _selectedRowIndexes = [rows copy];

    [self _updateHighlightWithOldRows:previousSelectedIndexes newRows:_selectedRowIndexes];
    [_tableDrawView display]; // FIXME: should be setNeedsDisplayInRect:enclosing rect of new (de)selected rows
                              // but currently -drawRect: is not implemented here
    [self _noteSelectionDidChange];
}

- (void)_updateHighlightWithOldRows:(CPIndexSet)oldRows newRows:(CPIndexSet)newRows
{
    var firstExposedRow = [_exposedRows firstIndex],
        exposedLength = [_exposedRows lastIndex] - firstExposedRow + 1,
        deselectRows = [],
        selectRows = [],
        deselectRowIndexes = [oldRows copy],
        selectRowIndexes = [newRows copy];

    [deselectRowIndexes removeMatches:selectRowIndexes];
    [deselectRowIndexes getIndexes:deselectRows maxCount:-1 inIndexRange:CPMakeRange(firstExposedRow, exposedLength)];
    [selectRowIndexes getIndexes:selectRows maxCount:-1 inIndexRange:CPMakeRange(firstExposedRow, exposedLength)];

    for (var identifier in _dataViewsForTableColumns)
    {
        var dataViewsInTableColumn = _dataViewsForTableColumns[identifier];

        var count = deselectRows.length;
        while (count--)
        {
            var rowIndex = deselectRows[count];
            var view = dataViewsInTableColumn[rowIndex];
            [view unsetThemeState:CPThemeStateHighlighted];
        }

        count = selectRows.length;
        while (count--)
        {
            var rowIndex = selectRows[count];
            var view = dataViewsInTableColumn[rowIndex];
            [view setThemeState:CPThemeStateHighlighted];
        }
    }
}

- (void)_updateHighlightWithOldColumns:(CPIndexSet)oldColumns newColumns:(CPIndexSet)newColumns
{
    var firstExposedColumn = [_exposedColumns firstIndex],
        exposedLength = [_exposedColumns lastIndex] - firstExposedColumn  +1,
        deselectColumns  = [],
        selectColumns  = [],
        deselectColumnIndexes = [oldColumns copy],
        selectColumnIndexes = [newColumns copy];


    [deselectColumnIndexes removeMatches:selectColumnIndexes];
    [deselectColumnIndexes getIndexes:deselectColumns maxCount:-1 inIndexRange:CPMakeRange(firstExposedColumn, exposedLength)];
    [selectColumnIndexes getIndexes:selectColumns maxCount:-1 inIndexRange:CPMakeRange(firstExposedColumn, exposedLength)];

    var count = deselectColumns.length;
    while (count--)
    {
        var columnIndex = deselectColumns[count],
            identifier = [_tableColumns[columnIndex] UID],
            dataViewsInTableColumn = _dataViewsForTableColumns[identifier];

        [dataViewsInTableColumn makeObjectsPerformSelector:@selector(unsetThemeState:) withObject:CPThemeStateHighlighted];
        var headerView = [_tableColumns[columnIndex] headerView];
        [headerView unsetThemeState:CPThemeStateSelected];
    }

    count = selectColumns.length;
    while (count--)
    {
        var columnIndex = selectColumns[count],
            identifier = [_tableColumns[columnIndex] UID],
            dataViewsInTableColumn = _dataViewsForTableColumns[identifier];

        [dataViewsInTableColumn makeObjectsPerformSelector:@selector(setThemeState:) withObject:CPThemeStateHighlighted];
        var headerView = [_tableColumns[columnIndex] headerView];
        [headerView setThemeState:CPThemeStateSelected];
    }
}

- (CPIndexSet)selectedColumnIndexes
{
    return _selectedColumnIndexes;
}

- (CPIndexSet)selectedRowIndexes
{
    return _selectedRowIndexes;
}

- (void)deselectColumn:(CPInteger)aColumn
{
    [_selectedColumnIndexes removeIndex:aColumn];
    [self _noteSelectionDidChange];
}

- (void)deselectRow:(CPInteger)aRow
{
    [_selectedRowIndexes removeIndex:aRow];
    [self _noteSelectionDidChange];
}

- (CPInteger)numberOfSelectedColumns
{
    return [_selectedColumnIndexes count];
}

- (CPInteger)numberOfSelectedRows
{
    return [_selectedRowIndexes count];
}

/*
- (CPInteger)selectedColumn
    * - selectedRow
*/

- (BOOL)isColumnSelected:(CPInteger)aColumn
{
    return [_selectedColumnIndexes containsIndex:aColumn];
}

- (BOOL)isRowSelected:(CPInteger)aRow
{
    return [_selectedRowIndexes containsIndex:aRow];
}
/*
- (void)selectAll:
    * - deselectAll:
    * - allowsTypeSelect
    * - setAllowsTypeSelect:
*/
- (void)deselectAll
{
    [self selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
    [self selectColumnIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
}

//Table Dimensions

- (int)numberOfColumns
{
    return NUMBER_OF_COLUMNS();
}

/*
    Returns the number of rows in the receiver.
*/
- (int)numberOfRows
{
    if (!_dataSource)
        return 0;

    return [_dataSource numberOfRowsInTableView:self];
}

//Displaying Cell
/*
    * - preparedCellAtColumn:row:
*/
//Editing Cells
/*
    * - editColumn:row:withEvent:select:
    * - editedColumn
    * - editedRow
*/
//Setting Auxiliary Views
/*
    * - setHeaderView:
    * - headerView
    * - setCornerView:
    * - cornerView
*/

- (CPView)cornerView
{
    return _cornerView;
}

- (void)setCornerView:(CPView)aView
{
    if (_cornerView === aView)
        return;

    _cornerView = aView;

    var scrollView = [[self superview] superview];

    if ([scrollView isKindOfClass:[CPScrollView class]] && [scrollView documentView] === self)
        [scrollView _updateCornerAndHeaderView];
}

- (CPView)headerView
{
    return _headerView;
}

- (void)setHeaderView:(CPView)aHeaderView
{
    if (_headerView === aHeaderView)
        return;

    [_headerView setTableView:nil];

    _headerView = aHeaderView;

    if (_headerView)
    {
        [_headerView setTableView:self];
        [_headerView setFrameSize:_CGSizeMake(_CGRectGetWidth([self frame]), _CGRectGetHeight([_headerView frame]))];
    }

    var scrollView = [[self superview] superview];

    if ([scrollView isKindOfClass:[CPScrollView class]] && [scrollView documentView] === self)
        [scrollView _updateCornerAndHeaderView];
}

//Layout Support

// Complexity:
// O(Columns)
- (void)_recalculateTableColumnRanges
{
    if (_dirtyTableColumnRangeIndex < 0)
        return;

    var index = _dirtyTableColumnRangeIndex,
        count = NUMBER_OF_COLUMNS(),
        x = index === 0 ? 0.0 : CPMaxRange(_tableColumnRanges[index - 1]);

    for (; index < count; ++index)
    {
        var tableColumn = _tableColumns[index];

        if ([tableColumn isHidden])
            _tableColumnRanges[index] = CPMakeRange(x, 0.0);

        else
        {
            var width = [_tableColumns[index] width];

            _tableColumnRanges[index] = CPMakeRange(x, width);

            x += width;
        }
    }

    _tableColumnRanges.length = count;
    _dirtyTableColumnRangeIndex = CPNotFound;
}

// Complexity:
// O(1)
- (CGRect)rectOfColumn:(CPInteger)aColumnIndex
{
    aColumnIndex = +aColumnIndex;

    if (aColumnIndex < 0 || aColumnIndex >= NUMBER_OF_COLUMNS())
        return _CGRectMakeZero();

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var range = _tableColumnRanges[aColumnIndex];

    return _CGRectMake(range.location, 0.0, range.length, CGRectGetHeight([self bounds]));
}

- (CGRect)rectOfRow:(CPInteger)aRowIndex
{
    if (NO)
        return NULL;

    // FIXME: WRONG: ASK TABLE COLUMN RANGE
    return _CGRectMake(0.0, (aRowIndex * (_rowHeight + _intercellSpacing.height)), _CGRectGetWidth([self bounds]), _rowHeight);
}

// Complexity:
// O(1)
- (CPRange)rowsInRect:(CGRect)aRect
{
    // If we have no rows, then we won't intersect anything.
    if (_numberOfRows <= 0)
        return CPMakeRange(0, 0);

    var bounds = [self bounds];

    // No rows if the rect doesn't even intersect us.
    if (!CGRectIntersectsRect(aRect, bounds))
        return CPMakeRange(0, 0);

    var firstRow = [self rowAtPoint:aRect.origin];

    // first row has to be undershot, because if not we wouldn't be intersecting.
    if (firstRow < 0)
        firstRow = 0;

    var lastRow = [self rowAtPoint:_CGPointMake(0.0, _CGRectGetMaxY(aRect))];

    // last row has to be overshot, because if not we wouldn't be intersecting.
    if (lastRow < 0)
        lastRow = _numberOfRows - 1;

    return CPMakeRange(firstRow, lastRow - firstRow + 1);
}

// Complexity:
// O(lg Columns) if table view contains no hidden columns
// O(Columns) if table view contains hidden columns
- (CPIndexSet)columnIndexesInRect:(CGRect)aRect
{
    var column = MAX(0, [self columnAtPoint:_CGPointMake(aRect.origin.x, 0.0)]),
        lastColumn = [self columnAtPoint:_CGPointMake(_CGRectGetMaxX(aRect), 0.0)];

    if (lastColumn === CPNotFound)
        lastColumn = NUMBER_OF_COLUMNS() - 1;

    // Don't bother doing the expensive removal of hidden indexes if we have no hidden columns.
    if (_numberOfHiddenColumns <= 0)
        return [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(column, lastColumn - column + 1)];

    //
    var indexSet = [CPIndexSet indexSet];

    for (; column <= lastColumn; ++column)
    {
        var tableColumn = _tableColumns[column];

        if (![tableColumn isHidden])
            [indexSet addIndex:column];
    }

    return indexSet;
}

// Complexity:
// O(lg Columns) if table view contains now hidden columns
// O(Columns) if table view contains hidden columns
- (CPInteger)columnAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds];

    if (!_CGRectContainsPoint(bounds, aPoint))
        return CPNotFound;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var x = aPoint.x,
        low = 0,
        high = _tableColumnRanges.length - 1;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            range = _tableColumnRanges[middle];

        if (x < range.location)
            high = middle - 1;

        else if (x >= CPMaxRange(range))
            low = middle + 1;

        else
        {
            var numberOfColumns = _tableColumnRanges.length;

            while (middle < numberOfColumns && [_tableColumns[middle] isHidden])
                ++middle;

            if (middle < numberOfColumns)
                return middle;

            return CPNotFound;
        }
   }

   return CPNotFound;
}

- (CPInteger)rowAtPoint:(CGPoint)aPoint
{
    var y = aPoint.y;

    var row = FLOOR(y / (_rowHeight + _intercellSpacing.height));

    if (row >= _numberOfRows)
        return -1;

    return row;
}

- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var tableColumnRange = _tableColumnRanges[aColumn],
        rectOfRow = [self rectOfRow:aRow];

    return _CGRectMake(tableColumnRange.location, _CGRectGetMinY(rectOfRow), tableColumnRange.length, _CGRectGetHeight(rectOfRow));
}

- (void)resizeWithOldSuperviewSize:(CGSize)aSize
{
    [super resizeWithOldSuperviewSize:aSize];

    var mask = _columnAutoResizingStyle;

    if(mask === CPTableViewUniformColumnAutoresizingStyle)
    {
        // FIX ME: needs to respect proportion of the the columns set width...
        // this can also get slow when there are many rows
        // do this by getting the width of the new size and subtracting it from the width of the old size dividing the difference by the number of visible rows.
        // loop trough the rows one by one adding the quotient to each row be sure to check for min/max widths when doing it.

        var superview = [self superview];

        if (!superview)
            return;

        var superviewSize = [superview bounds].size;

        UPDATE_COLUMN_RANGES_IF_NECESSARY();

        var count = NUMBER_OF_COLUMNS();

        var visColumns = [[CPArray alloc] init];

        for(var i=0; i < count; i++)
        {
            if(![_tableColumns[i] isHidden])
                [visColumns addObject:i];
        }

        count = [visColumns count];

        //if there are rows
        if (count > 0)
        {
            //get total width // don't let it be smaller than 15
            var newWidth = MAX(15.0, superviewSize.width / count);

            //loop through all the rows again
            for(var i = 0; i < count; i++)
            {
                var columnToResize = _tableColumns[visColumns[i]];
                var newWidth = MAX([columnToResize minWidth], superviewSize.width / count);
                newWidth = (newWidth > [columnToResize maxWidth]) ? [columnToResize maxWidth] : newWidth;

                [columnToResize setWidth:FLOOR(newWidth)];
            }
        }

        [self setNeedsLayout];
    }

    if(mask === CPTableViewLastColumnOnlyAutoresizingStyle)
    {
        [self sizeLastColumnToFit];
    }

    if(mask === CPTableViewFirstColumnOnlyAutoresizingStyle)
    {
        var superview = [self superview];

        if (!superview)
            return;

        var superviewSize = [superview bounds].size;

        UPDATE_COLUMN_RANGES_IF_NECESSARY();

        var count = NUMBER_OF_COLUMNS();

        var visColumns = [[CPArray alloc] init];
        var totalWidth = 0;

        for(var i=0; i < count; i++)
        {
            if(![_tableColumns[i] isHidden])
            {
                [visColumns addObject:i];
                totalWidth += [_tableColumns[i] width];
            }
        }

        count = [visColumns count];

        //if there are rows
        if (count > 0)
        {
            var columnToResize = _tableColumns[visColumns[0]];
            var newWidth = superviewSize.width - totalWidth;// - [columnToResize width];
            newWidth += [columnToResize width];
            newWidth = (newWidth < [columnToResize minWidth]) ? [columnToResize minWidth] : newWidth;
            newWidth = (newWidth > [columnToResize maxWidth]) ? [columnToResize maxWidth] : newWidth;

            [columnToResize setWidth:FLOOR(newWidth)];
        }

        [self setNeedsLayout];
    }

}

- (void)setColumnAutoresizingStyle:(unsigned)style
{
    //FIX ME: CPTableViewSequentialColumnAutoresizingStyle and CPTableViewReverseSequentialColumnAutoresizingStyle are not yet implemented
    _columnAutoResizingStyle = style;
}

- (unsigned)columnAutoresizingStyle
{
    return _columnAutoResizingStyle;
}

- (void)sizeLastColumnToFit
{
    var superview = [self superview];

    if (!superview)
        return;

    var superviewSize = [superview bounds].size;

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var count = NUMBER_OF_COLUMNS();

    //decrement the counter until we get to the last row that's not hidden
    while (count-- && [_tableColumns[count] isHidden]) ;

    //if the last row exists
    if (count >= 0)
    {
        var columnToResize = _tableColumns[count];
        var newSize = MAX(0.0, superviewSize.width - CGRectGetMinX([self rectOfColumn:count]));

        if (newSize > 0)
        {
            newSize = (newSize < [columnToResize minWidth]) ? [columnToResize minWidth] : newSize;
            newSize = (newSize > [columnToResize maxWidth]) ? [columnToResize maxWidth] : newSize;
            [columnToResize setWidth:newSize];
        }
    }

    [self setNeedsLayout];
}

- (void)noteNumberOfRowsChanged
{
    _numberOfRows = [_dataSource numberOfRowsInTableView:self];

    [self tile];
}

- (void)tile
{
    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    // FIXME: variable row heights.
    var width = _tableColumnRanges.length > 0 ? CPMaxRange([_tableColumnRanges lastObject]) : 0.0,
        height = (_rowHeight + _intercellSpacing.height) * _numberOfRows,
        superview = [self superview];

    if ([superview isKindOfClass:[CPClipView class]])
    {
        var superviewSize = [superview bounds].size;

        width = MAX(superviewSize.width, width);
        height = MAX(superviewSize.height, height);
    }

    [self setFrameSize:_CGSizeMake(width, height)];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*
    * - tile
    * - sizeToFit
    * - noteHeightOfRowsWithIndexesChanged:
*/
//Scrolling
/*
    * - scrollRowToVisible:
    * - scrollColumnToVisible:
*/

- (void)scrollRowToVisible:(int)rowIndex
{
    [self scrollRectToVisible:[self rectOfRow:rowIndex]];
}

- (void)scrollColumnToVisible:(int)columnIndex
{
    [self scrollRectToVisible:[self rectOfColumn:columnIndex]];
    /*FIX ME: tableview header isn't rendered until you click the horizontal scroller (or scroll)*/
}

//Persistence
/*
    * - autosaveName
    * - autosaveTableColumns
    * - setAutosaveName:
    * - setAutosaveTableColumns:
*/

//Setting the Delegate:(id)aDelegate

- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewColumnDidMoveNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewColumnDidResizeNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewSelectionDidChangeNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewSelectionIsChangingNotification
                        object:self];
    }

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(selectionShouldChangeInTableView:)])
        _implementedDelegateMethods |= CPTableViewDelegate_selectionShouldChangeInTableView_;

    if ([_delegate respondsToSelector:@selector(tableView:dataViewForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_dataViewForTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:didClickTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_didClickTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:didDragTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_didDragTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:heightOfRow:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_heightOfRow_;

    if ([_delegate respondsToSelector:@selector(tableView:isGroupRow:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_isGroupRow_;

    if ([_delegate respondsToSelector:@selector(tableView:mouseDownInHeaderOfTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_mouseDownInHeaderOfTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:nextTypeSelectMatchFromRow:toRow:forString:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_nextTypeSelectMatchFromRow_toRow_forString_;

    if ([_delegate respondsToSelector:@selector(tableView:selectionIndexesForProposedSelection:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldEditTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldEditTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectRow:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldSelectRow_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldSelectTableColumn:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldSelectTableColumn_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldShowViewExpansionForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldShowViewExpansionForTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldTrackView:forTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldTrackView_forTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:shouldTypeSelectForEvent:withCurrentSearchString:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_shouldTypeSelectForEvent_withCurrentSearchString_;

    if ([_delegate respondsToSelector:@selector(tableView:toolTipForView:rect:tableColumn:row:mouseLocation:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_toolTipForView_rect_tableColumn_row_mouseLocation_;

    if ([_delegate respondsToSelector:@selector(tableView:typeSelectStringForTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_typeSelectStringForTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableView:willDisplayView:forTableColumn:row:)])
        _implementedDelegateMethods |= CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_;

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewColumnDidMove:)
            name:CPTableViewColumnDidMoveNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewColumnDidResize:)
            name:CPTableViewColumnDidResizeNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewSelectionDidChange:)
            name:CPTableViewSelectionDidChangeNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewSelectionIsChanging:)
            name:CPTableViewSelectionIsChangingNotification
            object:self];
}

- (id)delegate
{
    return _delegate;
}

//Highlightable Column Headers
/*
- (CPTableColumn)highlightedTableColumn
{

}

    * - setHighlightedTableColumn:
*/
//Dragging
/*
    * - dragImageForRowsWithIndexes:tableColumns:event:offset:
    * - canDragRowsWithIndexes:atPoint:
    * - setDraggingSourceOperationMask:forLocal:
    * - setDropRow:dropOperation:
    * - setVerticalMotionCanBeginDrag:
    * - verticalMotionCanBeginDrag
*/
- (BOOL)canDragRowsWithIndexes:(CPIndexSet)rowIndexes atPoint:(CGPoint)mouseDownPoint
{
    return YES;
}

- (CPImage)dragImageForRowsWithIndexes:(CPIndexSet)dragRows 
						  tableColumns:(CPArray)theTableColumns 
								 event:(CPEvent)dragEvent 
								offset:(CPPointPointer)dragImageOffset
{
    return [[CPImage alloc] initWithContentsOfFile:@"Frameworks/AppKit/Resources/GenericFile.png" size:CGSizeMake(32,32)];
}

- (CPView)dragViewForRowsWithIndexes:(CPIndexSet)theDraggedRows 
						tableColumns:(CPArray)theTableColumns 
							   event:(CPEvent)theDragEvent 
							  offset:(CPPoint)dragViewOffset
{
	var size = [self bounds].size,
		view = [[CPView alloc] initWithFrame:CPMakeRect(dragViewOffset.x, dragViewOffset.y, size.width, size.height)];
		
	[view setBackgroundColor:[CPColor clearColor]];
	[view setAlphaValue:0.7];
	
	// We have to fetch all the data views for the selected rows and columns
	// After that we can copy these add them to a transparent drag view and use that drag view 
	// to make it appear we are dragging images of those rows (as you would do in regular Cocoa)
	var firstExposedColumn = [_exposedColumns firstIndex],
		exposedLength = [_exposedColumns lastIndex] - firstExposedColumn + 1,
		columns = [];
		
	[_exposedColumns getIndexes:columns maxCount:-1 inIndexRange:CPMakeRange(firstExposedColumn, exposedLength)];
	
	var columnIndex = [columns count],
		draggedDataViews = [],
		dragViewHeight = 0.0;
		
	while (columnIndex--) {
		var column = [_tableColumns objectAtIndex:columnIndex],
			yOffset = 0,
			rowIndex = CPNotFound;
		
		while ((rowIndex = [_selectedRowIndexes indexGreaterThanIndex:rowIndex]) !== CPNotFound)
		{
			var dataView = [self _newDataViewForRow:rowIndex tableColumn:column];
			
			[dataView setBackgroundColor:[CPColor clearColor]];
			[dataView setFrame:[self frameOfDataViewAtColumn:columnIndex row:rowIndex]];
			[dataView setObjectValue:[self _objectValueForTableColumn:column row:rowIndex]];
			
			[view addSubview:dataView];
		}
	}
	
	return view;
}

- (void)setDraggingSourceOperationMask:(CPDragOperation)mask forLocal:(BOOL)isLocal
{
    //ignoral local for the time being since only one capp app can run at a time...
    _dragOperationDefaultMask = mask;
}

/*
    this should be called inside tableView:validateDrop:... method
    either drop on or above,
    specify the row as -1 to select the whole table for drop on
*/
- (void)setDropRow:(CPInteger)row dropOperation:(CPTableViewDropOperation)operation
{
    if(row < 0 && operation === CPTableViewDropAbove)
        row = 0;

    if(row >= [self numberOfRows] && operation === CPTableViewDropOn)
        [[CPException exceptionWithName:@"Error" reason:@"Attempt to set dropRow="+ row +", dropOperation=CPTableViewDropOn when [0 - "+ [self numberOfRows] +"] is valid range of rows." userInfo:nil] raise];

    _retargetedDropRow = row;
    _retargetedDropOperation = operation;
}

/*
    can be:
    None
    Regular
    Source List

    FIX ME: this should vary up the highlight color, currently nothing is being done with it
*/
- (void)setDraggingDestinationFeedbackStyle:(CPTableViewDraggingDestinationFeedbackStyle)aStyle
{
    _destinationDragStyle = aStyle;
}

- (CPTableViewDraggingDestinationFeedbackStyle)draggingDestinationFeedbackStyle
{
    return _destinationDragStyle;
}

- (void)setVerticalMotionCanBeginDrag:(BOOL)aFlag
{
    _verticalMotionCanDrag = aFlag;
}

- (BOOL)verticalMotionCanBeginDrag
{
    return _verticalMotionCanDrag;
}



//Sorting
/*
    * - setSortDescriptors:
    * - sortDescriptors
*/

//Text Delegate Methods
/*
    * - textShouldBeginEditing:
    * - textDidBeginEditing:
    * - textDidChange:
    * - textShouldEndEditing:
    * - textDidEndEditing:
*/

- (id)_objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRowIndex
{
    var tableColumnUID = [aTableColumn UID],
        tableColumnObjectValues = _objectValues[tableColumnUID];

    if (!tableColumnObjectValues)
    {
        tableColumnObjectValues = [];
        _objectValues[tableColumnUID] = tableColumnObjectValues;
    }

    var objectValue = tableColumnObjectValues[aRowIndex];

    if (objectValue === undefined)
    {
        objectValue = [_dataSource tableView:self objectValueForTableColumn:aTableColumn row:aRowIndex];
        tableColumnObjectValues[aRowIndex] = objectValue;
    }

    return objectValue;
}

- (CGRect)_exposedRect
{
    var superview = [self superview];

    if (![superview isKindOfClass:[CPClipView class]])
        return [self bounds];

    return [self convertRect:CGRectIntersection([superview bounds], [self frame]) fromView:superview];
}

- (void)load
{
//    if (!window.blah)
//        return window.setTimeout(function() { window.blah = true; [self load]; window.blah = false}, 0.0);

 //   if (window.console && window.console.profile)
 //       console.profile("cell-load");

    if (_reloadAllRows)
    {
        [self _unloadDataViewsInRows:_exposedRows columns:_exposedColumns];

        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];

        _reloadAllRows = NO;
    }

    var exposedRect = [self _exposedRect],
        exposedRows = [CPIndexSet indexSetWithIndexesInRange:[self rowsInRect:exposedRect]],
        exposedColumns = [self columnIndexesInRect:exposedRect],
        obscuredRows = [_exposedRows copy],
        obscuredColumns = [_exposedColumns copy];

    [obscuredRows removeIndexes:exposedRows];
    [obscuredColumns removeIndexes:exposedColumns];

    var newlyExposedRows = [exposedRows copy],
        newlyExposedColumns = [exposedColumns copy];

    [newlyExposedRows removeIndexes:_exposedRows];
    [newlyExposedColumns removeIndexes:_exposedColumns];

    var previouslyExposedRows = [exposedRows copy],
        previouslyExposedColumns = [exposedColumns copy];

    [previouslyExposedRows removeIndexes:newlyExposedRows];
    [previouslyExposedColumns removeIndexes:newlyExposedColumns];

//    console.log("will remove:" + '\n\n' +
//        previouslyExposedRows + "\n" + obscuredColumns + "\n\n" +
//        obscuredRows + "\n" + previouslyExposedColumns + "\n\n" +
//        obscuredRows + "\n" + obscuredColumns);
    [self _unloadDataViewsInRows:previouslyExposedRows columns:obscuredColumns];
    [self _unloadDataViewsInRows:obscuredRows columns:previouslyExposedColumns];
    [self _unloadDataViewsInRows:obscuredRows columns:obscuredColumns];

    [self _loadDataViewsInRows:previouslyExposedRows columns:newlyExposedColumns];
    [self _loadDataViewsInRows:newlyExposedRows columns:previouslyExposedColumns];
    [self _loadDataViewsInRows:newlyExposedRows columns:newlyExposedColumns];

//    console.log("newly exposed rows: " + newlyExposedRows + "\nnewly exposed columns: " + newlyExposedColumns);
    _exposedRows = exposedRows;
    _exposedColumns = exposedColumns;

    [_tableDrawView setFrame:exposedRect];

//    [_tableDrawView setBounds:exposedRect];
    [_tableDrawView display];

    // Now clear all the leftovers
    // FIXME: this could be faster!
    for (identifier in _cachedDataViews)
    {
        var dataViews = _cachedDataViews[identifier],
            count = dataViews.length;

        while (count--)
            [dataViews[count] removeFromSuperview];
    }

  //  if (window.console && window.console.profile)
//        console.profileEnd("cell-load");
}

- (void)_unloadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    if (![rows count] || ![columns count])
        return;

    var rowArray = [],
        columnArray = [];

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];

    var columnIndex = 0,
        columnsCount = columnArray.length;

    for (; columnIndex < columnsCount; ++columnIndex)
    {
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID];

        var rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = _dataViewsForTableColumns[tableColumnUID][row];

            _dataViewsForTableColumns[tableColumnUID][row] = nil;

            [self _enqueueReusableDataView:dataView];
        }
    }
}

- (void)_loadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    if (![rows count] || ![columns count])
        return;

    var rowArray = [],
        rowRects = [],
        columnArray = [];

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];

    UPDATE_COLUMN_RANGES_IF_NECESSARY();

    var columnIndex = 0,
        columnsCount = columnArray.length;

    for (; columnIndex < columnsCount; ++columnIndex)
    {
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID];

        if (!_dataViewsForTableColumns[tableColumnUID])
            _dataViewsForTableColumns[tableColumnUID] = [];

        var rowIndex = 0,
            rowsCount = rowArray.length;

        var isColumnSelected = [_selectedColumnIndexes containsIndex:column];
        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = [self _newDataViewForRow:row tableColumn:tableColumn],
                isTextField = [dataView isKindOfClass:[CPTextField class]];

            [dataView setFrame:[self frameOfDataViewAtColumn:column row:row]];
            [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:row]];

            if (isColumnSelected || [self isRowSelected:row])
                [dataView setThemeState:CPThemeStateHighlighted];
            else
                [dataView unsetThemeState:CPThemeStateHighlighted];

            if (_implementedDelegateMethods & CPTableViewDelegate_tableView_willDisplayView_forTableColumn_row_)
                [[self delegate] tableView:self willDisplayView:dataView forTableColumn:tableColumn row:row];

            if ([dataView superview] !== self)
                [self addSubview:dataView];

            _dataViewsForTableColumns[tableColumnUID][row] = dataView;

            if (_editingCellIndex && _editingCellIndex.x === column && _editingCellIndex.y === row) {
                _editingCellIndex = undefined;

                if (isTextField) {
                    [dataView setEditable:YES];
                    [dataView setSendsActionOnEndEditing:YES];
                    [dataView setSelectable:YES];
                    [dataView selectText:nil]; // Doesn't seem to actually work (yet?).
                }
                [dataView setTarget:self];
                [dataView setAction:@selector(_commitDataViewObjectValue:)];
                dataView.tableViewEditedColumnObj = tableColumn;
                dataView.tableViewEditedRowIndex = row;
            } else if (isTextField) {
                [dataView setEditable:NO];
                [dataView setSelectable:NO];
            }
        }
    }
}

- (void)_commitDataViewObjectValue:(CPTextView)sender
{
    [_dataSource tableView:self
        setObjectValue:[sender objectValue]
        forTableColumn:sender.tableViewEditedColumnObj
        row:sender.tableViewEditedRowIndex];
}

- (CPView)_newDataViewForRow:(CPInteger)aRow tableColumn:(CPTableColumn)aTableColumn
{
    return [aTableColumn _newDataViewForRow:aRow];
}

- (void)_enqueueReusableDataView:(CPView)aDataView
{
    // FIXME: yuck!
    var identifier = aDataView.identifier;

    if (!_cachedDataViews[identifier])
        _cachedDataViews[identifier] = [aDataView];
    else
        _cachedDataViews[identifier].push(aDataView);
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];

    if (_headerView)
        [_headerView setFrameSize:_CGSizeMake(_CGRectGetWidth([self frame]), _CGRectGetHeight([_headerView frame]))];
}

- (CGRect)exposedClipRect
{
    var superview = [self superview];

    if (![superview isKindOfClass:[CPClipView class]])
        return [self bounds];

    return [self convertRect:CGRectIntersection([superview bounds], [self frame]) fromView:superview];
}

- (void)_drawRect:(CGRect)aRect
{
    var exposedRect = [self _exposedRect];

    [self drawBackgroundInClipRect:exposedRect];
    [self drawGridInClipRect:exposedRect];
    [self highlightSelectionInClipRect:exposedRect];
}

- (void)drawRect:(CGRect)aRect
{
    [_tableDrawView display];
}

- (void)drawBackgroundInClipRect:(CGRect)aRect
{
    if (![self usesAlternatingRowBackgroundColors])
        return;

    var rowColors = [self alternatingRowBackgroundColors],
        colorCount = [rowColors count];

    if (colorCount === 0)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    if (colorCount === 1)
    {
        CGContextSetFillColor(context, rowColors[0]);
        CGContextFillRect(context, aRect);

        return;
    }
    // CGContextFillRect(context, CGRectIntersection(aRect, fillRect));
    // console.profile("row-paint");
    var exposedRows = [self rowsInRect:aRect],
        firstRow = exposedRows.location,
        lastRow = CPMaxRange(exposedRows) - 1,
        colorIndex = MIN(exposedRows.length, colorCount),
        heightFilled = 0.0;

    while (colorIndex--)
    {
        var row = firstRow % colorCount + firstRow + colorIndex,
            fillRect = nil;

        CGContextBeginPath(context);

        for (; row <= lastRow; row += colorCount)
            CGContextAddRect(context, CGRectIntersection(aRect, fillRect = [self rectOfRow:row]));

        if (row - colorCount === lastRow)
            heightFilled = _CGRectGetMaxY(fillRect);

        CGContextClosePath(context);

        CGContextSetFillColor(context, rowColors[colorIndex]);
        CGContextFillPath(context);
    }
    // console.profileEnd("row-paint");

    var totalHeight = _CGRectGetMaxY(aRect);

    if (heightFilled >= totalHeight || _rowHeight <= 0.0)
        return;

    var rowHeight = _rowHeight + _intercellSpacing.height,
        fillRect = _CGRectMake(_CGRectGetMinX(aRect), _CGRectGetMinY(aRect) + heightFilled, _CGRectGetWidth(aRect), rowHeight);

    for (row = lastRow + 1; heightFilled < totalHeight; ++row)
    {
        CGContextSetFillColor(context, rowColors[row % colorCount]);
        CGContextFillRect(context, fillRect);

        heightFilled += rowHeight;
        fillRect.origin.y += rowHeight;
    }
}

- (void)drawGridInClipRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        gridStyleMask = [self gridStyleMask];

    if (!(gridStyleMask & (CPTableViewSolidHorizontalGridLineMask | CPTableViewSolidVerticalGridLineMask)))
        return;

    CGContextBeginPath(context);

    if (gridStyleMask & CPTableViewSolidHorizontalGridLineMask)
    {
        var exposedRows = [self rowsInRect:aRect];
            row = exposedRows.location,
            lastRow = CPMaxRange(exposedRows) - 1,
            rowY = 0.0,
            minX = _CGRectGetMinX(aRect),
            maxX = _CGRectGetMaxX(aRect);

        for (; row <= lastRow; ++row)
        {
            // grab each row rect and add the top and bottom lines
            var rowRect = [self rectOfRow:row],
                rowY = _CGRectGetMaxY(rowRect) - 0.5;

            CGContextMoveToPoint(context, minX, rowY);
            CGContextAddLineToPoint(context, maxX, rowY);
        }

        if (_rowHeight > 0.0)
        {
            var rowHeight = _rowHeight + _intercellSpacing.height,
                totalHeight = _CGRectGetMaxY(aRect);

            while (rowY < totalHeight)
            {
                rowY += rowHeight;

                CGContextMoveToPoint(context, minX, rowY);
                CGContextAddLineToPoint(context, maxX, rowY);
            }
        }
    }

    if (gridStyleMask & CPTableViewSolidVerticalGridLineMask)
    {
        var exposedColumnIndexes = [self columnIndexesInRect:aRect],
            columnsArray = [];

        [exposedColumnIndexes getIndexes:columnsArray maxCount:-1 inIndexRange:nil];

        var columnArrayIndex = 0,
            columnArrayCount = columnsArray.length,
            minY = _CGRectGetMinY(aRect),
            maxY = _CGRectGetMaxY(aRect);


        for (; columnArrayIndex < columnArrayCount; ++columnArrayIndex)
        {
            var columnRect = [self rectOfColumn:columnsArray[columnArrayIndex]],
                columnX = _CGRectGetMaxX(columnRect) + 0.5;

            CGContextMoveToPoint(context, columnX, minY);
            CGContextAddLineToPoint(context, columnX, maxY);
        }
    }

    CGContextClosePath(context);
    CGContextSetStrokeColor(context, _gridColor);
    CGContextStrokePath(context);
}


- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    // FIXME: This color thingy is terrible probably.
    if ([self selectionHighlightStyle] === CPTableViewSelectionHighlightStyleSourceList)
        [[CPColor selectionColorSourceView] setFill];
    else
       [[CPColor selectionColor] setFill];

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        indexes = [],
        rectSelector = @selector(rectOfRow:);

	   [_selectionHightlightColor setFill];


    if ([_selectedRowIndexes count] >= 1)
    {
        var exposedRows = [CPIndexSet indexSetWithIndexesInRange:[self rowsInRect:aRect]],
            firstRow = [exposedRows firstIndex],
            exposedRange = CPMakeRange(firstRow, [exposedRows lastIndex] - firstRow + 1);

        [_selectedRowIndexes getIndexes:indexes maxCount:-1 inIndexRange:exposedRange];
    }

    else if ([_selectedColumnIndexes count] >= 1)
    {
        rectSelector = @selector(rectOfColumn:);

        var exposedColumns = [self columnIndexesInRect:aRect],
            firstColumn = [exposedColumns firstIndex],
            exposedRange = CPMakeRange(firstColumn, [exposedColumns lastIndex] - firstColumn + 1);

        [_selectedColumnIndexes getIndexes:indexes maxCount:-1 inIndexRange:exposedRange];
    }

    var count = [indexes count];

    if (!count)
        return;

    var count2 = count;

    CGContextBeginPath(context);

    while (count--)
        CGContextAddRect(context, CGRectIntersection(objj_msgSend(self, rectSelector, indexes[count]), aRect));

    CGContextClosePath(context);
    CGContextFillPath(context);

    CGContextBeginPath(context);
    gridStyleMask = [self gridStyleMask];
    for(var i=0; i < count2-1; i++)
    {
         var rect = [self rectOfRow:indexes[i]],
             minX = _CGRectGetMinX(rect) - 0.5,
             maxX = _CGRectGetMaxX(rect) - 0.5,
             minY = _CGRectGetMinY(rect) - 0.5,
             maxY = _CGRectGetMaxY(rect) - 0.5;

        //FIX ME: if there are vertical lines we need to make them white too...
        /*if (gridStyleMask & CPTableViewSolidVerticalGridLineMask)
        {
            var exposedColumns = [self columnIndexesInRect:aRect],
                columnIndexes = [],
                exposedColumns2 = CPMakeRange([exposedColumns firstIndex], [exposedColumns lastIndex] - firstColumn + 1);
                [exposedColumns getIndexes:columnIndexes maxCount:-1 inIndexRange:exposedColumns2],
                columnCount = [exposedColumns count];

            for(var c = 0; c < columnCount - 1; c++)
            {
                var colRect = [self rectOfColumn:columnIndexes[c]],
                    colX = _CGRectGetMaxX(rect) - 0.5;
                console.log("colX");
                CGContextMoveToPoint(context, colX, minY);
                CGContextAddLineToPoint(context, colX, maxY);
            }

        }*/

         CGContextMoveToPoint(context, minX, maxY);
         CGContextAddLineToPoint(context, maxX, maxY);
    }

    CGContextClosePath(context);
    CGContextSetStrokeColor(context, [CPColor whiteColor]);
    CGContextStrokePath(context);
}

- (void)layoutSubviews
{
    [self load];
}

- (void)viewWillMoveToSuperview:(CPView)aView
{
    var superview = [self superview],
        defaultCenter = [CPNotificationCenter defaultCenter];

    if (superview)
    {
        [defaultCenter
            removeObserver:self
                      name:CPViewFrameDidChangeNotification
                    object:superview];

        [defaultCenter
            removeObserver:self
                      name:CPViewBoundsDidChangeNotification
                    object:superview];
    }

    if (aView)
    {
        [aView setPostsFrameChangedNotifications:YES];
        [aView setPostsBoundsChangedNotifications:YES];

        [defaultCenter
            addObserver:self
               selector:@selector(superviewFrameChanged:)
                   name:CPViewFrameDidChangeNotification
                 object:aView];

        [defaultCenter
            addObserver:self
               selector:@selector(superviewBoundsChanged:)
                   name:CPViewBoundsDidChangeNotification
                 object:aView];
    }
}

- (void)superviewBoundsChanged:(CPNotification)aNotification
{
    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (void)superviewFrameChanged:(CPNotification)aNotification
{
    [self tile];
}

//

/*
    var type = [anEvent type],
        point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        currentRow = MAX(0, MIN(_numberOfRows-1, [self _rowAtY:point.y]));

*/

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

/* ignore */
- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var row = [self rowAtPoint:aPoint];

    //if the user clicks outside a row then deslect everything
    if (row < 0 && _allowsEmptySelection)
        [self selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];

    [self _noteSelectionIsChanging];

    if ([self mouseDownFlags] & CPShiftKeyMask)
        _selectionAnchorRow = (ABS([_selectedRowIndexes firstIndex] - row) < ABS([_selectedRowIndexes lastIndex] - row)) ?
            [_selectedRowIndexes firstIndex] : [_selectedRowIndexes lastIndex];
    else
        _selectionAnchorRow = row;



    if (_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_) {
        _startTrackingPoint = aPoint;
        _startTrackingTimestamp = new Date();
        _trackingPointMovedOutOfClickSlop = NO;
    }

    // if the table has drag support then we use mouseUp to select a single row.
    // otherwise it uses mouse down.
    if(!(_implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_))
    {
        _previouslySelectedRowIndexes = nil;
        [self _updateSelectionWithMouseAtRow:row];
    }

    [[self window] makeFirstResponder:self];
    return YES;
}

/* ignore */
- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{

    var row = [self rowAtPoint:aPoint];


    // begin the drag is the datasource lets us, we've move at least +-3px vertical or horizontal, or we're dragging from selected rows and we haven't begun a drag session
    if
    (
        !_isSelectingSession &&
        (_implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_) &&
        (
            (lastPoint.x - aPoint.x > 3 || (_verticalMotionCanDrag && ABS(lastPoint.y - aPoint.y) > 3))
            || ([_selectedRowIndexes containsIndex:row])
        )
    )
    {
        if([_selectedRowIndexes containsIndex:row])
            _draggedRowIndexes = [[CPIndexSet alloc] initWithIndexSet:_selectedRowIndexes];
        else
            _draggedRowIndexes = [CPIndexSet indexSetWithIndex:row];


        //ask the datasource for the data
        var pboard = [CPPasteboard pasteboardWithName:CPDragPboard];

        if([self canDragRowsWithIndexes:_draggedRowIndexes atPoint:aPoint] && [_dataSource tableView:self writeRowsWithIndexes:_draggedRowIndexes toPasteboard:pboard])
        {
			var currentEvent = [CPApp currentEvent],
				offset = CPPointMakeZero();
				
			// We deviate from the default Cocoa implementation here by asking for a view in stead of an image
			// We support both, but the view prefered over the image because we can mimic the rows we are dragging
			// by re-creating the data views for the dragged rows
			var view = [self dragViewForRowsWithIndexes:_draggedRowIndexes 
										   tableColumns:_exposedColumns 
												  event:currentEvent 
												 offset:CPPointMakeZero()];
			
			if (!view) {
				var image = [self dragImageForRowsWithIndexes:_draggedRowIndexes 
												 tableColumns:_exposedColumns 
														event:currentEvent 
													   offset:CPPointMakeZero()];
				
				view = [[CPImageView alloc] initWithFrame:CPMakeRect(aPoint.x, aPoint.y, [image size].width, [image size].height)];
				[view setImage:image];
				
				offset = aPoint;
			}
			
			[self dragView:view at:offset offset:CPPointMakeZero() event:[CPApp currentEvent] pasteboard:pboard source:self slideBack:YES];
            return NO;
        }
    }

    _isSelectingSession = YES;
    [self _updateSelectionWithMouseAtRow:row];
    [self _updateSelectionWithMouseAtRow:[self rowAtPoint:aPoint]];

    if ((_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
        && !_trackingPointMovedOutOfClickSlop)
    {
        var CLICK_SPACE_DELTA = 5.0; // Stolen from AppKit/Platform/DOM/CPPlatformWindow+DOM.j
        if (ABS(aPoint.x - _startTrackingPoint.x) > CLICK_SPACE_DELTA
            || ABS(aPoint.y - _startTrackingPoint.y) > CLICK_SPACE_DELTA)
        {
            _trackingPointMovedOutOfClickSlop = YES;
        }
    }

    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    _isSelectingSession = NO;

    var CLICK_TIME_DELTA = 1000,
        columnIndex,
        column,
        rowIndex,
        shouldEdit = YES;

    if(_implementedDataSourceMethods & CPTableViewDataSource_tableView_writeRowsWithIndexes_toPasteboard_)
    {
        rowIndex = [self rowAtPoint:aPoint];
        if (rowIndex !== -1)
        {
            if(_draggedRowIndexes !== nil)
            {
                _draggedRowIndexes = nil;
                return;
            }
            // if the table has drag support then we use mouseUp to select a single row.
            _previouslySelectedRowIndexes = nil;
            [self _updateSelectionWithMouseAtRow:rowIndex];
        }
    }

    if (![_previouslySelectedRowIndexes isEqualToIndexSet:_selectedRowIndexes])
        [self _noteSelectionDidChange];


    if (mouseIsUp
        && (_implementedDataSourceMethods & CPTableViewDataSource_tableView_setObjectValue_forTableColumn_row_)
        && !_trackingPointMovedOutOfClickSlop
        && ([[CPApp currentEvent] clickCount] > 1))
    {
        columnIndex = [self columnAtPoint:lastPoint];
        if (columnIndex !== -1)
        {
            column = _tableColumns[columnIndex];
            if ([column isEditable])
            {
                rowIndex = [self rowAtPoint:aPoint];
                if (rowIndex !== -1)
                {

                    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldEditTableColumn_row_)
                        shouldEdit = [_delegate tableView:self shouldEditTableColumn:column row:rowIndex];
                    if (shouldEdit)
                    {
                        _editingCellIndex = CGPointMake(columnIndex, rowIndex);
                        [self reloadDataForRowIndexes:[CPIndexSet indexSetWithIndex:rowIndex]
                            columnIndexes:[CPIndexSet indexSetWithIndex:columnIndex]];

                        return;
                    }
                }
            }
        }

    } //end of editing conditional

    //double click actions
    if([[CPApp currentEvent] clickCount] === 2 && _doubleAction && _target)
        [self sendAction:_doubleAction to:_target];
}

/*
    @ignore
*/
- (CPDragOperation)draggingEntered:(id)sender
{
    var dropOperation = [self _proposedDropOperation],
        draggingLocation = [sender draggingLocation],
        row;

    var location = [self convertPoint:draggingLocation fromView:nil];

    row = [self _proposedRowAtPoint:location];
    
    if(_retargetedDropRow !== nil)
        row = _retargetedDropRow;
    
    var draggedTypes = [self registeredDraggedTypes], 
        count = [draggedTypes count],
        i;
        
    for (i = 0; i < count; i++) 
    { 
        if ([[[sender draggingPasteboard] types] containsObject:[draggedTypes objectAtIndex: i]]) 
            return [self _validateDrop:sender proposedRow:row proposedDropOperation:dropOperation]; 
    }
    
    return CPDragOperationNone;
}

/*
    @ignore
*/
- (void)draggingExited:(id)sender
{
    [_dropOperationFeedbackView setHidden:YES];
}

/*
    @ignore
*/
- (void)draggingEnded:(id)sender
{
    [self _draggingEnded];
}

- (void)_draggingEnded
{
    _retargetedDropOperation = nil;
    _retargetedDropRow = nil;
    _draggedRowIndexes = [CPIndexSet indexSet];
    [_dropOperationFeedbackView setHidden:YES];
}
/*
    @ignore
*/
- (BOOL)wantsPeriodicDraggingUpdates
{
    return YES;
}

/*
    @ignore
*/
- (CPTableViewDropOperation)_proposedDropOperation
{
    //check is something is forced...
    // otherwise we use the above action by default
    if(_retargetedDropOperation !== nil)
        return _retargetedDropOperation;
    else
        return CPTableViewDropAbove;
}

/*
    @ignore
*/
- (CPInteger)_proposedRowAtPoint:(CGPoint)dragPoint
{
    var numberOfRows = [self numberOfRows],
        row;
    // cocoa seems to jump to the next row when we approach the below row
    dragPoint.y += FLOOR(_rowHeight/4);
    
    if (dragPoint.y > numberOfRows * (_rowHeight + _intercellSpacing.height))
    {
        if ([self _proposedDropOperation] === CPTableViewDropAbove) 
            row = numberOfRows;
        else
            row = numberOfRows - 1;
    }
    else
        row = [self rowAtPoint:dragPoint];
    
    return row;
}

- (void)_validateDrop:(id)info proposedRow:(CPInteger)row proposedDropOperation:(CPTableViewDropOperation)dropOperation
{
    if(_implementedDataSourceMethods & CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_)
        return [_dataSource tableView:self validateDrop:info proposedRow:row proposedDropOperation:dropOperation];

    return CPDragOperationNone;
}

- (CPDragOperation)draggingUpdated:(id)sender
{
    var dropOperation = [self _proposedDropOperation],
        numberOfRows = [self numberOfRows],
        draggingLocation = [sender draggingLocation],
        dragOperation,
        row;

    var location = [self convertPoint:draggingLocation fromView:nil];

    row = [self _proposedRowAtPoint:location];
    dragOperation = [self _validateDrop:sender proposedRow:row proposedDropOperation:dropOperation];
    
    if(_retargetedDropRow !== nil)
        row = _retargetedDropRow;

    //if the user forces -1 then we should highlight the whole tabelview
    var rowRect;
    if(_retargetedDropRow === -1)
        rowRect = [self exposedClipRect];
    else
        rowRect = [self rectOfRow:row];
    
    var exposedClipRect = [self exposedClipRect];
    var visibleWidth = _CGRectGetWidth(exposedClipRect);

    rowRect = _CGRectMake(_CGRectGetMinX(exposedClipRect), rowRect.origin.y, visibleWidth, rowRect.size.height);

    [_dropOperationFeedbackView setDropOperation:dropOperation];
    [_dropOperationFeedbackView setHidden:(dragOperation == CPDragOperationNone)];
    [_dropOperationFeedbackView setFrame:rowRect];
    [_dropOperationFeedbackView setCurrentRow:row];
    [self addSubview:_dropOperationFeedbackView];
    
    // FIXME : Maybe we should do this in a timer outside this method. Problem: we don't know when the scroll ends and neighter when the next -draggingUpdated is called. Which one will come first ?
    if (row > 0 && location.y - CGRectGetMinY(exposedClipRect) < _rowHeight)
        [self scrollRowToVisible:row - 1];
    else if (row < numberOfRows && CGRectGetMaxY(exposedClipRect) - location.y < _rowHeight)
        [self scrollRowToVisible:row + 1];
        
    return dragOperation;
}

/*
    @ignore
*/
- (BOOL)prepareForDragOperation:(id)sender
{
    // FIX ME: is there anything else that needs to happen here?
    // actual validation is called in dragginUpdated:
    [_dropOperationFeedbackView setHidden:YES];

    return (_implementedDataSourceMethods & CPTableViewDataSource_tableView_validateDrop_proposedRow_proposedDropOperation_);
}

/*
    @ignore
*/
- (BOOL)performDragOperation:(id)sender
{
    var operation = [self _proposedDropOperation],
        draggingLocation = [sender draggingLocation];

    var location = [self convertPoint:draggingLocation fromView:nil];

    if(_retargetedDropRow !== nil)
        var row = _retargetedDropRow;
    else
        var row = [self rowAtPoint:location] - 1;

    return [_dataSource tableView:self acceptDrop:sender row:row dropOperation:operation];
}

/*
    @ignore
*/
- (void)concludeDragOperation:(id)sender
{
    [self reloadData];
}

/*
    //this method is sent to the data source for conviences...
*/
- (void)draggedImage:(CPImage)anImage endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    if([_dataSource respondsToSelector:@selector(tableView:didEndDraggedImage:atPosition:operation:)])
        [_dataSource tableView:self didEndDraggedImage:anImage atPosition:aLocation operation:anOperation];
}

/*
    @ignore
    we're using this because we drag views instead of images so we can get the rows themselves to actually drag
*/
- (void)draggedView:(CPImage)aView endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{   
    [self _draggingEnded];
    [self draggedImage:aView endedAt:aLocation operation:anOperation];
}

- (void)_updateSelectionWithMouseAtRow:(CPInteger)aRow
{

    //check to make sure the row exists
    if(aRow < 0)
        return;

    // If cmd/ctrl was held down XOR the old selection with the proposed selection
    if ([self mouseDownFlags] & (CPCommandKeyMask | CPControlKeyMask | CPAlternateKeyMask))
    {
        if ([_selectedRowIndexes containsIndex:aRow])
        {
            newSelection = [_selectedRowIndexes copy];

            [newSelection removeIndex:aRow];
        }

        else if (_allowsMultipleSelection)
        {
            newSelection = [_selectedRowIndexes copy];

            [newSelection addIndex:aRow];
        }

        else
            newSelection = [CPIndexSet indexSetWithIndex:aRow];
    }

    else if (_allowsMultipleSelection)
        newSelection = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(MIN(aRow, _selectionAnchorRow), ABS(aRow - _selectionAnchorRow) + 1)];

    else if (aRow >= 0 && aRow < _numberOfRows)
        newSelection = [CPIndexSet indexSetWithIndex:aRow];

    else
        newSelection = [CPIndexSet indexSet];

    if ([newSelection isEqualToIndexSet:_selectedRowIndexes])
        return;

    if (_implementedDelegateMethods & CPTableViewDelegate_selectionShouldChangeInTableView_ &&
        ![_delegate selectionShouldChangeInTableView:self])
        return;

    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_selectionIndexesForProposedSelection_)
        newSelection = [_delegate tableView:self selectionIndexesForProposedSelection:newSelection];

    if (_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_)
    {
        var indexArray = [];

        [newSelection getIndexes:indexArray maxCount:-1 inIndexRange:nil];

        var indexCount = indexArray.length;

        while (indexCount--)
        {
            var index = indexArray[indexCount];

            if (![_delegate tableView:self shouldSelectRow:index])
                [newSelection removeIndex:index];
        }
    }

    // if empty selection is not allowed and the new selection has nothing selected, abort
    if (!_allowsEmptySelection && [newSelection count] === 0)
        return;

    if ([newSelection isEqualToIndexSet:_selectedRowIndexes])
        return;

    if (!_previouslySelectedRowIndexes)
        _previouslySelectedRowIndexes = [_selectedRowIndexes copy];

    [self selectRowIndexes:newSelection byExtendingSelection:NO];

    [self _noteSelectionIsChanging];

}

- (void)_noteSelectionIsChanging
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];
}

- (void)_noteSelectionDidChange
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionDidChangeNotification
                      object:self
                    userInfo:nil];
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(CPEvent)anEvent
{
    [self interpretKeyEvents:[CPArray arrayWithObject:anEvent]];
}

- (void)moveDown:(id)sender
{
    var anEvent = [CPApp currentEvent];
    if([[self selectedRowIndexes] count] > 0)
    {
       var extend = NO;

       if(([anEvent modifierFlags] & CPShiftKeyMask) && _allowsMultipleSelection)
           extend = YES;

        var i = [[self selectedRowIndexes] lastIndex];
        if(i<[self numberOfRows] - 1)
            i++; //set index to the next row after the last row selected
    }
    else
    {
        var extend = NO;
        //no rows are currently selected
        if([self numberOfRows] > 0)
            var i = 0; //select the first row
    }


    if(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_)
    {

        while((![_delegate tableView:self shouldSelectRow:i]) && i<[self numberOfRows])
        {
            //check to see if the row can be selected if it can't be then see if the next row can be selected
            i++;
        }

        //if the index still can be selected after the loop then just return
         if(![_delegate tableView:self shouldSelectRow:i])
             return;
    }

    [self selectRowIndexes:[CPIndexSet indexSetWithIndex:i] byExtendingSelection:extend];

    if(i)
    {
        [self scrollRowToVisible:i];
        [self _noteSelectionDidChange];
    }
}

- (void)moveUp:(id)sender
{
    var anEvent = [CPApp currentEvent];
    if([[self selectedRowIndexes] count] > 0)
	{
         var extend = NO;
    
         if(([anEvent modifierFlags] & CPShiftKeyMask) && _allowsMultipleSelection)
           extend = YES;
    
          var i = [[self selectedRowIndexes] firstIndex];
          if(i > 0)
              i--; //set index to the prev row before the first row selected
    }
    else
    {
      var extend = NO;
      //no rows are currently selected
        if([self numberOfRows] > 0)
            var i = [self numberOfRows] - 1; //select the first row
     }
    
    
     if(_implementedDelegateMethods & CPTableViewDelegate_tableView_shouldSelectRow_)
     {
    
          while((![_delegate tableView:self shouldSelectRow:i]) && i > 0)
          {
              //check to see if the row can be selected if it can't be then see if the prev row can be selected
              i--;
          }
    
          //if the index still can be selected after the loop then just return
           if(![_delegate tableView:self shouldSelectRow:i])
               return;
     }
    
     [self selectRowIndexes:[CPIndexSet indexSetWithIndex:i] byExtendingSelection:extend];
    
     if(i)
     {
        [self scrollRowToVisible:i];
        [self _noteSelectionDidChange];
     }
}

- (void)deleteBackward:(id)sender
{
    if([_delegate respondsToSelector: @selector(tableViewDeleteKeyPressed:)])
        [_delegate tableViewDeleteKeyPressed:self];
}

@end

var CPTableViewDataSourceKey        = @"CPTableViewDataSourceKey",
    CPTableViewDelegateKey          = @"CPTableViewDelegateKey",
    CPTableViewHeaderViewKey        = @"CPTableViewHeaderViewKey",
    CPTableViewTableColumnsKey      = @"CPTableViewTableColumnsKey",
    CPTableViewRowHeightKey         = @"CPTableViewRowHeightKey",
    CPTableViewIntercellSpacingKey  = @"CPTableViewIntercellSpacingKey",
    CPTableViewMultipleSelectionKey = @"CPTableViewMultipleSelectionKey",
    CPTableViewEmptySelectionKey    = @"CPTableViewEmptySelectionKey";

@implementation CPTableView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        //Configuring Behavior
        _allowsColumnReordering = YES;
        _allowsColumnResizing = YES;
        _allowsMultipleSelection = [aCoder decodeBoolForKey:CPTableViewMultipleSelectionKey];
        _allowsEmptySelection = [aCoder decodeBoolForKey:CPTableViewEmptySelectionKey];
        _allowsColumnSelection = NO;

        _tableViewFlags = 0;

        //Setting Display Attributes
        _selectionHighlightMask = CPTableViewSelectionHighlightStyleRegular;

        [self setUsesAlternatingRowBackgroundColors:NO];
        [self setAlternatingRowBackgroundColors:[[CPColor whiteColor], [CPColor colorWithHexString:@"e4e7ff"]]];

        _tableColumns = [aCoder decodeObjectForKey:CPTableViewTableColumnsKey];
        [_tableColumns makeObjectsPerformSelector:@selector(setTableView:) withObject:self];

        _tableColumnRanges = [];
        _dirtyTableColumnRangeIndex = 0;
        _numberOfHiddenColumns = 0;

        _objectValues = { };
        _dataViewsForTableColumns = { };
        _dataViews=  [];
        _numberOfRows = 0;
        _exposedRows = [CPIndexSet indexSet];
        _exposedColumns = [CPIndexSet indexSet];
        _cachedDataViews = { };
        _rowHeight = [aCoder decodeFloatForKey:CPTableViewRowHeightKey];
        _intercellSpacing = [aCoder decodeSizeForKey:CPTableViewIntercellSpacingKey];

        _selectionHightlightColor = [CPColor selectionColor];

        [self setGridColor:[CPColor grayColor]];
        [self setGridStyleMask:CPTableViewGridNone];

        _headerView = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self bounds].size.width, _rowHeight)];

        [_headerView setTableView:self];

        _cornerView = [[_CPCornerView alloc] initWithFrame:CGRectMake(0, 0, [CPScroller scrollerWidth], CGRectGetHeight([_headerView frame]))];

        _selectedColumnIndexes = [CPIndexSet indexSet];
        _selectedRowIndexes = [CPIndexSet indexSet];

        [self setDataSource:[aCoder decodeObjectForKey:CPTableViewDataSourceKey]];
        [self setDelegate:[aCoder decodeObjectForKey:CPTableViewDelegateKey]];

        _tableDrawView = [[_CPTableDrawView alloc] initWithTableView:self];
        [_tableDrawView setBackgroundColor:[CPColor clearColor]];
        [self addSubview:_tableDrawView];

        [self viewWillMoveToSuperview:[self superview]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_dataSource forKey:CPTableViewDataSourceKey];
    [aCoder encodeObject:_delegate forKey:CPTableViewDelegateKey];

    [aCoder encodeFloat:_rowHeight forKey:CPTableViewRowHeightKey];
    [aCoder encodeSize:_intercellSpacing forKey:CPTableViewIntercellSpacingKey];

    [aCoder encodeBool:_allowsMultipleSelection forKey:CPTableViewMultipleSelectionKey];
    [aCoder encodeBool:_allowsEmptySelection forKey:CPTableViewEmptySelectionKey];

    [aCoder encodeObject:_tableColumns forKey:CPTableViewTableColumnsKey];
}

@end

@implementation CPColor (tableview)

+ (CPColor)selectionColor
{
    return [CPColor colorWithHexString:@"5f83b9"];
}

+ (CPColor)selectionColorSourceView
{
    return [CPColor colorWithPatternImage:[[CPImage alloc] initByReferencingFile:@"Resources/tableviewselection.png" size:CGSizeMake(6,22)]];
}

@end

@implementation CPIndexSet (tableview)

- (void)removeMatches:otherSet
{
    var firstindex = [self firstIndex];
    var index = MIN(firstindex,[otherSet firstIndex]);
    var switchFlag = (index == firstindex);
    while(index != CPNotFound)
    {
        var indexSet = (switchFlag) ? otherSet : self;
        otherIndex = [indexSet indexGreaterThanOrEqualToIndex:index];
        if (otherIndex == index)
        {
            [self removeIndex:index];
            [otherSet removeIndex:index];
        }
        index = otherIndex;
        switchFlag = !switchFlag;
    }
}

@end

@implementation _dropOperationDrawingView : CPView
{
    unsigned    dropOperation @accessors;
    CPTableView tableView @accessors;
    int         currentRow @accessors;
}

- (void)drawRect:(CGRect)aRect
{
    if(tableView._destinationDragStyle === CPTableViewDraggingDestinationFeedbackStyleNone)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"4886ca"]);
    CGContextSetLineWidth(context, 3);

    if(dropOperation === CPTableViewDropOn)
    {
        //if row is selected don't fill and stroke white
        var selectedRows = [tableView selectedRowIndexes];
        var newRect = _CGRectMake(aRect.origin.x + 2, aRect.origin.y + 2, aRect.size.width - 4, aRect.size.height - 5);
        if([selectedRows containsIndex:currentRow])
        {
            CGContextSetLineWidth(context, 2);
            CGContextSetStrokeColor(context, [CPColor whiteColor]);
        }
        else
        {
            CGContextSetFillColor(context, [CPColor colorWithRed:72/255 green:134/255 blue:202/255 alpha:0.25]);
            CGContextFillRoundedRectangleInRect(context, newRect, 8, YES, YES, YES, YES);
        }
        CGContextStrokeRoundedRectangleInRect(context, newRect, 8, YES, YES, YES, YES);

    }


    if(dropOperation === CPTableViewDropAbove)
    {


        //reposition the view up a tad
        [self setFrameOrigin:CGPointMake(_frame.origin.x, _frame.origin.y - 8)];

        var selectedRows = [tableView selectedRowIndexes];

        if([selectedRows containsIndex:currentRow - 1] || [selectedRows containsIndex:currentRow])
        {
            CGContextSetStrokeColor(context, [CPColor whiteColor]);
            CGContextSetLineWidth(context, 4);
            //draw the circle thing
            CGContextStrokeEllipseInRect(context, _CGRectMake(aRect.origin.x + 4, aRect.origin.y + 4, 8, 8));
            //then draw the line
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, 10, aRect.origin.y + 8);
            CGContextAddLineToPoint(context, aRect.size.width - aRect.origin.y - 8, aRect.origin.y + 8);
            CGContextClosePath(context);
            CGContextStrokePath(context);

            CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"4886ca"]);
            CGContextSetLineWidth(context, 3);
        }

        //draw the circle thing
        CGContextStrokeEllipseInRect(context, _CGRectMake(aRect.origin.x + 4, aRect.origin.y + 4, 8, 8));
        //then draw the line
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 10, aRect.origin.y + 8);
        CGContextAddLineToPoint(context, aRect.size.width - aRect.origin.y - 8, aRect.origin.y + 8);
        CGContextClosePath(context);
        CGContextStrokePath(context);
        //CGContextStrokeLineSegments(context, [aRect.origin.x + 8,  aRect.origin.y + 8, 300 , aRect.origin.y + 8]);
    }
}
@end

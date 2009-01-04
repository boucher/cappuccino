/*
 * NSSegmentedControl.j
 * nib2cib
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
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

@import <AppKit/CPSegmentedControl.j>

@import "NSSegmentedControl.j"


@implementation CPSegmentedControl (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        var cell = [aCoder decodeObjectForKey:"NSCell"];
        
        _segments           = [cell segments];
        _selectedSegment    = [cell selectedSegment];
        _segmentStyle       = [cell segmentStyle];
        _trackingMode       = [cell trackingMode];
    }
    
    return self;
}

@end

@implementation NSSegmentedControl : CPSegmentedControl
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSegmentedControl class];
}

@end

@implementation NSSegmentedCell : NSActionCell
{
    CPArray                 _segments           @accessors(readonly, getter=segments);
    int                     _selectedSegment    @accessors(readonly, getter=selectedSegment);
    int                     _segmentStyle       @accessors(readonly, getter=segmentStyle);
    CPSegmentSwitchTracking _trackingMode       @accessors(readonly, getter=trackingMode);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _segments           = [aCoder decodeObjectForKey:"NSSegmentImages"];
        _selectedSegment    = [aCoder decodeIntForKey:"NSSelectedSegment"];
        _segmentStyle       = [aCoder decodeIntForKey:"NSSegmentStyle"];
        _trackingMode       = [aCoder decodeIntForKey:"NSTrackingMode"];
        
        
    }
    
    return self;
}

@end


@implementation _CPSegmentItem (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        image       = [aCoder decodeObjectForKey:"NSSegmentItemImage"];
        label       = [aCoder decodeObjectForKey:"NSSegmentItemLabel"];
        menu        = [aCoder decodeObjectForKey:"NSSegmentItemMenu"];
        selected    = [aCoder decodeBoolForKey:"NSSegmentItemSelected"];
        enabled     = ![aCoder decodeBoolForKey:"NSSegmentItemDisabled"];
        tag         = [aCoder decodeIntForKey:"NSSegmentItemTag"];
        
        // NSSegmentItemImageScaling
        // NSSegmentItemTooltip
    }
    
    return self;
}

@end

@implementation NSSegmentItem : _CPSegmentItem
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPSegmentItem class];
}

@end


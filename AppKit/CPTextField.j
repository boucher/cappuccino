
/*
 * CPTextField.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
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

@import "CPControl.j"
@import "CPStringDrawing.j"

#include "CoreGraphics/CGGeometry.j"
#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"


/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByWordWrapping       = 0;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByCharWrapping       = 1;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByClipping           = 2;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByTruncatingHead     = 3;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByTruncatingTail     = 4;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByTruncatingMiddle   = 5;

/*
    A textfield bezel with a squared corners.
	@global
	@group CPTextFieldBezelStyle
*/
CPTextFieldSquareBezel          = 0;
/*
    A textfield bezel with rounded corners.
	@global
	@group CPTextFieldBezelStyle
*/
CPTextFieldRoundedBezel         = 1;


#if PLATFORM(DOM)
var CPTextFieldDOMInputElement = nil;
#endif

@implementation CPString (CPTextFieldAdditions)

/*!
    Returns the string (<code>self</code>).
*/
- (CPString)string
{
    return self;
}

@end

CPTextFieldStateRounded = 1 << 12;

/*!
    This control displays editable text in a Cappuccino application.
*/
@implementation CPTextField : CPControl
{
    BOOL                    _isEditable;
    BOOL                    _isSelectable;

    BOOL                    _drawsBackground;
    
    CPColor                 _textFieldBackgroundColor;
    
    id                      _placeholderString;
    
    id                      _delegate;
    
    CPString                _textDidChangeValue;

    // NS-style Display Properties
    CPTextFieldBezelStyle   _bezelStyle;
    BOOL                    _isBordered;
    CPControlSize           _controlSize;
}

+ (id)themedAttributes
{
    return [CPDictionary dictionaryWithObjects:[_CGInsetMakeZero(), _CGInsetMake(2.0, 2.0, 2.0, 2.0), _CGInsetMake(2.0, 2.0, 2.0, 2.0), nil]
                                       forKeys:[@"bezel-inset", @"content-inset", @"bezeled-content-inset", @"bezel-color"]];
}

/* @ignore */
#if PLATFORM(DOM)
+ (DOMElement)_inputElement
{
    if (!CPTextFieldDOMInputElement)
    {
         CPTextFieldDOMInputElement = document.createElement("input");
         CPTextFieldDOMInputElement.style.position = "absolute";
         CPTextFieldDOMInputElement.style.top = "0px";
         CPTextFieldDOMInputElement.style.left = "0px";
         CPTextFieldDOMInputElement.style.width = "100%"
         CPTextFieldDOMInputElement.style.height = "100%";
         CPTextFieldDOMInputElement.style.border = "0px";
         CPTextFieldDOMInputElement.style.padding = "0px";
         CPTextFieldDOMInputElement.style.whiteSpace = "pre";
         CPTextFieldDOMInputElement.style.background = "transparent";
         CPTextFieldDOMInputElement.style.outline = "none";
         CPTextFieldDOMInputElement.style.paddingLeft = HORIZONTAL_PADDING - 1.0 + "px";
         CPTextFieldDOMInputElement.style.paddingTop = TOP_PADDING - 2.0 + "px";
    }

    return CPTextFieldDOMInputElement;
}
#endif

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _value = "";
        _placeholderString = "";

        _sendActionOn = CPKeyUpMask | CPKeyDownMask;

/*        
#if PLATFORM(DOM)
        _DOMTextElement = document.createElement("div");
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.top = TOP_PADDING + "px";
        if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
        {
            _DOMTextElement.style.left = ROUNDEDBEZEL_HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(aFrame) - 2.0 * ROUNDEDBEZEL_HORIZONTAL_PADDING - 2.0) + "px";
        }
        else
        {
            _DOMTextElement.style.left = HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(aFrame) - 2.0 * HORIZONTAL_PADDING) + "px";
        }
        _DOMTextElement.style.height = MAX(0.0, CGRectGetHeight(aFrame) - TOP_PADDING - BOTTOM_PADDING) + "px";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        _DOMTextElement.style.zIndex = 100;
        _DOMTextElement.style.overflow = "hidden";

        _DOMElement.appendChild(_DOMTextElement);
#endif
*/
        [self setValue:CPLeftTextAlignment forThemedAttributeName:@"alignment"];
    }
    
    return self;
}

#pragma mark Controlling Editability and Selectability

/*! 
    Sets whether or not the receiver text field can be edited
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

/*!
    Returns <code>YES</code> if the textfield is currently editable by the user.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

/*!
    Sets whether the field's text is selectable by the user.
    @param aFlag <code>YES</code> makes the text selectable
*/
- (void)setSelectable:(BOOL)aFlag
{
    _isSelectable = aFlag;
}

/*!
    Returns <code>YES</code> if the field's text is selectable by the user.
*/
- (BOOL)isSelectable
{
    return _isSelectable;
}

// Setting the Bezel Style
/*!
    Sets whether the textfield will have a bezeled border.
    @param shouldBeBezeled <code>YES</code> means the textfield will draw a bezeled border
*/
- (void)setBezeled:(BOOL)shouldBeBezeled
{
    if ((!!(_controlState & CPControlStateBezeled)) === shouldBeBezeled)
        return;
    
    if (shouldBeBezeled)
        _controlState |= CPControlStateBezeled;
    else
        _controlState &= ~CPControlStateBezeled;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns <code>YES</code> if the textfield draws a bezeled border.
*/
- (BOOL)isBezeled
{
    return !!(_controlState & CPControlStateBezeled);
}

/*!
    Sets the textfield's bezel style.
    @param aBezelStyle the constant for the desired bezel style
*/
- (void)setBezelStyle:(CPTextFieldBezelStyle)aBezelStyle
{
    var shouldBeRounded = aBezelStyle === CPTextFieldRoundedBezel;
    
    if ((!!(_controlState & CPTextFieldStateRounded)) === shouldBeRounded)
        return;
    
    if (shouldBeRounded)
        _controlState |= CPTextFieldStateRounded;
    else
        _controlState &= ~CPTextFieldStateRounded;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the textfield's bezel style.
*/
- (CPTextFieldBezelStyle)bezelStyle
{
    if (_controlState & CPTextFieldStateRounded)
        return CPTextFieldRoundedBezel;

    return CPTextFieldSquareBezel;
}

/*!
    Sets whether the textfield will have a border drawn.
    @param shouldBeBordered <code>YES</code> makes the textfield draw a border
*/
- (void)setBordered:(BOOL)shouldBeBordered
{
    if ((!!(_controlState & CPControlStateBordered)) === shouldBeBordered)
        return;
    
    if (shouldBeBordered)
        _controlState |= CPControlStateBordered;
    else
        _controlState &= ~CPControlStateBordered;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns <code>YES</code> if the textfield has a border.
*/
- (BOOL)isBordered
{
    return !!(_controlState & CPControlStateBordered);
}

/*!
    Sets whether the textfield will have a background drawn.
    @param shouldDrawBackground <code>YES</code> makes the textfield draw a background
*/
- (void)setDrawsBackground:(BOOL)shouldDrawBackground
{
    if (_drawsBackground == shouldDrawBackground)
        return;
        
    _drawsBackground = shouldDrawBackground;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns <code>YES</code> if the textfield draws a background.
*/
- (BOOL)drawsBackground
{
    return _drawsBackground;
}

/*!
    Sets the background color, which is shown for non-bezeled text fields with drawsBackground set to YES
    @param aColor The background color
*/
- (void)setTextFieldBackgroundColor:(CPColor)aColor
{
    if (_textFieldBackgroundColor == aColor)
        return;
        
    _textFieldBackgroundColor = aColor;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the background color.
*/
- (CPColor)textFieldBackgroundColor
{
    return _textFieldBackgroundColor;
}

/* @ignore */
- (BOOL)acceptsFirstResponder
{
    return _isEditable && _isEnabled;
}

/* @ignore */
- (BOOL)becomeFirstResponder
{
    var string = [self stringValue];

    [self setStringValue:""];

#if PLATFORM(DOM)

    [_contentView setHidden:YES];

    var element = [[self class] _inputElement];

    element.value = "hey there hot shot";//string;
    element.style.color = _DOMElement.style.color;
    element.style.font = _DOMElement.style.font;
    element.style.zIndex = 1000;
    element.style.marginTop = "0px";
    if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
    {
        // http://cappuccino.lighthouseapp.com/projects/16499/tickets/191-cptextfield-shifts-updown-when-receiveslosts-focus
        // uncommenting the following 2 lines will solve the problem in Firefox only ...
        // element.style.paddingTop = TOP_PADDING - 0.0 + "px" ;
        // element.style.paddingLeft = HORIZONTAL_PADDING - 3.0 + "px" ;
        
        element.style.top = "0px" ;
        element.style.left = ROUNDEDBEZEL_HORIZONTAL_PADDING + 1.0 + "px" ;
        element.style.width = CGRectGetWidth([self bounds]) - (2 * ROUNDEDBEZEL_HORIZONTAL_PADDING) - 2.0 + "px";
    }
    else 
    {
        element.style.width = CGRectGetWidth([self bounds]) - 3.0 + "px";
    }

    _DOMElement.appendChild(element);
//    [anEvent _DOMEvent].
    var evt = document.createEvent("MouseEvents");
  evt.initMouseEvent("mousedown", true, true, window,
    0, 0, 0, 0, 0, false, false, false, false, 0, null);
  var canceled = !element.dispatchEvent(evt);/*
    var evt = document.createEvent("MouseEvents");
  evt.initMouseEvent("mousedown", true, true, window,
    0, 0, 0, 0, 0, false, false, false, false, 0, null);
  var canceled = !element.dispatchEvent(evt);
    var evt = document.createEvent("MouseEvents");
  evt.initMouseEvent("mousemove", true, true, window,
    1, 0, 0, 20, 0, false, false, false, false, 0, null);
  /*if(canceled) {
    // A handler called preventDefault
    alert("canceled");
  } else {
    // None of the handlers called preventDefault
    alert("not canceled");
  }*/
//    window.setTimeout(function() { element.focus(); }, 0.0);

    element.onblur = function () 
    { 
        [self setObjectValue:element.value];
        [self sendAction:[self action] to:[self target]];
        [[self window] makeFirstResponder:nil];
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
    
    //element.onblur = function() { objj_debug_print_backtrace(); }
    //element.select();
    
    element.onkeydown = function(aDOMEvent) 
    {
        //all key presses might trigger the delegate method controlTextDidChange: 
        //record the current string value before we allow this keydown to propagate
        _textDidChangeValue = [self stringValue];    
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        return true;
    }
        
    element.onkeypress = function(aDOMEvent) 
    {
        aDOMEvent = aDOMEvent || window.event;
        
        if (aDOMEvent.keyCode == 13) 
        {
            if (aDOMEvent.preventDefault)
                aDOMEvent.preventDefault(); 
            if (aDOMEvent.stopPropagation)
                aDOMEvent.stopPropagation();
            aDOMEvent.cancelBubble = true;
            
            element.blur();
        }    
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
    
    //inspect keyup to detect changes in order to trigger controlTextDidChange: delegate method
    element.onkeyup = function(aDOMEvent) 
    { 
        //check if we should fire a notification for CPControlTextDidChange
        if ([self stringValue] != _textDidChangeValue)
        {
            _textDidChangeValue = [self stringValue];

            //call to CPControls methods for posting the notification
            [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
        }    
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };

    // If current value is the placeholder value, remove it to allow user to update.
    if ([string lowercaseString] == [[self placeholderString] lowercaseString])
        element.value = "";
    
    //post CPControlTextDidBeginEditingNotification
    [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
    
    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
#endif

    return YES;
}

/* @ignore */
- (BOOL)resignFirstResponder
{
#if PLATFORM(DOM)
    var element = [[self class] _inputElement];

    //nil out dom handlers
    element.onkeyup = nil;
    element.onkeydown = nil;
    element.onkeypress = nil;
    
    _DOMElement.removeChild(element);
    [self setStringValue:element.value]; // redundant?

    // If textfield has no value, then display the placeholderValue
    if (!_value)
        [self setStringValue:[self placeholderString]];

#endif
    //post CPControlTextDidEndEditingNotification
    [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];

    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEditable])
        return [[self nextResponder] mouseDown:anEvent];

    [super mouseDown:anEvent];
}
/*
- (void)mouseUp:(CPEvent)anEvent
{    
    if (_isEditable && [[self window] firstResponder] == self)
        return;
        
    [super mouseUp:anEvent];
}
*/

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    /*
#if PLATFORM(DOM)
    if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
    {
        CPDOMDisplayServerSetStyleSize(_DOMTextElement, _frame.size.width - 2.0 * ROUNDEDBEZEL_HORIZONTAL_PADDING, _frame.size.height - TOP_PADDING - BOTTOM_PADDING);
    }
    else
    {
        CPDOMDisplayServerSetStyleSize(_DOMTextElement, _frame.size.width - 2.0 * HORIZONTAL_PADDING, _frame.size.height - TOP_PADDING - BOTTOM_PADDING);
    }
#endif
*/
}

/*!
    Returns the string the text field.
*/
- (id)objectValue
{
    // All of this needs to be better.
#if PLATFORM(DOM)
    if ([[self window] firstResponder] == self)
        return [[self class] _inputElement].value;
#endif
    //if the content is the same as the placeholder value, return "" instead
    if ([super objectValue] == [self placeholderString])
        return "";

    return [super objectValue];
}

/*
    @ignore
*/
- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];
    /*
#if PLATFORM(DOM)
    var displayString = "";

    if (aValue !== nil && aValue !== undefined)
    {
        if ([aValue respondsToSelector:@selector(string)])
            displayString = [aValue string];
        else
            displayString += aValue;
    }

    if ([[self window] firstResponder] == self)
        [[self class] _inputElement].value = displayString;

    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
        _DOMTextElement.innerText = displayString;
    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
        _DOMTextElement.textContent = displayString;
#endif
*/
}

/*!
    Sets a placeholder string for the receiver.  The placeholder is displayed until editing begins,
    and after editing ends, if the text field has an empty string value
*/
-(void)setPlaceholderString:(CPString)aStringValue
{
    if (_placeholderString === aStringValue)
        return;
    
    _placeholderString = aStringValue;

    // Only update things if we need to show the placeholder
    if ([self _shouldShowPlaceholderString])
    {
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }
}

/*!
    Returns the receiver's placeholder string
*/
- (CPString)placeholderString
{
    return _placeholderString;
}

/*!
    @ignore
*/
- (BOOL)_shouldShowPlaceholderString
{
    var string = [self stringValue];
    
    return (!string || [string length] === 0) && [_placeholderString length] > 0;
}

/*!
    Adjusts the text field's size in the application.
*/

- (void)sizeToFit
{
    var size = [(_value || " ") sizeWithFont:[self font]],
        contentInset = [self currentValueForThemedAttributeName:@"content-inset"];

    [self setFrameSize:CGSizeMake(size.width + contentInset.left + contentInset.right, size.height + contentInset.top + contentInset.bottom)];
/*#if PLATFORM(DOM)
    var size = [(_value || " ") sizeWithFont:[self font]];
    
    if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
    {
        [self setFrameSize:CGSizeMake(size.width + 2 * ROUNDEDBEZEL_HORIZONTAL_PADDING, size.height + TOP_PADDING + BOTTOM_PADDING)];
    }
    else
    {
        [self setFrameSize:CGSizeMake(size.width + 2 * HORIZONTAL_PADDING, size.height + TOP_PADDING + BOTTOM_PADDING)];
    }
#endif*/
}

/*!
    Select all the text in the CPTextField.
*/
- (void)selectText:(id)sender
{
#if PLATFORM(DOM)
    var element = [[self class] _inputElement];
    
    if (element.parentNode == _DOMElement && ([self isEditable] || [self isSelectable]))
        element.select();
#endif
}

#pragma mark Setting the Delegate

- (void)setDelegate:(id)aDelegate
{
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    //unsubscribe the existing delegate if it exists
    if (_delegate)
    {
        [defaultCenter removeObserver:_delegate name:CPControlTextDidBeginEditingNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPControlTextDidChangeNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPControlTextDidEndEditingNotification object:self];
    }
    
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(controlTextDidBeginEditing:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidBeginEditing:)
                   name:CPControlTextDidBeginEditingNotification
                 object:self];
    
    if ([_delegate respondsToSelector:@selector(controlTextDidChange:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidChange:)
                   name:CPControlTextDidChangeNotification
                 object:self];
    
    
    if ([_delegate respondsToSelector:@selector(controlTextDidEndEditing:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidEndEditing:)
                   name:CPControlTextDidEndEditingNotification
                 object:self];

}

- (id)delegate
{
    return _delegate;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemedAttributeName:@"content-inset"];
    
    if (!contentInset)
        return bounds;
    
    bounds.origin.x += contentInset.left;
    bounds.origin.y += contentInset.top;
    bounds.size.width -= contentInset.left + contentInset.right;
    bounds.size.height -= contentInset.top + contentInset.bottom;
    
    return bounds;
}

- (CGRect)bezelRectForBounds:(CFRect)bounds
{
    var bezelInset = [self currentValueForThemedAttributeName:@"bezel-inset"];
    
    if (!_CGInsetIsEmpty(bezelInset))
        return bounds;
    
    bounds.origin.x += bezelInset.left;
    bounds.origin.y += bezelInset.top;
    bounds.size.width -= bezelInset.left + bezelInset.right;
    bounds.size.height -= bezelInset.top + bezelInset.bottom;
    
    return bounds;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
        return [self bezelRectForBounds:[self bounds]];
    
    else if (aName === "content-view")
        return [self contentRectForBounds:[self bounds]];
    
    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

        [view setHitTests:NO];
        
        return view;
    }
    else
    {
        var view = [[_CPImageAndTextView alloc] initWithFrame:_CGRectMakeZero()];
        //[view setImagePosition:CPNoImage];
        
        return view;
    }
    
    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];
      
    if (bezelView)
        [bezelView setBackgroundColor:[self currentValueForThemedAttributeName:@"bezel-color"]];
    
    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];
    
    if (contentView)
    {
        if ([self _shouldShowPlaceholderString])
        {
            [contentView setText:[self placeholderString]];
            [contentView setTextColor:[CPColor grayColor]];
        }
        else
        {
            [contentView setText:[self stringValue]];
            [contentView setTextColor:[self currentValueForThemedAttributeName:@"text-color"]];
        }
        
        [contentView setFont:[self currentValueForThemedAttributeName:@"font"]];
        [contentView setAlignment:[self currentValueForThemedAttributeName:@"alignment"]];
        [contentView setVerticalAlignment:[self currentValueForThemedAttributeName:@"vertical-alignment"]];
        [contentView setLineBreakMode:[self currentValueForThemedAttributeName:@"line-break-mode"]];
        [contentView setTextShadowColor:[self currentValueForThemedAttributeName:@"text-shadow-color"]];
        [contentView setTextShadowOffset:[self currentValueForThemedAttributeName:@"text-shadow-offset"]];
    }
}

@end
/*
@implementation CPTextField (Theming)

- (void)viewDidChangeTheme
{
    [super viewDidChangeTheme];
    
    var theme = [self theme];
    
    [_bezelInset setTheme:theme];
    [_contentInset setTheme:theme];
    
    [_bezelColor setTheme:theme];
}

- (CPDictionary)themedValues
{
    var values = [super themedValues];

    [values setObject:_bezelInset forKey:@"bezel-inset"];
    [values setObject:_contentInset forKey:@"content-isnet"];
    
    [values setObject:_bezelColor forKey:@"bezel-color"];

    return values;
}

@end
*/
var CPTextFieldIsEditableKey            = "CPTextFieldIsEditableKey",
    CPTextFieldIsSelectableKey          = "CPTextFieldIsSelectableKey",
    CPTextFieldIsBorderedKey            = "CPTextFieldIsBorderedKey",
    CPTextFieldIsBezeledKey             = "CPTextFieldIsBezeledKey",
    CPTextFieldBezelStyleKey            = "CPTextFieldBezelStyleKey",
    CPTextFieldDrawsBackgroundKey       = "CPTextFieldDrawsBackgroundKey",
    CPTextFieldLineBreakModeKey         = "CPTextFieldLineBreakModeKey",
    CPTextFieldBackgroundColorKey       = "CPTextFieldBackgroundColorKey",
    CPTextFieldPlaceholderStringKey     = "CPTextFieldPlaceholderStringKey";

@implementation CPTextField (CPCoding)

/*!
    Initializes the textfield with data from a coder.
    @param aCoder the coder from which to read the textfield data
    @return the initialized textfield
*/
- (id)initWithCoder:(CPCoder)aCoder
{/*
#if PLATFORM(DOM)
    _DOMTextElement = document.createElement("div");
#endif
*/
    self = [super initWithCoder:aCoder];
    
    if (self)
    {/*
#if PLATFORM(DOM)
        var bounds = [self bounds];
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.top = TOP_PADDING + "px";
        if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
        {
            _DOMTextElement.style.left = ROUNDEDBEZEL_HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(bounds) - 2.0 * ROUNDEDBEZEL_HORIZONTAL_PADDING) + "px";
        }
        else
        {
            _DOMTextElement.style.left = HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(bounds) - 2.0 * HORIZONTAL_PADDING) + "px";
        }
        _DOMTextElement.style.height = MAX(0.0, CGRectGetHeight(bounds) - TOP_PADDING - BOTTOM_PADDING) + "px";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        
        _DOMElement.appendChild(_DOMTextElement);
#endif
*/
        [self setEditable:[aCoder decodeBoolForKey:CPTextFieldIsEditableKey]];
        [self setSelectable:[aCoder decodeBoolForKey:CPTextFieldIsSelectableKey]];

        [self setDrawsBackground:[aCoder decodeBoolForKey:CPTextFieldDrawsBackgroundKey]];

        [self setTextFieldBackgroundColor:[aCoder decodeObjectForKey:CPTextFieldBackgroundColorKey]];

        [self setPlaceholderString:[aCoder decodeObjectForKey:CPTextFieldPlaceholderStringKey]];
    }
    
    return self;
}

/*!
    Encodes the data of this textfield into the provided coder.
    @param aCoder the coder into which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:_isEditable forKey:CPTextFieldIsEditableKey];
    [aCoder encodeBool:_isSelectable forKey:CPTextFieldIsSelectableKey];
    
    [aCoder encodeBool:_drawsBackground forKey:CPTextFieldDrawsBackgroundKey];
    
    [aCoder encodeObject:_textFieldBackgroundColor forKey:CPTextFieldBackgroundColorKey];
    
    [aCoder encodeObject:_placeholderString forKey:CPTextFieldPlaceholderStringKey];
}

@end

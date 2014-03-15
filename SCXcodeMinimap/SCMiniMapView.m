//
//  SCMiniMapView.m
//  SCXcodeMinimap
//
//  Created by Jérôme ALVES on 30/04/13.
//  Copyright (c) 2013 Stefan Ceriu. All rights reserved.
//

#import "SCMiniMapView.h"
#import "SCXcodeMinimap.h"

const CGFloat kDefaultZoomLevel = 0.1f;
static const CGFloat kDefaultShadowLevel = 0.1f;

static NSString * const DVTFontAndColorSourceTextSettingsChangedNotification = @"DVTFontAndColorSourceTextSettingsChangedNotification";

@interface SCMiniMapView ()

@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSFont *font;

@end

@implementation SCMiniMapView

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        /* Configure ScrollView */
        [self setWantsLayer:YES];
        [self setAutoresizingMask: NSViewMinXMargin | NSViewHeightSizable];
        [self setDrawsBackground:NO];
        [self setHorizontalScrollElasticity:NSScrollElasticityNone];
        [self setVerticalScrollElasticity:NSScrollElasticityNone];
        
        /* Subscribe to show/hide notifications */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(show)
                                                     name:SCXodeMinimapWantsToBeShownNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(hide)
                                                     name:SCXodeMinimapWantsToBeHiddenNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateTheme)
                                                     name:DVTFontAndColorSourceTextSettingsChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Lazy Initialization

- (NSTextView *)textView
{
    if (_textView == nil) {
        _textView = [[NSTextView alloc] initWithFrame:self.bounds];
        [_textView setBackgroundColor:[NSColor clearColor]];
        
        [_textView.textContainer setLineFragmentPadding:0.0f];
        
        [_textView.layoutManager setDelegate:self];
        
        [_textView setAllowsUndo:NO];
        [_textView setAllowsImageEditing:NO];
        [_textView setAutomaticDashSubstitutionEnabled:NO];
        [_textView setAutomaticDataDetectionEnabled:NO];
        [_textView setAutomaticLinkDetectionEnabled:NO];
        [_textView setAutomaticQuoteSubstitutionEnabled:NO];
        [_textView setAutomaticSpellingCorrectionEnabled:NO];
        [_textView setAutomaticTextReplacementEnabled:NO];
        [_textView setContinuousSpellCheckingEnabled:NO];
        [_textView setDisplaysLinkToolTips:NO];
        [_textView setEditable:NO];
        [_textView setRichText:YES];
        [_textView setSelectable:NO];
        
        [self setDocumentView:_textView];
        
        [self updateTheme];
    }
    
    return _textView;
}

- (SCSelectionView *)selectionView
{
    if (_selectionView == nil) {
        _selectionView = [[SCSelectionView alloc] init];
        //[_selectionView setShouldInverseColors:YES];
        [self.textView addSubview:_selectionView];
    }
    
    return _selectionView;
}

- (NSFont *)font
{
    if(_font == nil) {
        _font = [NSFont fontWithName:@"Menlo" size:11 * kDefaultZoomLevel];
        
        Class DVTFontAndColorThemeClass = NSClassFromString(@"DVTFontAndColorTheme");
        if([DVTFontAndColorThemeClass respondsToSelector:@selector(currentTheme)]) {
            
            NSObject *theme = [DVTFontAndColorThemeClass performSelector:@selector(currentTheme)];
            if([theme respondsToSelector:@selector(sourcePlainTextFont)]) {
                NSFont *themeFont = [theme performSelector:@selector(sourcePlainTextFont)];
                self.font = [NSFont fontWithName:themeFont.familyName size:themeFont.pointSize * kDefaultZoomLevel];
            }
        }
    }
    
    return _font;
}

- (NSColor *)backgroundColor
{
    if(_backgroundColor == nil) {
        _backgroundColor = [[NSColor clearColor] shadowWithLevel:kDefaultShadowLevel];
        
        Class DVTFontAndColorThemeClass = NSClassFromString(@"DVTFontAndColorTheme");
        if([DVTFontAndColorThemeClass respondsToSelector:@selector(currentTheme)]) {
            
            NSObject *theme = [DVTFontAndColorThemeClass performSelector:@selector(currentTheme)];
            if([theme respondsToSelector:@selector(sourceTextBackgroundColor)]) {
                NSColor *themeBackgroundColor = [theme performSelector:@selector(sourceTextBackgroundColor)];
                self.backgroundColor = [themeBackgroundColor shadowWithLevel:kDefaultShadowLevel];
            }
        }
    }
    
    return _backgroundColor;
}

#pragma mark - Show/Hide

- (void)show
{
    self.hidden = NO;
    
    NSRect editorTextViewFrame = self.editorScrollView.frame;
    editorTextViewFrame.size.width = self.editorScrollView.superview.frame.size.width - self.bounds.size.width;
    self.editorScrollView.frame = editorTextViewFrame;
    
    [self updateTextView];
    [self updateSelectionView];
}

- (void)hide
{
    self.hidden = YES;
    
    NSRect editorTextViewFrame = self.editorScrollView.frame;
    editorTextViewFrame.size.width = self.editorScrollView.superview.frame.size.width;
    self.editorScrollView.frame = editorTextViewFrame;
}

#pragma mark - Updating

- (void)updateTheme
{
    [self setFont:nil];
    
    [self setBackgroundColor:nil];
    [self.selectionView setSelectionColor:nil];
    [self.textView setBackgroundColor:self.backgroundColor];
}

- (void)updateTextView
{
    if ([self isHidden]) {
        return;
    }
    
    NSMutableAttributedString *mutableAttributedString = [self.editorTextView.textStorage mutableCopy];
    
    if(mutableAttributedString.length == 0) {
        return;
    }
	
    __block NSMutableParagraphStyle *style;

	[mutableAttributedString enumerateAttribute:NSParagraphStyleAttributeName
										inRange:NSMakeRange(0, mutableAttributedString.length)
										options:0
									 usingBlock:^(id value, NSRange range, BOOL *stop) {
                                         style = [value mutableCopy];
                                         *stop = YES;
                                     }];
    
    
    [style setTabStops:@[]];
	[style setDefaultTabInterval:style.defaultTabInterval * kDefaultZoomLevel];

    [mutableAttributedString setAttributes:@{NSFontAttributeName: self.font, NSParagraphStyleAttributeName : style} range:NSMakeRange(0, mutableAttributedString.length)];
    
    [self.textView.textStorage setAttributedString:mutableAttributedString];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
    [super resizeWithOldSuperviewSize:oldSize];
    [self updateSelectionView];
}

- (void)updateSelectionView
{
    if ([self isHidden]) {
        return;
    }
    
    NSRect selectionViewFrame = NSMakeRect(0,
                                           0,
                                           self.bounds.size.width,
                                           self.editorScrollView.visibleRect.size.height * kDefaultZoomLevel);
    
    
    CGFloat editorContentHeight = [self.editorScrollView.documentView frame].size.height - self.editorScrollView.bounds.size.height;
    
    if(editorContentHeight == 0) {
        selectionViewFrame.origin.y = 0;
    }
    else {
        CGFloat ratio = ([self.documentView frame].size.height - self.bounds.size.height) / editorContentHeight;
        [self.contentView scrollToPoint:NSMakePoint(0, floorf(self.editorScrollView.contentView.bounds.origin.y * ratio))];
        
        CGFloat textHeight = [self.textView.layoutManager usedRectForTextContainer:self.textView.textContainer].size.height;
        ratio = (textHeight - self.selectionView.bounds.size.height) / editorContentHeight;
        selectionViewFrame.origin.y = self.editorScrollView.contentView.bounds.origin.y * ratio;
    }
    
	[self.selectionView setFrame:selectionViewFrame];
}

#pragma mark - NSLayoutManagerDelegate

- (void)layoutManager:(NSLayoutManager *)layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinished
{
    if([layoutManager isEqual:self.editorTextView.layoutManager]) {
        [(id<NSLayoutManagerDelegate>)self.editorTextView layoutManager:layoutManager
                                      didCompleteLayoutForTextContainer:textContainer
                                                                  atEnd:layoutFinished];
    }
    else if(layoutFinished) {
        [self updateSelectionView];
    }
}

- (NSDictionary *)layoutManager:(NSLayoutManager *)layoutManager shouldUseTemporaryAttributes:(NSDictionary *)attrs forDrawingToScreen:(BOOL)toScreen atCharacterIndex:(NSUInteger)charIndex effectiveRange:(NSRangePointer)effectiveCharRange
{
    return [(id<NSLayoutManagerDelegate>)self.editorTextView layoutManager:layoutManager
                                              shouldUseTemporaryAttributes:attrs
                                                        forDrawingToScreen:toScreen
                                                          atCharacterIndex:charIndex
                                                            effectiveRange:effectiveCharRange];
}

#pragma mark - Navigation

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    [self handleMouseEvent:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [self handleMouseEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    [self handleMouseEvent:theEvent];
}

- (void) handleMouseEvent:(NSEvent *)theEvent
{
    NSPoint locationInSelf = [self convertPoint:theEvent.locationInWindow fromView:nil];
    
    NSSize textSize = [self.textView.layoutManager usedRectForTextContainer:self.textView.textContainer].size;
    NSSize frameSize = self.frame.size;
    
    NSPoint point;
    if (textSize.height < frameSize.height) {
        point = NSMakePoint(locationInSelf.x / textSize.width, locationInSelf.y / textSize.height);
    }
    else {
        point = NSMakePoint(locationInSelf.x / textSize.width, locationInSelf.y / frameSize.height);
    }
    
    [self goAtRelativePosition:point];
}

- (void)goAtRelativePosition:(NSPoint)position
{
    CGFloat documentHeight = [self.editorScrollView.documentView frame].size.height;
    CGSize boundsSize = self.editorScrollView.bounds.size;
    CGFloat maxOffset = documentHeight - boundsSize.height;
    
    CGFloat offset =  floor(documentHeight * position.y - boundsSize.height/2);
    
    offset = MIN(MAX(0, offset), maxOffset);
    
    [self.editorTextView scrollRectToVisible:NSMakeRect(0, offset, boundsSize.width, boundsSize.height)];
}

@end

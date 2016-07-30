//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTResultsView.h"

#import "DTTermWindowController.h"

@implementation DTResultsView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib {
    // for some reason if we leave theses buttons with a "VibrantDark" appearance (when app is run in dark mode) they slightly mess with the UI by giving the line segment below them some extra highlight ... forcing them to Aqua (or VibrantLight) fixes that
    goPrevButton.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    goNextButton.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
	goPrevButton.cell.backgroundStyle = NSBackgroundStyleDark;
	goNextButton.cell.backgroundStyle = NSBackgroundStyleDark;
}

- (void)drawRect:(NSRect)rect {
    UnusedParameter(rect);
    
	[[[NSColor whiteColor] colorWithAlphaComponent:0.7] setStroke];
	
	NSBezierPath* outlinePath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 0.5, 0.5)
																xRadius:5.0 yRadius:5.0];
	[outlinePath stroke];
	
	NSPoint startPoint = NSMakePoint(0.0, CGRectGetHeight(self.bounds) - 18.0);
    startPoint = [self convertPointToBacking:startPoint];
	startPoint.y = floor(startPoint.y) + 0.5;
    startPoint = [self convertPointFromBacking:startPoint];
	
	NSPoint endPoint = NSMakePoint(CGRectGetWidth(self.bounds), startPoint.y);
	
	[NSBezierPath strokeLineFromPoint:startPoint
							  toPoint:endPoint];
}

- (BOOL)performKeyEquivalent:(NSEvent*)event {
	NSString* chars = event.charactersIgnoringModifiers;
	if([chars isEqualToString:@"c"] &&
	   ((event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) == NSEventModifierFlagControl)) {
		[self.window.windowController cancelCurrentCommand:self];
		return YES;
	}
	return [super performKeyEquivalent:event];
}

#pragma mark accessibility support

-(BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityRole
{
    return NSAccessibilityGroupRole;
}

@end

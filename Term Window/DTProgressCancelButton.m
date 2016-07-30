//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTProgressCancelButton.h"


@interface DTProgressCancelButton ()
- (void)updateImageForMouseInside:(BOOL)inside;
- (void)loadAnimationImages;
- (void)updateAnimation:(NSTimer*)timer;
@end

@implementation DTProgressCancelButton

- (void)awakeFromNib {
	self.cell.backgroundStyle = NSBackgroundStyleDark;
}

#pragma mark Rollover management

// NSImageNameStopProgressFreestandingTemplate

- (void)setHidden:(BOOL)hidden {
	BOOL wasHidden = [self isHiddenOrHasHiddenAncestor];
	[super setHidden:hidden];
	
	if(wasHidden == hidden)
		return;
	
	[self viewDidMoveToWindow];
	
	if(hidden) {
		// Now hiding; stop animation
		[animationTimer invalidate];
		animationTimer = nil;
	} else {
		if(!animationImages)
            [self loadAnimationImages];
		
		nextAnimImg = 0;
		if(!animationTimer)
			animationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/animationImages.count)
															  target:self
															selector:@selector(updateAnimation:)
															userInfo:nil
															 repeats:YES];
		[self updateAnimation:nil];
	}
}

- (void)loadAnimationImages {
	NSMutableArray* tmpImages = [NSMutableArray arrayWithCapacity:12];
	for(unsigned i=0; i<12; i++) {
		[tmpImages addObject:(NSImage* _Nonnull)[NSImage imageNamed:[NSString stringWithFormat:@"ProgressWhite-%d", i]]];
	}
	
	// Make an immutable copy so this is reasonably fast
	animationImages = [tmpImages copy];
}

- (void)updateAnimation:(NSTimer*) __unused timer {
	if(!self.window.visible)
		return;
	
	if(!animationImages)
        [self loadAnimationImages];
	
	if(mouseInside)
		return;
	
	self.image = animationImages[nextAnimImg];
	[self setNeedsDisplay];
	nextAnimImg = (nextAnimImg+1) % animationImages.count;
}

- (void)updateImageForMouseInside:(BOOL)inside {
	if(inside) {
		self.image = [NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];
	} else {
		[self updateAnimation:nil];
	}

	mouseInside = inside;
}

- (void)mouseEntered:(NSEvent*) __unused event {
	[self updateImageForMouseInside:YES];
}

- (void)mouseExited:(NSEvent*) __unused event {
	[self updateImageForMouseInside:NO];
}

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
	
	if(trackingArea)
		[self removeTrackingArea:trackingArea];
	trackingArea = [[NSTrackingArea alloc] initWithRect:self.visibleRect
												options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect)
												  owner:self
											   userInfo:nil];
	[self addTrackingArea:trackingArea];
}

- (void)viewDidMoveToWindow {
	if(self.window) {
		NSPoint loc=[self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
		BOOL inside=([self hitTest:loc]==self);
		[self updateImageForMouseInside:inside];
	}
}

@end

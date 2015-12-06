//  DTPrefsWindowController.m
//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTPrefsWindowController.h"

#import "DTAppController.h"
#import "DTPrefsAXController.h"
#import "FontNameToDisplayNameTransformer.h"
#import "SRRecorderControl.h"

@implementation DTPrefsWindowController

//@synthesize regPrefsViewController;
@synthesize axPrefsController;

+ (void)initialize {
	// Create and register font name value transformer
	NSValueTransformer *transformer = [[FontNameToDisplayNameTransformer alloc] init];
	[NSValueTransformer setValueTransformer:transformer forName:@"FontNameToDisplayNameTransformer"];
}

- (instancetype)init {
	if((self = [super initWithWindowNibName:@"Preferences"])) {
		[self setShouldCascadeWindows:NO];
		
		[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
	}
	
	return self;
}

// Don't allow closing if we can't commit editing
- (BOOL)windowShouldClose:(id) __unused window {
	return [self.window makeFirstResponder:nil];
}

- (void)windowDidLoad {
	[shortcutRecorder setAllowsKeyOnly:NO escapeKeysRecord:NO];
	shortcutRecorder.keyCombo = [APP_DELEGATE hotKey];
}

- (void)windowDidBecomeKey:(NSNotification *) __unused notification {
	[axPrefsController recheckGeneralAXAccess];
}

- (IBAction)showPrefs:(id)sender {
	if(!self.window.visible)
		[self showGeneral:sender];
	else {
		[self.window center];
		[self.window makeKeyAndOrderFront:sender];
	}
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder
			   isKeyCode:(NSInteger)keyCode
		   andFlagsTaken:(NSUInteger)flags
				  reason:(NSString * __autoreleasing *)aReason
{
    UnusedParameter(aRecorder);
    UnusedParameter(keyCode);
    UnusedParameter(flags);
    UnusedParameter(aReason);
    
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder
	   keyComboDidChange:(KeyCombo)newKeyCombo
{
    UnusedParameter(aRecorder);
    
//	NSLog(@"New key combo: key code %d, flags %d", newKeyCombo.code, newKeyCombo.flags);
	[APP_DELEGATE setHotKey:newKeyCombo];
}

- (void)showView:(NSView*)prefsView {
	NSWindow* prefsWindow = self.window;
	
	//blank view to stop flicker
	NSView *tempView = [[NSView alloc] initWithFrame:prefsWindow.contentView.frame];
    prefsWindow.contentView = tempView;
    
    //mojo to get the right frame for the new window.
    NSRect newFrame = prefsWindow.frame;
    newFrame.size.height = CGRectGetHeight(prefsView.frame) + (CGRectGetHeight(prefsWindow.frame) - CGRectGetHeight(prefsWindow.contentView.frame));
    newFrame.size.width = CGRectGetWidth(prefsView.frame);
    newFrame.origin.y += (CGRectGetHeight(prefsWindow.contentView.frame) - CGRectGetHeight(prefsView.frame));
    
    //set the frame to newFrame and animate it. (change animate:YES to animate:NO if you don't want this)
//    [prefsWindow setShowsResizeIndicator:YES];
    [prefsWindow setFrame:newFrame display:YES animate:YES];
    //set the main content view to the new view
    prefsWindow.contentView = prefsView;
	
	if (![prefsWindow isVisible]) {
		[self.window center];
		[self.window makeKeyAndOrderFront:self];
	}
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [toolbar valueForKeyPath:@"items.itemIdentifier"];
}

- (IBAction)showGeneral:(id) __unused sender {
	// make sure we have a window
	[self window];
	
	// This method can be called programmatically, so make sure general toolbar icon is selected
	NSToolbar* toolbar = self.window.toolbar;
	for(NSToolbarItem* item in toolbar.items) {
		if(item.tag == 1 /* general tag */) {
			toolbar.selectedItemIdentifier = item.itemIdentifier;
			break;
		}
	}
	
	[self showView:generalPrefsView];
}
- (IBAction)showAccessibility:(id) __unused sender {
	// make sure we have a window
	[self window];
	
	// This method can be called programmatically, so make sure accessibility toolbar icon is selected
	NSToolbar* toolbar = self.window.toolbar;
	for(NSToolbarItem* item in toolbar.items) {
		if(item.tag == 2 /* accessibility tag */) {
			toolbar.selectedItemIdentifier = item.itemIdentifier;
			break;
		}
	}
	
	[self showView:accessibilityPrefsView];
}

- (IBAction)showUpdates:(id) __unused sender {
	// make sure we have a window
	[self window];
	
	// This method can be called programmatically, so make sure updates toolbar icon is selected
	NSToolbar* toolbar = self.window.toolbar;
	for(NSToolbarItem* item in toolbar.items) {
		if(item.tag == 3 /* updates tag */) {
			toolbar.selectedItemIdentifier = item.itemIdentifier;
			break;
		}
	}
	
	[self showView:updatesPrefsView];
}

#pragma mark font selection

- (IBAction)showFontPanel:(id) __unused sender {
	// Get font name and size from user defaults
	NSDictionary *values = [NSUserDefaultsController sharedUserDefaultsController].values;
	NSString *fontName = [values valueForKey:DTFontNameKey];
	CGFloat fontSize = [[values valueForKey:DTFontSizeKey] floatValue];
	
	// Create font from name and size; initialize font panel
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
	if(!font) {
		font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
	[[NSFontManager sharedFontManager] setSelectedFont:font 
											isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
	
	// Set window as firstResponder so we get changeFont: messages
    [self.window makeFirstResponder:self.window];
}

- (IBAction)resetColorAndFont:(id) __unused sender {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:DTFontNameKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:DTFontSizeKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:DTTextColorKey];
}

#pragma mark Updates support

- (IBAction)checkForUpdatesNow:(id) sender
{
    UnusedParameter(sender);
//	[[APP_DELEGATE sparkleUpdater] checkForUpdates:sender];
    NSLog(@"enable the preceding line of code");
}

@end

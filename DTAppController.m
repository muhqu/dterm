//  DTAppController.m
//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTAppController.h"

#import "DSAppleScriptUtilities.h"
#import "DTPrefsWindowController.h"
#import "DTTermWindowController.h"
#import "Finder.h"
#import "PathFinder.h"
#import "RTFWindowController.h"

NSString* const DTResultsToKeepKey = @"DTResultsToKeep";
NSString* const DTHotkeyAlsoDeactivatesKey = @"DTHotkeyAlsoDeactivates";
NSString* const DTShowDockIconKey = @"DTShowDockIcon";
NSString* const DTTextColorKey = @"DTTextColor";
NSString* const DTFontNameKey = @"DTFontName";
NSString* const DTFontSizeKey = @"DTFontSize";
NSString* const DTDisableAntialiasingKey = @"DTDisableAntialiasing";

OSStatus DTHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData);
OSStatus DTHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData)
{
    UnusedParameter(nextHandler);
    UnusedParameter(theEvent);
    UnusedParameter(userData);

	[APP_DELEGATE hotkeyPressed];
	return noErr;
}

// Calling `CFAutorelease()` on NULL objects crashes with a EXC_BREAKPOINT and the message:
//      *** CFAutorelease() called with NULL ***
#define CF_AUTORELEASE(x) if(x) CFAutorelease(x)

@interface DTAppController ()

@property (readwrite, nonatomic) DTPrefsWindowController* prefsWindowController;

@end

@implementation DTAppController

@synthesize sparkleUpdater;

@synthesize termWindowController;

- (void)applicationWillFinishLaunching:(NSNotification*) __unused ntf {
	// Ignore SIGPIPE
	signal(SIGPIPE, SIG_IGN);
	
	// Set some environment variables for our child processes
	setenv("TERM_PROGRAM", "DTerm", 1);
	setenv("TERM_PROGRAM_VERSION", [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] cStringUsingEncoding:NSASCIIStringEncoding], 1);
	
	NSDictionary* defaultsDict = @{DTResultsToKeepKey: @"5",
								  DTHotkeyAlsoDeactivatesKey: @NO,
								  DTShowDockIconKey: @YES,
								  DTTextColorKey: [NSKeyedArchiver archivedDataWithRootObject:[[NSColor whiteColor] colorWithAlphaComponent:0.9]],
								  DTFontNameKey: @"Monaco",
								  DTFontSizeKey: @10.0f,
								  DTDisableAntialiasingKey: @NO};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
	
	// Register for URL handling
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
													   andSelector:@selector(getURL:withReplyEvent:)
													 forEventClass:kInternetEventClass
														andEventID:kAEGetURL];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:DTShowDockIconKey]) {
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		OSStatus err = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		if(err != noErr)
			NSLog(@"Error making DTerm non-LSUIElement: %d", err);
		else {
			NSDictionary* appleScriptError = nil;
			
			// TransformProcessType doesn't show the menubar, and the usual things don't work
			// See <https://decimus.fogbugz.com/default.asp?10520> for the cocoa-dev email that this is based on
			NSString* frontmostApp = [DSAppleScriptUtilities stringFromAppleScript:@"tell application \"System Events\" to name of first process whose frontmost is true"
																			 error:&appleScriptError];
			if(frontmostApp)
				[[NSWorkspace sharedWorkspace] launchApplication:frontmostApp];
			else
				NSLog(@"Couldn't get frontmost app from System Events: %@", appleScriptError);
			
			if(![DSAppleScriptUtilities bringApplicationToFront:@"DTerm" error:&appleScriptError])
				NSLog(@"Error bringing DTerm back to the front: %@", appleScriptError);
		}
	}
}

- (void)applicationDidFinishLaunching:(NSNotification*) __unused ntf {
	if( ![self isAXTrustedPromptIfNot:NO] )
    {
		[self.prefsWindowController showAccessibility:self];
	}
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *) __unused theApplication hasVisibleWindows:(BOOL)flag {
	if(!flag) {
		[self performSelector:@selector(showPrefs:)
				   withObject:nil
				   afterDelay:0.0];
	}
	
	return YES;
}

- (void)awakeFromNib {
	termWindowController = [[DTTermWindowController alloc] init];
	
	// Install event handler for hotkey events
	EventTypeSpec theTypeSpec[] =
	{
		{ kEventClassKeyboard, kEventHotKeyPressed },
		//{ kEventClassKeyboard, kEventHotKeyReleased }
	};
	InstallApplicationEventHandler(&DTHotKeyHandler, 1, theTypeSpec, NULL, NULL);

	[self loadHotKeyFromUserDefaults];
}

- (DTPrefsWindowController *) prefsWindowController {
	if(!_prefsWindowController)
		self.prefsWindowController = [[DTPrefsWindowController alloc] init];

	return _prefsWindowController;
}

- (KeyCombo)hotKey {
	return hotKey;
}

- (void)setHotKey:(KeyCombo)newHotKey {
	// Unregister old hotkey, if necessary
	if(hotKeyRef) {
		UnregisterEventHotKey(hotKeyRef);
		hotKeyRef = NULL;
	}
	
	// Save hotkey for the future
	hotKey = newHotKey;
	[self saveHotKeyToUserDefaults];
	
	// Register new hotkey, if we have one
	if((hotKey.code != -1) && (hotKey.flags != 0)) {
		EventHotKeyID hotKeyID = { 'htk1', 1 };
		RegisterEventHotKey((UInt32)hotKey.code,
							(UInt32)SRCocoaToCarbonFlags(hotKey.flags),
							hotKeyID,
							GetApplicationEventTarget(), 
							0, 
							&hotKeyRef);
	}
}

- (void)saveHotKeyToUserDefaults {
	KeyCombo myHotKey = [self hotKey];
	
	NSDictionary* hotKeyDict = @{@"flags": @(myHotKey.flags),
								@"code": @(myHotKey.code)};
	[[NSUserDefaults standardUserDefaults] setObject:hotKeyDict forKey:@"DTHotKey"];
}

- (void)loadHotKeyFromUserDefaults {
	KeyCombo myHotKey = { NSCommandKeyMask | NSShiftKeyMask, 36 /* return */ };
	
	NSDictionary* hotKeyDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"DTHotKey"];
	NSNumber* newFlags = hotKeyDict[@"flags"];
	NSNumber* newCode = hotKeyDict[@"code"];
	if(newFlags)
		myHotKey.flags = newFlags.unsignedIntValue;
	if(newCode)
		myHotKey.code = newCode.shortValue;
	
	[self setHotKey:myHotKey];
}

- (IBAction)showPrefs:(id)sender {
	[self.prefsWindowController showPrefs:sender];
}

- (NSRect)windowFrameOfAXWindow:(CFTypeRef)axWindow {
	AXError axErr = kAXErrorSuccess;
	
	// Get AXPosition of the main window
	CFTypeRef axPosition = NULL;
	axErr = AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute, &axPosition);
	CF_AUTORELEASE(axPosition);
	if((axErr != kAXErrorSuccess) || !axPosition) {
		NSLog(@"Couldn't get AXPosition: %d", axErr);
		return NSZeroRect;
	}
	
	// Convert to CGPoint
	CGPoint realAXPosition;
	if(!AXValueGetValue(axPosition, kAXValueCGPointType, &realAXPosition)) {
		NSLog(@"Couldn't extract CGPoint from AXPosition");
		return NSZeroRect;
	}
	
	// Get AXSize
	CFTypeRef axSize = NULL;
	axErr = AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute, &axSize);
	CF_AUTORELEASE(axSize);
	if((axErr != kAXErrorSuccess) || !axSize) {
		NSLog(@"Couldn't get AXSize: %d", axErr);
		return NSZeroRect;
	}
	
	// Convert to CGSize
	CGSize realAXSize;
	if(!AXValueGetValue(axSize, kAXValueCGSizeType, &realAXSize)) {
		NSLog(@"Couldn't extract CGSize from AXSize");
		return NSZeroRect;
	}
	
	NSRect windowBounds;
	windowBounds.origin.x = realAXPosition.x;
	windowBounds.origin.y = realAXPosition.y + 20.0;
	windowBounds.size.width = realAXSize.width;
	windowBounds.size.height = realAXSize.height - 20.0;
	return windowBounds;
}

- (NSString*)fileAXURLStringOfAXUIElement:(AXUIElementRef)uiElement {
	CFTypeRef axURL = NULL;
	
	AXError axErr = AXUIElementCopyAttributeValue(uiElement, kAXURLAttribute, &axURL);
	CF_AUTORELEASE(axURL);
	if((axErr != kAXErrorSuccess) || !axURL)
		return nil;
	
	// OK, we have some kind of AXURL attribute, but that could either be a string or a URL
	
	if(CFGetTypeID(axURL) == CFStringGetTypeID()) {
		if([(__bridge NSString*)axURL hasPrefix:@"file:///"])
			return (__bridge NSString*)axURL;
		else
			return nil;
	}
	
	if(CFGetTypeID(axURL) == CFURLGetTypeID()) {
		if(((__bridge NSURL*)axURL).fileURL)
			return ((__bridge NSURL*)axURL).absoluteString;
		else
			return nil;
	}
	
	// Unknown type...
	return nil;
}

- (BOOL)findWindowURL:(NSURL * __autoreleasing *)windowURL selectionURLs:(NSArray* __autoreleasing *)selectionURLStrings windowFrame:(NSRect*)windowFrame ofAXApplication:(CFTypeRef)focusedApplication {
	AXError axErr = kAXErrorSuccess;
	
	if(windowURL)
		*windowURL = nil;
	if(selectionURLStrings)
		*selectionURLStrings = nil;
	if(windowFrame)
		*windowFrame = NSZeroRect;
	
	// Mechanism 1: Find front window AXDocument (a CFURL), and use that window
	
	// Follow to main window
	CFTypeRef mainWindow = NULL;
	axErr = AXUIElementCopyAttributeValue(focusedApplication, kAXMainWindowAttribute, &mainWindow);
	CF_AUTORELEASE(mainWindow);
	if((axErr != kAXErrorSuccess) || !mainWindow) {
#ifdef DEVBUILD
		NSLog(@"Couldn't get main window: %d", axErr);
#endif
		goto failedAXDocument;
	}
	
	// Get the window's AXDocument URL string
	CFTypeRef axDocumentURLString = NULL;
	axErr = AXUIElementCopyAttributeValue(mainWindow, kAXDocumentAttribute, &axDocumentURLString);
	CF_AUTORELEASE(axDocumentURLString);
	if((axErr != kAXErrorSuccess) || !axDocumentURLString) {
#ifdef DEVBUILD
		NSLog(@"Couldn't get AXDocument: %d", axErr);
#endif
		goto failedAXDocument;
	}
	
	// OK, we're a go with this method!
	if(windowURL)
		*windowURL = [NSURL URLWithString:(__bridge NSString*)axDocumentURLString];
	if(selectionURLStrings)
		*selectionURLStrings = @[(__bridge NSString*)axDocumentURLString];
	if(windowFrame)
		*windowFrame = [self windowFrameOfAXWindow:mainWindow];
	return YES;
	
	
failedAXDocument:	;
	
	// Mechanism 2: Find focused UI element and try to find a selection from it.
	
	// Find focused UI element
	CFTypeRef focusedUIElement = NULL;
	axErr = AXUIElementCopyAttributeValue(focusedApplication, kAXFocusedUIElementAttribute, &focusedUIElement);
	CF_AUTORELEASE(focusedUIElement);
	if((axErr != kAXErrorSuccess) || !focusedUIElement) {
#ifdef DEVBUILD
		NSLog(@"Couldn't get AXFocusedUIElement");
#endif
		return NO;
	}
	
	// Does the focused UI element have any selected children or selected rows? Great for file views.
	CFTypeRef focusedSelectedChildren = NULL;
	axErr = AXUIElementCopyAttributeValue(focusedUIElement, kAXSelectedChildrenAttribute, &focusedSelectedChildren);
	CF_AUTORELEASE(focusedSelectedChildren);
	if((axErr != kAXErrorSuccess) || !focusedSelectedChildren || !CFArrayGetCount(focusedSelectedChildren)) {
		axErr = AXUIElementCopyAttributeValue(focusedUIElement, kAXSelectedRowsAttribute, &focusedSelectedChildren);
		CF_AUTORELEASE(focusedSelectedChildren);
	}
	if((axErr == kAXErrorSuccess) && focusedSelectedChildren) {
		// If it *worked*, we see if we can extract URLs from these selected children
		NSMutableArray* tmpSelectionURLs = [NSMutableArray array];
		for(CFIndex i=0; i<CFArrayGetCount(focusedSelectedChildren); i++) {
			CFTypeRef selectedChild = CFArrayGetValueAtIndex(focusedSelectedChildren, i);
			NSString* selectedChildURLString = [self fileAXURLStringOfAXUIElement:selectedChild];
			if(selectedChildURLString)
				[tmpSelectionURLs addObject:selectedChildURLString];
		}
		
		// If we have selection URLs now, grab the window the focused UI element belongs to
		if(tmpSelectionURLs.count) {
			CFTypeRef focusWindow = NULL;
			axErr = AXUIElementCopyAttributeValue(focusedUIElement, kAXWindowAttribute, &focusWindow);
			CF_AUTORELEASE(focusWindow);
			if((axErr == kAXErrorSuccess) && focusWindow) {
				// We're good with this! Return the values.
				if(selectionURLStrings)
					*selectionURLStrings = tmpSelectionURLs;
				if(windowFrame)
					*windowFrame = [self windowFrameOfAXWindow:focusWindow];
				return YES;
			}
		}
	}
	
	// Does the focused UI element have an AXURL of its own?
	NSString* focusedUIElementURLString = [self fileAXURLStringOfAXUIElement:focusedUIElement];
	if(focusedUIElementURLString) {
		CFTypeRef focusWindow = NULL;
		axErr = AXUIElementCopyAttributeValue(focusedUIElement, kAXWindowAttribute, &focusWindow);
		CF_AUTORELEASE(focusWindow);
		if((axErr == kAXErrorSuccess) && focusWindow) {
			// We're good with this! Return the values.
			if(selectionURLStrings)
				*selectionURLStrings = @[focusedUIElementURLString];
			if(windowFrame)
				*windowFrame = [self windowFrameOfAXWindow:focusWindow];
			return YES;
		}
	}
    
    return NO;
}

- (void)hotkeyPressed {
//	NSLog(@"HotKey pressed");
//	NSLog(@"AXAPIEnabled %d, AXIsProcessTrusted %d", AXAPIEnabled(), AXIsProcessTrusted());
	
	// See if it's already visible
	if(termWindowController.window.visible) {
		// Yep, it's visible...does the user want us to deactivate?
		if([[NSUserDefaults standardUserDefaults] boolForKey:DTHotkeyAlsoDeactivatesKey])
			[termWindowController deactivate];
		
		return;
	}
	
	NSString* workingDirectory = nil;
	NSURL* frontWindowURL = nil;
	NSArray* selectionURLStrings = nil;
	NSRect frontWindowBounds = NSZeroRect;
	
	NSString* frontmostAppBundleID = [NSWorkspace sharedWorkspace].frontmostApplication.bundleIdentifier;
	
	// If the Finder is frontmost, talk to it using ScriptingBridge
	if([frontmostAppBundleID isEqualToString:@"com.apple.finder"]) {
		FinderApplication* finder = (FinderApplication *)[SBApplication applicationWithBundleIdentifier:@"com.apple.finder"];
		
		// Selection URLs
		@try {
//			NSLog(@"selection: %@, insertionLocation: %@",
//				  [[finder.selection get] valueForKey:@"URL"],
//				  [[finder.insertionLocation get] valueForKey:@"URL"]);
			
			NSArray* selection = [finder.selection get];
			if(!selection.count) {
				SBObject* insertionLocation = [finder.insertionLocation get];
				if(!insertionLocation)
					return;
				
				selection = @[insertionLocation];
			}
			
			// Get the URLs of the selection
			selectionURLStrings = [selection valueForKey:@"URL"];
			
			// If any of it ended up as NSNull, dump the whole thing
			if([selectionURLStrings containsObject:[NSNull null]]) {
				selection = nil;
				selectionURLStrings = nil;
			}
		}
		@catch (NSException* e) {
			// *shrug*...guess we can't get a selection
		}
		
		
		// If insertion location is desktop, use the desktop as the WD
		@try {
			NSString* insertionLocationURL = [[finder.insertionLocation get] valueForKey:@"URL"];
			if(insertionLocationURL) {
				NSString* path = [NSURL URLWithString:insertionLocationURL].path;
				if([path.lastPathComponent isEqualToString:@"Desktop"])
					workingDirectory = path;
			}
		}
		@catch (NSException* e) {
			// *shrug*...guess we can't get insertion location
		}
		
		// If it wasn't the desktop, grab it from the frontmost window
		if(!workingDirectory) {
			@try {
				FinderFinderWindow* frontWindow = [[finder FinderWindows] firstObject];
				if([frontWindow exists]) {
					
					
					NSString* urlString = [[frontWindow.target get] valueForKey:@"URL"];
					if(urlString) {
						NSURL* url = [NSURL URLWithString:urlString];
						if(url && [url isFileURL]) {
							frontWindowBounds = frontWindow.bounds;
							workingDirectory = url.path;
						}
					}
				}
			}
			@catch (NSException* e) {
				// Fall through to the default attempts to set WD from selection
			}
		}
	}
	
	// Also use ScriptingBridge special case for Path Finder
	else if([frontmostAppBundleID isEqualToString:@"com.cocoatech.PathFinder"]) {
		PathFinderApplication* pf = (PathFinderApplication *)[SBApplication applicationWithBundleIdentifier:@"com.cocoatech.PathFinder"];
		
		// Selection URLs
		@try {
			NSArray* selection = pf.selection;
			if(selection.count) {
				selectionURLStrings = [selection valueForKey:@"URL"];
			}
		}
		@catch (NSException* e) {
			// *shrug*...guess we can't get a selection
		}
		
		@try {
			SBElementArray* finderWindows = [pf finderWindows];
			if(finderWindows.count) {
				PathFinderFinderWindow* frontWindow = finderWindows.firstObject;
				// [frontWindow exists] returns false here (???), but it works anyway
				frontWindowBounds = frontWindow.bounds;
				frontWindowBounds.origin.y += 20.0;
				
				NSString* urlString = [[frontWindow.target get] valueForKey:@"URL"];
				NSURL* url = [NSURL URLWithString:urlString];
				if(url && url.fileURL)
					workingDirectory = url.path;
			}
		}
		@catch (NSException* e) {
			// Fall through to the default attempts to set WD from selection
		}
		
	}

	// Otherwise, try to talk to the frontmost app with the Accessibility APIs
	else if([self isAXTrustedPromptIfNot:NO]) {
		// Use Accessibility API
		AXError axErr = kAXErrorSuccess;
		
		// Grab system-wide UI Element
		AXUIElementRef systemElement = AXUIElementCreateSystemWide();
		if(!systemElement) {
			NSLog(@"Couldn't get systemElement");
			goto done;
		}
		CF_AUTORELEASE(systemElement);
		
		// Follow to focused application
		CFTypeRef focusedApplication = NULL;
		axErr = AXUIElementCopyAttributeValue(systemElement, 
											  kAXFocusedApplicationAttribute,
											  &focusedApplication);
		if((axErr != kAXErrorSuccess) || !focusedApplication) {
			NSLog(@"Couldn't get focused application: %d", axErr);
			goto done;
		}
		CF_AUTORELEASE(focusedApplication);
		
		[self findWindowURL:&frontWindowURL selectionURLs:&selectionURLStrings windowFrame:&frontWindowBounds ofAXApplication:focusedApplication];
	}
	
	// Numbers returned by AS are funky; adjust to NSWindow coordinates
	if(!NSEqualRects(frontWindowBounds, NSZeroRect)) {
		CGFloat screenHeight = CGRectGetHeight([[NSScreen screens].firstObject frame]);
		frontWindowBounds.origin.y = screenHeight - CGRectGetMinY(frontWindowBounds) - CGRectGetHeight(frontWindowBounds);
	}
	
//	NSLog(@"Front window URL: %@", frontWindowURL);
//	NSLog(@"Selection URLs: %@", selectionURLs);
//	NSLog(@"Front window bounds: %@", NSStringFromRect(frontWindowBounds));
	
done:
	// If there's no explicit WD, but we have a front window URL, try to deduce a working directory from that
	if(!workingDirectory && [frontWindowURL isFileURL]) {
		LSItemInfoRecord outItemInfo;
		if((noErr == LSCopyItemInfoForURL((__bridge CFURLRef)frontWindowURL, kLSRequestAllFlags, &outItemInfo)) &&
		   ((outItemInfo.flags & kLSItemInfoIsPackage) || !(outItemInfo.flags & kLSItemInfoIsContainer))) {
			// It's a package or not a container (i.e. a file); use its parent as the WD
			workingDirectory = frontWindowURL.path.stringByDeletingLastPathComponent;
		} else {
			// It's not a package; use it directly as the WD
			workingDirectory = frontWindowURL.path;
		}
	}
	
	// If there's no explicit WD but we have a selection, try to deduce a working directory from that
	if(!workingDirectory && selectionURLStrings.count) {
		NSURL* url = [NSURL URLWithString:selectionURLStrings.firstObject];
		NSString* path = url.path;
		workingDirectory = path.stringByDeletingLastPathComponent;
	}
	
	// default to the home directory if we *still* don't have an explicit WD
	if(!workingDirectory)
		workingDirectory = NSHomeDirectory();
	
	[termWindowController activateWithWorkingDirectory:workingDirectory
											 selection:selectionURLStrings
										   windowFrame:frontWindowBounds];
	
}

- (BOOL) isAXTrustedPromptIfNot:(BOOL)shouldPrompt
{
    NSDictionary* options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @(shouldPrompt)};

    return (BOOL)AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

#pragma mark URL actions

- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *) __unused replyEvent {
	NSString* urlString = [event paramDescriptorForKeyword:keyDirectObject].stringValue;
	NSURL* url = [NSURL URLWithString:urlString];
	
	if(![url.scheme isEqualToString:@"dterm"])
		return;
	
	NSString* service = url.host;
	
	// Preferences
	if([service isEqualToString:@"prefs"]) {
		NSString* prefsName = url.path;
		if([prefsName isEqualToString:@"/general"])
			[self.prefsWindowController showGeneral:self];
		else if([prefsName isEqualToString:@"/accessibility"])
			[self.prefsWindowController showAccessibility:self];
		else if([prefsName isEqualToString:@"/updates"])
			[self.prefsWindowController showUpdates:self];
	}
}

#pragma mark menu actions

- (IBAction)showAcknowledgments:(id)sender {
	if(!acknowledgmentsWindowController) {
		acknowledgmentsWindowController = [[RTFWindowController alloc] initWithRTFFile:[[NSBundle mainBundle] pathForResource:@"Acknowledgments" ofType:@"rtf"]];
	}
	
	[acknowledgmentsWindowController showWindow:sender];
}

- (IBAction)showLicense:(id)sender {
	if(!licenseWindowController) {
		licenseWindowController = [[RTFWindowController alloc] initWithRTFFile:[[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"]];
	}
	
	[licenseWindowController showWindow:sender];
}

#pragma mark font panel support

- (void)changeFont:(id) __unused sender{
	/*
	 This is the message the font panel sends when a new font is selected
	 */
	
	// Get selected font
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *selectedFont = fontManager.selectedFont;
	if(!selectedFont) {
		selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
	NSFont *panelFont = [fontManager convertFont:selectedFont];
	
	// Get and store details of selected font
	// Note: use fontName, not displayName.  The font name identifies the font to
	// the system, we use a value transformer to show the user the display name
	NSNumber *fontSize = @(panelFont.pointSize);
	
	id currentPrefsValues =
	[NSUserDefaultsController sharedUserDefaultsController].values;
	[currentPrefsValues setValue:panelFont.fontName forKey:DTFontNameKey];
	[currentPrefsValues setValue:fontSize forKey:DTFontSizeKey];
}

@end

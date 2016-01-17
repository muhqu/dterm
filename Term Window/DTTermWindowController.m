//  DTTermWindowController.m
//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTTermWindowController.h"

#import "DTAppController.h"
#import "DTCommandFieldEditor.h"
#import "DTResultsView.h"
#import "DTResultsTextView.h"
#import "DTRunManager.h"
#import "DTShellUtilities.h"
#import "iTerm.h"
#import "iTerm2.h"
#import "iTerm2Nightly.h"
#import "Terminal.h"

#import "WAYTheDarkSide.h"

static void * DTPreferencesContext = &DTPreferencesContext;

@interface DTTermWindowController ()

@property BOOL didCallDeactivate;

@end

@implementation DTTermWindowController

@synthesize workingDirectory, selectedURLs, command, runs, runsController;

- (instancetype)init {
	if((self = [super initWithWindowNibName:@"TermWindow"])) {
		[self setShouldCascadeWindows:NO];
		
		self.command = @"";
		self.runs = [NSMutableArray array];
		
		NSUserDefaultsController *sdc = [NSUserDefaultsController sharedUserDefaultsController];
        for (NSString *defaultKeyPath in [self observedDefaults])
        {
            [sdc addObserver:self forKeyPath:defaultKeyPath options:0 context:DTPreferencesContext];
        }
	}
	
	return self;
}

-(void)dealloc
{
    NSUserDefaultsController *sdc = [NSUserDefaultsController sharedUserDefaultsController];
    for (NSString *defaultKeyPath in [self observedDefaults])
    {
        [sdc removeObserver:self forKeyPath:defaultKeyPath context:DTPreferencesContext];
    }
}

- (NSArray *)observedDefaults
{
    return @[ @"values.DTTextColor", @"values.DTFontName", @"values.DTFontSize" ];
}

- (void)windowDidLoad {
	NSPanel* panel = (NSPanel*)self.window;
	[panel setHidesOnDeactivate:NO];
	
	// Bind the results text storage up
	[resultsTextView bind:@"resultsStorage"
				 toObject:runsController
			  withKeyPath:@"selection.resultsStorage"
				  options:nil];
	
    // HACK to show "proper" placeholder despite in dark mode  (dark mode placeholder is too dark to actually be visible)
    // ... or switch appearance of this ivar?!
    NSDictionary *attr = [NSDictionary dictionaryWithObject:[NSColor lightGrayColor]
                                                     forKey:NSForegroundColorAttributeName];
    NSAttributedString *placeholder = [[NSAttributedString alloc] initWithString:@"no command run"
                                                                      attributes:attr];
    [cmdTextField bind:NSValueBinding
              toObject:runsController
           withKeyPath:@"selection.command"
               options:@{NSNoSelectionPlaceholderBindingOption: placeholder}];
    
    // Swap in the results view for its placeholder
	resultsView.frame = placeholderForResultsView.frame;
	[placeholderForResultsView removeFromSuperview];
	[self.window.contentView addSubview:resultsView];
	
	// Remove the excess action menu items if we're showing the dock icon
    if( ![[NSBundle mainBundle] objectForInfoDictionaryKey:@"LSUIElement"] ) {
        // It's not a UIElement, i.e. the dock icon is shown
        // Remove the menu items up to the last separator
        BOOL wasSeparator = NO;
        do {
            NSMenuItem* lastItem = [actionMenu itemAtIndex:(actionMenu.numberOfItems-1)];
            wasSeparator = lastItem.separatorItem;
            [actionMenu removeItem:lastItem];
        } while(!wasSeparator && actionMenu.numberOfItems);
    }
    
    [self setUpDarkModeHandling];
}

- (id)windowWillReturnFieldEditor:(NSWindow*)window toObject:(id)anObject {
	if(window != self.window)
		return nil;
	if(anObject != commandField)
		return nil;
	
	if(!commandFieldEditor) {
		commandFieldEditor = [[DTCommandFieldEditor alloc] initWithController:self];
	}
	
	return commandFieldEditor;
}

- (void)setCommand:(NSString*)newCommand {
	command = newCommand;
	
	id firstResponder = self.window.firstResponder;
	if([firstResponder isKindOfClass:[DTCommandFieldEditor class]]) {
		// We may be editing.  Make sure the field editor reflects the change too.
		NSTextStorage* textStorage = [firstResponder textStorage];
		[textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.length) 
								   withString:(newCommand ? newCommand : @"")];
	}
}


- (void)activateWithWorkingDirectory:(NSString*)wdPath
						   selection:(NSArray*)selection
						 windowFrame:(NSRect)frame {
	// Set the state variables
	self.workingDirectory = wdPath;
	self.selectedURLs = selection;
		
	// Hide window
	NSWindow* window = self.window;
	window.alphaValue = 0.0;
	
	// Resize text view
	[resultsTextView minSize];
	// Select all of the command field
	[commandFieldEditor setSelectedRange:NSMakeRange(0, commandFieldEditor.string.length)];
	[window makeFirstResponder:commandField];
	
	// If no parent window; use main screen
	if(NSEqualRects(frame, NSZeroRect)) {
		NSScreen* mainScreen = [NSScreen mainScreen];
		frame = mainScreen.visibleFrame;
	}
	
	// Set frame according to parent window location
	CGFloat desiredWidth = fmin(CGRectGetWidth(frame) - 20.0, 640.0);
	NSRect newFrame = NSInsetRect(frame, (CGRectGetWidth(frame) - desiredWidth) / 2.0, 0.0);
	newFrame.size.height = CGRectGetHeight(window.frame) + [resultsTextView desiredHeightChange];
	newFrame.origin.y = CGRectGetMinY(frame) + CGRectGetHeight(frame) - CGRectGetHeight(newFrame);
	[window setFrame:newFrame display:YES];
	
    [self showWindow];
    
    self.didCallDeactivate = NO;
}

- (void)deactivate {
    self.didCallDeactivate = YES;
    
    [self cleanUpOldRuns];
	
    [self hideWindow];
}

- (void)windowDidResignKey:(NSNotification*)notification {
	if(notification.object != self.window)
		return;
	
    // if the user made us resign the key window status (e.g. by clicking outside the window), we want to deactivate
    // but if we get this notification because of us deactivating the window (e.g. after hitting ESC), don't call `-deactivate` again
    //
    if (!self.didCallDeactivate) {
        [self deactivate];
    }
}

- (NSTimeInterval) animationDuration
{
    BOOL animated = YES; // TODO: add user default for animation (and duration?)
    return animated ? 0.1 : 0.;
}

- (void) showWindow
{
    NSTimeInterval duration = [self animationDuration];
    
    [self.window makeKeyAndOrderFront:self];
    
    {
        [NSAnimationContext beginGrouping];
        [NSAnimationContext currentContext].duration = duration;
        [self.window animator].alphaValue = 1.0;
        [NSAnimationContext endGrouping];
    }
}

- (void) hideWindow
{
    NSTimeInterval duration = [self animationDuration];
    
    {
        [NSAnimationContext beginGrouping];
        [NSAnimationContext currentContext].duration = duration;
        [self.window animator].alphaValue = 0.0;
        [NSAnimationContext endGrouping];
    }
    
    [self.window performSelector:NSSelectorFromString(@"orderOut:")
                      withObject:self
                      afterDelay:duration + 0.01f];
}

- (void) cleanUpOldRuns
{
    NSUInteger numRunsToKeep = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:DTResultsToKeepKey];
    if(numRunsToKeep > 100)
        numRunsToKeep = 100;
    
    if(runs.count > numRunsToKeep) {
        // Delete non-running runs until we're below the threshold or are out of runs
        NSMutableArray* newRuns = [self.runs mutableCopy];
        
        unsigned i=0;
        while((newRuns.count > numRunsToKeep) && (i < newRuns.count)) {
            DTRunManager* run = newRuns[i];
            if(run.task)
                i++;
            else
                [newRuns removeObjectAtIndex:i];								 
        }
        
        self.runs = newRuns;
    }
}

- (IBAction)insertSelection:(id) __unused sender {
	NSMutableArray* paths = [NSMutableArray arrayWithCapacity:selectedURLs.count];
	for(NSString* urlString in self.selectedURLs) {
		NSURL* url = [NSURL URLWithString:urlString];
		if(url.fileURL) {
			NSString* newPath = url.path;
			if([newPath hasPrefix:workingDirectory]) {
				newPath = [newPath substringFromIndex:workingDirectory.length];
				if([newPath hasPrefix:@"/"])
					newPath = [newPath substringFromIndex:1];
			}
			[paths addObject:[escapedPath(newPath) mutableCopy]];
		}
	}
	
	[commandFieldEditor insertFiles:paths];
}
- (IBAction)insertSelectionFullPaths:(id) __unused sender {
	NSMutableArray* paths = [NSMutableArray arrayWithCapacity:selectedURLs.count];
	for(NSString* urlString in self.selectedURLs) {
		NSURL* url = [NSURL URLWithString:urlString];
		if(url.fileURL) {
			NSString* newPath = url.path;
			[paths addObject:[escapedPath(newPath) mutableCopy]];
		}
	}
	
	[commandFieldEditor insertFiles:paths];
}
- (IBAction)pullCommandFromResults:(id) __unused sender {
	NSString* resultsCommand = [runsController.selection valueForKey:@"command"];
    
    if (!resultsCommand)
        return;
    
    // At this point, self.command is still the last executed command (?!), so we have to use
    // the length of [commandFieldEditor string] to reflect anything the user's typed since then
    // https://decimus.fogbugz.com/default.asp?11185
    [commandFieldEditor insertText:resultsCommand
                  replacementRange:NSMakeRange(0, commandFieldEditor.string.length)];
}
- (IBAction)executeCommand:(id) __unused sender {
	// Commit editing first
	if(![self.window makeFirstResponder:self.window])
		return;
	
	if(!self.command || !(self.command).length)
		return;
	
    DTRunManager* runManager = [[DTRunManager alloc] initWithWD:self.workingDirectory
                                                      selection:self.selectedURLs
                                                        command:self.command];
    [runsController addObject:runManager];
}

- (IBAction)executeCommandInTerminal:(id) __unused sender {
	// Commit editing first
	if(![self.window makeFirstResponder:self.window])
		return;
	
	NSString* cdCommandString = [NSString stringWithFormat:@"cd %@", escapedPath(self.workingDirectory)];
	
	id iTerm = [SBApplication applicationWithBundleIdentifier:@"net.sourceforge.iTerm"];
	if(!iTerm)
		iTerm = [SBApplication applicationWithBundleIdentifier:@"com.googlecode.iterm2"];
    
    // test for iTerms newer scripting bridge
    if(iTerm && [iTerm respondsToSelector:@selector(createWindowWithDefaultProfileCommand:)]) {
        iTermTerminal *terminal = nil;
        iTermSession  *session  = nil;
        
        if([iTerm isRunning]) {
            [iTerm createWindowWithDefaultProfileCommand:nil];
        }
        terminal = [iTerm valueForKey:@"currentWindow"];
        session = [terminal valueForKey:@"currentSession"];
        
        // write text "cd ~/whatever"
        [session writeContentsOfFile:nil text:cdCommandString];
        
        // write text "thecommand"
        if ([self.command length] > 0) {
            [session writeContentsOfFile:nil text:self.command];
        }
        
        [iTerm activate];
    } else if(iTerm) { // assume old scripting bridge
		iTermTerminal *terminal = nil;
		iTermSession  *session  = nil;
		
		if([iTerm isRunning]) {
			// set terminal to (make new terminal at the end of terminals)
			terminal = [[[iTerm classForScriptingClass:@"terminal"] alloc] init];
			[[iTerm terminals] addObject:terminal];
			
			// set session to (make new session at the end of sessions)
			session = [[[iTerm classForScriptingClass:@"session"] alloc] init];
			[[terminal sessions] addObject:session];
		} else {
			// It wasn't running yet, so just use the "current" terminal/session so we don't open more than one
			terminal = [iTerm valueForKey:@"currentTerminal"];
			session = [terminal valueForKey:@"currentSession"];
		}
		
		// set shell to system attribute "SHELL"
		// exec command shell
		[session execCommand:[DTRunManager shellPath]];
		
		// write text "cd ~/whatever"
		[session writeContentsOfFile:nil text:cdCommandString];
		
        // write text "thecommand"
        if ([self.command length] > 0) {
            [session writeContentsOfFile:nil text:self.command];
        }
		[iTerm activate];
	} else {
		TerminalApplication* terminal = (TerminalApplication *)[SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
		BOOL terminalAlreadyRunning = [terminal isRunning];
		
		TerminalWindow* frontWindow = [terminal windows].firstObject;
		if(![frontWindow exists])
			frontWindow = nil;
		else
			frontWindow = [frontWindow get];
		
		TerminalTab* tab = nil;
		if(frontWindow) {
			if(!terminalAlreadyRunning) {
				tab = [frontWindow tabs].firstObject;
			} else if(/*terminalUsesTabs*/false) {
				tab = [[[terminal classForScriptingClass:@"tab"] alloc] init];
				[[frontWindow tabs] addObject:tab];
			}
		}
		
		tab = [terminal doScript:cdCommandString in:tab];
        
        if ([self.command length] > 0) {
            [terminal doScript:self.command in:tab];
        }
		
		[terminal activate];
	}
}


- (void)cancelOperation:(id) __unused sender {
	[self deactivate];
}

- (IBAction)copyResultsToClipboard:(id) __unused sender {
//	[[NSSound soundNamed:@"Blow"] play];
	//	NSLog(@"Asked to copy results to clipboard");
	
	id selection = runsController.selection;
	NSTextStorage* resultsStorage = [selection valueForKey:@"resultsStorage"];
	if(!resultsStorage)
		return;
	
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:@[NSStringPboardType] owner:self];
	[pb setString:resultsStorage.string forType:NSStringPboardType];
	
	[self deactivate];
}

- (IBAction)cancelCurrentCommand:(id)sender {
	NSArray* selection = runsController.selectedObjects;
	[selection makeObjectsPerformSelector:NSSelectorFromString(@"cancel:") withObject:sender];
}

- (void)requestWindowHeightChange:(CGFloat)dHeight {
	NSWindow* window = self.window;
	
	// Calculate new frame, ignoring window constraint
	NSRect windowFrame = window.frame;
	windowFrame.size.height += dHeight;
	windowFrame.origin.y -= dHeight;
	
	// Adjust bottom edge so it's on the screen
	NSScreen* screen = window.screen;
	NSRect screenRect = screen.visibleFrame;
	dHeight = windowFrame.origin.y - screenRect.origin.y;
	if(dHeight < 0.0) {
		windowFrame.size.height += dHeight;
		windowFrame.origin.y -= dHeight;
	}
	
	[window setFrame:windowFrame
			 display:YES
			 animate:YES];
}

- (NSArray*)completionsForPartialWord:(NSString*)partialWord
							isCommand:(BOOL)isCommand
				  indexOfSelectedItem:(NSInteger*)index
{
    UnusedParameter(index);
    
	BOOL allowFiles = (!isCommand || [partialWord hasPrefix:@"/"] || [partialWord hasPrefix:@"./"] || [partialWord hasPrefix:@"../"]);
	
	NSTask* task = [[NSTask alloc] init];
	task.currentDirectoryPath = self.workingDirectory;
	task.launchPath = @"/bin/bash";
	task.arguments = [DTRunManager argumentsToRunCommand:[NSString stringWithFormat:@"compgen -%@%@%@ %@",
															([[DTRunManager shellPath].lastPathComponent isEqualToString:@"bash"] ? @"a" : @""),
															(isCommand ? @"bc" : @""),
															(allowFiles ? @"df" : @""),
															partialWord]];
	
	// Attach pipe to task's standard output
	NSPipe* newPipe = [NSPipe pipe];
	NSFileHandle* stdOut = newPipe.fileHandleForReading;
	task.standardOutput = newPipe;
	
	// Setting the accessibility flag gives us a sticky egid of 'accessibility', which seems to interfere with shells using .bashrc and whatnot.
	// We temporarily set our gid back before launching to work around this problem.
	// Case 8042: http://fogbugz.decimus.net/default.php?8042
    int egidResult = 0;
	gid_t savedEGID = getegid();
	egidResult = setegid(getgid());
    if (egidResult != 0)
        NSLog(@"WARNING: failed to set EGID");

	[task launch];

	egidResult = setegid(savedEGID);
    if (egidResult != 0)
        NSLog(@"WARNING: failed to set EGID");

	NSData* resultsData = [stdOut readDataToEndOfFile];
	NSString* results = [[NSString alloc] initWithData:resultsData encoding:NSUTF8StringEncoding];
	
	NSMutableSet* completionsSet = [NSMutableSet setWithArray:[results componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
	[completionsSet removeObject:@""];
	
	NSMutableArray* completions = [NSMutableArray arrayWithCapacity:completionsSet.count];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	for(__strong NSString* completion in completionsSet) {
		NSString* actualPath = ([completion hasPrefix:@"/"] ? completion : [workingDirectory stringByAppendingPathComponent:completion]);
		BOOL isDirectory = NO;
		if([fileManager fileExistsAtPath:actualPath isDirectory:&isDirectory] && isDirectory)
			completion = [completion stringByAppendingString:@"/"];
		
		[completions addObject:completion];
	}
	
	if(!completions.count)
		return nil;
	
	[completions sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"length" ascending:YES],
									   [[NSSortDescriptor alloc] initWithKey:@"lowercaseString" ascending:YES]]];
	
	return completions;
}

#pragma mark font/color support

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if(context != DTPreferencesContext){
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if([keyPath isEqualToString:@"values.DTFontName"] || [keyPath isEqualToString:@"values.DTFontSize"]) {
		NSFont* newFont = [NSFont fontWithName:[defaults objectForKey:DTFontNameKey]
										  size:[defaults doubleForKey:DTFontSizeKey]];
		for(DTRunManager* run in runs)
			[run setDisplayFont:newFont];
	} else if([keyPath isEqualToString:@"values.DTTextColor"]) {
		NSColor* newColor = [NSKeyedUnarchiver unarchiveObjectWithData:[defaults objectForKey:DTTextColorKey]];
		for(DTRunManager* run in runs)
			[run setDisplayColor:newColor];
	}
	
	[self.window.contentView setNeedsDisplay:YES];
}

- (CGFloat)resultsCommandFontSize {
	return 10.0;
}

- (void)setUpDarkModeHandling
{
    __weak typeof(self) weakSelf = self;

    // dark
    [WAYTheDarkSide welcomeApplicationWithBlock:^{
        typeof(self) strongSelf = weakSelf;
        // HUD style windows (utilizing the NSHUDWindowMask) now automatically utilize NSVisualEffectView to create a blurred background. Applications should set the NSAppearance with the name NSAppearanceNameVibrantDark on the window to get vibrant and dark controls.
        //  https://developer.apple.com/library/mac/releasenotes/AppKit/RN-AppKitOlderNotes/#X10_10Notes -- "AppKit Release Notes for OS X v10.10"
        strongSelf.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        strongSelf->commandField.focusRingType = NSFocusRingTypeNone;
        // HACK: textfield doesn't handle highlighting text properly when in "VibrantLight" mode (no hightlight is visible)
        //         last checked on 10.11.2
//        strongSelf->commandField.appearance = nil; // counteract hack (a few lines down)
//        [strongSelf->commandField.cell setValue:@(NSTextFieldRoundedBezel) forKeyPath:@"bezelStyle"];
    } immediately:YES];

    // light
    [WAYTheDarkSide outcastApplicationWithBlock:^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        strongSelf->commandField.focusRingType = NSFocusRingTypeDefault;
        // HACK: textfield doesn't handle highlighting text properly when in "VibrantLight" mode (no hightlight is visible)
        //         last checked on 10.11.2
//        strongSelf->commandField.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
//        NSLog(@"bordered: %@", strongSelf->commandField.cell.bordered ? @"YES" : @"NO");
//        NSLog(@"bezeled: %@", strongSelf->commandField.cell.bezeled ? @"YES" : @"NO");
//        NSLog(@"style: %@", [strongSelf->commandField.cell valueForKeyPath:@"bezelStyle"]);
//        [strongSelf->commandField.cell setValue:@(NSTextFieldSquareBezel) forKeyPath:@"bezelStyle"];
        // setting the command fields appearance to Aqua ... or even just changing the bezelStyle will introduce UI glitches when the terminal output "grows" while the window isn't visible ... if you then reactivate the (now taller) window, the new window part will be missing the expected blur, and will instead be completely transparent
        
    } immediately:YES];
}

@end

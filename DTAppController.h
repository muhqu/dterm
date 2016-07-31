//  DTAppController.h
//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

@class DTPrefsWindowController;
@class DTTermWindowController;
@class RTFWindowController;

@class SUUpdater;

extern NSString* const DTResultsToKeepKey;
extern NSString* const DTTextColorKey;
extern NSString* const DTFontNameKey;
extern NSString* const DTFontSizeKey;

extern NSString* const DTGlobalShortcutPreferenceKey;

@interface DTAppController : NSObject 

@property (unsafe_unretained) SUUpdater* sparkleUpdater;
@property (readonly, nonatomic) DTPrefsWindowController* prefsWindowController;
@property (readonly) DTTermWindowController* termWindowController;

- (BOOL) isAXTrustedPromptIfNot:(BOOL)shouldPrompt;

- (IBAction)showPrefs:(id)sender;
- (IBAction)showAcknowledgments:(id)sender;
- (IBAction)showLicense:(id)sender;

@end

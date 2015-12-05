//
//  SRRecorderControl.h
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

@import Cocoa;
#import "SRRecorderCell.h"

@protocol SRRecorderDelegate;

@interface SRRecorderControl : NSControl

#pragma mark *** Aesthetics ***
@property (assign)	BOOL			animates;
@property (assign)	SRRecorderStyle	style;

#pragma mark *** Delegate ***
@property	(assign) id <SRRecorderDelegate> delegate;

#pragma mark *** Key Combination Control ***

@property (assign)	NSUInteger	allowedFlags;

- (BOOL)allowsKeyOnly;
- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord;
- (BOOL)escapeKeysRecord;

@property (assign)		BOOL	canCaptureGlobalHotKeys;
@property (assign)		NSUInteger	requiredFlags;
@property (assign)		KeyCombo	keyCombo;
@property (readonly)	NSString	*keyChars;
@property (readonly)	NSString	*keyCharsIgnoringModifiers;

#pragma mark *** Autosave Control ***

@property (copy)	NSString	*autosaveName;

#pragma mark -

// Returns the displayed key combination if set
@property (readonly)	NSString	*keyComboString;

#pragma mark *** Conversion Methods ***

- (NSUInteger)cocoaToCarbonFlags:(NSUInteger)cocoaFlags;
- (NSUInteger)carbonToCocoaFlags:(NSUInteger)carbonFlags;

#pragma mark *** Binding Methods ***

@property	(copy)	NSDictionary	*objectValue;

@end

// Delegate Methods
@protocol SRRecorderDelegate <NSObject>
@optional
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;
@end

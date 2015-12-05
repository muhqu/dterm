//
//  SRRecorderCell.h
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
#import "SRCommon.h"
#import "SRValidator.h"

#define SRMinWidth 50
#define SRMaxHeight 22

#define SRTransitionFPS 30.0f
#define SRTransitionDuration 0.35f
//#define SRTransitionDuration 2.35
#define SRTransitionFrames (SRTransitionFPS*SRTransitionDuration)
#define SRAnimationAxisIsY YES
#define ShortcutRecorderNewStyleDrawing

#define SRAnimationOffsetRect(X,Y)	(SRAnimationAxisIsY ? NSOffsetRect(X,0.0f,-NSHeight(Y)) : NSOffsetRect(X,NSWidth(Y),0.0f))

@class SRRecorderControl, SRValidator;

enum SRRecorderStyle {
    SRGradientBorderStyle = 0,
    SRGreyStyle = 1
};
typedef enum SRRecorderStyle SRRecorderStyle;

@interface SRRecorderCell : NSActionCell <NSCoding, SRValidatorDelegate>

- (void)resetTrackingRects;

#pragma mark *** Aesthetics ***

+ (BOOL)styleSupportsAnimation:(SRRecorderStyle)style;

@property (assign)		BOOL			animates;
@property (assign)		SRRecorderStyle	style;

#pragma mark *** Delegate ***

@property	(assign)	id				delegate;

#pragma mark *** Responder Control ***

- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

#pragma mark *** Key Combination Control ***

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)flagsChanged:(NSEvent *)theEvent;

@property (assign)	NSUInteger	allowedFlags;
@property (assign)	NSUInteger	requiredFlags;

@property (assign)	BOOL		allowsKeyOnly;
@property (assign)	BOOL		escapeKeysRecord;
- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord;

@property (assign)	BOOL		canCaptureGlobalHotKeys;
@property (assign)	KeyCombo	keyCombo;

#pragma mark *** Autosave Control ***

@property (copy)	NSString	*autosaveName;

// Returns the displayed key combination if set
@property (readonly)	NSString	*keyComboString;
@property (readonly)	NSString	*keyChars;
@property (readonly)	NSString	*keyCharsIgnoringModifiers;

@end

// Delegate Methods
@interface NSObject (SRRecorderCellDelegate)
- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newCombo;
@end

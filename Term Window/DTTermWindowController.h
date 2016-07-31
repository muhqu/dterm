//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

@class DTCommandFieldEditor;
@class DTResultsView;
@class DTResultsTextView;

@interface DTTermWindowController : NSWindowController

@property NSString* workingDirectory;
@property NSArray* selectedURLs;
@property (nonatomic) NSString* command;
@property NSMutableArray* runs;
@property NSArrayController* runsController;

- (void)activateWithWorkingDirectory:(NSString*)wdPath
						   selection:(NSArray*)selection
						 windowFrame:(NSRect)frame;
- (void)deactivate;

- (void)requestWindowHeightChange:(CGFloat)dHeight;

- (IBAction)insertSelection:(id)sender;
- (IBAction)insertSelectionFullPaths:(id)sender;
- (IBAction)pullCommandFromResults:(id)sender;
- (IBAction)executeCommand:(id)sender;
- (IBAction)executeCommandInTerminal:(id)sender;
- (IBAction)copyResultsToClipboard:(id)sender;
- (IBAction)cancelCurrentCommand:(id)sender;

- (NSArray*)completionsForPartialWord:(NSString*)partialWord
							isCommand:(BOOL)isCommand
				  indexOfSelectedItem:(NSInteger*)index;

@end

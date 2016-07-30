/*
 * PathFinder.h
 */

@import AppKit;
@import ScriptingBridge;


@class PathFinderApplication, PathFinderDocument, PathFinderWindow, PathFinderRichText, PathFinderCharacter, PathFinderParagraph, PathFinderWord, PathFinderAttributeRun, PathFinderAttachment, PathFinderFsItem, PathFinderFsFile, PathFinderContainer, PathFinderFsFolder, PathFinderDisk, PathFinderFinderWindow, PathFinderApplication, PathFinderInfoWindow;

typedef enum {
	PathFinderSaveOptionsYes = 'yes ' /* Save the file. */,
	PathFinderSaveOptionsNo = 'no  ' /* Do not save the file. */,
	PathFinderSaveOptionsAsk = 'ask ' /* Ask the user whether or not to save the file. */
} PathFinderSaveOptions;

typedef enum {
	PathFinderPrintingErrorHandlingStandard = 'lwst' /* Standard PostScript error handling */,
	PathFinderPrintingErrorHandlingDetailed = 'lwdt' /* print a detailed report of PostScript errors */
} PathFinderPrintingErrorHandling;



/*
 * Standard Suite
 */

// The application's top-level scripting object.
@interface PathFinderApplication : SBApplication

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *version;  // The version of the application.

- (void) open:(NSArray *)x;  // Open a document.
- (void) print:(id)x withProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) quitSaving:(PathFinderSaveOptions)saving;  // Quit the application.
- (SBObject *) duplicate:(NSArray *)x to:(NSString *)to withProperties:(NSDictionary *)withProperties replacing:(BOOL)replacing;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists:(id)x;  // Verify if an object exists.
- (SBObject *) move:(NSArray *)x to:(NSString *)to replacing:(BOOL)replacing;  // Move object(s) to a new location.
- (void) reveal:(id)x;  // Reveal an item.
- (void) select:(id)x;
- (void) delete:(id)x;
- (void) addToFavorites:(id)x;
- (void) eject:(id)x;
- (void) PFOpen:(id)x using:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo:(id)x;  // Show info window - used by DragThing
- (void) empty;  // Empty Trash

@end

// A Sketch document.
@interface PathFinderDocument : SBObject

@property (copy, readonly) NSString *name;  // The document's name.
@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy, readonly) NSURL *file;  // The document's location on disk.

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end

// A window.
@interface PathFinderWindow : SBObject

@property (copy, readonly) NSString *name;  // The full title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (readonly) BOOL minimizable;  // Whether the window can be minimized.
@property BOOL minimized;  // Whether the window is currently minimized.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.
@property (copy, readonly) PathFinderDocument *document;  // The document whose contents are being displayed in the window.

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end



/*
 * Text Suite
 */

// Rich (styled) text
@interface PathFinderRichText : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property double size;  // The size in points of the first character.

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end

// This subdivides the text into characters.
@interface PathFinderCharacter : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end

// This subdivides the text into paragraphs.
@interface PathFinderParagraph : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end

// This subdivides the text into words.
@interface PathFinderWord : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end

// This subdivides the text into chunks that all have the same attributes.
@interface PathFinderAttributeRun : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end

// Represents an inline text attachment. This class is used mainly for make commands.
@interface PathFinderAttachment : PathFinderRichText

@property (copy, readonly) NSURL *file;  // The path to the file for the attachment


@end



/*
 * Path Finder suite
 */

// A file system item
@interface PathFinderFsItem : SBObject

@property BOOL extensionHidden;
@property BOOL locked;
@property (copy, readonly) NSString *kind;
@property (readonly) NSInteger size;
@property (copy) NSDate *modificationDate;
@property (copy) NSString *name;
@property (copy) NSString *groupPrivileges;
@property (copy) NSString *displayedName;
@property NSInteger labelIndex;
@property (copy) NSString *everyonesPrivileges;
@property (copy, readonly) PathFinderDisk *disk;
@property (copy) NSString *group;
@property (copy) NSString *owner;
@property (copy, readonly) PathFinderInfoWindow *informationWindow;
@property (copy) NSString *ownerPrivileges;
@property (copy, readonly) NSDate *creationDate;
@property (copy, readonly) NSString *nameExtension;
@property (readonly) NSInteger physicalSize;
@property (copy, readonly) PathFinderContainer *container;
@property (copy) NSString *URL;
@property (copy) NSString *POSIXPath;
@property (copy) NSString *path;

- (void) closeSaving:(PathFinderSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) reveal;  // Reveal an item.
- (void) select;
- (BOOL) exists;
- (void) addToFavorites;
- (void) eject;
- (void) PFOpenUsing:(NSString *)using_;  // used by DragThing to open a folder
- (void) PFInfo;  // Show info window - used by DragThing

@end

@interface PathFinderFsFile : PathFinderFsItem

@property (copy) NSString *fileType;
@property (copy) NSString *creatorType;


@end

// An item that contains other items
@interface PathFinderContainer : PathFinderFsItem

- (SBElementArray *) fsFolders;
- (SBElementArray *) fsFiles;


@end

@interface PathFinderFsFolder : PathFinderContainer


@end

@interface PathFinderDisk : PathFinderContainer

@property (readonly) BOOL localVolume;
@property (readonly) BOOL startup;
@property (readonly) BOOL ejectable;
@property (readonly) NSInteger capacity;
@property (readonly) NSInteger freeSpace;


@end

// A Finder Window
@interface PathFinderFinderWindow : PathFinderWindow

@property (copy) PathFinderContainer *target;
@property (copy) NSString *currentView;


@end

// This class represents Path Finder.
@interface PathFinderApplication (PathFinderSuite)

- (SBElementArray *) finderWindows;
- (SBElementArray *) disks;
- (SBElementArray *) infoWindows;

@property (copy, readonly) PathFinderFsFolder *home;
@property (copy) NSArray *selection;
@property (copy, readonly) PathFinderDisk *startupDisk;
@property (copy, readonly) PathFinderFsFolder *desktop;
@property (copy, readonly) SBObject *trash;

@end

// An Info Window
@interface PathFinderInfoWindow : PathFinderWindow

@property (copy, readonly) PathFinderFsItem *item;


@end


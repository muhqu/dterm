//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTTermWindowContentView.h"

@interface DTTermWindowContentView ()
{
    IBOutlet NSTextField* workingDirectoryTextField;
    IBOutlet NSTextField* commandTextField;
    IBOutlet NSButton* actionButton;
    
    IBOutlet DTResultsView* resultsView;
    
    BOOL alreadySizing;
}
@end

@implementation DTTermWindowContentView

//- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
//	NSSize boundsSize = [self bounds].size;
//	
//	NSRect wdFrame = [workingDirectoryTextField frame];
//	wdFrame = NSMakeRect(20.0, boundsSize.height - 20.0, boundsSize.width-40.0, wdFrame.size.height);
//	[workingDirectoryTextField setFrame:wdFrame];
//	
//	NSRect actionFrame = [actionButton frame];
//	actionFrame.origin = NSMakePoint(boundsSize.width - 20.0 - actionFrame.size.width, wdFrame.origin.y - wdFrame.size.height - 8.0);
//	[actionButton setFrameOrigin:actionFrame.origin];
//	
//	NSRect cmdFrame = [commandTextField frame];
//	cmdFrame.origin = NSMakePoint(20.0, wdFrame.origin.y - wdFrame.size.height - 8.0);
//	cmdFrame.size.width = actionFrame.origin.x - cmdFrame.origin.x - 8.0;
//	[commandTextField setFrame:cmdFrame];
//	
//	NSRect progressFrame = [runningIndicator frame];
//	progressFrame.origin = NSMakePoint(20.0, cmdFrame.origin.y - cmdFrame.size.height - 8.0);
//	[runningIndicator setFrameOrigin:progressFrame.origin];
//	
//	NSRect resultsFrame = [resultsScrollView frame];
//	resultsFrame.origin = NSMakePoint(progressFrame.origin.x + progressFrame.size.width + 8.0, 8.0);//progressFrame.origin.y);
//	resultsFrame.size.width = boundsSize.width - 20.0 - resultsFrame.origin.x;
//	resultsFrame.size.height = progressFrame.origin.y + progressFrame.size.height - 10.0;
//	if(resultsFrame.size.height < 0.0)
//		resultsFrame.size.height = 0.0;
//	[resultsScrollView setFrame:resultsFrame];
////	NSLog(@"-[DTTermWindowContentView resizeSubviewsWithOldSize:] ending resultsFrame: %@", NSStringFromRect(resultsFrame));
//}

@end

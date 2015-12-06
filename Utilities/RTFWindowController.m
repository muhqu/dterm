//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "RTFWindowController.h"

@implementation RTFWindowController

- (instancetype)initWithRTFFile:(NSString*)inRTFPath {
	if((self = [super initWithWindowNibName:@"RTFWindow"])) {
		self.rtfPath = inRTFPath;
		self.windowTitle = inRTFPath.lastPathComponent.stringByDeletingPathExtension;
	}
	
	return self;
}

@end

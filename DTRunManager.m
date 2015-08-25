//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTRunManager.h"

#import "DTAppController.h"


#define DTUserDefault_ShellPath @"ShellPath"


@interface DTRunManager ()
@property NSTask* task;
- (void)launch;
- (void)processResultsData;
- (void)handleEscapeSequenceWithType:(UInt8)type params:(NSArray*)params;
@end

@implementation DTRunManager

@synthesize workingDirectory, selectedURLStrings, command, task, resultsStorage;

+ (NSString*)shellPath {
	static NSString* sharedPath = nil;
	if(!sharedPath) {
		sharedPath = [[NSUserDefaults standardUserDefaults] stringForKey:DTUserDefault_ShellPath];
		
		if(!sharedPath || ![sharedPath hasPrefix:@"/"]) {
			NSDictionary* env = [[NSProcessInfo processInfo] environment];
			sharedPath = env[@"SHELL"];
		}
		
		if(!sharedPath)
			sharedPath = @"/bin/bash";
	}
	
	return sharedPath;
}

+ (NSArray*)argumentsToRunCommand:(NSString*)command {
	NSString* shell = [[DTRunManager shellPath] lastPathComponent];
	if([shell isEqualToString:@"bash"] || [shell isEqualToString:@"sh"])
		return @[@"-l", @"-i", @"-c", command];
	else
		return @[@"-i", @"-c", command];
}

-(instancetype)init NS_UNAVAILABLE
{
    NSAssert(NO, @"must call -initWithWD:selection:command:");
    @throw nil;
}

- (instancetype)initWithWD:(NSString*)_wd selection:(NSArray*)_selection command:(NSString*)_command {
	if((self = [super init])) {
		resultsStorage = [[NSTextStorage alloc] init];
		currentAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							 [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] objectForKey:DTFontNameKey]
											 size:[[NSUserDefaults standardUserDefaults] doubleForKey:DTFontSizeKey]], NSFontAttributeName,
							 [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:DTTextColorKey]], NSForegroundColorAttributeName,
							 nil];
		self.workingDirectory = _wd;
		self.selectedURLStrings = _selection;
		command = _command;
		
		NSMutableString* selectedFilesEnvString = [NSMutableString string];
		for(NSString* urlString in _selection) {
			NSURL* url = [NSURL URLWithString:urlString];
			if([url isFileURL]) {
				NSString* newPath = [url path];
				
				if([selectedFilesEnvString length])
					[selectedFilesEnvString appendString:@" "];
				
				[selectedFilesEnvString appendString:newPath];
			}
		}
		if([selectedFilesEnvString length])
			setenv("DTERM_SELECTED_FILES", [selectedFilesEnvString fileSystemRepresentation], 1);
		else
			unsetenv("DTERM_SELECTED_FILES");
		
        [self launch];
	}
	
	return self;
}

- (void)launch {
	// Set up basic task parameters
	self.task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath:self.workingDirectory];
	[task setLaunchPath:[DTRunManager shellPath]];
	[task setArguments:[DTRunManager argumentsToRunCommand:self.command]];
	
	// Attach pipe to task's standard output
	NSPipe* newPipe = [NSPipe pipe];
	stdOut = [newPipe fileHandleForReading];
	[task setStandardOutput:newPipe];
	
	// Attach pipe to task's standard err
	newPipe = [NSPipe pipe];
	stdErr = [newPipe fileHandleForReading];
	[task setStandardError:newPipe];
	
//	NSLog(@"Executing command %@ with args %@ in WD %@", [task launchPath], [[task arguments] componentsJoinedByString:@" "], [task currentDirectoryPath]);
	
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(readData:)
												 name:NSFileHandleReadCompletionNotification
											   object:stdOut];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(readData:)
												 name:NSFileHandleReadCompletionNotification
											   object:stdErr];
	
	[stdOut readInBackgroundAndNotify];
	[stdErr readInBackgroundAndNotify];
}

- (void)readData:(NSNotification*)notification {
	id fileHandle = [notification object];
	if((fileHandle == stdOut) || (fileHandle == stdErr)) {
		NSData* data = [notification userInfo][NSFileHandleNotificationDataItem];
		if([data length]) {
			// Data was returned; append it
			if(!unprocessedResultsData)
				unprocessedResultsData = [NSMutableData dataWithCapacity:[data length]];
			[unprocessedResultsData appendData:data];
			
			[self processResultsData];
			
			// Reschedule for the next round of reading
			[fileHandle readInBackgroundAndNotify];
		} else {
			// No data, so this handle is done
			if(fileHandle == stdOut)
				stdOut = nil;
			if(fileHandle == stdErr)
				stdErr = nil;
			
			// If both handles have closed, we're done with the task too
			if(!stdOut && !stdErr) {				
				self.task = nil;
				
                // TODO: re-add Growl support
//				DTTermWindowController* termWindowController = [APP_DELEGATE termWindowController];
//				if(![[termWindowController window] isVisible] || ![[[termWindowController runsController] selectedObjects] containsObject:self]) {
//					NSArray* lines = [[self.resultsStorage string] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//					NSString* lastLine = [lines lastObject];
//					if(![lastLine length])
//						lastLine = NSLocalizedString(@"<no results>", @"Growl notification description");
//					[GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Command finished: %@", @"Growl notification title"), self.command]
//												description:lastLine 
//										   notificationName:@"DTCommandCompleted"
//												   iconData:nil 
//												   priority:0 
//												   isSticky:NO 
//											   clickContext:nil];
//				}
			}
		}
	}
}

#define ASCII_BS	0x08
#define ASCII_CR	0x0D
#define ASCII_ESC	0x1B

- (void)processResultsData {
	if(![unprocessedResultsData length])
		return;
	
	const UInt8* data = [unprocessedResultsData bytes];
	NSUInteger remainingLength = [unprocessedResultsData length];
	
	[resultsStorage beginEditing];
	
	// Add our trailing whitespace back on
	if([trailingWhitespace length])
		[resultsStorage appendAttributedString:trailingWhitespace];
	trailingWhitespace = nil;
	
	// Process the data
	while(remainingLength) {
		// Handle escape sequences
		if(data[0] == ASCII_ESC) {
			// If we don't have enough chars for ESC[x (a minimal escape sequence), wait for more data
			if(remainingLength < 3)
				break;
			
			if(data[1] == '[') {
				// Pull off the ESC[
				data += 2;
				remainingLength -= 2;
				
				// Grab ##;###;### sequence
				NSUInteger lengthOfEscapeString = 0;
				while(((lengthOfEscapeString < remainingLength) &&
					  ((data[lengthOfEscapeString] >= '0') && (data[lengthOfEscapeString] <= '9'))) ||
					  (data[lengthOfEscapeString] == ';'))
					lengthOfEscapeString++;
				
				// If we ate up all of the rest of the string without a terminating char, wait for more data
				if(lengthOfEscapeString == remainingLength) {
					// Only after putting back the ESC[, of course
					// https://decimus.fogbugz.com/default.asp?10711
					data -= 2;
					remainingLength += 2;
					
					break;
				}
				
				NSString* escapeString = [[NSString alloc] initWithBytes:data
																  length:lengthOfEscapeString
																encoding:NSUTF8StringEncoding];
				[self handleEscapeSequenceWithType:data[lengthOfEscapeString]
											params:[escapeString componentsSeparatedByString:@";"]];
				
				data += (lengthOfEscapeString + 1);
				remainingLength -= (lengthOfEscapeString + 1);
			} else {
				// Hmmm...malformed ESC sequence without the [...
				// Just pass it through as normal characters, I guess...
				data++;
				remainingLength--;
			}
		}
		
		// Handle backspace characters
		else if(data[0] == ASCII_BS) {
			cursorLoc--;
			data++;
			remainingLength--;
		}
		
		// Handle CR
		else if(data[0] == ASCII_CR) {
			data++;
			remainingLength--;
			
			// Go back until we find a newline
			while(cursorLoc && ([[resultsStorage string] characterAtIndex:(cursorLoc-1)] != '\n'))
				cursorLoc--;
		}
		
		// Handle cursor not at end of string
		else if(cursorLoc != [resultsStorage length]) {
			unichar oldChar = [[resultsStorage string] characterAtIndex:cursorLoc];
			unichar newChar = data[0];
			
			if(oldChar == newChar) {
				// bold it if they're identical
				[resultsStorage applyFontTraits:NSBoldFontMask range:NSMakeRange(cursorLoc, 1)];
			} else if((oldChar == '_') || (newChar == '_')) {
				// If one is an underscore, underline the other char
				if(oldChar == '_') {
					// Need to replace the old underscore with the new real char
					[resultsStorage replaceCharactersInRange:NSMakeRange(cursorLoc, 1)
												  withString:[NSString stringWithCharacters:&newChar length:1]];
				}
				[resultsStorage addAttributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle|NSUnderlinePatternSolid)}
										range:NSMakeRange(cursorLoc, 1)];
			} else if(newChar == '\n') {
				// For newlines, seek forward to the next newline
				while((cursorLoc < [resultsStorage length]) && ([[resultsStorage string] characterAtIndex:cursorLoc] != '\n'))
					cursorLoc++;
				// If we're at the end, we didn't find one, so append one
				if(cursorLoc == [resultsStorage length])
					[resultsStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"
																						   attributes:[currentAttributes copy]]];
				
				// The code outside this if-else if-... will skip over the \n the cursor is now at
			} else {
				// Just overwrite the old character
				[resultsStorage replaceCharactersInRange:NSMakeRange(cursorLoc, 1)
											  withString:[NSString stringWithCharacters:&newChar length:1]];
			}
			
			cursorLoc++;
			data++;
			remainingLength--;
		}
		
		// Normal case; just appending bytes
		else {
			NSUInteger lengthOfNormalString = 0;
			while((lengthOfNormalString < remainingLength) &&
				  (data[lengthOfNormalString] != ASCII_BS) &&
				  (data[lengthOfNormalString] != ASCII_CR) &&
				  (data[lengthOfNormalString] != ASCII_ESC))
				lengthOfNormalString++;
			
			if(lengthOfNormalString > 0) {
				NSString* plainString = nil;
				
				while(!plainString && (lengthOfNormalString > 0)) {
					plainString = [[NSString alloc] initWithBytes:data
														   length:lengthOfNormalString
														 encoding:NSUTF8StringEncoding];
					
					if(!plainString) {
						// Failed!  Cut off half of it and try again, rounding down so we'll eventually hit zero
						lengthOfNormalString = (NSUInteger)trunc(lengthOfNormalString / 2.0);
					}
				}
				
				if(!plainString) {
					// If we couldn't get a good string, fill in a '?' and skip a byte to try and get back on track
					plainString = @"?";
					lengthOfNormalString = 1;
				}
				
				[resultsStorage appendAttributedString:[[NSAttributedString alloc] initWithString:plainString
																					   attributes:[currentAttributes copy]]];
					
				data += lengthOfNormalString;
				remainingLength -= lengthOfNormalString;
				cursorLoc += [plainString length];
				
				
			}
		}
	}
	
	// Pull any trailing whitespace off
	NSCharacterSet* wsChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSUInteger wsStart = [resultsStorage length];
	while((wsStart > 0) && [wsChars characterIsMember:[[resultsStorage string] characterAtIndex:(wsStart-1)]])
		wsStart--;
	if(wsStart < [resultsStorage length]) {
		NSRange wsRange = NSMakeRange(wsStart, [resultsStorage length]-wsStart);
		trailingWhitespace = [resultsStorage attributedSubstringFromRange:wsRange];
		[resultsStorage deleteCharactersInRange:wsRange];
	}
	
	[resultsStorage endEditing];
	
	if(remainingLength) {
		if(remainingLength != [unprocessedResultsData length])
			unprocessedResultsData = [NSMutableData dataWithBytes:data length:remainingLength];
	} else {
		[unprocessedResultsData setLength:0];
	}
}

- (void)handleEscapeSequenceWithType:(UInt8)type params:(NSArray*)params {
	switch(type) {
		case 'm':
		{
			NSColor* fgColor = currentAttributes[NSForegroundColorAttributeName];
			NSColor* bgColor = currentAttributes[NSBackgroundColorAttributeName];
			
			for(NSString* paramString in params) {
				switch([paramString integerValue]) {
					case 0:		// turn off all attributes
						fgColor = nil;
						bgColor = nil;
						[currentAttributes removeObjectForKey:NSUnderlineStyleAttributeName];
						currentAttributes[NSFontAttributeName] = [[NSFontManager sharedFontManager] convertFont:currentAttributes[NSFontAttributeName]
																					 toNotHaveTrait:NSFontBoldTrait];
						break;
					case 1:		// bold
						currentAttributes[NSFontAttributeName] = [[NSFontManager sharedFontManager] convertFont:currentAttributes[NSFontAttributeName]
																						toHaveTrait:NSFontBoldTrait];
						break;
					case 4:		// underline single
						currentAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
						break;
					case 5:		// blink
						// not supported
						break;
					case 7:		// FG black on BG white
						fgColor = [NSColor blackColor];
						bgColor = [NSColor whiteColor];
						break;
					case 8:		// "hidden"
						fgColor = bgColor;
						break;
					case 21:	// underline double
						currentAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleDouble);
						break;
					case 22:	// stop bold
						currentAttributes[NSFontAttributeName] = [[NSFontManager sharedFontManager] convertFont:currentAttributes[NSFontAttributeName]
																					 toNotHaveTrait:NSFontBoldTrait];
						break;
					case 24:	// underline none
						currentAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleNone);
						break;
					case 30:	// FG black
						fgColor = [NSColor blackColor];
						break;
					case 31:	// FG red
						fgColor = [NSColor redColor];
						break;
					case 32:	// FG green
						fgColor = [NSColor greenColor];
						break;
					case 33:	// FG yellow
						fgColor = [NSColor yellowColor];
						break;
					case 34:	// FG blue
						fgColor = [NSColor blueColor];
						break;
					case 35:	// FG magenta
						fgColor = [NSColor magentaColor];
						break;
					case 36:	// FG cyan
						fgColor = [NSColor cyanColor];
						break;
					case 37:	// FG white
						fgColor = [NSColor whiteColor];
						break;
					case 39:	// FG reset
						fgColor = nil;
						break;
					case 40:	// BG black
						bgColor = [NSColor blackColor];
						break;
					case 41:	// BG red
						bgColor = [NSColor redColor];
						break;
					case 42:	// BG green
						bgColor = [NSColor greenColor];
						break;
					case 43:	// BG yellow
						bgColor = [NSColor yellowColor];
						break;
					case 44:	// BG blue
						bgColor = [NSColor blueColor];
						break;
					case 45:	// BG magenta
						bgColor = [NSColor magentaColor];
						break;
					case 46:	// BG cyan
						bgColor = [NSColor cyanColor];
						break;
					case 47:	// BG white
						bgColor = [NSColor whiteColor];
						break;
					case 49:	// BG reset
						bgColor = nil;
						break;
					case 90:	// FG bright black
						fgColor = [NSColor blackColor];
						break;
					case 91:	// FG bright red
						fgColor = [NSColor redColor];
						break;
					case 92:	// FG bright green
						fgColor = [NSColor greenColor];
						break;
					case 93:	// FG bright yellow
						fgColor = [NSColor yellowColor];
						break;
					case 94:	// FG bright blue
						fgColor = [NSColor blueColor];
						break;
					case 95:	// FG bright magenta
						fgColor = [NSColor magentaColor];
						break;
					case 96:	// FG bright cyan
						fgColor = [NSColor cyanColor];
						break;
					case 97:	// FG bright white
						fgColor = [NSColor whiteColor];
						break;
					case 100:	// BG bright black
						bgColor = [NSColor blackColor];
						break;
					case 101:	// BG bright red
						bgColor = [NSColor redColor];
						break;
					case 102:	// BG bright green
						bgColor = [NSColor greenColor];
						break;
					case 103:	// BG bright yellow
						bgColor = [NSColor yellowColor];
						break;
					case 104:	// BG bright blue
						bgColor = [NSColor blueColor];
						break;
					case 105:	// BG bright magenta
						bgColor = [NSColor magentaColor];
						break;
					case 106:	// BG bright cyan
						bgColor = [NSColor cyanColor];
						break;
					case 107:	// BG bright white
						bgColor = [NSColor whiteColor];
						break;
				}
			}
			
			NSColor* standardFGColor = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:DTTextColorKey]];
			fgColor = ( fgColor ? [fgColor colorWithAlphaComponent:[standardFGColor alphaComponent]] : standardFGColor );
			bgColor = [bgColor colorWithAlphaComponent:[standardFGColor alphaComponent]];
			
			currentAttributes[NSForegroundColorAttributeName] = fgColor;
			if(bgColor)
				currentAttributes[NSBackgroundColorAttributeName] = bgColor;
			else
				[currentAttributes removeObjectForKey:NSBackgroundColorAttributeName];
		}
			break;
			
			
		default:
			// If we don't handle it, just ignore it
#ifdef DEVBUILD
			NSLog(@"Got '%c' escape sequence with: %@", type, params);
#endif
			break;
	}
}

- (IBAction)cancel:(id) __unused sender {
	@try {
		if([task isRunning]) {
			// Bash catches basically all signals, but terminates on SIGHUP, terminating subprocesses as well
			kill([task processIdentifier], SIGHUP);
		}
		
		self.task = nil;
		stdOut = nil;
		stdErr = nil;
	}
	@catch (NSException* e) {
		NSLog(@"Caught exception terminating process: %@", e);
	}
}

#pragma mark display support

- (void)setDisplayFont:(NSFont*)font {
	[resultsStorage beginEditing];
	[resultsStorage addAttribute:NSFontAttributeName
						   value:font
						   range:NSMakeRange(0, [resultsStorage length])];
	[resultsStorage endEditing];
	
	currentAttributes[NSFontAttributeName] = font;
}

- (void)setDisplayColor:(NSColor*)color {
	[resultsStorage beginEditing];
	[resultsStorage addAttribute:NSForegroundColorAttributeName
						   value:color
						   range:NSMakeRange(0, [resultsStorage length])];
	[resultsStorage endEditing];
	
	currentAttributes[NSForegroundColorAttributeName] = color;
}

@end

//  Copyright (c) 2007-2010 Decimus Software, Inc. All rights reserved.

#import "DTCommandFieldEditor.h"

#import "DTShellUtilities.h"
#import "DTTermWindowController.h"
#import "DTAppController.h"  // for -changeFont:

@interface DTCommandFieldEditor ()
{
    DTTermWindowController* controller;
}

@end

@implementation DTCommandFieldEditor

@dynamic isFirstResponder;

- (instancetype)initWithController:(DTTermWindowController*)_controller {
	if((self = [super init])) {
		controller = _controller;
		
		[self setAutomaticLinkDetectionEnabled:NO];
		[self setAutomaticQuoteSubstitutionEnabled:NO];
		[self setContinuousSpellCheckingEnabled:NO];
		[self setGrammarCheckingEnabled:NO];
		[self setRichText:NO];
		[self setSmartInsertDeleteEnabled:NO];
		[self setUsesFindPanel:NO];
		[self setUsesFontPanel:NO];
		[self setUsesRuler:NO];
		[self setFieldEditor:YES];
	}
	
	return self;
}

- (BOOL)isFirstResponder {
	return [controller.window.firstResponder isEqual:self];
}

- (void)insertTab:(id)sender {
	// Need to have exactly one selection
	NSArray* selectedRanges = self.selectedRanges;
	if(selectedRanges.count == 1) {
		// Selection needs to be zero length
		NSRange selectedRange = [selectedRanges.firstObject rangeValue];
		if(selectedRange.length == 0) {
			// If it's at the end of the field, do the autocompletion
			if(selectedRange.location == self.string.length) {
				[self complete:sender];
				return;
			} else {
				// If just before a space, do the autocompletion
				selectedRange.length = 1;
				NSString* nextChar = [self.string substringWithRange:selectedRange];
				if(!nextChar || !nextChar.length || [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[nextChar characterAtIndex:0]]) {
					[self complete:sender];
					return;
				}
			}
		}
	}

	[super insertTab:sender];
}

- (NSRange)rangeForUserCompletion {
	NSRange selectedRange = self.selectedRanges.firstObject.rangeValue;
	NSString* str = self.string;
	
	return lastShellWordBeforeIndex(str, selectedRange.location);
}

- (NSArray*)completionsForPartialWordRange:(NSRange)charRange
					   indexOfSelectedItem:(NSInteger*)index {
	NSString* partialWord = [self.string substringWithRange:charRange];
	if(!partialWord)
		return nil;
	
	NSArray* rawCompletions = [controller completionsForPartialWord:partialWord
														  isCommand:(charRange.location == 0)
												indexOfSelectedItem:index];
	
	BOOL shouldBeEscaped = ![unescapedPath(partialWord) isEqualToString:partialWord] ||	// when unescaped, it was different (so was likely escaped in the first place)
							[escapedPath(partialWord) isEqualToString:partialWord]; // or it doesn't change when escaped, meaning that there's been no need to escape yet
	
	NSMutableArray* completions = [NSMutableArray arrayWithCapacity:rawCompletions.count];
	for(__strong NSString* completion in rawCompletions) {
		if(shouldBeEscaped)
			completion = escapedPath(completion);
		
		[completions addObject:completion];
	}
	
	@try {
		// Find the common prefix
		NSString* prefix = nil;
		for(NSString* completion in completions) {
			if(!prefix)
				prefix = completion;
			else
				prefix = [prefix commonPrefixWithString:completion
                                                options:(NSStringCompareOptions)(NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch)];
		}
		
		// If there's a common prefix, we just go ahead and insert it in this case and cancel completion, to behave like bash.
		// The user can trigger completion again if they want the different options.
		if(prefix.length && ![prefix isEqualToString:partialWord]) {
			//NSLog(@"found common prefix: %@", prefix);
			[self insertText:prefix replacementRange:self.rangeForUserCompletion];
			
			return nil;
		}
	}
	@catch (NSException* e) {
		NSLog(@"Caught exception trying to find a common prefix: %@", e);
	}
	
	if(completions.count <= 1)
		return nil;
	if(completions.count)
		*index = -1;
	return completions;
}

- (void)insertFiles:(NSArray*)selectedPaths {
	NSString* insertString = [selectedPaths componentsJoinedByString:@" "];
	[self insertText:insertString replacementRange:self.selectedRange];
}

// We don't want this to eat our font changes
- (void)changeFont:(id)sender {
	[APP_DELEGATE changeFont:sender];
}

@end

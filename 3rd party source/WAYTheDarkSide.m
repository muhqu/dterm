//
//  WAYTheDarkSide.h
//  WAYTheDarkSideDemo
//
//  Created by Raffael Hannemann on 18.11.14.
//  Copyright (c) 2014 We Are Yeah!. All rights reserved.
//  Visit weAreYeah.com or follow @weareYeah for updates.
//
//  Licensed under the BSD License <http://www.opensource.org/licenses/bsd-license>
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "WAYTheDarkSide.h"

NSString *const kWAYTheDarkSideGlobalPersistentDomainInterfaceStyleKey = @"AppleInterfaceStyle";
NSString *const kWAYTheDarkSideGlobalPersistentDomainDarkInterfaceStyleValue = @"Dark";
NSString *const kWAYTheDarkSideAppleInterfaceThemeChangedNotification = @"AppleInterfaceThemeChangedNotification";

static BOOL _WAYTheDarkSideRecentValue;
static BOOL _WAYTheDarkSideValueKnown;
static NSMapTable *_WAYTheDarkSideEnteringBlocksMapTable;
static NSMapTable *_WAYTheDarkSideLeavingBlocksMapTable;

@implementation WAYTheDarkSide

+ (void) initialize {

	// Initialize two NSMapTables which hold the blocks per object.
	// NSMapTables are used since NSDictionary copies the keys and not all objects implement NSCopying
	_WAYTheDarkSideEnteringBlocksMapTable = [NSMapTable weakToStrongObjectsMapTable];
	_WAYTheDarkSideLeavingBlocksMapTable = [NSMapTable weakToStrongObjectsMapTable];

	// Subscribe to the Distributed Notification for the Interface Style switch
	[[NSDistributedNotificationCenter defaultCenter] addObserverForName:kWAYTheDarkSideAppleInterfaceThemeChangedNotification
																 object:nil
																  queue:[NSOperationQueue mainQueue]
															 usingBlock:^(NSNotification *notification) {
																 BOOL isDarkMode = [self applicationIsOnTheDarkSide];
																 // The blocks are only performed if an actual change happened
																 if (!_WAYTheDarkSideValueKnown || _WAYTheDarkSideRecentValue!=isDarkMode) {
																	 [self _broadcastDarkMode:isDarkMode];
																	 _WAYTheDarkSideRecentValue = isDarkMode;
																	 _WAYTheDarkSideValueKnown = YES;
																 }
															 }];
}

+ (BOOL) applicationReadyForTheDarkSide {
	return NSAppKitVersionNumber > NSAppKitVersionNumber10_9;
}

+ (BOOL) applicationIsOnTheDarkSide {
	NSDictionary *globalPersistentDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
	@try {
		NSString *interfaceStyle = [globalPersistentDomain valueForKey:kWAYTheDarkSideGlobalPersistentDomainInterfaceStyleKey];
		return [interfaceStyle isEqualToString:kWAYTheDarkSideGlobalPersistentDomainDarkInterfaceStyleValue];
	}
	@catch (NSException *exception) {
		return NO;
	}
}

+ (void) _broadcastDarkMode:(BOOL) isDarkMode {
	NSEnumerator *e = [(isDarkMode)?_WAYTheDarkSideEnteringBlocksMapTable:_WAYTheDarkSideLeavingBlocksMapTable objectEnumerator];
	
	for ( void(^block)(void) in e.allObjects) {
		if (block)
			block();
	}
}

+ (void) welcomeObject:(id)object withBlock:(void (^)(void))eventHandler
		   immediately:(BOOL)flag {
#ifdef DEBUG
	if ([_WAYTheDarkSideEnteringBlocksMapTable objectForKey:object]) {
		NSLog(@"WARNING: Re-defining block for object '%@' which is performed while entering the Dark Mode.", object);
	}
#endif
	[_WAYTheDarkSideEnteringBlocksMapTable setObject:[eventHandler copy]
												forKey:object];
	if (flag && [self applicationIsOnTheDarkSide]) {
		eventHandler();
	}
}

+ (void) outcastObject:(id)object withBlock:(void (^)(void))eventHandler
		   immediately:(BOOL)flag {
#ifdef DEBUG
	if ([_WAYTheDarkSideLeavingBlocksMapTable objectForKey:object]) {
		NSLog(@"WARNING: Re-defining block for object '%@' which is performed while entering the Dark Mode.", object);
	}
#endif
	[_WAYTheDarkSideLeavingBlocksMapTable setObject:[eventHandler copy]
											   forKey:object];
	if (flag && ![self applicationIsOnTheDarkSide]) {
		eventHandler();
	}
}

+ (void) welcomeApplicationWithBlock:(void (^)(void))eventHandler immediately:(BOOL)flag {
	[self welcomeObject:[NSApplication sharedApplication].delegate
			  withBlock:eventHandler
			immediately:flag];
}

+ (void) outcastApplicationWithBlock:(void (^)(void))eventHandler immediately:(BOOL)flag {
	[self outcastObject:[NSApplication sharedApplication].delegate
			  withBlock:eventHandler
			immediately:flag];
}

@end

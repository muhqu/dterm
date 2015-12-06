//  Copyright (c) 2007-2011 Decimus Software, Inc. All rights reserved.

#import "DTPrefsAXController.h"

#import "DTAppController.h"
#import "DTBlackRedStatusTransformer.h"


@interface DTPrefsAXController ()
@property (readwrite) BOOL axGeneralAccessEnabled;
@end


@implementation DTPrefsAXController

+ (void)initialize {
	DTBlackRedStatusTransformer* vt = [[DTBlackRedStatusTransformer alloc] init];
	[NSValueTransformer setValueTransformer:vt forName:@"DTBlackRedStatusTransformer"];
}

#pragma mark accessors

- (BOOL)axAppTrusted {
	return (BOOL)[(DTAppController *)APP_DELEGATE isAXTrustedPromptIfNot:NO];
}

+ (NSSet*) keyPathsForValuesAffectingAxTrustStatusString {
	return [NSSet setWithObject:@"axAppTrusted"];
}
- (NSString*)axTrustStatusString {
	if(self.axAppTrusted)
		return NSLocalizedString(@"trusted", @"Accessibility API trust status tag");
	else
		return NSLocalizedString(@"not trusted", @"Accessibility API trust status tag");
}

- (void)recheckGeneralAXAccess {
	self.axGeneralAccessEnabled = (BOOL)[(DTAppController *)APP_DELEGATE isAXTrustedPromptIfNot:NO];
}

+ (NSSet*)keyPathsForValuesAffectingAxGeneralAccessEnabledString {
	return [NSSet setWithObjects:
	        @"axGeneralAccessEnabled",
	        nil];
}
- (NSString*)axGeneralAccessEnabledString {
	if(self.axGeneralAccessEnabled)
		return NSLocalizedString(@"enabled", @"Accessibility API enabledness status tag");
	else
		return NSLocalizedString(@"disabled", @"Accessibility API enabledness status tag");
}

#pragma mark actions

- (IBAction)setAXTrusted:(id) __unused sender {
    BOOL isTrusted = [(DTAppController *)APP_DELEGATE isAXTrustedPromptIfNot:YES];

    if ( isTrusted )
    {
        return;
    }

    NSAlert* relaunchAlert = [[NSAlert alloc] init];
    relaunchAlert.messageText = NSLocalizedString(@"Trust settings updated", @"relaunch alert title");
    relaunchAlert.informativeText = NSLocalizedString(@"The new trust settings will take effect when DTerm is next launched.  Would you like to relaunch DTerm now?", @"relaunch alert text");
    [relaunchAlert addButtonWithTitle:NSLocalizedString(@"Relaunch now",  @"relaunch alert default button")];
    [relaunchAlert addButtonWithTitle:NSLocalizedString(@"Relaunch later", @"relaunch alert alternate button")];
    
    if([relaunchAlert runModal] == NSAlertFirstButtonReturn) {
        // This code borrowed from Sparkle, which was in turn borrowed from Allan Odgaard
        NSString *currentAppPath = [NSBundle mainBundle].bundlePath;
        setenv("LAUNCH_PATH", currentAppPath.UTF8String, 1);
        system("/bin/bash -c '{ for (( i = 0; i < 3000 && $(echo $(/bin/ps -xp $PPID|/usr/bin/wc -l))-1; i++ )); do\n"
               "    /bin/sleep .2;\n"
               "  done\n"
               "  if [[ $(/bin/ps -xp $PPID|/usr/bin/wc -l) -ne 2 ]]; then\n"
               "    /bin/sleep 1.0;\n"
               "    /usr/bin/open \"${LAUNCH_PATH}\"\n"
               "  fi\n"
               "} &>/dev/null &'");
        [NSApp terminate:self];
    }
}

@end

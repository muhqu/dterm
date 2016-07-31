//  Copyright (c) 2007-2011 Decimus Software, Inc. All rights reserved.


@interface DTPrefsAXController : NSViewController

@property (readonly, nonatomic) BOOL axAppTrusted;
@property (readonly, nonatomic) NSString* axTrustStatusString;
@property (readonly, nonatomic) BOOL axGeneralAccessEnabled;
@property (readonly, nonatomic) NSString* axGeneralAccessEnabledString;

- (void)recheckGeneralAXAccess;

- (IBAction)setAXTrusted:(id)sender;

@end

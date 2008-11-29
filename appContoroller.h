//
//  appContoroller.h
//  GrowlToggle
//
//  Created by soh kitahara on 08/11/19.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "Carbon/Carbon.h"
#define GROWL_PREFPANE_BUNDLE_IDENTIFIER		XSTR("com.growl.prefpanel")
#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY	XSTR("PreferencePanes")
#define GROWL_PREFPANE_NAME						XSTR("Growl.prefPane")
#define PREFERENCE_PANE_EXTENSION				XSTR("prefPane")
#define GROWL_HELPERAPP_BUNDLE_IDENTIFIER	XSTR("com.Growl.GrowlHelperApp")

@interface appContoroller : NSObject <GrowlApplicationBridgeDelegate>{
	NSStatusItem* _status_item;
	BOOL* isOn;
	NSString* status;
	IBOutlet NSMenu* _status_menu;
	IBOutlet NSMenuItem* _status_menu_item;
}
- (IBAction)myAction:(id)sender;
- (BOOL) isRunning:(NSString *)theBundleIdentifier;
- (BOOL) isGrowlRunning;
- (void)sendEvent:(NSEvent*)event;
- (void) toggleGrowl;
+ (NSBundle *) growlPrefPaneBundle;
+ (NSBundle *) runningHelperAppBundle;
+ (NSBundle *) bundleForProcessWithBundleIdentifier:(NSString *)identifier;
@end

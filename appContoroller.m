//
//  appContoroller.m
//  GrowlToggle
//
//  Created by soh kitahara on 08/11/19.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "appContoroller.h"
static NSBundle *prefPaneBundle;




OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
						 void *userData)
{
	//Do something once the key is pressed
	[(id)userData myAction:nil];
	printf("hoge");
	return noErr;
}

@implementation appContoroller

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{	
	
	EventHotKeyRef gMyHotKeyRef;
	EventHotKeyID gMyHotKeyID;
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	InstallApplicationEventHandler(&MyHotKeyHandler,1,&eventType,self,NULL);
	gMyHotKeyID.signature='htk1';
	gMyHotKeyID.id=1;
	RegisterEventHotKey(18, cmdKey+shiftKey, gMyHotKeyID, 
						GetApplicationEventTarget(), 0, &gMyHotKeyRef);
	
	NSStatusBar *status_bar = [NSStatusBar systemStatusBar];
	_status_item = [status_bar statusItemWithLength:NSVariableStatusItemLength];
	[_status_item retain];
	[_status_item setTitle:@""];
	[_status_item setHighlightMode:YES];
	[_status_item setMenu:_status_menu];
	
	if([self isGrowlRunning]){
		isOn = YES;
		[_status_item setTitle:@"on"];
	}else{
		isOn = NO;
		[_status_item setTitle:@"off"];
	}
	
	//growl
	/*NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	NSString *growlPath = [[myBundle privateFrameworksPath]
						   stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	if (growlBundle && [growlBundle load]) {
		// Register ourselves as a Growl delegate
		[GrowlApplicationBridge setGrowlDelegate:self];
	} else {
		NSLog(@"Could not load Growl.framework");
	}*/
	NSString *frameworkPath=[[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *growlFramework = [NSBundle bundleWithPath:frameworkPath];
	if(growlFramework && [growlFramework load]){
		[GrowlApplicationBridge setGrowlDelegate:self];
	}else {
		NSLog(@"Could not load Growl.framework");
	}


	
	//[GrowlApplicationBridge notifyWithTitle:@"title" description:@"description" notificationName:@"notifyname" iconData:nil priority:0 isSticky:NO clickContext:nil];
	//[GrowlApplicationBridge setGrowlDelegate:self];
	
	NSBundle* prefPaneBundle = [NSBundle bundleWithIdentifier:@"GROWL_PREFPANE_BUNDLE_IDENTIFIER"];
	NSLog([prefPaneBundle bundlePath]);
}

- (void)applicationWillTerminate:(NSNotification *)notification{}

- (IBAction)myAction:(id)sender{
	[self toggleGrowl];

}

- (void) toggleGrowl{	
	if(isOn){
		[_status_menu_item setTitle:@"now:off"];
		isOn=NO;
		CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
											 (CFStringRef)GROWL_SHUTDOWN,
											 /*object*/ NULL,
											 /*userInfo*/ NULL,
											 /*deliverImmediately*/ false);
		[_status_item setTitle:@"off"];
	}else{
		[_status_menu_item setTitle:@"now:on"];
		isOn = YES;
		//NSString *helperPath = @"/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app";
		NSBundle *bundle = [appContoroller growlPrefPaneBundle];
		NSString *helperAppPath = [bundle pathForResource:@"GrowlHelperApp" ofType:@"app"];
		NSBundle *helperAppBundle = [NSBundle bundleWithPath:helperAppPath];
		NSString *helperPath = [helperAppBundle bundlePath];
		NSURL *helperURL = [NSURL fileURLWithPath:helperPath];
		unsigned options = NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync;
		[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:helperURL]
						withAppBundleIdentifier:nil
										options:options
				 additionalEventParamDescriptor:nil
							  launchIdentifiers:NULL];
		[_status_item setTitle:@"on"];
		
	}
	
}

- (BOOL) isRunning:(NSString *)theBundleIdentifier {
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };
	
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		NSString *bundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
		isRunning = bundleID && [bundleID isEqualToString:theBundleIdentifier];
		[infoDict release];
		
		if (isRunning)
			break;
	}
	
	return isRunning;
}

- (BOOL) isGrowlRunning {
	return [self isRunning:@"com.Growl.GrowlHelperApp"];
}

+ (NSBundle *) growlPrefPaneBundle {
	NSArray			*librarySearchPaths;
	NSString		*path;
	NSString		*bundleIdentifier;
	NSEnumerator	*searchPathEnumerator;
	NSBundle		*bundle;
	
	if (prefPaneBundle)
		return prefPaneBundle;
	
	prefPaneBundle = [NSBundle bundleWithIdentifier:GROWL_PREFPANE_BUNDLE_IDENTIFIER];
 	if (prefPaneBundle)
		return prefPaneBundle;
	
	//If GHA is running, the prefpane bundle is the bundle that contains it.
	NSBundle *runningHelperAppBundle = [self runningHelperAppBundle];
	NSString *runningHelperAppBundlePath = [runningHelperAppBundle bundlePath];
	//GHA in Growl.prefPane/Contents/Resources/
	NSString *possiblePrefPaneBundlePath1 = [runningHelperAppBundlePath stringByDeletingLastPathComponent];
	//GHA in Growl.prefPane/ (hypothetical)
	NSString *possiblePrefPaneBundlePath2 = [[possiblePrefPaneBundlePath1 stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	if ([[[possiblePrefPaneBundlePath1 pathExtension] lowercaseString] isEqualToString:@"prefpane"]) {
		prefPaneBundle = [NSBundle bundleWithPath:possiblePrefPaneBundlePath1];
		if (prefPaneBundle)
			return prefPaneBundle;
	}
	if ([[[possiblePrefPaneBundlePath2 pathExtension] lowercaseString] isEqualToString:@"prefpane"]) {
		prefPaneBundle = [NSBundle bundleWithPath:possiblePrefPaneBundlePath2];
		if (prefPaneBundle)
			return prefPaneBundle;
	}
	
	static const unsigned bundleIDComparisonFlags = NSCaseInsensitiveSearch | NSBackwardsSearch;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask & ~NSSystemDomainMask, YES);
	
	/*First up, we'll look for Growl.prefPane, and if it exists, check whether
	 *	it is our prefPane.
	 *This is much faster than having to enumerate all preference panes, and
	 *	can drop a significant amount of time off this code.
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		path = [path stringByAppendingPathComponent:GROWL_PREFPANE_NAME];
		
		if ([fileManager fileExistsAtPath:path]) {
			bundle = [NSBundle bundleWithPath:path];
			
			if (bundle) {
				bundleIdentifier = [bundle bundleIdentifier];
				
				if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
					prefPaneBundle = bundle;
					return prefPaneBundle;
				}
			}
		}
	}
	
	/*Enumerate all installed preference panes, looking for the Growl prefpane
	 *	bundle identifier and stopping when we find it.
	 *Note that we check the bundle identifier because we should not insist
	 *	that the user not rename his preference pane files, although most users
	 *	of course will not.  If the user wants to mutilate the Info.plist file
	 *	inside the bundle, he/she deserves to not have a working Growl
	 *	installation.
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		NSString				*bundlePath;
		NSDirectoryEnumerator   *bundleEnum;
		
		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		bundleEnum = [fileManager enumeratorAtPath:path];
		
		while ((bundlePath = [bundleEnum nextObject])) {
			if ([[bundlePath pathExtension] isEqualToString:PREFERENCE_PANE_EXTENSION]) {
				bundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:bundlePath]];
				
				if (bundle) {
					bundleIdentifier = [bundle bundleIdentifier];
					
					if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
						prefPaneBundle = bundle;
						return prefPaneBundle;
					}
				}
				
				[bundleEnum skipDescendents];
			}
		}
	}
	
	return nil;
}

+ (NSBundle *) runningHelperAppBundle {
	return [self bundleForProcessWithBundleIdentifier:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
}

+ (NSBundle *) bundleForProcessWithBundleIdentifier:(NSString *)identifier
{
	
restart:;
	OSStatus err;
	NSBundle *bundle = nil;
	struct ProcessSerialNumber psn = { 0, 0 };
	UInt32 oldestProcessLaunchDate = UINT_MAX;
	
	while ((err = GetNextProcess(&psn)) == noErr) {
		struct ProcessInfoRec info = { .processInfoLength = sizeof(struct ProcessInfoRec) };
		err = GetProcessInformation(&psn, &info);
		if (err == noErr) {
			//Compare the launch dates first, since it's cheaper than comparing bundle IDs.
			if (info.processLaunchDate < oldestProcessLaunchDate) {
				//This one is older (fewer ticks since startup), so this is our current prospect to be the result.
				NSDictionary *dict = (NSDictionary *)ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
				
				if (dict) {
					pid_t pid = 0;
					GetProcessPID(&psn, &pid);
					if ([[dict objectForKey:(NSString *)kCFBundleIdentifierKey] isEqualToString:identifier]) {
						NSString *bundlePath = [dict objectForKey:@"BundlePath"];
						if (bundlePath) {
							bundle = [NSBundle bundleWithPath:bundlePath];
							oldestProcessLaunchDate = info.processLaunchDate;
						}
					}
					
					[dict release];
				} else {
					//ProcessInformationCopyDictionary returning NULL probably means that the process disappeared out from under us (i.e., exited) in between GetProcessInformation and ProcessInformationCopyDictionary. Start over.
					goto restart;
				}
			}
		} else {
			if (err != noErr) {
				//Unexpected failure of GetProcessInformation (Process Manager got confused?). Assume severe breakage and bail.
				NSLog(@"Couldn't get information about process %lu,%lu: GetProcessInformation returned %i/%s", psn.highLongOfPSN, psn.lowLongOfPSN, err, GetMacOSStatusCommentString(err));
				err = noErr; //So our NSLog for GetNextProcess doesn't complain. (I wish I had Python's while..else block.)
				break;
			} else {
				//Process disappeared out from under us (i.e., exited) in between GetNextProcess and GetProcessInformation. Start over.
				goto restart;
			}
		}
	}
	if (err != procNotFound) {
		NSLog(@"%s: GetNextProcess returned %i/%s", __PRETTY_FUNCTION__, err, GetMacOSStatusCommentString(err));
	}
	
	return bundle;
}


- (void)sendEvent:(NSEvent*)event
{
	printf("fuga");
    // For hot key event
    if ([event type] == NSSystemDefined && [event subtype] == 6){
		printf("fuga");
	}
}
    

@end

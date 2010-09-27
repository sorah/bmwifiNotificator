//
//  bmwifiNoficatorAppDelegate.h
//  bmwifiNoficator
//
//  Created by Shota Fukumori on 9/26/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegexKitLite.h"

@interface bmwifiNotificatorAppDelegate : NSObject {// <NSApplicationDelegate> {
    NSWindow *window;
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSMenuItem *menuExit;
	IBOutlet NSMenuItem *menuStatus;
	IBOutlet NSMenuItem *menuCarrier;
	IBOutlet NSMenuItem *menuLevel;
	IBOutlet NSMenuItem *menuBattery;
	IBOutlet NSMenuItem *menuNetwork;
	IBOutlet NSMenuItem *menuAutoRefresh;
	IBOutlet NSView *customView;
	IBOutlet NSTextField *customLabel;
	IBOutlet NSImageView *customImage;
	NSTimer *t;
	NSUserDefaults *pref;
	BOOL isAutoRefreshing;
}

@property (assign) IBOutlet NSWindow *window;

-(void) dealloc;
-(BOOL) isBwAvailable;
-(BOOL) login;
-(NSMutableDictionary*) getInformation;
-(IBAction) updateInformation: (id)sender;
-(IBAction) showPreferences: (id)sender;
-(IBAction) toggleAutoRefresh: (id)sender;
-(void) startAutoRefresh;
-(void) stopAutoRefresh;
@end

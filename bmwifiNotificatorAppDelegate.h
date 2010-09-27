/*
 * bmwifiNoficatorAppDelegate.h
 *
 * The MIT Licence
 *     (c) 2010-, Shota Fukumori (sora_h)
 *     Permission is hereby granted, free of charge, to any person obtaining a copy
 *     of this software and associated documentation files (the "Software"), to deal
 *     in the Software without restriction, including without limitation the rights
 *     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *     copies of the Software, and to permit persons to whom the Software is
 *     furnished to do so, subject to the following conditions:
 * 
 *     The above copyright notice and this permission notice shall be included in
 *     all copies or substantial portions of the Software.
 * 
 *     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *     THE SOFTWARE.
 */

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

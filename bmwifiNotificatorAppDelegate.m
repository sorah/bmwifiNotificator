/*
 * bmwifiNoficatorAppDelegate.m
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
#import "bmwifiNotificatorAppDelegate.h"

@implementation bmwifiNotificatorAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Default Preferences
	pref = [[NSUserDefaults standardUserDefaults] retain];

	//// IP
	if([pref stringForKey:@"ip"] == nil)
		[pref setObject:@"192.168.0.1" forKey:@"ip"];
	//// User
	if([pref stringForKey:@"user"] == nil)
		[pref setObject:@"admin" forKey:@"user"];
	//// Pass
	if([pref stringForKey:@"pass"] == nil)
		[pref setObject:@"admin" forKey:@"pass"];
	
	// Initialize
	[menuExit setEnabled:YES];
	[statusMenu update];
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	
	NSImage *img = [[NSImage alloc] initWithContentsOfFile:
					[[NSBundle mainBundle] pathForResource:@"mf30notfound"
													ofType:@"png"]];
	[statusItem setImage:img];
	[img release];
	
	[statusItem setTitle:@"Init"];
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];
	[self updateInformation:nil];
	[self startAutoRefresh];
}

-(void) startAutoRefresh {
	if(!t) {
		t = [[NSTimer scheduledTimerWithTimeInterval:20
											 target:self
										   selector:@selector(updateInformation:)
										   userInfo:nil
											repeats:YES] retain];
		[t fire];
	}
	isAutoRefreshing = YES;
	[menuAutoRefresh setState:isAutoRefreshing];
}
-(void) stopAutoRefresh {
	if(t) {
		[t invalidate];
		[t release];
		t = nil;
	}
	isAutoRefreshing = NO;
	[menuAutoRefresh setState:isAutoRefreshing];
}
-(IBAction) toggleAutoRefresh: (id)sender {
	if(isAutoRefreshing) {
		[self stopAutoRefresh];
	} else {
		[self startAutoRefresh];
	}
}

- (BOOL) isBwAvailable {
	NSMutableURLRequest *req;
	NSHTTPURLResponse *res = nil;
	NSError *err = nil;
	
	req = [[NSMutableURLRequest alloc]
		   initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/",
											 [pref stringForKey:@"ip"]]]];
	req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	[req setHTTPMethod:@"HEAD"];
	
	[NSURLConnection sendSynchronousRequest:req
						  returningResponse:&res
									  error:&err];
	
	BOOL ny = NO;
	if(!err && [@"GoAhead-Webs" isEqualToString:[[res allHeaderFields] objectForKey:@"Server"]])
		ny = YES;

	[req release];
	return ny;
}

- (BOOL) login {
	NSMutableURLRequest *req;
	NSHTTPURLResponse *res = nil;
	NSError *err = nil;
	NSData *result = nil;
	
	req = [[NSMutableURLRequest alloc] 
		   initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/goform/login",
											 [pref stringForKey:@"ip"]]]];
	req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[[NSString stringWithFormat:@"user=%@&psw=%@",
					   [pref stringForKey:@"user"],[pref stringForKey:@"pass"]]
					  dataUsingEncoding:NSUTF8StringEncoding]];
	
	result = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];

	[req release];

	if(err) {
		NSLog(@"error = %@",err);
	}else{
		NSString *str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
		if([str isMatchedByRegex:@"login.asp"]) {
			[str release];
			return NO;
		}
		[str release];
	}
	return YES;
}

- (NSMutableDictionary*) getInformation {
	NSMutableDictionary *hash = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
								 @"MF30 Not Found - Auto Refreshing was stopped.",@"wanState",@"N/A",@"network_type",
								 @"N/A",@"network_provider",@"N/A",@"battery_status",
								 @"N/A",@"rssi",nil] retain];
	if([self isBwAvailable]){
		if(![self login]) {
			[hash release];
			return [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"Failed to Login",@"wanState",@"N/A",@"network_type",
					@"N/A",@"network_provider",@"N/A",@"battery_status",
					@"N/A",@"rssi",nil];
		}
		NSMutableURLRequest *req;
		NSHTTPURLResponse *res = nil;
		NSError *err = nil;
		NSData *result;
		NSString *result_string;
		
		req = [[NSMutableURLRequest alloc]
			   initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/logo.asp",
												 [pref stringForKey:@"ip"]]]];
		req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
		[req setHTTPMethod:@"GET"];
		
		result = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];

		if(!err){
			result_string = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
			[hash release];
			hash = [[NSMutableDictionary alloc] init];
			NSArray *ary = [[result_string componentsSeparatedByRegex:
							  @"var rssi = '(.+?)'; \nvar wanState = '(.+?)';  \nvar icardState = '.+?';\nvar network_type = '(.+?)';\nvar network_provider = '(.+?)';\nvar roam_status = '.+?';\nvar battery_status = '(.+?)';"
							] retain];
			[result_string release];
			[hash setObject:[ary objectAtIndex:1]
					 forKey:@"rssi"];
			[hash setObject:[ary objectAtIndex:2]
					 forKey:@"wanState"];
			[hash setObject:[ary objectAtIndex:3]
					 forKey:@"network_type"];
			[hash setObject:[ary objectAtIndex:4]
					 forKey:@"network_provider"];
			[hash setObject:[ary objectAtIndex:5]
					 forKey:@"battery_status"];
			if(ary) [ary release];
		}
		[req release];
	}
	return [hash autorelease];
}

-(IBAction) updateInformation: (id)sender {
	NSDictionary *status = [[self getInformation] retain];

	[menuStatus setTitle:[NSString stringWithFormat:@"Status: %@",
							[status valueForKey:@"wanState"]]];
	[menuNetwork setTitle:[NSString stringWithFormat:@"Network Type: %@",
						    [status valueForKey:@"network_type"]]];
	[menuCarrier setTitle:[NSString stringWithFormat:@"Carrier: %@",
							[status valueForKey:@"network_provider"]]];
	[menuBattery setTitle:[NSString stringWithFormat:@"Battery: %@%%",
							[status valueForKey:@"battery_status"]]];
	[menuLevel setTitle:[NSString stringWithFormat:@"Signal Level: %@",
							[status valueForKey:@"rssi"]]];
	
	if([self isBwAvailable]) {
		if([[status valueForKey:@"wanState"] isEqualToString:@"Failed to Login"]) {
			[statusItem setTitle:@""];
			NSImage *image = [[NSImage alloc] initWithContentsOfFile:
							  [[NSBundle mainBundle] pathForResource:@"mf30err"
															  ofType:@"png"]];
			[statusItem setImage:image];
			[image release];
		}else{
			[statusItem setTitle:[NSString stringWithFormat:@"%@%%",
								  [status valueForKey:@"battery_status"],[status valueForKey:@"rssi"]]];
			int rssi = [[status valueForKey:@"rssi"] intValue];
			NSImage *state;
			if ( rssi > 107 || rssi < 1 ) {
				state = [[NSImage alloc] initWithContentsOfFile:
						 [[NSBundle mainBundle] pathForResource:@"antenna0"
														 ofType:@"png"]];
			} else if ( rssi <= 107 && rssi >  99 ) {
				state = [[NSImage alloc] initWithContentsOfFile:
						 [[NSBundle mainBundle] pathForResource:@"antenna1"
														 ofType:@"png"]];
			} else if ( rssi <= 99  && rssi >  93 ) {
				state = [[NSImage alloc] initWithContentsOfFile:
						 [[NSBundle mainBundle] pathForResource:@"antenna2"
														 ofType:@"png"]];
			} else if ( rssi <= 93  && rssi >  87 ) {
				state = [[NSImage alloc] initWithContentsOfFile:
						 [[NSBundle mainBundle] pathForResource:@"antenna3"
														 ofType:@"png"]];
			} else if ( rssi <= 87  && rssi >  81 ) {
				state = [[NSImage alloc] initWithContentsOfFile:
						 [[NSBundle mainBundle] pathForResource:@"antenna4"
														 ofType:@"png"]];
			} else if ( rssi <= 81  && rssi >= 1  ) {
				state = [[NSImage alloc] initWithContentsOfFile:
						 [[NSBundle mainBundle] pathForResource:@"antenna5"
														 ofType:@"png"]];
			}
			[statusItem setImage:state];
			[state release];
		}
	}else{
		[statusItem setTitle:@""];
		NSImage *img = [[NSImage alloc] initWithContentsOfFile:
						[[NSBundle mainBundle] pathForResource:@"mf30notfound"
														ofType:@"png"]];
		[statusItem setImage:img];
		[img release];
		[self stopAutoRefresh];
	}
	[status autorelease];
}

-(IBAction) showPreferences: (id)sender {
	[window makeKeyAndOrderFront:sender];
	[window becomeMainWindow];
}

- (void) dealloc {
	[pref release];
	[menuExit release];
	[statusMenu release];
	[statusItem release];
	[menuExit release];
	[menuStatus release];
	[menuCarrier release];
	[menuLevel release];
	[menuBattery release];
	[menuNetwork release];
	[menuAutoRefresh release];
	[super dealloc];
}

@end

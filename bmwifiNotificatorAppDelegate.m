//
//  bmwifiNoficatorAppDelegate.m
//  bmwifiNoficator
//
//  Created by Shota Fukumori on 9/26/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
	[statusItem setTitle:@"MF30Wait"];
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];
	[self updateInformation:nil];
	
}

- (BOOL) isBwAvailable {
	NSMutableURLRequest *req;
	NSHTTPURLResponse *res = nil;
	NSError *err = nil;
	
	req = [[NSMutableURLRequest alloc]
		   initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/",
											 [pref stringForKey:@"ip"]]]];
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
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[[NSString stringWithFormat:@"user=%@&psw=%@",
					   [pref stringForKey:@"user"],[pref stringForKey:@"pass"]]
					  dataUsingEncoding:NSUTF8StringEncoding]];
	
	result = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];

	[req release];

	if(err) {
		NSLog(@"error = %@",err);
	}else{
		if([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding]
			isMatchedByRegex:@"login.asp"]) {
			return NO;
		}
	}
	return YES;
}

- (NSMutableDictionary*) getInformation {
	NSMutableDictionary *hash = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
								 @"MF30 Not Found",@"wanState",@"N/A",@"network_type",
								 @"N/A",@"network_provider",@"N/A",@"battery_status",
								 @"N/A",@"rssi",nil] retain];
	if([self isBwAvailable]){
		if(![self login]) {
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
	[menuBattery setTitle:[NSString stringWithFormat:@"Battery: %@",
							[status valueForKey:@"battery_status"]]];
	[menuLevel setTitle:[NSString stringWithFormat:@"Signal Level: %@",
							[status valueForKey:@"rssi"]]];
	
	if([self isBwAvailable]) {
		if([[status valueForKey:@"wanState"] isEqualToString:@"Failed to Login"]) {
			[statusItem setTitle:@"ErrMF30"];
		}else{
			[statusItem setTitle:[NSString stringWithFormat:@"MF:%@%%/l%@",
								  [status valueForKey:@"battery_status"],[status valueForKey:@"rssi"]]];
		}
	}else{
		[statusItem setTitle:@"NoMF30"];
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
	[super dealloc];
}

@end

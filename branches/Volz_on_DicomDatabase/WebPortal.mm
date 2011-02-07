/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "WebPortal.h"
#import "WebPortalDatabase.h"
#import "WebPortalSession.h"
#import "WebPortalConnection.h"
#import "ThreadPoolServer.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSUserDefaultsController+N2.h"
#import "AppController.h"
#import "NSData+N2.h"
#import "NSString+N2.h"
#import "DDData.h"
#import "DicomDatabase.h"

#import "BrowserController.h" // TODO: REMOVE with badness


@interface WebPortalServer ()

@property(readwrite, assign) WebPortal* portal;

@end

@implementation WebPortalServer

@synthesize portal;

@end


@interface WebPortal ()

@property(readwrite, retain) WebPortalDatabase* database;
@property(readwrite, retain) DicomDatabase* dicomDatabase;
@property(readwrite) BOOL isAcceptingConnections;

@end


NSString* const WebPortalEnabledContext = @"";


@implementation WebPortal

static const NSString* const defaultPortalDatabasePath = @"~/Library/Application Support/OsiriX/WebUsers.sql";

+(void)initialize {
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWadoServiceEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
}

+(void)applicationWillFinishLaunching { // called from AppController
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalPortNumberDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalAddressDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalUsesSSLDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalPrefersCustomWebPagesKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalRequiresAuthenticationDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalUsersCanRestorePasswordDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalUsesWeasisDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalPrefersFlashDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWadoServiceEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];
	// last because this starts the listener
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:self.defaultPortal];

	//	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixWebPortalNotificationsIntervalDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
}

+(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if (!context) {
		if ([keyPath isEqual:valuesKeyPath(OsirixWadoServiceEnabledDefaultsKey)])
			if (!NSUserDefaults.wadoServiceEnabled)
				[NSUserDefaultsController.sharedUserDefaultsController setBool:NO forKey:OsirixWebPortalUsesWeasisDefaultsKey];
	} else {
		WebPortal* webPortal = (id)context;
		
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalEnabledDefaultsKey)])
			if (NSUserDefaults.webPortalEnabled)
				[webPortal startAcceptingConnections];
			else [webPortal stopAcceptingConnections];
		else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalUsesSSLDefaultsKey)])
			webPortal.usesSSL = NSUserDefaults.webPortalUsesSSL;
		else

		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalPortNumberDefaultsKey)])
			webPortal.portNumber = NSUserDefaults.webPortalPortNumber;
		else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalAddressDefaultsKey)])
			webPortal.address = NSUserDefaults.webPortalAddress;
		else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalPrefersCustomWebPagesKey)]) {
			NSMutableArray* dirsToScanForFiles = [NSMutableArray arrayWithCapacity:2];
			if (NSUserDefaults.webPortalPrefersCustomWebPages) [dirsToScanForFiles addObject:@"~/Library/Application Support/OsiriX/WebServicesHTML"];
			[dirsToScanForFiles addObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WebServicesHTML"]];
			webPortal.dirsToScanForFiles = dirsToScanForFiles;
		} else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalRequiresAuthenticationDefaultsKey)])
			webPortal.authenticationRequired = NSUserDefaults.webPortalRequiresAuthentication;
		else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalUsersCanRestorePasswordDefaultsKey)])
			webPortal.passwordRestoreAllowed = NSUserDefaults.webPortalUsersCanRestorePassword;
		else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalUsesWeasisDefaultsKey)])
			webPortal.weasisEnabled = NSUserDefaults.webPortalUsesWeasis;
		else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWebPortalPrefersFlashDefaultsKey)])
			webPortal.flashEnabled = NSUserDefaults.webPortalPrefersFlash;
		else
			
		if ([keyPath isEqual:valuesKeyPath(OsirixWadoServiceEnabledDefaultsKey)])
			webPortal.wadoEnabled = NSUserDefaults.wadoServiceEnabled;
	}
	
	//NSTimer* t = [[NSTimer scheduledTimerWithTimeInterval:60 * [[NSUserDefaults standardUserDefaults] integerForKey: @"notificationsEmailsInterval"] target: self selector: @selector( webServerEmailNotifications:) userInfo: nil repeats: YES] retain];
}

+(void)applicationWillTerminate {
	//	[NSUserDefaultsController.sharedUserDefaultsController removeObserver:self forValuesKey:OsirixWebPortalNotificationsIntervalDefaultsKey];
	[self.defaultPortal release];
}

+(WebPortal*)defaultPortal {
	static WebPortal* defaultPortal = NULL;
	if (!defaultPortal)
		defaultPortal = [[self alloc] initWithDatabaseAtPath:defaultPortalDatabasePath dicomDatabase:DicomDatabase.defaultDatabase]; // TODO: should not point to BrowserController
	
	return defaultPortal;
}

#pragma mark Instance

@synthesize database, dicomDatabase;
@synthesize isAcceptingConnections;
@synthesize usesSSL;
@synthesize portNumber;
@synthesize address;
@synthesize dirsToScanForFiles;
@synthesize authenticationRequired;

@synthesize passwordRestoreAllowed;
@synthesize wadoEnabled;
@synthesize weasisEnabled;
@synthesize flashEnabled;

-(id)initWithDatabase:(WebPortalDatabase*)db dicomDatabase:(DicomDatabase*)dd; {
	self = [super init];
	
	sessions = [[NSMutableArray alloc] initWithCapacity:64];
	sessionsArrayLock = [[NSLock alloc] init];
	sessionCreateLock = [[NSLock alloc] init];

	self.database = db;
	self.dicomDatabase = dd;
	server = [[WebPortalServer alloc] init];
	server.portal = self;
	
	return self;
}

-(id)initWithDatabaseAtPath:(NSString*)sqlFilePath dicomDatabase:(DicomDatabase*)dd; {
	return [self initWithDatabase:[[[WebPortalDatabase alloc] initWithPath:sqlFilePath] autorelease] dicomDatabase:dd];
}

-(void)invalidate {
	[self stopAcceptingConnections];
	//[notificationsTimer invalidate]; notificationsTimer = NULL;
}

-(void)dealloc {
	[self invalidate];
	[server release];
	self.database = NULL;
	self.dicomDatabase = NULL;
	
	[sessionCreateLock release];
	[sessionsArrayLock release];
	[sessions release];
	
	self.address = NULL;
	self.dirsToScanForFiles = NULL;
	
	[super dealloc];
}

-(void)restartIfRunning {
	if (isAcceptingConnections) {
		[self stopAcceptingConnections];
		[self startAcceptingConnections];
	}
}

-(void)setPortNumber:(NSInteger)n {
	if (n != portNumber) {
		portNumber = n;
		[self restartIfRunning];
	}
}

-(void)setUsesSSL:(BOOL)b {
	if (b != usesSSL) {
		usesSSL = b;
		[self restartIfRunning];
	}
}

-(void)startAcceptingConnections {
	if (!isAcceptingConnections) {
		@try {
			server.connectionClass = WebPortalConnection.class;
			
			if (self.usesSSL)
				server.type = @"_https._tcp.";
			else server.type = @"_http._tcp.";
			
			server.TXTRecordDictionary = [NSDictionary dictionaryWithObject:@"OsiriX" forKey:@"ServerType"];
			server.port = self.portNumber;
			server.documentRoot = [NSURL fileURLWithPath:[@"~/Sites" stringByExpandingTildeInPath]];
			
			thread = [[[NSThread alloc] initWithTarget:self selector:@selector(connectionsThread:) object:NULL] autorelease];
			[thread start];
		} @catch (NSException * e) {
			NSLog(@"Exception: [WebPortal startAcceptingConnections] %@", e);
		}
	}
}

-(void)connectionsThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSError* err = NULL;
		if (![server start:&err]) {
			NSLog(@"Exception: [WebPortal startAcceptingConnectionsThread:] %@", err);
			[AppController.sharedAppController performSelectorOnMainThread:@selector(displayError:) withObject:NSLocalizedString(@"Cannot start Web Server. TCP/IP port is probably already used by another process.", NULL) waitUntilDone:YES];
			return;
		}
		
		isAcceptingConnections = YES;
		[NSRunLoop.currentRunLoop addTimer:[NSTimer scheduledTimerWithTimeInterval:DBL_MAX target:self selector:@selector(ignore:) userInfo:NULL repeats:NO] forMode:@"privateHTTPWebServerRunMode"];
		while (!NSThread.currentThread.isCancelled && [NSRunLoop.currentRunLoop runMode:@"privateHTTPWebServerRunMode" beforeDate:NSDate.distantFuture]);
		
		NSLog(@"[WebPortal connectionsThread:] finishing");
	} @catch (NSException* e) {
		NSLog(@"Warning: [WebPortal connetionsThread] %@", e);
	} @finally {
		[pool release];
	}
}

-(void)stopAcceptingConnections {
	if (isAcceptingConnections) {
		isAcceptingConnections = NO;
		@try {
			[server stop];
			[thread cancel];
		} @catch (NSException* e) {
			NSLog(@"Exception: [WebPortal stopAcceptingConnections] %@", e);
		}
	}
}

-(NSData*)dataForPath:(NSString*)file {
	NSMutableArray* dirsToScanForFile = [[self.dirsToScanForFiles mutableCopy] autorelease];
	
	const NSString* const DefaultLanguage = @"English";
	BOOL isDirectory;
	
	for (NSInteger i = 0; i < dirsToScanForFile.count; ++i) {
		NSString* path = [dirsToScanForFile objectAtIndex:i];
		
		// path not on disk, ignore
		if (![[NSFileManager defaultManager] fileExistsAtPath:[path resolvedPathString] isDirectory:&isDirectory] || !isDirectory) {
			[dirsToScanForFile removeObjectAtIndex:i];
			--i; continue;
		}
		
		// path exists, look for a localized subdir first, otherwise in the dir itself
		
		for (NSString* lang in [[[NSBundle mainBundle] preferredLocalizations] arrayByAddingObject:DefaultLanguage]) {
			NSString* langPath = [path stringByAppendingPathComponent:lang];
			if ([[NSFileManager defaultManager] fileExistsAtPath:[langPath resolvedPathString] isDirectory:&isDirectory] && isDirectory) {
				[dirsToScanForFile insertObject:langPath atIndex:i];
				++i; break;
			}
		}
	}
	
	for (NSString* dirToScanForFile in dirsToScanForFile) {
		NSString* path = [dirToScanForFile stringByAppendingPathComponent:file];
		@try {
			NSData* data = [NSData dataWithContentsOfFile:[path resolvedPathString]];
			if (data) return data;
		} @catch (NSException* e) {
			// do nothing, just try next
		}
	}
	
	//	NSLog( @"****** File not found: %@", file);
	
	return NULL;
}

-(NSString*)stringForPath:(NSString*)file {
	NSData* data = [self dataForPath:file];
	if (!data) {
		NSLog(@"Warning: [WebPortal stringForPath] is returning NULL for %@", file);
		return NULL;
	}
	
	NSMutableString* html = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	NSRange range;
	while ((range = [html rangeOfString:@"%INCLUDE:"]).length) {
		NSRange rangeEnd = [html rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(range.location+range.length, html.length-(range.location+range.length))];
		NSString* replaceFilename = [html substringWithRange:NSMakeRange(range.location+range.length, rangeEnd.location-(range.location+range.length))];
		NSString* replaceFilepath = [file stringByComposingPathWithString:replaceFilename];
		[html replaceCharactersInRange:NSMakeRange(range.location, rangeEnd.location+rangeEnd.length-range.location) withString:N2NonNullString([self stringForPath:replaceFilepath])];
	}
	
	return html;
}

#pragma mark Sessions

-(id)sessionForId:(NSString*)sid {
	[sessionsArrayLock lock];
	WebPortalSession* session = NULL;
	
	for (WebPortalSession* isession in sessions)
		if ([isession.sid isEqual:sid]) {
			session = isession;
			break;
		}
	
	[sessionsArrayLock unlock];
	return session;
}

-(id)sessionForUsername:(NSString*)username token:(NSString*)token {
	[sessionsArrayLock lock];
	WebPortalSession* session = NULL;
	
	for (WebPortalSession* isession in sessions)
		if ([[isession objectForKey:SessionUsernameKey] isEqual:username] && [isession consumeToken:token]) {
			session = isession;
			break;
		}
	
	[sessionsArrayLock unlock];
	return session;
}

-(id)newSession {
	[sessionCreateLock lock];
	
	NSString* sid;
	long sidd;
	do { // is this a dumb way to generate SIDs?
		sidd = random();
	} while ([self sessionForId: sid = [[[NSData dataWithBytes:&sidd length:sizeof(long)] md5Digest] hex]]);
	
	WebPortalSession* session = [[WebPortalSession alloc] initWithId:sid];
	[sessionsArrayLock lock];
	[sessions addObject:session];
	[sessionsArrayLock unlock];
	[session release];
	
	[sessionCreateLock unlock];
	return session;
}


-(NSString*)URL {
	return [self URLForAddress:NULL];
}

-(NSString*)URLForAddress:(NSString*)add {
	if (!add)
		add = self.address;
	NSString* protocol = self.usesSSL? @"https" : @"http";
	return [NSString stringWithFormat: @"%@://%@:%d", protocol, add, self.portNumber];
}

@end



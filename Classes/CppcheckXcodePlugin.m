//
//  CppcheckXcodePlugin.m
//  CppcheckXcodePlugin
//
//  Created by Alexander Perepelitsyn on 15.04.2014
//  Copyright (c) 2014 Alexander Perepelitsyn. All rights reserved
//

#import "CppcheckXcodePlugin.h"
#import <objc/runtime.h>

static NSString * const IDEEditorDocumentWillSaveNotification = @"IDEEditorDocumentWillSaveNotification";
static NSString * const PBXProjectDidOpenNotification = @"PBXProjectDidOpenNotification";

@implementation CppcheckXcodePlugin

static CppcheckXcodePlugin *instance = nil;

+ (void)pluginDidLoad:(NSBundle *)plugin {
	static dispatch_once_t onceToken;	
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
}

- (id)init {
	if (self = [super init]) {
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catchAllXcodeNotifications:) name:nil object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openProject:) name:PBXProjectDidOpenNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDocument:) name:IDEEditorDocumentWillSaveNotification object:nil];
    }
	return self;
}

-(void) catchAllXcodeNotifications:(NSNotification*) sender {
	if ([[sender name] length] >= 2 && [[[sender name] substringWithRange:NSMakeRange(0, 2)] isEqualTo:@"NS"]) {
		return;
	} else {
		NSLog(@"Xcode: %@", [sender name]);
	}
}

-(void) openProject:(NSNotification*) sender {
	if ([[NSApp mainMenu] itemWithTitle:@"View"] == nil) {
		NSLog(@"Don't calculate derived data folder");
		return;
	}
	 
	if (![[sender object] respondsToSelector:@selector(projectFilePath)]) {
		NSLog(@"ERROR: sender not supported event");
		return;
	}
	
	NSString* pbxprojDirPath = [[sender object] performSelector:@selector(projectFilePath)];
	NSString* projectDirPath = [pbxprojDirPath substringToIndex:[pbxprojDirPath rangeOfString:@"/" options:NSBackwardsSearch].location];
	
	NSString* xcodebuildOutputFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"CppCheckIncremental.tmp"];
	
	NSString* cmd = [NSString stringWithFormat:@"/usr/bin/xcodebuild -project %@ -showBuildSettings > %@",projectDirPath, xcodebuildOutputFile];
	system([cmd UTF8String]);
	
	NSString *xcodeBuildOutput = [NSString stringWithContentsOfFile:xcodebuildOutputFile encoding:NSUTF8StringEncoding error:nil];
	
	NSRange tempDirRange = [xcodeBuildOutput rangeOfString:@"PROJECT_TEMP_ROOT = "];
	if (tempDirRange.location == NSNotFound) {
		NSLog(@"ERROR: can't find PROJECT_TEMP_ROOT in xcodebuild output");
		return;
	}
	
	NSRange newLineSearchRange = NSMakeRange(tempDirRange.location, [xcodeBuildOutput length]-tempDirRange.location);
	NSRange newLineRange = [xcodeBuildOutput rangeOfString:@"\n" options:NSCaseInsensitiveSearch range:newLineSearchRange];
	if (newLineRange.location == NSNotFound) {
		NSLog(@"ERROR: can't find new line in xcodebuild output");
		return;
	}
	
	NSString* openedProjectTempDir = [xcodeBuildOutput substringWithRange:NSMakeRange(tempDirRange.location+tempDirRange.length, newLineRange.location-tempDirRange.location-tempDirRange.length)];
	if (workingDir == nil) {
		workingDir = openedProjectTempDir;
	}
	NSString* curWorkingDirFile = [NSString stringWithFormat:@"%@/WorkingDirPath.txt", openedProjectTempDir];
	[workingDir writeToFile:curWorkingDirFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)saveDocument:(NSNotification*)sender {
	NSString* changedFileAbsoluteString = [[[sender object] fileURL] absoluteString];
	NSString* changedFilePath = [changedFileAbsoluteString substringFromIndex:7];
	
	NSString* changedFilesStoragePath = [NSString stringWithFormat:@"%@/ChangedFiles.plist", workingDir];
	
	NSMutableArray* changedFiles = [NSMutableArray arrayWithContentsOfFile:changedFilesStoragePath];
	if (changedFiles == nil) {
		changedFiles = [NSMutableArray array];
	}
	
	if ([changedFiles indexOfObject:changedFilePath] == NSNotFound) {
		[changedFiles addObject:changedFilePath];
		[changedFiles writeToFile:changedFilesStoragePath atomically:YES];
	}
}

@end
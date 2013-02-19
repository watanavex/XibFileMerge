//
//  XibFileMergeAppDelegate.m
//  XibFileMerge
//
//  Created by susan335 on 12/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "XibFileMergeAppDelegate.h"

@implementation XibFileMergeAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

}

- (IBAction) pathSelect:(id)sender
{
	// ファイルオープンダイアログを作成
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	
	// ファイル選択可 フォルダ選択不可
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	
	// ファイルオープンダイアログ表示
	[openPanel beginSheetModalForWindow:self.window
					  completionHandler:^(NSInteger result)
	{
		if (result == NSFileHandlingPanelOKButton)
		{
			NSURL* url = [openPanel URL];
			
			NSTextField* txtField;
			if([sender isEqual:_btnSelectNewFile])
			{
				txtField = _txtNewFile;
			}
			else if([sender isEqual:_btnSelectMergedFile])
			{
				txtField = _txtMergedFile;
			}
			
			if(txtField)
			{
				[txtField setStringValue:[url path]];
			}
		}
	}];
}

#define GENSTRINGS_COMMAND @"ibtool --generate-stringsfile %@ %@"
- (NSString*)createStringsFile:(NSString*)xibFilePath
{
	NSTask* aTask = [[[NSTask alloc]init]autorelease];
	NSPipe* pipe = [NSPipe pipe];
	
	NSString* stringsFile = [[xibFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"xibFiles.strings"];
	
	NSString* command = [NSString stringWithFormat:GENSTRINGS_COMMAND, stringsFile, xibFilePath];
	[aTask setLaunchPath:@"/bin/bash"];
	[aTask setArguments:[NSArray arrayWithObjects:@"-c", command, nil]];
	
	[aTask setStandardOutput: pipe];
	[aTask launch];
	[aTask waitUntilExit];
	
	NSFileHandle* aFile = [pipe fileHandleForReading];
	NSData* aData = [aFile readDataToEndOfFile];
	if([aData length] > 0)
	{
		NSString* aString = [NSString stringWithUTF8String: [aData bytes]];
		NSLog(@"%@", aString);
	}
	
	return stringsFile;
}

#define	IBTOOL_COMMAND2 @"ibtool --write %@ -d %@ %@"
#define	IBTOOL_COMMAND @"ibtool --previous-file %@ --incremental-file %@ --strings-file %@ --write %@ --localize-incremental %@"
#define STRINGS_FILE_FORMAT @"\"%@\" = \"%@\";\n"
- (NSString*)mergeingXibFile:(NSString*)newFileStrings mergedFileStrings:(NSString*)mergedFileStrings
{	
	// 日本語stringsファイルと編集後英語stringsファイルの差分check
	NSMutableDictionary* stringsDicSrc = [NSMutableDictionary dictionaryWithContentsOfFile:newFileStrings];
	NSMutableDictionary* stringsDicDist = [NSMutableDictionary dictionaryWithContentsOfFile:mergedFileStrings];
	NSString* newStringsDist = [NSString string]; // 新しい日本語stringsファイルの中身
	
	
	for(NSString* keySrc in [stringsDicSrc allKeys])
	{
		if(![[stringsDicDist allKeys]containsObject:keySrc])
		{
			// 英語しかないリソースは英語から取る
			NSString* str = [NSString stringWithFormat:STRINGS_FILE_FORMAT, keySrc, [stringsDicSrc objectForKey:keySrc]];
			newStringsDist = [newStringsDist stringByAppendingString:str];
		}
		else
		{
			// 日本語リソースがある場合は日本語からとる
			NSString* str = [NSString stringWithFormat:STRINGS_FILE_FORMAT, keySrc, [stringsDicDist objectForKey:keySrc]];
			newStringsDist = [newStringsDist stringByAppendingString:str];
		}
	}
	
	// 新しいstringsファイルを書き込み
	if([newStringsDist writeToFile:mergedFileStrings atomically:YES encoding:NSUTF16BigEndianStringEncoding error:nil])
	{
		NSDictionary *attr = [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedInteger: 0777] forKey: NSFilePosixPermissions];
		[[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:mergedFileStrings error:nil];
	}
	
	// 日本語xibファイルのバックアップ
	NSString* extension = [[_txtMergedFile stringValue]pathExtension];				// xib
	NSString* backupFileName = [[_txtMergedFile stringValue] lastPathComponent];	// ****.xib
	backupFileName = [backupFileName stringByDeletingPathExtension];				// ****
	backupFileName = [NSString stringWithFormat:@"%@_old", backupFileName];			// ****_old
	backupFileName = [backupFileName stringByAppendingPathExtension:extension];		// ****_old.xib
	NSString* backupFilePath = [[[_txtMergedFile stringValue] stringByDeletingLastPathComponent]stringByAppendingPathComponent:backupFileName];
	[[NSFileManager defaultManager] moveItemAtPath:[_txtMergedFile stringValue]
											toPath:backupFilePath
											 error:nil];
	
	
	NSTask* aTask = [[[NSTask alloc]init]autorelease];
	NSPipe* pipe = [NSPipe pipe];
	NSString* command = [NSString stringWithFormat:IBTOOL_COMMAND2, [_txtMergedFile stringValue], mergedFileStrings, [_txtNewFile stringValue]];
	[aTask setLaunchPath:@"/bin/bash"];
	[aTask setArguments:[NSArray arrayWithObjects:@"-c", command, nil]];
	
	[aTask setStandardOutput: pipe];
	[aTask launch];
	[aTask waitUntilExit];
	
	NSFileHandle* aFile = [pipe fileHandleForReading];
	NSData* aData = [aFile readDataToEndOfFile];
	if([aData length] > 0)
	{
		NSString* aString = [NSString stringWithUTF8String: [aData bytes]];
		NSLog(@"%@", aString);
	}
	
	return nil;
}

- (IBAction) execute:(id)sender
{
	NSString* newFileStrings = [self createStringsFile:[_txtNewFile stringValue]];
	NSString* mergedFileStrings = [self createStringsFile:[_txtMergedFile stringValue]];
	
	[self mergeingXibFile:newFileStrings mergedFileStrings:mergedFileStrings];
	
	[[NSFileManager defaultManager]removeItemAtPath:newFileStrings error:nil];
	[[NSFileManager defaultManager]removeItemAtPath:mergedFileStrings error:nil];
}

@end

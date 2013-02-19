//
//  XibFileMergeAppDelegate.h
//  XibFileMerge
//
//  Created by susan335 on 12/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XibFileMergeAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow *window;
	
	IBOutlet NSTextField	*_txtNewFile;
	IBOutlet NSTextField	*_txtMergedFile;
	
	IBOutlet NSButton	*_btnSelectNewFile;
	IBOutlet NSButton	*_btnSelectMergedFile;
}

- (IBAction) pathSelect:(id)sender;
- (IBAction) execute:(id)sender;

@property (assign) IBOutlet NSWindow *window;

@end

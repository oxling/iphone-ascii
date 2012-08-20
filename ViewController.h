//
//  ViewController.h
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    UITextView * textView;
}

@property (nonatomic, retain) AVCaptureSession * session;
@property (nonatomic, retain) IBOutlet UITextView * textView;

@end

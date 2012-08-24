//
//  ViewController.h
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//  Copyright (c) 2012 Amy Dyer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ASCIIView.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
}

@property (nonatomic, retain) AVCaptureSession * session;
@property (nonatomic, retain) IBOutlet ASCIIView * asciiView;
@property (nonatomic, retain) IBOutlet UIView * photoButtonContainer;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityView;
@property (nonatomic, retain) IBOutlet UIButton * photoButton;

- (IBAction)takePhoto:(id)sender;

@end

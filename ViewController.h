//
//  ViewController.h
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ASCIIView.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    ASCIIView * asciiView;
}

@property (nonatomic, retain) AVCaptureSession * session;
@property (nonatomic, retain) ASCIIView * asciiView;

@end

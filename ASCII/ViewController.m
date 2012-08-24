//
//  ViewController.m
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//  Copyright (c) 2012 Amy Dyer. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "pixel_t.h"
#import "BlockGrid.h"

@interface ViewController ()

- (void) didTapScreen:(UITapGestureRecognizer *)tapper;
- (void) showPhotoButton:(BOOL)show;
- (void) startCaptureSession;
- (void) stopCaptureSession;

@end

@implementation ViewController
@synthesize session = _session, asciiView=_asciiView, photoButtonContainer=_photoButtonContainer;
@synthesize activityView = _activityView, photoButton = _photoButton;

#pragma mark - Memory Management

- (void) dealloc {
    [_session release];
    [_asciiView release];
    [_photoButtonContainer release];
    [_activityView release];
    [_photoButton release];
    [super dealloc];
}

#pragma mark - View management

- (void) viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapScreen:)];
    [_asciiView addGestureRecognizer:tapper];
    [tapper release];
}

- (void) viewDidUnload {
    self.asciiView = nil;
    self.photoButtonContainer = nil;
    self.activityView = nil;
    self.photoButton = nil;
    
    [super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {
    [self startCaptureSession];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self stopCaptureSession];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Video capture

- (void) startCaptureSession {
        
    NSError * error = nil;
    
    AVCaptureSession * session = [[[AVCaptureSession alloc] init] autorelease];
    session.sessionPreset = AVCaptureSessionPresetMedium;
        
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (error || !input) {
        NSLog(@"Error: %@", [error localizedDescription]);
        return;
    }
    
    [session addInput:input];
    
    AVCaptureVideoDataOutput * output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;
    [session addOutput:output];
    [output release];
    
    output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                                                       forKey:(id)kCVPixelBufferPixelFormatTypeKey];    
    dispatch_queue_t queue = dispatch_queue_create("AVQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    AVCaptureConnection * connection = [output connectionWithMediaType:AVMediaTypeVideo];
    connection.videoMinFrameDuration = CMTimeMake(1, 1/3);
    
    [session startRunning];
    self.session = session;
}

- (void) stopCaptureSession {
    [self.session stopRunning];
    self.session = nil;
}

static pixel_t * getPixel(void * data, int row, int col, size_t bytes_per_row)  {
    size_t offset = (bytes_per_row * row) + (sizeof(pixel_t) * col);
    return (pixel_t *) ((char *)data + offset);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection {
    
    CVImageBufferRef img = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(img, 0);
    
    size_t bytes_per_row = CVPixelBufferGetBytesPerRow(img);
    size_t width = CVPixelBufferGetWidth(img);
    size_t height = CVPixelBufferGetHeight(img);
    
    void * data = CVPixelBufferGetBaseAddress(img);
    
    //Scaling factor - pixels will be averaged in a block of size (gridRows * gridCols)
    int gridRows = 6;
    int gridCols = 8;
    
    int gridHeight = height/gridRows;
    int gridWidth = width/gridCols;
    
    //Video comes in rotated 90 degrees, hence the transform here.
    BlockGrid * grid = [[BlockGrid alloc] initWithWidth:gridHeight height:gridWidth];
    
    block_t block;
    
    for (int row=0; row<gridHeight; row++) {
        for (int col=0; col<gridWidth; col++) {
            float sum_r = 0;
            float sum_g = 0;
            float sum_b = 0;

            for (int pxCol=0; pxCol<gridCols; pxCol++) {
                for (int pxRow=0; pxRow<gridRows; pxRow++) {
                    pixel_t * px = getPixel(data, row*gridRows+pxRow, col*gridCols+pxCol, bytes_per_row);
                    
                    sum_r += px->r;
                    sum_g += px->g;
                    sum_b += px->b;
                }
            }
            
            
            int pxtotal = gridCols * gridRows;
            sum_r /= pxtotal * 255;
            sum_g /= pxtotal * 255;
            sum_b /= pxtotal * 255;
            
            block.r = sum_r;
            block.g = sum_g;
            block.b = sum_b;
            block.a = 1.0;
            
            //See above - video is in the wrong orientation. This rotates it correctly
            [grid copyBlock:&block toRow:col col:grid.width-row-1];
        }
    }

        
    CVPixelBufferUnlockBaseAddress(img, 0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_asciiView setGrid:grid];
        [grid release];
    });
    
}

#pragma mark - Screenshots

- (void) takePhoto:(id)sender {    
    _photoButton.hidden = YES;
    [_activityView startAnimating];
    
    BlockGrid * grid = _asciiView.grid;
    [grid retain];
    
    //Doing this in the background keeps the main thread from blocking while the app draws/saves
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        ASCIIView * view = [[ASCIIView alloc] initWithFrame:self.asciiView.frame];
        view.grid = grid;
        
        UIImage * image = [view takeScreenshot];
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        
        [grid release];
        [view release];
    });
    
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
        
    [self showPhotoButton:NO];
    [_activityView stopAnimating];
    
}

- (void) showPhotoButton:(BOOL)show {
    if (show) {
        _photoButtonContainer.alpha = 0;
        _photoButtonContainer.hidden = NO;
        
        [UIView animateWithDuration:0.25 animations:^{
            _photoButtonContainer.alpha = 1.0;
        } completion:^(BOOL finished) {
            _photoButton.hidden = NO;
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            _photoButtonContainer.alpha = 0.0;
        } completion:^(BOOL finished) {
            _photoButtonContainer.hidden = YES;
        }];
    }
}
- (void) didTapScreen:(UITapGestureRecognizer *)tapper {
    if (_photoButtonContainer.hidden == NO) {
        [self showPhotoButton:NO];
    } else {
        [self showPhotoButton:YES];
    }
}

@end

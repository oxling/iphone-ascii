//
//  ViewController.m
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "pixel_t.h"
#import "BlockGrid.h"

@implementation ViewController
@synthesize session = _session, asciiView;

- (void) dealloc {
    [_session release];
    [asciiView release];
    [super dealloc];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    asciiView = [[ASCIIView alloc] initWithFrame:CGRectInset(self.view.bounds, 0, 20)];
    [self.view addSubview:asciiView];
}

- (void) viewDidUnload {
    self.asciiView = nil;
    [super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {
        
    NSError * error = nil;
    
    AVCaptureSession * session = [[[AVCaptureSession alloc] init] autorelease];
    session.sessionPreset = AVCaptureSessionPresetLow;
        
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (error || !input) {
        NSLog(@"Error: %@", [error localizedDescription]);
        return;
    }
    
    [session addInput:input];
    
    AVCaptureVideoDataOutput * output = [[AVCaptureVideoDataOutput alloc] init];
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

- (void) viewDidDisappear:(BOOL)animated {
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
    int gridRows = 3;
    int gridCols = 4;
    
    int gridHeight = height/gridRows;
    int gridWidth = width/gridCols;
    
    //Video comes in oriented incorrectly, hence the transform here
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
                    
                    sum_r += (float)px->r/255;
                    sum_g += (float)px->g/255;
                    sum_b += (float)px->b/255;
                }
            }
            
            
            int pxtotal = gridCols * gridRows;
            sum_r /= pxtotal;
            sum_g /= pxtotal;
            sum_b /= pxtotal;
            
            block.r = sum_r;
            block.g = sum_g;
            block.b = sum_b;
            block.a = 1.0;
            
            //See above - video is in the wrong orientation
            [grid copyBlock:&block toRow:col col:grid.width-row-1];
        }
    }

        
    CVPixelBufferUnlockBaseAddress(img, 0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [asciiView setGrid:grid];
        [grid release];
    });
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

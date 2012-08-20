//
//  ViewController.m
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "letter.h"
#import "pixel_t.h";

@implementation ViewController
@synthesize session = _session, textView = _textView;

- (void) dealloc {
    [_session release];
    [_textView release];
    [super dealloc];
}

- (void) viewDidAppear:(BOOL)animated {
    
    [self createTree];
    
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

- (void) createTree {
    
    if (treeRoot != NULL) {
        destroyTree(treeRoot);
        treeRoot = NULL;
    }
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"definitions" ofType:@"txt"];
    NSString * text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSAssert(![text isEqualToString:@""], @"Could not load definitions.txt");
    
    NSArray * lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString * line in lines) {
        NSArray * components = [line componentsSeparatedByString:@":"];
        NSAssert([components count] == 2, @"Incorrect formatting in definitions file at line \"%@\"", line);
        
        const char * letterStr = [[components objectAtIndex:0] cString];
        char * letter = malloc(strlen(letterStr) + 1);
        strcpy(letter, letterStr);
        
        float darkness = [[components objectAtIndex:1] floatValue];
        
        if (treeRoot == NULL) {
            treeRoot = newNode(letter, darkness);
        } else {
            insertLetter(treeRoot, letter, darkness);
        }
        
        free(letter);
    }
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
    
    //Scaling factor - averages blocks 10px wide x 5 px high
    int gridRows = 6;
    int gridCols = 12;
    
    int gridHeight = height/gridRows;
    int gridWidth = width/gridCols;
    
    NSMutableString * str = [NSMutableString string];
    
    //Flip it sideways and mirror it
    for (int col=0; col<gridWidth; col++) {
        for (int row=gridHeight-1; row>=0; row--) {
            float sum = 0;
            for (int pxCol=0; pxCol<gridCols; pxCol++) {
                for (int pxRow=0; pxRow<gridRows; pxRow++) {
                    pixel_t * px = getPixel(data, row*gridRows+pxRow, col*gridCols+pxCol, bytes_per_row);
                    
                    //Increase the contrast by a lot
                    
                    float darkness = 0.2126 * (float)px->r + 0.7152 * (float)px->g + 0.0722 * (float)px->b;
                    sum += darkness/255;
                }
            }
            sum = sum/(gridCols * gridRows);
            char * letter = findLetter(treeRoot, sum);
            //printf("%s", letter);
            [str appendFormat:@"%s", letter];
        }
        [str appendFormat:@"\n"];
        //printf("\n");
    }

    
    //printf("\n\n");
    
    CVPixelBufferUnlockBaseAddress(img, 0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_textView setText:str];
    });
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

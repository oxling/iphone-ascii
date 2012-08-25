//
//  AcceleratedViewController.m
//  ASCII
//
//  Created by Amy Dyer on 8/25/12.
//
//

#import "AcceleratedViewController.h"
#import "GPUImage.h"

@interface DemoFilter : GPUImageFilter {
    GLint samplePercentUniform;
}

@end

@implementation DemoFilter

NSString *const fragmentString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform highp float samplePercent;
 
 void main() {     
     highp vec2 sampleDivisor = vec2(samplePercent, samplePercent);
     highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
     
     lowp vec4 color = texture2D(inputImageTexture, samplePos);
     lowp float dotScaling = (color.r + color.g + color.b) * 0.333; //size of dot is relative to darkness
     
     highp float distanceFromSamplePoint = distance(samplePos, textureCoordinate);
     lowp float checkForPresenceWithinDot = step(distanceFromSamplePoint, (samplePercent * 0.5) * dotScaling);
     
     gl_FragColor = vec4( vec3(1.0, 1.0, 1.0) * checkForPresenceWithinDot, 1.0);
 }
 
);

- (id) init {
    self = [super initWithFragmentShaderFromString:fragmentString];
    if (self) {
        samplePercentUniform = [filterProgram uniformIndex:@"samplePercent"];
        [self setFloat:0.015 forUniform:samplePercentUniform program:filterProgram];
    }
    return self;
}


@end


@interface AcceleratedViewController ()

@end

@implementation AcceleratedViewController

#pragma mark - View Management
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) viewDidAppear:(BOOL)animated {
    GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    GPUImageFilter *customFilter = [[DemoFilter alloc] init];

    
    float viewWidth = self.view.bounds.size.width;
    float viewHeight = self.view.bounds.size.height;
    
    GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, viewHeight)];
    
    // Add the view somewhere so it's visible
    
    [videoCamera addTarget:customFilter];
    [customFilter addTarget:filteredVideoView];
    
    [videoCamera startCameraCapture];
    
    [self.view addSubview:filteredVideoView];
}

@end

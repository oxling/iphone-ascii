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
    
     lowp vec4 sampleColor = texture2D(inputImageTexture, samplePos);
     lowp vec4 originalColor = texture2D(inputImageTexture, textureCoordinate);
     
     lowp float darkness = (originalColor.r + originalColor.b + originalColor.g) * 0.333;
     lowp vec4 outputColor;
     
     outputColor.r = darkness;
     outputColor.g = darkness;
     outputColor.b = darkness;
     outputColor.a = 1.0;
     
     outputColor = outputColor * sampleColor;
     
     gl_FragColor = outputColor;
 }
 
);

- (id) init {
    self = [super initWithFragmentShaderFromString:fragmentString];
    if (self) {
        samplePercentUniform = [filterProgram uniformIndex:@"samplePercent"];
        [self setFloat:0.025 forUniform:samplePercentUniform program:filterProgram];
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

//
//  ASCIIView.m
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//
//

#import "ASCIIView.h"
#import "letter.h"
#import <QuartzCore/QuartzCore.h>

@interface ASCIIView () {
    CGRect _bounds; //Saving the view's bounds makes drawing a tiny bit quicker
}

- (void) createTree;

@end

@implementation ASCIIView
@synthesize grid = _grid;

#pragma mark - Memory management

- (void) initializeVariables {
    self.backgroundColor = [UIColor blackColor];
    [self createTree];
    _bounds = self.bounds;
    
    self.layer.contents = (id) [UIImage imageNamed:@"Default.png"].CGImage;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {        
        [self initializeVariables];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeVariables];
    }
    return self;
}

- (void) dealloc {
    [_grid release];
    [super dealloc];
}

#pragma mark - Properties

- (void) setGrid:(BlockGrid *)grid {
    if (grid == _grid) return;
    [_grid release];
    [grid retain];
    
    _grid = grid;
    
    [self setNeedsDisplay];
}

- (void) setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    _bounds = bounds;
}

#pragma mark - Drawing

- (void) drawBlockAtRow:(int)row col:(int)col inContext:(CGContextRef) ctx {
    CGFloat blockWidth = _bounds.size.width / _grid.width;
    CGFloat blockHeight = _bounds.size.height / _grid.height;
    
    block_t block = [_grid blockAtRow:row col:col];
    
    //See wikipedia article on grayscale for an explanation of this formula.
    float darkness = 0.2126 * block.r + 0.7152 * block.g + 0.0722 * block.b;
    char * letter = findLetter(treeRoot, (1-darkness)); //Swapping darkness since we're on a black background
    
    CGRect rect = CGRectMake(_bounds.origin.x + blockWidth * col, _bounds.origin.y + blockHeight * row, blockWidth, blockHeight);
    
    block.a = 1.0;
    CGContextSetFillColor(ctx, (CGFloat *)&block);
    CGContextShowTextAtPoint(ctx, rect.origin.x, rect.origin.y, letter, strlen(letter));
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSelectFont(ctx, "Courier-Bold", 9.0, kCGEncodingMacRoman);
    CGContextSetCharacterSpacing(ctx, 1.7);
    CGContextSetTextDrawingMode(ctx, kCGTextFill);
    CGAffineTransform transform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
    CGContextSetTextMatrix(ctx, transform);
    
    for (int x=0; x < _grid.width; x++) {
        for (int y=0; y < _grid.height; y++) {
            [self drawBlockAtRow:y col:x inContext:ctx];
        }
    }
}

- (UIImage *) takeScreenshot {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    return UIGraphicsGetImageFromCurrentImageContext();
}

#pragma mark - ASCII

- (void) createTree {
    
    //treeRoot is global to the letter.h file; only needs to be created once.
    
    if (treeRoot == NULL) {
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
}


@end

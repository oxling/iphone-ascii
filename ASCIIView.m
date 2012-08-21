//
//  ASCIIView.m
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//
//

#import "ASCIIView.h"
#import "letter.h"

@interface ASCIIView ()

- (void) createTree;

@end

@implementation ASCIIView
@synthesize grid = _grid;

#pragma mark - Memory management

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self createTree];
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

#pragma mark - Drawing

- (void) drawBlockAtRow:(int)row col:(int)col inContext:(CGContextRef) ctx {
    CGRect bounds = self.bounds;
    CGFloat blockWidth = bounds.size.width / _grid.width;
    CGFloat blockHeight = bounds.size.height / _grid.height;
    
    block_t block = [_grid blockAtRow:row col:col];
    //See wikipedia article on grayscale
    float darkness = 0.2126 * block.r + 0.7152 * block.g + 0.0722 * block.b;
    char * letter = findLetter(treeRoot, darkness);
        
    CGContextSetFillColor(ctx, (CGFloat *)&block);
    CGRect rect = CGRectMake(bounds.origin.x + blockWidth * col, bounds.origin.y + blockHeight * row, blockWidth, blockHeight);
    CGContextFillRect(ctx, rect);
    
    //CGContextShowTextAtPoint(ctx, rect.origin.x, rect.origin.y, letter, strlen(letter));
    //CGContextFillRect(ctx, rect);
    
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    CGContextSetFillColorWithColor(ctx, self.backgroundColor.CGColor);
    CGContextFillRect(ctx, self.bounds);
    CGContextSelectFont(ctx, "Courier", 8.0, kCGEncodingMacRoman);
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

#pragma mark - ASCII

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


@end

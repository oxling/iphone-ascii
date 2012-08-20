//
//  ASCIIView.m
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//
//

#import "ASCIIView.h"
#import "letter.h"

typedef struct block {
    CGFloat r;
    CGFloat g;
    CGFloat b;
    CGFloat a;
} block_t;

@interface ASCIIView () {
    block_t * _blocks;
}

@end

@implementation ASCIIView
@synthesize gridWidth=_gridWidth, gridHeight=_gridHeight;

- (void) dealloc {
    free(_blocks);
    [super dealloc];
}

- (void) updateBlocks {
    if (_blocks) free(_blocks);
    unsigned long length = sizeof(block_t) * _gridHeight * _gridWidth;
    _blocks = malloc(length);
    memset(_blocks, 0, length);
}

- (void) setGridHeight:(int)gridHeight {
    _gridHeight = gridHeight;
    [self updateBlocks];
}

- (void)setGridWidth:(int)gridWidth {
    _gridWidth = gridWidth;
    [self updateBlocks];
}

- (void) drawBlockAtRow:(int)row col:(int)col inContext:(CGContextRef) ctx {
    CGRect bounds = self.bounds;
    CGFloat blockWidth = bounds.size.width / _gridWidth;
    CGFloat blockHeight = bounds.size.height / _gridHeight;
    
    size_t offset = _gridWidth * row + col;
    block_t * block = _blocks + offset;
        
    CGContextSetFillColor(ctx, (CGFloat *)block);
    CGRect rect = CGRectMake(bounds.origin.x + blockWidth * col, bounds.origin.y + blockHeight * row, blockWidth, blockHeight);
    CGContextFillRect(ctx, rect);
    
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    for (int x=0; x<_gridHeight; x++) {
        for (int y=0; y<_gridWidth; y++) {
            [self drawBlockAtRow:x col:y inContext:ctx];
        }
    }
}

- (void) setRGB:(CGFloat *)components atRow:(int)row col:(int)col {
    @synchronized(self) {
        size_t offset = _gridWidth * row + col;    
        memcpy(_blocks + offset, components, sizeof(block_t));
    }
}

@end

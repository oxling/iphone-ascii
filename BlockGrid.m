//
//  BlockGrid.m
//  ASCII
//
//  Created by Amy Dyer on 8/21/12.
//
//

#import "BlockGrid.h"

@interface BlockGrid () {
    block_t * _blocks;
    int _width;
    int _height;
}

@end

@implementation BlockGrid
@synthesize width=_width, height=_height;

#pragma mark - Memory Management

- (id) init {
    return [self initWithWidth:0 height:0];
}

- (id) initWithWidth:(int)width height:(int)height {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
        
        _blocks = malloc(sizeof(block_t) * _width * _height);
    }
    return self;
}

- (void) dealloc {
    free(_blocks);
    [super dealloc];
}

#pragma mark - Block manipulation

- (void) copyBlock:(block_t *)block toRow:(int)row col:(int)col {
    NSAssert(col < _width && row < _height, @"Tried to set block (%i, %i) outside of range (%i, %i)", col, row, _width, _height);
    
    @synchronized(self) {
        size_t offset = _width * row + col;
        memcpy(_blocks + offset, block, sizeof(block_t));
    }
}

- (block_t) blockAtRow:(int)row col:(int)col {
    NSAssert(col < _width && row < _height, @"Tried to retrieve block (%i, %i) outside of range (%i, %i)", col, row, _width, _height);
    
    block_t result;
    @synchronized(self) {
        size_t offset = _width * row + col;
        result = *(_blocks + offset);
    }
    return result;
}

@end

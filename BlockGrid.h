//
//  BlockGrid.h
//  ASCII
//
//  Created by Amy Dyer on 8/21/12.
//
//

#import <Foundation/Foundation.h>

typedef struct block {
    CGFloat r;
    CGFloat g;
    CGFloat b;
    CGFloat a;
} block_t;

/* BlockGrid is a wrapper around a buffer of block_t objects, which represent CGFloat color components */

@interface BlockGrid : NSObject

@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;

- (id) initWithWidth:(int)width height:(int)height;

- (block_t) blockAtRow:(int)row col:(int)col;
- (void) copyBlock:(block_t *)block toRow:(int)row col:(int)col;


@end

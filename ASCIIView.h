//
//  ASCIIView.h
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//
//

#import <UIKit/UIKit.h>

@interface ASCIIView : UIView

@property (nonatomic) int gridWidth;
@property (nonatomic) int gridHeight;

- (void) setRGB:(float *)components atRow:(int)row col:(int)col;

@end
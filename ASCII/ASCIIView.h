//
//  ASCIIView.h
//  ASCII
//
//  Created by Amy Dyer on 8/20/12.
//
//

#import <UIKit/UIKit.h>
#import "BlockGrid.h"

/* ASCIIView creates ASCII art from a Grid object */

@interface ASCIIView : UIView

@property (nonatomic, retain) BlockGrid * grid;

- (UIImage *) takeScreenshot;

@end
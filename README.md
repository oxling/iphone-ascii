# ASCII Cam

ASCII Cam is an iOS application that turns a video feed into ASCII art. The ASCII generation code is based on my previous project, Ascii Generator. 

## How it works

The application reads a video feed from the default device camera. Each frame is split up into cells of pixels, each of which represents an ASCII letter in the final rendering. The app then computes the average color of each cell and stores it in a ``BlockGrid`` object. ``BlockGrid`` is an objective-C wrapper around a buffer of CGFloats.

The main ViewController passes the ``BlockGrid`` to a custom UIView subclass ``ASCIIView``. For each cell in the grid, ASCIIView:

1. Computes the darkness of the cell on a scale of 1.0 to 0.0
2. Searches through a predefined binary tree of darkness/letter pairs. For example, this would match the darkness value 1.0 to a space and darkness 0.0 to an @. 
3. Draws the appropriate character in the cell, using the cell's color 

All drawing is done with Quartz. The app averages around 10 FPS, which feels fairly smooth. In the future, it might be an interesting exercise to port it to OpenGL instead.

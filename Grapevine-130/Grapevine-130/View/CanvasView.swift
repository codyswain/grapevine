// SOURCE CITATION:
// This drawing module is heavily based on the YouTube tutorial: https://www.youtube.com/watch?v=ZP9tWkTx7p4
// Originally, we wanted to follow: https://www.raywenderlich.com/5895-uikit-drawing-tutorial-how-to-make-a-simple-drawing-app
// so there may be remaining pieces from that
// Rendering from https://www.hackingwithswift.com/example-code/media/how-to-render-a-uiview-to-a-uiimage

import UIKit

/// Describes the canvas for drawing posts.
class CanvasView: UIView {
    var lineWidth:CGFloat!
    var path:UIBezierPath!
    var touchPoint:CGPoint!
    var startingPoint:CGPoint!
    var currentColor = Constants.Colors.darkPurple
    
    /// Sets up the canvas
    override func layoutSubviews() {
        self.clipsToBounds = true
        self.isMultipleTouchEnabled = false
        lineWidth = 6
    }
    
    /**
     Recognizes touch input on the screen.
     
     - Parameter touches: Touch recognizer
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        startingPoint = touch?.location(in: self)
    }
    
    /**
     Recognizes touch movement.
     
     - Parameter touches: Touch recognizer
     */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        touchPoint = touch?.location(in: self)
        
        path = UIBezierPath()
        path.move(to: startingPoint)
        path.addLine(to: touchPoint)
        
        startingPoint = touchPoint
        
        drawShapeLayer()
    }
    
    /// Draws the path.
    func drawShapeLayer() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = currentColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        self.layer.addSublayer(shapeLayer)
        self.setNeedsDisplay()
        
    }
    
    /// Clears the canvas.
    func clearCanvas() {
        if path != nil {
            path.removeAllPoints()
            self.layer.sublayers = nil
            self.setNeedsDisplay()
        } 
    }
    
    /**
     Renders the image on the canvas to a `UIImage`
     
     - Returns: `UIImage` version of the `UIView`
     */
    func renderToImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        var image : UIImage?
        if self.layer.sublayers != nil {
            image = renderer.image { ctx in
                self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
            }
        }
        
        return image
    }
    
    func changeColor(){
        if currentColor == Constants.Colors.darkPurple {
            self.currentColor = .black
        } else {
            self.currentColor = Constants.Colors.darkPurple
        }
        
    }
}

//
//  CircularView.swift
//  Animo
//
//  Created by Kauntey Suryawanshi on 29/06/15.
//  Copyright (c) 2015 Kauntey Suryawanshi. All rights reserved.
//

import Foundation
import Cocoa

@IBDesignable
class CircularProgressView: DeterminateAnimation {
    var backgroundLayer = CAShapeLayer()
    var backgroundCircle = CAShapeLayer()
    var progressLayer = CAShapeLayer()
        
    @IBInspectable var color: NSColor = NSColor.whiteColor() {
        didSet {
            backgroundCircle.strokeColor = color.colorWithAlphaComponent(0.5).CGColor
            progressLayer.strokeColor = color.CGColor
        }
    }
    
    @IBInspectable var backgroundColor: NSColor = NSColor(calibratedWhite: 0, alpha: 0.39) {
        didSet {
            backgroundLayer.fillColor = backgroundColor.CGColor
        }
    }
    
    @IBInspectable var strokeWidth: CGFloat = -1 {
        didSet {
            backgroundCircle.lineWidth = self.strokeWidth / 2
            progressLayer.lineWidth = strokeWidth
        }
    }

    override func updateProgress() {
        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(0.5)
        } else {
            CATransaction.setDisableActions(true)
        }
        let timing = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        CATransaction.setAnimationTimingFunction(timing)
        progressLayer.strokeEnd = max(0, min(progress, 1))
        CATransaction.commit()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        makeLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        makeLayers()
    }
    
    func makeLayers() {
        self.wantsLayer = true
        let rect = self.bounds
        let radius = (rect.width / 2) * 0.75

        func addBackgroundLayer(rect: NSRect) {
            let radius = NSWidth(rect) * 0.1
            backgroundLayer.frame = rect
            backgroundLayer.fillColor = backgroundColor.CGColor
            var backgroundPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
            backgroundLayer.path = backgroundPath.CGPath
            self.layer?.addSublayer(backgroundLayer)
        }
        
        let strokeScalingFactor = CGFloat(0.05)
        func addBackgroundCircle() {
            backgroundCircle.frame = rect
            backgroundCircle.lineWidth = strokeWidth == -1 ? (rect.width * strokeScalingFactor / 2) : strokeWidth / 2

            backgroundCircle.strokeColor = color.colorWithAlphaComponent(0.5).CGColor
            backgroundCircle.fillColor = NSColor.clearColor().CGColor
            var backgroundPath = NSBezierPath()
            backgroundPath.appendBezierPathWithArcWithCenter(rect.center(), radius: radius, startAngle: 0, endAngle: 360)
            backgroundCircle.path = backgroundPath.CGPath
            self.layer?.addSublayer(backgroundCircle)
        }
        
        func addProgressLayer(rect: NSRect, radius: CGFloat) {
            progressLayer.strokeStart = 0 //REMOVe this
            progressLayer.strokeEnd = 0 //REMOVe this
            progressLayer.fillColor = NSColor.clearColor().CGColor
            progressLayer.lineCap = kCALineCapRound
            progressLayer.lineWidth = strokeWidth == -1 ? (rect.width * strokeScalingFactor) : strokeWidth

            progressLayer.frame = rect
            progressLayer.strokeColor = color.CGColor
            var arcPath = NSBezierPath()
            var startAngle = CGFloat(90)
            arcPath.appendBezierPathWithArcWithCenter(rect.center(), radius: radius, startAngle: startAngle, endAngle: (startAngle - 360), clockwise: true)
            progressLayer.path = arcPath.CGPath
            self.layer?.addSublayer(progressLayer)
        }

        addBackgroundLayer(rect)
        addBackgroundCircle()
        addProgressLayer(rect, radius)
    }
}

extension NSRect {
    func center() -> NSPoint {
        let x = CGRectGetMidX(self)
        let y = CGRectGetMidY(self)
        return NSMakePoint(x, y)
    }
}

extension NSBezierPath {
    var CGPath: CGPathRef {
        get {
            return self.convertToCGPath()
        }
    }
    
    /// Transforms the NSBezierPath into a CGPathRef
    ///
    /// :returns: The transformed NSBezierPath
    private func convertToCGPath() -> CGPathRef {
        
        // Create path
        var path = CGPathCreateMutable()
        var points = UnsafeMutablePointer<NSPoint>.alloc(3)
        let numElements = self.elementCount
        
        if numElements > 0 {
            var didClosePath = true
            for index in 0..<numElements {
                let pathType = self.elementAtIndex(index, associatedPoints: points)
                switch pathType {
                case .MoveToBezierPathElement:
                    CGPathMoveToPoint(path, nil, points[0].x, points[0].y)
                case .LineToBezierPathElement:
                    CGPathAddLineToPoint(path, nil, points[0].x, points[0].y)
                    didClosePath = false
                case .CurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, nil, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y)
                    didClosePath = false
                case .ClosePathBezierPathElement:
                    CGPathCloseSubpath(path)
                    didClosePath = true
                }
            }
            if !didClosePath { CGPathCloseSubpath(path) }
        }
        points.dealloc(3)
        return path
    }
}
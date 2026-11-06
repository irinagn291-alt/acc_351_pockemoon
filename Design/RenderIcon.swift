// Original vector artwork for the nutrition journal. Run with an output PNG path.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let side = 1024
let c = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
    bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}
c.setFillColor(color(11, 18, 32))
c.fill(CGRect(x: 0, y: 0, width: side, height: side))
let colors = [color(21, 44, 76), color(11, 18, 32)] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
c.drawLinearGradient(gradient, start: CGPoint(x: 170, y: 1000), end: CGPoint(x: 800, y: 60), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
// A plate: a single bold blue ring, with a subtle inner rim.
c.setStrokeColor(color(77, 157, 255))
c.setLineWidth(46)
c.strokeEllipse(in: CGRect(x: 225, y: 225, width: 574, height: 574))
c.setStrokeColor(color(40, 73, 112))
c.setLineWidth(12)
c.strokeEllipse(in: CGRect(x: 285, y: 285, width: 454, height: 454))
// The leaf forms the food-first mark in the center of the plate.
let leaf = CGMutablePath()
leaf.move(to: CGPoint(x: 378, y: 387))
leaf.addCurve(to: CGPoint(x: 681, y: 675), control1: CGPoint(x: 321, y: 620), control2: CGPoint(x: 478, y: 710))
leaf.addCurve(to: CGPoint(x: 378, y: 387), control1: CGPoint(x: 712, y: 462), control2: CGPoint(x: 585, y: 333))
c.addPath(leaf)
c.setFillColor(color(53, 218, 156))
c.fillPath()
let vein = CGMutablePath()
vein.move(to: CGPoint(x: 369, y: 341))
vein.addCurve(to: CGPoint(x: 592, y: 591), control1: CGPoint(x: 400, y: 459), control2: CGPoint(x: 507, y: 530))
c.addPath(vein)
c.setStrokeColor(color(15, 31, 49))
c.setLineCap(.round)
c.setLineWidth(26)
c.strokePath()
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, c.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination), "Could not write icon")

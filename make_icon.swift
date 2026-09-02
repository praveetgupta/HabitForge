import Foundation
import CoreGraphics
import ImageIO
import CoreText
import UniformTypeIdentifiers
import AppKit

// HabitForge app icon generator.
// Family style (cross-referenced from DriveVerse + AutoRenew): flat gradient + single glyph.
// HabitForge branding (HANDOFF §5): deep near-black, gold #C9A84C / #D4AF61 / #E8C96B, serif.
// Glyph: the app's signature progress ring with a gap, flame or serif-H in the centre.
// Usage: swift gen_icon.swift <output.png> <flame|monogram>

let size = 1024

// Palette
let bgTopLeft     = CGColor(red: 0.070, green: 0.062, blue: 0.047, alpha: 1)  // #12100C warm near-black
let bgBottomRight = CGColor(red: 0.157, green: 0.129, blue: 0.078, alpha: 1)  // #282014 dark bronze
let goldLight     = CGColor(red: 0.910, green: 0.788, blue: 0.420, alpha: 1)  // #E8C96B
let goldMid       = CGColor(red: 0.788, green: 0.659, blue: 0.298, alpha: 1)  // #C9A84C
let goldDeep      = CGColor(red: 0.600, green: 0.478, blue: 0.200, alpha: 1)  // #997A33

func makeContext() -> CGContext {
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                              bytesPerRow: 0, space: space,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        fatalError("could not create CGContext")
    }
    return ctx
}

func writePNG(_ image: CGImage, to path: String) {
    let utType = UTType.png.identifier
    guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, utType as CFString, 1, nil) else {
        fatalError("could not create image destination at \(path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("could not write png to \(path)") }
    print("wrote \(path)")
}

func drawBackground(_ ctx: CGContext) {
    // Diagonal warm near-black gradient (top-left → bottom-right)
    let colors = [bgTopLeft, bgBottomRight] as CFArray
    guard let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1]) else {
        fatalError("gradient")
    }
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: CGFloat(size)), end: CGPoint(x: CGFloat(size), y: 0), options: [])

    // Soft gold glow behind the glyph
    let glowColors = [
        CGColor(red: 0.910, green: 0.788, blue: 0.420, alpha: 0.14),
        CGColor(red: 0.910, green: 0.788, blue: 0.420, alpha: 0.0)
    ] as CFArray
    guard let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: glowColors, locations: [0, 1]) else {
        fatalError("glow")
    }
    ctx.drawRadialGradient(glow,
                           startCenter: CGPoint(x: 512, y: 560), startRadius: 0,
                           endCenter: CGPoint(x: 512, y: 560), endRadius: 460,
                           options: [])
}

/// The signature progress ring: gold arc, round caps, gap at the top-right (~280° sweep).
func drawRing(_ ctx: CGContext) {
    let center = CGPoint(x: 512, y: 512)
    let radius: CGFloat = 302
    let lineWidth: CGFloat = 64

    let gapCenter: CGFloat = .pi / 4          // 45° = top-right
    let gapHalf: CGFloat = .pi * 0.19         // ~34° each side → ~292° ring
    let start = gapCenter + gapHalf
    let end = gapCenter - gapHalf + 2 * .pi   // drawn CCW the long way round

    let ring = CGMutablePath()
    ring.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false, transform: .identity)

    ctx.saveGState()
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    ctx.addPath(ring)
    ctx.replacePathWithStrokedPath()
    ctx.clip()

    let colors = [goldLight, goldMid, goldDeep] as CFArray
    guard let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 0.55, 1]) else {
        fatalError("ring gradient")
    }
    // Gold falls top-left → bottom-right like the background
    ctx.drawLinearGradient(grad,
                           start: CGPoint(x: 512 - radius, y: 512 + radius),
                           end: CGPoint(x: 512 + radius, y: 512 - radius),
                           options: [])
    ctx.restoreGState()

    // Small circular "progress dot" capping the arc's leading end (reads as the ring's head)
    let dotAngle = gapCenter - gapHalf
    let dot = CGPoint(x: center.x + radius * cos(dotAngle), y: center.y + radius * sin(dotAngle))
    ctx.setFillColor(goldLight)
    ctx.fillEllipse(in: CGRect(x: dot.x - lineWidth * 0.62, y: dot.y - lineWidth * 0.62,
                               width: lineWidth * 1.24, height: lineWidth * 1.24))
}

/// Variant A — flame (streaks / forge fire) inside the ring, with an inner cut-out.
func drawFlame(_ ctx: CGContext) {
    let flame = CGMutablePath()

    // Outer flame: tip leans slightly right, body bulges at the bottom, rounded base.
    flame.move(to: CGPoint(x: 512, y: 700))
    flame.addCurve(to: CGPoint(x: 402, y: 470),
                   control1: CGPoint(x: 448, y: 626), control2: CGPoint(x: 396, y: 548))
    flame.addCurve(to: CGPoint(x: 474, y: 352),
                   control1: CGPoint(x: 408, y: 414), control2: CGPoint(x: 428, y: 372))
    flame.addCurve(to: CGPoint(x: 550, y: 352),
                   control1: CGPoint(x: 500, y: 332), control2: CGPoint(x: 524, y: 332))
    flame.addCurve(to: CGPoint(x: 622, y: 470),
                   control1: CGPoint(x: 596, y: 372), control2: CGPoint(x: 616, y: 414))
    flame.addCurve(to: CGPoint(x: 512, y: 700),
                   control1: CGPoint(x: 628, y: 548), control2: CGPoint(x: 576, y: 626))
    flame.closeSubpath()

    // Inner tongue cut-out (shows the background through it)
    let inner = CGMutablePath()
    inner.move(to: CGPoint(x: 512, y: 470))
    inner.addCurve(to: CGPoint(x: 462, y: 392),
                   control1: CGPoint(x: 476, y: 438), control2: CGPoint(x: 462, y: 416))
    inner.addCurve(to: CGPoint(x: 562, y: 392),
                   control1: CGPoint(x: 548, y: 376), control2: CGPoint(x: 548, y: 376))
    inner.addCurve(to: CGPoint(x: 512, y: 470),
                   control1: CGPoint(x: 562, y: 438), control2: CGPoint(x: 536, y: 438))
    inner.closeSubpath()

    flame.addPath(inner)

    ctx.saveGState()
    ctx.addPath(flame)
    ctx.clip(using: .evenOdd)

    let colors = [goldLight, goldMid] as CFArray
    guard let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1]) else {
        fatalError("flame gradient")
    }
    ctx.drawLinearGradient(grad,
                           start: CGPoint(x: 512, y: 710),
                           end: CGPoint(x: 512, y: 340),
                           options: [])
    ctx.restoreGState()
}

/// Variant B — serif "H" monogram (old-money wordmark style) inside the ring.
func drawMonogram(_ ctx: CGContext) {
    let font = CTFontCreateWithName("Didot-Bold" as CFString, 400, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: goldLight
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: "H", attributes: attrs))

    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    // Flip for CoreText (it draws in y-up space; bitmap is y-up too — but CT expects y-down text origin)
    ctx.saveGState()
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)

    let x = 512 - bounds.midX
    let y = 512 - bounds.midY
    ctx.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

let args = CommandLine.arguments
guard args.count >= 3 else {
    fatalError("usage: swift gen_icon.swift <output.png> <flame|monogram>")
}
let output = args[1]
let variant = args[2]

let ctx = makeContext()
drawBackground(ctx)
drawRing(ctx)
switch variant {
case "flame": drawFlame(ctx)
case "monogram": drawMonogram(ctx)
default: fatalError("unknown variant \(variant)")
}

guard let image = ctx.makeImage() else { fatalError("makeImage") }
writePNG(image, to: output)

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceDirectory = root.appendingPathComponent("assets/brand")
let outputDirectory = sourceDirectory.appendingPathComponent("generated")
let canvasSize = 1024

func render(
    sourceName: String,
    outputName: String,
    artworkWidth: CGFloat,
    background: NSColor? = nil
) throws {
    let sourceURL = sourceDirectory.appendingPathComponent(sourceName)
    guard
        let sourceImage = NSImage(contentsOf: sourceURL),
        let cgImage = sourceImage.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        )
    else {
        throw NSError(
            domain: "BrandAssetGenerator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not load \(sourceURL.path)"]
        )
    }

    guard let context = CGContext(
        data: nil,
        width: canvasSize,
        height: canvasSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(
            domain: "BrandAssetGenerator",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Could not create image context"]
        )
    }

    if let background {
        context.setFillColor(background.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
    }

    let scale = artworkWidth / CGFloat(cgImage.width)
    let width = CGFloat(cgImage.width) * scale
    let height = CGFloat(cgImage.height) * scale
    let rect = CGRect(
        x: (CGFloat(canvasSize) - width) / 2,
        y: (CGFloat(canvasSize) - height) / 2,
        width: width,
        height: height
    )
    context.interpolationQuality = .high
    context.draw(cgImage, in: rect)

    guard let output = context.makeImage(),
          let png = NSBitmapImageRep(cgImage: output).representation(
              using: .png,
              properties: [:]
          ) else {
        throw NSError(
            domain: "BrandAssetGenerator",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Could not encode \(outputName)"]
        )
    }

    try png.write(to: outputDirectory.appendingPathComponent(outputName))
}

try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

try render(
    sourceName: "logo-white.png",
    outputName: "app_icon_ios.png",
    artworkWidth: 716,
    background: NSColor(
        red: 204 / 255,
        green: 51 / 255,
        blue: 51 / 255,
        alpha: 1
    )
)
try render(
    sourceName: "logo-white.png",
    outputName: "app_icon_foreground.png",
    artworkWidth: 675
)
try render(
    sourceName: "logo-white.png",
    outputName: "app_icon_monochrome.png",
    artworkWidth: 675
)
try render(
    sourceName: "logo-red.png",
    outputName: "splash_light.png",
    artworkWidth: 716
)
try render(
    sourceName: "logo-white.png",
    outputName: "splash_dark.png",
    artworkWidth: 716
)
try render(
    sourceName: "logo-red.png",
    outputName: "splash_android12_light.png",
    artworkWidth: 675
)
try render(
    sourceName: "logo-white.png",
    outputName: "splash_android12_dark.png",
    artworkWidth: 675
)

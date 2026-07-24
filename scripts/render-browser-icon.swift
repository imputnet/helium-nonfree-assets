#!/usr/bin/env swift

import AppKit

guard CommandLine.arguments.count == 4 else {
    FileHandle.standardError.write(
        Data("Usage: render-browser-icon.swift <app> <output> <name>\n".utf8)
    )
    exit(64)
}

let appPath = URL(fileURLWithPath: CommandLine.arguments[1])
    .resolvingSymlinksInPath()
    .path
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let browserName = CommandLine.arguments[3]

func legacyIcon(forAppAt appPath: String) -> NSImage? {
    guard
        let bundle = Bundle(path: appPath),
        let resourcesURL = bundle.resourceURL,
        let iconFile = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String
    else {
        return nil
    }

    var iconURL = resourcesURL.appendingPathComponent(iconFile)
    if iconURL.pathExtension.isEmpty {
        iconURL.appendPathExtension("icns")
    }

    return NSImage(contentsOf: iconURL)
}

let image: NSImage

// Arc and Opera don't ship Liquid Glass icons, so we use legacy ones instead.
if browserName == "arc" || browserName == "opera" {
    image = legacyIcon(forAppAt: appPath)
        ?? NSWorkspace.shared.icon(forFile: appPath)
} else {
    image = NSWorkspace.shared.icon(forFile: appPath)
}

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    FileHandle.standardError.write(Data("Could not render: \(appPath)\n".utf8))
    exit(1)
}

try png.write(to: outputURL)

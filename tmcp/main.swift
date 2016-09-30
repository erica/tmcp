//
//  tmcp - perform a time machine copy
//
//  Created by Erica Sadun on 9/30/16.
//  Copyright © 2016 Erica Sadun. All rights reserved.


import Cocoa
public let manager = FileManager.default

// Fetch arguments and test for usage
var arguments = CommandLine.arguments
let appName = arguments.remove(at: 0).lastPathComponent
func usage() -> Never {
    print("Usage: \(appName) paths")
    print("       \(appName) --offset count paths")
    print("       \(appName) --list (count)")
    print("       \(appName) --help")
    print("")
    print("Copies time machine versions to the current folder")
    print("appending the time machine date to the copy.")
    print("For example `\(appName) --offset 3 README.txt` might")
    print("copy the file to `README.txt+2016-09-30-100004`")
    exit(-1)
}

// Help message
if arguments.contains("--help") { usage() }

// Fetch time machine backup list in reverse order
let tmItems = tmlist()

// Perform Time Machine backup list
if arguments.contains("--list") {
    var max = tmItems.count
    if let argOffset = arguments.index(of: "--list"),
        arguments.index(after: argOffset) < arguments.endIndex
    {
        let countString = arguments[arguments.index(after: argOffset)]
        if let count = Int(countString), count < max { max = count }
    }
    tmItems.prefix(upTo: max).enumerated().forEach {
        print("\($0.0): \($0.1.ns.lastPathComponent)")
    }
    exit(0)
}

// Process offset
var offset = 1
if arguments.contains("--offset") {
    var max = tmItems.count
    if let argOffset = arguments.index(of: "--offset"),
        arguments.index(after: argOffset) < arguments.endIndex {
        let countOffset = arguments.index(after: argOffset)
        let countString = arguments[countOffset]
        if let count = Int(countString), count < max { offset = count }
        else { print("Offset invalid or too high (max is \(max - 1))"); exit(-1) }
        [countOffset, argOffset].forEach { arguments.remove(at: $0) }
    } else {
        print("Invalid use of --offset (must be followed by a number)"); exit(-1)
    }
}

// Remove any dashed things that may have snuck into this call
arguments = arguments.filter({ !$0.hasPrefix("-") })

// Check whether any paths are left
if arguments.isEmpty {
    print("No files to copy")
    usage()
}

// Test offset
guard tmItems.count > offset else {
    print("Invalid time machine offset (\(offset) > \(tmItems.count))")
    exit(-1)
}

let tmPath = tmItems[offset]
arguments = arguments.flatMap({ makeCanonical(tmPath: tmPath, sourcePath: $0) })

print("Time Machine: \(tmPath.lastPathComponent)\n")

let wd = manager.currentDirectoryPath

// Perform copies
for path in arguments {
    guard manager.fileExists(atPath: path) else {
        print("\"\(path.lastPathComponent)\" is not part of this time machine backup. Skipping.")
        continue
    }
    
    let destinationPath = wd
        .appendingPathComponent(path.lastPathComponent)
        .appending("+")
        .appending(tmPath.lastPathComponent)
    print("Copying \(path.lastPathComponent) to \(destinationPath)")
    
    let task = Process()
    task.launchPath = "/bin/cp"
    task.arguments = [path, destinationPath]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()
    
    let data = pipe
        .fileHandleForReading
        .readDataToEndOfFile()
    
    print(String(data: data, encoding: String.Encoding.utf8) ?? "")
}


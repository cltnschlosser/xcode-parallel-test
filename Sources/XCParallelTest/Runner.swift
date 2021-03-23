//
//  Runner.swift
//
//
//  Created by Colton Schlosser on 6/19/20.
//

import Foundation
import XcodeProj

private enum Errors: Error {
    case noScheme(String)
    case nonZeroExit
    case failedTests
}

public struct Runner {
    private let config: Config
    private let kind: ProjectKind
    private let schemeName: String
    private let batching: Bool

    public init(config: Config, kind: ProjectKind, scheme: String, batching: Bool) {
        self.config = config
        self.kind = kind
        self.schemeName = scheme
        self.batching = batching
    }

    public func run() throws {
        try? FileManager.default.removeItem(atPath: "build")
        try FileManager.default.createDirectory(atPath: "build/data", withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: "build/logs", withIntermediateDirectories: true)

        let targets = try testTargets()

        try build()

        let devicePool = DevicePool(destinations: config.destinations)
        if batching {
            let parallelCount = config.destinations.count
            // ceil(targets / destinations)
            let batchSize = (targets.count + parallelCount - 1) / parallelCount
            let batches = targets.chunked(into: batchSize)
            for (index, batch) in batches.enumerated() {
                devicePool.useDestination { destination in
                    let process = Process()
                    process.launchPath = "/usr/bin/env"
                    process.arguments = ["xcodebuild"]
                        + self.kind.xcodebuildArguments
                        + ["-scheme", self.schemeName,
                           "-derivedDataPath", "build/data",
                           "-destination", destination]
                        + batch.map { "-only-testing:\($0)" }
                        + ["test-without-building"]
                    let path = "build/logs/test-\(index).log"
                    FileManager.default.createFile(atPath: path, contents: nil)
                    let output = FileHandle(forWritingAtPath: path)!
                    process.standardOutput = output
                    process.standardError = output
                    process.launch()
                    process.waitUntilExit()
                    output.closeFile()
                    if process.terminationStatus != 0 {
                        throw Errors.nonZeroExit
                    }
                }
            }
        } else {
            for target in targets {
                devicePool.useDestination { destination in
                    let process = Process()
                    process.launchPath = "/usr/bin/env"
                    process.arguments = ["xcodebuild"]
                        + self.kind.xcodebuildArguments
                        + ["-scheme", self.schemeName,
                           "-derivedDataPath", "build/data",
                           "-destination", destination,
                           "-only-testing:\(target)",
                            "test-without-building"]
                    let path = "build/logs/test-\(target).log"
                    FileManager.default.createFile(atPath: path, contents: nil)
                    let output = FileHandle(forWritingAtPath: path)!
                    process.standardOutput = output
                    process.standardError = output
                    process.launch()
                    process.waitUntilExit()
                    output.closeFile()
                    if process.terminationStatus != 0 {
                        throw Errors.nonZeroExit
                    }
                }
            }
        }

        if !devicePool.waitForFinish() {
            throw Errors.failedTests
        }
    }

    private func build() throws {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["xcodebuild"]
            + kind.xcodebuildArguments
            + ["-scheme", schemeName,
               "-derivedDataPath", "build/data"]
            + config.destinations.flatMap { ["-destination", $0] }
            + ["build-for-testing"]
        let path = "build/logs/xcodebuild.log"
        FileManager.default.createFile(atPath: path, contents: nil)
        let output = FileHandle(forWritingAtPath: path)!
        process.standardOutput = output
        process.standardError = output
        process.launch()
        process.waitUntilExit()
        output.closeFile()
        if process.terminationStatus != 0 {
            throw Errors.nonZeroExit
        }
    }

    private func testTargets() throws -> [String] {
        let project = try kind.xcodeProject()
        let scheme = try project.scheme(name: schemeName)
        guard let testables = scheme.testAction?.testables else { return [] }
        return testables.map { $0.buildableReference.blueprintName }
    }
}

private extension ProjectKind {
    func xcodeProject() throws -> XcodeProj {
        switch self {
        case let .project(path):
            return try XcodeProj(pathString: path)
        case let .workspace(_, project):
            return try XcodeProj(pathString: project)
        }
    }

    var xcodebuildArguments: [String] {
        switch self {
        case let .project(path):
            return ["-project", path]
        case let .workspace(path, _):
            return ["-workspace", path]
        }
    }
}

private extension XcodeProj {
    func scheme(name: String) throws -> XCScheme {
        guard let sharedData = sharedData,
            let scheme = sharedData.schemes.first(where: { $0.name == name }) else {
                throw Errors.noScheme(name)
        }
        return scheme
    }
}

// https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

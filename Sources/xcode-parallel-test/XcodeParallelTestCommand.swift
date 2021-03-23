//
//  XcodeParallelTestCommand.swift
//  
//
//  Created by Colton Schlosser on 6/19/20.
//

import ArgumentParser
import Foundation
import XCParallelTest
import Yams

struct XcodeParallelTest: ParsableCommand {
    @Option(help: "Path to config yml file")
    var config: String

    @Option(help: "Path to workspace")
    var workspace: String?

    @Option(help: "Path to project")
    var project: String

    @Option(help: "Name of the scheme")
    var scheme: String

    @Flag(name: .long, help: "Run xcodebuild in batches")
    var batching: Bool

    private var projectKind: ProjectKind {
        if let workspace = workspace {
            return .workspace(path: workspace, project: project)
        } else {
            return .project(path: project)
        }
    }

    mutating func run() throws {
        let configString = try String(contentsOfFile: config)
        let decoder = YAMLDecoder()
        let config = try decoder.decode(Config.self, from: configString)

        let runner = Runner(config: config,
                            kind: projectKind,
                            scheme: scheme,
                            batching: batching)
        try runner.run()
    }
}

//
//  RequiresInstruction.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 15/07/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public final class RequiresInstruction: Instruction {
    public let lineNumber: Int
    public let plugin: String
    public let version: Version
    
    public init(lineNumber: Int, plugin: String, version: Version) {
        self.lineNumber = lineNumber
        self.plugin = plugin
        self.version = version
    }
    
    public func run(context: GRPHContextProtocol) throws {
        guard let current = RequiresInstruction.currentVersion(plugin: plugin) else {
            try throwUnsupported(context: context, message: "This script requires '\(plugin)'")
        }
        if version > current {
            try throwUnsupported(context: context, message: "This script requires \(plugin) \(version), current version is \(current)")
        }
    }
    
    func throwUnsupported(context: GRPHContextProtocol, message: String) throws -> Never {
        if context is CompilingContext {
            throw GRPHCompileError(type: .unsupported, message: message)
        } else {
            throw GRPHRuntimeError(type: .reflection, message: message)
        }
    }
    
    public func toString(indent: String) -> String {
        "\(line):\(indent)#requires \(plugin) \(version)"
    }
    
    public static func currentVersion(plugin: String) -> Version? {
        switch plugin {
        case "GRPH", "GRPHSwift":
            return Version(1, 11)
        case "Swift":
            return Version(5, 3)
        #if os(iOS)
        case "iOS":
            return Version(14) // Not using exact version because it doesn't matter
        #elseif os(macOS)
        case "macOS":
            if #available(OSX 10.16, *) {
                return Version(11, 0)
            } else {
                return Version(10, 15)
            }
        #endif
        default:
            return nil
        }
    }
    
    public var astNodeData: String {
        "throw if \(plugin) version \(version) isn't available"
    }
    
    public var astChildren: [ASTElement] { [] }
}

public struct Version: Comparable {
    public let components: [Int]
    
    public init(_ components: Int...) {
        self.components = components
    }
    
    public static func < (lhs: Version, rhs: Version) -> Bool {
        for i in 0..<min(lhs.components.count, rhs.components.count) {
            if lhs.components[i] < rhs.components[i] {
                return true
            } else if lhs.components[i] > rhs.components[i] {
                return false
            }
        }
        return lhs.components.count < rhs.components.count
    }
}

extension Version: CustomStringConvertible {
    public var description: String {
        components.map(String.init).joined(separator: ".")
    }
    
    public init?(description: String) {
        var success = true
        components = description.components(separatedBy: ".").map { str in
            if let i = Int(str) {
                return i
            } else {
                success = false
                return 0
            }
        }
        if !success {
            return nil
        }
    }
}

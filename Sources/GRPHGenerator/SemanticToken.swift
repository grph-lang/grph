//
//  File.swift
//  File
//
//  Created by Emil Pedersen on 09/09/2021.
//

import Foundation
import GRPHLexer
import GRPHValues

public struct SemanticToken {
    public var token: Token
    
    public var modifiers: Modifiers
    
    public struct Modifiers: OptionSet {
        public static let none: Self = []
        
        public static let declaration = Self(rawValue: 1 << 0)
        public static let definition = Self(rawValue: 1 << 1)
        public static let readonly = Self(rawValue: 1 << 2)
        public static let deprecated = Self(rawValue: 1 << 3)
        public static let modification = Self(rawValue: 1 << 4)
        public static let documentation = Self(rawValue: 1 << 5)
        public static let defaultLibrary = Self(rawValue: 1 << 6)
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public var rawValue: UInt32
    }
}

extension Token {
    func withModifiers(_ modifiers: SemanticToken.Modifiers) -> SemanticToken {
        SemanticToken(token: self, modifiers: modifiers)
    }
}

extension Function {
    var semantic: SemanticToken.Modifiers {
        switch storage {
        case .native:
            return .defaultLibrary
        case .block(_):
            return []
        }
    }
}

extension Variable {
    var semantic: SemanticToken.Modifiers {
        final ? .readonly : .none
    }
}

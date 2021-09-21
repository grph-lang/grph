//
//  SemanticToken.swift
//  GRPH Generator
//
//  Created by Emil Pedersen on 09/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHLexer
import GRPHValues

public struct SemanticToken {
    public var token: Token
    
    public var modifiers: Modifiers
    
    public var data: AssociatedData
    
    public init(token: Token, modifiers: SemanticToken.Modifiers, data: SemanticToken.AssociatedData) {
        self.token = token
        self.modifiers = modifiers
        self.data = data
    }
    
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
    
    public enum AssociatedData {
        case function(Function)
        case method(GRPHValues.Method)
        case variable(Variable)
        case property(Property)
        case constructor(Constructor)
        case identifier(String)
        
        case none
    }
}

extension Token {
    func withModifiers(_ modifiers: SemanticToken.Modifiers, data: SemanticToken.AssociatedData? = nil) -> SemanticToken {
        SemanticToken(token: self, modifiers: modifiers, data: data ?? .none)
    }
    
    func forVariable(_ variable: Variable?) -> SemanticToken {
        withModifiers(variable?.semantic ?? [], data: variable.map( { .variable($0) }))
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

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
        
        /// This token is part of a declaration: the current token is here potentially given a name and a type, it is created
        public static let declaration = Self(rawValue: 1 << 0)
        /// This token is defined, it is given a value. Will always also be a declaration.
        public static let definition = Self(rawValue: 1 << 1)
        /// This token cannot be written to. For variables & properties only.
        public static let readonly = Self(rawValue: 1 << 2)
        /// This token is deprecated
        public static let deprecated = Self(rawValue: 1 << 3)
        /// This token is currently being modified, as the left hand side of an assignment. **Warning:** this is currently not set for lvalues.
        public static let modification = Self(rawValue: 1 << 4)
        /// This token is inside a documentation. Example: A parameter inside a doc comment
        public static let documentation = Self(rawValue: 1 << 5)
        /// This token is part of the standard library. Builtin functions, methods, types, commands and enum cases will be annotated with this.
        public static let defaultLibrary = Self(rawValue: 1 << 6)
        
        // TODO add call, access, etc
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public var rawValue: UInt32
    }
    
    public enum AssociatedData {
        case function(Function)
        case method(GRPHValues.Method)
        case variable(Variable)
        case property(Property, in: GRPHType)
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

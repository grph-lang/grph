//
//  Documentation.swift
//  GRPH DocGen
//
//  Created by Emil Pedersen on 10/09/2021.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHGenerator
import GRPHValues

public struct Documentation {
    // modifier will always include declaration
    /// The semantic token for the declaration of the symbol
    public var symbol: SemanticToken
    
    /// The documentation overview & explanation for the member
    public var info: String
    
    /// The version at which the symbol was introduced
    public var since: String?
    /// Information about the deprecation of this symbol, including the version at which it was deprecated (nil if not deprecated)
    public var deprecation: String?
    
    /// Other relevant members
    public var seeAlso: [String]
    /// The documentation for each parameter of this member, if it is a function, method or constructor
    public var paramDoc: [Parameter]
    
    public struct Parameter {
        public var name: String
        public var doc: String?
    }
}

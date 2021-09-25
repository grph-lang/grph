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

public extension Documentation {
    var markdown: String {
        var doc = ""
        
        if let name = symbol.documentationNames.last {
            doc += "**\(name.replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]"))**\n\n"
        }
        
        doc += info + "\n\n"
        if let since = since {
            doc += "**Since**: \(since)  \n"
        }
        
        if let deprecation = deprecation {
            doc += "**Deprecated**: \(deprecation)  \n"
        }
        
        if !paramDoc.isEmpty {
            doc += "**Parameters**:\n"
            for param in paramDoc {
                doc += "- `\(param.name)`: \(param.doc ?? "*No documentation found*")\n"
            }
            doc += "\n"
        }
        
        if !seeAlso.isEmpty {
            doc += "**See Also**:\n"
            for see in seeAlso {
                doc += "- [\(see)](\(see))\n"
            }
            doc += "\n"
        }
        
        return doc
    }
}

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
    public var symbol: SemanticToken
    
    public var info: String
    public var since: String?
    
    public var seeAlso: [String]
    public var paramDoc: [Parameter]
    
    public struct Parameter {
        public var name: String
        public var doc: String?
    }
}

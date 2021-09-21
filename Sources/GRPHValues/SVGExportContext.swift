//
//  SVGExportContext.swift
//  GRPH Values
//
//  Created by Emil Pedersen on 04/08/2020.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

public struct SVGExportContext {
    public init() {
        
    }
}

extension TextOutputStream {
    @inlinable mutating func writeln(_ string: String) {
        write(string + "\n")
    }
}

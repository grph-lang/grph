//
//  SVGExportContext.swift
//  Graphism
//
//  Created by Emil Pedersen on 04/08/2020.
//

import Foundation

public struct SVGExportContext {
    
}

extension TextOutputStream {
    @inlinable mutating func writeln(_ string: String) {
        write(string + "\n")
    }
}

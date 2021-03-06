//
//  TupleType.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 19/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension TupleType: RepresentableGRPHType {
    var typeid: UInt8 {
        128
    }
    
    var genericsVector: [RepresentableGRPHType] {
        content.map { ($0 as! RepresentableGRPHType) }
    }
    
    var representationMode: RepresentationMode {
        for cnt in content where (cnt as! RepresentableGRPHType).representationMode != .pureValue {
            return .impureValue
        }
        return .pureValue
    }
    
    var vwt: ValueWitnessTable {
        .tupleRecursive
    }
    
    func asLLVM() throws -> IRType {
        try StructType(elementTypes: content.map { try $0.findLLVMType() })
    }
}

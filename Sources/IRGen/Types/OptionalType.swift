//
//  OptionalType.swift
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

// if wrapped is a reference, we could be a nullable reference
extension OptionalType: RepresentableGRPHType {
    var typeid: UInt8 {
        130
    }
    
    var genericsVector: [RepresentableGRPHType] {
        [wrapped as! RepresentableGRPHType]
    }
    
    var representationMode: RepresentationMode {
        if (wrapped as! RepresentableGRPHType).representationMode == .pureValue {
            return .pureValue
        }
        return .impureValue
    }
    
    var vwt: ValueWitnessTable {
        representationMode == .pureValue ? .trivial : .optionalRecursive
    }
    
    func getLLVMType() throws -> StructType {
        StructType(elementTypes: [IntType.int1, try wrapped.findLLVMType()])
    }
    
    func asLLVM() throws -> IRType {
        try getLLVMType()
    }
}

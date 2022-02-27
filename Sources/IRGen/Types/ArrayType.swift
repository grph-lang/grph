//
//  ArrayType.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension GRPHValues.ArrayType: RepresentableGRPHType {
    var typeid: UInt8 {
        129
    }
    
    var genericsVector: [RepresentableGRPHType] {
        [content as! RepresentableGRPHType]
    }
    
    var representationMode: RepresentationMode {
        .referenceType
    }
    
    func asLLVM() throws -> IRType {
        PointerType.toVoid
    }
}

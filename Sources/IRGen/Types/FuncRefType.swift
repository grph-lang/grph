//
//  FuncRefType.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 02/06/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension FuncRefType: RepresentableGRPHType {
    var typeid: UInt8 {
        131
    }
    
    var genericsVector: [RepresentableGRPHType] {
        ([self.returnType] + self.parameterTypes).map({ $0 as! RepresentableGRPHType })
    }
    
    var representationMode: RepresentationMode {
        .impureValue
    }
    
    var vwt: ValueWitnessTable {
        .funcref
    }
    
    func asLLVM() throws -> IRType {
        GRPHTypes.funcref
    }
}

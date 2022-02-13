//
//  GRPHType.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension GRPHType {
    func findLLVMType(forReturnType: Bool = false) throws -> IRType {
        if forReturnType, self.isTheVoid {
            return VoidType()
        }
        if let ty = self as? SimpleType {
            // TODO handle other types
            return ty.asLLVM()
        } else {
            throw GRPHCompileError(type: .unsupported, message: "Type \(self) not found")
        }
    }
}

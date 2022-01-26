//
//  ExpressionInstruction.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 26/01/2022.
//  Copyright © 2022 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension ExpressionInstruction: RepresentableInstruction {
    func build(generator: IRGenerator) throws {
        if let expression = expression as? RepresentableExpression {
            _ = try expression.build(generator: generator)
        } else {
            throw GRPHCompileError(type: .unsupported, message: "ExpressionInstruction of type \(type(of: expression)) is not supported in IRGen mode")
        }
    }
}

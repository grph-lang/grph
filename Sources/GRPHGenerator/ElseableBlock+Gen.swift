//
//  ElseableBlock.swift
//  GRPH Generator
// 
//  Created by Emil Pedersen on 03/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues

extension ElseableBlock {
    func appendElse(_ branch: ElseLikeBlock) throws {
        if let elseBranch = self.elseBranch {
            if let elseBranch = elseBranch as? ElseableBlock {
                return try elseBranch.appendElse(branch)
            } else {
                throw GRPHCompileError(type: .parse, message: "#else may not be attached to another #else")
            }
        } else {
            self.elseBranch = branch
        }
    }
}

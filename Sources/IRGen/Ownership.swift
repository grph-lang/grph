//
//  Ownership.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 23/04/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

enum Ownership {
    /// The parent of the Expression owns this value, and must destroy it when finished
    case owned
    /// The parent of the Expression does not own the value.
    /// It may use its content, but must copy it if it wants to store it, or guarantee its existence
    case borrowed
    /// This expression never needs reference counting, its type's representationMode is pureValue or it is immortal
    case trivial
}

//
//  ElseableBlock.swift
//  GRPH Values
// 
//  Created by Emil Pedersen on 02/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

// If, ElseIf, While, ForEach
public protocol ElseableBlock: BlockInstruction {
    var elseBranch: ElseLikeBlock? { get set }
}

// ElseIf and Else
public protocol ElseLikeBlock: BlockInstruction {
    
}

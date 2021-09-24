//
//  Notice+LSP.swift
//  GRPH LSP
// 
//  Created by Emil Pedersen on 24/09/2021.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHLexer
import LanguageServerProtocol

extension Notice {
    func toLSP(doc: DocumentURI) -> Diagnostic {
        let rel: [DiagnosticRelatedInformation]
        if let hint = hint {
            rel = [DiagnosticRelatedInformation(location: Location(uri: doc, range: token.positionRange), message: hint)]
        } else {
            rel = []
        }
        return Diagnostic(
            range: token.positionRange,
            severity: .init(rawValue: severity.rawValue),
            source: source.rawValue,
            message: message,
            relatedInformation: rel
        )
    }
}

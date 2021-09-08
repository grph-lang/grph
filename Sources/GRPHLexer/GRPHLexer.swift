//
//  GRPHLexer.swift
//  GRPHLexer
//
//  Created by Emil Pedersen on 27/08/2021.
//

import Foundation

public class GRPHLexer {
    
    // State for the current line
    var lineNumber = 0
    var line = ""
    var hierarchy: [Token] = []
    
    // lexing options
    var alternativeBracketSet = false
    var indentation = "\t"
    
    public private(set) var diagnostics: [Notice] = []
    
    public init() {
        
    }
    
    /// Fully lexes (base lexing + token detection) a full source file.
    /// - Parameter content: The source to parse
    /// - Returns: An array of line tokens. Each token in the array is a fully lexed `.line` token
    public func parseDocument(content: String) -> [Token] {
        let lines = content.components(separatedBy: "\n")
        var tokens: [Token] = []
        tokens.reserveCapacity(lines.count)
        for lineNumber in 0..<lines.count {
            var line = parseLine(lineNumber: lineNumber, content: lines[lineNumber])
            tokenDetectLine(line: &line)
            tokens.append(line)
        }
        return tokens
    }
    
    // MARK: - Phase 1 - Base lexing
    
    /// Parses a line with base lexing only
    /// - Parameters:
    ///   - lineNumber: the line number of the given line
    ///   - content: the line to parse
    /// - Returns: A token of type `.line`, containing all the tokens in the line as its children
    public func parseLine(lineNumber: Int, content: String) -> Token {
        self.lineNumber = lineNumber
        self.line = content
        hierarchy = [Token(lineNumber: lineNumber, lineOffset: content.startIndex, literal: content[...], tokenType: .line), Token(lineNumber: lineNumber, lineOffset: content.startIndex, literal: "", tokenType: .indent)]
        var unindented = line[...]
        var level = 0
        while unindented.hasPrefix(indentation) {
            unindented = unindented.dropFirst(indentation.count)
            level += 1
        }
        hierarchy.head.data = .integer(level)
        for index in unindented.indices {
            let char = content[index]
            let currentTokenType = hierarchy.head.tokenType
            switch satisfies(tokenType: currentTokenType, char: char) {
            case .satisfies:
                continue
            case .newToken: // close current, probably open new
                var last = hierarchy.popLast()!
                last.literal = content[last.lineOffset..<index] // notice ..<, not including current
                hierarchy.head.children.append(last)
                if !maybeHandleClosingBrackets(char: char, index: index) {
                    let resolved = newTokenType(previous: currentTokenType, char: char)
                    hierarchy.append(Token(lineNumber: lineNumber, lineOffset: index, literal: "", tokenType: resolved))
                    if resolved == .squareBrackets || resolved == .parentheses || resolved == .curlyBraces {
                        hierarchy.append(Token(lineNumber: lineNumber, lineOffset: content.index(after: index), literal: "", tokenType: .whitespace))
                    }
                }
            case .satisfiesAndTerminates:
                popHierarchyClosing(index: index)
                hierarchy.append(Token(lineNumber: lineNumber, lineOffset: content.index(after: index), literal: "", tokenType: .whitespace))
            case .satisfiesAndCloses:
                popHierarchyClosing(index: index)
            case .satisfiesSubToken(let subtokenType):
                hierarchy.append(Token(lineNumber: lineNumber, lineOffset: index, literal: "", tokenType: subtokenType))
            case .changeCurrentType(let tokenType):
                hierarchy.head.tokenType = tokenType
            }
        }
        while hierarchy.count > 1 {
            var last = hierarchy.popLast()!
            last.literal = content[last.lineOffset...]
            switch last.tokenType {
            case .stringLiteral, .fileLiteral:
                diagnostics.append(Notice(token: last, severity: .error, source: .lexer, message: "Unclosed string literal"))
            case .stringLiteralEscapeSequence:
                diagnostics.append(Notice(token: last, severity: .error, source: .lexer, message: "Empty escape sequence"))
            case .squareBrackets:
                diagnostics.append(Notice(token: last, severity: .error, source: .lexer, message: "Expected a closing bracket ']'"))
            case .parentheses:
                diagnostics.append(Notice(token: last, severity: .error, source: .lexer, message: "Expected a closing parenthesis ')'"))
            case .curlyBraces:
                diagnostics.append(Notice(token: last, severity: .error, source: .lexer, message: "Expected a closing brace '}'"))
            default:
                break // ok
            }
            hierarchy.head.children.append(last)
        }
        return hierarchy[0]
    }
    
    /// Reads a token, and if it is a closing bracket, closes it in the hierarchy, or errors if it is unmatched
    /// - Parameters:
    ///   - char: The character to evaluate
    ///   - index: The index in the line at which the character was found
    /// - Returns: True if a valid closing bracket was found, false otherwise
    func maybeHandleClosingBrackets(char: Character, index: String.Index) -> Bool {
        let token = { [self] in Token(lineNumber: lineNumber, lineOffset: index, literal: line[index..<line.index(after: index)], tokenType: .operator) }
        switch char {
        case "]":
            if hierarchy.head.tokenType == .squareBrackets {
                popHierarchyClosing(index: index)
            } else {
                switch hierarchy.head.tokenType {
                case .parentheses:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Expected a closing parenthesis ')'"))
                case .curlyBraces:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Expected a closing brace '}'"))
                default:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Unexpected closing bracket, no opening bracket found"))
                }
                return false
            }
        case ")":
            if hierarchy.head.tokenType == .parentheses {
                popHierarchyClosing(index: index)
            } else {
                switch hierarchy.head.tokenType {
                case .squareBrackets:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Expected a closing bracket ']'"))
                case .curlyBraces:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Expected a closing brace '}'"))
                default:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Unexpected closing parentheses, no opening parentheses found"))
                }
                return false
            }
        case "}":
            if hierarchy.head.tokenType == .curlyBraces {
                popHierarchyClosing(index: index)
            } else {
                switch hierarchy.head.tokenType {
                case .squareBrackets:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Expected a closing bracket ']'"))
                case .parentheses:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Expected a closing parenthesis ')'"))
                default:
                    diagnostics.append(Notice(token: token(), severity: .error, source: .lexer, message: "Unexpected closing brace, no opening brace found"))
                }
                return false
            }
        default:
            return false
        }
        hierarchy.append(Token(lineNumber: lineNumber, lineOffset: line.index(after: index), literal: "", tokenType: .whitespace))
        return true
    }
    
    /// Closes a token in the hierarchy. This finished token will include the given index.
    /// - Parameter index: the index of the last character to include in the token
    func popHierarchyClosing(index: String.Index) {
        var last = hierarchy.popLast()!
        last.literal = line[last.lineOffset...index]
        hierarchy.head.children.append(last)
    }
    
    /// Answers the question: when the previous character was of type `tokenType`, is the next too?
    /// - Parameters:
    ///   - tokenType: the current token type
    ///   - char: the current character to consider
    /// - Returns: what to do with that character (include in previous token? new token? change token type? include and close token?)
    func satisfies(tokenType: TokenType, char: Character) -> SatisfiesResult {
        switch tokenType {
        case .whitespace:
            return char.isWhitespace ? .satisfies : .newToken
        case .indent:
            return .newToken // indentation is fully parsed before this phase. just a start of line, always a new token
        case .slashOperator:
            if char == "/" {
                return .changeCurrentType(.comment)
            }
            return .newToken
        case .comment:
            if char == "/" {
                return .changeCurrentType(.docComment)
            }
            return .satisfiesSubToken(.commentContent)
        case .docComment:
            return .satisfiesSubToken(.commentContent)
        case .commentContent:
            return .satisfies
        case .identifier, .label:
            return char.isASCII && (char.isLetter || char.isNumber || char == "_") ? .satisfies : .newToken
        case .commandName:
            return char.isASCII && char.isLetter ? .satisfies : .newToken
        case .numberLiteral:
            if char == "f" || char == "F" {
                return .satisfiesAndTerminates
            }
            if char == "º" || char == "°" {
                return .changeCurrentType(.rotationLiteral)
            }
            if char == "," {
                return .changeCurrentType(.posLiteral)
            }
            return char.isASCII && (char.isNumber || char == ".") ? .satisfies : .newToken
        case .rotationLiteral:
            return .newToken
        case .posLiteral:
            return char.isASCII && (char.isNumber || char == "." || char == "-") ? .satisfies : .newToken
        case .stringLiteral:
            if char == "\\" {
                return .satisfiesSubToken(.stringLiteralEscapeSequence)
            } else if char == "\"" {
                return .satisfiesAndTerminates
            } else {
                return .satisfies
            }
        case .fileLiteral:
            if char == "\\" {
                return .satisfiesSubToken(.stringLiteralEscapeSequence)
            } else if char == "\'" {
                return .satisfiesAndTerminates
            } else {
                return .satisfies
            }
        case .stringLiteralEscapeSequence:
            return .satisfiesAndCloses
        case .lambdaHatOperator, .labelPrefixOperator, .comma, .dot:
            return .newToken
        case .assignmentOperator:
            if char == "=" {
                return .changeCurrentType(.operator) // ==
            } else {
                return .newToken
            }
        case .operator:
            switch char {
            // these are either syntax errors, or valid as second character of a binary operator
            // they don't conflict with binary+unary (ex 3+-7 has two operator tokens)
            case "<", ">", "&", "|", "=":
                return .satisfies
            default:
                return .newToken
            }
        case .methodCallOperator:
            if char == ":" {
                return .changeCurrentType(.labelPrefixOperator)
            } else {
                return .newToken
            }
        case .squareBrackets, .parentheses, .curlyBraces:
            preconditionFailure("token type should never be current")
        case .line, .variable, .function, .method, .type, .keyword, .enumCase, .booleanLiteral, .nullLiteral, .assignmentCompound, .varargs:
            preconditionFailure("token type is never yielded at this point")
        case .unresolved:
            return .newToken
        }
    }
    
    /// When a new token is encountered. Most of the time, previous is ignoreable. Only used for identifying labels.
    /// - Parameters:
    ///   - previous: the token type of the previous token
    ///   - char: the current character to consider
    /// - Returns: the token type of this new token
    func newTokenType(previous: TokenType, char: Character) -> TokenType {
        if char.isWhitespace {
            return .whitespace
        }
        if char.isASCII {
            if char.isNumber {
                return .numberLiteral
            } else if char.isLetter || char == "_" || char == "$" {
                if previous == .labelPrefixOperator {
                    return .label
                } else {
                    return .identifier
                }
            }
        }
        switch char {
        case "/":
            return .slashOperator
        case ".":
            return .dot
        case "^":
            return .lambdaHatOperator
        case ":":
            return .methodCallOperator
        case ",":
            return .comma
        case "=":
            return .assignmentOperator
        case "#":
            return .commandName
        case "\"":
            return .stringLiteral
        case "\'":
            return .fileLiteral
        case "+", "-", "*", "%", "<", ">", "≥", "≤", "~", "!", "&", "|", "≠", "?":
            return .operator
        case "[": // these are handled specially
            return .squareBrackets
        case "(":
            return .parentheses
        case "{":
            return .curlyBraces
        case "]", ")", "}":
            return .whitespace // only happens for unmatched braces, we decide to ignore them (error already triggered)
        default:
            return .unresolved
        }
    }
    
    // MARK: - Phase 2 - Token detection
    
    /// Performs the token detection phase for this line
    /// This will execute #compiler directives, change some identifiers to their correct token type (literals, keywords), and parse & store data in literals.
    /// It will also apply the alternative bracket set if needed, and squash some tokens together.
    /// - Parameter line: the line to update
    public func tokenDetectLine(line: inout Token) {
        performTokenDetection(token: &line)
        
        let stripped = line.strippedChildren
        // [.indent, .commandName, .identifier, value(s)...]
        if stripped.count >= 4,
           stripped[1].literal == "#compiler" {
            // handle what we can
            switch stripped[2].literal {
            case "indent":
                let multiplier: Int?
                let specifier: Token
                if stripped.count == 6 {
                    // n*name
                    guard stripped[4].tokenType == .operator && stripped[4].literal == "*" else {
                        diagnostics.append(Notice(token: stripped[4], severity: .error, source: .tokenDetector, message: "Expected '*' in syntax '#compiler indent n*string'"))
                        break
                    }
                    guard stripped[3].tokenType == .numberLiteral,
                          let int = Int(stripped[3].literal) else {
                          diagnostics.append(Notice(token: stripped[3], severity: .error, source: .tokenDetector, message: "Expected integer multiplier in syntax '#compiler indent n*string'"))
                          break
                    }
                    multiplier = int
                    specifier = stripped[5]
                } else if stripped.count == 4 {
                    multiplier = nil
                    specifier = stripped[3]
                } else {
                    diagnostics.append(Notice(token: stripped[4], severity: .error, source: .tokenDetector, message: "Unexpected token in syntax '#compiler indent string'"))
                    break
                }
                if specifier.tokenType == .stringLiteral {
                    if case .string(let data) = specifier.data {
                        indentation = String(repeating: data, count: multiplier ?? 1)
                    } else {
                        diagnostics.append(Notice(token: specifier, severity: .error, source: .tokenDetector, message: "Invalid string literal given"))
                    }
                } else {
                    switch specifier.literal {
                    case "spaces", "space":
                        indentation = String(repeating: " ", count: multiplier ?? 4)
                    case "tabs", "tab", "tabulation", "tabulations":
                        indentation = String(repeating: "\t", count: multiplier ?? 1)
                    case "dash", "dashes", "-":
                        indentation = String(repeating: "-", count: multiplier ?? 4)
                    case "underscores", "underscore", "_":
                        indentation = String(repeating: "_", count: multiplier ?? 4)
                    case "tildes", "tilde", "~":
                        indentation = String(repeating: "~", count: multiplier ?? 4)
                    case "uwus":
                        indentation = String(repeating: "uwu ", count: multiplier ?? 1)
                    default:
                        diagnostics.append(Notice(token: specifier, severity: .error, source: .tokenDetector, message: "Unknown indent '\(specifier.literal)'"))
                    }
                }
            case "altBrackets", "altBracketSet", "alternativeBracketSet":
                guard stripped[3].tokenType == .booleanLiteral else {
                    diagnostics.append(Notice(token: stripped[3], severity: .error, source: .tokenDetector, message: "Expected value to be a boolean literal"))
                    break
                }
                alternativeBracketSet = stripped[3].literal == "true"
            case "strict", "strictUnbox", "strictUnboxing", "noAutoUnbox", "strictBoxing", "noAutobox", "noAutoBox", "strictest", "ignore":
                break // this is the job of the generator
            default:
                diagnostics.append(Notice(token: stripped[2], severity: .warning, source: .tokenDetector, message: "Unknown compiler key '\(stripped[2].literal)'"))
            }
        }
    }
    
    /// Recursively performs token detection on a token
    /// - Parameter token: the token to update. it's type and stored data may change, and this will happen recursively with all its children
    func performTokenDetection(token: inout Token) {
        switch token.tokenType {
        case .whitespace, .indent, .comment, .docComment, .commentContent, .label, .commandName, .stringLiteralEscapeSequence, .lambdaHatOperator, .labelPrefixOperator, .methodCallOperator, .comma, .dot, .slashOperator, .line, .assignmentOperator, .keyword, .varargs:
            break // nothing to do
        case .identifier:
            switch token.literal {
            case "true", "false":
                token.tokenType = .booleanLiteral
            case "null":
                token.tokenType = .nullLiteral
            case "is", "global", "static", "final", "auto": // `as` is already handled
                token.tokenType = .keyword
            case "right", "downRight", "down", "downLeft", "left", "upLeft", "up", "upRight", "elongated", "cut", "rounded":
                token.tokenType = .enumCase
                // TODO type
            default:
                break // another identifier: .variable, .function, .method, .type
            }
        case .operator: // detect compounds s.t. `+=`
            let literal = token.literal
            if literal == "==" || literal == "!=" || literal == ">=" || literal == "<=" {
                break
            } else if literal.hasSuffix("=") {
                token.tokenType = .assignmentCompound
                let op = literal.dropLast()
                token.children.append(Token(lineNumber: token.lineNumber, lineOffset: token.lineOffset, literal: op, tokenType: .operator))
                token.children.append(Token(lineNumber: token.lineNumber, lineOffset: op.endIndex, literal: literal[op.endIndex..<literal.endIndex], tokenType: .assignmentOperator))
            }
        case .numberLiteral:
            if token.literal.hasSuffix("f") || token.literal.hasSuffix("F") {
                guard let parsed = Float(token.literal.dropLast()) else {
                    diagnostics.append(Notice(token: token, severity: .error, source: .tokenDetector, message: "Invalid float literal"))
                    break
                }
                token.data = .float(parsed)
            } else if token.literal.contains(".") {
                guard let parsed = Float(token.literal) else {
                    diagnostics.append(Notice(token: token, severity: .error, source: .tokenDetector, message: "Invalid float literal"))
                    break
                }
                token.data = .float(parsed)
            } else {
                guard let parsed = Int(token.literal) else {
                    diagnostics.append(Notice(token: token, severity: .error, source: .tokenDetector, message: "Invalid integer literal"))
                    break
                }
                token.data = .integer(parsed)
            }
        case .rotationLiteral:
            guard let parsed = Int(token.literal.dropLast()) else {
                diagnostics.append(Notice(token: token, severity: .error, source: .tokenDetector, message: "Invalid rotation literal: expected an integer"))
                break
            }
            token.data = .integer(parsed)
        case .posLiteral:
            guard let comma = token.literal.firstIndex(of: ",") else {
                diagnostics.append(Notice(token: token, severity: .error, source: .tokenDetector, message: "Invalid pos literal"))
                break
            }
            // those numberLiteral will be parsed recursively
            token.children.append(Token(lineNumber: token.lineNumber, lineOffset: token.lineOffset, literal: token.literal[token.lineOffset..<comma], tokenType: .numberLiteral))
            let afterComma = token.literal.index(after: comma)
            token.children.append(Token(lineNumber: token.lineNumber, lineOffset: comma, literal: token.literal[comma..<afterComma], tokenType: .comma))
            token.children.append(Token(lineNumber: token.lineNumber, lineOffset: afterComma, literal: token.literal[afterComma..<token.literal.endIndex], tokenType: .numberLiteral))
        case .stringLiteral, .fileLiteral:
            var str = ""
            var i = token.literal.index(after: token.literal.startIndex)
            for escape in token.children {
                str += token.literal[i..<escape.literal.startIndex]
                i = escape.literal.endIndex
                var char: Character
                switch escape.literal.last {
                case "n": char = "\n"
                case "t": char = "\t"
                case "r": char = "\r"
                case "0": char = "\0"
                case "b": char = "\u{8}"
                case "f": char = "\u{c}"
                case "\"", "'", "\\":
                    char = escape.literal.last!
                default:
                    diagnostics.append(Notice(token: escape, severity: .warning, source: .tokenDetector, message: "Invalid escape sequence in string literal"))
                    continue
                }
                str.append(char)
            }
            str += token.literal[i..<token.literal.index(before: token.literal.endIndex)]
            token.data = .string(str)
        case .squareBrackets:
            if alternativeBracketSet {
                token.tokenType = .curlyBraces
            }
        case .parentheses:
            if alternativeBracketSet {
                token.tokenType = .squareBrackets
            }
        case .curlyBraces:
            if alternativeBracketSet {
                token.tokenType = .parentheses
            }
        case .unresolved:
            diagnostics.append(Notice(token: token, severity: .error, source: .lexer, message: "Unresolved token '\(token.literal)' in source"))
        case .variable, .function, .method, .type, .enumCase, .booleanLiteral, .nullLiteral, .assignmentCompound:
            assertionFailure("tried to validate an already validated token")
        }
        
        performSquashing(token: &token)
        performUnsquashing(token: &token)
        
        // recurse
        token.children = token.children.map {
            var copy = $0
            performTokenDetection(token: &copy)
            return copy
        }
    }
    
    func performSquashing(token: inout Token) {
        var i = 0
        var squashingResult: [Token] = []
        while i < token.children.count {
            if token.children[i].literal == "as" {
                let index = i
                i += 1
                if token.children.count > i && token.children[i].tokenType == .operator && token.children[i].literal == "?" {
                    i += 1
                }
                if token.children.count > i && token.children[i].tokenType == .operator && token.children[i].literal == "!" {
                    i += 1
                }
                squashingResult.append(Token(squash: token.children[index..<i], type: .keyword))
            } else if i + 1 < token.children.count,
                      token.children[i].literal == "-",
                      case let next = token.children[i + 1].tokenType,
                      next == .numberLiteral || next == .posLiteral || next == .rotationLiteral {
                // `-` signs are part of literals
                squashingResult.append(Token(squash: token.children[i...(i+1)], type: next))
                i += 2
            } else if i + 2 < token.children.count,
                      token.children[i].tokenType == .dot,
                      token.children[i + 1].tokenType == .dot,
                      token.children[i + 2].tokenType == .dot {
                squashingResult.append(Token(squash: token.children[i...(i+2)], type: .varargs))
                i += 3
            } else {
                squashingResult.append(token.children[i])
                i += 1
            }
        }
        token.children = squashingResult
    }
    
    func performUnsquashing(token: inout Token) {
        var i = 0
        var squashingResult: [Token] = []
        while i < token.children.count {
            let current = token.children[i]
            if current.tokenType == .posLiteral,
               current.literal.hasSuffix(",") {
                // invalid posLiteral, fix it
                squashingResult.append(Token(lineNumber: token.lineNumber, lineOffset: current.lineOffset, literal: current.literal.dropLast(), tokenType: .numberLiteral))
                let commaIndex = current.literal.index(before: current.literal.endIndex)
                squashingResult.append(Token(lineNumber: token.lineNumber, lineOffset: commaIndex, literal: current.literal[commaIndex..<current.literal.endIndex], tokenType: .comma))
                i += 1
            } else {
                squashingResult.append(token.children[i])
                i += 1
            }
        }
        token.children = squashingResult
    }
}

extension GRPHLexer {
    enum SatisfiesResult {
        /// The character is a valid part of this token type
        case satisfies
        /// The character isn't part of the current token, create a new
        case newToken
        /// The character is a part of this token, but the next character to parse will not. forces an empty whitespace token.
        case satisfiesAndTerminates
        /// The character is a part of this token, but the next character to parse will not, by closing a children context (next token will be part of the parent)
        case satisfiesAndCloses
        /// The character opens a subtoken with the given type
        case satisfiesSubToken(TokenType)
        /// The character is still a part of the same token, but the type that was given is wrong, change it.
        case changeCurrentType(TokenType)
    }
}

extension Array {
    /// Same as `last`, but with a setter, and it crashes if empty
    var head: Element {
        get {
            self[count - 1]
        }
        set {
            self[count - 1] = newValue
        }
    }
}

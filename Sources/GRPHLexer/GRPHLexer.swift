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
    
    var diagnostics: [Notice] = []
    
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
    
    public func parseLine(lineNumber: Int, content: String) -> Token {
        self.lineNumber = lineNumber
        self.line = content
        hierarchy = [Token(lineNumber: lineNumber, lineOffset: content.startIndex, literal: content[...], tokenType: .line, children: []), Token(lineNumber: lineNumber, lineOffset: content.startIndex, literal: "", tokenType: .indent, children: [])]
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
                    hierarchy.append(Token(lineNumber: lineNumber, lineOffset: index, literal: "", tokenType: resolved, children: []))
                    if resolved == .squareBrackets || resolved == .parentheses || resolved == .curlyBraces {
                        hierarchy.append(Token(lineNumber: lineNumber, lineOffset: content.index(after: index), literal: "", tokenType: .ignoreableWhiteSpace, children: []))
                    }
                }
            case .satisfiesAndTerminates:
                popHierarchyClosing(index: index)
                hierarchy.append(Token(lineNumber: lineNumber, lineOffset: content.index(after: index), literal: "", tokenType: .ignoreableWhiteSpace, children: []))
            case .satisfiesAndCloses:
                popHierarchyClosing(index: index)
            case .satisfiesSubToken(let subtokenType):
                hierarchy.append(Token(lineNumber: lineNumber, lineOffset: index, literal: "", tokenType: subtokenType, children: []))
            case .changeCurrentType(let tokenType):
                hierarchy.head.tokenType = tokenType
            }
        }
        while hierarchy.count > 1 {
            var last = hierarchy.popLast()!
            last.literal = content[last.lineOffset...]
            hierarchy.head.children.append(last)
        }
        return hierarchy[0]
    }
    
    func maybeHandleClosingBrackets(char: Character, index: String.Index) -> Bool {
        switch char {
        case "]":
            if hierarchy.head.tokenType == .squareBrackets {
                popHierarchyClosing(index: index)
            } else {
                print("Error: brackets incorrectly closed")
            }
        case ")":
            if hierarchy.head.tokenType == .parentheses {
                popHierarchyClosing(index: index)
            } else {
                print("Error: parentheses incorrectly closed")
            }
        case "}":
            if hierarchy.head.tokenType == .curlyBraces {
                popHierarchyClosing(index: index)
            } else {
                print("Error: braces incorrectly closed")
            }
        default:
            return false
        }
        hierarchy.append(Token(lineNumber: lineNumber, lineOffset: line.index(after: index), literal: "", tokenType: .ignoreableWhiteSpace, children: []))
        return true
    }
    
    func popHierarchyClosing(index: String.Index) {
        var last = hierarchy.popLast()!
        last.literal = line[last.lineOffset...index]
        hierarchy.head.children.append(last)
    }
    
    // when the previous character was of type `tokenType`, is the next too?
    func satisfies(tokenType: TokenType, char: Character) -> SatisfiesResult {
        switch tokenType {
        case .ignoreableWhiteSpace:
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
            if char == "f" || char == "F" || char == "º" || char == "°" {
                return .satisfiesAndTerminates
            }
            if char == "," {
                return .changeCurrentType(.posLiteral)
            }
            return char.isASCII && (char.isNumber || char == ".") ? .satisfies : .newToken
        case .posLiteral:
            return char.isASCII && (char.isNumber || char == ".") ? .satisfies : .newToken
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
        case .line, .variable, .function, .method, .type, .keyword, .enumCase, .booleanLiteral, .nullLiteral, .assignmentCompound, .namespaceSeparator:
            preconditionFailure("token type is never yielded at this point")
        case .unresolved:
            return .newToken
        }
    }
    
    /// When a new token is encountered. Most of the time, previous is ignoreable. Only used for identifying labels.
    func newTokenType(previous: TokenType, char: Character) -> TokenType {
        if char.isWhitespace {
            return .ignoreableWhiteSpace
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
        default:
            return .unresolved
        }
    }
    
    // MARK: - Phase 2 - Token detection
    
    func tokenDetectLine(line: inout Token) {
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
                    print("TODO")
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
    
    func performTokenDetection(token: inout Token) {
        switch token.tokenType {
        case .ignoreableWhiteSpace, .indent, .comment, .docComment, .commentContent, .label, .commandName, .posLiteral, .numberLiteral, .stringLiteral, .fileLiteral, .stringLiteralEscapeSequence, .lambdaHatOperator, .labelPrefixOperator, .methodCallOperator, .comma, .dot, .slashOperator, .line, .assignmentOperator, .keyword:
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
            if literal == "==" || literal == "!=" {
                break
            } else if literal.hasSuffix("=") {
                token.tokenType = .assignmentCompound
                let op = literal.dropLast()
                token.children.append(Token(lineNumber: token.lineNumber, lineOffset: token.lineOffset, literal: op, tokenType: .operator, children: []))
                token.children.append(Token(lineNumber: token.lineNumber, lineOffset: op.endIndex, literal: literal[op.endIndex..<literal.endIndex], tokenType: .assignmentOperator, children: []))
            }
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
        case .variable, .function, .method, .type, .enumCase, .booleanLiteral, .nullLiteral, .assignmentCompound, .namespaceSeparator:
            assertionFailure("tried to validate an already validated token")
        }
        // TODO squash the namespace identifiers
        
        // Squashing tokens
        var i = 0
        var squashingResult: [Token] = []
        while i < token.children.count {
            if token.children[i].literal == "as" {
                let index = i
                i += 1
                if token.children[i].tokenType == .operator && token.children[i].literal == "?" {
                    i += 1
                }
                if token.children[i].tokenType == .operator && token.children[i].literal == "!" {
                    i += 1
                }
                let squash = token.children[index..<i]
                let result = Token(lineNumber: token.lineNumber, lineOffset: squash.first!.lineOffset, literal: token.literal[squash.first!.lineOffset..<squash.last!.literal.endIndex], tokenType: .keyword, children: [])
                squashingResult.append(result)
            } else {
                squashingResult.append(token.children[i])
                i += 1
            }
        }
        token.children = squashingResult
        
        // recurse
        token.children = token.children.map {
            var copy = $0
            performTokenDetection(token: &copy)
            return copy
        }
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

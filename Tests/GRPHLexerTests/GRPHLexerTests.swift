import XCTest
@testable import GRPHLexer

final class GRPHLexerTests: XCTestCase {
    let lexer = GRPHLexer()
    var lineNumber = 0
    
    func testExample() throws {
        parsing(line: "#requires GRPH 1.1 // this is a comment", assert: [.indent, .commandName, .identifier, .numberLiteral, .comment])
        parsing(line: "::LABEL /// great", assert: [.indent, .labelPrefixOperator, .label, .docComment])
        parsing(line: "pos p = 4,7", assert: [.indent, .identifier, .identifier, .assignmentOperator, .posLiteral])
        parsing(line: #"string s = "something\n\"great\"""#, assert: [.indent, .identifier, .identifier, .assignmentOperator, .stringLiteral])
        parsing(line: #"log["hey" "you"] // hey"#, assert: [.indent, .identifier, .squareBrackets, .comment])
        parsing(line: #"Background(pos(640 480) WHITE)"#, assert: [.indent, .identifier, .parentheses])
        parsing(line: "shape? s = null", assert: [.indent, .identifier, .operator, .identifier, .assignmentOperator, .nullLiteral])
        parsing(line: "p += 1,1", assert: [.indent, .identifier, .assignmentCompound, .posLiteral])
        parsing(line: "p == 5,8", assert: [.indent, .identifier, .operator, .posLiteral])
        parsing(line: "i+-7", assert: [.indent, .identifier, .operator, .operator, .numberLiteral])
        parsing(line: "~i >> 2", assert: [.indent, .operator, .identifier, .operator, .numberLiteral])
        parsing(line: "1 as float as? integer as! int?", assert: [.indent, .numberLiteral, .keyword, .identifier, .keyword, .identifier, .keyword, .identifier, .operator])
        parsing(line: "#compiler altBrackets true", assert: [.indent, .commandName, .identifier, .booleanLiteral])
        parsing(line: "log: pos{10 10} createPos(10 10)", assert: [.indent, .identifier, .methodCallOperator, .identifier, .parentheses, .identifier, .squareBrackets])
        
        expectDiagnostic(line: "#compiler ayo true", notice: "Unknown compiler key 'ayo'")
        expectDiagnostic(line: "#compiler altBrackets 1", notice: "Expected value to be a boolean literal")
        expectDiagnostic(line: #"@echo "hey";"#, notice: "Unresolved token ';' in source")
        print(lexer.diagnostics.map { $0.represent() }.joined(separator: "\n"))
    }
    
    func parsing(line: String, assert tokenTypes: [TokenType]) {
        var result = lexer.parseLine(lineNumber: lineNumber, content: line)
        lexer.tokenDetectLine(line: &result)
        result.stripWhitespaces()
        print(result.represent())
        XCTAssertEqual(result.children.map({$0.tokenType }), tokenTypes)
        lineNumber += 1
    }
    
    func expectDiagnostic(line: String, notice: String) {
        var result = lexer.parseLine(lineNumber: lineNumber, content: line)
        lexer.tokenDetectLine(line: &result)
        result.stripWhitespaces()
        print(result.represent())
        XCTAssertEqual(lexer.diagnostics.last?.message, notice)
        lineNumber += 1
    }
}

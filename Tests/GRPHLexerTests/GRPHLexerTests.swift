import XCTest
@testable import GRPHLexer

final class GRPHLexerTests: XCTestCase {
    let lexer = GRPHLexer()
    
    func testExample() throws {
        parsing(line: "#requires GRPH 1.1 // this is a comment", assert: [.indent, .commandName, .identifier, .numberLiteral, .comment])
        parsing(line: "::LABEL /// great", assert: [.indent, .labelPrefixOperator, .label, .docComment])
        parsing(line: "pos p = 4,7", assert: [.indent, .identifier, .identifier, .assignmentOperator, .posLiteral])
        parsing(line: #"string s = "something\n\"great\"""#, assert: [.indent, .identifier, .identifier, .assignmentOperator, .stringLiteral])
        parsing(line: #"log["hey" "you"] // hey"#, assert: [.indent, .identifier, .squareBrackets, .comment])
        parsing(line: #"Background(pos(640 480) WHITE)"#, assert: [.indent, .identifier, .parentheses])
        parsing(line: "shape? s = null", assert: [.indent, .identifier, .operator, .identifier, .assignmentOperator, .nullLiteral])
    }
    
    func parsing(line: String, assert tokenTypes: [TokenType]) {
        var result = lexer.parseLine(lineNumber: 0, content: line)
        lexer.performTokenDetection(token: &result)
        result.stripWhitespaces()
        print(result.represent())
        XCTAssertEqual(result.children.map({$0.tokenType }), tokenTypes)
    }
}

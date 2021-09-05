import XCTest
@testable import GRPHLexer

final class GRPHLexerTests: XCTestCase {
    var lexer = GRPHLexer()
    var lineNumber = 0
    
    override func setUp() {
        lexer = GRPHLexer()
        lineNumber = 0
    }
    
    func testLexing() throws {
        parsing(line: "#requires GRPH 1.1 // this is a comment", assert: [.indent, .commandName, .identifier, .numberLiteral, .comment])
        parsing(line: "::LABEL /// great", assert: [.indent, .labelPrefixOperator, .label, .docComment])
        parsing(line: "pos p = 4,7", assert: [.indent, .identifier, .identifier, .assignmentOperator, .posLiteral])
        parsing(line: #"string s = "something\n\"great\"""#, assert: [.indent, .identifier, .identifier, .assignmentOperator, .stringLiteral])
        parsing(line: #"log["hey" "you"] // hey"#, assert: [.indent, .identifier, .squareBrackets, .comment])
        parsing(line: #"Background(pos(640 480) WHITE)"#, assert: [.indent, .identifier, .parentheses])
        parsing(line: "shape? s = null", assert: [.indent, .identifier, .operator, .identifier, .assignmentOperator, .nullLiteral])
        parsing(line: "p += -1,1", assert: [.indent, .identifier, .assignmentCompound, .posLiteral])
        parsing(line: "p == -5,-8", assert: [.indent, .identifier, .operator, .posLiteral])
        parsing(line: "i+-7", assert: [.indent, .identifier, .operator, .numberLiteral])
        parsing(line: "~i >> 2", assert: [.indent, .operator, .identifier, .operator, .numberLiteral])
        parsing(line: "1 as float as? integer as! int?", assert: [.indent, .numberLiteral, .keyword, .identifier, .keyword, .identifier, .keyword, .identifier, .operator])
        parsing(line: "18 as", assert: [.indent, .numberLiteral, .keyword])
        parsing(line: "a{i-}=", assert: [.indent, .identifier, .curlyBraces, .assignmentOperator])
        
        parsing(line: "#compiler altBrackets true", assert: [.indent, .commandName, .identifier, .booleanLiteral])
        parsing(line: "\t\tlog: pos{10 10} createPos(10 10)", assert: [.indent, .identifier, .methodCallOperator, .identifier, .parentheses, .identifier, .squareBrackets])
        lexer.alternativeBracketSet = false
        
        expectDiagnostic(line: "#compiler ayo true", notice: "Unknown compiler key 'ayo'")
        expectDiagnostic(line: "#compiler altBrackets 1", notice: "Expected value to be a boolean literal")
        expectDiagnostic(line: #"@echo "hey";"#, notice: "Unresolved token ';' in source")
        expectDiagnostic(line: "createPos[1 2", notice: "Expected a closing bracket ']'")
        expectDiagnostic(line: #""flower"#, notice: "Unclosed string literal")
        expectDiagnostic(line: #"pos(1 2]"#, notice: "Expected a closing parenthesis ')'")
        expectDiagnostic(line: #"pos: 1 2}"#, notice: "Unexpected closing brace, no opening brace found")
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
    
    func testIndentation() throws {
        expectIndent(spec: "tabs", expectedResult: "\t")
        expectIndent(spec: "spaces", expectedResult: "    ")
        expectIndent(spec: "2*spaces", expectedResult: "  ")
        expectIndent(spec: "2*tabs", expectedResult: "\t\t")
        expectIndent(spec: "uwus", expectedResult: "uwu ")
        expectIndent(spec: #""pizza""#, expectedResult: "pizza")
        expectIndent(spec: #""\t""#, expectedResult: "\t")
        
        expectDiagnostic(line: "#compiler indent true", notice: "Unknown indent 'true'")
        expectDiagnostic(line: "#compiler indent space*4", notice: "Expected integer multiplier in syntax '#compiler indent n*string'")
        expectDiagnostic(line: "#compiler indent spaces/4", notice: "Expected '*' in syntax '#compiler indent n*string'")
        expectDiagnostic(line: "#compiler indent spaces*", notice: "Unexpected token in syntax '#compiler indent string'")
        print(lexer.diagnostics.map { $0.represent() }.joined(separator: "\n"))
    }
    
    func expectIndent(spec: String, expectedResult: String) {
        var result = lexer.parseLine(lineNumber: lineNumber, content: "#compiler indent \(spec)")
        lexer.tokenDetectLine(line: &result)
        
        let next = lexer.parseLine(lineNumber: lineNumber + 1, content: "\(expectedResult)\(expectedResult)auto a = 1")
        
        XCTAssertEqual(lexer.indentation, expectedResult)
        XCTAssertEqual(next.children[0].data, .integer(2))
        lineNumber += 2
    }
    
    func testLiteralParsing() throws {
        parseLiteral(string: "28", assert: .integer(28))
        parseLiteral(string: "1.01", assert: .float(1.01))
        parseLiteral(string: "42f", assert: .float(42))
        parseLiteral(string: "18.0F", assert: .float(18))
        
        parseLiteral(string: #""Hello, World!\n""#, assert: .string("Hello, World!\n"))
        parseLiteral(string: #""\they\0malicious\"string\"hehe\\""#, assert: .string("\they\0malicious\"string\"hehe\\"))
        
        expectDiagnostic(line: "1.2.3", notice: "Invalid float literal")
        expectDiagnostic(line: #""flower\z""#, notice: "Invalid escape sequence in string literal")
    }
    
    func parseLiteral(string: String, assert: Token.AssociatedData) {
        var result = lexer.parseLine(lineNumber: lineNumber, content: string)
        lexer.tokenDetectLine(line: &result)
        print(result.represent())
        XCTAssertEqual(result.children[1].data, assert)
        lineNumber += 1
    }
}


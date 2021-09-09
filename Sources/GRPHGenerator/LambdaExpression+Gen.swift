//
//  LambdaExpression.swift
//  LambdaExpression
//
//  Created by Emil Pedersen on 26/08/2021.
//

import GRPHLexer
import GRPHValues

extension LambdaExpression {
    init(context: CompilingContext, token: Token, infer: GRPHType?) throws {
        guard let type = infer as? FuncRefType else {
            // TODO could determine the type from the expression
            throw DiagnosticCompileError(notice: Notice(token: token, severity: .error, source: .generator, message: "Could not determine the type of the lambda", hint: "try inserting 'as funcref<returnType><>'"))
        }
        
        // new capturing context
        let compiler = context.generator
        let lambdaContext = LambdaCompilingContext(compiler: compiler, parent: context)
        
        for param in type.parameters {
            lambdaContext.addVariable(Variable(name: param.name, type: param.type, final: true, compileTime: true), global: false)
        }
        let prevContext = compiler.context
        compiler.context = lambdaContext
        
        let lambda: Lambda
        
        // if void
        if type.returnType.isTheVoid {
            let instruction: Instruction
            if token.children.isEmpty {
                instruction = ExpressionInstruction(lineNumber: compiler.lineNumber, expression: ConstantPropertyExpression(property: SimpleType.void.staticConstants[0], inType: SimpleType.void))
            } else if let resolved = try compiler.resolveInstruction(children: compiler.trimUselessStuff(children: token.children))?.instruction {
                instruction = resolved
            } else {
                throw DiagnosticCompileError(notice: Notice(token: token, severity: .error, source: .generator, message: "Invalid instruction in void lambda"))
            }
            try lambdaContext.accepts(instruction: instruction)
            lambda = Lambda(currentType: type, instruction: instruction)
        } else {
            let expr = try compiler.resolveExpression(tokens: token.children, infer: type.returnType)
            let exprType = try expr.getType(context: lambdaContext, infer: type.returnType)
            guard exprType.isInstance(of: type.returnType) else {
                throw GRPHCompileError(type: .typeMismatch, message: "Lambda of type '\(type)' must return value of type '\(type.returnType)', found value of type '\(exprType.string)'")
            }
            lambda = Lambda(currentType: type, instruction: ExpressionInstruction(lineNumber: compiler.lineNumber, expression: expr))
        }
        compiler.context = prevContext
        
        self.init(lambda: lambda, capturedVarNames: Array(lambdaContext.capturedVarNames))
    }
}

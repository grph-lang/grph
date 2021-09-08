//
//  BinaryExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 02/07/2020.
//

import Foundation
import GRPHValues

extension BinaryExpression: RunnableExpression {
    func eval(context: RuntimeContext) throws -> GRPHValue {
        let left = try mayUnbox(value: self.left.evalIfRunnable(context: context))
        switch op {
        case .logicalAnd:
            return left as! Bool
                ? try mayUnbox(value: self.right.evalIfRunnable(context: context)) as! Bool
                : false
        case .logicalOr:
            return left as! Bool
                ? true
                : try mayUnbox(value: self.right.evalIfRunnable(context: context)) as! Bool
        default:
            break
        }
        let right = try mayUnbox(value: self.right.evalIfRunnable(context: context))
        switch op {
        case .plus, .minus:
            if operands == .rotation {
                return run(left as! Rotation, right as! Rotation)
            }
            fallthrough
        case .greaterThan, .greaterOrEqualTo, .lessThan, .lessOrEqualTo:
            if operands == .pos {
                return run(left as! Pos, right as! Pos)
            }
            fallthrough
        case .multiply, .divide, .modulo:
            // num: int or float
            if operands == .integer {
                return run(left as! Int, right as! Int)
            } else {
                return run(left as? Float ?? Float(left as! Int), right as? Float ?? Float(right as! Int))
            }
        case .bitwiseAnd, .bitwiseOr, .bitwiseXor:
            // bool or int
            if operands == .boolean {
                switch op {
                case .bitwiseAnd:
                    return left as! Bool && right as! Bool
                case .bitwiseOr:
                    return left as! Bool || right as! Bool
                case .bitwiseXor:
                    return left as! Bool != (right as! Bool)
                default:
                    fatalError()
                }
            }
            //  numbers
            fallthrough
        case .bitshiftLeft, .bitshiftRight, .bitrotation:
            return run(left as! Int, right as! Int)
        case .equal, .notEqual:
            return left.isEqual(to: right) == (op == .equal)
        case .concat:
            let aleft = left as! String
            let aright = right as! String
            return aleft + aright
        case .logicalAnd, .logicalOr:
            fatalError()
        }
    }
    
    func mayUnbox(value: GRPHValue) throws -> GRPHValue {
        unbox ? try GRPHTypes.unbox(value: value) : value
    }
    
    func run(_ first: Float, _ second: Float) -> GRPHValue {
        switch op {
        case .greaterOrEqualTo:
            return first >= second
        case .lessOrEqualTo:
            return first <= second
        case .greaterThan:
            return first > second
        case .lessThan:
            return first < second
        case .plus:
            return first + second
        case .minus:
            return first - second
        case .multiply:
            return first * second
        case .divide:
            return first / second
        case .modulo:
            return fmodf(first, second)
        default:
            fatalError("Operator \(op.rawValue) doesn't take floats")
        }
    }
    
    func run(_ first: Int, _ second: Int) -> GRPHValue {
        switch op {
        case .bitwiseAnd:
            return first & second
        case .bitwiseOr:
            return first | second
        case .bitwiseXor:
            return first ^ second
        case .bitshiftLeft:
            return first << second
        case .bitshiftRight:
            return first >> second
        case .bitrotation:
            return Int(bitPattern: UInt(bitPattern: first) >> UInt(second))
        case .greaterOrEqualTo:
            return first >= second
        case .lessOrEqualTo:
            return first <= second
        case .greaterThan:
            return first > second
        case .lessThan:
            return first < second
        case .plus:
            return first + second
        case .minus:
            return first - second
        case .multiply:
            return first * second
        case .divide:
            return first / second
        case .modulo:
            return first % second
        default:
            fatalError("Operator \(op.rawValue) doesn't take integers")
        }
    }
    
    func run(_ first: Pos, _ second: Pos) -> GRPHValue {
        switch op {
        case .greaterOrEqualTo:
            return first.x >= second.x && first.y >= second.y
        case .lessOrEqualTo:
            return first.x <= second.x && first.y <= second.y
        case .greaterThan:
            return first.x > second.x && first.y > second.y
        case .lessThan:
            return first.x < second.x && first.y < second.y
        case .plus:
            return first + second
        case .minus:
            return first - second
        default:
            fatalError("Operator \(op.rawValue) doesn't take pos")
        }
    }
    
    func run(_ first: Rotation, _ second: Rotation) -> GRPHValue {
        switch op {
        case .plus:
            return first + second
        case .minus:
            return first - second
        default:
            fatalError("Operator \(op.rawValue) doesn't take floats")
        }
    }
}

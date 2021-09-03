//
//  ColorPaint.swift
//  Graphism
//
//  Created by Emil Pedersen on 30/06/2020.
//

import Foundation

enum ColorPaint: Paint, Equatable {
    // sys
    case white, gray, black, red, green, blue, orange, yellow, pink, purple, primary, secondary
    
    case components(red: Float, green: Float, blue: Float, alpha: Float = 1)
    
    var state: String {
        switch self {
        case .components(red: _, green: _, blue: _, alpha: let alpha):
            return "color(\(grphRed) \(grphGreen) \(grphBlue) \(alpha))"
        case .white:
            return "color.SYS_WHITE"
        case .black:
            return "color.SYS_BLACK"
        case .red:
            return "color.SYS_RED"
        case .green:
            return "color.SYS_GREEN"
        case .blue:
            return "color.SYS_BLUE"
        case .orange:
            return "color.SYS_ORANGE"
        case .yellow:
            return "color.SYS_YELLOW"
        case .pink:
            return "color.SYS_PINK"
        case .purple:
            return "color.SYS_PURPLE"
        case .gray:
            return "color.SYS_GRAY"
        case .primary:
            return "color.SYS_PRIMARY"
        case .secondary:
            return "color.SYS_SECONDARY"
        }
    }
    
    var rgba: (red: Float, green: Float, blue: Float, alpha: Float)? {
        switch self {
        case let .components(red: r, green: g, blue: b, alpha: a):
            return (red: r, green: g, blue: b, alpha: a)
        default:
            return nil
        }
    }
    
    var type: GRPHType { SimpleType.color }
}

extension ColorPaint {
    var grphRed: Int {
        get {
            Int((rgba?.red ?? -1) * 255)
        }
        set {
            if case let .components(_, green, blue, alpha) = self {
                self = .components(red: Float(newValue) / 255, green: green, blue: blue, alpha: alpha)
            }
        }
    }
    var grphGreen: Int {
        get {
            Int((rgba?.green ?? -1) * 255)
        }
        set {
            if case let .components(red, _, blue, alpha) = self {
                self = .components(red: red, green: Float(newValue) / 255, blue: blue, alpha: alpha)
            }
        }
    }
    var grphBlue: Int {
        get {
            Int((rgba?.blue ?? -1) * 255)
        }
        set {
            if case let .components(red, green, _, alpha) = self {
                self = .components(red: red, green: green, blue: Float(newValue) / 255, alpha: alpha)
            }
        }
    }
    var grphAlpha: Int {
        get {
            Int((rgba?.alpha ?? -1) * 255)
        }
        set {
            if case let .components(red, green, blue, _) = self {
                self = .components(red: red, green: green, blue: blue, alpha: Float(newValue) / 255)
            }
        }
    }
    var grphFRed: Float {
        get {
            rgba?.red ?? -1
        }
        set {
            if case let .components(_, green, blue, alpha) = self {
                self = .components(red: newValue, green: green, blue: blue, alpha: alpha)
            }
        }
    }
    var grphFGreen: Float {
        get {
            rgba?.green ?? -1
        }
        set {
            if case let .components(red, _, blue, alpha) = self {
                self = .components(red: red, green: newValue, blue: blue, alpha: alpha)
            }
        }
    }
    var grphFBlue: Float {
        get {
            rgba?.blue ?? -1
        }
        set {
            if case let .components(red, green, _, alpha) = self {
                self = .components(red: red, green: green, blue: newValue, alpha: alpha)
            }
        }
    }
    var grphFAlpha: Float {
        get {
            rgba?.alpha ?? -1
        }
        set {
            if case let .components(red, green, blue, _) = self {
                self = .components(red: red, green: green, blue: blue, alpha: newValue)
            }
        }
    }
    
    init(integer value: Int, alpha: Bool) {
         self = .components(red: Float((value >> 16) & 0xFF) / 255,
                                     green: Float((value >> 8) & 0xFF) / 255,
                                     blue: Float(value & 0xFF) / 255,
                                     alpha: alpha ? Float((value >> 24) & 0xFF) / 255 : 1)
    }
    
    var svgColor: String {
        "rgba(\(grphRed), \(grphGreen), \(grphBlue), \(grphFAlpha))"
    }
}

//
//  NSRegularExpression+Swift.swift
//  Graphism
//  Utilities for using the NSRegularExpression from Objective-C naturally with Swift, using Swift `Range` instead of Objective-C `NSRange`. A String in Swift is indexed differently than NSString, every conversion is handled correctly here.
//
//  Created by Emil Pedersen on 01/07/2020.
//  Published on GitHub Gist: https://gist.github.com/Snowy1803/d18775d247faf81f356434bc1f36524d
//

import Foundation

extension NSRegularExpression {
    
    /// Executes the closure for every match, passing the range of the match. Use string[match] to get the substring matched. This method doesn't support capture groups.
    func allMatches(in string: String, using block: (_ match: Range<String.Index>) -> Void) {
        try! allMatchesThrows(in: string, using: block)
    }
    
    /// Same as allMatches, but supports a throwing closure that will rethrow.
    // Only throws if block throws, but can't use rethrows because NSRegularExpression.enumerateMatches doesn't "rethrows"
    func allMatchesThrows(in string: String, using block: (_ match: Range<String.Index>) throws -> Void) throws {
        var err: Error?
        self.enumerateMatches(in: string, range: NSRange(string.startIndex..., in: string)) { result, _, stop in
            if let result = result,
               let range = Range(result.range, in: string) {
                do {
                    try block(range)
                } catch let error {
                    err = error
                    stop.pointee = true
                }
            }
        }
        if let err = err {
            throw err
        }
    }
    
    /// Replaces all matches of a regular expression with another string. This method doesn't support capture groups.
    func replaceMatches(in string: String, using block: (_ match: String) -> String) -> String {
        var builder = ""
        var last: String.Index?
        self.enumerateMatches(in: string, range: NSRange(string.startIndex..., in: string)) { result, _, _ in
            if let result = result,
               let range = Range(result.range, in: string) {
                
                builder += last == nil ? string[..<range.lowerBound] : string[last!..<range.lowerBound]
                
                // Replacement
                builder += block(String(string[range]))
                
                last = range.upperBound
            }
        }
        guard let end = last else {
            return string // No matches
        }
        builder += string[end...]
        return builder
    }
    
    /// Returns the capture groups of the first match as strings.
    /// The first index, 0 is guaranteed to be non-nil and contains the whole match, the other indexes will be nil if the capture group wasn't matched, otherwise it returns its content as a String.
    /// The whole returned array will be nil if there is no match.
    func firstMatch(string: String) -> [String?]? {
        guard let result = self.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return nil
        }
        var matches = [String?]()
        for i in 0...numberOfCaptureGroups {
            if let range = Range(result.range(at: i), in: string) {
                matches.append(String(string[range]))
            } else {
                matches.append(nil)
            }
        }
        return matches
    }
    
    /// Used for pattern matching in a switch. Use an NSRegularExpression as a pattern in a switch, will match if there is at least one match. Use anchors on your regular expression to match everything.
    static func ~= (lhs: NSRegularExpression, rhs: String) -> Bool {
        return lhs.firstMatch(string: rhs) != nil
    }
}

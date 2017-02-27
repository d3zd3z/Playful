//
//  Stroke.swift
//  Playful
//
//  Created by David Brown on 2/25/17.
//  Copyright © 2017 David Brown. All rights reserved.
//

import Foundation

struct Stroke: CustomStringConvertible {
    var value: UInt32 = 0
    
    init(from v: UInt32) {
        value = v
    }

    // Parse a sequence of strokes, possibly separated by "/"
    // characters, returning the sequence if that makes sense.
    static func parseStrokes(_ text: String) throws -> [Stroke] {
        let fullChars = Array(fullSteno.characters)

        var result = [Stroke]()

        // The parser matches characters in the input with characters
        // in the steno string.
        var pos = 0
        var bits = UInt32(0)

        // TODO: We don't handle any numbers yet.
        for ch in text.characters {
            if ch == "/" {
                if bits == 0 {
                    throw StrokeError.Simple("Empty stroke")
                }
                result.append(Stroke(from: bits))
                pos = 0
                bits = 0
                continue
            }
            if ch == "-" {
                // Technically, this should be at position 7, but one
                // of the lessons includes a hyphen after a *.
                if pos >= 10 {
                    throw StrokeError.Simple("Invalid '-' position in \(text)")
                }
                pos = 12
                continue
            }

            while pos < fullChars.count && fullChars[pos] != ch {
                pos += 1
            }
            if pos == fullChars.count {
                throw StrokeError.Simple("Invalid character: \(ch) in \(text)")
            }

            bits |= UInt32(1) << UInt32(pos)
        }
        if bits == 0 {
            throw StrokeError.Simple("Empty stroke")
        }
        result.append(Stroke(from: bits))

        return result
    }

    static func parseStroke(_ text: String) throws -> Stroke {
        let strokes = try parseStrokes(text)
        if strokes.count != 1 {
            throw StrokeError.Simple("Expecting a single stroke \(text)")
        }
        return strokes[0]
    }
    
    // The string value is a canonical representation of the stroke.
    var description: String {
        var result = ""
        var base = Stroke.fullSteno

        // If this is a number, and there are keys that distinguish
        // that, just use the numeric encoding.  Otherwise we need to
        // add the number sign to tell the difference.
        if (value & Stroke.num) != 0 {
            // print("value:", String(value, radix: 16))
            // print(String(format: "value: 0x%x", value))
            print(String(value, radix: 16, uppercase: false))
            if (value & Stroke.nums) != 0 {
                base = Stroke.numSteno
            } else {
                result.append("#")
            }
        }
        let needHyphen = ((value & Stroke.mid) == 0 &&
            (value & Stroke.right) != 0)

        var bit = UInt32(1)
        for ch in base.characters {
            if bit == Stroke.fStroke && needHyphen {
                result.append("-")
            }

            if (value & bit) != 0 {
                result.append(ch)
            }
            bit <<= 1
        }

        return result
    }

    static let fullSteno = "STKPWHRAO*EUFRPBLGTSDZ"
    static let numSteno =  "12K3W4R50*EU6R7B8G9SDZ"
    static let left: UInt32 = 0x7f
    static let mid: UInt32 = 0xf80
    static let right: UInt32 = 0x3ff000
    static let num: UInt32 = 0x400000
    static let nums: UInt32 = 0x551ab
    static let fStroke: UInt32 = 0x1000
}

enum StrokeError : Error {
    case Simple(String)
}

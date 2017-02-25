//
//  Stroke.swift
//  Playful
//
//  Created by David Brown on 2/25/17.
//  Copyright © 2017 David Brown. All rights reserved.
//

import Foundation

struct Stroke {
    var value: UInt32 = 0
    
    init(from v: UInt32) {
        value = v
    }
    
    // The string value is a canonical representation of the stroke.
    func toString() -> String {
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

//
//  ViewController.swift
//  Playful
//
//  Created by David Brown on 2/17/17.
//  Copyright © 2017 David Brown. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // This block seems to capture the key events.  However if System
        // Preferences -> Keyboard -> Shortcuts -> Full Key Access is set to
        // All controls, we then get called twice for each event.  Not sure if
        // we need to conditionally invoke this based on that setting, or be
        // able to ignore the doubled events.
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { (aEvent) -> NSEvent? in
            self.keyUp(with: aEvent)
            return aEvent
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
            self.keyDown(with: aEvent)
            return aEvent
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // keysDown tracks the keys that are currently pressed.  When this
    // goes back to empty.  This is indexed by keycode, since there
    // are multiple keys that result in the same steno.
    var keysDown = Set<UInt16>()

    // strokeKeys sets the keys that are seen in each stroke.
    var strokeKeys: UInt32 = 0
    
    override func keyDown(with event: NSEvent) {
        if let keyBit = keymap[event.keyCode] {
            // print("down: ", event.keyCode, keyBit, keysDown, strokeKeys)
            keysDown.insert(event.keyCode)
	    strokeKeys |= keyBit
        }
        // pass command keys up so that the command keys can control the app.
        if event.modifierFlags.contains(.command) {
            super.keyDown(with: event)
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if let _ = keymap[event.keyCode] {
            keysDown.remove(event.keyCode)
            if keysDown.isEmpty && strokeKeys != 0 {
                let st = Stroke(from: strokeKeys)
                print("Stroke:", st.toString())
                strokeKeys = 0
            }
        }
    }
    
    @IBOutlet weak var captureButton: NSButton!
    @IBAction func doCapture(_ sender: Any) {
        print("state: ", captureButton.state)
    }

    // Grumble. Swift 3.0 (Xcode 8.2.1) requires all of these explicit
    // types to avoid aborting because the inference is too
    // complicated (despite the top-level type being specified).
    let keymap: [UInt16: UInt32] = [
        UInt16(12): UInt32(1 << 0),
        UInt16( 0): UInt32(1 << 0),
        UInt16(13): UInt32(1 << 1),
        UInt16( 1): UInt32(1 << 2),
        UInt16(14): UInt32(1 << 3),
        UInt16( 2): UInt32(1 << 4),
        UInt16(15): UInt32(1 << 5),
        UInt16( 3): UInt32(1 << 6),
        UInt16( 8): UInt32(1 << 7),
        UInt16( 9): UInt32(1 << 8),
        UInt16(17): UInt32(1 << 9),
        UInt16( 5): UInt32(1 << 9),
        UInt16(45): UInt32(1 << 10),
        UInt16(46): UInt32(1 << 11),
        UInt16(32): UInt32(1 << 12),
        UInt16(38): UInt32(1 << 13),
        UInt16(34): UInt32(1 << 14),
        UInt16(40): UInt32(1 << 15),
        UInt16(31): UInt32(1 << 16),
        UInt16(37): UInt32(1 << 17),
        UInt16(35): UInt32(1 << 18),
        UInt16(41): UInt32(1 << 19),
        UInt16(33): UInt32(1 << 20),
        UInt16(39): UInt32(1 << 21),
        UInt16(29): UInt32(1 << 22),
        // TODO: Some keyboards will send any number, but SOFT/HRUF does not.
        // Allow for these other keyboards.
    ]
}


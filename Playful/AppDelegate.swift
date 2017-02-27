//
//  AppDelegate.swift
//  Playful
//
//  Created by David Brown on 2/17/17.
//  Copyright © 2017 David Brown. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let name = Bundle.main.path(forResource: "dict-canonical", ofType: "json")!
        let url = URL(fileURLWithPath: name)
        print(url)
        do {
            let data = try Data(contentsOf: url, options: [])
            print("data:", data.count)
            let obj = try JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, String>
            print("obj:", obj)
        } catch {
            print("Unable to load data")
            // TODO: Stop the app
            return
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}


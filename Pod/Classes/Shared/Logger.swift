//
//  Logger.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 23/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation

public class Log {
    public static var dev = true

    public static func e(_ message: String) {
        print("❌ \(message)")
    }

    public static func e(_ error: NSError?) {
        if error != nil {
            self.e("Error: \(error)")
        }
    }

    public static func w(_ message: String) {
        print("⚠️ \(message)")
    }

    public static func t(_ message: String) {
        print(message)
    }

    static func print(_ message: String) {
        if Log.dev {
            Swift.print(message)
        }
    }


    static var start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    static func startPerf() {
        self.start = CFAbsoluteTimeGetCurrent()
    }

    static func perf(_ message: String) {
        let now = CFAbsoluteTimeGetCurrent()
        let time = now - start

        print("[\(time*1000)ms] \(message)")
    }
}

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

    public static func e(message: String) {
        print("❌ \(message)")
    }

    public static func e(error: NSError?) {
        if error != nil {
            self.e("Error: \(error)")
        }
    }

    public static func w(message: String) {
        print("⚠️ \(message)")
    }

    public static func t(message: String) {
        print(message)
    }

    static func print(message: String) {
        if Log.dev {
            Swift.print(message)
        }
    }


    static var start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    static func startPerf() {
        self.start = CFAbsoluteTimeGetCurrent()
    }

    static func perf(message: String) {
        let now = CFAbsoluteTimeGetCurrent()
        let time = now - start

        print("[\(time*1000)ms] \(message)")
    }
}
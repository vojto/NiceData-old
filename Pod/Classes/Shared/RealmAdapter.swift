//
//  RealmAdapter.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 09/02/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation
//import RealmSwift
//
//
//struct RealmHandle: UpdatingHandle {
//}
//
//
//
//class RealmTask: Object {
//    dynamic var id = ""
//    dynamic var title = ""
//    dynamic var archived = false
//    dynamic var weight = 1
//    dynamic var finished = false
//    dynamic var estimate = 1
//    dynamic var finishedPomodoros = 0
//    dynamic var createdAt: Double = 0
//}
//
//
//class RealmAdapter: StoreAdapter {
//    func create(path: String, id: String?, data: RecordData, callback: CreateCallback?) {
//        print("Creating")
//        print("  \(path)")
//        print("  \(id)")
//        print("  \(data.priority)")
//        print("  \(data.values)")
//
//
//        let values = data.values as! SimpleDict
//
//        let realm = try! Realm()
//
//        try! realm.write {
//            let task = RealmTask()
//
//            task.id = id ?? generatePushID()
//            task.title = values["title"] as! String
//            task.archived = values["archived"] as! Bool
//            task.weight = values["weight"] as! Int
//            task.finished = values["finished"] as! Bool
//            task.estimate = values["estimate"] as! Int
//            task.finishedPomodoros = values["finishedPomodoros"] as! Int
//            task.createdAt = values["createdAt"] as! Double
//
//
//            realm.add(task)
//        }
//    }
//
//    func update(path: String, id: String, data: RecordData, callback: UpdateCallback?) {
//
//    }
//
//    func startUpdating(path: String, filter: Filter, sort: String?, callback: StoreCallback) -> UpdatingHandle {
//
//        // Going for very versatile code
//        if path != "tasks" {
//            return RealmHandle()
//        }
//
//        let realm = try! Realm()
//
//        let items = realm.objects(RealmTask)
//
//        let records: [Record] = items.map { task in
//            let values: RecordValues = [
//                "title": task.title,
//                "archived": task.archived,
//                "weight": task.weight,
//                "finished": task.finished,
//                "estimate": task.estimate,
//                "finishedPomodoros": task.finishedPomodoros
//            ]
//            let data = RecordData(values: values, priority: 1)
//            let record = Record(id: task.id, data: data)
//
//            return record
//        }
//
//        callback(records: records)
//
////        print("Items: \(items)")
//
//        return RealmHandle()
//    }
//
//    func stopUpdating(handle: UpdatingHandle) {
//
//    }
//
//    func loadNow(path: String, filter: Filter, sort: String?, callback: StoreCallback) {
//        
//    }
//
//    func find(path: String, id: String, callback: FindCallback) {
//
//    }
//}
//
//
//


/// custom unique identifier
/// @see https://www.firebase.com/blog/2015-02-11-firebase-unique-identifiers.html
// Taken from: https://gist.github.com/pgherveou/8e2b3a718bc9e367efa0
private let ASC_CHARS: [Character] = Array("-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".characters)
private let DESC_CHARS: [Character] = ASC_CHARS.reversed()
private var lastPushTime: UInt64 = 0
private var lastRandChars = Array<Int>(repeating: 0, count: 12)

func generatePushID(_ ascending: Bool = true) -> String {
    let PUSH_CHARS = ascending ? ASC_CHARS: DESC_CHARS
    var timeStampChars = Array<Character>(repeating: PUSH_CHARS.first!, count: 8)
    var now = UInt64(Date().timeIntervalSince1970 * 1000)
    let duplicateTime = (now == lastPushTime)
    lastPushTime = now
    
    for i in (0...7).reversed() {
        timeStampChars[i] = PUSH_CHARS[Int(now % 64)]
        now >>= 6
    }

    assert(now == 0, "We should have converted the entire timestamp.")
    var id: String = String(timeStampChars)

    if !duplicateTime {
        for i in 0..<12 { lastRandChars[i] = Int(64 *  Double(arc4random()) / Double(RAND_MAX)) }
    } else {
        var lastI: Int?
        
        for i in (0...11).reversed() where lastRandChars[i] == 63 {
            lastRandChars[i] = 0
            lastI = i
        }

        lastRandChars[lastI!] += 1
    }

    for i in 0..<12 { id.append(PUSH_CHARS[lastRandChars[i]]) }
    //    assert(count(id) == 20, "Length should be 20.")
    return id
}

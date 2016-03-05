//
//  MemoryAdapter.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 20/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation

/*

func isEqual<T: Equatable>(a: T, b: T) -> Bool {
    return a == b
}

func isEqual<T, U>(a: T, b: U) -> Bool {
    return false
}


class MemoryAdapter: StoreAdapter {
    var allRecords = [String: [Record]]()

    var callbacks = [String: [StoreCallback]]()
    var onChangeRecord: ((path: String, id: String, changes: [String: AnyObject]) -> ())?
    var onCreateRecord: ((path: String, id: String, record: Record) -> ())?

    func startUpdating(path: String, filter: [String: AnyObject], sort: String?, callback: StoreCallback) {
        if callbacks[path] == nil {
            callbacks[path] = [StoreCallback]()
        }

        callbacks[path]!.append(callback)
    }

    func loadNow(path: String, filter: Filter, sort: String?, callback: StoreCallback) {
        print("Loading now")
    }

    func create(path: String, var id: String?, data recordData: RecordData, callback: CreateCallback?) {
        ExtensionDelegate.log("MemoryAdapter.create called")

        if id == nil {
            id = generatePushID() + "-mem"
        }

        let record = Record(id: id!, data: recordData)

        if allRecords[path] == nil {
            allRecords[path] = []
        }

        allRecords[path]!.append(record)

        ExtensionDelegate.log("MemoryAdapter.create - done creating")

        callback?(record: record)

        ExtensionDelegate.log("MemoryAdapter.create - called immediate callback")

        runCallbacks(path)

        ExtensionDelegate.log("MemoryAdapter.create - called other callbacks - subscriptions")

        onCreateRecord?(path: path, id: id!, record: record)

        ExtensionDelegate.log("MemoryAdapter.create - called adapter's callback")

        ExtensionDelegate.log("MemoryAdapter.create done")
    }

    func update(path: String, id: String, data recordData: RecordData, callback: UpdateCallback?) {
        let records = allRecords[path]

        if let existingRecord = records?.filter({ $0.id == id }).first {

            var changes = [String: AnyObject]()

            let oldData = existingRecord.data.values
            let newData = recordData.values

            let keys1 = Set(oldData.keys)
            let keys2 = Set(newData.keys)
            let allKeys = keys1.union(keys2)

            for key in allKeys {
                if oldData[key] == nil && newData[key] != nil {
                    changes[key] = newData[key]
                } else if oldData[key] != nil && newData[key] == nil {
                    changes[key] = NSNull()
                } else if let old = oldData[key] as? NSObject, let new = newData[key] as? NSObject where !old.isEqual(new) {
                    changes[key] = newData[key]
                }
            }

            print("Updating: \(path) \(id) \(changes)")

            existingRecord.data.values = recordData.values

            if changes.keys.count > 0 {
                onChangeRecord?(path: path, id: id, changes: changes)
            }

            callback?()

            runCallbacks(path)
        }
    }

    func incrementalUpdate(path: String, id: String, changes: RecordValues, callback: UpdateCallback?) {
        print("Incremental update called on MemoryStore, but it's not implemented")
    }


    func updateMemory(path: String, items: [SerializedRecord]) {
        var records = [Record]()

        ExtensionDelegate.log("Deserializing \(items.count) items")

        for item in items {
            if let record = Record.deserialize(item) {
                records.append(record)
            } else {
                print("Cannot deserialize record from \(item)")
            }
        }

        ExtensionDelegate.log("Deserialized \(items.count) items")

        ExtensionDelegate.log("Replacing records for path: \(path)")


        allRecords[path] = records

        ExtensionDelegate.log("Replaced records for path: \(path)")

        ExtensionDelegate.log("Running callbacks for path: \(path)")

        runCallbacks(path)

        ExtensionDelegate.log("Ran callbacks for path: \(path)")
    }

    func runCallbacks(path: String) {
        for callback in (callbacks[path] ?? []) {
            callback(records: allRecords[path] ?? [])
        }
    }
}








*/
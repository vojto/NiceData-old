
//
//  FirebaseAdapter.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 20/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation
import Firebase


struct FirebaseHandle: UpdatingHandle {
    let id: UInt
    let path: String
}


public class FirebaseAdapter: StoreAdapter {
    public static var firebase: Firebase!
    var firebase: Firebase
    public static var instance: FirebaseAdapter!

    var uid: String? {
        return firebase.authData?.uid
    }

    public init() {
//        Firebase.setLoggingEnabled(true)

        Firebase.defaultConfig().persistenceEnabled = true
//        firebase = Firebase(url: "https://pomodoro-done.firebaseio.com")
        firebase = Firebase(url: "https://focuslist-dev.firebaseio.com")

        FirebaseAdapter.firebase = firebase

        FirebaseAdapter.instance = self
    }

    public func startUpdating(path: String, filter: [String: AnyObject], sort: String?, callback: StoreCallback) -> UpdatingHandle {
        let query = buildQuery(path, filter: filter, sort: sort)

        let id = query.observeEventType(.Value, withBlock: { snapshot in
            let records = self.recordsFromSnapshot(snapshot, filter: filter, sort: sort)
            callback(records: records)
        })

        let handle = FirebaseHandle(id: id, path: path)

        return handle
    }

    public func stopUpdating(handle: UpdatingHandle) {
        let handle = handle as! FirebaseHandle

        let node = rootLocation.childByAppendingPath(handle.path)

        node.removeObserverWithHandle(handle.id)
    }

    public func loadNow(path: String, filter: [String: AnyObject], sort: String?, callback: StoreCallback) {
        let query = buildQuery(path, filter: filter, sort: sort)

        query.observeSingleEventOfType(.Value, withBlock: { snapshot in
            let records = self.recordsFromSnapshot(snapshot, filter: filter, sort: sort)
            callback(records: records)
        })
    }

    public func buildQuery(path: String, filter: [String: AnyObject], sort: String?) -> FQuery {
        var query: FQuery = rootLocation.childByAppendingPath(path)

        if filter.count > 0 {
            if filter.count > 1 {
                fatalError("Filtering on more than 1 condition not supported: \(filter)")
            }

            let key = filter.keys.first!
            let value = filter[key]

            query = query.queryOrderedByChild(key)

            if let values = value as? [AnyObject] {
                query = query.queryStartingAtValue(values[0]).queryEndingAtValue(values[1])
            } else {
                query = query.queryEqualToValue(value)
            }
        } else if let sort = sort where sort == "priority" {
            query.queryOrderedByPriority()
        } // TODO: Sorting other than priority

        return query
    }

    func recordsFromSnapshot(snapshot: FDataSnapshot, filter: [String: AnyObject], sort: String?) -> [Record] {
        var records = [Record]()

        for item in snapshot.children {
            let snap = (item as! FDataSnapshot)
            if let record = recordFromSnapshot(snap) {
                records.append(record)
            } else {
                Log.e("Cannot create record from snapshot: \(snap)")
            }

        }

        // If there was a filter, then sorting was not applied and
        // we have to apply it here.

        if filter.count > 0 && sort == "priority" {
            records.sortInPlace { $0.data.priority < $1.data.priority }
        }

        return records
    }

    func recordFromSnapshot(snap: FDataSnapshot) -> Record? {
        guard let data = snap.value as? [String: AnyObject] else { return nil }
        let priority = (snap.priority as? NSNumber)?.integerValue
        let record = Record(id: snap.key, priority: priority, values: data)

        return record
    }

    // MARK: Finding

    public func find(path: String, id: String, callback: FindCallback) {
        let query = rootLocation.childByAppendingPath(path).childByAppendingPath(id)

        query.observeSingleEventOfType(.Value, withBlock: { snap in
            let record = self.recordFromSnapshot(snap)
            callback(record: record)
        })

    }

    // MARK: Helpers

    public var rootLocation: Firebase {
        let id: String

        if let user = firebase.authData {
            return firebase.childByAppendingPath("online").childByAppendingPath(user.uid)
        } else {
            return offlineLocation
        }
    }

    var offlineLocation: Firebase {
//        fatalError("Firebase will NOT be used offline!")
        return firebase.childByAppendingPath("offline").childByAppendingPath(NKDevice.uniqueIdentifier)
    }

    // MARK: Creating


    public func create(path: String, id: String?, data: RecordData, callback: CreateCallback?) {
        var location = rootLocation.childByAppendingPath(path)

        if let id = id {
            location = location.childByAppendingPath(id)
        } else {
            location = location.childByAutoId()
        }

        location.setValue(data.values, andPriority: data.priority) { (error, node) -> Void in
            let record = Record(id: node.key, data: data)

            callback?(record: record)
        }
    }

    // MARK: Updating

    public func update(path: String, id: String, data: RecordData, callback: UpdateCallback?) {
        let location = rootLocation.childByAppendingPath(path).childByAppendingPath(id)
        location.setValue(data.values, andPriority: data.priority) { _ in
            callback?()
        }
    }


    /*
    func incrementalUpdate(path: String, id: String, changes: RecordValues, callback: UpdateCallback?) {
        let location = rootLocation.childByAppendingPath(path).childByAppendingPath(id)
        location.updateChildValues(changes) { _ in
            callback?()
        }
    }
    */

    func find(id: String, filter: Filter, callback: FindCallback) {

    }
}


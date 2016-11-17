
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


open class FirebaseAdapter: StoreAdapter {
    open static var firebase: Firebase!
    var firebase: Firebase
    open static var instance: FirebaseAdapter!

    var uid: String? {
        return firebase.authData?.uid
    }

    public init(url: String) {
//        Firebase.setLoggingEnabled(true)

        Firebase.defaultConfig().persistenceEnabled = true

        firebase = Firebase(url: url)

        FirebaseAdapter.firebase = firebase

        FirebaseAdapter.instance = self
    }

    open func startUpdating(_ path: String, filter: Filter, sort: String?, callback: @escaping StoreCallback) -> UpdatingHandle {
        
        let query = buildQuery(path, filter: filter, sort: sort)

        let id = query.observe(.value, with: { snapshot in
            let records = self.recordsFromSnapshot(snapshot!, filter: filter, sort: sort)
            
            callback(records)
        })

        let handle = FirebaseHandle(id: id, path: path)

        return handle
    }

    open func stopUpdating(_ handle: UpdatingHandle) {
        let handle = handle as! FirebaseHandle

        let node = rootLocation.child(byAppendingPath: handle.path)

        node?.removeObserver(withHandle: handle.id)
    }

    open func loadNow(_ path: String, filter: Filter, sort: String?, callback: @escaping StoreCallback) {
        if let inCondition = filter.removeInCondition() {
            return self.loadNow(path, filter:filter, sort: sort, inCondition: inCondition, callback: callback)
        }

        let query = buildQuery(path, filter: filter, sort: sort)
        
        query.observeSingleEvent(of: .value, with: { snapshot in
            let records = self.recordsFromSnapshot(snapshot!, filter: filter, sort: sort)
            callback(records)
        })
    }

    open func loadNow(_ path: String, filter: Filter, sort: String?, inCondition: InFilterCondition, callback: @escaping StoreCallback) {
        if inCondition.column == "id" {
            let ids = inCondition.values as! [String]
            self.loadNow(path, filter: filter, sort: sort, idIn: ids, callback: callback)
        } else {
            fatalError("Cannot make IN queries for columns other than ID")
        }
    }

    open func loadNow(_ path: String, filter: Filter, sort: String?, idIn ids: [String], callback: @escaping StoreCallback) {
        // Loading data for multiple IDs takes finding multiple locations and waiting for each request fo finish
        
        var ids = ids
        if filter.conditions.count > 0 {
            fatalError("When loading using IN for ids, further filtering is not supported")
        }

        if sort != nil {
            fatalError("When loading using IN for ids, sorting is not supported")
        }


        var records = [Record]()

        ids = Array(Set(ids))

        let requestsCount = ids.count
        var loadedCount = 0

        for id in ids {
            let query: FQuery = rootLocation.child(byAppendingPath: path).child(byAppendingPath: id)

            query.observeSingleEvent(of: .value, with: { snapshot in
                if let record = self.recordFromSnapshot(snapshot!) {
                    records.append(record)
                }

                loadedCount += 1

                if loadedCount == requestsCount {
                    callback(records)
                }
            })
        }

    }

    open func buildQuery(_ path: String, filter: Filter, sort: String?) -> FQuery {
        var query: FQuery = rootLocation.child(byAppendingPath: path)

        query = self.applyFilterToQuery(query, filter: filter)

        if let sort = sort, sort == "priority" {
            query.queryOrderedByPriority()
        } // TODO: Sorting other than priority

        return query
    }

    func applyFilterToQuery( _ query: FQuery, filter: Filter) -> FQuery {
        var query = query
        let conditions = filter.conditions

        if conditions.count == 0 {
            return query
        }

        if conditions.count > 1 {
            fatalError("Firebase only supports filtering by 1 condition \(filter)")
        }

        let condition = conditions.first!
        let key = condition.column

        query = query.queryOrdered(byChild: key)

        switch condition {
        case let condition as EqualsFilterCondition:
            query = query.queryEqual(toValue: condition.value)
        case let condition as BetweenFilterCondition:
            query = query.queryStarting(atValue: condition.value1).queryEnding(atValue: condition.value2)
        default:
            fatalError("Cannot apply filter to query for condition type \(type(of: condition))")
        }

        return query
    }

    func recordsFromSnapshot(_ snapshot: FDataSnapshot, filter: Filter, sort: String?) -> [Record] {
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

        if filter.conditions.count > 0 && sort == "priority" {
            records.sorted { $0.data.priority! < $1.data.priority! }
        }

        return records
    }

    func recordFromSnapshot(_ snap: FDataSnapshot) -> Record? {
        guard let data = snap.value as? [String: AnyObject] else { return nil }
        let priority = (snap.priority as? NSNumber)?.intValue
        let record = Record(id: snap.key, priority: priority, values: data)

        return record
    }

    // MARK: Finding

    open func find(_ path: String, id: String, callback: @escaping FindCallback) {
        let query = rootLocation.child(byAppendingPath: path).child(byAppendingPath: id)

        query?.observeSingleEvent(of: .value, with: { snap in
            let record = self.recordFromSnapshot(snap!)
            callback(record)
        })

    }

    // MARK: Helpers
    // ----------------------------------------------------------------------

    open var rootLocation: Firebase {
        if let user = firebase.authData {
            return firebase.child(byAppendingPath: "online").child(byAppendingPath: user.uid)
        } else {
            return offlineLocation
        }
    }

    var offlineLocation: Firebase {
//        fatalError("Firebase will NOT be used offline!")
        return firebase.child(byAppendingPath: "offline").child(byAppendingPath: NKDevice.uniqueIdentifier)
    }

    // MARK: Creating
    // ----------------------------------------------------------------------

    open func create(_ path: String, id: String?, data: RecordData, callback: CreateCallback?) -> String {
        var location = rootLocation.child(byAppendingPath: path)

        if let id = id {
            location = location?.child(byAppendingPath: id)
        } else {
            location = location?.childByAutoId()
        }

        location?.setValue(data.values, andPriority: data.priority) { (error, node) -> Void in
            let record = Record(id: (node?.key)!, data: data)

            callback?(record)
        }
        
        return location!.key
    }

    // MARK: - Updating
    // ----------------------------------------------------------------------

    open func update(_ path: String, id: String, data: RecordData, callback: UpdateCallback?) {
        let location = rootLocation.child(byAppendingPath: path).child(byAppendingPath: id)
        location?.setPriority(data.priority)
        location?.updateChildValues(data.values) { (err, loc) in
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

    func find(_ id: String, filter: Filter, callback: FindCallback) {
    }


    // MARK: - Deleting
    // ----------------------------------------------------------------------

    open func delete(_ path: String, id: String, callback: DeleteCallback?) {
        let location = rootLocation.child(byAppendingPath: path).child(byAppendingPath: id)
        
        location?.removeValue()
    }
}


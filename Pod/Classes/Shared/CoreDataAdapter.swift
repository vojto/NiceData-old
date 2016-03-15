//
//  CoreDataAdapter.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 10/02/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord


struct EmptyHandle: UpdatingHandle {

}

struct CoreDataHandle: UpdatingHandle {
    let observer: CDObserver
}

public class CoreDataAdapter: StoreAdapter {
    // TODO: Great job hard coding this
    public static var pathMap = [
        "tasks": "Task",
        "cycles": "Cycle",
        "dayStats": "DayStat"
    ]

    public init() {
    }

    public func create(path: String, var id: String?, data: RecordData, callback: CreateCallback?) {
        let priority = data.priority

        let context = NSManagedObjectContext.MR_defaultContext()

        let entityName = self.entityForPath(path)

        // First, try to find an existing object with the same ID
        var object: NSManagedObject?

        if id != nil {
            object = self.findObject(context, path: path, id: id!)
        } else {
            id = generatePushID()
        }

        if object == nil {
            object = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
        }

            self.updateObjectFromRecord(object!, id: id!, data: data)

        context.MR_saveToPersistentStoreAndWait()

        let record = Record(id: id!, priority: priority, values: data.values)
        callback?(record: record)
    }

    public func updateObjectFromRecord(object: NSManagedObject, id: String, data: RecordData) {
        object.setValue(id, forKey: "id")

        if let priority = data.priority {
            object.setValue(priority, forKey: "priority")
        }

        for (key, value) in data.values {
            if value is NSNull {
                object.setValue(nil, forKey: key)
            } else {
                object.setValue(value, forKey: key)
            }
        }
    }

    public func update(path: String, id: String, data: RecordData, callback: UpdateCallback?) {
        Log.t("😡 updating \(path)/\(id)")

        let context = NSManagedObjectContext.MR_defaultContext()

        guard let object = self.findObject(context, path: path, id: id) else {
            Log.e("Cannot find object with id = \(id)")
            return
        }

        self.updateObjectFromRecord(object, id: id, data: data)

        context.MR_saveToPersistentStoreAndWait()
        
        callback?()
    }

    internal func findObject(context: NSManagedObjectContext, path: String, id: String) -> NSManagedObject? {
        let entityName = self.entityForPath(path)
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "id = %@", id)

        do {
            let results = try context.executeFetchRequest(request)
            return results.first as! NSManagedObject?
        } catch _ {
            Log.e("Failed finding object by id \(path) \(id)")
            return nil
        }


    }


    public func startUpdating(path: String, filter: Filter, sort: String?, callback: StoreCallback) -> UpdatingHandle {
        let request = createFetchRequest(path, filter: filter, sort: sort)

        let observer = CDObserver(request: request) { results in
            let records = self.recordsFromResults(results)

            callback(records: records)
        }

        return CoreDataHandle(observer: observer)
    }

    public func recordsFromResults(results: [NSManagedObject]) -> [Record] {
        var records = [Record]()

        for object in results {
            var values = RecordValues()
            var priority: Int?
            let id = object.valueForKey("id") as! String

            let entity = object.entity
            let attributes = entity.attributesByName

            for (attribute, _) in attributes {
                if attribute == "priority" {
                    priority = object.valueForKey(attribute) as? Int
                } else {
                    values[attribute] = object.valueForKey(attribute)
                }
            }

            let record = Record(id: id, priority: priority, values: values)
            records.append(record)
        }

        return records
    }

    public func createFetchRequest(path: String, filter: Filter, var sort: String?) -> NSFetchRequest {
//        print("Creating request: \(path), filter: \(filter), sort: \(sort)")


        if sort == nil {
            sort = "priority"
        }

        let entityName = entityForPath(path)
        let request = NSFetchRequest(entityName: entityName)
        request.sortDescriptors = [NSSortDescriptor(key: sort, ascending: true)]

        // Create NSCompoundPredicate from conditions

        var predicates = [NSPredicate]()
        for condition in filter.conditions {
            let column = condition.column

            switch condition {
            case let condition as EqualsFilterCondition:
                let value = condition.value
                let predicate = NSPredicate(format: "\(column) = %@", argumentArray: [value])
                predicates.append(predicate)
            case let condition as  BetweenFilterCondition:
                let value1 = condition.value1
                let value2 = condition.value2
                let predicate = NSPredicate(format: "%K >= %@ AND %K <= %@", argumentArray: [column, value1, column, value2])
                predicates.append(predicate)
            default:
                fatalError("Cannot create predicate from condition of type \(condition.dynamicType)")
            }
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        request.predicate = predicate

        return request
    }

    public func stopUpdating(handle: UpdatingHandle) {
        guard let handle = handle as? CoreDataHandle else { return }
        handle.observer.cancel()
    }

    public func loadNow(path: String, filter: Filter, sort: String?, callback: StoreCallback) {
        let request = createFetchRequest(path, filter: filter, sort: sort)
        let context = NSManagedObjectContext.MR_defaultContext()

        do {
            let results = try context.executeFetchRequest(request)

            let records = self.recordsFromResults(results as! [NSManagedObject])

            callback(records: records)
        } catch _ {
            Log.e("Failed loading results using loadNow")
        }

    }

    public func find(path: String, id: String, callback: FindCallback) {
        fatalError("find not implemented")
    }


    // Private

    internal func entityForPath(path: String) -> String {
        if let entity = CoreDataAdapter.pathMap[path] {
            return entity
        } else {
            fatalError("No entity for path \(path)")
        }
    }
}
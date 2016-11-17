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

open class CoreDataAdapter: StoreAdapter {
    // TODO: Great job hard coding this
    open static var pathMap = [
        "tasks": "Task",
        "cycles": "Cycle",
        "dayStats": "DayStat"
    ]

    public init() {
    }

    open func create(_ path: String, id: String?, data: RecordData, callback: CreateCallback?) -> String {
        var id = id
        let priority = data.priority

        let context = NSManagedObjectContext.mr_default()!

        let entityName = self.entityForPath(path)

        // First, try to find an existing object with the same ID
        var object: NSManagedObject?

        if id != nil {
            object = self.findObject(context, path: path, id: id!)
        } else {
            id = generatePushID()
        }

        if object == nil {
            object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        }

            self.updateObjectFromRecord(object!, id: id!, data: data)

        context.mr_saveToPersistentStoreAndWait()

        let record = Record(id: id!, priority: priority, values: data.values)
        callback?(record)
        
        return id!
    }

    open func updateObjectFromRecord(_ object: NSManagedObject, id: String, data: RecordData) {
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

    open func update(_ path: String, id: String, data: RecordData, callback: UpdateCallback?) {
        let context = NSManagedObjectContext.mr_default()

        guard let object = self.findObject(context!, path: path, id: id) else {
            Log.e("Cannot find object with id = \(id)")
            return
        }

        self.updateObjectFromRecord(object, id: id, data: data)

        context?.mr_saveToPersistentStoreAndWait()
        
        callback?()
    }

    internal func findObject(_ context: NSManagedObjectContext, path: String, id: String) -> NSManagedObject? {
        let entityName = self.entityForPath(path)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = NSPredicate(format: "id = %@", id)

        do {
            let results = try context.fetch(request)
            return results.first as! NSManagedObject?
        } catch _ {
            Log.e("Failed finding object by id \(path) \(id)")
            return nil
        }
    }


    open func startUpdating(_ path: String, filter: Filter, sort: String?, callback: @escaping StoreCallback) -> UpdatingHandle {
        let request = createFetchRequest(path, filter: filter, sort: sort)

        let observer = CDObserver(request: request) { results in
            let records = self.recordsFromResults(results)

            callback(records)
        }

        return CoreDataHandle(observer: observer)
    }

    open func recordsFromResults(_ results: [NSManagedObject]) -> [Record] {
        var records = [Record]()

        for object in results {
            var values = RecordValues()
            var priority: Int?
            let id = object.value(forKey: "id") as! String

            let entity = object.entity
            let attributes = entity.attributesByName

            for (attribute, _) in attributes {
                if attribute == "priority" {
                    priority = object.value(forKey: attribute) as? Int
                } else {
                    values[attribute] = object.value(forKey: attribute) as AnyObject?
                }
            }

            let record = Record(id: id, priority: priority, values: values)
            records.append(record)
        }

        return records
    }

    open func createFetchRequest(_ path: String, filter: Filter, sort: String?) -> NSFetchRequest<NSFetchRequestResult> {
        var sort = sort
        if sort == nil {
            sort = "priority"
        }

        let entityName = entityForPath(path)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
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
            case let condition as InFilterCondition:
                let values = condition.values
                let predicate = NSPredicate(format: "%K IN %@", argumentArray: [column, values])
                predicates.append(predicate)
            default:
                fatalError("Cannot create predicate from condition of type \(type(of: condition))")
            }
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        request.predicate = predicate

        return request
    }

    open func stopUpdating(_ handle: UpdatingHandle) {
        guard let handle = handle as? CoreDataHandle else { return }
        handle.observer.cancel()
    }

    open func loadNow(_ path: String, filter: Filter, sort: String?, callback: @escaping StoreCallback) {
        let request = createFetchRequest(path, filter: filter, sort: sort)
        let context = NSManagedObjectContext.mr_default()

        do {
            let results = try context?.fetch(request)

            let records = self.recordsFromResults(results as! [NSManagedObject])

            callback(records)
        } catch _ {
            Log.e("Failed loading results using loadNow")
        }

    }

    open func find(_ path: String, id: String, callback: @escaping FindCallback) {
        fatalError("find not implemented")
    }

    // MARK: - Deleting
    // -----------------------------------------------------------------------


    open func delete(_ path: String, id: String, callback: DeleteCallback?) {
        let context = NSManagedObjectContext.mr_default()

        guard let object = findObject(context!, path: path, id: id) else {
            Log.e("Didn't find object with id \(id) at \(path) so cannot delete.")
            return
        }

        context!.delete(object)

        context!.mr_saveToPersistentStoreAndWait()

        callback?()
    }


    // Private

    internal func entityForPath(_ path: String) -> String {
        if let entity = CoreDataAdapter.pathMap[path] {
            return entity
        } else {
            fatalError("No entity for path \(path)")
        }
    }
}

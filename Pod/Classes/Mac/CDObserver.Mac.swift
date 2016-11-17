//
//  CDObserver.Mac.swift
//  FocusList
//
//  Created by Vojtech Rinik on 11/02/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation
import MagicalRecord


typealias CDCallback = (([NSManagedObject]) -> ())


class CDObserver: NSObject {
    let request: NSFetchRequest<NSFetchRequestResult>
    let callback: CDCallback

    init(request: NSFetchRequest<NSFetchRequestResult>, callback: @escaping CDCallback) {
        self.request = request
        self.callback = callback

        super.init()

        let context = NSManagedObjectContext.mr_default()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(CDObserver.handleObjectsChanged(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)

        fetch()
    }

    func fetch() {
        let context = NSManagedObjectContext.mr_default()!

        do {
            let results = try context.fetch(request) as! [NSManagedObject]
            callback(results)
        } catch _ {
            Log.e("Failed executing fetch request \(request)")
        }
    }

    func handleObjectsChanged(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let entity = request.entity

        let insertedObjects = userInfo[NSInsertedObjectsKey] as? NSSet
        let updatedObjects = userInfo[NSUpdatedObjectsKey] as? NSSet
        let deletedObjects = userInfo[NSDeletedObjectsKey] as? NSSet
//        let refreshedObjects = userInfo[NSRefreshedObjectsKey] as? NSSet

        var changedEntities = Set<String>()

        for set in [insertedObjects, updatedObjects, deletedObjects] {
            if set == nil { continue }

            for object in set!.allObjects {
                let entityName = (object as! NSManagedObject).entity.name!
                changedEntities.insert(entityName)
            }
        }

        if self.request.entity?.name == "Task" {
            Log.t("    Updated Tasks 👽")
        }


        if changedEntities.contains(request.entity!.name!) {
            fetch()
        }
    }



    func cancel() {
        let center = NotificationCenter.default
        let context = NSManagedObjectContext.mr_default()

        center.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
    }
}

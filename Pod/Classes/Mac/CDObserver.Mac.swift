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
    let request: NSFetchRequest
    let callback: CDCallback

    init(request: NSFetchRequest, callback: CDCallback) {
        self.request = request
        self.callback = callback

        super.init()

        let context = NSManagedObjectContext.MR_defaultContext()
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "handleObjectsChanged:", name: NSManagedObjectContextObjectsDidChangeNotification, object: context)

        fetch()
    }

    func fetch() {
        let context = NSManagedObjectContext.MR_defaultContext()

        do {
            let results = try context.executeFetchRequest(request) as! [NSManagedObject]
            callback(results)
        } catch _ {
            Log.e("Failed executing fetch request \(request)")
        }
    }

    func handleObjectsChanged(notification: NSNotification) {
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
            print("Re-fetching")
            fetch()
        }
    }



    func cancel() {
        let center = NSNotificationCenter.defaultCenter()
        let context = NSManagedObjectContext.MR_defaultContext()

        center.removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: context)
    }
}
//
//  CoreDataHelpers.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 09/02/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord

typealias CDCallback = (([NSManagedObject]) -> ())


class CDObserver: NSObject, NSFetchedResultsControllerDelegate {
    var controller: NSFetchedResultsController!
    var callback: CDCallback?

    init(request: NSFetchRequest, callback: CDCallback) {
        let context = NSManagedObjectContext.MR_defaultContext()

        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        self.callback = callback


        super.init()

        controller.delegate = self


        try! controller.performFetch()

        self.triggerCallback()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

    }


    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.triggerCallback()
    }

    func triggerCallback() {
        let section = controller.sections!.first!

        let count = section.numberOfObjects

        var items = [NSManagedObject]()

        for var i = 0; i < count; i++ {
            let item = controller.objectAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) as! NSManagedObject
            items.append(item)
        }

        callback?(items)
    }

    func cancel() {
        controller.delegate = nil
    }
}

//class CoreDataHelpers {
//    static func observe(request: NSFetchRequest, sort: NSSortDescriptor) {
//        let context = NSManagedObjectContext.MR_defaultContext()
//    }
//}
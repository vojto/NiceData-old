//
//  StoreSubscription.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 21/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation


open class StoreSubscription: Hashable {
    let name: String
    open var path: String!
    open var filter = Filter()
    open var sort: String?

    var callbacks = [StoreCallback]()
    var lastRecords: [Record]?
    var handle: UpdatingHandle?

    public init(name: String) {
        self.name = name
    }

    var active: Bool {
        return handle != nil
    }

    open func addCallback(_ callback: @escaping StoreCallback) {
        callbacks.append(callback)
    }

    var adapter: StoreAdapter {
        return GeneralStore.instance.adapter
    }

    open var hashValue: Int {
        return name.hashValue
    }

    open func start() {
        let store = GeneralStore.instance

        if !store.hasSubscription(self) {
            fatalError("Cannot start subscription, because it wasn't added to GeneralStore")
        }


        if active {
            stop()
        }

        self.handle = adapter.startUpdating(path, filter: filter, sort: sort) { records in
            self.lastRecords = records
            self.runCallbacks(records)
        }
    }

    open func stop() {
        if let handle = self.handle {
            adapter.stopUpdating(handle)
            self.handle = nil
        } else {
            Log.e("Can't stop updating subscription, it was never started")
        }
    }

    open func forceRefresh() {
        let store = GeneralStore.instance

        if !store.hasSubscription(self) {
            fatalError("Cannot forceRefresh subscription, because it wasn't added to GeneralStore")
        }

        stop()
        start()
    }

    func runCallbacks(_ records: [Record]) {
        for callback in callbacks {
            callback(records)
        }
    }
}

public func ==(lhs: StoreSubscription, rhs: StoreSubscription) -> Bool {
    return lhs.name == rhs.name
}

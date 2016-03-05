//
//  StoreSubscription.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 21/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation


public class StoreSubscription: Hashable {
    let name: String
    public var path: String!
    public var filter = Filter()
    public var sort: String?

    var callbacks = [StoreCallback]()
    var lastRecords: [Record]?
    var handle: UpdatingHandle?

    public init(name: String) {
        self.name = name
    }

    var active: Bool {
        return handle != nil
    }

    public func addCallback(callback: StoreCallback) {
        callbacks.append(callback)
    }

    var adapter: StoreAdapter {
        return GeneralStore.instance.adapter
    }

    public var hashValue: Int {
        return name.hashValue
    }

    public func start() {
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

    func stop() {
        if let handle = self.handle {
            adapter.stopUpdating(handle)
            self.handle = nil
        } else {
            Log.e("Can't stop updating subscription, it was never started")
        }
    }

    func forceRefresh() {
        let store = GeneralStore.instance

        if !store.hasSubscription(self) {
            fatalError("Cannot forceRefresh subscription, because it wasn't added to GeneralStore")
        }

        stop()
        start()
    }

    func runCallbacks(records: [Record]) {
        for callback in callbacks {
            callback(records: records)
        }
    }
}

public func ==(lhs: StoreSubscription, rhs: StoreSubscription) -> Bool {
    return lhs.name == rhs.name
}
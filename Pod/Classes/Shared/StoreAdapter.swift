//
//  StoreAdapter.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 21/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation

public typealias StoreCallback = (records: [Record]) -> ()
public typealias CreateCallback = ((record: Record) -> ())
public typealias UpdateCallback = (() -> ())
public typealias DeleteCallback = (() -> ())
public typealias FindCallback = ((record: Record?) -> ())

public protocol StoreAdapter {
    // Create record. You can pass optional ID - if you pass it, record will be
    // created with that ID.
    func create(path: String, id: String?, data: RecordData, callback: CreateCallback?)
    func update(path: String, id: String, data: RecordData, callback: UpdateCallback?)
    func delete(path: String, id: String, callback: DeleteCallback?)
    func startUpdating(path: String, filter: Filter, sort: String?, callback: StoreCallback) -> UpdatingHandle
    func stopUpdating(handle: UpdatingHandle)
    func loadNow(path: String, filter: Filter, sort: String?, callback: StoreCallback)
    func find(path: String, id: String, callback: FindCallback)
}

public protocol UpdatingHandle {
}
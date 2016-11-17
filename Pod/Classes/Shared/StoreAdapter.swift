//
//  StoreAdapter.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 21/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation

public typealias StoreCallback = (_ records: [Record]) -> ()
public typealias CreateCallback = ((_ record: Record) -> ())
public typealias UpdateCallback = (() -> ())
public typealias DeleteCallback = (() -> ())
public typealias FindCallback = ((_ record: Record?) -> ())

public protocol StoreAdapter {
    // Create record. You can pass optional ID - if you pass it, record will be
    // created with that ID.
    func create(_ path: String, id: String?, data: RecordData, callback: CreateCallback?) -> String
    func update(_ path: String, id: String, data: RecordData, callback: UpdateCallback?)
    func delete(_ path: String, id: String, callback: DeleteCallback?)
    func startUpdating(_ path: String, filter: Filter, sort: String?, callback: @escaping StoreCallback) -> UpdatingHandle
    func stopUpdating(_ handle: UpdatingHandle)
    func loadNow(_ path: String, filter: Filter, sort: String?, callback: @escaping StoreCallback)
    func find(_ path: String, id: String, callback: @escaping FindCallback)
}

public protocol UpdatingHandle {
}

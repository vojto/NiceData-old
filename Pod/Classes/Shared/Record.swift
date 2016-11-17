//
//  Record.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 21/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation

typealias SerializedRecord = SimpleDict
public typealias RecordValues = SimpleDict
public typealias RecordPriority = Int?

public enum ModelError : Error {
    case badData
}

struct RecordKeys {
    static let id = "i"
    static let data = "d"
    static let values = "v"
    static let priority = "p"
}

open class Record: CustomDebugStringConvertible {
    open let id: String
    open let data: RecordData

    init(id: String, data: RecordData) {
        self.id = id
        self.data = data
    }

    convenience init(id: String, priority: RecordPriority, values: RecordValues) {
        self.init(id: id, data: RecordData(values, priority: priority))
    }

    func serialize() -> SerializedRecord {
        return [
            RecordKeys.id: id as AnyObject,
            RecordKeys.data: data.serialize() as AnyObject
        ]
    }

    static func deserialize(_ serialized: SerializedRecord) -> Record? {
        guard let id = serialized[RecordKeys.id] as? String else { return nil }
        guard let data = serialized[RecordKeys.data] as? SimpleDict else { return nil }
        guard let recordData = RecordData.deserialize(data) else { return nil }

        return Record(id: id, data: recordData)
    }

    open var debugDescription: String {
        return "<\(id):\(data)>"
    }
}

open class RecordData: CustomDebugStringConvertible {
    open let priority: RecordPriority
    open var values: RecordValues

    public init(_ values: RecordValues, priority: RecordPriority) {
        self.priority = priority
        self.values = values
    }

    open func serialize() -> [String: AnyObject] {
        var result: [String: AnyObject] = [
            RecordKeys.values: values as AnyObject
        ]

        if let priority = self.priority {
            result[RecordKeys.priority] = priority as AnyObject?
        }

        return result
    }

    open static func deserialize(_ serialized: SimpleDict) -> RecordData? {
        guard let priority = serialized[RecordKeys.priority] as? RecordPriority else { return nil }
        guard let values = serialized[RecordKeys.values] as? RecordValues else { return nil }

        return RecordData(values, priority: priority)
    }

    open func requiredDate(_ key: String) throws -> Date {
        guard let timestamp = values[key] as? NSNumber else { throw ModelError.badData }
        return Date(timeIntervalSince1970: timestamp.doubleValue)
    }

    open func optionalDate(_ key: String) throws -> Date? {
        guard let timestamp = values[key] as? NSNumber? else { throw ModelError.badData }
        if let timestamp = timestamp {
            return Date(timeIntervalSince1970: timestamp.doubleValue)
        } else {
            return nil
        }
    }

    open func requiredDouble(_ key: String) throws -> Double {
        guard let value = values[key] as? NSNumber else { throw ModelError.badData }
        return value.doubleValue
    }

    open func optionalDouble(_ key: String) throws -> Double? {
        guard let value = values[key] as? NSNumber? else { throw ModelError.badData }
        return value?.doubleValue
    }

    open func optionalInt(_ key: String) throws -> Int? {
        guard let value = values[key] as? NSNumber? else { throw ModelError.badData }
        return value?.intValue
    }

    open func requiredBool(_ key: String) throws -> Bool {
        guard let value = values[key] as? NSNumber else { throw ModelError.badData }
        return value.boolValue
    }

    open func optionalBool(_ key: String) throws -> Bool? {
        guard let value = values[key] as? NSNumber? else { throw ModelError.badData }
        return value?.boolValue
    }

    open func requiredString(_ key: String) throws -> String {
        guard let value = values[key] as? String else { throw ModelError.badData }
        return value
    }

    open func optionalString(_ key: String) throws -> String? {
        guard let value = values[key] as? String? else { throw ModelError.badData }
        return value
    }

    open var debugDescription: String {
        return "{\(priority) \(values)}"
    }




}

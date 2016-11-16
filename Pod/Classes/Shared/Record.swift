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
    case BadData
}

struct RecordKeys {
    static let id = "i"
    static let data = "d"
    static let values = "v"
    static let priority = "p"
}

public class Record: CustomDebugStringConvertible {
    public let id: String
    public let data: RecordData

    init(id: String, data: RecordData) {
        self.id = id
        self.data = data
    }

    convenience init(id: String, priority: RecordPriority, values: RecordValues) {
        self.init(id: id, data: RecordData(values: values, priority: priority))
    }

    func serialize() -> SerializedRecord {
        return [
            RecordKeys.id: id,
            RecordKeys.data: data.serialize()
        ]
    }

    static func deserialize(serialized: SerializedRecord) -> Record? {
        guard let id = serialized[RecordKeys.id] as? String else { return nil }
        guard let data = serialized[RecordKeys.data] as? SimpleDict else { return nil }
        guard let recordData = RecordData.deserialize(data) else { return nil }

        return Record(id: id, data: recordData)
    }

    public var debugDescription: String {
        return "<\(id):\(data)>"
    }
}

public class RecordData: CustomDebugStringConvertible {
    public let priority: RecordPriority
    public var values: RecordValues

    public init(values: RecordValues, priority: RecordPriority) {
        self.priority = priority
        self.values = values
    }

    public func serialize() -> [String: AnyObject] {
        var result: [String: AnyObject] = [
            RecordKeys.values: values
        ]

        if let priority = self.priority {
            result[RecordKeys.priority] = priority
        }

        return result
    }

    public static func deserialize(serialized: SimpleDict) -> RecordData? {
        guard let priority = serialized[RecordKeys.priority] as? RecordPriority else { return nil }
        guard let values = serialized[RecordKeys.values] as? RecordValues else { return nil }

        return RecordData(values: values, priority: priority)
    }

    public func requiredDate(key: String) throws -> NSDate {
        guard let timestamp = values[key] as? NSNumber else { throw ModelError.BadData }
        return NSDate(timeIntervalSince1970: timestamp.doubleValue)
    }

    public func optionalDate(key: String) throws -> NSDate? {
        guard let timestamp = values[key] as? NSNumber? else { throw ModelError.BadData }
        if let timestamp = timestamp {
            return NSDate(timeIntervalSince1970: timestamp.doubleValue)
        } else {
            return nil
        }
    }

    public func requiredDouble(key: String) throws -> Double {
        guard let value = values[key] as? NSNumber else { throw ModelError.BadData }
        return value.doubleValue
    }

    public func optionalDouble(key: String) throws -> Double? {
        guard let value = values[key] as? NSNumber? else { throw ModelError.BadData }
        return value?.doubleValue
    }

    public func optionalInt(key: String) throws -> Int? {
        guard let value = values[key] as? NSNumber? else { throw ModelError.BadData }
        return value?.integerValue
    }

    public func requiredBool(key: String) throws -> Bool {
        guard let value = values[key] as? NSNumber else { throw ModelError.BadData }
        return value.boolValue
    }

    public func optionalBool(key: String) throws -> Bool? {
        guard let value = values[key] as? NSNumber? else { throw ModelError.BadData }
        return value?.boolValue
    }

    public func requiredString(key: String) throws -> String {
        guard let value = values[key] as? String else { throw ModelError.BadData }
        return value
    }

    public func optionalString(key: String) throws -> String? {
        guard let value = values[key] as? String? else { throw ModelError.BadData }
        return value
    }

    public var debugDescription: String {
        return "{\(priority) \(values)}"
    }




}

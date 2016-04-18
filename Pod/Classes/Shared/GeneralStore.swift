//
//  GeneralStore.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 21/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation


//public typealias Filter = [String: AnyObject]

public class Filter {
    var conditions = [FilterCondition]()

    public init() {
    }

    public func between(column: String, value1: AnyObject, value2: AnyObject) -> Filter {
        conditions.append(BetweenFilterCondition(column: column, value1: value1, value2: value2))
        return self
    }

    public func equals(column: String, value: AnyObject) -> Filter {
        conditions.append(EqualsFilterCondition(column: column, value: value))
        return self
    }

    public func inValues(column: String, values: [AnyObject]) -> Filter {
        conditions.append(InFilterCondition(column: column, values: values))
        return self
    }

    public func removeInCondition() -> InFilterCondition? {
        for var i = 0; i < conditions.count; i++ {
            let condition = conditions[i]

            if let condition = condition as? InFilterCondition {
                conditions.removeAtIndex(i)
                return condition
            }
        }

        return nil
    }
}

//enum ConditionType {
//    case Equals
//    case GreaterThan
//    case LessThan
//    case Between
//    case In
//}

public class FilterCondition {
    var column: String

    init(column: String) {
        self.column = column
    }
}

public class EqualsFilterCondition: FilterCondition {
    public var value: AnyObject

    public init(column: String, value: AnyObject) {
        self.value = value
        super.init(column: column)
    }

}

public class BetweenFilterCondition: FilterCondition {
    public var value1: AnyObject
    public var value2: AnyObject

    init(column: String, value1: AnyObject, value2: AnyObject) {
        self.value1 = value1
        self.value2 = value2
        super.init(column: column)
    }
}

public class InFilterCondition: FilterCondition {
    public var values: [AnyObject]

    init(column: String, values: [AnyObject]) {
        self.values = values
        super.init(column: column)
    }
}


public class GeneralStore {
    var subscriptions = Set<StoreSubscription>()

    static var _instance: GeneralStore?
    public static var instance: GeneralStore { return GeneralStore._instance! }

    public var adapter: StoreAdapter!
    
    // MARK: - Lifecycle
    // -----------------------------------------------------------------------

    public init(adapter: StoreAdapter) {
        self.adapter = adapter
        GeneralStore._instance = self
    }
    
    // MARK: - Managing subscriptions
    // -----------------------------------------------------------------------

    public func addSubscription(subscription: StoreSubscription) {
        if subscriptions.contains(subscription) {
            fatalError("Cannot add subscription named \(subscription.name), already have one with same name.")
        }

        subscriptions.insert(subscription)
    }

    public func hasSubscription(subscription: StoreSubscription) -> Bool {
        return subscriptions.contains(subscription)
    }

    public func removeSubscription(subscription: StoreSubscription) {
        subscription.stop()
        subscriptions.remove(subscription)
    }
    
    public func subscriptionNamed(name: String) -> StoreSubscription? {
        return subscriptions.filter { $0.name == name }.first
    }
    
    // MARK: - Controlling subscriptions
    // -----------------------------------------------------------------------

    public func refreshAll() {
        for subscription in subscriptions {
            subscription.forceRefresh()
        }
    }

    public func stopAll() {
        for subscription in subscriptions {
            subscription.stop()
        }
    }

    public func startAll() {
        for subscription in subscriptions {
            subscription.start()
        }
    }

    public func create(path: String, id: String?, data: RecordData, callback: CreateCallback?) {
        adapter.create(path, id: id, data: data, callback: callback)
    }

    public func update(path: String, id: String, data: RecordData, callback: UpdateCallback?) {
        adapter.update(path, id: id, data: data, callback: callback)
    }

    public func find(path: String, id: String, callback: FindCallback) {
        print("Finding: \(path) / \(id)")

        adapter.find(path, id: id, callback: callback)
    }

    public func findOnce(path: String, filter: Filter, sort: String?, callback: StoreCallback) {
        adapter.loadNow(path, filter: filter, sort: sort, callback: callback)
    }

    public func delete(path: String, id: String, callback: DeleteCallback?) {
        adapter.delete(path, id: id, callback: callback)
    }
}

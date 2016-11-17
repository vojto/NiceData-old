//
//  GeneralStore.swift
//  Pomodoro Done
//
//  Created by Vojtech Rinik on 21/01/16.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation


//public typealias Filter = [String: AnyObject]

open class Filter {
    var conditions = [FilterCondition]()

    public init() {
    }

    open func between(_ column: String, value1: AnyObject, value2: AnyObject) -> Filter {
        conditions.append(BetweenFilterCondition(column: column, value1: value1, value2: value2))
        return self
    }

    open func equals(_ column: String, value: AnyObject) -> Filter {
        conditions.append(EqualsFilterCondition(column: column, value: value))
        return self
    }

    open func inValues(_ column: String, values: [AnyObject]) -> Filter {
        conditions.append(InFilterCondition(column: column, values: values))
        return self
    }

    open func removeInCondition() -> InFilterCondition? {
        for i in 0 ..< conditions.count {
            let condition = conditions[i]

            if let condition = condition as? InFilterCondition {
                conditions.remove(at: i)
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

open class FilterCondition {
    var column: String

    init(column: String) {
        self.column = column
    }
}

open class EqualsFilterCondition: FilterCondition {
    open var value: AnyObject

    public init(column: String, value: AnyObject) {
        self.value = value
        super.init(column: column)
    }

}

open class BetweenFilterCondition: FilterCondition {
    open var value1: AnyObject
    open var value2: AnyObject

    init(column: String, value1: AnyObject, value2: AnyObject) {
        self.value1 = value1
        self.value2 = value2
        super.init(column: column)
    }
}

open class InFilterCondition: FilterCondition {
    open var values: [AnyObject]

    init(column: String, values: [AnyObject]) {
        self.values = values
        super.init(column: column)
    }
}


open class GeneralStore {
    var subscriptions = Set<StoreSubscription>()

    static var _instance: GeneralStore?
    open static var instance: GeneralStore { return GeneralStore._instance! }

    open var adapter: StoreAdapter!
    
    // MARK: - Lifecycle
    // -----------------------------------------------------------------------

    public init(adapter: StoreAdapter) {
        self.adapter = adapter
        GeneralStore._instance = self
    }
    
    // MARK: - Managing subscriptions
    // -----------------------------------------------------------------------

    open func addSubscription(_ subscription: StoreSubscription) {
        if subscriptions.contains(subscription) {
            fatalError("Cannot add subscription named \(subscription.name), already have one with same name.")
        }

        subscriptions.insert(subscription)
    }

    open func hasSubscription(_ subscription: StoreSubscription) -> Bool {
        return subscriptions.contains(subscription)
    }

    open func removeSubscription(_ subscription: StoreSubscription) {
        subscription.stop()
        subscriptions.remove(subscription)
    }
    
    open func subscriptionNamed(_ name: String) -> StoreSubscription? {
        return subscriptions.filter { $0.name == name }.first
    }
    
    // MARK: - Controlling subscriptions
    // -----------------------------------------------------------------------

    open func refreshAll() {
        for subscription in subscriptions {
            subscription.forceRefresh()
        }
    }

    open func stopAll() {
        for subscription in subscriptions {
            subscription.stop()
        }
    }

    open func startAll() {
        for subscription in subscriptions {
            subscription.start()
        }
    }

    open func create(_ path: String, id: String?, data: RecordData, callback: CreateCallback?) {
        let id = adapter.create(path, id: id, data: data, callback: callback)
        
        UndoManager.instance.trackCreate(path, id: id)
    }

    open func update(_ path: String, id: String, data: RecordData, callback: UpdateCallback?) {
        adapter.update(path, id: id, data: data, callback: callback)
    }

    open func find(_ path: String, id: String, callback: @escaping FindCallback) {
        print("Finding: \(path) / \(id)")

        adapter.find(path, id: id, callback: callback)
    }

    open func findOnce(_ path: String, filter: Filter, sort: String?, callback: @escaping StoreCallback) {
        adapter.loadNow(path, filter: filter, sort: sort, callback: callback)
    }

    open func delete(_ path: String, id: String, callback: DeleteCallback?) {
        adapter.delete(path, id: id, callback: callback)
    }
}

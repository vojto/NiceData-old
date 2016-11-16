//
//  UndoManager.swift
//  FocusList
//
//  Created by Vojtech Rinik on 15/11/2016.
//  Copyright © 2016 Vojtech Rinik. All rights reserved.
//

import Foundation
import NiceData

enum UndoOperation {
    case create(path: String, id: String)
    case update(path: String, id: String, valuesBefore: RecordValues)
}

/*
enum UndoOperationType {
    case create
    case remove
}

struct UndoOperation {
    let type: UndoOperationType
    let path: String
    let id: String
    let data: RecordData?
}
 */

class UndoGroup {
    var operations = [UndoOperation]()
}

public class UndoManager {
    public static let instance = UndoManager()
    
    var trackedGroups = [UndoGroup]()
    var currentGroup: UndoGroup?
    
    public func track(block: (() -> ())) {
        
        currentGroup = UndoGroup()
        
        block()
        
        trackedGroups.append(currentGroup!)
        
        currentGroup = nil
    }
    
    func track(_ op: UndoOperation) {
        if let group = currentGroup {
            group.operations.append(op)
        }
    }
    
    func trackCreate(path: String, id: String) {
        let op = UndoOperation.create(path: path, id: id)
        self.track(op)
    }
    
    
    // Updates aren't tracked automatically from Store, gotta track them 
    // from UI code.
    public func trackUpdate(path: String, id: String, valuesBefore: RecordValues) {
        let op = UndoOperation.update(path: path, id: id, valuesBefore: valuesBefore)
        self.track(op)
        
    }
    
    public func undo() {
        guard trackedGroups.count > 0 else {
            return
        }
        
        let group = trackedGroups.removeLast()
        
        for op in group.operations {
            self.undoOp(op)
        }
    }
    
    func undoOp(_ op: UndoOperation) {
        let store = GeneralStore.instance
        
        switch op {
        case .create(let path, let id):
            store.delete(path, id: id, callback: nil)
            
            break
        case .update(let path, let id, let valuesBefore):
            let data = RecordData(values: valuesBefore, priority: nil)
            store.update(path, id: id, data: data, callback: nil)
        }
    }
}
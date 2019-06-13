////
////  Store.swift
////  Counters
////
////  Created by Petr Šíma on 09/06/2019.
////  Copyright © 2019 Petr Šíma. All rights reserved.
////
//
//import Foundation
//
////@dynamicMemberLookup
//@propertyWrapper struct W<Value> {
//    init(initialValue: Value) {
//        storage = initialValue
//    }
//    private var storage: Value
//    
//    var value: Value {
//        get { storage }
//        set {
//            dirtyKeyPaths.append(\Value.self)
//            storage = newValue
//        }
//    }
////
////    subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property{
////        get {
////            print("get")
////            return storage[keyPath: keyPath]
////        }
////        set {
////            print("set \(newValue) on \(storage)")
////            print(keyPath)
////            print(keyPath == \String.self)
////            dirtyKeyPaths.append(keyPath)
////            storage[keyPath: keyPath] = newValue
////        }
////    }
//}
//
//var dirtyKeyPaths: [AnyKeyPath] = []
//
//struct AppState {
//    @W var counter: Counter = Counter()
//    @W var counters: [Counter] = [Counter()]
//}
//struct Counter {
//    @W var name: String = "beers today"
//}
//
//
//let playground: () -> Void = {
//    var s = AppState()
//    s.counter.name = "foo"
//    
//    print(dirtyKeyPaths.contains(\Counter.self))
//}

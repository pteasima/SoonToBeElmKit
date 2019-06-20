import Foundation
import Combine
import SwiftUI

final class Program<State, Action, Effects> {
    let viewStore: ObjectBinding<ViewStore<State, Action>>
    @ReadOnce var rerender = true
    @ReadOnce var transaction: Transaction? = nil
    
    private var state: State
    private var queue : [Action] = []
    private var dispatch: ((Action) -> Void)!
    private var recursiveDispatch: ((Action) -> Void)!
    private var subscriptions: [(Subscription<Effects, Action>, AnyCancellable)] = []//subscriptions we've already fired and may want to cancel
    
    
    init(initialState: State, initialCommands: [Command<State, Action, Effects>], update: @escaping (inout State, Action) -> [Command<State, Action, Effects>], subscriptions: @escaping (State) -> [Subscription<Effects, Action>], effects: Effects) {
        state = initialState
        viewStore = { fatalError() }()
        
        recursiveDispatch = { [unowned self] action in
            assert(!self.queue.isEmpty) //recursiveDispatch should only be call when queue isnt empty
            self.queue.append(action) //just append to queue, it will be processed by the while loop in dispatch
        }
        dispatch = { [unowned self] action in
            assert(self.queue.isEmpty) //dispatch should only be called when idle
            self.queue.append(action)
            while !self.queue.isEmpty {
                let currentAction = self.queue.first!
                let cmds = update(&self.state, currentAction)
                cmds.forEach {
                    switch $0 {
                    case let .internal(modify):
                        modify(self)
                    case let .effect(effect):
                        //TODO: dont ignore the cancellables, store them and cancel on deinit. Then we can replace weak below with unowned
                        _ = effect(effects).sink { [weak self] in
                            guard let self = self else { return }
                            if self.queue.isEmpty {
                                self.dispatch($0)
                            } else {
                                self.recursiveDispatch($0)
                            }
                        }
                    }
                }
                self.queue.removeFirst()
            }
            assert(self.queue.isEmpty) // we got here so everything should be processed.
            
            //we only fire subscriptions once all recursive dispatches from commands have been processed. No point firing subscriptions for the intermediate states. This is a design decision and doing otherwise could change the Program's behavior (when we have cold subscriptions that dispatch immediately)
            let subs = subscriptions(self.state)
            let subsDiff = self.subscriptions.map { $0.0 }.difference(from: subs)
            subsDiff.forEach { change in
                switch change {
                case let .insert(offset: offset, element: element, associatedWith: associatedWith):
                    break
//                    self.subscriptions.insert(element, at: <#T##Int#>)
                case let .remove(offset: offset, element: element, associatedWith: associatedWith):
                    break
                }
            }
//            subs.forEach {
//                _ = $0.perform(effects).sink { [weak self] in
//                    guard let self = self else { return }
//                    if self.queue.isEmpty {
//                        self.dispatch($0)
//                    } else {
//                        self.recursiveDispatch($0)
//                    }
//                }
//            }
            
            
        }
    }
}

// a property that flips back to its default value when it is read
// TODO: does this have proper value semantics with the class inside? And do we even care?
@propertyWrapper struct ReadOnce<Value> {
    init(initialValue: Value) {
        defaultValue = initialValue
        box = ValueBox(value: initialValue)
    }
    private let defaultValue: Value
    final class ValueBox {
        init(value: Value) { self.value = value }
        var value: Value
    }
    private var box: ValueBox
    var value: Value {
        get {
            let result = box.value
            box.value = defaultValue
            return result
        }
        set {
            box.value = newValue
        }
    }
}
//enum App {
//    struct State {
//        var value: Int = 42
//    }
//    enum Action {
//        case increment
//        case decrement
//    }
//    static func update(state: inout State, action: Action) -> [Command<Effects, Action>] {
//        switch action {
//        case .increment:
//            state.value += 1
//            return [
//                Command(\.http.get, URL(string: "www.google.com")!) { _ in .increment }
//            ]
//
//        case .decrement:
//            state.value -= 1
//            return []
//        }
//    }
//
//    static func subscriptions(state: State) -> [Subscription<Effects, Action>] {
//        return []
//    }
//
//}

//let runApp: () -> Void = {
//    let p = Program(initialState: App.State(), initialCommands: [], update: App.update, subscriptions: App.subscriptions, effects: Effects())
//}

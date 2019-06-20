import Foundation
import Combine
import SwiftUI

final class Program<State, Action> {
    let viewStore: ObjectBinding<ViewStore<State, Action>>
    @ReadOnce var rerender = true
    @ReadOnce var transaction: Transaction? = nil
    init<Effects>(initialState: State, initialCommands: [Command<Effects, Action, State>], update: @escaping (inout State, Action) -> [Command<Effects,Action, State>], subscriptions: @escaping (State) -> [Subscription<Effects, Action>], effects: Effects) {
        let input = PassthroughSubject<Action, Never>()
//        let frames: AnyPublisher<Frame, Never> = input
//            .reduce((initialState, [], [])) { frame, action in
//                var newState = frame.state
//                let cmds = update(&newState, action)
//                let subs = subscriptions(newState)
//                frame.subscriptions
//                return (newState, cmds, subs)
//
//        }
//        .eraseToAnyPublisher()
        viewStore = { fatalError() }()
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

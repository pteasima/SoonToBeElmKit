import Foundation
import Combine

final class ViewStore<State> { } //TODO:

final class Program<State, Action> {
    init(initialState: State, update: @escaping (inout State, Action) -> [Command<Action>], subscriptions: @escaping (State) -> [Subscription<Action>]/*, view: (ViewStore<State>) -> ()*/) {
        fatalError()
    }
    
}

enum App {
    struct State {
        var value: Int = 42
    }
    enum Action {
        case increment
        case decrement
    }
    static func update(state: inout State, action: Action) -> [Command<Action>] {
        switch action {
        case .increment:
            state.value += 1
            return []
        case .decrement:
            state.value -= 1
            return []
        }
    }
    
    static func subscriptions(state: State) -> [Subscription<Action>] {
        return []
    }

}

let runApp: () -> Void = {
    let p = Program(initialState: App.State(), update: App.update, subscriptions: App.subscriptions)
}

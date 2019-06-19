import Foundation
import Combine

final class Program<State, Action, Effects> {
    typealias Cmd = Command<Effects, Action>
    typealias Sub = Subscription<Effects, Action>
    private typealias Frame = (state: State, commands: [Cmd], subscriptions: [Sub])
    init(initialState: State, initialCommands: [Cmd], update: @escaping (inout State, Action) -> [Cmd], subscriptions: @escaping (State) -> [Sub], effects: Effects) {
        let input = PassthroughSubject<Action, Never>()
        let frames: AnyPublisher<Frame, Never> = input
            .reduce((initialState, [], [])) { frame, action in
                var newState = frame.state
                let cmds = update(&newState, action)
                let subs = subscriptions(newState)
                frame.subscriptions
                return (newState, cmds, subs)

        }
        .eraseToAnyPublisher()
        
        
//        let state = CurrentValueSubject<(State, [], Never>(initialState)
//        state.red
//        self._state = state
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
    static func update(state: inout State, action: Action) -> [Command<Effects, Action>] {
        switch action {
        case .increment:
            state.value += 1
            return [
                Command(\.http.get, URL(string: "www.google.com")!) { _ in .increment }
            ]

        case .decrement:
            state.value -= 1
            return []
        }
    }

    static func subscriptions(state: State) -> [Subscription<Effects, Action>] {
        return []
    }

}

let runApp: () -> Void = {
    let p = Program(initialState: App.State(), initialCommands: [], update: App.update, subscriptions: App.subscriptions, effects: Effects())
}

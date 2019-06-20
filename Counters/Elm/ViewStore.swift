import SwiftUI
import Combine

typealias Store<State, Action> = ObjectBinding<ViewStore<State, Action>>

final class ViewStore<State, Action>: BindableObject {
    let didChange = PassthroughSubject<(), Never>()
    init(state: State, dispatch: @escaping (Action) -> Void) {
        self.state = state
        self.dispatch = dispatch
    }
    var state: State {
        didSet {
            didChange.send(())
        }
    }
    let dispatch: (Action) -> Void
}

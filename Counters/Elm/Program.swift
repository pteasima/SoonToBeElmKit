import Foundation
import Combine
import SwiftUI

final class Program<State, Action, Effects> {
    let viewStore: ObjectBinding<ViewStore<State, Action>>
    var rerender = true
    var transaction: Transaction?
    
    private var state: State
    private var isIdle = true
    private var queue : [Action] = []
    private var dispatch: ((Action) -> Void)!
    private var subscriptions: [(subscription: Subscription<Effects, Action>, cancellable: AnyCancellable)] = []//subscriptions we've already fired and may want to cancel
    
    private var commandCancellables: [AnyCancellable] = []
    init(initialState: State, initialCommands: [Command<State, Action, Effects>], update: @escaping (inout State, Action) -> [Command<State, Action, Effects>], subscriptions: @escaping (State) -> [Subscription<Effects, Action>], effects: Effects) {
        state = initialState
        viewStore = { fatalError() }()
        
        
        dispatch = { [weak self] action in
            guard let self = self else { assertionFailure("if I properly managed all cancellables, a dispatch on a dead Program would never happen"); return }
            self.queue.append(action)
            if self.isIdle { //only start the processing while-loop once. If not idle, then this is a recursive dispatch and we just need to enqueue it.
                self.isIdle = false
                defer {
                    self.isIdle = true
                    //these may have been modified by .internal Commands. Reset them when done
                    self.rerender = true
                    self.transaction = nil
                }
                while !self.queue.isEmpty {
                    let currentAction = self.queue.removeFirst()
                    let cmds = update(&self.state, currentAction)
                    cmds.forEach {
                        switch $0 {
                        case let .internal(modify):
                            modify(self)
                        case let .effect(effect):
                            var cancellable: AnyCancellable?
                            cancellable = AnyCancellable(effect(effects).sink(receiveCompletion: { [weak self] _ in
                                //commandCancellables shouldnt grow indefinitelly, so we remove the cancellable on completion
                                // TODO: removeFirst(where:)
                                self?.commandCancellables.removeAll { $0 === cancellable }
                            },receiveValue: self.dispatch))
                            self.commandCancellables.append(cancellable!)
                        }
                    }
                    let subs = subscriptions(self.state)
                    // we cant do a collection.difference here, since that can produce .inserts and .removes for reordering
                    // we dont care about order, just cancel and remove old ones and append new ones
                    self.subscriptions.forEach { oldSub in
                        if !subs.contains(oldSub.subscription) {
                            oldSub.cancellable.cancel()
                            // TODO: removeFirst(where:)
                            self.subscriptions.removeAll { $0.subscription == oldSub.subscription }
                        }
                    }
                    subs.forEach { newSub in
                        if !self.subscriptions.contains(where: { $0.subscription == newSub }) {
                            let cancellable = AnyCancellable(newSub.perform(effects).sink(receiveValue: self.dispatch))
                            self.subscriptions.append((newSub, cancellable))
                        }
                    }
                }
                
                if self.rerender {
                    // update the view
                    let storeToState: ReferenceWritableKeyPath<ViewStore<State, Action>, State> = \.state
                    if let transaction = self.transaction {
                        self.viewStore.delegateValue[dynamicMember: storeToState].transaction(transaction).value = self.state
                    } else {
                        self.viewStore.delegateValue[dynamicMember: storeToState].value = self.state
                    }
                    
                }
                
            }
            
            
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

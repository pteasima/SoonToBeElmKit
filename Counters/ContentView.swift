import SwiftUI
import Combine

final class P {
    let store: Store<ExampleApp.State, ExampleApp.Action> = ObjectBinding(initialValue: ExampleApp.theStore)
    func dispatch(_ action: ExampleApp.Action, transaction: Transaction? = nil) {
        print("jo \(action)")
        let storeToState: ReferenceWritableKeyPath<ViewStore<ExampleApp.State, ExampleApp.Action>, ExampleApp.State> = \.state
        self.store.delegateValue[dynamicMember: storeToState].transaction(transaction!).value = ExampleApp.State(isOn: false)
//        self.store.delegateValue[dynamicMember: storeToState].animation().value = ExampleApp.State(isOn: false)
    }
}
var p = P()

typealias Store<State, Action> = ObjectBinding<ViewStore<State, Action>>

final class ViewStore<State, Action>: BindableObject {
    let didChange = PassthroughSubject<(), Never>()
    init(state: State) {
        self.state = state
    }
    var state: State {
        didSet {
            didChange.send(())
        }
    }
    func dispatch(_ action: Action, transaction: Transaction? = nil) {
        p.dispatch(action as! ExampleApp.Action, transaction: transaction)
    }
}

@dynamicMemberLookup protocol ElmView: View {
    associatedtype State
    associatedtype Action
    var store: ObjectBinding<ViewStore<State, Action>> { get }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> (@escaping (Subject) -> Action) -> Binding<Subject> { get }
}
extension ElmView {
    func dispatch(_ action: Action, transaction: Transaction? = nil) {
        store.value.dispatch(action, transaction: transaction)
    }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> (@escaping (Subject) -> Action) -> Binding<Subject> {
        let storeToState: ReferenceWritableKeyPath<ViewStore<State, Action>, State> = \.state
        let storeToSubject = storeToState.appending(path: keyPath)
        return { transform in
            Binding(getValue: {
            self.store.delegateValue[dynamicMember: storeToSubject].value
            }, setValue: { newValue, transaction in
                self.dispatch(transform(newValue), transaction: transaction)
                //without `transaction`, animated Bindings wouldnt animate. Using transaction like this seems to be the right way to "compose Bindings"
//                self.store.delegateValue[dynamicMember: storeToSubject].transaction(transaction).value = newValue
//                self.store.delegateValue[dynamicMember: storeToState].transaction(transaction).value = ExampleApp.State(isOn: newValue as! Bool) as! State
        })
            
        }
        
        
    }
}

enum ExampleApp {
    struct State {
        var isOn: Bool = true
    }
    enum Action {
        case none
    }
    static let theStore = ViewStore<State, Action>(state: State())
}

struct ContentView : ElmView {
    let store: Store<ExampleApp.State, ExampleApp.Action>
    
    var body: some View {
        VStack {
            V2(store: store)
            V2(store: store)
            List(0...100) { _ in
                Toggle(isOn: self.isOn { _ in .none }.animation()) {
                    Text("is it on?")
                }
            }
        }
    }
}

struct V2: ElmView {
    let store: Store<ExampleApp.State, ExampleApp.Action>
    
    var body: some View {
        VStack {
            Toggle(isOn: self.isOn { _ in .none }.animation()) {
                Text("v2 is it on?")
            }
            Toggle(isOn: self.isOn { _ in .none }.animation()) {
                Text("v22 is it on?")
            }
        }
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(store: ObjectBinding(initialValue: ExampleApp.theStore))
    }
}
#endif






//final class Store<State, Action> {
//    func dispatch(_ action: Action) {
//        _ = output.receive(action)
//    }
//    let output: AnySubscriber<Action, Never>
//    let cancellable =
//    init(input: AnyPublisher<State, Never>, output: AnySubscriber<Action, Never>) {
//        self.output = output
//        input.assign(to: \.state, on: self)
//    }
//    var state: State!
//}


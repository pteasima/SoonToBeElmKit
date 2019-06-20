import SwiftUI
import Combine

final class P {
    let store: Store<ExampleApp.State, ExampleApp.Action> = ObjectBinding(initialValue: ExampleApp.theStore)
    func dispatch(_ action: ExampleApp.Action, transaction: Transaction? = nil) {
        print("jo \(action)")
        print(transaction, transaction?.disablesAnimations, transaction?.animation, transaction?.isContinuous)
 
        switch action {
        case .none:
            break
        case .toggle(let newValue):
            state.isOn = newValue
        case .onDrag(let newX):
            state.dragged = newX
        }
//        self.store.delegateValue[dynamicMember: storeToState].transaction(transaction!).value = state
        let storeToState: ReferenceWritableKeyPath<ViewStore<ExampleApp.State, ExampleApp.Action>, ExampleApp.State> = \.state
        self.store.delegateValue[dynamicMember: storeToState].animation().value = state
    }
    var state: ExampleApp.State = .init()
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
        var dragged: Double = 0.0
    }
    enum Action {
        case none
        case toggle(Bool)
        case onDrag(Double)
    }
    
    static func update(state: inout State, action: Action) -> [Command<Effects, Action, State>] {
        switch action {
        case .none:
            return [
//                Command(\.http.get, URL(string: "www.google.com")!) { _ in .increment }
            ]
        case .toggle(let newValue):
            state.isOn = newValue
            return []
        case .onDrag(let newX):
            state.dragged = newX
            return []
        }
    }
    
    static func subscriptions(state: State) -> [Subscription<Effects, Action>] {
        return []
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
//            Slider(value: self.sliderValue { _ in .none })
            Toggle(isOn: self.isOn { .toggle($0)  }.animation()) {
                Text("v2 is it on?")
            }
            Toggle(isOn: self.isOn { .toggle($0) }.animation()) {
                Text("v22 is it on?")
            }
//            Text("\(self.dragged.value)")
        }
            .gesture(
            DragGesture()
                .onChanged { value in
                    self.dispatch(.onDrag(Double(value.location.x)))
                }
        )
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(store: ObjectBinding(initialValue: ExampleApp.theStore))
    }
}
#endif

import SwiftUI
import Combine

@dynamicMemberLookup protocol ElmView: View {
    associatedtype State
    associatedtype Action
    var store: ObjectBinding<ViewStore<State, Action>> { get }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> (@escaping (Subject) -> Action) -> Binding<Subject> { get }
}
extension ElmView {
    func dispatch(_ action: Action) {
        store.value.dispatch(action)
    }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> (@escaping (Subject) -> Action) -> Binding<Subject> {
        let storeToState: ReferenceWritableKeyPath<ViewStore<State, Action>, State> = \.state
        let storeToSubject = storeToState.appending(path: keyPath)
        return { transform in
            Binding(getValue: {
            self.store.delegateValue[dynamicMember: storeToSubject].value
            }, setValue: { newValue, transaction in
                self.dispatch(transform(newValue))
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
    
    static func update(state: inout State, action: Action) -> [Command<State, Action, Effects>] {
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
        Text("no preview")
//        ContentView(store: ObjectBinding(initialValue: ExampleApp.theStore))
    }
}
#endif

import SwiftUI
import Combine

typealias Store<State, Action> = ObjectBinding<ViewStore<State>>
final class ViewStore<State>: BindableObject {
    let didChange = PassthroughSubject<(), Never>()
    init(state: State) {
        self.state = state
    }
    var state: State {
        didSet {
            //this nesting ensures didChange is always triggered. And, with @dynamicMemberLookup we'll get rid of `.state` nesting everywhere
            didChange.send(())
        }
    }
}

// this isnt very Elm-y (yet!), its just a View that has a single Store
@dynamicMemberLookup protocol ElmView: View {
    associatedtype State
    var store: ObjectBinding<ViewStore<State>> { get }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> Binding<Subject> { get }
}
extension ElmView {
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> Binding<Subject> {
        let storeToState: ReferenceWritableKeyPath<ViewStore<State>, State> = \.state
        let storeToSubject = storeToState.appending(path: keyPath)
        return Binding(getValue: {
            self.store.delegateValue[dynamicMember: storeToSubject].value
            }, setValue: { newValue, transaction in
                //without `transaction`, animated Bindings wouldnt animate. Using transaction like this seems to be the right way to "compose Bindings"
                self.store.delegateValue[dynamicMember: storeToSubject].transaction(transaction).value = newValue
        })
        
        
    }
}

enum ExampleApp {
    struct State {
        var isOn: Bool = true
    }
    static let theStore = ViewStore(state: State())
}

struct ContentView : ElmView {
    let store: Store<ExampleApp.State, Never>
    
    var body: some View {
        List(0...100) { _ in
            Toggle(isOn: self.isOn.animation()) {
                Text("is it on?")
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


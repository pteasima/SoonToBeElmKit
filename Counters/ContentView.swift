import SwiftUI
import Combine

final class Store<State>: BindableObject {
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
    var store: ObjectBinding<Store<State>> { get }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> Binding<Subject> { get }
}
extension ElmView {
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> Binding<Subject> {
        let storeToState: ReferenceWritableKeyPath<Store<State>, State> = \.state
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
    static let theStore = Store(state: State())
}

struct ContentView : ElmView {
    //we have one store per app, but each View needs its own ObjectBinding
    let store = ObjectBinding(initialValue: ExampleApp.theStore)
    
    var body: some View {
        List(0...100) { _ in
            //Bindings to all State properties are accessible on `self`
            Toggle(isOn: self.isOn.animation()) {
                Text("is it on?")
            }
        }
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
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


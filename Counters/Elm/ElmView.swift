import SwiftUI

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
            })
        }
    }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<State, Subject>) -> (@escaping (Subject, Transaction?) -> Action) -> Binding<Subject> {
        let storeToState: ReferenceWritableKeyPath<ViewStore<State, Action>, State> = \.state
        let storeToSubject = storeToState.appending(path: keyPath)
        return { transform in
            Binding(getValue: {
                self.store.delegateValue[dynamicMember: storeToSubject].value
            }, setValue: { newValue, transaction in
                self.dispatch(transform(newValue, transaction))
            })
        }
    }
}

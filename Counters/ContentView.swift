import SwiftUI
import Combine

enum ExampleApp {
    struct State {
        var isOn: Bool = true
        var dragged: Double = 0.0
    }
    enum Action {
        case none
        case toggle(Bool)
        case toggleWithTransaction(Bool, Transaction?)
        case onDrag(Double)
        case tick
    }
    
    static func update(state: inout State, action: Action) -> [Command<State, Action, Effects>] {
        switch action {
        case .none:
            return [
                .dontRerender // this means the toggle that triggered it will stay flipped to the wrong state
            ]
        case .toggle(let newValue):
            state.isOn = newValue
            return [
//                .setTransaction(Transaction(animation: .default))
            ]
        case let .toggleWithTransaction(newValue, transaction):
            state.isOn = newValue
            return [
                transaction.map { .setTransaction($0) }
                ].compactMap { $0 }
        case .onDrag(let newX):
            state.dragged = newX
            return []
        case .tick:
            state.isOn.toggle()
            return [
                .setTransaction(Transaction(animation: .default))
            ]
        }
    }
    
    static func subscriptions(state: State) -> [Subscription<Effects, Action>] {
        return [.init(\.clock.repeatedTimer, 5, \.tick)]
    }
}
extension Date {
    var tick: ExampleApp.Action {
        .tick
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
            Toggle(isOn: self.isOn { .toggle($0)  }) {
                Text("v2 is it on?")
            }
            Toggle(isOn: self.isOn { .toggleWithTransaction($0,$1) }.animation()) {
                Text("here, the view supplies the animation")
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

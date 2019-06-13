import SwiftUI
import Combine

@propertyWrapper struct Wrap<A> {
    init(initialValue: A) {
        self.value = value
    }
    
    var value: A
    
}

struct Foo {
    @Wrap var foo: String
}



struct ContentView : View {
    var body: some View {
Text("foo")
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

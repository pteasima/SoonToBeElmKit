import SwiftUI
import Combine


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

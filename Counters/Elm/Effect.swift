import Foundation
import Combine


protocol Effect {
    associatedtype Output
    
    static var perform: (Self) -> AnyPublisher<Output, Never> { get }
}

struct Get: Effect {
    typealias Output = (Data?, URLResponse?, Error?)
    
    let url: URL
    
    
    static var perform: (Self) -> AnyPublisher<(Data?, URLResponse?, Error?), Never> = { params in
        /*var task: URLSessionDataTask?
        return Publishers.Future { callback in
            task = URLSession.shared.dataTask(with: params.url) { data, response, error in
                callback(.success((data, response, error)))
            }
            task?.resume()
            }
            .handleEvents(receiveCancel: {
                task?.cancel()
            })
            .eraseToAnyPublisher()*/
    }
}

struct Observe: Effect, Equatable {
    typealias Output = Data
    
    let path: String
    
    static var perform: (Self) -> AnyPublisher<Data, Never> = { params in
        fatalError("Firestore.observe...")
    }
}


struct Command<Action> {
    let perform: AnyPublisher<Action, Never>
    init<E>(_ effect: E, transform: @escaping (E.Output) -> Action) where E: Effect {
        perform = E.perform(effect).map(transform).eraseToAnyPublisher()
    }
}

extension Effect {
    func map<A>(transform: @escaping (Output) -> A) -> Command<A> {
        return Command(self, transform: transform)
    }
}

struct Subscription<Action>: Equatable {
    let perform: AnyPublisher<Action, Never>
    private let data: (params: Any, transform: AnyKeyPath)
    private let eq: (Subscription) -> Bool
    init<E>(_ effect: E, transform: KeyPath<E.Output, Action>) where E: Effect, E: Equatable {
        perform = E.perform(effect).map { $0[keyPath: transform ] }.eraseToAnyPublisher()
        data = (effect, transform)
        eq = { other in effect == other.data.params as? E && transform == other.data.transform }
    }
    static func ==(lhs: Subscription, rhs: Subscription) -> Bool {
        return lhs.eq(rhs)
    }
}

extension Effect where Self: Equatable {
    func map<A>(_ transform: KeyPath<Output, A>) -> Subscription<A> {
        return Subscription(self, transform: transform)
    }
}

enum A {
    case none
}
let pg: () -> Void = {
//    let x = Command<A>(Get(url: URL(string: "www.google.com")!)) {
//        _ in .none
//    }
    let x = Get(url: URL(string: "www.google.com")!).map {
        _ in A.none
    }
    
    let s = Observe(path: "/counters").map(\.countersFromFirestoreSnapshot)
    
}

struct Counter {}
extension Observe.Output {
    var countersFromFirestoreSnapshot: [Counter] {
        fatalError()
    }
}

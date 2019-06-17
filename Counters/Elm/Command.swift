import Foundation
import Combine

protocol Effect {
    associatedtype Action
    associatedtype Params
    
    var params: Params { get }
    static var perform: (Params) -> AnyPublisher<Action, Never> { get }
}

func batch<E1, E2>(_ e1: E1, _ e2: E2) -> AnyEffect<E1.Action> where E1: Effect, E2: Effect, E1.Action == E2.Action {
    return AnyEffect(perform: Publishers.Merge(e1.perform, e2.perform).eraseToAnyPublisher())
}

extension Effect {
    var perform: AnyPublisher<Action, Never> {
        return Self.perform(self.params).eraseToAnyPublisher()
    }
}

struct AnyEffect<Action> {
    var perform: AnyPublisher<Action, Never>
}

struct Get<Action>: Effect {
    struct Params {
        let url: URL
        let action: (Data?, URLResponse?, Error?) -> Action
    }
    let params: Params
    //TODO: test
    static var perform: (Get<Action>.Params) -> AnyPublisher<Action, Never> {
        { params in
            var task: URLSessionDataTask?
            return Publishers.Future { callback in
                task = URLSession.shared.dataTask(with: params.url) { (data, response, error) in
                    callback(.success(params.action(data, response, error)))
                }
                task?.resume()
                
            }
                .handleEvents(receiveCancel: {
                        task?.cancel()
                })
                .eraseToAnyPublisher()
        }
    }
}

let playground: () -> Void = {
    enum A {
        case none
    }
    let g = Get<A>(params: .init(url: URL(string: "www.google.com")!) { _,_,_  in
        .none
    })
    
    let b = batch(
        g,
        g
    )
}

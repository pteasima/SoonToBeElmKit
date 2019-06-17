import Foundation
import Combine

protocol Effect {
    associatedtype Action
    associatedtype Params
    
    var params: Params { get }
    static var perform: (Params) -> AnyPublisher<Action, Never> { get }
}

extension Effect {
    func eraseToAnyEffect() -> AnyEffect<Action> {
        AnyEffect(perform: Self.perform(self.params))
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
    
    let anyG = g.eraseToAnyEffect()
}

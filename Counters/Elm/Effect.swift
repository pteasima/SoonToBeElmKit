import Foundation
import Combine

struct Effects {
    var http: HTTP = .init()
}
struct HTTP {
    var get: (URL) -> AnyPublisher<Data, Never> = { url in
        var task: URLSessionDataTask?
        return Publishers.Future { callback in
            task = URLSession.shared.dataTask(with: url) { data, response, error in
                callback(.success(data!))
            }
            task?.resume()
            }
            .handleEvents(receiveCancel: {
                task?.cancel()
            })
            .eraseToAnyPublisher()
    }
}

struct Command<Effects, Action> {
    let perform: (Effects) -> AnyPublisher<Action, Never>
    init<Input, Output>(_ keyPath: KeyPath<Effects, (Input) -> AnyPublisher<Output, Never>>, _ input: Input, _ transform: @escaping (Output) -> Action) {
        perform = { effects in
            effects[keyPath: keyPath](input).map(transform).eraseToAnyPublisher()
        }
    }
}

struct Subscription<Effects, Action>: Equatable {
    let perform: (Effects) -> AnyPublisher<Action, Never>
    private let data: (keyPath: AnyKeyPath, input: Any, transform: AnyKeyPath)
    private let eq: (Subscription) -> Bool
    init<Input: Equatable, Output>(_ keyPath: KeyPath<Effects, (Input) -> AnyPublisher<Output, Never>>, _ input: Input, _ transform: KeyPath<Output, Action>) {
        perform = { effects in
            effects[keyPath: keyPath](input).map { $0[keyPath: transform] }.eraseToAnyPublisher()
        }
        data = (keyPath, input, transform)
        eq = { other in keyPath == other.data.keyPath && input == other.data.input as? Input && transform == other.data.transform }
    }
    
    static func ==(lhs: Subscription, rhs: Subscription) -> Bool {
        lhs.eq(rhs)
    }
}



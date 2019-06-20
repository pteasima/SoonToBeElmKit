import Foundation
import Combine
import SwiftUI

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

//TODO: explore how we can use StaticMember to hide the cases but still keep leading dot syntax
// alternativelly, consider hiding the cases in a RawCommand type thats only accessible to Program
//TODO: nest Command in Program since it has all the same generic params?
enum Command<State, Action, Effects> {
    case effect((Effects) -> AnyPublisher<Action, Never>) //external effect
    case `internal`((Program<State, Action, Effects>) -> Void) //used to modify internal state of the Program, e.g. to disable rerender or set Transaction for rerender
    
    init<Input, Output>(_ keyPath: KeyPath<Effects, (Input) -> AnyPublisher<Output, Never>>, _ input: Input, _ transform: @escaping (Output) -> Action) {
        self = .effect { effects in
            effects[keyPath: keyPath](input).map(transform).eraseToAnyPublisher()
        }
    }
    
    static var dontRerender: Command {
        return .internal { $0.rerender = false }
    }
    static func setTransaction(_ transaction: Transaction) -> Command {
        return .internal { $0.transaction = transaction }
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



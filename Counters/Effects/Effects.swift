import Foundation
import Combine

struct Effects {
    var http: HTTP = .init()
    var clock: Clock = .init()
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

struct Clock {
    //TODO: use UnitDuration or whatever is the current Swift way of representing time
    var repeatedTimer: (TimeInterval) -> AnyPublisher<Date, Never> = { interval in
        let subject = PassthroughSubject<Date, Never>()
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            subject.send(timer.fireDate)
        }
        return subject.eraseToAnyPublisher()
    }
}

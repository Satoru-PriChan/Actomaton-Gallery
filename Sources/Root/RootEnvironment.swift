import UIKit
import Stopwatch
import GitHub
import GameOfLife

public struct RootEnvironment
{
    let getDate: () -> Date
    let timer: (TimeInterval) -> AsyncStream<Date>
    let fetchRequest: (URLRequest) async throws -> Data

    let gameOfLife: GameOfLife.Root.Environment
}

// MARK: - Live Environment

extension RootEnvironment
{
    public static var live: RootEnvironment
    {
        RootEnvironment(
            getDate: { Date() },
            timer: { timeInterval in
                Timer.publish(every: timeInterval, tolerance: timeInterval * 0.1, on: .main, in: .common)
                    .autoconnect()
                    .toAsyncStream()

                // Warning: Using `Task.sleep` may not be accurate timer.
//                AsyncStream { continuation in
//                    let task = Task {
//                        while true {
//                            if Task.isCancelled { break }
//                            await Task.sleep(UInt64(timeInterval * 1_000_000_000))
//                            continuation.yield(Date())
//                        }
//                    }
//                    continuation.onTermination = { @Sendable _ in
//                        task.cancel()
//                    }
//                }
            },
            fetchRequest: { urlRequest in
                if #available(iOS 15.0, *) {
                    let (data, _) = try await URLSession.shared.data(for: urlRequest, delegate: nil)
                    return data
                } else {
                    let task = Task<Data, Swift.Error> {
                        let data: Data = try await withUnsafeThrowingContinuation { continuation in
                            let sessionTask = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
                                if let data = data {
                                    continuation.resume(returning: data)
                                }
                                else if let error = error {
                                    continuation.resume(throwing: error)
                                }
                                else {
                                    fatalError("Should never reahc here")
                                }
                            }
                            sessionTask.resume()
                        }
                        return data
                    }

                    let data = try await withTaskCancellationHandler {
                        try await task.value
                    } onCancel: {
                        task.cancel()
                    }

                    return data
                }
            },
            gameOfLife: .live
        )
    }
}

extension RootEnvironment
{
    var github: GitHub.Environment
    {
        GitHub.Environment(
            fetchRepositories: { searchText in
                var urlComponents = URLComponents(string: "https://api.github.com/search/repositories")!
                urlComponents.queryItems = [
                    URLQueryItem(name: "q", value: searchText)
                ]

                var urlRequest = URLRequest(url: urlComponents.url!)
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                let data = try await self.fetchRequest(urlRequest)
                let response = try decoder.decode(SearchRepositoryResponse.self, from: data)
                return response
            },
            fetchImage: { url in
                let urlRequest = URLRequest(url: url)
                guard let data = try? await self.fetchRequest(urlRequest) else {
                    return nil
                }
                return UIImage(data: data)
            },
            searchRequestDelay: 0.3,
            imageLoadMaxConcurrency: 3
        )
    }

    var stopwatch: Stopwatch.Environment
    {
        Stopwatch.Environment(
            getDate: getDate,
            timer: timer
        )
    }
}

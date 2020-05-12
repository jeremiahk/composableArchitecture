import ComposableArchitecture

private let wolframAlphaApiKey = "6H69Q3-828TKQJ4EP"

private struct WolframAlphaResult: Decodable {
  let queryresult: QueryResult

  struct QueryResult: Decodable {
    let pods: [Pod]

    struct Pod: Decodable {
      let primary: Bool?
      let subpods: [SubPod]

      struct SubPod: Decodable {
        let plaintext: String
      }
    }
  }
}

private func wolframAlpha(query: String) -> Effect<WolframAlphaResult?> {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: wolframAlphaApiKey),
    ]

//    return dataTask(with: components.url(relativeTo: nil)!)
//        .decode(as: WolframAlphaResult.self)

    return URLSession.shared
        .dataTaskPublisher(for: components.url(relativeTo: nil)!)
        .map { data, _ in data }
        .decode(type: WolframAlphaResult.self, decoder: JSONDecoder())
        .map(Optional.some)
        .replaceError(with: nil)
        .eraseToEffect()
}

//func dataTask(with url: URL) -> Effect<(Data?, URLResponse?, Error?)> {
//    return Effect { callback in
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            callback((data, response, error))
//        }
//        .resume()
//    }
//}

func nthPrime(_ n: Int) -> Effect<Int?> {
//    return wolframAlpha(query: "prime \(n)").map { request in
//        switch request {
//        case let .success(result):
//            guard let count = result.queryresult
//                    .pods
//                    .first(where: { $0.primary == .some(true) })?
//                    .subpods
//                    .first?
//                    .plaintext
//                 else {
//                    return nil
//            }
//
//            return Int(count)
//        case let .failure(error):
//            print("Error here: \(error)")
//            return nil
//        }
//    }

    return wolframAlpha(query: "prime \(n)")
        .map { result in
            result.flatMap {
                $0.queryresult
                    .pods
                    .first(where: { $0.primary == .some(true) })?
                    .subpods
                    .first?
                    .plaintext
            }
            .flatMap(Int.init)
        }
        .eraseToEffect()
}

//enum DeserializationError: Error {
//    case generalFailure
//}

//extension Effect where A == (Data?, URLResponse?, Error?) {
//    func decode<M: Decodable>(as type: M.Type) -> Effect<Result<M, DeserializationError>> {
//        return self.map { data, _, _ in
//            do {
//                let finalData = try JSONDecoder().decode(M.self, from: data!)
//                return Result.success(finalData)
//            } catch {
//                return Result.failure(DeserializationError.generalFailure)
//            }
//        }
//    }
//}
//
//extension Effect {
//    func receive(on queue: DispatchQueue) -> Effect {
//        return Effect { callback in
//            self.run { a in
//                queue.async {
//                    callback(a)
//                }
//            }
//        }
//    }
//}

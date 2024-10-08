import Foundation
import Network
import Combine

class CellularDataProvider {
    
    func request(request: URLRequest) -> AnyPublisher<Data, Error> {
        return Future<Data, Error> { promise in
            guard let url = request.url, let host = url.host else {
                promise(.failure(URLError(.badURL)))
                return
            }

            let endpoint = NWEndpoint.url(url)
            let parameters = NWParameters.tls
            parameters.allowFastOpen = true
            parameters.requiredInterfaceType = .cellular
            let connection = NWConnection(to: endpoint, using: parameters)

            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    logger.debug("connection is ready. sending request via cellular.")
                    
                    var httpRequestData = "\(request.httpMethod ?? "GET") \(url.path) HTTP/1.1\r\n"
                    httpRequestData += "Host: \(host)\r\n"
                    
                    if let headers = request.allHTTPHeaderFields {
                        for (headerField, value) in headers {
                            httpRequestData += "\(headerField): \(value)\r\n"
                        }
                    }
                    
                    httpRequestData += "\r\n"
                    var requestData = httpRequestData.data(using: .utf8)!
                    if let body = request.httpBody {
                        requestData.append(body)
                    }
                    connection.send(content: requestData, completion: .contentProcessed({ error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            logger.debug("request sent successfully. url :\(url)")
                        }
                    }))
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, context, isComplete, error) in
                        if let data = data {
                            promise(.success(data))
                        } else if let error = error {
                            promise(.failure(error))
                        }
                    }

                case .failed(let error):
                    promise(.failure(error))

                default:
                    break
                }
            }
            connection.start(queue: .global())
        }
        .eraseToAnyPublisher()
    }
    
}




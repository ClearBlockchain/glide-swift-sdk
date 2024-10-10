import Foundation
import Network
import Combine

class CellularDataProvider {
    
    func request(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        return Future<(data: Data, response: URLResponse), Error> { promise in
            self.performRequest(request: request, promise: promise)
        }
        .eraseToAnyPublisher()
    }

    private func performRequest(request: URLRequest, promise: @escaping (Result<(data: Data, response: URLResponse), Error>) -> Void) {
        guard let url = request.url, let host = url.host else {
            promise(.failure(URLError(.badURL)))
            return
        }

        let connection = self.createConnection(for: url)
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                self.sendRequest(connection, with: request, host: host, promise: promise)
            case .failed(let error):
                promise(.failure(error))
            default:
                break
            }
        }
        connection.start(queue: .global())
    }

    private func createConnection(for url: URL) -> NWConnection {
        let endpoint = NWEndpoint.url(url)
        let parameters = NWParameters.tls
        parameters.requiredInterfaceType = .cellular // Force cellular interface
        return NWConnection(to: endpoint, using: parameters)
    }

    private func sendRequest(_ connection: NWConnection, with request: URLRequest, host: String, promise: @escaping (Result<(data: Data, response: URLResponse), Error>) -> Void) {
        let requestData = createRequestData(from: request, host: host)

        connection.send(content: requestData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                promise(.failure(error))
            } else {
                self?.receiveResponse(connection, originalRequest: request, promise: promise)
            }
        })
    }

    private func createRequestData(from request: URLRequest, host: String) -> Data {
        // Use the full URL with query parameters if present
        let fullPath = request.url?.path ?? "/"
        let queryString = request.url?.query.map { "?\($0)" } ?? ""

        var httpRequestData = "\(request.httpMethod ?? "GET") \(fullPath)\(queryString) HTTP/1.1\r\n"
        httpRequestData += "Host: \(host)\r\n"

        if let headers = request.allHTTPHeaderFields {
            for (headerField, value) in headers {
                httpRequestData += "\(headerField): \(value)\r\n"
            }
        }
        httpRequestData += "\r\n"

        var requestData = httpRequestData.data(using: .utf8)!

        // If there is a body, append it to the request data
        if let body = request.httpBody {
            requestData.append(body)
        }

        return requestData
    }

    private func receiveResponse(_ connection: NWConnection, originalRequest: URLRequest, promise: @escaping (Result<(data: Data, response: URLResponse), Error>) -> Void) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, _, error) in
            if let data = data {
                if let (body, response) = self?.parseResponse(data), let httpResponse = response as? HTTPURLResponse {
                    
                    // Check if it's a redirect response (3xx status code)
                    if (300...399).contains(httpResponse.statusCode), let location = httpResponse.allHeaderFields["Location"] as? String {
                        
                        // Handle redirect
                        if let redirectURL = URL(string: location, relativeTo: originalRequest.url) {
                            var redirectRequest = originalRequest
                            redirectRequest.url = redirectURL
                            self?.performRequest(request: redirectRequest, promise: promise)
                        } else {
                            promise(.failure(URLError(.badURL)))
                        }
                    } else {
                        // Normal response
                        promise(.success((body, response)))
                    }
                } else {
                    promise(.failure(URLError(.badServerResponse)))
                }
            } else if let error = error {
                promise(.failure(error))
            }
        }
    }

    private func parseResponse(_ data: Data) -> (Data, URLResponse)? {
        guard let responseString = String(data: data, encoding: .utf8),
              let headerEndRange = responseString.range(of: "\r\n\r\n") else {
            return nil
        }

        let headerPart = responseString[..<headerEndRange.lowerBound]
        let bodyPart = data.subdata(in: headerEndRange.upperBound.utf16Offset(in: responseString)..<data.count)
        let headerLines = headerPart.split(separator: "\r\n")
        let statusLine = headerLines.first ?? ""
        let statusComponents = statusLine.split(separator: " ")

        guard statusComponents.count >= 3,
              let statusCode = Int(statusComponents[1]),
              let url = URL(string: String(statusComponents[0])) else {
            return nil
        }

        var headerFields = [String: String]()
        for line in headerLines.dropFirst() {
            let parts = line.components(separatedBy: ": ")
            if parts.count == 2 {
                headerFields[parts[0]] = parts[1]
            }
        }

        if let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headerFields) {
            return (bodyPart, response)
        }

        return nil
    }
}

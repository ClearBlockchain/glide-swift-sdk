import Foundation
import Combine

let threeLeggedFlowName = "three_legged_flow"

class ThreeLeggedAuthFlow {
    
    private let cellularDataProvider = CellularDataProvider()
    
    func authenticate(config: ThreeLeggedConfig) -> AnyPublisher<ThreeLeggedResponse, Error>? {
        return Just(0)
            .compactMap { [weak self] _ in self?.auth(config: config) }
            .flatMap { $0 }
            .eraseToAnyPublisher()
    }
    
    private func auth(config: ThreeLeggedConfig) -> AnyPublisher<ThreeLeggedResponse, Error>? {
        guard let request = createRequest(config: config) else { return nil }
        
        return cellularDataProvider.request(request: request)
            .tryMap { data, response in
                try self.validateResponse(data: data, response: response)
            }
            .decode(type: ThreeLeggedResponse.self, decoder: JSONDecoder())
            .catch { Fail(error: $0).eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    private func validateResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == successCode else {
            let error = try? JSONDecoder().decode(APIError.self, from: data)
            throw SDKError.statusCode((response as? HTTPURLResponse)?.statusCode ?? 0, error?.error_description ?? "")
        }
        return data
    }
    
    private func createRequest(config: ThreeLeggedConfig) -> URLRequest? {
        guard let url = generateAuthUrl(config: config) else {
            logger.error("\(threeLeggedFlowName): invalid config")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }
    
    private func generateAuthUrl(config: ThreeLeggedConfig) -> URL? {
        var urlComponents = URLComponents(string: "\(config.authBaseUrl)/oauth2/auth?")
        urlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri ?? ""),
            URLQueryItem(name: "scope", value: "openid"),
            URLQueryItem(name: "purpose", value: "dpv:FraudPreventionAndDetection:number-verification"),
            URLQueryItem(name: "state", value: UUID().uuidString),
            URLQueryItem(name: "nonce", value: UUID().uuidString),
            URLQueryItem(name: "dev_print", value: "true"),
            URLQueryItem(name: "max_age", value: "0")
        ]
        
        if let phoneNumber = config.phoneNumber {
            urlComponents?.queryItems?.append(URLQueryItem(name: "login_hint", value: "tel:\(phoneNumber)"))
        }
        
        return urlComponents?.url
    }
}

struct ThreeLeggedConfig {
    let state: String
    let printCode: Bool
    let authBaseUrl: String
    let clientID: String
    let phoneNumber: String?
    let redirectUri: String?
}

struct ThreeLeggedResponse: Codable {
    let code: String
    let state: String
}

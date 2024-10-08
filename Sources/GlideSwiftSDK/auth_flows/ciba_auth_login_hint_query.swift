import Foundation
import Combine

let successCode = 200

class CibaAuthFlow {
    
    let cellularDataProvider = CellularDataProvider()
    
    public func authenticate(authConfig: AuthConfigProtocol, config: GlideConfig) -> AnyPublisher<String, Error>? {
        
        let triggerPublisher : Just<Int> = Just(.zero)
        
        let concatPublisher = triggerPublisher
            .compactMap({ [weak self]_ in
                return self?.getCibaAuthLoginHintPiublisher(authConfig: authConfig, config: config)
            })
            .flatMap{$0}
            .map { $0.auth_req_id}
            .compactMap({ [weak self] id in
                return self?.getCibaAuthToken(authReqId : id, config: config)
            })
            .flatMap {$0}
            .eraseToAnyPublisher()
        
        return concatPublisher
        
    }
    
    private func getCibaAuthLoginHintPiublisher(authConfig: AuthConfigProtocol, config: GlideConfig) -> AnyPublisher<CibaAuthResponse, Error>? {
        
        guard let cibaAuthRequest = getCibaAuthLoginHintRequest(authConfig: authConfig, config: config) else {
            logger.error("CibaAuthFlow: getCibaAuthLoginHint faild init request")
            return nil
        }
        
        return URLSession.shared.dataTaskPublisher(for: cibaAuthRequest)
            .tryMap { output in
                    guard let httpResponse = output.response as? HTTPURLResponse,
                          httpResponse.statusCode == successCode else {
                        logger.error("CibAuthFlow: getCibaAuthLoginHint failed request: \(output)")
                        throw URLError(.badServerResponse)
                    }
                    return output.data
                }
            .decode(type: CibaAuthResponse.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<CibaAuthResponse, Error> in
                logger.error("CibAuthFlow: cibaAuthRequest failed with errr: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    private func getCibaAuthToken(authReqId : String, config: GlideConfig) -> AnyPublisher<String, Error>? {
        
        guard let cibaTokenRequest = getCibaTokenRequest(authReqId: authReqId, config: config) else {
            logger.error("CibaAuthFlow: cibaTokenRequest faild init request")
            return nil
        }
        
        return URLSession.shared.dataTaskPublisher(for: cibaTokenRequest)
            .tryMap { output in
                    guard let httpResponse = output.response as? HTTPURLResponse,
                          httpResponse.statusCode == successCode else {
                        logger.error("CibAuthFlow: getCibaAuthToken failed request: \(output)")
                        throw URLError(.badServerResponse)
                    }
                    return output.data
                }
            .decode(type: CibaTokenResponse.self, decoder: JSONDecoder())
            .compactMap { response -> String? in
                let accessToken = response.access_token
                logger.debug("CibaAuthFlow: Received CIBA token response, data: \(accessToken)")
                return accessToken
            }.catch { error -> AnyPublisher<String, Error> in
                logger.error("CibAuthFlow: getCibaAuthToken failed with errr: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    private func getCibaAuthLoginHintRequest(authConfig: AuthConfigProtocol, config: GlideConfig) -> URLRequest? {
        var scopes = ["scope": "openId",
                      "purpos" : "dpv:FraudPreventionAndDetection:sim-swap"]
        if let loginHint = authConfig.loginHint {
            scopes["login_hint"] = loginHint
        }
        
        guard let url = URL(string: "\(config.internalUrls.authBaseUrl)/oauth2/backchannel-authentication") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(getBasicAuthHeader(clientId: config.clientId, clientSecret: config.clientSecret), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = percentEncoded(data: scopes)
        return request
    }
    
    private func getCibaTokenRequest(authReqId: String, config: GlideConfig) -> URLRequest? {
        
        guard let url = URL(string: "\(config.internalUrls.authBaseUrl)/oauth2/token") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(getBasicAuthHeader(clientId: config.clientId, clientSecret: config.clientSecret), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = percentEncoded(data: ["grant_type": "urn:openid:params:grant-type:ciba", "auth_req_id": authReqId])
        
        return request
    }
    
    private func getBasicAuthHeader(clientId: String, clientSecret: String) -> String {
        let credentials = "\(clientId):\(clientSecret)"
        guard let data = credentials.data(using: .utf8) else {
            return ""
        }
        return "Basic \(data.base64EncodedString())"
    }
    
}

struct CibaAuthResponse: Codable {
    var auth_req_id: String
    var expires_in: Int
    var interval: Int
    var consent_url: String
}

struct CibaTokenResponse: Codable {
    var access_token: String
    var expires_in: Int
    var scope: String
    var token_type: String
}





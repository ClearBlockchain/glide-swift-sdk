import Foundation
import Combine

class CibaAuthFlow {
    
    private let queuesProvider: QueuesProvider!
    
    init(queuesProvider: QueuesProvider) {
        self.queuesProvider = queuesProvider
    }
    
    public func authenticate(authConfig: AuthConfigProtocol, config: GlideConfig) -> AnyPublisher<String, Error>? {
        
        guard let cibaAuthRequest = getCibaAuthLoginHintRequest(authConfig: authConfig, config: config) else {
            logger.error("CibaAuthFlow: getCibaAuthLoginHint faild init request")
            return nil
        }
        
        let firstPublisher = URLSession.shared.dataTaskPublisher(for: cibaAuthRequest)
            .map { $0.data }
            .decode(type: CibaAuthResponse.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<CibaAuthResponse, Error> in
                logger.error("CibAuthFlow: cibaAuthRequest failed with errr: \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
        
        return firstPublisher
            .map { $0.auth_req_id}
            .compactMap { [weak self] id -> URLRequest?  in
                guard let cibaTokenRequest = self?.getCibaTokenRequest(authReqId: id, config: config) else {
                    logger.error("CibaAuthFlow: cibaTokenRequest faild init request")
                    return nil
                }
                return cibaTokenRequest
            }.flatMap { request in
                return URLSession.shared.dataTaskPublisher(for: request)
                    .map { $0.data }
                    .decode(type: [String: String].self, decoder: JSONDecoder())
                    .compactMap { dictionary -> String? in
                        guard let accessToken = dictionary["access_token"] else {
                            return nil
                        }
                        logger.debug("CibaAuthFlow: Received CIBA token response, data: \(accessToken)")
                        return accessToken
                    }.catch { error -> AnyPublisher<String, Error> in
                        logger.error("CibAuthFlow: getCibaTokenRequest failed with errr: \(error)")
                        return Fail(error: error).eraseToAnyPublisher()
                    }
            }.eraseToAnyPublisher()
        
        
    }
    
    private func getCibaAuthLoginHintRequest(authConfig: AuthConfigProtocol, config: GlideConfig) -> URLRequest? {
        var scopes = ["scope": "openId"]
        scopes["purpos"] = "dpv:FraudPreventionAndDetection:sim-swap"
        if let loginHint = authConfig.loginHint {
            scopes["login_hint"] = loginHint
        }
        
        guard let url = URL(string: "\(config.internalUrls.authBaseUrl)/oauth2/backchannel-authentication") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Basic QUdHWDA3SjdEU00zMThYWlBUTk1RUjp3T2FVaWpiWWdUa2hLTmxoOFkwZjd2Rnd0dzQ5ZHJYcw==", forHTTPHeaderField: "Authorization")
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



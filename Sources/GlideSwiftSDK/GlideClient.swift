import Foundation

protocol AuthConfigProtocol {
    var scopes: [String] { get set }
    var loginHint: String? { get set }
}

struct BaseAuthConfig: AuthConfigProtocol {
    var scopes: [String]
    var loginHint: String?
}

struct AuthConfig: AuthConfigProtocol {
    var scopes: [String]
    var loginHint: String?
    var provider: SessionType
}

struct AuthenticationResponse {
    var session: Session?
    var redirectUrl: URL?
}

struct CibaAuthResponse: Codable {
    var authReqId: String
    var expiresIn: Int
    var interval: Int
}

struct NumberVerificationResponse: Codable {
    var devicePhoneNumberVerified: Bool
}

struct GetPhoneNumberResponse: Codable {
    var devicePhoneNumber: String
}

struct LastSimChangeResponse: Codable {
    var lastSimChange: String
}

struct SimSwapCheckRequest: Codable {
    let phoneNumber: String
    let maxAge: Int
}

struct SimSwapResponse: Codable {
    var swapped: Bool
}

struct LocationBody: Codable {
    var latitude: Double
    var longitude: Double
    var radius: Double
    var deviceId: String
    var deviceIdType: DeviceIDType
    var maxAge: Int
}

struct LocationResponse: Codable {
    var verificationResult: String
}

enum DeviceIDType: String, Codable {
    case ipv4Address = "ipv4Address"
    case ipv6Address = "ipv6Address"
    case phoneNumber = "phoneNumber"
    case networkAccessIdentifier = "networkAccessIdentifier"
}

func percentEncoded(data: [String: String]) -> Data? {
    return data.map { 
        key, 
        value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return ""
            }
            return "\(encodedKey)=\(encodedValue)"
    }
    .joined(separator: "&")
    .data(using: .utf8)
}

@available(iOS 17.0, macOS 14.0, *)
class GlideClient {
    private var config: GlideConfig
    private var session: Session?

    init(clientId: String?, clientSecret: String?, redirectUri: String?, authBaseUrl: String?, apiBaseUrl: String?) throws {
        self.config = try getGlideConfig(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectUri: redirectUri,
            authBaseUrl: authBaseUrl,
            apiBaseUrl: apiBaseUrl
        )
    }

    private func getBasicAuthHeader() -> String {
        let credentials = "\(config.clientId):\(config.clientSecret)"
        guard let data = credentials.data(using: .utf8) else {
            return ""
        }
        return "Basic \(data.base64EncodedString())"
    }

    private func getCibaAuthLoginHint(authConfig: AuthConfigProtocol) async throws -> CibaAuthResponse {
        logger.debug("Sending CIBA auth request, authConfig: \(authConfig)")

        var scopes = ["scope": authConfig.scopes.joined(separator: " ")]
        if let loginHint = authConfig.loginHint {
            scopes["loginHint"] = loginHint
        }

        guard let url = URL(string: "\(config.internalUrls.authBaseUrl)/oauth2/backchannel-authentication") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(getBasicAuthHeader(), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = percentEncoded(data: scopes)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HTTPResponseError(response: response)
        }

        let decoder = JSONDecoder()
        let resData = try decoder.decode(CibaAuthResponse.self, from: data)
        logger.debug("Received CIBA auth response, data: \(resData)")
        return resData
    }

    private func fetchCibaToken(authReqId: String) async throws -> Session {
        logger.debug("Polling for CIBA token, authReqId: \(authReqId)")

        guard let url = URL(string: "\(config.internalUrls.authBaseUrl)/oauth2/token") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(getBasicAuthHeader(), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = percentEncoded(data: ["grant_type": "urn:openid:params:grant-type:ciba", "auth_req_id": authReqId])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HTTPResponseError(response: response)
        }

        let decoder = JSONDecoder()
        let resData = try decoder.decode([String: String].self, from: data)
        guard let accessToken = resData["access_token"] else {
            throw NSError(domain: "GlideClientError", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Access token not found in response"])
        }

        logger.debug("Received CIBA token response, data: \(resData)")
        return Session(accessToken: accessToken, sessionType: .ciba)
    }

    private func pollCibaToken(authReqId: String, interval: Int) async throws -> Session {
        if interval < 1 {
            throw NSError(domain: "GlideClientError", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Invalid polling interval"])
        }

        logger.debug("Polling CIBA token, authReqId: \(authReqId), interval: \(interval)")

        var retries = 0
        let MAX_RETRIES = 10

        while retries < MAX_RETRIES {
            do {
                let newSession = try await fetchCibaToken(authReqId: authReqId)
                if newSession.accessToken != "" {
                    return newSession
                }
            } catch {
                logger.error("Failed to poll CIBA token, error: \(error)")
                throw error
            }

            retries += 1

            try await Task.sleep(nanoseconds: UInt64(interval * 1000))
        }

        logger.debug("Unable to poll CIBA token")
        throw NSError(domain: "GlideClientError", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Unable to poll CIBA token"])
    }

    private func getCibaSession(authConfig: AuthConfigProtocol) async throws -> Session {
        logger.debug("Starting ciba authentication flow, authConfig: \(authConfig)")

        do {
            let cibaAuthResponse = try await getCibaAuthLoginHint(authConfig: authConfig)
            let session = try await pollCibaToken(authReqId: cibaAuthResponse.authReqId, interval: cibaAuthResponse.interval)

            logger.debug("Received CIBA session")
            return session
        } catch {
            logger.error("Failed to get CIBA session, error: \(error)")
            throw error
        }
    }

    private func get3LeggedAuthRedirectUrl(authConfig: AuthConfigProtocol) -> URL {
        logger.debug("Getting 3-legged auth redirect URL, authConfig: \(authConfig)")

        let nonce = randomString(length: 16)
        let state = randomString(length: 10)

        var urlComponents = URLComponents(string: "\(config.internalUrls.authBaseUrl)/oauth2/auth")!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: authConfig.scopes.joined(separator: " ")),
            URLQueryItem(name: "nonce", value: nonce),
            URLQueryItem(name: "max_age", value: "0"),
            URLQueryItem(name: "purpose", value: ""),
            URLQueryItem(name: "audience", value: config.clientId)
        ]

        if let loginHint = authConfig.loginHint {
            urlComponents.queryItems?.append(URLQueryItem(name: "login_hint", value: loginHint))
        }

        guard let url = urlComponents.url else {
            return URL(string: "")!
        }

        logger.debug("Received 3-legged auth redirect URL, url: \(url)")
        return url
    }

    public func exchangeCodeForSession(code: String) async throws -> Session {
        logger.debug("Exchanging code for session, code: \(code)")

        guard let url = URL(string: "\(config.internalUrls.authBaseUrl)/oauth2/token") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(getBasicAuthHeader(), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = percentEncoded(data: ["grant_type": "authorization_code", "code": code, "redirect_uri": config.redirectUri])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HTTPResponseError(response: response)
        }

        let decoder = JSONDecoder()
        let resData = try decoder.decode([String: String].self, from: data)
        guard let accessToken = resData["access_token"] else {
            throw NSError(domain: "GlideClientError", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Access token not found in response"])
        }

        logger.debug("Received session, data: \(resData)")
        return Session(accessToken: accessToken, sessionType: .threeLeggedOAuth2)
    }

    public func authenticate(authConfig: AuthConfigProtocol) async throws -> AuthenticationResponse {
        // Attempt to cast authConfig to AuthConfig type
        guard let authConfig = authConfig as? AuthConfig else {
            throw NSError(domain: "GlideClientError", code: 1009, userInfo: [NSLocalizedDescriptionKey: "Invalid authConfig type"])
        }

        var mutableAuthConfig = authConfig // Make a mutable copy of authConfig
        
        if let session = self.session, session.sessionType.rawValue >= mutableAuthConfig.provider.rawValue {
            logger.debug("Returning existing session")
            return AuthenticationResponse(session: session, redirectUrl: nil)
        }

        if mutableAuthConfig.scopes.isEmpty {
            mutableAuthConfig.scopes = ["openid"]
        }

        do {
            switch mutableAuthConfig.provider {
            case .ciba:
                self.session = try await getCibaSession(authConfig: mutableAuthConfig)
                return AuthenticationResponse(session: self.session, redirectUrl: nil)
            case .threeLeggedOAuth2:
                return AuthenticationResponse(session: nil, redirectUrl: get3LeggedAuthRedirectUrl(authConfig: mutableAuthConfig))
            // default:
            //     throw NSError(domain: "GlideClientError", code: 1008, userInfo: [NSLocalizedDescriptionKey: "Invalid session type"])
            }
        } catch {
            logger.error("Failed to authenticate, error: \(error)")
            throw error
        }
    }

    private func baseVerifyNumber(phoneNumber: String?, hashedPhoneNumber: String?) async throws -> Bool {
        var data = AuthConfig(scopes: ["openid", "dpv:FraudDetectionAndPrevention:number-verification"], provider: .threeLeggedOAuth2)
        if let phoneNumber = phoneNumber {
            data.loginHint = "tel:\(formatPhoneNumber(phoneNumber))"
        }

        do {
            let authRes = try await authenticate(authConfig: data)

            if authRes.redirectUrl != nil {
                throw InsufficientSessionError(have: self.session?.sessionType, need: .threeLeggedOAuth2, message: "VerifyByNumber requires ThreeLeggedOAuth2 session - call this.authenticate first.")
            }

            guard let url = URL(string: "\(config.internalUrls.apiBaseUrl)/number-verification/verify") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(self.session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["phoneNumber": phoneNumber, "hashedPhoneNumber": hashedPhoneNumber])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw HTTPResponseError(response: response)
            }

            let decoder = JSONDecoder()
            let resData = try decoder.decode(NumberVerificationResponse.self, from: data)
            logger.debug("Received number verification response, data: \(resData)")
            return resData.devicePhoneNumberVerified
        } catch {
            logger.error("Failed to verify phone number, error: \(error)")
            throw error
        }
    }

    public func verifyByNumber(phoneNumber: String) async throws -> Bool {
        logger.debug("Verifying phone number, phoneNumber: \(phoneNumber)")
        return try await baseVerifyNumber(phoneNumber: phoneNumber, hashedPhoneNumber: nil)
    }

    public func verifyByNumberHash(hashedPhoneNumber: String) async throws -> Bool {
        logger.debug("Verifying phone number hash, hashedPhoneNumber: \(hashedPhoneNumber)")
        return try await baseVerifyNumber(phoneNumber: nil, hashedPhoneNumber: hashedPhoneNumber)
    }

    public func getPhoneNumber() async throws -> String {
        do {
            let authRes = try await authenticate(authConfig: AuthConfig(scopes: ["openid", "dpv:FraudDetectionAndPrevention:number-verification"], provider: .threeLeggedOAuth2))

            if authRes.redirectUrl != nil {
                throw InsufficientSessionError(have: self.session?.sessionType, need: .threeLeggedOAuth2, message: "GetPhoneNumber requires ThreeLeggedOAuth2 session - call this.authenticate first.")
            }

            guard let url = URL(string: "\(config.internalUrls.apiBaseUrl)/number-verification/device-phone-number") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(self.session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw HTTPResponseError(response: response)
            }

            let decoder = JSONDecoder()
            let resData = try decoder.decode(GetPhoneNumberResponse.self, from: data)
            logger.debug("Received phone number response, data: \(resData)")
            return resData.devicePhoneNumber
        } catch {
            logger.error("Failed to get phone number, error: \(error)")
            throw error
        }
    }

    public func retrieveDate(phoneNumber: String) async throws -> String {
        logger.debug("Retrieving last sim change date, phoneNumber: \(phoneNumber)")

        do {
            let authRes = try await authenticate(authConfig: AuthConfig(scopes: ["openid", "dpv:FraudDetectionAndPrevention:sim-swap"], loginHint: "tel:\(formatPhoneNumber(phoneNumber))", provider: .ciba))

            if authRes.redirectUrl != nil {
                throw InsufficientSessionError(have: self.session?.sessionType, need: .ciba, message: "RetrieveDate requires Ciba session - call this.authenticate first.")
            }

            guard let url = URL(string: "\(config.internalUrls.apiBaseUrl)/sim-swap/retrieve-date") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(self.session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["phoneNumber": formatPhoneNumber(phoneNumber)])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw HTTPResponseError(response: response)
            }

            let decoder = JSONDecoder()
            let resData = try decoder.decode(LastSimChangeResponse.self, from: data)
            logger.debug("Received last sim change response, data: \(resData)")
            return resData.lastSimChange
        } catch {
            logger.error("Failed to retrieve last sim change date, error: \(error)")
            throw error
        }
    }

    public func checkSimSwap(phoneNumber: String, maxAge: Int) async throws -> Bool {
        logger.debug("Checking sim swap, phoneNumber: \(phoneNumber), maxAge: \(maxAge)")

        do {
            let authRes = try await authenticate(authConfig: AuthConfig(scopes: ["openid", "dpv:FraudDetectionAndPrevention:sim-swap"], loginHint: "tel:\(formatPhoneNumber(phoneNumber))", provider: .ciba))

            if authRes.redirectUrl != nil {
                throw InsufficientSessionError(have: self.session?.sessionType, need: .ciba, message: "CheckSimSwap requires Ciba session - call this.authenticate first.")
            }

            guard let url = URL(string: "\(config.internalUrls.apiBaseUrl)/sim-swap/check") else {
                throw URLError(.badURL)
            }
            
            let requestPayload = SimSwapCheckRequest(phoneNumber: formatPhoneNumber(phoneNumber), maxAge: maxAge)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(self.session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestPayload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw HTTPResponseError(response: response)
            }

            let decoder = JSONDecoder()
            let resData = try decoder.decode(SimSwapResponse.self, from: data)
            logger.debug("Received sim swap response, data: \(resData)")
            return resData.swapped
        } catch {
            logger.error("Failed to check sim swap, error: \(error)")
            throw error
        }
    }

    public func verifyLocation(latitude: Double, longitude: Double, deviceId: String, radius: Double = 2000, deviceIdType: DeviceIDType = .phoneNumber, maxAge: Int = 3600) async throws -> Bool {
        logger.debug("Verifying location, latitude: \(latitude), longitude: \(longitude), radius: \(radius), deviceId: \(deviceId), deviceIdType: \(deviceIdType), maxAge: \(maxAge)")

        if latitude == 0 || longitude == 0 || deviceId.isEmpty {
            throw NSError(domain: "GlideClientError", code: 1009, userInfo: [NSLocalizedDescriptionKey: "Invalid location data - latitude, longitude, deviceId are required"])
        }

        do {
            let authRes = try await authenticate(authConfig: AuthConfig(scopes: ["openid", "dpv:FraudPreventionAndDetection:device-location"], provider: .ciba))

            if authRes.redirectUrl != nil {
                throw InsufficientSessionError(have: self.session?.sessionType, need: .ciba, message: "VerifyLocation requires Ciba session - call this.authenticate first.")
            }

            guard let url = URL(string: "\(config.internalUrls.apiBaseUrl)/device-location/verify") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(self.session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(LocationBody(latitude: latitude, longitude: longitude, radius: radius, deviceId: deviceId, deviceIdType: deviceIdType, maxAge: maxAge))

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw HTTPResponseError(response: response)
            }

            let decoder = JSONDecoder()
            let resData = try decoder.decode(LocationResponse.self, from: data)
            logger.debug("Received location verification response, data: \(resData)")

            if resData.verificationResult == "FALSE" {
                return false
            }

            return true
        } catch {
            logger.error("Failed to verify location, error: \(error)")
            throw error
        }
    }
}

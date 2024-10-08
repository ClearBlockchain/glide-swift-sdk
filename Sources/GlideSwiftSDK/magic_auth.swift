import Foundation
import JWTDecode

enum VerificationType: String, Codable {
    case magic = "MAGIC"
    case sms = "SMS"
    case email = "EMAIL"
}

enum FallbackVerificationChannel: String, Codable {
    case sms = "SMS"
    case email = "EMAIL"
}

struct StartVerificationDto: Codable {
    let phoneNumber: String?
    let email: String?
    let fallbackChannel: FallbackVerificationChannel?
}

struct StartVerificationResponseDto: Codable {
    let type: VerificationType
    let authUrl: String?
    let verified: Bool?
}

struct VerifyTokenDto: Codable {
    let phoneNumber: String
}

struct CheckCodeDto: Codable {
    let phoneNumber: String?
    let email: String?
    let code: String
}

@available(iOS 17.0, macOS 14.0, *)
class MagicAuth {
    private var config: GlideConfig

    init(clientId: String?, clientSecret: String?, redirectUri: String?, authBaseUrl: String?, apiBaseUrl: String?) throws {
        self.config = try getGlideConfig(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectUri: redirectUri,
            authBaseUrl: authBaseUrl,
            apiBaseUrl: apiBaseUrl
        )
    }


    func authenticate(startVerificationDto: StartVerificationDto) async throws -> StartVerificationResponseDto {
        let url = URL(string: "\(config.internalUrls.apiBaseUrl)/magic-auth/verification/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(StartVerificationDto(
            phoneNumber: startVerificationDto.phoneNumber.map { formatPhoneNumber($0) },
            email: startVerificationDto.email,
            fallbackChannel: startVerificationDto.fallbackChannel
        ))
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HTTPResponseError(response: response)
        }

        let resData = try JSONDecoder().decode(StartVerificationResponseDto.self, from: data)
        if resData.type == VerificationType.magic, let authUrl = resData.authUrl, let authURL = URL(string: authUrl) {
            let (authData, authResponse) = try await URLSession.shared.data(from: authURL)
            guard let authHTTPResponse = authResponse as? HTTPURLResponse, authHTTPResponse.statusCode == 200 else {
                throw HTTPResponseError(response: authResponse)
            }

            let jwtToken = String(decoding: authData, as: UTF8.self)
            // Decode JWT without signature verification
            do {
                let jwt = try decode(jwt: jwtToken)
                guard let issuer = jwt.claim(name: "iss").string, issuer == config.internalUrls.authBaseUrl else {
                    throw NSError(domain: "JWTError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JWT issuer"])
                }
                return StartVerificationResponseDto(type: VerificationType.magic, authUrl: nil, verified: true)
            } catch {
                throw NSError(domain: "JWTError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode JWT"])
            }
        }
        return resData
    }

    func checkCode(checkCodeDto: CheckCodeDto) async throws -> Bool {
        let url = URL(string: "\(config.internalUrls.apiBaseUrl)/magic-auth/verification/check-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(CheckCodeDto(
            phoneNumber: checkCodeDto.phoneNumber.map { formatPhoneNumber($0) },
            email: checkCodeDto.email,
            code: checkCodeDto.code
        ))
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HTTPResponseError(response: response)
        }
        let resData = try JSONDecoder().decode(Bool.self, from: data)
        return resData
    }
}

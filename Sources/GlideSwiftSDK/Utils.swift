import Foundation

struct GlideConfig {
    let clientId: String
    let clientSecret: String
    let redirectUri: String
    let internalUrls: (authBaseUrl: String, apiBaseUrl: String)
}

func getGlideConfig(clientId: String?, clientSecret: String?, redirectUri: String?, authBaseUrl: String?, apiBaseUrl: String?) throws -> GlideConfig {
    guard let clientId = clientId ?? ProcessInfo.processInfo.environment["GLIDE_CLIENT_ID"]  else {
        throw NSError(domain: "EnvironmentError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "GLIDE_CLIENT_ID is required"])
    }

    guard let clientSecret = clientSecret ?? ProcessInfo.processInfo.environment["GLIDE_CLIENT_SECRET"] else {
        throw NSError(domain: "EnvironmentError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "GLIDE_CLIENT_SECRET is required"])
    }

    guard let redirectUri = redirectUri ?? ProcessInfo.processInfo.environment["GLIDE_REDIRECT_URI"] else {
        throw NSError(domain: "EnvironmentError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "GLIDE_REDIRECT_URI is required"])
    }

    let authBaseUrl = authBaseUrl ?? ProcessInfo.processInfo.environment["GLIDE_AUTH_BASE_URL"] ?? "https://oidc.gateway-x.io"
    let apiBaseUrl = apiBaseUrl ?? ProcessInfo.processInfo.environment["GLIDE_API_BASE_URL"] ?? "https://api.gateway-x.io"

    return GlideConfig(
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUri: redirectUri,
        internalUrls: (authBaseUrl: authBaseUrl, apiBaseUrl: apiBaseUrl)
    )
}

struct HTTPResponseError: Error {
    let response: URLResponse
    var localizedDescription: String {
        guard let httpResponse = response as? HTTPURLResponse else {
            return "Invalid response type"
        }
        let statusCode = httpResponse.statusCode
        let statusMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        return "HTTP Error Response: \(statusCode) \(statusMessage)"
    }
}

struct InsufficientSessionError: Error {
    let have: SessionType?
    let need: SessionType?
    let message: String

    var localizedDescription: String {
        return message
    }
}

func formatPhoneNumber(_ phoneNumber: String) -> String {
    var formattedNumber = phoneNumber.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    if !formattedNumber.hasPrefix("+") {
        formattedNumber = "+\(formattedNumber)"
    }
    return formattedNumber
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).compactMap { _ in letters.randomElement() })
}

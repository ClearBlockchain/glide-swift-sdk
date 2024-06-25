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





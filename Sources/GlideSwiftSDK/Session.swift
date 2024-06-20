import Foundation

enum SessionType: Int {
    case ciba = 0
    case threeLeggedOAuth2 = 1
}

class Session {
    var accessToken: String
    var sessionType: SessionType

    init(accessToken: String, sessionType: SessionType) {
        self.accessToken = accessToken
        self.sessionType = sessionType
    }

    func getScopes() -> [String] {
        if accessToken.isEmpty {
            return []
        }

        // TODO: Implement this
        return []
    }
}

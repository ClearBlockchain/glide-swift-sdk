

enum SDKError: Error {
    case statusCode(Int, String)
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .statusCode(let code, let desctiption):
            return "request failed with status code: \(code). description: \(desctiption)"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}

struct APIError: Codable {
    let error: String
    let error_description: String
}

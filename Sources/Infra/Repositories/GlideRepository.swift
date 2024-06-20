import Foundation

class GlideRepository : AuthRepository {
    
    let authQuery: AuthQuery!
    
    init(authQuery: AuthQuery) {
        self.authQuery = authQuery
    }
    
    func authenticate(completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        authQuery.authenticate(completion: completion)
    }
}

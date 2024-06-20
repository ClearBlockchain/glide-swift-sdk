import Foundation

protocol AuthRepository {
    func authenticate(completion : @escaping (Data?, URLResponse?, Error?) -> Void)
}


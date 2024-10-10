import Foundation

protocol Repository {
    func threeLeggedAuthenticate(config: ThreeLeggedConfig, completion : @escaping ((code: String, state: String)) -> Void)
}


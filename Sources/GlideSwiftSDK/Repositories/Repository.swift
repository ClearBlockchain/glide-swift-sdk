import Foundation

protocol Repository {
    func cibaAuthenticate(authConfig: AuthConfigProtocol, config: GlideConfig, completion : @escaping (String) -> Void)
}


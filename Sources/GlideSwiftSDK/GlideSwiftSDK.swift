//
//  File.swift
//
//
//  Created by amir avisar on 20/06/2024.
//

import Foundation

public final class Glide {
    
    public static var instance: Glide!
    
    private let repository : Repository
    let configs: GlideConfig!
    let authConfigs: AuthConfig!
    
    public static func configure() {
        Glide.instance = Glide(repository: GlideRepository(cibaAuthFlow: CibaAuthFlow(queuesProvider: QueuesProvider())))
    }
    
    init(repository : Repository) {
        self.repository = repository
        
        self.authConfigs = AuthConfig(scopes: ["dpv:FraudPreventionAndDetection:sim-swap", "openId"],
                                      loginHint: "tel:+555123456789",
                                      provider: .ciba)
        
        let clientId = "AGGX07J7DSM318XZPTNMQR"
        let clientSecret =  "wOaUijbYgTkhKNlh8Y0f7vFwtw49drX"
        let redirectUri = "https://dev.gateway-x.io/dev-redirector/callback"
        let authBaseUrl =  "https://oidc.gateway-x.io"
        let apiBaseUrl = "https://api.gateway-x.io"
        
        self.configs = GlideConfig(clientId: clientId, clientSecret: clientSecret, redirectUri: clientSecret, internalUrls: (authBaseUrl: authBaseUrl, apiBaseUrl: apiBaseUrl))
    }
    
    public func cibaAuthenticate(completion: @escaping (String) -> Void) {
        self.repository.cibaAuthenticate(authConfig: self.authConfigs, config: self.configs, completion: completion)
    }
    
}

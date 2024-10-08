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
        Glide.instance = Glide(repository: GlideRepository(cibaAuthFlow: CibaAuthFlow()))
    }
    
    init(repository : Repository) {
        self.repository = repository
        
        self.authConfigs = AuthConfig(scopes: ["dpv:FraudPreventionAndDetection:sim-swap", "openId"],
                                      loginHint: "tel:+555123456789",
                                      provider: .ciba)
        
        let clientId = "AGGX6VJSW4F6UISLLDY5XF"
        let clientSecret =  "wxWg4uh65QU9q8P0Nh3qO2UtAnRp702x"
        let redirectUri = "https://dev.gateway-x.io/dev-redirector/callback"
        let authBaseUrl =  "https://oidc-staging.gateway-x.io"
        let apiBaseUrl = "https://api-staging.gateway-x.io" // this use in sim swap
        let phoneNumber = "+555123456789"
        
        self.configs = GlideConfig(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri, internalUrls: (authBaseUrl: authBaseUrl, apiBaseUrl: apiBaseUrl), phoneNumber: phoneNumber)
    }
    
    public func cibaAuthenticate(completion: @escaping (String) -> Void) {
        self.repository.cibaAuthenticate(authConfig: self.authConfigs, config: self.configs, completion: completion)
    }
    
}

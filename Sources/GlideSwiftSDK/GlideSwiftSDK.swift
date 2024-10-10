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
    private var clientId: String!
    private var redirectUri: String?
    
    public static func configure(clientId: String, redirectUri: String? = nil) {
        Glide.instance = Glide(repository: GlideRepository(threeLeggedAuthFlow: ThreeLeggedAuthFlow()))
        Glide.instance.clientId = clientId
        Glide.instance.redirectUri = redirectUri
    }
    
    init(repository : Repository) {
        self.repository = repository
    }
    
    public func startVerification(state: String, printCode: Bool = false, phoneNumber: String? = nil, completion: @escaping ((code: String, state: String)) -> Void) {
        let config = ThreeLeggedConfig(state: state, printCode: printCode, authBaseUrl: constAuthBaseUrl, clientID: self.clientId, phoneNumber: phoneNumber, redirectUri: self.redirectUri)
        self.repository.threeLeggedAuthenticate(config: config, completion: completion)
    }
    
}



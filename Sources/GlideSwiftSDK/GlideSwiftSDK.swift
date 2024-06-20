//
//  File.swift
//  
//
//  Created by amir avisar on 20/06/2024.
//

import Foundation

final class Glide {
    
    public static var instance: Glide!
    
    public static func configure() {
        Glide.instance = Glide(authRepository: GlideRepository(authQuery: AuthQuery(queuesProvider: QueuesProvider())))
    }
    
    private let authRepository : AuthRepository
    
    init(authRepository : AuthRepository) {
        self.authRepository = authRepository
    }
    
}

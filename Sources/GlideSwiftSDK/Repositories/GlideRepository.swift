import Foundation
import Combine

class GlideRepository : Repository {
    
    let cibaAuthFlow: CibaAuthFlow!
    var cancellables = Set<AnyCancellable>()
    
    init(cibaAuthFlow: CibaAuthFlow) {
        self.cibaAuthFlow = cibaAuthFlow
    }
    
    func cibaAuthenticate(authConfig: AuthConfigProtocol, config: GlideConfig, completion: @escaping (String) -> Void) {
        guard let flow = cibaAuthFlow.authenticate(authConfig: authConfig, config: config) else {return}
        flow.sink(receiveCompletion: { [weak self] complete in
            self?.cancellables.removeAll()
            switch complete {
            case .failure(let error):
                logger.error("CIBA Auth failed with error: \(error)")
            default: break
            }
        }, receiveValue: { [weak self] token in
            logger.info("CIBA Auth success with token: \(token)")
            completion(token)
        })
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
}

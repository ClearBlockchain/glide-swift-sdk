import Foundation
import Combine

class GlideRepository : Repository {
    
    let threeLeggedAuthFlow: ThreeLeggedAuthFlow!
    var cancellables = Set<AnyCancellable>()
    
    init(threeLeggedAuthFlow : ThreeLeggedAuthFlow) {
        self.threeLeggedAuthFlow = threeLeggedAuthFlow
    }
    
    internal func threeLeggedAuthenticate(config: ThreeLeggedConfig, completion: @escaping ((code: String, state: String)) -> Void) {
        guard let flow = threeLeggedAuthFlow.authenticate(config: config) else {return}
        flow.sink(receiveCompletion: { [weak self] complete in
            self?.cancellables.removeAll()
            switch complete {
            case .failure(let error):
                logger.error("\(threeLeggedFlowName) failed with error: \(error)")
            default: break
            }
        }, receiveValue: { response in
            logger.info("\(threeLeggedFlowName) success with status: \(response)")
            completion((code: response.code, state: response.state))
        })
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
}

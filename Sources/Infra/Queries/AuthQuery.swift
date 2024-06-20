import Foundation

class AuthQuery {
    
    private let operationQueue = OperationQueue()
    private let queuesProvider: QueuesProvider!
    
    init (queuesProvider: QueuesProvider) {
        self.queuesProvider = queuesProvider
    }
    
    public func authenticate(completion: @escaping (Data?, URLResponse?, Error?) -> Void){
        
        let firstURL = URL(string: "https://example.com/first")!
        let secondURL = URL(string: "https://example.com/second")!
        
        let firstOperation = queuesProvider.urlRequest(url: firstURL, completion: completion)
        let secondOperation = queuesProvider.urlRequest(url: secondURL, completion: completion)
        
        secondOperation.addDependency(firstOperation)
        
        operationQueue.addOperation(firstOperation)
        operationQueue.addOperation(secondOperation)
    }
    
    
}




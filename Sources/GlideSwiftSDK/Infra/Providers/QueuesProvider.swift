import Foundation
import Combine


struct QueuesProvider {
    
    func urlRequest(url: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> BlockOperation {
        let operation = BlockOperation {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                completion(data, response, error)
            }
            task.resume()
        }
        return operation
    }
    
    func urlRequestPublisher(url: URLRequest) -> URLSession.DataTaskPublisher {
        return URLSession.shared.dataTaskPublisher(for: url)
    }
    
}








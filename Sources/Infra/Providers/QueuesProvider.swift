import Foundation

struct QueuesProvider {
    
    func urlRequest(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> BlockOperation {
        let operation = BlockOperation {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                completion(data, response, error)
            }
            task.resume()
        }
        return operation
    }
    
}







import Foundation

 let logger = AppLogger()

class AppLogger {
    enum LogLevel: String {
        case error = "❌ ERROR"
        case info = "ℹ️ INFO"
        case verbose = "🔍 VERBOSE"
        case debug = "🐛 DEBUG"
    }

    func log(message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        print("\(level.rawValue): [\(filename):\(line)] \(function) -> \(message)")
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, level: .error, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, level: .info, file: file, function: function, line: line)
    }

    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, level: .verbose, file: file, function: function, line: line)
    }

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(message: message, level: .debug, file: file, function: function, line: line)
        #endif
    }
}

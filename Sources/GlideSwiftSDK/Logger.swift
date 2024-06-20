import Logging
import Foundation

// Setup the logger
var logger = Logger(label: "com.glide.swift-sdk")

// Configure logger based on the environment
func configureLogger() {
    if ProcessInfo.processInfo.environment["NODE_ENV"] == "production" {
        LoggingSystem.bootstrap { label in
            var handlers = [LogHandler]()
            handlers.append(StreamLogHandler.standardOutput(label: label))
            return MultiplexLogHandler(handlers)
        }
    } else {
        LoggingSystem.bootstrap { label in
            var handlers = [LogHandler]()
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug // Set log level to debug for non-production
            handlers.append(handler)
            return MultiplexLogHandler(handlers)
        }
    }

    // Set the log level based on environment variable or default to error
    let logLevel = ProcessInfo.processInfo.environment["LOG_LEVEL"] ?? "error"
    logger.logLevel = Logger.Level(rawValue: logLevel) ?? .error
}

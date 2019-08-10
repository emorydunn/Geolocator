//
//  exiftool.swift
//  Geolocator
//
//  Created by Emory Dunn on 15 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation

//public typealias TraceFunction = (_ command: String?, _ response: Data?) -> Void
//
//public struct ProcessResult {
//    let terminationStatus: Int32
//    let response: Data
//}
//
//public enum ExiftoolError: Error, LocalizedError {
//    case responseNotZero(process: Process, stdErr: String?)
//    case exiftoolNotFound(at: String)
//    
//    public var localizedDescription: String {
//        switch self {
//        case .responseNotZero(let p, _):
//            switch p.terminationReason {
//            case .uncaughtSignal:
//                return "exiftool exited with uncaught signal"
//            default:
//                return "exiftool exited normally"
//            }
//        case .exiftoolNotFound(_):
//            return "Exiftool could not be launched"
//        }
//    }
//    
//    public var failureReason: String? {
//        switch self {
//        case .responseNotZero(_, let err):
//            return err
//        case .exiftoolNotFound(let path):
//            return "exiftool not found at \(path)"
//        }
//    }
//}
//
//public class Exiftool: ExiftoolProtocol {
//    
//    public var exiftoolLocation: String
//    public var trace: TraceFunction?
//    
//    static let bundle = Bundle(for: Exiftool.self)
//    
//    public convenience init?(trace: TraceFunction?) {
//        
//        guard let url = Exiftool.bundle.url(forResource: "exiftool", withExtension: nil) else {
//            NSLog("Could not find exiftool in resources of \(Exiftool.bundle.bundleURL.path)")
//            return nil
//        }
//        
//        self.init(exiftool: url.path, trace: trace)
//    }
//    
//    public required init(exiftool: String = "/usr/local/bin/exiftool", trace: TraceFunction?) {
//        self.exiftoolLocation = exiftool
//        self.trace = trace
//    }
//    
//    public required init(exiftool: String = "/usr/local/bin/exiftool") {
//        self.exiftoolLocation = exiftool
//        self.trace = { command, response in
//            if let command = command {
//                NSLog(command)
//            }
//            if let data = response, let respnseString = String(data: data, encoding: .utf8) {
//                NSLog(respnseString)
//            }
//        }
//        
//    }
//}
//
//
//
//public protocol ExiftoolProtocol {
//    
//    var exiftoolLocation: String { get set }
//    var trace: TraceFunction? { get set }
//    
//    init(exiftool: String, trace: TraceFunction?)
//    
//    func execute(arguments: [String]) throws -> ProcessResult
//    
//    func execute<T: Decodable>(arguments: [String]) throws -> T
//    
//}
//
//extension ExiftoolProtocol {
//    
//    public func execute(arguments: [String]) throws -> ProcessResult {
//        
//        guard exiftoolExists(at: exiftoolLocation) else {
//            throw ExiftoolError.exiftoolNotFound(at: exiftoolLocation)
//        }
//        
//        let process = Process()
//        let stdOutPipe = Pipe()
//        let stdErrPipe = Pipe()
//        
//        process.launchPath = exiftoolLocation
//        process.arguments = arguments
//        
//        process.standardOutput = stdOutPipe
//        process.standardError = stdErrPipe
//        
//        trace?("""
//            \(process.launchPath!) \
//            \(process.arguments!.joined(separator: " "))
//            """, nil)
//    
//        process.launch()
//        
//        // Process Pipe into Data
//        let stdOutputData = stdOutPipe.fileHandleForReading.readDataToEndOfFile()
//        let stdErrorData = stdErrPipe.fileHandleForReading.readDataToEndOfFile()
//        
//        process.waitUntilExit()
//        trace?(nil, stdOutputData)
//        
//        if process.terminationStatus != 0 {
//            let errorMessage = String(data: stdErrorData, encoding: .utf8)
//            throw ExiftoolError.responseNotZero(process: process, stdErr: errorMessage)
//        }
//        
//        return ProcessResult(terminationStatus: process.terminationStatus, response: stdOutputData)
//    }
//    
//    public func execute<T: Decodable>(arguments: [String]) throws -> T {
//        let decoder = JSONDecoder()
//        let data: ProcessResult = try execute(arguments: arguments)
//        
//        return try decoder.decode(T.self, from: data.response)
//        
//    }
//    
//    
//    func exiftoolExists(at path: String) -> Bool {
//        let isExec = FileManager.default.isExecutableFile(atPath: path)
//        let exists = FileManager.default.fileExists(atPath: path)
//        
//        return isExec && exists
//    }
//}

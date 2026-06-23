//
//  SSEClient.swift
//  X-Manage
//
//  Server-Sent Events 客户端 - 用于实时进度更新
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.xyouacg.X-Manage", category: "SSE")

// MARK: - SSE 连接状态

enum SSEConnectionState: String {
    case connecting
    case connected
    case disconnected
    case error
}

// MARK: - SSE 事件类型

enum SSEEventType: String {
    case connected
    case progress
    case heartbeat
    case done
    case timeout
    case error
}

// MARK: - SSE 事件数据模型

struct SSEConnectedData: Codable {
    let taskId: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case message
    }
}

struct SSEProgressData: Codable {
    let taskId: String
    let status: String
    let progress: Int
    let phase: String
    let message: String
    let duration: Int
    let error: String?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case progress
        case phase
        case message
        case duration
        case error
    }
}

struct SSEHeartbeatData: Codable {
    let timestamp: Int
}

struct SSEDoneData: Codable {
    let taskId: String
    let status: String
    let message: String
    let duration: Int

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case message
        case duration
    }
}

struct SSETimeoutData: Codable {
    let message: String
}

struct SSEErrorData: Codable {
    let message: String
    let error: String
}

// MARK: - SSE 事件回调

protocol SSEClientDelegate: AnyObject {
    func sseClient(_ client: SSEClient, didChangeState state: SSEConnectionState)
    func sseClient(_ client: SSEClient, didReceiveConnected data: SSEConnectedData)
    func sseClient(_ client: SSEClient, didReceiveProgress data: SSEProgressData)
    func sseClient(_ client: SSEClient, didReceiveHeartbeat data: SSEHeartbeatData)
    func sseClient(_ client: SSEClient, didReceiveDone data: SSEDoneData)
    func sseClient(_ client: SSEClient, didReceiveTimeout data: SSETimeoutData)
    func sseClient(_ client: SSEClient, didReceiveError data: SSEErrorData)
}

// MARK: - 默认实现（可选方法）
extension SSEClientDelegate {
    func sseClient(_ client: SSEClient, didReceiveConnected data: SSEConnectedData) {}
    func sseClient(_ client: SSEClient, didReceiveHeartbeat data: SSEHeartbeatData) {}
    func sseClient(_ client: SSEClient, didReceiveTimeout data: SSETimeoutData) {}
}

// MARK: - SSE 客户端

@MainActor
class SSEClient: NSObject {
    private let taskId: String
    private let baseURL: String
    private let endpoint: String

    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var buffer = Data()

    private(set) var state: SSEConnectionState = .disconnected {
        didSet {
            if oldValue != state {
                delegate?.sseClient(self, didChangeState: state)
            }
        }
    }

    weak var delegate: SSEClientDelegate?

    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    private let reconnectDelay: TimeInterval = 1.0
    // 总连接超时上限，避免 .infinity 让任务无限挂起
    private let resourceTimeout: TimeInterval = 60 * 60

    init(taskId: String, baseURL: String, endpoint: String) {
        self.taskId = taskId
        self.baseURL = baseURL
        self.endpoint = endpoint
        super.init()
    }

    deinit {
        // URLSession 强引用 delegate（self），必须显式失效；invalidateAndCancel 线程安全
        urlSession?.invalidateAndCancel()
    }

    // MARK: - 连接管理

    func connect() {
        disconnect()
        state = .connecting

        guard let url = URL(string: baseURL + endpoint) else {
            logger.error("Invalid SSE URL")
            state = .error
            return
        }

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        // token 通过 Authorization 头传递，避免出现在 URL 与日志中
        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = resourceTimeout

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval.infinity
        config.timeoutIntervalForResource = resourceTimeout

        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = urlSession?.dataTask(with: request)
        dataTask?.resume()

        logger.info("SSE connecting (task: \(self.taskId))")
    }

    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        buffer.removeAll()
        state = .disconnected
        reconnectAttempts = 0
        logger.info("SSE disconnected")
    }

    // MARK: - 重连逻辑

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            logger.error("SSE max reconnect attempts reached")
            let errorData = SSEErrorData(message: "连接失败，已达到最大重试次数", error: "MAX_RECONNECT_ATTEMPTS")
            delegate?.sseClient(self, didReceiveError: errorData)
            return
        }

        reconnectAttempts += 1
        let delay = reconnectDelay * pow(2.0, Double(reconnectAttempts - 1))
        logger.info("SSE reconnecting in \(delay)s (attempt \(self.reconnectAttempts))")

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, self.state == .error || self.state == .disconnected else { return }
            self.connect()
        }
    }

    // MARK: - 数据解析

    fileprivate func appendData(_ data: Data) {
        buffer.append(data)
        processBuffer()
    }

    private func processBuffer() {
        guard let string = String(data: buffer, encoding: .utf8) else { return }

        let lines = string.components(separatedBy: "\n\n")
        guard lines.count > 1 else { return }

        // 保留最后一个不完整的事件
        let completeEvents = lines.dropLast()
        if let lastEvent = lines.last {
            buffer = Data(lastEvent.utf8)
        } else {
            buffer.removeAll()
        }

        for eventBlock in completeEvents {
            parseEvent(eventBlock)
        }
    }

    private func parseEvent(_ eventBlock: String) {
        var eventType: String?
        var eventData: String?

        for line in eventBlock.components(separatedBy: "\n") {
            if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                eventData = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }

        guard let type = eventType, let data = eventData else { return }

        logger.debug("SSE event: \(type), data: \(data)")

        handleEvent(type: type, data: data)
    }

    fileprivate func handleTransportError(_ error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        logger.error("SSE connection error: \(error.localizedDescription)")
        state = .error
        attemptReconnect()
    }

    fileprivate func handleResponse(statusCode: Int) {
        if statusCode == 200 {
            logger.info("SSE connection established")
        } else {
            logger.error("SSE connection failed with status: \(statusCode)")
            state = .error
        }
    }

    private func handleEvent(type: String, data: String) {
        guard let jsonData = data.data(using: .utf8) else { return }
        let decoder = JSONDecoder()

        do {
            switch type {
            case "connected":
                let event = try decoder.decode(SSEConnectedData.self, from: jsonData)
                state = .connected
                reconnectAttempts = 0
                delegate?.sseClient(self, didReceiveConnected: event)

            case "progress":
                let event = try decoder.decode(SSEProgressData.self, from: jsonData)
                delegate?.sseClient(self, didReceiveProgress: event)

            case "heartbeat":
                let event = try decoder.decode(SSEHeartbeatData.self, from: jsonData)
                delegate?.sseClient(self, didReceiveHeartbeat: event)

            case "done":
                let event = try decoder.decode(SSEDoneData.self, from: jsonData)
                delegate?.sseClient(self, didReceiveDone: event)
                disconnect()

            case "timeout":
                let event = try decoder.decode(SSETimeoutData.self, from: jsonData)
                delegate?.sseClient(self, didReceiveTimeout: event)
                disconnect()

            case "error":
                let event = try decoder.decode(SSEErrorData.self, from: jsonData)
                delegate?.sseClient(self, didReceiveError: event)

            default:
                logger.warning("Unknown SSE event type: \(type)")
            }
        } catch {
            logger.error("SSE event decode error: \(error.localizedDescription)")
        }
    }
}

// MARK: - URLSessionDataDelegate

extension SSEClient: URLSessionDataDelegate {
    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Task { @MainActor [weak self] in
            self?.appendData(data)
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        Task { @MainActor [weak self] in
            self?.handleTransportError(error)
        }
    }

    nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        Task { @MainActor [weak self] in
            if let statusCode {
                self?.handleResponse(statusCode: statusCode)
            }
        }
        completionHandler(.allow)
    }
}

// MARK: - 转码任务 SSE 客户端工厂

@MainActor
class TranscodeSSEClientFactory {
    static func create(taskId: String) -> SSEClient {
        let baseURL = APIClient.shared.baseURL
        let endpoint = APIEndpoints.Transcode.stream(taskId)
        return SSEClient(taskId: taskId, baseURL: baseURL, endpoint: endpoint)
    }
}

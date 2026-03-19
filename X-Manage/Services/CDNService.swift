//
//  CDNService.swift
//  X-Manage
//
//  CDN 节点管理服务（通过 admin-gateway API）

import Foundation

@MainActor
class CDNService: ObservableObject {
    static let shared = CDNService()
    private let client = APIClient.shared
    private init() {}

    // MARK: - 节点 CRUD

    func listNodes() async throws -> [CDNNode] {
        struct Resp: Decodable {
            let nodes: [CDNNode]
            let total: Int64
        }
        let resp: Resp = try await client.request(endpoint: APIEndpoints.CDN.nodes)
        return resp.nodes
    }

    func getNode(_ id: Int) async throws -> CDNNode {
        try await client.request(endpoint: APIEndpoints.CDN.node(id))
    }

    func createNode(_ req: CDNNodeCreateRequest) async throws -> CDNNode {
        try await client.request(endpoint: APIEndpoints.CDN.nodes, method: .post, body: req)
    }

    func updateNode(_ id: Int, _ req: CDNNodeCreateRequest) async throws -> CDNNode {
        try await client.request(endpoint: APIEndpoints.CDN.node(id), method: .put, body: req)
    }

    func deleteNode(_ id: Int) async throws {
        try await client.requestVoid(endpoint: APIEndpoints.CDN.node(id), method: .delete)
    }

    // MARK: - 节点操作

    func getNodeStats(_ id: Int) async throws -> CDNCacheStats {
        // 响应: {node_id, node_name, stats: {...}}
        struct Resp: Decodable {
            struct Stats: Decodable {
                let cacheSizeMb: Int64
                let cacheFiles: Int64
                let diskTotalGb: Int64
                let diskFreeGb: Int64
                let diskUsedPct: Int
                let maxSizeGb: Int64
                enum CodingKeys: String, CodingKey {
                    case cacheSizeMb = "cache_size_mb"
                    case cacheFiles = "cache_files"
                    case diskTotalGb = "disk_total_gb"
                    case diskFreeGb = "disk_free_gb"
                    case diskUsedPct = "disk_used_pct"
                    case maxSizeGb = "max_size_gb"
                }
            }
            let nodeId: Int
            let nodeName: String
            let stats: Stats
            enum CodingKeys: String, CodingKey {
                case nodeId = "node_id"
                case nodeName = "node_name"
                case stats
            }
        }
        let resp: Resp = try await client.request(endpoint: APIEndpoints.CDN.nodeStats(id))
        let s = resp.stats
        return CDNCacheStats(
            nodeId: resp.nodeId,
            nodeName: resp.nodeName,
            cacheSizeMb: s.cacheSizeMb,
            cacheFiles: s.cacheFiles,
            diskTotalGb: s.diskTotalGb,
            diskFreeGb: s.diskFreeGb,
            diskUsedPct: s.diskUsedPct,
            maxSizeGb: s.maxSizeGb,
            error: nil
        )
    }

    func evictNodeCache(_ id: Int) async throws -> CDNCacheEvictResult {
        try await client.request(endpoint: APIEndpoints.CDN.nodeEvict(id), method: .post)
    }

    func clearNodeCache(_ id: Int) async throws -> CDNCacheClearResult {
        try await client.request(endpoint: APIEndpoints.CDN.nodeClear(id), method: .post)
    }

    func getNodeDownloads(_ id: Int) async throws -> CDNDownloadSnapshot {
        try await client.request(endpoint: APIEndpoints.CDN.nodeDownloads(id))
    }

    func checkNodeHealth(_ id: Int) async throws {
        try await client.requestVoid(endpoint: APIEndpoints.CDN.nodeHealth(id))
    }

    func pushNodeConfig(_ id: Int) async throws {
        try await client.requestVoid(endpoint: APIEndpoints.CDN.nodeConfigPush(id), method: .post)
    }

    struct SyncResult: Decodable {
        let nodeId: Int
        let synced: Int
        let skipped: Int
        let errors: [String]?
        enum CodingKeys: String, CodingKey {
            case nodeId = "node_id"
            case synced, skipped, errors
        }
    }

    func syncNodeDomains(_ id: Int) async throws -> SyncResult {
        try await client.request(endpoint: APIEndpoints.CDN.nodeDomainSync(id), method: .post)
    }

    func getNodeRunningConfig(_ id: Int) async throws -> CDNRunningConfig {
        // 响应: {node_id, running: {...}}
        struct Resp: Decodable {
            let running: CDNRunningConfig
        }
        let resp: Resp = try await client.request(endpoint: APIEndpoints.CDN.nodeRunningConfig(id))
        return resp.running
    }

    // MARK: - 域名管理

    func listNodeDomains(_ nodeId: Int) async throws -> [CDNNodeDomain] {
        struct Resp: Decodable {
            let domains: [CDNNodeDomain]
        }
        let resp: Resp = try await client.request(endpoint: APIEndpoints.CDN.nodeDomains(nodeId))
        return resp.domains
    }

    func addNodeDomain(_ nodeId: Int, req: CDNDomainAddRequest) async throws -> CDNNodeDomain {
        try await client.request(endpoint: APIEndpoints.CDN.nodeDomains(nodeId), method: .post, body: req)
    }

    func updateNodeDomain(_ nodeId: Int, domainId: Int, req: CDNDomainAddRequest) async throws -> CDNNodeDomain {
        try await client.request(endpoint: APIEndpoints.CDN.nodeDomain(nodeId, domainId), method: .put, body: req)
    }

    func deleteNodeDomain(_ nodeId: Int, domainId: Int) async throws {
        try await client.requestVoid(endpoint: APIEndpoints.CDN.nodeDomain(nodeId, domainId), method: .delete)
    }

    // MARK: - 聚合

    func getAllDownloads() async throws -> [CDNNodeDownloadSnapshot] {
        struct Resp: Decodable { let nodes: [CDNNodeDownloadSnapshot] }
        let resp: Resp = try await client.request(endpoint: APIEndpoints.CDN.downloads)
        return resp.nodes
    }

    func getAllStats() async throws -> [CDNCacheStats] {
        // 响应: {nodes: [{node_id, node_name, region, enabled, cache_size_mb, ...}]}
        struct NodeStats: Decodable {
            let nodeId: Int
            let nodeName: String
            let region: String
            let enabled: Bool
            let cacheSizeMb: Int64
            let cacheFiles: Int64
            let diskTotalGb: Int64
            let diskFreeGb: Int64
            let diskUsedPct: Int
            let maxSizeGb: Int64
            let error: String?
            enum CodingKeys: String, CodingKey {
                case nodeId = "node_id"
                case nodeName = "node_name"
                case region, enabled, error
                case cacheSizeMb = "cache_size_mb"
                case cacheFiles = "cache_files"
                case diskTotalGb = "disk_total_gb"
                case diskFreeGb = "disk_free_gb"
                case diskUsedPct = "disk_used_pct"
                case maxSizeGb = "max_size_gb"
            }
        }
        struct Resp: Decodable { let nodes: [NodeStats] }
        let resp: Resp = try await client.request(endpoint: APIEndpoints.CDN.allStats)
        return resp.nodes.map {
            CDNCacheStats(
                nodeId: $0.nodeId,
                nodeName: $0.nodeName,
                cacheSizeMb: $0.cacheSizeMb,
                cacheFiles: $0.cacheFiles,
                diskTotalGb: $0.diskTotalGb,
                diskFreeGb: $0.diskFreeGb,
                diskUsedPct: $0.diskUsedPct,
                maxSizeGb: $0.maxSizeGb,
                error: $0.error
            )
        }
    }
}

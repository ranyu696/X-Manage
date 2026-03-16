//
//  CDN.swift
//  X-Manage
//
//  CDN 代理管理模型

import Foundation

// MARK: - 缓存统计
struct CDNCacheStats: Codable {
    let cacheSizeMb: Int
    let cacheFiles: Int
    let diskTotalGb: Int
    let diskFreeGb: Int
    let diskUsedPct: Int
    let maxSizeGb: Int

    enum CodingKeys: String, CodingKey {
        case cacheSizeMb = "cache_size_mb"
        case cacheFiles = "cache_files"
        case diskTotalGb = "disk_total_gb"
        case diskFreeGb = "disk_free_gb"
        case diskUsedPct = "disk_used_pct"
        case maxSizeGb = "max_size_gb"
    }
}

// MARK: - 缓存淘汰结果
struct CDNCacheEvictResult: Codable {
    let evictedFiles: Int
    let evictedMb: Int
    let currentMb: Int

    enum CodingKeys: String, CodingKey {
        case evictedFiles = "evicted_files"
        case evictedMb = "evicted_mb"
        case currentMb = "current_mb"
    }
}

// MARK: - 缓存清空结果
struct CDNCacheClearResult: Codable {
    let clearedFiles: Int
    let clearedMb: Int

    enum CodingKeys: String, CodingKey {
        case clearedFiles = "cleared_files"
        case clearedMb = "cleared_mb"
    }
}

// MARK: - 反代域名配置
struct CDNDomainConfig: Codable, Identifiable {
    var domain: String
    var target: String
    var enabled: Bool

    var id: String { domain }

    enum CodingKeys: String, CodingKey {
        case domain, target, enabled
    }
}

// MARK: - 新增/更新域名请求
struct CDNDomainRequest: Codable {
    let domain: String
    let target: String
    let enabled: Bool
}

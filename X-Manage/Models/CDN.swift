//
//  CDN.swift
//  X-Manage
//
//  CDN 节点管理模型

import Foundation

// MARK: - CDN 节点（CDNNodeSafe 不含敏感凭证）

struct CDNNode: Codable, Identifiable {
    var id: Int
    var name: String
    var description: String
    var region: String
    var enabled: Bool
    var url: String
    var healthStatus: String
    var lastHealthAt: String?
    var r2AccountId: String?
    var r2Region: String?
    var animeR2BucketName: String?
    var gameR2BucketName: String?
    var comicR2BucketName: String?
    var novelR2BucketName: String?
    var downloadR2BucketName: String?
    var cacheDir: String?
    var cacheMaxSize: Int64
    var rateLimitEnabled: Bool
    var rateLimitPerIp: Int
    var segmentRateLimitPerIp: Int
    var imageRateLimitPerIp: Int
    var bandwidthLimitMbps: Int
    var logLevel: String
    var metricsEnabled: Bool
    var autoCertEmail: String?
    var httpPort: String
    var httpsPort: String
    var domains: [CDNNodeDomain]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, region, enabled, url, domains
        case healthStatus = "health_status"
        case lastHealthAt = "last_health_at"
        case r2AccountId = "r2_account_id"
        case r2Region = "r2_region"
        case animeR2BucketName = "anime_r2_bucket_name"
        case gameR2BucketName = "game_r2_bucket_name"
        case comicR2BucketName = "comic_r2_bucket_name"
        case novelR2BucketName = "novel_r2_bucket_name"
        case downloadR2BucketName = "download_r2_bucket_name"
        case cacheDir = "cache_dir"
        case cacheMaxSize = "cache_max_size"
        case rateLimitEnabled = "rate_limit_enabled"
        case rateLimitPerIp = "rate_limit_per_ip"
        case segmentRateLimitPerIp = "segment_rate_limit_per_ip"
        case imageRateLimitPerIp = "image_rate_limit_per_ip"
        case bandwidthLimitMbps = "bandwidth_limit_mbps"
        case logLevel = "log_level"
        case metricsEnabled = "metrics_enabled"
        case autoCertEmail = "auto_cert_email"
        case httpPort = "http_port"
        case httpsPort = "https_port"
    }
}

// MARK: - CDN 节点域名

struct CDNNodeDomain: Codable, Identifiable {
    var id: Int
    var nodeId: Int
    var domain: String
    var target: String
    var note: String
    var enabled: Bool
    var forceHttps: Bool
    var cacheTtl: Int
    var certStatus: String
    var certIssuedAt: String?
    var certExpireAt: String?
    var certError: String?

    enum CodingKeys: String, CodingKey {
        case id, domain, target, note, enabled
        case nodeId = "node_id"
        case forceHttps = "force_https"
        case cacheTtl = "cache_ttl"
        case certStatus = "cert_status"
        case certIssuedAt = "cert_issued_at"
        case certExpireAt = "cert_expire_at"
        case certError = "cert_error"
    }
}

// MARK: - 缓存统计（单节点 /stats 直接返回）

struct CDNCacheStats: Codable {
    let nodeId: Int
    let nodeName: String
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
        case cacheSizeMb = "cache_size_mb"
        case cacheFiles = "cache_files"
        case diskTotalGb = "disk_total_gb"
        case diskFreeGb = "disk_free_gb"
        case diskUsedPct = "disk_used_pct"
        case maxSizeGb = "max_size_gb"
        case error
    }
}

struct CDNCacheEvictResult: Codable {
    let evictedFiles: Int
    let evictedMb: Int64
    let currentMb: Int64

    enum CodingKeys: String, CodingKey {
        case evictedFiles = "evicted_files"
        case evictedMb = "evicted_mb"
        case currentMb = "current_mb"
    }
}

struct CDNCacheClearResult: Codable {
    let clearedFiles: Int
    let clearedMb: Int64

    enum CodingKeys: String, CodingKey {
        case clearedFiles = "cleared_files"
        case clearedMb = "cleared_mb"
    }
}

// MARK: - 节点运行时配置（cdn-proxy RuntimeConfigView）

struct CDNRunningConfig: Codable {
    var logLevel: String
    var rateLimitEnabled: Bool
    var rateLimitPerIp: Int
    var segmentRateLimitPerIp: Int
    var imageRateLimitPerIp: Int
    var bandwidthLimitMbps: Int
    var cacheMaxSize: Int64
    var cacheDir: String
    var r2AccountId: String
    var r2Region: String
    var httpsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case logLevel = "log_level"
        case rateLimitEnabled = "rate_limit_enabled"
        case rateLimitPerIp = "rate_limit_per_ip"
        case segmentRateLimitPerIp = "segment_rate_limit_per_ip"
        case imageRateLimitPerIp = "image_rate_limit_per_ip"
        case bandwidthLimitMbps = "bandwidth_limit_mbps"
        case cacheMaxSize = "cache_max_size"
        case cacheDir = "cache_dir"
        case r2AccountId = "r2_account_id"
        case r2Region = "r2_region"
        case httpsEnabled = "https_enabled"
    }
}

// MARK: - 下载监控

struct CDNDownloadInfo: Codable, Identifiable {
    let id: String
    let userId: String
    let fileKey: String
    let totalSize: Int64
    let bytesSent: Int64
    let clientIp: String
    let speedBps: Double
    let progress: Double
    let cacheHit: Bool

    enum CodingKeys: String, CodingKey {
        case id, progress
        case userId = "user_id"
        case fileKey = "file_key"
        case totalSize = "total_size"
        case bytesSent = "bytes_sent"
        case clientIp = "client_ip"
        case speedBps = "speed_bps"
        case cacheHit = "cache_hit"
    }
}

// 单节点下载快照（GET /cdn/nodes/{id}/downloads）
struct CDNDownloadSnapshot: Codable {
    let timestamp: Int64
    let activeDownloads: [CDNDownloadInfo]
    let totalActive: Int
    let totalBandwidthBps: Double

    enum CodingKeys: String, CodingKey {
        case timestamp
        case activeDownloads = "active_downloads"
        case totalActive = "total_active"
        case totalBandwidthBps = "total_bandwidth_bps"
    }
}

// 聚合下载快照（GET /cdn/downloads，每节点一个）
struct CDNNodeDownloadSnapshot: Codable {
    let nodeId: Int
    let nodeName: String
    let region: String
    let timestamp: Int64
    let activeDownloads: [CDNDownloadInfo]
    let totalActive: Int
    let totalBandwidthBps: Double
    let error: String?

    enum CodingKeys: String, CodingKey {
        case nodeId = "node_id"
        case nodeName = "node_name"
        case region, timestamp, error
        case activeDownloads = "active_downloads"
        case totalActive = "total_active"
        case totalBandwidthBps = "total_bandwidth_bps"
    }
}

// MARK: - 创建/更新节点请求

struct CDNNodeCreateRequest: Encodable {
    var name: String
    var url: String
    var token: String
    var description: String
    var region: String
    var enabled: Bool = true
    var r2AccountId: String
    var r2AccessKeyId: String
    var r2SecretAccessKey: String
    var r2Region: String
    var animeR2BucketName: String
    var gameR2BucketName: String
    var comicR2BucketName: String
    var novelR2BucketName: String
    var downloadR2BucketName: String
    var signSecret: String
    var cacheDir: String
    var cacheMaxSize: Int64
    var rateLimitEnabled: Bool
    var rateLimitPerIp: Int
    var segmentRateLimitPerIp: Int
    var imageRateLimitPerIp: Int
    var bandwidthLimitMbps: Int
    var logLevel: String
    var metricsEnabled: Bool
    var autoCertEmail: String
    var httpPort: String
    var httpsPort: String

    enum CodingKeys: String, CodingKey {
        case name, url, token, description, region, enabled
        case r2AccountId = "r2_account_id"
        case r2AccessKeyId = "r2_access_key_id"
        case r2SecretAccessKey = "r2_secret_access_key"
        case r2Region = "r2_region"
        case animeR2BucketName = "anime_r2_bucket_name"
        case gameR2BucketName = "game_r2_bucket_name"
        case comicR2BucketName = "comic_r2_bucket_name"
        case novelR2BucketName = "novel_r2_bucket_name"
        case downloadR2BucketName = "download_r2_bucket_name"
        case signSecret = "sign_secret"
        case cacheDir = "cache_dir"
        case cacheMaxSize = "cache_max_size"
        case rateLimitEnabled = "rate_limit_enabled"
        case rateLimitPerIp = "rate_limit_per_ip"
        case segmentRateLimitPerIp = "segment_rate_limit_per_ip"
        case imageRateLimitPerIp = "image_rate_limit_per_ip"
        case bandwidthLimitMbps = "bandwidth_limit_mbps"
        case logLevel = "log_level"
        case metricsEnabled = "metrics_enabled"
        case autoCertEmail = "auto_cert_email"
        case httpPort = "http_port"
        case httpsPort = "https_port"
    }
}

// MARK: - 添加域名请求

struct CDNDomainAddRequest: Encodable {
    var domain: String
    var target: String
    var note: String
    var enabled: Bool
    var forceHttps: Bool
    var cacheTtl: Int

    enum CodingKeys: String, CodingKey {
        case domain, target, note, enabled
        case forceHttps = "force_https"
        case cacheTtl = "cache_ttl"
    }
}

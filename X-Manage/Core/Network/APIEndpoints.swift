//
//  APIEndpoints.swift
//  X-Manage
//
//  API 端点定义

import Foundation

enum APIEndpoints {
    static let basePrefix = "/api/v1"

    // MARK: - 认证
    enum Auth {
        static let login = "\(basePrefix)/auth/login"
        static let refresh = "\(basePrefix)/auth/refresh"
        static let me = "\(basePrefix)/auth/me"
    }

    // MARK: - 漫画
    enum Comics {
        static let list = "\(basePrefix)/comics"
        static func detail(_ id: Int) -> String { "\(basePrefix)/comics/\(id)" }
        static let chapters = "\(basePrefix)/comic-chapters"
        static func chapterDetail(_ id: Int) -> String { "\(basePrefix)/comic-chapters/\(id)" }
        static let pages = "\(basePrefix)/comic-pages"
        static let pricings = "\(basePrefix)/comic-pricings"
        static func pricingDetail(_ id: Int) -> String { "\(basePrefix)/comic-pricings/\(id)" }
        static let orders = "\(basePrefix)/comic-orders"
        static let comments = "\(basePrefix)/comic-comments"
        // 封面上传
        static func uploadCover(_ slug: String) -> String { "\(basePrefix)/comics/\(slug)/upload/cover" }
        static func updateCover(_ id: Int) -> String { "\(basePrefix)/comics/\(id)/cover" }
    }

    // MARK: - 游戏
    enum Games {
        static let list = "\(basePrefix)/games"
        static func detail(_ id: Int) -> String { "\(basePrefix)/games/\(id)" }
        static func versions(_ gameId: Int) -> String { "\(basePrefix)/games/\(gameId)/versions" }
        static let pricings = "\(basePrefix)/games/pricings"
        static func pricingDetail(_ id: Int) -> String { "\(basePrefix)/games/pricings/\(id)" }
        static let orders = "\(basePrefix)/games/orders"
        static let comments = "\(basePrefix)/comments"
        // 图片上传
        static func uploadCovers(_ slug: String) -> String { "\(basePrefix)/games/\(slug)/upload/covers" }
        static func uploadContents(_ slug: String) -> String { "\(basePrefix)/games/\(slug)/upload/contents" }
        static func uploadUpdates(_ slug: String) -> String { "\(basePrefix)/games/\(slug)/upload/updates" }
        static func updateCovers(_ id: Int) -> String { "\(basePrefix)/games/\(id)/covers" }
        static func updateContentImages(_ id: Int) -> String { "\(basePrefix)/games/\(id)/content-images" }
        static func updateUpdateImages(_ id: Int) -> String { "\(basePrefix)/games/\(id)/update-images" }
    }

    // MARK: - 小说
    enum Novels {
        static let list = "\(basePrefix)/novels"
        static func detail(_ id: Int) -> String { "\(basePrefix)/novels/\(id)" }
        static let chapters = "\(basePrefix)/novel-chapters"
        static let pricings = "\(basePrefix)/novel-pricings"
        static func pricingDetail(_ id: Int) -> String { "\(basePrefix)/novel-pricings/\(id)" }
        static let orders = "\(basePrefix)/novel-orders"
        static let comments = "\(basePrefix)/novel-comments"
        // 封面上传
        static func uploadCover(_ slug: String) -> String { "\(basePrefix)/novels/\(slug)/upload/cover" }
        static func updateCover(_ id: Int) -> String { "\(basePrefix)/novels/\(id)/cover" }
    }

    // MARK: - 动漫
    enum Anime {
        static let list = "\(basePrefix)/animes"
        static func detail(_ id: Int) -> String { "\(basePrefix)/animes/\(id)" }
        static func episodes(_ animeId: Int) -> String { "\(basePrefix)/animes/\(animeId)/episodes" }
        static let pricings = "\(basePrefix)/animes/pricings"
        static func pricingDetail(_ id: Int) -> String { "\(basePrefix)/animes/pricings/\(id)" }
        static let orders = "\(basePrefix)/anime-orders"
        static let comments = "\(basePrefix)/animes/comments"
        static let transcode = "\(basePrefix)/transcode/tasks"
        // 剧集相关
        static func episodeDetail(_ episodeId: Int) -> String { "\(basePrefix)/episodes/\(episodeId)" }
        static let episodeCoverUpload = "\(basePrefix)/anime/episodes/cover/upload-url"
        static let episodeFanartUpload = "\(basePrefix)/anime/episodes/fanart/upload-url"
        static let videoUploadInit = "\(basePrefix)/anime/upload/init"
        static func videoUploadComplete(_ uploadId: String) -> String { "\(basePrefix)/anime/upload/\(uploadId)/complete" }
        static let subtitleUploadURL = "\(basePrefix)/anime/episodes/subtitle/upload-url"
    }

    // MARK: - 漫画上传任务
    enum ComicTasks {
        static let list = "\(basePrefix)/comics/upload/tasks"
        static func detail(_ taskId: String) -> String { "\(basePrefix)/comics/upload/tasks/\(taskId)" }
        static func action(_ taskId: String) -> String { "\(basePrefix)/comics/upload/tasks/\(taskId)/action" }
        static func retry(_ taskId: String) -> String { "\(basePrefix)/comics/upload/tasks/\(taskId)/retry" }
    }

    // MARK: - 转码任务
    enum Transcode {
        static let tasks = "\(basePrefix)/transcode/tasks"
        static func detail(_ taskId: String) -> String { "\(basePrefix)/transcode/tasks/\(taskId)" }
        static func retry(_ taskId: String) -> String { "\(basePrefix)/transcode/tasks/\(taskId)/retry" }
        static func cancel(_ taskId: String) -> String { "\(basePrefix)/transcode/tasks/\(taskId)/cancel" }
        static func stream(_ taskId: String) -> String { "\(basePrefix)/transcode/tasks/\(taskId)/stream" }
    }

    // MARK: - 用户
    enum Users {
        static let list = "\(basePrefix)/users"
        static func detail(_ id: Int) -> String { "\(basePrefix)/users/\(id)" }
        static func stats(_ id: Int) -> String { "\(basePrefix)/users/\(id)/stats" }
        static func balance(_ id: Int) -> String { "\(basePrefix)/users/\(id)/balance" }
        static func vip(_ id: Int) -> String { "\(basePrefix)/users/\(id)/vip" }
        static func ban(_ id: Int) -> String { "\(basePrefix)/users/\(id)/ban" }
        static func unban(_ id: Int) -> String { "\(basePrefix)/users/\(id)/unban" }
    }

    // MARK: - 分类
    enum Categories {
        static let list = "\(basePrefix)/categories"
        static let tree = "\(basePrefix)/categories/tree"
        static func detail(_ id: Int) -> String { "\(basePrefix)/categories/\(id)" }
        static func children(_ id: Int) -> String { "\(basePrefix)/categories/\(id)/children" }
        static func childrenBySlug(_ slug: String) -> String { "\(basePrefix)/categories/slug/\(slug)/children" }
    }

    // MARK: - 标签
    enum Tags {
        static let list = "\(basePrefix)/tags"
        static func detail(_ id: Int) -> String { "\(basePrefix)/tags/\(id)" }
    }

    // MARK: - 工单
    enum Tickets {
        static let list = "\(basePrefix)/tickets"
        static func detail(_ id: Int) -> String { "\(basePrefix)/tickets/\(id)" }
        static func replies(_ ticketId: Int) -> String { "\(basePrefix)/tickets/\(ticketId)/replies" }
    }

    // MARK: - 支付
    enum Payments {
        static let list = "\(basePrefix)/payments"
        static let stats = "\(basePrefix)/payments/stats"
    }

    // MARK: - 系统配置
    enum Configs {
        static let list = "\(basePrefix)/configs"
    }

    // MARK: - 应用版本
    enum AppVersions {
        static let list = "\(basePrefix)/app-versions"
        static func detail(_ id: Int) -> String { "\(basePrefix)/app-versions/\(id)" }
        static func publish(_ id: Int) -> String { "\(basePrefix)/app-versions/\(id)/publish" }
        static func deprecate(_ id: Int) -> String { "\(basePrefix)/app-versions/\(id)/deprecate" }
        static func uploadUrl(_ id: Int) -> String { "\(basePrefix)/app-versions/\(id)/upload-url" }
        static func confirmUpload(_ id: Int) -> String { "\(basePrefix)/app-versions/\(id)/confirm-upload" }
        static let devices = "\(basePrefix)/app-versions/devices"
        static let updateLogs = "\(basePrefix)/app-versions/update-logs"
    }
}

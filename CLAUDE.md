# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a macOS SwiftUI app built with Xcode. Open `X-Manage.xcodeproj` in Xcode.

```bash
# Build from command line
xcodebuild -scheme X-Manage -configuration Debug build

# Run tests
xcodebuild -scheme X-Manage -configuration Debug test
```

The scheme is at `X-Manage.xcodeproj/xcshareddata/xcschemes/X-Manage.xcscheme`. Test targets (X-ManageTests, X-ManageUITests) exist but are currently empty.

## Dependencies

Managed via Swift Package Manager (no CocoaPods/Carthage). Key packages:
- **swift-nio** + **swift-nio-ssl** — async networking
- **swift-dotenv** — environment configuration
- **swift-log** — logging
- **SwiftMail** + **swift-nio-imap** — email functionality

Resolve packages: Xcode > File > Packages > Resolve Package Versions.

## Architecture

**Layered MVVM + Service pattern** with three main layers:

### Core Layer (`Core/`)
- **AuthManager** — Singleton (`AuthManager.shared`), `@MainActor`. Manages login/logout, stores tokens in Keychain (service: `com.xyouacg.X-Manage`), user in UserDefaults. Publishes `isAuthenticated`.
- **APIClient** — Singleton (`APIClient.shared`), `@MainActor`. Generic `request<T>()` and `requestVoid()` methods. Handles automatic token refresh on 401, gzip compression for payloads >1024 bytes, snake_case JSON decoding, request ID logging, and RFC 7807 error responses. Base URL is user-configurable via `UserDefaults`.

### Service Layer (`Services/`)
Each domain has a dedicated `@MainActor` singleton service (e.g., `ComicService.shared`) conforming to a protocol (e.g., `ComicServiceProtocol`). Services encapsulate API calls and expose typed async methods. Query parameters are encapsulated in parameter structs (e.g., `ComicListParams`).

Services: Comic, Game, Novel, Anime, User, Category, Tag, Ticket, Payment, Comment, Email, Config, AppVersion, Upload, ComicZipUploader, AnimeVideoUploader, GeminiService, SSEClient.

### Model Layer (`Models/`)
Swift structs conforming to `Codable`. Use `CodingKeys` for snake_case ↔ camelCase mapping. `Common.swift` contains shared types: `PaginationMeta` (supports multiple API pagination formats), `PaginationParams`, and various request/response wrappers.

### View Layer (`Views/`)
Organized by feature domain. Each domain typically has:
- `{Domain}ListView` — table with filtering, pagination, and a collapsible detail side panel
- `{Domain}DetailView` — shown in the side panel
- `{Domain}CreateView` — sheet overlay for creation/editing

**Navigation**: `MainView.swift` uses `NavigationSplitView` with a sidebar. The sidebar has expandable groups: Content Management (Comics, Games, Novels, Anime), System Management (Users, Categories, Tags), Operations (Comments, Tickets, Emails, Payments), and System (AppVersions, Config, Settings).

**App entry** (`X_ManageApp.swift`): Injects `AuthManager` as `@EnvironmentObject`. Shows `LoginView` when unauthenticated, `MainView` when authenticated.

### Reusable Components (`Views/Components/`)
- `PaginationView` — table pagination controls
- `CollapsibleDetailPanel` — expandable side panel for detail views
- `DetailPlaceholderView` — empty state placeholder
- `ImageUploader` — image selection and upload

## Conventions

- All services and managers use `@MainActor` and singleton pattern (`static let shared`)
- API endpoints defined as static properties/functions in `APIEndpoints` enum (nested by domain)
- All API routes use prefix `/api/v1`
- Async/await throughout — no Combine publishers or completion handlers for network calls
- Views use `@StateObject` for view models, `@State` for local UI state
- Comments and UI strings are in Chinese (zh-Hans)

## Network & Auth Flow

1. `LoginView` calls `AuthManager.login()` → `APIClient` posts to `/auth/login`
2. Tokens saved to Keychain, user to UserDefaults, `isAuthenticated` set to `true`
3. All subsequent requests get `Bearer {accessToken}` header via `APIClient`
4. On 401 response, `APIClient` automatically calls `/auth/refresh` and retries
5. `SSEClient` handles real-time progress updates (transcoding, uploads) via Server-Sent Events

## App Configuration

- **Entitlements**: App sandbox disabled, network client/server access enabled, user-selected file read/write
- **Info.plist**: Allows arbitrary HTTP loads (`NSAllowsArbitraryLoads: true`)
- Minimum window size: 1200x800

//
//  DashVideoPlayer.swift
//  X-Manage
//
//  DASH 视频播放器 - 使用 WebView + Shaka Player

import SwiftUI
import WebKit

// MARK: - DASH 视频播放器
struct DashVideoPlayer: NSViewRepresentable {
    let manifestUrl: String
    let encryption: EpisodeEncryption?
    var autoPlay: Bool = false

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = autoPlay ? [] : [.all]

        // 启用 JavaScript
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // 使用 https baseURL 以允许加载外部脚本
        let html = generatePlayerHTML()
        webView.loadHTMLString(html, baseURL: URL(string: "https://localhost"))

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // 如果 URL 变化，重新加载
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func generatePlayerHTML() -> String {
        let keyId = encryption?.keyId ?? ""
        let key = encryption?.key ?? ""
        let hasEncryption = encryption != nil

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    background: #1a1a1a;
                    overflow: hidden;
                }
                #video-container {
                    width: 100%;
                    height: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    flex-direction: column;
                }
                video {
                    width: 100%;
                    height: 100%;
                    object-fit: contain;
                }
                .error-message {
                    color: #ff6b6b;
                    text-align: center;
                    padding: 20px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 14px;
                }
                .loading {
                    color: #888;
                    text-align: center;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 14px;
                }
                .debug {
                    color: #666;
                    font-size: 12px;
                    margin-top: 10px;
                }
            </style>
        </head>
        <body>
            <div id="video-container">
                <div id="loading" class="loading">正在加载播放器...</div>
                <video id="video" controls style="display: none;"></video>
            </div>

            <script>
                const manifestUrl = "\(manifestUrl)";
                const hasEncryption = \(hasEncryption ? "true" : "false");
                const keyId = "\(keyId)";
                const key = "\(key)";
                const autoPlay = \(autoPlay ? "true" : "false");

                function updateLoading(msg) {
                    document.getElementById('loading').innerHTML = msg;
                }

                function showError(msg) {
                    document.getElementById('loading').innerHTML = '<div class="error-message">' + msg + '</div>';
                    document.getElementById('loading').style.display = 'block';
                    document.getElementById('video').style.display = 'none';
                }

                // 动态加载 Shaka Player
                function loadScript(src) {
                    return new Promise((resolve, reject) => {
                        const script = document.createElement('script');
                        script.src = src;
                        script.onload = resolve;
                        script.onerror = () => reject(new Error('Failed to load: ' + src));
                        document.head.appendChild(script);
                    });
                }

                async function initPlayer() {
                    const video = document.getElementById('video');

                    try {
                        updateLoading('正在加载 Shaka Player...');

                        // 加载 Shaka Player
                        await loadScript('https://cdn.jsdelivr.net/npm/shaka-player@4.16.1/dist/shaka-player.compiled.min.js');

                        updateLoading('正在初始化播放器...');

                        // 检查浏览器支持
                        if (typeof shaka === 'undefined') {
                            showError('Shaka Player 加载失败');
                            return;
                        }

                        shaka.polyfill.installAll();

                        if (!shaka.Player.isBrowserSupported()) {
                            showError('浏览器不支持 DASH 播放');
                            return;
                        }

                        const player = new shaka.Player();
                        await player.attach(video);

                        // 配置播放器
                        player.configure({
                            streaming: {
                                bufferingGoal: 30,
                                rebufferingGoal: 2,
                            }
                        });

                        // 配置 Clear Key 解密
                        if (hasEncryption && keyId && key) {
                            player.configure({
                                drm: {
                                    clearKeys: {
                                        [keyId]: key
                                    }
                                }
                            });
                        }

                        // 错误处理
                        player.addEventListener('error', (event) => {
                            console.error('Player error:', event.detail);
                            showError('播放错误: ' + (event.detail.message || '未知错误'));
                        });

                        updateLoading('正在加载视频...');

                        await player.load(manifestUrl);

                        document.getElementById('loading').style.display = 'none';
                        video.style.display = 'block';

                        if (autoPlay) {
                            video.play();
                        }
                    } catch (error) {
                        console.error('Init error:', error);
                        showError('加载失败: ' + error.message);
                    }
                }

                // 页面加载完成后初始化
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', initPlayer);
                } else {
                    initPlayer();
                }
            </script>
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading")
        }
    }
}

// MARK: - 简单预览播放器（用于预览视频，非 DASH）
struct PreviewVideoPlayer: NSViewRepresentable {
    let url: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; background: #000; }
                video { width: 100%; height: 100%; object-fit: contain; }
            </style>
        </head>
        <body>
            <video src="\(url)" controls></video>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}
}

#Preview("DashVideoPlayer") {
    DashVideoPlayer(
        manifestUrl: "https://example.com/video.mpd",
        encryption: nil
    )
    .frame(width: 640, height: 360)
}

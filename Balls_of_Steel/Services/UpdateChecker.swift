import Foundation
import AppKit

@MainActor
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    @Published var isUpdateAvailable = false
    @Published var latestVersion: String?
    @Published var releaseNotes: String?
    @Published var downloadURL: URL?
    
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let repoURL = "https://api.github.com/repos/ghostintheprompt/balls-of-steel/releases/latest"
    private let publicRepoURL = "https://github.com/ghostintheprompt/balls-of-steel/releases"
    
    func checkForUpdates(silent: Bool = true) async {
        guard let url = URL(string: repoURL) else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            let latest = release.tagName.replacingOccurrences(of: "v", with: "")
            
            if isVersion(latest, newerThan: currentVersion) {
                self.latestVersion = latest
                self.releaseNotes = release.body
                self.downloadURL = URL(string: release.htmlUrl)
                self.isUpdateAvailable = true
                
                if !silent {
                    showUpdateAlert()
                }
            } else if !silent {
                showUpToDateAlert()
            }
        } catch {
            print("Failed to check for updates: \(error)")
            if !silent {
                showErrorAlert()
            }
        }
    }
    
    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        return v1.compare(v2, options: .numeric) == .orderedDescending
    }
    
    private func showUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "A new version (\(latestVersion ?? "")) is available. Would you like to download it now?"
        alert.alertStyle = .informative
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = downloadURL {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "App is Up to Date"
        alert.informativeText = "You are running the latest version of Balls of Steel (\(currentVersion))."
        alert.alertStyle = .informative
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Check Failed"
        alert.informativeText = "Unable to check for updates. Please try again later or visit the GitHub repository."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Visit GitHub")
        
        if alert.runModal() == .alertSecondButtonReturn {
            if let url = URL(string: publicRepoURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case body
    }
}

import AuthenticationServices
import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum SchwabOAuthLaunchResult: Equatable {
    case systemSession
    case externalBrowser(String)
}

enum SchwabOAuthLaunchError: LocalizedError {
    case noCallback
    case cannotStart

    var errorDescription: String? {
        switch self {
        case .noCallback:
            return "Schwab sign-in closed before a callback was received."
        case .cannotStart:
            return "The system sign-in session could not start."
        }
    }
}

@MainActor
final class SchwabOAuthSessionCoordinator: NSObject, ObservableObject {
    static let shared = SchwabOAuthSessionCoordinator()

    @Published private(set) var isRunning = false

    private var session: ASWebAuthenticationSession?
    private var completion: ((Result<URL, Error>) -> Void)?

    @discardableResult
    func start(
        authURL: URL,
        callbackURL: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) -> SchwabOAuthLaunchResult {
        cancel()

        #if os(macOS) || os(iOS)
        if #available(iOS 17.4, macOS 14.4, *),
           let callback = Self.systemAuthenticationCallback(for: callbackURL) {
            let session = ASWebAuthenticationSession(url: authURL, callback: callback) { [weak self] callbackURL, error in
                Task { @MainActor in
                    self?.finish(callbackURL: callbackURL, error: error)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            guard session.canStart, session.start() else {
                Self.openExternally(authURL)
                return .externalBrowser(Self.externalLaunchMessage(for: callbackURL))
            }

            self.session = session
            self.completion = completion
            isRunning = true
            return .systemSession
        }
        #endif

        Self.openExternally(authURL)
        return .externalBrowser(Self.externalLaunchMessage(for: callbackURL))
    }

    func cancel() {
        session?.cancel()
        session = nil
        completion = nil
        isRunning = false
    }

    private func finish(callbackURL: URL?, error: Error?) {
        let completion = completion
        session = nil
        self.completion = nil
        isRunning = false

        if let callbackURL {
            completion?(.success(callbackURL))
        } else if let error {
            completion?(.failure(error))
        } else {
            completion?(.failure(SchwabOAuthLaunchError.noCallback))
        }
    }

    @available(iOS 17.4, macOS 14.4, *)
    private static func systemAuthenticationCallback(for callbackURL: String) -> ASWebAuthenticationSession.Callback? {
        guard let url = URL(string: AppConfig.Schwab.sanitizedCallbackURL(callbackURL)),
              let scheme = url.scheme?.lowercased() else {
            return nil
        }

        if scheme != "https" {
            return .customScheme(scheme)
        }

        guard let host = url.host?.lowercased(),
              !Self.isLoopbackHost(host) else {
            return nil
        }

        return .https(host: host, path: Self.normalizedPath(url.path))
    }

    private static func externalLaunchMessage(for callbackURL: String) -> String {
        guard let url = URL(string: AppConfig.Schwab.sanitizedCallbackURL(callbackURL)),
              let host = url.host?.lowercased() else {
            return "Opened Schwab in your browser. Paste the final callback URL or code into Steel."
        }

        if isLoopbackHost(host) {
            return "Opened Schwab in your browser. The portal callback is local HTTPS, so paste the final callback URL or code into Steel when Schwab redirects."
        }

        return "Opened Schwab in your browser. Steel will connect automatically if this domain is associated with the app; otherwise paste the final callback URL or code."
    }

    private static func isLoopbackHost(_ host: String) -> Bool {
        host == "127.0.0.1" || host == "localhost" || host == "::1"
    }

    private static func normalizedPath(_ path: String) -> String {
        path.isEmpty ? "/" : path
    }

    private static func openExternally(_ url: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
}

#if os(macOS) || os(iOS)
extension SchwabOAuthSessionCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow
            }
        }
        return scenes.first?.windows.first ?? ASPresentationAnchor()
        #endif
    }
}
#endif

import AuthenticationServices
import Foundation
#if os(macOS)
import AppKit
import Network
import Security
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
    case callbackError(String)

    var errorDescription: String? {
        switch self {
        case .noCallback:
            return "Schwab sign-in closed before a callback was received."
        case .cannotStart:
            return "The system sign-in session could not start."
        case .callbackError(let message):
            return message
        }
    }
}

@MainActor
final class SchwabOAuthSessionCoordinator: NSObject, ObservableObject {
    static let shared = SchwabOAuthSessionCoordinator()

    @Published private(set) var isRunning = false

    private var session: ASWebAuthenticationSession?
    private var completion: ((Result<URL, Error>) -> Void)?
    #if os(macOS)
    private let loopbackServer = SchwabLocalOAuthCallbackServer()
    #endif

    @discardableResult
    func start(
        authURL: URL,
        callbackURL: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) -> SchwabOAuthLaunchResult {
        cancel()

        #if os(macOS)
        if Self.isLoopbackCallback(callbackURL) {
            do {
                try loopbackServer.start(callbackURL: callbackURL) { [weak self] result in
                    Task { @MainActor in
                        self?.finish(result)
                    }
                }
                self.completion = completion
                isRunning = true
                Self.openExternally(authURL)
                return .externalBrowser(Self.localLoopbackLaunchMessage(for: callbackURL))
            } catch {
                Self.openExternally(authURL)
                return .externalBrowser(Self.loopbackFailureMessage(error, callbackURL: callbackURL))
            }
        }
        #endif

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
        #if os(macOS)
        loopbackServer.stop()
        #endif
        isRunning = false
    }

    private func finish(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            finish(callbackURL: url, error: nil)
        case .failure(let error):
            finish(callbackURL: nil, error: error)
        }
    }

    private func finish(callbackURL: URL?, error: Error?) {
        let completion = completion
        session = nil
        self.completion = nil
        #if os(macOS)
        loopbackServer.stop()
        #endif
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

    private static func localLoopbackLaunchMessage(for callbackURL: String) -> String {
        "Opened Schwab in your browser and armed the Mac callback listener at \(callbackURL). If Chrome shows a certificate warning after login, continue to 127.0.0.1 once."
    }

    private static func loopbackFailureMessage(_ error: Error, callbackURL: String) -> String {
        let detail = error.localizedDescription
        if URL(string: AppConfig.Schwab.sanitizedCallbackURL(callbackURL))?.port == nil {
            return "Opened Schwab in your browser, but Mac auto-callback cannot bind no-port HTTPS 443. Set the Schwab portal callback to https://127.0.0.1:8182 for local Mac OAuth, or paste the final callback URL."
        }
        return "Opened Schwab in your browser, but the Mac callback listener could not start: \(detail). Paste the final callback URL or code into Steel."
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

    private static func isLoopbackCallback(_ callbackURL: String) -> Bool {
        guard let url = URL(string: AppConfig.Schwab.sanitizedCallbackURL(callbackURL)),
              let host = url.host?.lowercased() else {
            return false
        }
        return url.scheme?.lowercased() == "https" && isLoopbackHost(host)
    }

    nonisolated fileprivate static func isLoopbackHost(_ host: String) -> Bool {
        host == "127.0.0.1" || host == "localhost" || host == "::1"
    }

    nonisolated fileprivate static func normalizedPath(_ path: String) -> String {
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

#if os(macOS)
private enum SchwabLocalOAuthServerError: LocalizedError {
    case invalidCallback
    case unsupportedNoPortCallback
    case invalidPort
    case identityUnavailable
    case invalidHTTPRequest

    var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "The Schwab callback URL is not a valid HTTPS loopback URL."
        case .unsupportedNoPortCallback:
            return "No-port HTTPS uses port 443, which a normal macOS app cannot bind."
        case .invalidPort:
            return "The Schwab callback URL has an invalid port."
        case .identityUnavailable:
            return "The local OAuth TLS identity could not be loaded."
        case .invalidHTTPRequest:
            return "The local OAuth callback request was not valid HTTP."
        }
    }
}

private final class SchwabLocalOAuthCallbackServer {
    private static let pkcs12Password = "steel-local-oauth"
    private static let pkcs12Base64 = """
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
"""

    private let queue = DispatchQueue(label: "app.mdrn.steel.schwab.oauth.loopback")
    private var listener: NWListener?
    private var didComplete = false

    func start(callbackURL: String, onCallback: @escaping (Result<URL, Error>) -> Void) throws {
        stop()
        didComplete = false

        guard let registeredURL = URL(string: AppConfig.Schwab.sanitizedCallbackURL(callbackURL)),
              registeredURL.scheme?.lowercased() == "https",
              let host = registeredURL.host?.lowercased(),
              SchwabOAuthSessionCoordinator.isLoopbackHost(host) else {
            throw SchwabLocalOAuthServerError.invalidCallback
        }

        let requestedPort = registeredURL.port ?? 443
        guard requestedPort > 0,
              requestedPort <= UInt16.max else {
            throw SchwabLocalOAuthServerError.invalidPort
        }
        guard requestedPort != 443 else {
            throw SchwabLocalOAuthServerError.unsupportedNoPortCallback
        }
        guard let port = NWEndpoint.Port(rawValue: UInt16(requestedPort)) else {
            throw SchwabLocalOAuthServerError.invalidPort
        }

        let parameters = try Self.tlsParameters()
        let ip = IPv4Address("127.0.0.1")!
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(ip), port: port)
        parameters.allowLocalEndpointReuse = true

        let listener = try NWListener(using: parameters, on: port)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection, registeredURL: registeredURL, onCallback: onCallback)
        }
        listener.stateUpdateHandler = { [weak self] state in
            guard case .failed(let error) = state else { return }
            self?.complete(.failure(error), onCallback: onCallback)
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    func stop() {
        listener?.cancel()
        listener = nil
        didComplete = true
    }

    private func handle(
        _ connection: NWConnection,
        registeredURL: URL,
        onCallback: @escaping (Result<URL, Error>) -> Void
    ) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, error in
            guard let self else { return }

            if let error {
                self.complete(.failure(error), onCallback: onCallback)
                connection.cancel()
                return
            }

            guard let data,
                  let requestText = String(data: data, encoding: .utf8),
                  let callbackURL = Self.callbackURL(fromHTTPRequest: requestText, registeredURL: registeredURL) else {
                self.sendResponse(.error, on: connection)
                self.complete(.failure(SchwabLocalOAuthServerError.invalidHTTPRequest), onCallback: onCallback)
                return
            }

            if let callbackError = Self.callbackError(from: callbackURL) {
                self.sendResponse(.error, on: connection)
                self.complete(.failure(SchwabOAuthLaunchError.callbackError(callbackError)), onCallback: onCallback)
                return
            }

            self.sendResponse(.success, on: connection)
            self.complete(.success(callbackURL), onCallback: onCallback)
        }
    }

    private func complete(_ result: Result<URL, Error>, onCallback: @escaping (Result<URL, Error>) -> Void) {
        guard !didComplete else { return }
        didComplete = true
        listener?.cancel()
        listener = nil
        onCallback(result)
    }

    private func sendResponse(_ response: LocalResponse, on connection: NWConnection) {
        let body = response.body
        let header = """
        HTTP/1.1 \(response.status)\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        """
        let payload = Data((header + body).utf8)
        connection.send(content: payload, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func callbackURL(fromHTTPRequest request: String, registeredURL: URL) -> URL? {
        guard let requestLine = request.components(separatedBy: "\r\n").first else {
            return nil
        }
        let parts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else {
            return nil
        }

        let target = parts[1]
        if let absoluteURL = URL(string: target),
           absoluteURL.scheme != nil {
            return absoluteURL
        }

        var components = URLComponents()
        components.scheme = registeredURL.scheme
        components.host = registeredURL.host
        components.port = registeredURL.port

        let split = target.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        components.percentEncodedPath = split.first.map(String.init).flatMap { $0.isEmpty ? "/" : $0 } ?? "/"
        if split.count > 1 {
            components.percentEncodedQuery = String(split[1])
        }
        return components.url
    }

    private static func callbackError(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let error = components.queryItems?.first(where: { $0.name == "error" })?.value,
              !error.isEmpty else {
            return nil
        }
        let description = components.queryItems?
            .first(where: { $0.name == "error_description" })?
            .value?
            .removingPercentEncoding
        if let description, !description.isEmpty {
            return "Schwab OAuth failed: \(error). \(description)"
        }
        return "Schwab OAuth failed: \(error)."
    }

    private static func tlsParameters() throws -> NWParameters {
        let cleanBase64 = pkcs12Base64.filter { !$0.isWhitespace }
        guard let data = Data(base64Encoded: cleanBase64) else {
            throw SchwabLocalOAuthServerError.identityUnavailable
        }

        var importedItems: CFArray?
        let options = [kSecImportExportPassphrase as String: pkcs12Password] as CFDictionary
        let status = SecPKCS12Import(data as CFData, options, &importedItems)
        guard status == errSecSuccess,
              let items = importedItems as? [[String: Any]],
              let identityItem = items.first?[kSecImportItemIdentity as String] else {
            throw SchwabLocalOAuthServerError.identityUnavailable
        }
        let identity = identityItem as! SecIdentity
        guard let secIdentity = sec_identity_create(identity) else {
            throw SchwabLocalOAuthServerError.identityUnavailable
        }

        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentity)
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = false
        return NWParameters(tls: tlsOptions, tcp: tcpOptions)
    }

    private enum LocalResponse {
        case success
        case error

        var status: String {
            switch self {
            case .success:
                return "200 OK"
            case .error:
                return "400 Bad Request"
            }
        }

        var body: String {
            switch self {
            case .success:
                return """
                <!doctype html><html><head><meta charset="utf-8"><title>Steel Schwab OAuth</title><style>body{margin:0;background:#050505;color:#f4f4f4;font:16px -apple-system,BlinkMacSystemFont,sans-serif;display:grid;place-items:center;min-height:100vh}main{max-width:560px;padding:32px}h1{color:#ffb000;letter-spacing:.08em;font-size:18px}p{line-height:1.45;color:#b8b8b8}</style></head><body><main><h1>SCHWAB CONNECTED</h1><p>You can close this browser tab and return to Steel Trading Desk.</p></main></body></html>
                """
            case .error:
                return """
                <!doctype html><html><head><meta charset="utf-8"><title>Steel Schwab OAuth</title><style>body{margin:0;background:#050505;color:#f4f4f4;font:16px -apple-system,BlinkMacSystemFont,sans-serif;display:grid;place-items:center;min-height:100vh}main{max-width:560px;padding:32px}h1{color:#ff4d57;letter-spacing:.08em;font-size:18px}p{line-height:1.45;color:#b8b8b8}</style></head><body><main><h1>OAUTH CALLBACK ERROR</h1><p>Return to Steel Trading Desk and use the callback field if needed.</p></main></body></html>
                """
            }
        }
    }
}
#endif

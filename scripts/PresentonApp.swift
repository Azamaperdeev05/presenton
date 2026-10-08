import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var loadingView: NSView!
    var progressIndicator: NSProgressIndicator!
    var statusLabel: NSTextField!
    var pollTimer: Timer?
    var startTime = Date()

    static func resolveAppDir() -> String {
        if let env = ProcessInfo.processInfo.environment["PRESENTON_DIR"], FileManager.default.fileExists(atPath: env) {
            return env
        }
        let cwd = FileManager.default.currentDirectoryPath
        if FileManager.default.fileExists(atPath: "\(cwd)/scripts/start-presenton.sh") {
            return cwd
        }
        let bundleParent = Bundle.main.bundleURL.deletingLastPathComponent().path
        if FileManager.default.fileExists(atPath: "\(bundleParent)/scripts/start-presenton.sh") {
            return bundleParent
        }
        let home = NSHomeDirectory()
        let standardCandidates = [
            "\(home)/Developer/Presenton",
            "\(home)/Developer.noindex/GitHub/Презентация",
            "/Applications/Presenton.app/Contents/Resources/app"
        ]
        for candidate in standardCandidates {
            if FileManager.default.fileExists(atPath: "\(candidate)/scripts/start-presenton.sh") {
                return candidate
            }
        }
        return cwd
    }

    var appDir: String {
        return AppDelegate.resolveAppDir()
    }
    let targetURL = URL(string: "http://127.0.0.1:3000")!
    let backendURL = URL(string: "http://127.0.0.1:8000/api/v1/auth/status")!
    var isChecking = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupSignals()
        setupMenu()
        setupWindow()
        startServersIfNeeded()
    }

    func setupSignals() {
        signal(SIGTERM) { _ in
            let dir = AppDelegate.resolveAppDir()
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["\(dir)/scripts/stop-presenton.sh"]
            task.currentDirectoryURL = URL(fileURLWithPath: dir)
            try? task.run()
            task.waitUntilExit()
            exit(0)
        }
        signal(SIGINT) { _ in
            let dir = AppDelegate.resolveAppDir()
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["\(dir)/scripts/stop-presenton.sh"]
            task.currentDirectoryURL = URL(fileURLWithPath: dir)
            try? task.run()
            task.waitUntilExit()
            exit(0)
        }
    }

    func setupMenu() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Presenton туралы", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Жасыру", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Басқаларын жасыру", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: "Барлығын көрсету", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Presenton-нан шығу", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "Файл")
        fileMenu.addItem(withTitle: "Терезені жабу", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit Menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Өңдеу")
        editMenu.addItem(withTitle: "Қайтару", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "Қайталау", action: Selector(("redo:")), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Қиып алу", action: Selector(("cut:")), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Көшіру", action: Selector(("copy:")), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Қою", action: Selector(("paste:")), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Барлығын таңдау", action: Selector(("selectAll:")), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "Көрініс")
        viewMenu.addItem(withTitle: "Қайта жүктеу", action: #selector(reloadWebView), keyEquivalent: "r")
        viewMenu.addItem(withTitle: "Браузерде ашу", action: #selector(openInDefaultBrowser), keyEquivalent: "b")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Толық экран", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Терезе")
        windowMenu.addItem(withTitle: "Кішірейту", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Үлкейту", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    func setupWindow() {
        let rect = NSRect(x: 0, y: 0, width: 1360, height: 860)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.minSize = NSSize(width: 1024, height: 680)
        window.title = "Presenton"
        window.delegate = self
        window.isReleasedWhenClosed = false

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.alphaValue = 0.0

        // Loading view
        loadingView = NSView(frame: window.contentView!.bounds)
        loadingView.autoresizingMask = [.width, .height]
        loadingView.wantsLayer = true
        loadingView.layer?.backgroundColor = NSColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0).cgColor

        progressIndicator = NSProgressIndicator(frame: NSRect(x: (1360-48)/2, y: 860/2 + 20, width: 48, height: 48))
        progressIndicator.style = .spinning
        progressIndicator.isIndeterminate = true
        progressIndicator.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        progressIndicator.startAnimation(nil)

        statusLabel = NSTextField(labelWithString: "Presenton іске қосылуда...\nBackend және Frontend дайындалуда")
        statusLabel.alignment = .center
        statusLabel.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = NSColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        statusLabel.frame = NSRect(x: 100, y: 860/2 - 50, width: 1160, height: 50)
        statusLabel.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]

        loadingView.addSubview(progressIndicator)
        loadingView.addSubview(statusLabel)

        window.contentView?.addSubview(webView)
        window.contentView?.addSubview(loadingView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func startServersIfNeeded() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["\(self.appDir)/scripts/start-presenton.sh", "--no-open"]
            task.currentDirectoryURL = URL(fileURLWithPath: self.appDir)
            try? task.run()
        }

        startTime = Date()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkServerReady()
        }
    }

    func checkServerReady() {
        if isChecking { return }
        isChecking = true

        let session = URLSession(configuration: .ephemeral)
        var nextReq = URLRequest(url: targetURL)
        nextReq.timeoutInterval = 0.8
        nextReq.httpMethod = "HEAD"

        session.dataTask(with: nextReq) { [weak self] _, response, _ in
            guard let self = self else { return }
            let nextReady = (response as? HTTPURLResponse).map { [200, 307, 308].contains($0.statusCode) } ?? false
            if !nextReady {
                self.isChecking = false
                self.checkTimeout()
                return
            }

            var fastReq = URLRequest(url: self.backendURL)
            fastReq.timeoutInterval = 0.8
            fastReq.httpMethod = "GET"
            session.dataTask(with: fastReq) { [weak self] _, fastResp, _ in
                guard let self = self else { return }
                self.isChecking = false
                let fastReady = (fastResp as? HTTPURLResponse)?.statusCode == 200
                if fastReady {
                    DispatchQueue.main.async {
                        self.pollTimer?.invalidate()
                        self.pollTimer = nil
                        self.loadApp()
                    }
                } else {
                    self.checkTimeout()
                }
            }.resume()
        }.resume()
    }

    func checkTimeout() {
        if Date().timeIntervalSince(startTime) > 40 {
            DispatchQueue.main.async {
                self.statusLabel.stringValue = "Жүктеу уақыты асып кетті.\nҚайта қосып көріңіз немесе жүйе журналдарын тексеріңіз."
            }
        }
    }

    func loadApp() {
        let request = URLRequest(url: targetURL)
        webView.load(request)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            self.webView.animator().alphaValue = 1.0
            self.loadingView.animator().alphaValue = 0.0
        }, completionHandler: {
            self.loadingView.isHidden = true
        })
    }

    @objc func reloadWebView() {
        webView.reload()
    }

    @objc func openInDefaultBrowser() {
        NSWorkspace.shared.open(targetURL)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        window.orderOut(nil)
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopServers()
    }

    func stopServers() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["\(appDir)/scripts/stop-presenton.sh"]
        task.currentDirectoryURL = URL(fileURLWithPath: appDir)
        try? task.run()
        task.waitUntilExit()
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            NSWorkspace.shared.open(url)
            return nil
        }
        let popup = WKWebView(frame: .zero, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        return popup
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "Жарайды")
        alert.runModal()
        completionHandler()
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "Иә")
        alert.addButton(withTitle: "Жоқ")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let path = url.path.lowercased()
        if path.contains("/api/export-presentation/file") || path.hasSuffix(".pdf") || path.hasSuffix(".pptx") {
            if #available(macOS 11.3, *) {
                decisionHandler(.download)
                return
            }
        }

        // Popup or new-window action (e.g. ChatGPT OAuth) -> open in system default browser!
        if navigationAction.targetFrame == nil {
            if url.absoluteString != "about:blank" {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }

        if url.host == "127.0.0.1" || url.host == "localhost" {
            decisionHandler(.allow)
            return
        }

        // External links (OAuth login, Google, GitHub, OpenAI, Pexels, Docs) -> open in default browser!
        if url.scheme == "http" || url.scheme == "https" {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    @available(macOS 11.3, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            let disposition = (httpResponse.allHeaderFields["Content-Disposition"] as? String)
                ?? (httpResponse.allHeaderFields["content-disposition"] as? String)
                ?? ""
            if disposition.lowercased().contains("attachment") {
                decisionHandler(.download)
                return
            }
        }

        let path = navigationResponse.response.url?.path.lowercased() ?? ""
        if path.contains("/api/export-presentation/file") || path.hasSuffix(".pdf") || path.hasSuffix(".pptx") {
            decisionHandler(.download)
            return
        }

        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }

    @available(macOS 11.3, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    @available(macOS 11.3, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    @available(macOS 11.3, *)
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        var destination = downloadsDir.appendingPathComponent(suggestedFilename)
        var counter = 1
        let baseName = (suggestedFilename as NSString).deletingPathExtension
        let ext = (suggestedFilename as NSString).pathExtension
        
        while FileManager.default.fileExists(atPath: destination.path) {
            let newName = "\(baseName) (\(counter)).\(ext)"
            destination = downloadsDir.appendingPathComponent(newName)
            counter += 1
        }
        
        completionHandler(destination)
    }

    @available(macOS 11.3, *)
    func downloadDidFinish(_ download: WKDownload) {
        NSSound(named: "Glass")?.play()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

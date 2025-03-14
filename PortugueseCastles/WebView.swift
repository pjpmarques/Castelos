import SwiftUI
import WebKit
import SafariServices

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var showFallbackSafari: Bool
    @Binding var errorOccurred: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        print("WebView - Creating WebView for URL: \(url.absoluteString)")
        
        // Create a configuration with more permissive settings
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.allowsInlineMediaPlayback = true
        
        // Set preferences
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences
        
        // Process pool to share cookies and other data
        configuration.processPool = WKProcessPool()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        
        // Clear cache and website data to avoid potential issues
        let dataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: date) { 
            print("WebView - Cache cleared")
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        print("WebView - Updating WebView with URL: \(url.absoluteString)")
        
        // Create a request with cache policy
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var loadRetryCount = 0
        let maxRetries = 2
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("WebView - Started loading: \(webView.url?.absoluteString ?? "unknown URL")")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView - Successfully loaded: \(webView.url?.absoluteString ?? "unknown URL")")
            // Reset error state when page loads successfully
            parent.errorOccurred = false
            loadRetryCount = 0
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView - Navigation failed: \(error.localizedDescription)")
            handleError(error, webView: webView)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView - Provisional navigation failed: \(error.localizedDescription)")
            print("WebView - Error code: \((error as NSError).code), domain: \((error as NSError).domain)")
            print("WebView - User info: \((error as NSError).userInfo)")
            
            handleError(error, webView: webView)
        }
        
        private func handleError(_ error: Error, webView: WKWebView) {
            let nsError = error as NSError
            print("WebView - Error details: code=\(nsError.code), domain=\(nsError.domain)")
            
            // Check if we should retry loading
            if loadRetryCount < maxRetries {
                loadRetryCount += 1
                print("WebView - Retrying load, attempt \(loadRetryCount)")
                
                // Retry with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Use the webView's current URL if available, otherwise fall back to the initial URL
                    let urlToLoad = webView.url ?? self.parent.url
                    print("WebView - Retrying with URL: \(urlToLoad.absoluteString)")
                    let request = URLRequest(url: urlToLoad, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                    webView.load(request)
                }
            } else {
                // If we've exhausted retries, show fallback
                print("WebView - All retries failed, showing fallback")
                parent.errorOccurred = true
                
                // Automatically switch to Safari after all retries fail
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.parent.showFallbackSafari = true
                }
            }
        }
    }
}

// Fallback Safari View Controller wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        print("SafariView - Opening URL: \(url.absoluteString)")
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: configuration)
        safariVC.preferredControlTintColor = UIColor.systemBlue
        safariVC.dismissButtonStyle = .done
        safariVC.delegate = context.coordinator
        
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariView
        
        init(_ parent: SafariView) {
            self.parent = parent
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 
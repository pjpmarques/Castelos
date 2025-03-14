//
// WebView.swift
//
// This file contains components for displaying web content within the app.
// It provides a WebKit-based view for showing Wikipedia pages about castles
// along with a fallback Safari view controller for when WebKit encounters errors.
// The implementation handles error recovery, retries, and graceful degradation.
//

import SwiftUI
import WebKit
import SafariServices

/// A SwiftUI wrapper around WKWebView for displaying web content inside the app
/// Handles loading web pages with error handling and fallback mechanisms
struct WebView: UIViewRepresentable {
    let url: URL                              // The URL to load in the web view
    @Binding var showFallbackSafari: Bool     // Controls when to show Safari as fallback
    @Binding var errorOccurred: Bool          // Indicates if an error occurred during loading
    
    /// Creates the underlying WKWebView with appropriate configuration
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
    
    /// Updates the web view when its state changes
    /// Forces a reload of the URL with cache-busting settings
    func updateUIView(_ webView: WKWebView, context: Context) {
        print("WebView - Updating WebView with URL: \(url.absoluteString)")
        
        // Create a request with cache policy
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        webView.load(request)
    }
    
    /// Creates a coordinator to handle the WKWebView's navigation events
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class that implements WKNavigationDelegate to handle web view events
    /// Manages error handling, loading states, and automatic retry logic
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var loadRetryCount = 0        // Tracks how many times we've tried to reload the page
        let maxRetries = 2            // Maximum number of reload attempts before falling back to Safari
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        /// Called when the web view starts loading a URL
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("WebView - Started loading: \(webView.url?.absoluteString ?? "unknown URL")")
        }
        
        /// Called when the web view successfully loads a page
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView - Successfully loaded: \(webView.url?.absoluteString ?? "unknown URL")")
            // Reset error state when page loads successfully
            parent.errorOccurred = false
            loadRetryCount = 0
        }
        
        /// Called when a navigation fails after it has been committed
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView - Navigation failed: \(error.localizedDescription)")
            handleError(error, webView: webView)
        }
        
        /// Called when a navigation fails before it is committed
        /// This is the most common failure case, e.g., when a network request fails
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView - Provisional navigation failed: \(error.localizedDescription)")
            print("WebView - Error code: \((error as NSError).code), domain: \((error as NSError).domain)")
            print("WebView - User info: \((error as NSError).userInfo)")
            
            handleError(error, webView: webView)
        }
        
        /// Centralized error handling function that implements retry logic
        /// After a certain number of failures, it will trigger the fallback to Safari
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

/// A SwiftUI wrapper around SFSafariViewController for displaying web content
/// Used as a fallback when the embedded WebView fails to load content
struct SafariView: UIViewControllerRepresentable {
    let url: URL                                    // The URL to load in Safari
    @Environment(\.presentationMode) var presentationMode
    
    /// Creates a Safari view controller with the specified URL
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
    
    /// Updates the Safari view controller when its state changes
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Nothing to update
    }
    
    /// Creates a coordinator to handle Safari view controller events
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class that implements SFSafariViewControllerDelegate
    /// Handles the dismissal of the Safari view controller
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariView
        
        init(_ parent: SafariView) {
            self.parent = parent
        }
        
        /// Called when the Safari view controller is dismissed
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 
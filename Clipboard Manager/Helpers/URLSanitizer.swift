//
//  URLSanitizer.swift
//  Clipboard Manager
//
//  Tracking parametrelerini temizleyen URL sanitizer (Sandbox uyumlu).
//

import Foundation

/// HTTP/HTTPS URL'lerindeki takip parametrelerini temizler
enum URLSanitizer {
    
    /// Bilinen tracking / analytics query parametreleri
    static let trackingParameters: Set<String> = [
        "utm_source",
        "utm_medium",
        "utm_campaign",
        "utm_term",
        "utm_content",
        "fbclid",
        "gclid",
        "igsh",
        "si",
        "ref",
        "_hsenc",
        "mc_cid"
    ]
    
    struct SanitizeResult: Sendable {
        let cleaned: String
        let didClean: Bool
    }
    
    /// Metin geçerli bir HTTP/HTTPS URL ise tracking parametrelerini siler.
    /// URL değilse `nil` döner.
    nonisolated static func sanitize(_ text: String) -> SanitizeResult? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }
        
        guard let items = components.queryItems, !items.isEmpty else {
            return SanitizeResult(cleaned: trimmed, didClean: false)
        }
        
        let filtered = items.filter { item in
            !trackingParameters.contains(item.name.lowercased())
        }
        
        let didClean = filtered.count != items.count
        guard didClean else {
            return SanitizeResult(cleaned: trimmed, didClean: false)
        }
        
        components.queryItems = filtered.isEmpty ? nil : filtered
        
        // trailing "?" kalıntısını önle
        if components.queryItems == nil {
            components.query = nil
        }
        
        guard let cleanedURL = components.url?.absoluteString else {
            return SanitizeResult(cleaned: trimmed, didClean: false)
        }
        
        return SanitizeResult(cleaned: cleanedURL, didClean: true)
    }
}

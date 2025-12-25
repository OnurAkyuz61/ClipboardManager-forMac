//
//  ClipboardItem.swift
//  ClipHistory
//
//  Created by Onur Akyüz on 25.12.2025.
//

import Foundation

/// Panodan kopyalanan bir metin öğesini temsil eden model
struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let text: String
    let date: Date
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.date = Date()
    }
    
    /// Aynı metin içeriğine sahip olup olmadığını kontrol eder
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.text == rhs.text
    }
}


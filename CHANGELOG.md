# Changelog

Bu dosya, [Clipboard Manager](https://github.com/OnurAkyuz61/ClipboardManager-forMac) projesindeki tüm önemli değişiklikleri belgeler.

Format [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) esas alınmıştır ve bu proje [Semantic Versioning](https://semver.org/lang/tr/) kullanır.

## [v2.0.0] - 2026-10-25

### Eklendi

- **Otomatik URL Temizleyici** (`URLSanitizer`): HTTP/HTTPS URL'lerindeki tracking parametrelerini (`utm_*`, `fbclid`, `gclid`, `igsh`, `si`, `ref`, `_hsenc`, `mc_cid`) otomatik siler; sonsuz döngü koruması ile panoya geri yazar; UI'da "✨ Temizlendi" rozeti
- **Hassas Veri & Gizlilik Kalkanı** (`PrivacyShield`): JWT, API key (`sk_live_`, `ghp_`, `AIza`, AWS `AKIA` vb.), `.env` ve Luhn doğrulamalı kredi kartı tespiti; geçmişte maskeleme; ayarlanabilir süre sonunda (varsayılan 60 sn) pano + geçmişten otomatik silme; "🛡️ Ns sonra silinecek" geri sayımı
- **Geliştirici Dönüştürücüsü** (`DevConverter`): Geçerli JSON için Swift Struct / TypeScript Interface / C# Class üretimi, Format / Minify; Base64 ve URL-encoded Decode; HEX renk (`#FF5733`) önizlemesi
- **Akıllı Kurallar** paneli: Otomatik URL temizleme, hassas veri silici (süre seçimi), geliştirici JSON araçları toggle'ları (`UserDefaults`)

### Teknik

- Smart pipeline mevcut `NSPasteboard` polling mekanizmasına entegre edildi (`ignoreNextPasteboardChange` ile loop koruması)
- Analiz ve kod üretimi `Task.detached` ile arka planda; UI `@MainActor`
- Mac App Store Sandbox uyumluluğu korundu (ek entitlement yok)

## [v1.0.0] - 2025-10-25

### Eklendi

- Otomatik clipboard izleme (Cmd+C ile kopyalanan metinleri yakalama)
- Son 10 kopyalanan metni saklama (FIFO)
- Aynı metnin tekrar eklenmesini önleme
- Menü çubuğundan hızlı erişim ve tek tıkla panoya kopyalama
- Geçmişi temizleme özelliği
- Dock'ta görünmeyen menü çubuğu uygulaması (`LSUIElement`)
- Otomatik dil algılama (Türkçe / İngilizce)
- Otomatik başlatma (Launch at Login)

### Teknik

- MVVM mimarisi (SwiftUI)
- NSPasteboard.changeCount ile saniyede 1 clipboard kontrolü
- Verilerin RAM'de tutulması (kalıcı depolama yok)
- macOS 13.0+ desteği

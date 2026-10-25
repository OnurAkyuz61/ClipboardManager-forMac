# Changelog

Bu dosya, [Clipboard Manager](https://github.com/OnurAkyuz61/ClipboardManager-forMac) projesindeki tüm önemli değişiklikleri belgeler.

Format [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) esas alınmıştır ve bu proje [Semantic Versioning](https://semver.org/lang/tr/) kullanır.

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

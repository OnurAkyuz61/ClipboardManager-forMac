# Changelog

Bu dosya, [Clipboard Manager](https://github.com/OnurAkyuz61/ClipboardManager-forMac) projesindeki tüm önemli değişiklikleri belgeler.

Format [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) esas alınmıştır ve bu proje [Semantic Versioning](https://semver.org/lang/tr/) kullanır.

## [v2.1.0] - 2026-10-25

### Eklendi

- **Pinleme:** Öğeleri sabitleme; pinliler FIFO sınırına takılmaz, Clear All yalnızca pinlenmemişleri siler
- **Güvenli JSON persistence:** Non-sensitive geçmiş `Application Support/ClipboardManager/clipboard_history.json` — sensitive asla diske yazılmaz
- **Arama + filtre hapları:** Tümü / Pinli / Link / Dev / Gizli
- **Password manager uyumu:** `org.nspasteboard.ConcealedType` / `TransientType` → `SensitiveKind.passwordManager`
- **JWT decoder:** Payload pretty JSON + "Copy Decoded Payload"
- **cURL → Swift URLRequest / JS fetch()**
- **Unix timestamp → yerel/UTC önizleme + ISO8601 kopyalama**
- **Case converter:** camelCase, snake_case, kebab-case, UPPER_CASE
- Hover aksiyonları (Pin / Copy / Delete) ve "✅ Kopyalandı!" geri bildirimi
- Ayarlardan maks. geçmiş: 15 / 30 / 50

### Değişti

- `MACOSX_DEPLOYMENT_TARGET` → **13.0** (Ventura+)
- `ClipboardItem` Equatable: tüm property'ler (SwiftUI state bug fix)
- `maxItems` varsayılanı 30
- Kullanılmayan boş Core Data modeli kaldırıldı

## [v2.0.0] - 2026-10-25

### Eklendi

- **Otomatik URL Temizleyici** (`URLSanitizer`)
- **Hassas Veri & Gizlilik Kalkanı** (`PrivacyShield`)
- **Geliştirici Dönüştürücüsü** (`DevConverter`)
- **Akıllı Kurallar** paneli

### Teknik

- Smart pipeline + `ignoreNextPasteboardChange`
- Mac App Store Sandbox uyumlu

## [v1.0.0] - 2025-10-25

### Eklendi

- Otomatik clipboard izleme, menü çubuğu geçmişi, Launch at Login, TR/EN

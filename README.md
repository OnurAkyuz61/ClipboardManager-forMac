<div align="center">
  <img src="https://raw.githubusercontent.com/OnurAkyuz61/ClipboardManager-forMac/main/Clipboard%20Manager/Assets.xcassets/AppIcon.appiconset/Icon-macOS-Default-256x256@1x.png" alt="Clipboard Manager Logo" width="128" height="128">
  <h1>Clipboard Manager</h1>
  <p>macOS Menü Çubuğunda çalışan hafif bir Clipboard Manager uygulaması</p>
  <p>
    <a href="https://github.com/OnurAkyuz61/ClipboardManager-forMac">
      <img src="https://img.shields.io/badge/GitHub-Repository-blue?style=flat-square&logo=github" alt="GitHub Repository">
    </a>
    <img src="https://img.shields.io/badge/macOS-13.0+-blue?style=flat-square&logo=apple" alt="macOS">
    <img src="https://img.shields.io/badge/Swift-5.0+-orange?style=flat-square&logo=swift" alt="Swift">
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
  </p>
</div>

## Özellikler

- ✅ Otomatik clipboard izleme (Cmd+C ile kopyalanan metinleri yakalar)
- ✅ Son 10 kopyalanan metni saklama
- ✅ Aynı metnin tekrar eklenmesini önleme
- ✅ Menü çubuğundan hızlı erişim
- ✅ Tek tıkla panoya kopyalama
- ✅ Geçmişi temizleme özelliği
- ✅ Dock'ta görünmez (sadece menü çubuğunda)
- ✅ Otomatik dil algılama (Türkçe/İngilizce)

## Gereksinimler

- macOS 13.0 (Ventura) veya üzeri
- Xcode 14.0 veya üzeri
- Swift 5.0+

## Kurulum

### GitHub'dan Klonlama

```bash
git clone https://github.com/OnurAkyuz61/ClipboardManager-forMac.git
cd ClipboardManager-forMac
```

### Xcode'da Açma

1. Projeyi klonlayın veya indirin
2. Xcode'da `Clipboard Manager.xcodeproj` dosyasını açın
3. **ÖNEMLİ:** Info.plist ayarını kontrol edin:
   - Xcode'da proje ayarlarına gidin
   - "Info" sekmesine tıklayın
   - "Custom macOS Application Target Properties" bölümünde
   - `LSUIElement` anahtarını ekleyin ve değerini `YES` yapın
   - VEYA `Config/Info.plist` dosyasındaki ayarın projeye eklendiğinden emin olun
4. Projeyi derleyin ve çalıştırın (⌘R)

## Kullanım

1. Uygulamayı başlattığınızda menü çubuğunda bir clipboard ikonu görünecektir
2. Herhangi bir metni kopyaladığınızda (Cmd+C), uygulama bunu otomatik olarak algılar
3. Menü çubuğundaki ikona tıklayarak son kopyalanan metinleri görebilirsiniz
4. Bir metne tıklayarak tekrar panoya kopyalayabilirsiniz
5. "Geçmişi Temizle" / "Clear History" butonu ile tüm geçmişi silebilirsiniz
6. "Çıkış" / "Quit" butonu ile uygulamadan çıkabilirsiniz

**Not:** Uygulama sistem dilinize göre otomatik olarak Türkçe veya İngilizce arayüz gösterir.

## Proje Yapısı

```
Clipboard Manager/
├── Clipboard_ManagerApp.swift       # Ana uygulama entry point
├── Models/
│   └── ClipboardItem.swift          # Veri modeli
├── ViewModels/
│   └── ClipboardViewModel.swift     # İş mantığı (MVVM)
├── Views/
│   └── MenuBarList.swift            # Ana UI görünümü
├── Helpers/
│   ├── PasteboardHelper.swift       # NSPasteboard yardımcı sınıfı
│   └── LocalizationHelper.swift     # Çoklu dil desteği
└── Config/
    └── Info.plist                   # LSUIElement ayarı
```

## Teknik Detaylar

- **Mimari:** MVVM (Model-View-ViewModel)
- **UI Framework:** SwiftUI
- **Clipboard İzleme:** Timer ile saniyede 1 kontrol (NSPasteboard.changeCount)
- **Veri Depolama:** RAM'de (kalıcı depolama yok)
- **Maksimum Öğe:** 10 (FIFO mantığı)
- **Dil Desteği:** Otomatik dil algılama (Türkçe/İngilizce)

## Lisans

MIT License - Detaylar için `LICENSE` dosyasına bakın.

## Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen [GitHub Repository](https://github.com/OnurAkyuz61/ClipboardManager-forMac)'ye pull request gönderin.

## Geliştirici

**Onur Akyüz** - 2025

- GitHub: [@OnurAkyuz61](https://github.com/OnurAkyuz61)
- Repository: [ClipboardManager-forMac](https://github.com/OnurAkyuz61/ClipboardManager-forMac)


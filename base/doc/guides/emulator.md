# Android Emulator Troubleshooting

## Sorun: Emulator exit code 1 / device offline
Bilgisayar yeniden başlatılsa bile emulator bağlanmıyor, "offline" görünüyor.

## Çözüm Adımları:
1. ADB sunucusunu yeniden başlat:
   ```bash
   ~/Library/Android/sdk/platform-tools/adb kill-server
   ~/Library/Android/sdk/platform-tools/adb start-server
   ```

2. Tüm AVD cache ve snapshot'larını temizle:
   ```bash
   for avd in ~/.android/avd/*.avd; do rm -rf "$avd/cache.img" "$avd/snapshots"; done
   ```

3. Eski emulator process'lerini öldür:
   ```bash
   pkill -f "qemu-system"
   ```

4. Emülatörü wipe-data ve host GPU ile temiz başlat:
   ```bash
   ~/Library/Android/sdk/emulator/emulator -avd <AVD_NAME> -no-snapshot-load -gpu host -wipe-data &
   ```

5. Boot tamamlandıktan sonra hala offline görünüyorsa ADB restart:
   ```bash
   ~/Library/Android/sdk/platform-tools/adb kill-server
   sleep 2
   ~/Library/Android/sdk/platform-tools/adb start-server
   ```

## Not:
- `adb` ve `emulator` komutları PATH'te olmayabilir, tam yol kullan: `~/Library/Android/sdk/...`
- `-gpu swiftshader_indirect` offline sorunu çözmediyse `-gpu host` dene
- `-wipe-data` emulator verisini sıfırlar ama sorunu kesin çözer
- Boot sonrası "offline" görünüyorsa ADB restart kesin çözüm
- Mevcut AVD'ler: Medium_Phone_API_36.1, Pixel_9, Pixel_9_Pro_Fold, Pixel_Fold, Small_Phone

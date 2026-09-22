#!/bin/bash

# Flutter Starter Template - Paket Yeniden Adlandırma Script'i
# Kullanım: ./rename_package.sh yeni_paket_adi
#
# Bu script:
# 1. pubspec.yaml'daki name alanını günceller
# 2. Tüm .dart dosyalarındaki package import'larını günceller
# 3. Generated dosyaları yeniden oluşturmanız için hatırlatma yapar

set -e

OLD_NAME="akillisletme"
NEW_NAME="$1"

if [ -z "$NEW_NAME" ]; then
  echo "Kullanım: ./rename_package.sh yeni_paket_adi"
  echo "Örnek:    ./rename_package.sh my_awesome_app"
  exit 1
fi

if [ "$OLD_NAME" = "$NEW_NAME" ]; then
  echo "Yeni isim mevcut isimle aynı: $OLD_NAME"
  exit 1
fi

# Geçerli Dart paket adı kontrolü (küçük harf, rakam, alt çizgi)
if ! echo "$NEW_NAME" | grep -qE '^[a-z][a-z0-9_]*$'; then
  echo "Hata: Paket adı sadece küçük harf, rakam ve alt çizgi içerebilir."
  echo "      Küçük harfle başlamalıdır. Örnek: my_app_name"
  exit 1
fi

echo "Paket adı değiştiriliyor: $OLD_NAME -> $NEW_NAME"
echo ""

# 1. pubspec.yaml güncelle
echo "[1/3] pubspec.yaml güncelleniyor..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^name: $OLD_NAME/name: $NEW_NAME/" pubspec.yaml
else
  sed -i "s/^name: $OLD_NAME/name: $NEW_NAME/" pubspec.yaml
fi

# 2. Tüm .dart dosyalarındaki import'ları güncelle
echo "[2/3] Dart import'ları güncelleniyor..."
DART_FILES=$(find lib test -name "*.dart" 2>/dev/null || true)
COUNT=0

for file in $DART_FILES; do
  if grep -q "package:$OLD_NAME/" "$file"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|package:$OLD_NAME/|package:$NEW_NAME/|g" "$file"
    else
      sed -i "s|package:$OLD_NAME/|package:$NEW_NAME/|g" "$file"
    fi
    COUNT=$((COUNT + 1))
  fi
done

echo "   $COUNT dosya güncellendi."

# 3. Script'in kendisindeki OLD_NAME'i güncelle (bir sonraki kullanım için)
echo "[3/3] Script güncelleniyor..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^OLD_NAME=\"$OLD_NAME\"/OLD_NAME=\"$NEW_NAME\"/" "$0"
else
  sed -i "s/^OLD_NAME=\"$OLD_NAME\"/OLD_NAME=\"$NEW_NAME\"/" "$0"
fi

echo ""
echo "Tamamlandı! Şimdi şu komutları çalıştır:"
echo ""
echo "  flutter pub get"
echo "  dart run build_runner build --delete-conflicting-outputs"
echo ""

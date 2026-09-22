#!/usr/bin/env bash
# Uretilen dosyalari ve bagimlilik onbellegini sifirdan kurar.
# Codegen cakismasi, "Target URI doesn't exist" veya iOS pod sorunlarinda kullan.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter clean
find lib -name '*.g.dart' -delete
find lib -name '*.freezed.dart' -delete
rm -f pubspec.lock

if [ -d ios ]; then
  rm -rf ios/Pods ios/Podfile.lock
fi

flutter pub get

if [ -d ios ] && command -v pod >/dev/null 2>&1; then
  (cd ios && pod install)
fi

./script/codegen.sh
./script/lang.sh

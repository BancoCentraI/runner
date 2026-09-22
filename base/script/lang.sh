#!/usr/bin/env bash
# assets/translations/*.json -> lib/product/init/language/locale_keys.g.dart
#
# DIKKAT: `-s en.json` zorunludur. Verilmezse easy_localization kaynak dosyayi
# alfabetik ilk dosyadan (tr.json) secer ve yalnizca bir dilde bulunan anahtarlar
# uretilen sinifin disinda kalir — hata vermeden anahtar duser.
set -euo pipefail
cd "$(dirname "$0")/.."

dart run easy_localization:generate \
  -S assets/translations \
  -O lib/product/init/language \
  -o locale_keys.g.dart \
  -f keys \
  -s en.json

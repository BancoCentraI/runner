#!/usr/bin/env bash
# Tum uretim adimlari tek komutta: bagimliliklar -> codegen -> ceviri anahtarlari.
# Klonladiktan sonra ve her ceviri/model degisiminde bunu calistirmak yeterlidir.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter pub get
./script/codegen.sh
./script/lang.sh

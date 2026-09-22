#!/usr/bin/env bash
# Bitirme kontrolu — doc/clean_code.md "Bitirme kontrolu" bolumunun calistirilabilir hali.
# Her gorev bununla kapanir; CI de ayni adimlari calistirir.
set -euo pipefail
cd "$(dirname "$0")/.."

echo '── dart format ─────────────────────────────'
dart format .

echo '── flutter analyze ─────────────────────────'
flutter analyze

echo '── flutter test ────────────────────────────'
flutter test

echo '✓ Bitirme kontrolu gecti'

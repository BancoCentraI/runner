#!/usr/bin/env bash
# Freezed, GoRouter, Hive adapter, FlutterGen ve JsonSerializable dosyalarini uretir.
# Kapsam build.yaml ile daraltilmistir.
set -euo pipefail
cd "$(dirname "$0")/.."

dart run build_runner build --delete-conflicting-outputs

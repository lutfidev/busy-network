#!/usr/bin/env bash
# Pasang Flutter SDK (channel stable) kalau perintah `flutter` belum ada.
# Pemakaian: source scripts/setup_flutter.sh   (biar PATH ikut ke shell aktif)
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter --version
flutter pub get

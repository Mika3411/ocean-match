#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.4}"
FLUTTER_HOME="${RENDER_FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  curl -fsSL "$FLUTTER_URL" -o "/tmp/${FLUTTER_ARCHIVE}"
  tar -xJf "/tmp/${FLUTTER_ARCHIVE}" -C "$(dirname "$FLUTTER_HOME")"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

dart_defines=()
if [ -n "${OCEAN_MATCH_API_URL:-}" ]; then
  dart_defines+=(--dart-define="OCEAN_MATCH_API_URL=${OCEAN_MATCH_API_URL}")
elif [ -n "${OCEAN_MATCH_API_ORIGIN:-}" ]; then
  dart_defines+=(--dart-define="OCEAN_MATCH_API_URL=${OCEAN_MATCH_API_ORIGIN%/}/v1")
fi

flutter build web --release "${dart_defines[@]}"

#!/usr/bin/env bash
# `flutter analyze` falha com caminhos não-ASCII (ex.: "Área de trabalho").
# Este script analisa uma cópia em /tmp/tqvp_analyze (caminho ASCII).
set -e
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DST=/tmp/tqvp_analyze_$$
mkdir -p "$DST"
rsync -a --exclude build --exclude .dart_tool --exclude android --exclude ios --exclude .git "$SRC"/ "$DST"/
cd "$DST" && flutter pub get >/dev/null && flutter analyze
rc=$?; rm -rf "$DST"; exit $rc

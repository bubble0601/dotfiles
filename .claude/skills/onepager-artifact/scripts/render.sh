#!/usr/bin/env bash
# 図の HTML(1600x900 固定)を headless Chrome で 2x の PNG に描画し、JPEG(q88)にも変換する
# usage: [PYTHON=.venv/bin/python] render.sh <out_dir> <html>... ; 出力は <out_dir>/<basename>.png / .jpg
# Pillow が無いときは PNG だけ残す(JPEG 化は build 前に別途行う)
set -euo pipefail
OUT="$1"; shift
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PY="${PYTHON:-python3}"
mkdir -p "$OUT"
for f in "$@"; do
  b=$(basename "${f%.html}")
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --window-size=1600,900 \
    --screenshot="$OUT/$b.png" "file://$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" >/dev/null 2>&1
  if "$PY" - "$OUT/$b.png" "$OUT/$b.jpg" <<'PY'
import sys
try:
    from PIL import Image
except ImportError:
    sys.exit(1)
Image.open(sys.argv[1]).convert('RGB').save(sys.argv[2], quality=88, optimize=True, subsampling=0)
PY
  then echo "rendered $b (png + jpg)"; else echo "rendered $b (png のみ。JPEG 化は PYTHON=<Pillow 入り python> を指定)"; fi
done

#!/usr/bin/env bash
# OpenMontage setup for DesiJorrKhana content production.
#
# Reproduces the working environment used to render content/every-jorr-counts.
# Tested on Ubuntu 24.04 (Claude Code remote sandbox). Requires: git, python3.10+,
# node 18+ (22 recommended), curl. Run as a user that can apt-get install.
set -euo pipefail

OM_DIR="${OM_DIR:-$HOME/OpenMontage}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> 1. System packages (ffmpeg for rendering, woff2 for font conversion, Noto for Devanagari fallback)"
sudo apt-get update -qq || apt-get update -qq
sudo apt-get install -y ffmpeg woff2 fonts-noto-core || apt-get install -y ffmpeg woff2 fonts-noto-core

echo "==> 2. Clone + set up OpenMontage"
[ -d "$OM_DIR" ] || git clone --depth 1 https://github.com/calesthio/OpenMontage.git "$OM_DIR"
make -C "$OM_DIR" setup

echo "==> 3. Piper TTS voice (free local narration)"
mkdir -p "$HOME/.piper/models"
"$OM_DIR/.venv/bin/python" -m piper.download_voices en_US-lessac-medium \
  --download-dir "$HOME/.piper/models" 2>/dev/null \
  || (cd "$HOME/.piper/models" && "$OM_DIR/.venv/bin/python" -m piper.download_voices en_US-lessac-medium)
# OpenMontage's piper tool calls a bare `piper` binary; give it one that knows the model dir.
sudo tee /usr/local/bin/piper >/dev/null <<EOF
#!/bin/sh
exec "$OM_DIR/.venv/bin/piper" --data-dir "$HOME/.piper/models" "\$@"
EOF
sudo chmod +x /usr/local/bin/piper

echo "==> 4. Offline fonts (sandboxes block fonts.gstatic.com at render time)"
FD="$OM_DIR/remotion-composer/public/fonts"; mkdir -p "$FD"
declare -A FONTS=(
  [space-grotesk-var.woff2]="https://fonts.gstatic.com/s/spacegrotesk/v22/V8mDoQDjQSkFtoMM3T6r8E7mPbF4Cw.woff2"
  [playfair-var.woff2]="https://fonts.gstatic.com/s/playfairdisplay/v40/nuFiD-vYSZviVYUb_rj3ij__anPXDTzYgA.woff2"
  [playfair-italic-var.woff2]="https://fonts.gstatic.com/s/playfairdisplay/v40/nuFkD-vYSZviVYUb_rj3ij__anPXDTnogkk7.woff2"
  [teko-latin.woff2]="https://fonts.gstatic.com/s/teko/v23/LYjNdG7kmE0gfaN9pQ.woff2"
  [teko-devanagari.woff2]="https://fonts.gstatic.com/s/teko/v23/LYjNdG7kmE0gfaJ9pRtB.woff2"
  [mukta-400-latin.woff2]="https://fonts.gstatic.com/s/mukta/v17/iJWKBXyXfDDVXbnBrXw.woff2"
  [mukta-400-devanagari.woff2]="https://fonts.gstatic.com/s/mukta/v17/iJWKBXyXfDDVXbnArXyi0A.woff2"
  [mukta-700-latin.woff2]="https://fonts.gstatic.com/s/mukta/v17/iJWHBXyXfDDVXbF6iGmd8WA.woff2"
  [mukta-700-devanagari.woff2]="https://fonts.gstatic.com/s/mukta/v17/iJWHBXyXfDDVXbF6iGmc8WDm7Q.woff2"
)
for f in "${!FONTS[@]}"; do [ -f "$FD/$f" ] || curl -sSo "$FD/$f" "${FONTS[$f]}"; done

# Install as system fonts so Chromium resolves them via fontconfig with zero
# network I/O (FontFace() from the bundle server proved flaky in multi-tab renders).
sudo mkdir -p /usr/share/fonts/truetype/brand
(cd "$FD" && for f in *.woff2; do woff2_decompress "$f"; done && sudo cp *.ttf /usr/share/fonts/truetype/brand/)
# Variable TTFs ship with "<Family> Light" name records; rename so CSS "Teko" etc. matches.
python3 -m pip install --quiet --break-system-packages fonttools brotli
python3 - <<'PYEOF'
from fontTools.ttLib import TTFont
fixes = {
    "/usr/share/fonts/truetype/brand/teko-latin.ttf": "Teko",
    "/usr/share/fonts/truetype/brand/teko-devanagari.ttf": "Teko",
    "/usr/share/fonts/truetype/brand/space-grotesk-var.ttf": "Space Grotesk",
}
for path, fam in fixes.items():
    f = TTFont(path)
    for nid in (1, 16):
        for rec in f["name"].names:
            if rec.nameID == nid:
                rec.string = fam.encode("utf-16-be") if b"\x00" in rec.toBytes() else fam.encode("latin-1")
    f.save(path)
PYEOF
sudo fc-cache -f >/dev/null

echo "==> 5. Apply repo patches (offline font loading + theme-aware HeroTitle/ComparisonCard)"
cp "$REPO_DIR/openmontage/patches/local-fonts.ts" "$OM_DIR/remotion-composer/src/local-fonts.ts"
git -C "$OM_DIR" apply --3way "$REPO_DIR/openmontage/patches/offline-fonts-and-theme.patch" || \
  git -C "$OM_DIR" apply "$REPO_DIR/openmontage/patches/offline-fonts-and-theme.patch"

echo "==> 6. Un-break Remotion behind an HTTPS proxy (it launches Chromium with --no-proxy-server)"
RD="$OM_DIR/remotion-composer/node_modules/@remotion/renderer/dist"
sed -i "s/'--no-proxy-server',//; s/\"--proxy-server='direct:\\/\\/'\",//; s/'--proxy-bypass-list=\\*',//" "$RD/open-browser.js"
sed -i 's/"--no-proxy-server",//; s/"--proxy-server='"'"'direct:\/\/'"'"'",//; s/"--proxy-bypass-list=\*",//' "$RD/esm/index.mjs"

echo "==> Done. Render the DesiJorrKhana promo with:"
echo "  cd $OM_DIR/remotion-composer && npx remotion render src/index.tsx Explainer out.mp4 \\"
echo "    --props $REPO_DIR/content/every-jorr-counts/remotion_props.json --codec h264 \\"
echo "    --browser-executable \$(command -v chromium || echo /opt/pw-browsers/chromium) --chrome-mode=chrome-for-testing"

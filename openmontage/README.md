# OpenMontage × DesiJorrKhana

This folder wires [OpenMontage](https://github.com/calesthio/OpenMontage) — an
open-source, agentic video production system (AGPL-3.0) — into this repo as the
content-production toolchain for the DesiJorrKhana brand.

OpenMontage itself is **not vendored** here (it's ~2,000 files and AGPL); it is
cloned and configured by `setup.sh`. What lives in this repo:

| Path | What it is |
|---|---|
| `openmontage/setup.sh` | One-shot environment setup: clones OpenMontage, installs FFmpeg/Piper TTS/fonts, applies the patches below |
| `openmontage/patches/local-fonts.ts` | Offline replacement for `@remotion/google-fonts` (sandboxes block `fonts.gstatic.com` at render time) |
| `openmontage/patches/offline-fonts-and-theme.patch` | Makes `HeroTitle`/`ComparisonCard` theme-aware and switches all compositions to the offline font loader |
| `content/every-jorr-counts/` | First produced video + all pipeline artifacts (script, scene plan, props, decision log) |

## What the toolchain can do right now (zero API keys)

- **Narration**: Piper TTS, local and free (`en_US-lessac-medium`)
- **Composition**: Remotion (React scenes), HyperFrames (HTML/GSAP), FFmpeg
- **Subtitles**: word-level animated captions
- **Brand look**: a `themeConfig` with the Jorr Counter palette (mitti `#15100B`,
  brass `#D4A02C`, sindoor `#C8401B`, bone `#EDE6D6`) and the app's Teko + Mukta
  fonts (incl. Devanagari)

Adding API keys to OpenMontage's `.env` unlocks AI video/image/music generation
and premium voices — run `make preflight` inside the OpenMontage clone to see
the full capability menu.

## Producing a new video

1. `bash openmontage/setup.sh`
2. Open the OpenMontage clone in Claude Code (or another agent) — its
   `AGENT_GUIDE.md` drives the pipeline: proposal → script → scene plan →
   assets (TTS) → edit → compose.
3. Reuse `content/every-jorr-counts/remotion_props.json` as the starting point
   for the brand look: swap the `cuts` text, regenerate narration WAVs with
   Piper, re-measure timings, render.

Render command (from `remotion-composer/`):

```bash
npx remotion render src/index.tsx Explainer out.mp4 \
  --props ../path/to/props.json --codec h264 \
  --browser-executable /opt/pw-browsers/chromium --chrome-mode=chrome-for-testing
```

## Environment gotchas we already solved (see setup.sh)

- **Piper voice discovery**: OpenMontage calls a bare `piper` binary; the shim in
  `/usr/local/bin/piper` points it at `~/.piper/models`.
- **`fonts.gstatic.com` blocked / MITM'd**: `@remotion/google-fonts` aborts the whole
  render with `NetworkError`. Fixed by vendoring woff2 files and installing them as
  *system* fonts (the in-page `FontFace()` route was flaky in multi-tab renders).
- **Remotion disables the proxy**: it launches Chromium with `--no-proxy-server`,
  which breaks sandboxes where all egress goes through an HTTPS proxy. `setup.sh`
  strips those flags from `@remotion/renderer`'s launch args.
- **Variable-font naming**: Google's variable TTFs register as "Teko Light" etc.;
  the name tables are rewritten so CSS `font-family: Teko` matches.

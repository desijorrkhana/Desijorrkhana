# Every Jorr Counts — brand promo (v1)

First video produced with the OpenMontage toolchain (see `/openmontage`).

- **`every-jorr-counts.mp4`** — 32s, 1920×1080 @ 30fps, H.264. Narrated promo
  for the Jorr Counter app: hook → problem → solution → features → proof → CTA.
- **`poster.png`** — hero frame, usable as a video poster / social card.
- Narration: Piper TTS (`en_US-lessac-medium`), free and local.
- Look: Jorr Counter palette (mitti/brass/sindoor/bone) + Teko/Mukta fonts,
  word-level animated captions.
- No background music in v1 (no music source was available in the build
  sandbox — see `decision_log.json`). Drop a royalty-free track into
  OpenMontage's `music_library/` and re-render to add one.

## Provenance (pipeline artifacts)

| File | Stage |
|---|---|
| `proposal_packet.json` | proposal — 3 concept options, selected concept, production plan, $0.00 cost estimate |
| `script.json` | script — 6 narration beats (~75 words) |
| `scene_plan.json` | scene plan — scene types + timings derived from measured narration durations |
| `asset_manifest.json` | assets — per-scene Piper WAVs |
| `edit_decisions.json` | edit — final cut list, `render_runtime: remotion` |
| `remotion_props.json` | compose — the exact props rendered (brand `themeConfig`, cuts, captions) |
| `timeline.json` | measured narration timings that drive everything |
| `decision_log.json` | why each production choice was made |

## Re-rendering / remixing

```bash
bash ../../openmontage/setup.sh   # one-time environment setup
cd ~/OpenMontage/remotion-composer
npx remotion render src/index.tsx Explainer out.mp4 \
  --props <this dir>/remotion_props.json --codec h264 \
  --browser-executable /opt/pw-browsers/chromium --chrome-mode=chrome-for-testing
```

Change the `cuts` text in `remotion_props.json` for new copy; regenerate the
narration WAVs with Piper and re-measure timings if the words change.

// Offline replacement for @remotion/google-fonts loaders.
//
// Sandboxed render environments (e.g. Claude Code remote sessions) MITM or
// block fonts.gstatic.com, which makes the google-fonts loaders abort the
// whole render with NetworkError. FontFace() loading from the bundle server
// also proved flaky under multi-tab renders (delayRender timeouts), so the
// fonts are installed as SYSTEM fonts instead: the woff2 files vendored in
// public/fonts/ are decompressed to TTF and dropped into
// /usr/share/fonts/truetype/brand (see scripts in the project README).
// Chromium then resolves the families via fontconfig with zero network I/O
// and zero delayRender handles.
//
// Signature-compatible with @remotion/google-fonts loadFont(style?, options?).

const result = (family: string) => ({
  fontFamily: family,
  fonts: {},
  unicodeRanges: {},
  waitUntilDone: () => Promise.resolve(undefined),
});

export const loadSpaceGrotesk = (..._args: unknown[]) =>
  result("Space Grotesk");

export const loadPlayfairDisplay = (..._args: unknown[]) =>
  result("Playfair Display");

export const loadBrandFonts = () => {
  // Teko + Mukta (incl. Devanagari) are system-installed; nothing to load.
};

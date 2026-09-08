# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.9.0](https://github.com/bernardopg/ioruba/compare/v1.8.4...v1.9.0) (2026-09-08)

### Added

- Firmware `0.6.2` publishes its effective knob, button and encoder pin map in
  the protocol-v2 handshake. Pin maps are board-specific, customizable at
  compile time and rejected by `static_assert` when any enabled input overlaps.
- The Hardware panel now presents a responsive, accessible wiring card with the
  active pins, encoder A/B pairs and a conflict-free connection summary.

### Fixed

- The desktop serial stream retains line terminators and buffers split lines in
  the vendored serial plugin. A firmware `HELLO` split across reads can no
  longer be merged into a corrupt frame.
- Boot noise and individual malformed serial frames are logged and discarded
  without marking a live serial connection as failed.
- The AUR `-bin` package is installable again: `package()` redirected the
  launcher into `${pkgdir}/usr/bin` without creating the directory, so
  `makepkg` died with "No such file or directory" on every build.

### Changed

- Migrated the test stack to vitest 5: `vitest` and `@vitest/coverage-v8` are
  now 5.0.0 in both workspaces, with a Vitest `Assertion` augmentation so the
  jest-axe `toHaveNoViolations()` matcher typechecks again under the new
  interface.
- Bumped dependencies: `tauri-plugin-dialog` to 2.7.3, `tauri-plugin-updater`
  to 2.11.0, `tauri-plugin-single-instance` to 2.4.4, `tauri-plugin-opener` to
  2.5.5, `tauri-plugin-serialplugin-api` to 3.0.5, `lucide-react` to 1.43.0,
  `@types/node` to 26.5.0, `@types/react-dom` to 19.2.7 and GitHub Actions to
  their latest versions, plus 139 transitive Rust lockfile bumps.

## [1.8.4](https://github.com/bernardopg/ioruba/compare/v1.8.2...v1.8.4) (2026-08-25)

> **Nota sobre a v1.8.3:** a tag `v1.8.3` foi criada apenas para reexecutar o
> workflow de release da v1.8.2 após uma falha de CI no Windows, sem commit de
> bump de versão. Os artefatos publicados nela são, na verdade, binários 1.8.2,
> e o `latest.json` correspondente anunciava 1.8.3 apontando para eles — o que
> deixava o updater in-app num loop infinito. A v1.8.3 foi despromovida de
> `releases/latest`; use a v1.8.4.

### Fixed

- O manifesto do updater (`latest.json`) agora valida que cada artefato
  referenciado carrega a versão anunciada no nome. Um release cuja tag não bate
  com os bundles falha o pipeline em vez de publicar um manifesto que empurra
  usuários para um binário mais antigo.
- O updater in-app não é mais oferecido em instalações gerenciadas por
  gerenciador de pacotes (pacman/AUR, apt, dnf). Antes, clicar em "Atualizar e
  reiniciar" falhava com `Permission denied (os error 13)` ao tentar sobrescrever
  um executável em `/usr`, sem explicação visível na interface.
- O toast de atualização passa a exibir o motivo real da falha e um botão para
  abrir a página do release, em vez de uma mensagem genérica.
- O cask do Homebrew voltou a ser instalável. A URL era remontada a partir da
  versão anunciada (`Ioruba_#{version}_#{arch}.app.tar.gz`), o que na v1.8.3
  apontou para um arquivo inexistente e fez `brew install --cask ioruba` retornar
  404 em toda máquina. Agora ela deriva do nome que foi realmente publicado, e
  só a arquitetura é interpolada.
- O bloco `autoupdate` do Scoop passa a ser derivado da URL publicada em vez de
  escrito à mão, eliminando a mesma suposição que quebrou o cask.

### Added

- O workflow de release ganhou um gate de consistência de versão que compara a
  tag com `package.json`, `apps/desktop/package.json`, `tauri.conf.json`,
  `Cargo.toml` e a existência da seção correspondente no `CHANGELOG.md` antes de
  iniciar qualquer build.
- Novo passo `Verify every manifest URL resolves`: antes de publicar no tap do
  Homebrew, no bucket do Scoop ou no release, toda URL de download dos
  manifestos gerados precisa responder HTTP 200. Rodado contra a v1.8.3, ele
  reprova com os dois 404 que passaram despercebidos.

### Removed

- Assinatura de código de plataforma (Apple Developer ID e Windows Authenticode)
  foi removida do pipeline por decisão de projeto: os certificados não existem e
  não serão adquiridos. Saíram os secrets `APPLE_*`/`WINDOWS_CERTIFICATE*`, a
  ramificação condicional por presença de certificado, o passo duplicado de build
  para macOS e a limpeza de keychain — restou um único passo de build.

  Isso corrige um estado em que o workflow *aparentava* assinar sem assinar: o
  hotfix `def4782` removeu os passos que definiam `WINDOWS_CERTIFICATE_THUMBPRINT`
  e `APPLE_SIGNING_IDENTITY`, mas manteve os consumidores dessas variáveis e o
  condicional `HAS_APPLE_CERT`.

  A assinatura do **updater** (minisign, chave própria do projeto) permanece
  obrigatória e inalterada; a integridade dos downloads segue verificável por
  `SHA256SUMS.txt` e por attestations do GitHub.

### Changed

- O warning `libayatana-appindicator is deprecated` deixa de poluir o stdout em
  builds de release no Linux. A causa é upstream (`tauri-apps/tray-icon#260`,
  marcado `wontfix`) e não tem correção disponível; o app agora silencia
  especificamente esse domínio de log, preservando todos os demais avisos GLib.

## [1.8.2](https://github.com/bernardopg/ioruba/compare/v1.8.1...v1.8.2) (2026-08-13)

### Security

- Updated transitive `event-listener` from 5.4.1 to 5.4.2, fixing RUSTSEC-2026-0221 (`StackSlot` could move non-`Send` tags across threads). CI now runs both npm and RustSec dependency audits.
- Linux/macOS and Windows one-line installers now fail closed when `SHA256SUMS.txt`, the exact checksum entry, or an unambiguous architecture-specific asset is unavailable.
- The Arduino CLI bootstrap verifies a pinned SHA-256 and retries transient downloads; release checksum/provenance generation now requires every expected desktop and firmware asset, including `.bin`, `.elf`, and `.eep` files.
- Public Windows release builds now require the Authenticode certificate instead of silently publishing unsigned installers.

### Changed

- The Windows release pipeline no longer hard-fails when `WINDOWS_CERTIFICATE` is absent; unsigned Windows bundles are published until the Authenticode certificate is configured.

### Changed

- Bumped frontend dependencies: `@vitejs/plugin-react` to 6.1.0, `vite` to 8.2.2, `vitest` to 4.1.11, `@vitest/coverage-v8` to 4.1.11, and `lucide-react` to 1.33.0.

## [1.8.1](https://github.com/bernardopg/ioruba/compare/v1.8.0...v1.8.1) (2026-08-12)

### Fixed

- The generated AUR `PKGBUILD` for `ioruba-desktop` now sets `options=('!lto' '!debug')`. Arch's stock `makepkg.conf` enables LTO and injects `-flto=auto` into `CFLAGS`, so the `cc` crate compiled the `ring` crate's C and assembly sources into GIMPLE bitcode instead of native ELF objects; the final link, driven by `rust-lld`, then failed with `undefined symbol: ring_core_0_17_14__*` and no one could install v1.8.0 from source. The linker was a red herring — only removing `-flto` fixes it. The `PKGBUILD` also regained the `provides`/`conflicts`/`replaces` entries that v1.8.0 dropped, so it no longer silently coexists with `ioruba-desktop-bin`.

## [1.8.0](https://github.com/bernardopg/ioruba/compare/v1.7.1...v1.8.0) (2026-08-10)

### Added

- The app now offers signed in-app updates. Tauri verifies the detached signature against a public key embedded in the app before it downloads, installs, and restarts; releases fail closed if their signing key or a platform signature is absent. A single post-matrix job builds `latest.json`, avoiding concurrent release jobs overwriting it with incomplete platform data.
- Release workflows now generate verified Homebrew cask, Scoop, and winget manifests from the published release assets and their `SHA256SUMS.txt`. Homebrew and Scoop manifests are also committed automatically to the project tap/bucket through separate deploy keys; winget manifests remain attached for Microsoft’s external review. Their checksums are never copied by hand.

### Changed

- The telemetry chart no longer depends on `recharts`. It is drawn by a small SVG component with the same monotone-cubic curve, grid, axes and tooltip. The boot payload drops from 878.45 kB to 535.15 kB raw (252.14 kB to 154.49 kB gzip, -39%): the lazy boundary that was supposed to keep `recharts` out of startup never worked, because `manualChunks` placed React's own entry in the same chunk and Vite preloaded it from `index.html`.
- The Windows audio backend now runs on a dedicated thread that owns the COM apartment and caches the default-output handle, instead of rebuilding the whole COM stack on every volume write. The macOS backend caches the resolved device together with the elements that accept a volume write, instead of re-probing them per write. Both use the 250 ms window Linux already had.

### Fixed

- The cross-platform one-line installer no longer falls back from an unavailable arm64 package to an arbitrary package of another architecture. It now names the requested artifact and lists the release assets, and its architecture selection is exercised by fixture tests in CI.
- Retained notifications are capped at 100. The list deduplicated by id but never trimmed, so nothing except the six-hour release-check cadence kept it bounded in a session left running for days.
- The `Publish to AUR` release job now retries every AUR network call with backoff instead of failing the whole job on the first error. The AUR takes itself down for maintenance without notice, which is what left `ioruba-desktop`/`ioruba-desktop-bin` un-updated on the v1.7.1 release.

## [1.7.1](https://github.com/bernardopg/ioruba/compare/v1.7.0...v1.7.1) (2026-08-10)

### Changed

- Bumped `lucide-react` to 1.31.0, `vite` to 8.2.1 and `@types/node` to 26.2.0.
- Bumped the GitHub Actions group: `Swatinem/rust-cache` to 2.9.2, `github/codeql-action/{init,analyze}` to 4.37.6 and `actions/attest-build-provenance` to 4.2.2.

### Fixed

- The `[Unreleased]` comparison link at the bottom of this file pointed at `v1.5.2`, three releases behind the actual baseline.

## [1.7.0](https://github.com/bernardopg/ioruba/compare/v1.6.3...v1.7.0) (2026-08-03)

### Added

- Control bindings (buttons, encoders) now accept an optional `target` (`AudioTarget`) that directs a `mute` action at a specific sink, source, or application instead of the default output. Absent target preserves the previous behavior (toggle default output). Linux uses the same name-matching rules as knob volume targets (aliases `default_output`/`default_microphone`, case-insensitive substring); Windows accepts `master` or no target and rejects specific targets with `supported: false`.

- Visual editor for control bindings in **Settings › Profile editor › Buttons and encoders**: add or remove buttons and encoders, switch between the two input kinds, and pick the mute target from the session audio inventory without touching the advanced JSON.

### Changed

- `target` is now only accepted with `action: "mute"`. `next`/`prev` drive the MPRIS media player, so a target there could never take effect: the profile editor reports it as a validation error and persisted-state validation drops the binding.
- The in-app changelog dialog no longer lists the `Unreleased` section: it describes work that is not in the running binary.

## [1.6.3](https://github.com/bernardopg/ioruba/compare/v1.6.2...v1.6.3) (2026-07-29)

### Changed

- Bumped `react` and `react-dom` to 19.2.8.
- Bumped frontend dependencies: `lucide-react` to 1.27.0, `recharts` to 3.10.1, `@radix-ui/react-switch` to 1.3.7, `@radix-ui/react-tabs` to 1.1.21, and `@vitejs/plugin-react` to 6.0.4.
- Bumped test tooling across majors: `jsdom` to 30.0.1 and `jest-axe` to 11.0.0 (`axe-core` 4.12.1).
- Bumped `@types/node` to 26.1.2.
- Bumped pinned GitHub Actions: `actions/checkout` to v7.0.1, `github/codeql-action` (`init` and `analyze`) to v4.37.3, and `trufflesecurity/trufflehog` to v3.96.0.

### Documentation

- Recorded that `npm run rust:audit` is reachable only through `npm run release:check` and is not wired into any GitHub workflow, and that the duplicated dev-only `axe-core` in the dependency tree is left in place on purpose.

## [1.6.2](https://github.com/bernardopg/ioruba/compare/v1.6.1...v1.6.2) (2026-07-20)

### Changed

- Bumped `tauri-plugin-serialplugin` (Rust and JS/TS) to 3.0.1, `tauri-plugin-dialog` to 2.7.2, and `tauri-plugin-single-instance` to 2.4.3.
- Bumped `serde` to 1.0.229, `serde_json` to 1.0.151, and `thiserror` to 2.0.19.
- Bumped frontend dependencies: `vite` to 8.1.5, `@tailwindcss/vite` to 4.3.3, `lucide-react` to 1.25.0, `@radix-ui/react-switch` to 1.3.4, `@radix-ui/react-tabs` to 1.1.18, and the `@fontsource/instrument-sans`/`@fontsource/space-grotesk` font packages to 5.3.0.
- Bumped pinned GitHub Actions: `actions/setup-node` to v7.0.0, `github/codeql-action` to v4.37.1, and `softprops/action-gh-release` to v3.0.2.

## [1.6.1](https://github.com/bernardopg/ioruba/compare/v1.6.0...v1.6.1) (2026-07-15)

### Changed

- Migrated to `tauri-plugin-serialplugin` v3 (Rust and JS/TS API). Auto-reconnect and the serial read stream are now managed natively by the plugin (`watch()`/`WatchHandle.unwatch()` replaces the old `listen()`/`startListening()`/`cancelListen()` trio), instead of coordinating it manually in `use-serial-runtime.ts`.
- Bumped TypeScript to 7.0.2.

### Fixed

- Worked around a packaging bug in `tauri-plugin-serialplugin-api@3.0.0` where its `"development"` export condition pointed at a source file the npm package never ships, breaking module resolution in local dev and tests.

## [1.6.0](https://github.com/bernardopg/ioruba/compare/v1.5.3...v1.6.0) (2026-07-10)

### Added

- Added a floating runtime status pill that reports the exact running binary version, device state, active serial port, audio backend, and latest serial frame while avoiding the installed-update toast.
- Added compact header actions for the embedded changelog, notifications, and app settings. The reusable native dialog shell supports modal focus trapping, Escape/backdrop dismissal, and focus restoration.
- Added opt-in GitHub release notifications with six-hour checks, semantic-version comparison, unread state, deduplication, persisted preferences, and direct access to release and repository pages.
- Added a centralized app settings dialog for the active profile language and theme, release notifications, launch-on-login, running version, and changelog access. All new interface chrome is translated into English and Spanish.

### Changed

- Simplified the desktop sidebar to its compact brand, connection health, and icon-plus-label navigation. Runtime port, backend, and serial telemetry now live in the status pill, and the top ribbon keeps only session and active-profile context.

### Security

- External links now use `tauri-plugin-opener` with capability scope restricted to `https://github.com/bernardopg/ioruba*`; the CSP only adds `https://api.github.com` for release checks.

## [1.5.3](https://github.com/bernardopg/ioruba/compare/v1.5.2...v1.5.3) (2026-07-09)

### Fixed

- Fixed a WebKitWebProcess segfault when hiding the window to the tray after the Ioruba binary was replaced on disk (e.g. by a system package upgrade) while the old process was still running. The app now snapshots its own executable at boot and, when the binary has been swapped, closing the window or reopening it from the tray triggers a clean in-place restart instead of hiding/rebuilding the webview against the replaced assets. The frontend shows a dismissable "Update installed" toast (translated to en/es) with a "Restart now" action.

## [1.5.2](https://github.com/bernardopg/ioruba/compare/v1.5.1...v1.5.2) (2026-07-09)

### Fixed

- Persisted profiles saved before the firmware baud-rate bump (0.4.x → 0.5.x, 9600 → 115200) now self-heal to 115200 on load instead of getting stuck in a permanent handshake retry loop.
- Firmware (0.6.1): ESP8266/ESP32 builds now disable the WiFi radio in `setup()` (this sketch is serial-only and never uses WiFi). The default-on radio was injecting measurable ADC noise, especially noticeable as jitter when touching the potentiometer wiper.

## [1.5.1](https://github.com/bernardopg/ioruba/compare/v1.5.0...v1.5.1) (2026-07-09)

### Security

- Added a dedicated Secret Scan workflow with pinned Gitleaks and TruffleHog jobs on pushes, pull requests, weekly schedules, and manual dispatches.
- Added local secret-scanning scripts and a `release:check` gate so release validation now covers Gitleaks, TruffleHog, Rust audit, firmware matrix, script linting, tests, build, and docs generation.
- Updated Rust transitive dependencies `plist` to 1.10.0, `quick-xml` to 0.41.0, and `anyhow` to 1.0.103, clearing the actionable `cargo audit` vulnerabilities while keeping the known GTK3/Tauri informational warnings.

### Changed

- Removed tracked `.serena` project metadata and expanded ignore rules so local agent/tool state stays out of releases.

## [1.5.0](https://github.com/bernardopg/ioruba/compare/v1.4.0...v1.5.0) (2026-07-09)

### Features

- Firmware support for ESP8266 (NodeMCU and compatible boards): board detection, `ANALOG_PINS`/`MCU_NAME` branches, and the existing `IORUBA_NUM_KNOBS` compile-time override cover its single exposed analog pin (A0). Validated on a physical NodeMCU V3 (CH340) — see `docs/guides/hardware-setup.md` for the required build-property flag and CI job.
- `RAW ON`/`RAW OFF` serial command: an opt-in mode where the periodic frame carries unfiltered, oversampled ADC readings (prefixed `RAW`) instead of the calibrated `n|n|n` frame, for a future live-capture calibration wizard. Disabled by default so existing hosts see no frame-shape change.
- ADC oversampling: each knob reading now averages 4 consecutive `analogRead()` samples, reducing single-sample noise on all boards.
- Encoders now use pin-change interrupts on boards that support `attachInterrupt` on both quadrature pins (ESP32/ESP8266/RP2040), instead of only being sampled once per loop iteration — a blocking `Serial.print` (handshake, RAW mode) can no longer cause a missed quadrature step. AVR boards (Nano/Uno/Mega/Leonardo/Micro), whose fixed encoder pins aren't interrupt-capable, keep the previous polling behavior unchanged.

### Fixed

- Serial connection no longer goes deaf after a disconnect/connect cycle or after applying knob calibration. The serial plugin's `close()` only pauses its auto-reconnect manager while keeping it enabled, so the disconnected event emitted by the close itself re-armed the loop and a "zombie" port reopened in the background seconds later, stealing the read thread from the next connection (status showed connected while frames never arrived, and knobs stopped controlling audio until the app was restarted). The runtime now explicitly disables auto-reconnect before closing, takes the port reference atomically so concurrent teardowns cannot double-close, and serializes open/close operations through a queue — eliminating the `Serial port open/close already in progress` races visible in the watch log.
- Calibration settings sent via the `CONFIG` serial command are no longer silently lost on the next reset/power-cycle on ESP32/RP2040/ESP8266 boards. Their flash-emulated EEPROM requires an explicit `EEPROM.begin(size)` before use and `EEPROM.commit()` after `put()` to actually persist — both were missing, so the write only ever reached RAM. Validated on a physical ESP8266 NodeMCU (config survives a reset). AVR boards were unaffected (real byte-addressable EEPROM).

### Changed

- Launching the app while an instance is already running (launcher click, `.desktop` entry, duplicate autostart) now brings the existing window back from the tray instead of spawning a second process (`tauri-plugin-single-instance`).
- The tray icon now carries an "Ioruba" tooltip.
- The AUR packages install the desktop entry as `io.ioruba.desktop.desktop` with `StartupWMClass=io.ioruba.desktop`, matching the Wayland `app_id`/X11 `WM_CLASS` set by `enableGTKAppId` — fixing window-to-icon association in Hyprland, waybar taskbars and docks (previously `ioruba.desktop` with `StartupWMClass=Ioruba` never matched).
- Firmware serial baud rate default raised from 9600 to 115200 (firmware constant and the host's `profile.serial.baudRate` default). The field remains freely configurable per profile for boards/cables that need a lower rate.

## [1.4.0](https://github.com/bernardopg/ioruba/compare/v1.3.2...v1.4.0) (2026-07-08)

### Features

- The interface is now available in Spanish (`es`), alongside Portuguese (Brazil) and English. The translation layer was restructured into per-language maps (`TEXT_MAP_EN`/`TEXT_MAP_ES` registered in `LANGUAGE_TEXT_MAPS`), the `UiLanguage` union and its validation were extended end to end (shared normalization and the profile JSON editor fall back to `pt-BR` on unknown values), and the profile editor's language selector offers the new option. The translation guide documents how to add further languages.
- Dashboard accessibility audit (Scrum 18): the sidebar navigation now implements the full WAI-ARIA tabs keyboard pattern — Arrow keys move selection with roving focus, Home/End jump to the extremes; previously inactive tabs carried `tabindex="-1"` with no key handler, making them unreachable by keyboard. The calibration wizard manages focus across its lifecycle (focus moves into the session panel when calibration starts and returns to the originating knob's button when it ends), announces step changes through a polite live region, and raises the short-span validation as an assertive alert.

### Changed

- Assistive-technology polish across panels: watch log filter buttons expose `aria-pressed`, hardware and session-statistics tables mark their header cells with `scope="col"`, the telemetry chart is exposed as a named image (`role="img"`) instead of leaking raw SVG internals to screen readers, and the advanced JSON editor textarea gained an accessible name. Automated axe coverage now spans every dashboard panel (HardwarePanel, CalibrationWizard, SessionStatsPanel, WatchLogPanel, OverviewSignalPanel, and all three ProfileWorkbench views).

### Fixed

- A typo in the knob panel outcome summary class (`wrap-break-wordword`) that prevented long outcome texts from wrapping.

## [1.3.2](https://github.com/bernardopg/ioruba/compare/v1.3.1...v1.3.2) (2026-07-08)

### Features

- New knob calibration wizard in the Hardware section: a guided min -> max -> review flow per knob that tracks the observed extreme from live serial readings (more robust than instant capture), validates the captured span and stores `minRaw`/`maxRaw` in the active profile. The serial runtime already pushes a `CONFIG` command whenever the profile diverges from the firmware, so applying the wizard result syncs the hardware with no extra step.

### Fixed

- Volume writes are now throttled (leading + trailing) instead of debounced while a knob is moving. The previous pure debounce restarted its timer on every serial frame, so with smooth transitions enabled the audio backend was only invoked after the knob stopped moving; rapid knob movement now applies the first batch immediately and coalesces the burst into at most one backend call per profile transition window (40 ms minimum), always carrying the latest value per slider.
- The release workflow no longer wastes runner time on nonexistent tags. Manual dispatches (`workflow_dispatch`) accepted any `release_tag` input — a typo such as `v1.4.0` for a tag that was never created caused every bundle job (Linux, Windows, macOS ×2, firmware, Arch) to fail at the `checkout` step in parallel, burning up to ~10 minutes of runner time per platform before erroring. A new `validate-tag` job now runs first: it rejects malformed or nonexistent tags in seconds and short-circuits the entire pipeline before any build starts.
- Release publish and attestation jobs no longer run when upstream builds fail. The `arch-pkgbuild`, `attest-and-checksum`, and `aur-publish` jobs previously gated on `!= 'cancelled'`, which evaluates to true on failure — meaning a broken bundle could still produce PKGBUILD metadata, generate build-provenance attestations for an incomplete release, or push to the AUR. They now require `== 'success'` so a partial release never reaches distribution.

### Changed

- The duplicated audio-backend helpers (`describe_target`, `summarize_slider_outcome`, `volume_percent`) and the whole master-only slider-apply loop shared by the Windows and macOS backends were extracted into `audio/common.rs`. The platform backends now only provide a `set_master_volume` closure, outcome strings are parameterized by platform name, and the shared batching/summary logic is covered by host-independent unit tests that run on every CI platform (previously `windows.rs`/`macos.rs` had no tests at all). No behavior change.
- The release pipeline now validates the release tag before kicking off the full CI gate (`typecheck`, shared/desktop tests, firmware matrix, native-audio smoke on Windows/macOS), so a bad tag fails fast instead of consuming the entire multi-platform CI budget.

## [1.3.1](https://github.com/bernardopg/ioruba/compare/v1.3.0...v1.3.1) (2026-06-25)

### Fixed

- The Home dashboard metric cards now lay out responsively and no longer compress their icons when the value text is long. Metric styling moved from inline Tailwind utilities into dedicated CSS classes (`.metric-card` / `.metric-body` / `.metric-icon` / `.metric-copy`), the metric grid uses `auto-fit` columns, and the hardware panel corners are aligned to `rounded-2xl`.

### Changed

- CI and release builds now pin the macOS runner to `macos-15` instead of the floating `macos-latest` label, which migrates to macOS 26 from 2026-06-15 (actions/runner-images#14167). Release builds stay reproducible, and the bundle/signing/notarization step conditionals were decoupled from the exact label (`startsWith(matrix.platform, 'macos')`) so the pinned version can be bumped without touching every gate.

## [1.3.0](https://github.com/bernardopg/ioruba/compare/v1.2.3...v1.3.0) (2026-06-22)

### Fixed

- Serial frame watch-log entries are now throttled to at most one per second. The firmware streams frames continuously and the buffered serial backlog is drained in a burst on connect, which previously flooded the watch log with hundreds of identical `Frame serial recebido` / `Slideres elegiveis para aplicacao` entries within a few milliseconds. Audio application is unaffected — only logging is sampled.
- The firmware handshake is now retried (up to 5 times, every 2 s) while no handshake has been received. The initial `HELLO?` could be lost to the DTR auto-reset / bootloader boot noise, leaving the app stuck on "Aguardando handshake" even though frames were streaming normally.

### Changed

- The release workflow now gates every build and publish job on the full CI workflow (reused via `workflow_call`), including the Windows/macOS `native-audio-smoke` job. This stops a tag from becoming a release with a broken platform build — the cause of the v1.2.2 → v1.2.3 hotfix, where the Windows compile error was only detected by CI after the tag was pushed
- The GitHub Release body is now the matching `CHANGELOG.md` section, extracted deterministically and published verbatim (with a download-verification footer)
- Dropped the duplicated firmware host-parser test from the release pipeline; the `firmware-host` CI job already runs it via the `ci-gate`, so the release job only builds and uploads the artifact

### Removed

- Removed the AI-assisted changelog generation from the release pipeline (the `prepare-release-notes` job: GitHub Copilot CLI with a Codex fallback that committed and pushed a generated `CHANGELOG.md` back to `main` mid-release). Release notes are now hand-authored and reviewed in `CHANGELOG.md` — no machine-generated content, no release-time writes to `main`, and no `COPILOT_PAT` / `OPENAI_API_KEY` in the release path
- Removed the archived `legacy/` Python/GTK prototype and the `docs/migration/` planning material, along with every reference to the legacy directory across root docs, the PT-BR mirror set, and the docs-site. The legacy `P1:512` packet-format compatibility (a live protocol feature) is unaffected.

## [1.2.3](https://github.com/bernardopg/ioruba/compare/v1.2.2...v1.2.3) (2026-06-21)

### Fixed

- Fixed the Windows Rust build for the new mute control action by using the `IAudioEndpointVolume::SetMute(bool, ...)` wrapper directly instead of importing a non-exported `Win32::Foundation::BOOL` type

## [1.2.2](https://github.com/bernardopg/ioruba/compare/v1.2.1...v1.2.2) (2026-06-21)

### Features

- Completed Scrum 11 button/encoder support: profiles now accept `controls` bindings for `mute`, `next` and `prev`, and the shared serial parser understands prefixed `EV` button/encoder packets without changing existing slider frames
- Firmware `0.5.1` can be compiled with `IORUBA_NUM_BUTTONS` / `IORUBA_NUM_ENCODERS`, reads digital controls with `INPUT_PULLUP`, debounce and encoder quadrature, and emits control events only after the desktop opts in with `EVENTS ON`
- Desktop runtime resolves control events from the active profile and dispatches actions through Tauri: Linux supports mute via `pactl` and media next/previous via `playerctl`; Windows supports default-output mute; unsupported actions are reported in the watch log instead of breaking serial processing

### Changed

- Hardware setup documentation now covers optional button/encoder wiring, compile flags, control-event packets and profile `controls` examples in English and Portuguese

## [1.2.1](https://github.com/bernardopg/ioruba/compare/v1.2.0...v1.2.1) (2026-06-21)

### Features

- knob→audio apply latency is now instrumented: each batch apply is timed and a `warning` is logged to the watch log when it exceeds the budget (80 ms), with the elapsed time and target count — surfacing slow `pactl`/backend calls without flooding the log (Scrum 13)
- Export session telemetry statistics to a file as JSON or CSV (Scrum 16): new buttons on the session-stats panel save a per-knob summary (samples, min/avg/max/last percent) via a save dialog, reusing the existing export flow. Pure `sessionStatsToJson` / `sessionStatsToCsv` formatters in `@ioruba/shared` and an `export_session_stats` Tauri command
- Always-visible connection-health indicator in the sidebar (Scrum 18): a colour-coded status dot + label and a live signal-freshness readout (time since the last serial/demo frame, refreshed every second) as a latency proxy, aligned with `.impeccable.md` ("connection state must be impossible to miss"). Backed by a new `lastFrameAt` field in the store
- Redesigned navigation: the sidebar is now organized into labelled groups (Operation / Monitoring / Adjustments) with finer-grained sections. Channels (live knobs) split out of the control panel, and a dedicated Hardware section was added
- Settings split into three focused sidebar entries — Profiles, Editor and Advanced — each a full-width view instead of one dense two-column page (the `ProfileWorkbench` now takes a `view` prop)
- New `HardwarePanel` surfaces the firmware handshake end to end — board, MCU, ADC resolution (10/12-bit), protocol compatibility, knob count and per-knob calibration — with a clear empty state when no controller is connected (Scrum 18: hardware diagnostics panel)
- ESP32 and RP2040/Pico toolchains are now built in CI (Scrum 11): a dedicated `firmware-arch` job installs each 12-bit core and compiles the firmware, validating the `adcBits=12` path end to end on real toolchains
- Per-board analog-pin tables (Scrum 11): the firmware no longer hard-codes `{A0, A1, A2}`. Pins are selected at compile time per board (Nano A0..A7, Uno A0..A5, Mega2560 A0..A15, Leonardo/Micro A0..A11, ESP32 ADC1, RP2040/Pico A0..A2) and the first `IORUBA_NUM_KNOBS` are used. This enables **>6 knobs on the Mega** (up to 16); a `static_assert` rejects a knob count that exceeds the board's analog channels
- CI compiles the firmware across an FQBN matrix (Nano, Uno, Mega2560, Leonardo, Micro); a dedicated host job runs the config-parser tests in both the default (3 knobs / 10-bit) and wide (8 knobs / 12-bit) configurations. `npm run firmware:compile:matrix` and `npm run firmware:test:wide` reproduce these locally
- Supported-boards matrix (MCU, ADC bits, channels, max knobs, pin order) documented in `docs/guides/hardware-setup.md`
- ADC resolution is now generic across boards (Scrum 11 keystone). The firmware handshake reports `mcu=` and `adcBits=` (additive protocol v2 fields; older hosts ignore them), and `@ioruba/shared` normalizes raw readings against the active `adcBits` instead of the hard-coded 10-bit `1023`. 12-bit boards (ESP32, RP2040/Pico → `0..4095`) now map to the correct percent
- Firmware derives `ADC_MAX` from `IORUBA_ADC_BITS` (auto-set to 12 on ESP32/RP2040, 10 on AVR; overridable by define) and reports the detected MCU name (`ATmega328P`/`ATmega2560`/`ATmega32U4`/`RP2040`/`ESP32`)
- Desktop overview panel shows a Hardware tile with the detected board, MCU, ADC bit depth and protocol version

### Fixed

- Firmware `BOARD_NAME` constant renamed to `IORUBA_BOARD_NAME` to avoid a collision with the `BOARD_NAME` macro defined by the arduino-pico (RP2040) core, which broke RP2040 builds

### Security

- Updated transitive development dependency `undici` from `7.25.0` to `7.28.0`, resolving CVE-2026-9697 and CVE-2026-9678 reported by Dependabot

### Changed

- `@ioruba/shared` mixer/runtime functions take an optional `adcMax` argument (defaults to 10-bit for backward compatibility); the serial frame parser accepts raw values up to 16-bit, leaving per-board normalization to the runtime via `adcBits`

## [1.2.0](https://github.com/bernardopg/ioruba/compare/v1.1.0...v1.2.0) (2026-06-17)

### Features

- Cross-platform one-line installer: `scripts/install.sh` (Linux/macOS) and `scripts/install.ps1` (Windows) auto-detect OS and architecture, download the matching asset from the latest release (or a pinned `--version`/`-Version`), verify it against `SHA256SUMS.txt`, and install it (rootless AppImage by default on Linux, `.app` into `/Applications` on macOS, MSI/NSIS on Windows)
- Session telemetry statistics: per-knob sample count, min/avg/max and current percent that persist for the whole session (independent of the sliding chart window), shown in a new `SessionStatsPanel` on the telemetry tab with a reset action
- `updateSessionStats` / `createSessionStats` / `knobAveragePercent` pure reducers in `@ioruba/shared` (O(points), no unbounded growth); session aggregates reset automatically whenever telemetry is cleared (new connection, demo toggle, profile reset)

- Windows Core Audio backend (`audio/windows.rs`) using WASAPI via `windows` crate for default output (`master`) volume control
- macOS Core Audio backend (`audio/macos.rs`) using the system `CoreAudio` framework (hand-rolled FFI, no extra crate) for default output (`master`) volume control, with per-channel scalar fallback
- Application/source/sink targets return explicit `unavailable` outcome on Windows and macOS instead of pretending to work
- AppImage validation script (`scripts/validate-appimage.sh`) with extraction, structure, and optional launch smoke test under Xvfb
- CI integration: Linux release job runs `scripts/validate-appimage.sh --require-launch` on Ubuntu 22.04 before publishing assets
- CI: `native-audio-smoke` matrix job compiles, lints, and links the Rust backend on `macos-latest` and `windows-latest`, validating the cfg-gated CoreAudio/WASAPI code that the Linux gate never builds
- `AudioBackendBanner` distinguishes platform-unsupported (Windows/macOS) from missing-pactl (Linux) with tailored fallback UX
- Test coverage for audio backend banner fallback behavior (`audio-backend-banner.test.tsx`)

### Changed

- Platform matrix: Windows and macOS now "Partial" (master/default-output volume only via Core Audio)
- Updated docs (README, QUICKSTART, TESTING) to reflect Windows and macOS partial audio support

### Fixed

- Onboarding checklist marks audio as ready for any functional backend (Windows/macOS Core Audio), not only the Linux `pactl` backend
- Completed the `AudioInventory.backend` type union with the `"macos"` member the Rust backend already serializes
- Collapsed identical severity branches in `audio/windows.rs` (clippy `if_same_then_else`), surfaced for the first time by the new Windows CI smoke job

## [1.1.0](https://github.com/bernardopg/ioruba/compare/v1.0.0...v1.1.0) (2026-06-13)

### Features

- ready-made profile presets for streaming, calls, and music, applied from the profile workbench
- import and export profiles as JSON files (`export_profile` / `import_profile` Tauri commands with save/open dialogs and atomic write), with validation and id/name de-duplication on import
- first-run onboarding checklist on the home tab deriving live steps from runtime state (controller connected, serial port found, audio backend available); dismissal is persisted
- firmware protocol-version validation: `SUPPORTED_PROTOCOL_VERSION` and a `protocolSupported` flag warn when a connected firmware speaks a different protocol
- boot, serial-connection, and inventory-refresh timings recorded in the watch log via `performance.now()`
- firmware now emits `ERR command-too-long` / `ERR config-rejected` and skips redundant EEPROM writes on unchanged `CONFIG`

### Performance

- `pushTelemetry` rewritten to a single allocation per serial frame (was merge-and-slice)
- telemetry chart lazy-loaded (recharts kept out of the initial bundle until the telemetry tab opens), memoized series, and `React.memo` renders
- short-TTL cache for the `pactl` inventory snapshot shared between listing and applying volumes
- watch-log append is now O(1) amortized instead of a full read-modify-write per event
- knob bars honor the configured `transitionDurationMs` (and `prefers-reduced-motion`) instead of a fixed duration

### Bug Fixes

- fixed `clippy::needless_borrow` so the `-D warnings` gate compiles
- fixed undefined behavior passing a possibly-negative `char` to `isspace` in firmware
- partial `pactl` failures are surfaced in inventory diagnostics instead of returning an empty inventory

### Security

- restrictive Content-Security-Policy on the webview (was `null`)
- narrowed the dialog capability to `allow-save` + `allow-open` (was the full default)
- `persist-credentials: false` on every read-only checkout in CI
- pinned the CodeQL action to a fixed `v4.36.2` SHA and stopped cancelling scheduled scans

### Changed

- hardened persisted-state writes: dedicated lock, unique temp suffix, and `fsync` before/after rename
- `apply_slider_targets_batch` runs async via `spawn_blocking` so blocking `pactl` calls leave the command thread
- CI gains `cargo fmt`/`clippy -D warnings`, a firmware host-test for the `CONFIG` parser, a glib-vendor staleness gate, and SHA-pinned actions
- added a product roadmap (`docs/roadmap.md`) with a multi-controller study and post-migration backlog

## [1.0.0](https://github.com/bernardopg/ioruba/compare/v0.6.12...v1.0.0) (2026-06-12)

### Changed

- refreshed frontend, Tauri CLI, Rust, and GitHub Actions dependencies
- grouped compatible Dependabot updates to reduce fragmented dependency PRs

### Removed

- removed the unreliable automated documentation update workflow
- removed the obsolete vendored PHF generator patch after the dependency graph moved to PHF 0.13

## [0.6.12](https://github.com/bernardopg/ioruba/compare/v0.6.11...v0.6.12) (2026-05-22)

### Features

- added `schemaVersion` field to `PersistedState` for future-safe migration tracking
- atomic state write with `.tmp` + rename, eliminating partial-write corruption
- automatic backup of persisted state when `schemaVersion` changes (named `ioruba-state.backup.v{ver}.{timestamp}.json`)
- export watch log via save-file dialog (`tauri-plugin-dialog`), writing JSON Lines; Rust command `export_watch_log` returns path and entry count
- Export button in the Watch Log panel with inline result/cancellation message and accessible `aria-live` status
- JSON parse errors in profile import now include line and column numbers

### Bug Fixes

- `load_watch_log_entries` now reports malformed lines as a structured `Warning` in the watch log instead of silently discarding them
- allowed non-Linux audio module code paths to compile without dead-code warnings

### Changed

- updated docs-site home page (`index.md`), added Getting Started guide, quick-reference sidebar card, and new deck cards on the home layout

## [0.6.11](https://github.com/bernardopg/ioruba/compare/v0.6.10...v0.6.11) (2026-05-22)

### Changed

- synchronized desktop package metadata for the 0.6.11 release
- updated release jobs to build artifacts from the target release tag and keep updater JSON disabled until updater signing is configured

### Bug Fixes

- split the macOS build into signed and unsigned steps to avoid codesign failures
- patched `tauri.conf.json` to use ad-hoc macOS signing when no certificate secret is available
- allowed downstream release jobs to run after partial matrix failures
- handled rebase failures and tightened job conditions for desktop builds

## [0.6.10](https://github.com/bernardopg/ioruba/compare/v0.6.9...v0.6.10) (2026-05-22)

### Features

- added `AudioBackendBanner` for missing `pactl` detection
- classified serial open errors with actionable messages in the runtime observability flow
- configured Windows and macOS code signing and notarization
- closed Scrum 07 release tasks (provenance, checksums, tray docs, recovery guide)

### Bug Fixes

- hardened CI workflow correctness and safety
- fixed CI step conditions to avoid `Unrecognized named-value: secrets` errors

## [0.6.9](https://github.com/bernardopg/ioruba/compare/v0.6.8...v0.6.9) (2026-05-22)

### Changed

- bumped all Dependabot updates (#40-#49)
- updated the changelog for v0.6.8

## [0.6.8](https://github.com/bernardopg/ioruba/compare/v0.6.7...v0.6.8) (2026-05-07)

### Changed

- hardened the docs auto-update workflow in CI
- synchronized repository documentation and refreshed the repository screenshot
- refreshed desktop dependencies across Tauri and frontend tooling (`@tauri-apps/api`, `@tauri-apps/cli`, `tauri`, `tauri-build`, `@vitejs/plugin-react`, `@tailwindcss/vite`, `vitest`, `jsdom`, `lucide-react`)

### Bug Fixes

- removed a duplicate `Sessão` key in `TEXT_MAP`

### Security

- updated the Tauri security patch and bumped the `rand` dependency line in the desktop stack

## [0.6.7](https://github.com/bernardopg/ioruba/compare/v0.6.6...v0.6.7) (2026-04-22)

### Bug Fixes

- skipped the macOS `dmg` bundle in CI release builds to avoid macOS GUI-dependent bundling failures and keep macOS artifacts publishable

### Changed

- updated changelog entries for the `v0.6.7` release

## [0.6.6](https://github.com/bernardopg/ioruba/compare/v0.6.5...v0.6.6) (2026-04-22)

### Changed

- synchronized repository documentation

### Features

- added an automated documentation update workflow

## [0.6.4](https://github.com/bernardopg/ioruba/compare/v0.6.3...v0.6.4) (2026-04-21)

### Bug Fixes

- fixed `arch-pkgbuild` job computing sha256sum from a local `git archive` tarball instead of the actual GitHub-generated tarball; the two differ in metadata so hashes never matched, causing `makepkg` verification to fail on install; replaced with a `curl` download of the real `archive/refs/tags/vN.N.N.tar.gz` before hashing

## [0.6.3](https://github.com/bernardopg/ioruba/compare/v0.6.2...v0.6.3) (2026-04-21)

### Bug Fixes

- fixed `aur-publish` job failing to download `.SRCINFO` and `.SRCINFO-bin` assets: GitHub silently renames dot-prefixed files on upload (`.SRCINFO` → `default.SRCINFO`); release assets are now uploaded as `SRCINFO`/`SRCINFO-bin` (no leading dot) and renamed back to `.SRCINFO` after download in the `aur-publish` step

## [0.6.2](https://github.com/bernardopg/ioruba/compare/v0.6.1...v0.6.2) (2026-04-21)

### Bug Fixes

- fixed PKGBUILD-bin generation: nested `<<'LAUNCHER'` heredoc inside `<<EOF` caused YAML indentation stripping to break the heredoc delimiter, producing a syntactically invalid PKGBUILD; replaced with `run-appimage-compat.sh` fetched as a source entry and a two-line `printf` wrapper
- fixed `.SRCINFO` source lines using literal `${pkgver}` instead of the expanded version number
- fixed `.SRCINFO` and `.SRCINFO-bin` missing `provides`, `conflicts`, and `replaces` fields
- fixed `PKGBUILD-bin` missing `provides=ioruba`, `conflicts=ioruba-desktop-bin`, and `replaces=ioruba`
- added missing `libayatana-appindicator3-dev` to CI Linux dependency list, preventing silent build failures

### Features

- added `aur-publish` job to the release workflow: automatically clones `ioruba-desktop` and `ioruba-desktop-bin` AUR repos and pushes updated PKGBUILDs after each release, eliminating manual AUR publishing

## [0.6.1](https://github.com/bernardopg/ioruba/compare/v0.6.0...v0.6.1) (2026-04-20)

### Changed

- split the desktop release workflow so the AppImage upload runs in its own job, isolating it from the other installers
- added a timeout guard to the desktop bundle jobs to avoid indefinite hangs during release publication

### Bug Fixes

- kept the AppImage publish step from blocking the deb/rpm/Windows/macOS release assets

## [0.6.0](https://github.com/bernardopg/ioruba/compare/v0.5.0...v0.6.0) (2026-04-20)

### Changed

- modernized the docs site, navigation, and page-generation workflow for GitHub Pages
- refreshed the Portuguese documentation set to align with the GitHub migration and README updates
- added Dependabot coverage for the docs and workflow surface
- refreshed TypeScript, Vitest, and GitHub Actions dependencies after Dependabot resolution

### Features

- added PT-BR documentation translations across the root docs, guides, migration notes, and support materials
- added an AppImage compatibility script and updated the desktop launcher and release flow

### Bug Fixes

- allowed the repository smoke workflow to include the scripts directory
- stabilized GitHub Actions usage across CI, CodeQL, and Pages deployment

## [0.5.0](https://github.com/bernardopg/ioruba/compare/v0.4.0...v0.5.0) (2026-04-20)

### Changed

- synchronized the workspace versioning and release metadata for the 0.5.0 cut
- refreshed the documentation set for the current desktop, firmware, testing, and migration flow

### Features

- added PT-BR/EN translation helpers, a translation guide, and accessibility shell coverage for the desktop app
- expanded the release workflow to ship AppImage and Arch packaging metadata alongside the existing desktop and firmware artifacts

### Bug Fixes

- stabilized CodeQL workflow configuration and Dependabot update resolution
- improved the Linux packaging dependency path for the current release flow

## [0.4.0](https://github.com/bernardopg/ioruba/compare/v0.3.0...v0.4.0) (2026-04-19)

### Changed

- refreshed the repository documentation to match the active Tauri desktop stack, Linux-first audio support, and current hardware workflow
- added the Arduino Nano Type-C circuit diagram and updated the Nano, hardware, testing, and release docs for the new firmware handshake and Arch smoke-test flow

### Features

- persist knob calibration and firmware tuning in EEPROM
- add tray/background handling and launch-on-login support on Linux
- expose firmware thresholds, deadzone, smoothing, and per-knob calibration in the desktop profile workbench
- expand the serial handshake to report controller config with protocol v2

### Bug Fixes

- keep the release and CI workflows pinned to current GitHub Actions versions
- preserve legacy `P1:512` packets while adding controller config support to the serial parser
- align Linux desktop packaging metadata with tray and indicator requirements

### Security

- upgraded `vite` from `7.3.1` to `7.3.2` in the desktop toolchain
- resolved GitHub/Dependabot advisories `GHSA-p9ff-h696-f583`, `GHSA-v2wj-q39q-566r`, and `GHSA-4w7w-66w2-5vf9`
- confirmed the npm toolchain reports `0` open audit vulnerabilities after the upgrade
- documented that the remaining Rust audit findings are upstream/transitive warnings in the current Tauri + GTK3 Linux stack, not newly introduced project-level advisories

## [0.3.0](https://github.com/bernardopg/ioruba/compare/v0.2.3...v0.3.0) (2026-03-20)

### Features

- refresh the desktop control deck UI and live watch workflow
- persist watch logs and improve serial runtime diagnostics

### Bug Fixes

- keep Arduino serial sessions stable during idle periods and port discovery
- backport the Linux `glib` fix for `GHSA-wrw7-89jp-8q8g`

## [0.2.3](https://github.com/bernardopg/ioruba/compare/v0.2.2...v0.2.3) (2026-03-19)

### Bug Fixes

- preserve docker release artifact permissions ([2815390](https://github.com/bernardopg/ioruba/commit/28153905da65343efa4a78954a008b0e30ca1679))

## [0.2.2](https://github.com/bernardopg/ioruba/compare/v0.2.1...v0.2.2) (2026-03-19)

### Bug Fixes

- ship installable release artifacts ([d474351](https://github.com/bernardopg/ioruba/commit/d4743513bd184fd63e14e3679cc09bf569d4357c))

## [0.2.1](https://github.com/bernardopg/ioruba/compare/v0.2.0...v0.2.1) (2026-03-19)

### Bug Fixes

- pass tag name when uploading manual release assets ([08b7291](https://github.com/bernardopg/ioruba/commit/08b72914c1dd1d66d9fdbaf7c26c841f203e009a))
- support chained and manual release artifact runs ([42e42f8](https://github.com/bernardopg/ioruba/commit/42e42f8249eb56c182589337db2c82d8b97fb82f))

## [0.2.0](https://github.com/bernardopg/ioruba/compare/v0.1.0...v0.2.0) (2026-03-19)

### Features

- add Arduino Nano support with 3 potentiometers ([d04715b](https://github.com/bernardopg/ioruba/commit/d04715ba07441f23e29146bf434465604627f250))
- implement serial communication with Arduino ([2739438](https://github.com/bernardopg/ioruba/commit/2739438ee62e16fb263fe6bf02de5894dccbfc6c))
- polish runtime docs and release surface ([66138ba](https://github.com/bernardopg/ioruba/commit/66138baaeaee40310fa33b79d33b335ba5abeb72))
- refresh nano controller app and docs ([89d854d](https://github.com/bernardopg/ioruba/commit/89d854d7f556698f9e5c9de32ac663d78741e901))
- ship haskell runtime and modernize repo surface ([dd34cae](https://github.com/bernardopg/ioruba/commit/dd34cae5d2ef47202fbf29b376d70828b5b6b15b))

### Bug Fixes

- keep ci focused on actionable checks ([cdab0aa](https://github.com/bernardopg/ioruba/commit/cdab0aa493e5bf75412a822502978b9a6b15d161))
- keep release-please versioning on package yaml ([ae44855](https://github.com/bernardopg/ioruba/commit/ae44855ec6776dbc62baf29065452fc2227ca3f9))
- make CI fail faster and pass HLint ([bcae458](https://github.com/bernardopg/ioruba/commit/bcae458dc478c6773568ab3f8843d133ad1cbcf4))
- make metadata sync skip cleanly without token ([d59f445](https://github.com/bernardopg/ioruba/commit/d59f445c37c2c9212e8685f402699671b7b5687f))
- make release-please update generic version files ([d7c871d](https://github.com/bernardopg/ioruba/commit/d7c871d8cb5d361c2ff5b759e785aebdc0a90728))
- stabilize automation and hlint compliance ([0c7c114](https://github.com/bernardopg/ioruba/commit/0c7c11461a621bea55e568c7514f5ae5e374ba6a))

## [0.1.0] - 2025-12-22

### Added

- Initial tagged baseline before the current Haskell-first productization pass

[Unreleased]: https://github.com/bernardopg/ioruba/compare/v1.8.2...HEAD
[1.2.3]: https://github.com/bernardopg/ioruba/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/bernardopg/ioruba/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/bernardopg/ioruba/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/bernardopg/ioruba/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/bernardopg/ioruba/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/bernardopg/ioruba/compare/v0.6.12...v1.0.0
[0.6.12]: https://github.com/bernardopg/ioruba/compare/v0.6.11...v0.6.12
[0.6.11]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.11
[0.6.10]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.10
[0.6.9]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.9
[0.6.8]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.8
[0.6.7]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.7
[0.6.6]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.6
[0.6.4]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.4
[0.6.3]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.3
[0.6.2]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.2
[0.6.1]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.1
[0.6.0]: https://github.com/bernardopg/ioruba/releases/tag/v0.6.0
[0.5.0]: https://github.com/bernardopg/ioruba/releases/tag/v0.5.0
[0.4.0]: https://github.com/bernardopg/ioruba/releases/tag/v0.4.0
[0.3.0]: https://github.com/bernardopg/ioruba/releases/tag/v0.3.0
[0.1.0]: https://github.com/bernardopg/ioruba/releases/tag/v0.1.0

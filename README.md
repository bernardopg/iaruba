<div align="center">

<img src="docs/assets/banner.png" alt="Ioruba — desktop audio on physical controls" width="100%" />

<br />
<br />

**A tactile desktop audio deck built with Arduino, Tauri, React, and Rust.**

[![Release](https://github.com/bernardopg/ioruba/actions/workflows/release.yml/badge.svg?event=release)](https://github.com/bernardopg/ioruba/actions/workflows/release.yml)
[![CI](https://github.com/bernardopg/ioruba/actions/workflows/ci.yml/badge.svg)](https://github.com/bernardopg/ioruba/actions/workflows/ci.yml)
[![Version](https://img.shields.io/github/package-json/v/bernardopg/ioruba?filename=package.json&label=version)](package.json)
[![License: MIT](https://img.shields.io/badge/license-MIT-0A66C2)](LICENSE)
[![Docs: PT-BR](https://img.shields.io/badge/docs-PT--BR-0A66C2)](docs/translations/pt-br/README.md)

[![Linux: supported](https://img.shields.io/badge/Linux-supported-3FB950?logo=linux&logoColor=black)](#platform-support)
[![macOS: partial](https://img.shields.io/badge/macOS-partial-A0A0A0?logo=apple&logoColor=white)](#platform-support)
[![Windows: partial](https://img.shields.io/badge/Windows-partial-0078D6?logo=windows11&logoColor=white)](#platform-support)

[**Download**](https://github.com/bernardopg/ioruba/releases/latest) · [**Quick start**](QUICKSTART.md) · [**Build the controller**](docs/guides/hardware-setup.md) · [**Documentation**](docs/index.md) · [**Português**](docs/translations/pt-br/root/README.md)

</div>

## What is Ioruba?

Ioruba turns inexpensive microcontroller hardware into a physical desktop audio controller. The reference build uses an **Arduino Nano and three potentiometers**, but the firmware also supports Uno, Mega 2560, Leonardo/Micro, ESP32, RP2040/Pico, and ESP8266 configurations.

Turn a knob and Ioruba reads the serial frame, applies the active profile, updates live telemetry, and changes the configured audio target. On Linux, targets can be the master output, individual applications, sinks, or sources. Windows and macOS currently support the default output only.

<div align="center">

![Ioruba desktop dashboard](docs/assets/screenshot.png)

<sub>Desktop dashboard with connection health, live controls, telemetry, hardware diagnostics, profiles, and watch logs.</sub>

</div>

## Highlights

- **Physical controls:** potentiometers, optional buttons, and rotary encoders.
- **Flexible firmware:** 1–16 knobs depending on the board, 10-bit and 12-bit ADC support, calibration stored in EEPROM, and protocol metadata in the handshake.
- **Linux audio coverage:** master, application, sink, and source volume through `pactl`; targeted mute and media actions are also available.
- **Cross-platform desktop app:** real default-output volume on Windows through WASAPI and on macOS through CoreAudio.
- **Profiles:** presets, a visual editor, advanced JSON, import/export, per-control calibration, and targeted mute bindings.
- **Diagnostics:** connection health, hardware identity, live telemetry, session statistics export, and a persistent watch log.
- **Desktop integration:** tray behavior, `Ctrl+Alt+I` window toggle, launch-on-login, release notifications, and signed in-app updates.
- **Internationalized UI:** Portuguese (Brazil), English, and Spanish.
- **Verified releases:** checksums, GitHub build provenance, signed updater artifacts, and generated package-manager manifests.

## Platform support

| Platform | Audio support | Distribution notes |
| --- | --- | --- |
| **Linux** | Full: `master`, `application`, `sink`, and `source` through a PulseAudio-compatible `pactl` interface. | `.deb`, `.rpm`, AppImage, AUR source package, and AUR binary package. |
| **Windows** | Partial: default output (`master`) volume and mute through WASAPI. | MSI and NSIS installers; Scoop and winget manifests. Bundles are unsigned — SmartScreen shows "unrecognized app"; choose **More info → Run anyway**. |
| **macOS** | Partial: default output (`master`) volume through CoreAudio. | Apple Silicon and Intel `.app.tar.gz`; Homebrew cask. Bundles are unsigned and not notarized; the installer and cask strip the quarantine attribute. |

The project holds no Apple Developer ID or Windows Authenticode certificate, so
desktop bundles carry no platform code signature. Verify any download with the
published `SHA256SUMS.txt`, or with
`gh attestation verify <asset> --repo bernardopg/ioruba`. In-app updates are
signed independently with the project's own updater key and are always verified
before installation.

Serial input, profiles, demo mode, telemetry, and diagnostics work on all three desktop platforms. Application/source/sink targets remain Linux-only.

## How it works

```text
Physical control
  → Arduino firmware
  → serial protocol
  → shared TypeScript parser and runtime math
  → Zustand store
  → typed Tauri command
  → platform audio backend
```

| Layer | Path | Responsibility |
| --- | --- | --- |
| Firmware | `firmware/arduino/ioruba-controller` | Reads controls, stores calibration, and emits handshake, knob, and event frames. |
| Shared domain | `packages/shared` | Owns types, defaults, profile validation, protocol parsing, presets, and knob-to-value math. |
| Desktop UI | `apps/desktop/src` | Runs the serial session, state store, profile editor, telemetry, diagnostics, and updater UI. |
| Rust shell | `apps/desktop/src-tauri` | Provides persistence, watch logging, desktop integration, and platform audio commands. |

Protocol and runtime-math changes belong in `packages/shared`, not in the app, so every consumer uses the same behavior.

## Install

Prebuilt artifacts are published on the [latest release](https://github.com/bernardopg/ioruba/releases/latest). The installers below detect the host platform and architecture and require an exact match in `SHA256SUMS.txt`; they refuse an unverified installation.

> Review remote scripts before piping them into a shell. The sources are [`scripts/install.sh`](scripts/install.sh) and [`scripts/install.ps1`](scripts/install.ps1).

### Linux and macOS

```bash
curl -fsSL https://raw.githubusercontent.com/bernardopg/ioruba/main/scripts/install.sh | sh
```

Useful options:

```bash
./scripts/install.sh --version v1.9.1
./scripts/install.sh --type appimage   # Linux default
./scripts/install.sh --type deb
./scripts/install.sh --type rpm
./scripts/install.sh --dir "$HOME/.local/bin"
```

The Linux default is a rootless AppImage at `~/.local/bin/ioruba.AppImage`. macOS installs to `/Applications` when writable and otherwise uses `~/Applications`.

### Windows

Run in PowerShell:

```powershell
irm https://raw.githubusercontent.com/bernardopg/ioruba/main/scripts/install.ps1 | iex
```

The default installer type is MSI. To run the script locally with explicit options:

```powershell
.\scripts\install.ps1 -Version v1.9.1 -Type msi
.\scripts\install.ps1 -Type nsis
```

### Package managers and manual assets

- **Arch Linux:** `yay -S ioruba-desktop` (source) or `yay -S ioruba-desktop-bin` (prebuilt AppImage).
- **Homebrew:** `brew tap bernardopg/ioruba && brew install --cask ioruba`.
- **Scoop:** `scoop bucket add ioruba https://github.com/bernardopg/scoop-ioruba && scoop install ioruba`.
- **Debian/Ubuntu:** download the matching `.deb`, then run `sudo apt install ./Ioruba_*_amd64.deb`.
- **Fedora/RHEL:** download the matching `.rpm`, then run `sudo dnf install ./Ioruba-*.x86_64.rpm`.
- **Other systems:** choose the architecture-specific asset on the [release page](https://github.com/bernardopg/ioruba/releases/latest).

See [Release distribution](docs/guides/release-distribution.md) for signing, updater, package-manifest, and macOS status details.

## First use

1. Install Ioruba or [build it from source](#development-setup).
2. Assemble and flash a controller with the [hardware guide](docs/guides/hardware-setup.md) and [Nano setup](NANO_SETUP.md).
3. Open Ioruba and select the serial port if auto-detection does not choose it.
4. Confirm the firmware handshake appears and the connection status becomes connected.
5. Turn the controls and check the live readings, telemetry, and Watch section.
6. Open **Settings → Profile editor** to choose audio targets or start from a preset.
7. On Linux, use **Refresh audio** / **Atualizar áudio** after starting the applications you want to control.

The current firmware defaults to **115200 baud**, protocol version **2**, and frames such as:

```text
HELLO board=Ioruba Nano; fw=0.6.1; protocol=2; knobs=3; mcu=ATmega328P; adcBits=10; threshold=4; deadzone=7; smooth=75; mins=0,0,0; maxs=1023,1023,1023
512|768|1023
```

The desktop parser also accepts legacy `P1:512` packets and automatically heals profiles that still contain the old 9600-baud default.

### Default profile

| Knob | Label | Target |
| --- | --- | --- |
| 1 | Master Volume | Default output volume |
| 2 | Applications | Spotify, Google Chrome, and Firefox |
| 3 | Microphone | Default microphone source |

## Development setup

### Prerequisites

- Node.js **22** and npm
- Rust stable and Cargo (the crate declares Rust `1.77.2` as its minimum)
- `arduino-cli` for firmware builds
- Linux desktop development libraries required by Tauri
- `pactl` for real Linux audio control

### Clone, validate, and run

```bash
git clone https://github.com/bernardopg/ioruba.git
cd ioruba
npm install

npm run verify
npm run firmware:compile
npm run desktop:watch
```

Use `npm run desktop:dev` for browser-only Vite UI work. Use `npm run desktop:watch` for the full Tauri shell with serial, persistence, updater, tray, and audio integrations.

### Common commands

| Command | Purpose |
| --- | --- |
| `npm run verify` | Typecheck shared/desktop code, run shared/desktop/Rust tests, and build the frontend. |
| `npm run ci` | Run `verify` and compile the default Nano firmware. |
| `npm run desktop:dev` | Start the Vite frontend on port 1420. |
| `npm run desktop:watch` | Start the full Tauri development app. |
| `npm run desktop:tauri:build` | Build the local Tauri binary without installers. |
| `npm run firmware:compile` | Compile the default Nano firmware. |
| `npm run firmware:compile:matrix` | Compile all supported AVR targets. |
| `npm run release:check` | Run the extended local release gate, including audit, firmware matrix, scripts, packaging, secret scans, and docs generation. |
| `npm run docs:prepare-site` | Build the generated GitHub Pages source in `.site-src/`. |

See [Testing](TESTING.md) for the complete CI and manual validation matrix.

## Data and recovery

The app stores:

- `ioruba-state.json` — profiles and persisted app settings;
- `ioruba-watch.log` — structured watch events, automatically trimmed to about 1 MiB;
- `ioruba-state.backup.*.json` — a backup created when incompatible/corrupt persisted state must be replaced.

| OS | Config directory |
| --- | --- |
| Linux | `~/.config/io.ioruba.desktop/` |
| macOS | `~/Library/Application Support/io.ioruba.desktop/` |
| Windows | `%APPDATA%\io.ioruba.desktop\` |

Deleting `ioruba-state.json` resets the app to safe defaults. Back up the directory first if you want to preserve custom profiles. See the [support playbook](docs/debug/support.md) for recovery steps.

## Repository map

| Path | Purpose |
| --- | --- |
| `apps/desktop` | React 19 frontend and Tauri 2 desktop shell. |
| `packages/shared` | Shared domain model, protocol, validation, presets, and runtime math. |
| `firmware/arduino/ioruba-controller` | Parametric Arduino firmware and host-side parser tests. |
| `docs` | Canonical guides, troubleshooting, roadmap, plans, and translations. |
| `docs-site` | GitHub Pages layouts, navigation, and styles. Content is generated from canonical Markdown. |
| `scripts` | Installer, packaging, AppImage, and docs-generation tooling. |
| `.github/workflows` | CI, security scanning, Pages, CodeQL, and release automation. |

## Documentation

| Document | Use it for |
| --- | --- |
| [Documentation index](docs/index.md) | Finding the right guide by task. |
| [Quick start](QUICKSTART.md) | Going from a clone or installation to a working session. |
| [Hardware setup](docs/guides/hardware-setup.md) | Wiring boards, knobs, buttons, and encoders. |
| [Nano setup](NANO_SETUP.md) | Compiling, flashing, and validating the reference Nano build. |
| [Profile examples](docs/guides/profile-examples.md) | Current profile JSON and target-matching behavior. |
| [Support playbook](docs/debug/support.md) | Serial, audio, state, update, and tray troubleshooting. |
| [Testing](TESTING.md) | Automated checks and release validation. |
| [Audio backend contract](docs/guides/audio-backend-contract.md) | Rust ↔ TypeScript command and serialization contract. |
| [Release distribution](docs/guides/release-distribution.md) | Signing, updater, package managers, and release operations. |
| [Contributing](CONTRIBUTING.md) | Development workflow and pull-request expectations. |
| [Product roadmap](docs/roadmap.md) | Product direction; [TODO.md](TODO.md) tracks executable work. |
| [Changelog](CHANGELOG.md) | Complete release history. |
| [PT-BR documentation](docs/translations/pt-br/README.md) | Portuguese documentation and translation coverage. |

## Contributing and support

Contributions to code, hardware support, documentation, and translations are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and run the checks appropriate to your change before opening a pull request.

For troubleshooting, use [docs/debug/support.md](docs/debug/support.md). For project support options, see [FUNDING.md](FUNDING.md).

## License

MIT © Bernardo Gomes. See [LICENSE](LICENSE).

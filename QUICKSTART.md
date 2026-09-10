# Quick Start

Use this guide to get from installation or a fresh clone to a working Ioruba session. The reference hardware is an Arduino Nano with three potentiometers; the desktop app also supports other boards documented in the [hardware guide](docs/guides/hardware-setup.md).

> Linux has full audio-target support through `pactl`. Windows and macOS support the default output (`master`) only. Serial input, profiles, demo mode, telemetry, and diagnostics are cross-platform.

## 1. Choose installation or development

### Install a release

Linux or macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/bernardopg/ioruba/main/scripts/install.sh | sh
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/bernardopg/ioruba/main/scripts/install.ps1 | iex
```

The installers choose the matching OS/architecture asset and require an exact match in `SHA256SUMS.txt`; they refuse an unverified installation. Package-manager and manual options are in the [README installation section](README.md#install).

### Build from source

You need:

- Node.js 22 and npm;
- Rust stable and Cargo;
- `arduino-cli` if you will compile or flash firmware;
- Tauri's platform development dependencies;
- `pactl` on Linux for real audio control.

Clone and install dependencies:

```bash
git clone https://github.com/bernardopg/ioruba.git
cd ioruba
npm install
```

Validate the software stack:

```bash
npm run verify
```

Launch the full desktop app:

```bash
npm run desktop:watch
```

Use `npm run desktop:dev` only for browser-based frontend work; it does not provide native serial, persistence, tray, updater, or audio integrations.

## 2. Assemble the reference controller

Reference parts:

- Arduino Nano ATmega328P;
- three 10k linear potentiometers;
- USB data cable;
- jumper wires and a breadboard or enclosure.

Reference wiring:

| Knob | Outer pin | Center pin | Other outer pin |
| --- | --- | --- | --- |
| 1 | `GND` | `A0` | `5V` |
| 2 | `GND` | `A1` | `5V` |
| 3 | `GND` | `A2` | `5V` |

If rotation feels inverted, swap the two outer pins. Read [Hardware setup](docs/guides/hardware-setup.md) before wiring another board or adding buttons/encoders.

## 3. Compile and flash the firmware

Detect the board and port:

```bash
arduino-cli board list
```

Compile the default Nano firmware:

```bash
npm run firmware:compile
```

Upload to a standard Nano:

```bash
arduino-cli upload \
  -p /dev/ttyUSB0 \
  --fqbn arduino:avr:nano \
  firmware/arduino/ioruba-controller
```

For common clones with the old bootloader:

```bash
arduino-cli upload \
  -p /dev/ttyUSB0 \
  --fqbn arduino:avr:nano:cpu=atmega328old \
  firmware/arduino/ioruba-controller
```

Replace `/dev/ttyUSB0` with the port reported on your system. See [Nano setup](NANO_SETUP.md) for upload failures and serial validation.

## 4. Prepare Linux serial access

If the app reports permission denied, add your user to the group used by your distribution:

```bash
sudo usermod -a -G dialout "$USER"
sudo usermod -a -G uucp "$USER"
```

Not every distribution uses both groups. Log out and back in after changing membership.

## 5. Connect Ioruba

Open the app and confirm:

1. the serial port is auto-detected or selected manually;
2. connection health progresses to **connected**;
3. the firmware handshake reports board, firmware, protocol, knob count, MCU, and ADC bits;
4. the **Watch** section receives frames such as `512|768|1023`;
5. turning a knob changes the live control and telemetry displays;
6. the Hardware section reports protocol 2 as compatible;
7. the active profile survives an app restart.

The current firmware uses **115200 baud** and emits:

```text
HELLO board=Ioruba Nano; fw=0.6.1; protocol=2; knobs=3; mcu=ATmega328P; adcBits=10; threshold=4; deadzone=7; smooth=75; mins=0,0,0; maxs=1023,1023,1023
512|768|1023
```

The app accepts the legacy `P1:512` format and migrates profiles that still use the old 9600-baud default.

## 6. Configure audio targets

The default profile maps:

| Knob | Target |
| --- | --- |
| 1 | Default output / master volume |
| 2 | Spotify, Google Chrome, and Firefox |
| 3 | Default microphone source |

Open **Settings → Profile editor** to choose a preset, edit sliders and controls visually, or use advanced JSON. Profiles can be imported, exported, duplicated, and reset.

On Linux:

```bash
pactl info
pactl list short sink-inputs
pactl list short sinks
pactl list short sources
```

Start playback in target applications, then select **Refresh audio** / **Atualizar áudio**. Application streams only appear while active. For durable device mappings, prefer `default_output` and `default_microphone`.

See [Profile examples and target matching](docs/guides/profile-examples.md).

## 7. Use calibration, telemetry, and controls

- **Calibration:** open Hardware and run the per-knob calibration wizard. The profile stores `minRaw`/`maxRaw`, and the serial runtime sends the matching `CONFIG` command to firmware.
- **Telemetry:** inspect the live chart and whole-session min/average/max values. Export session statistics as JSON or CSV.
- **Watch log:** filter runtime events and export them as JSON Lines or text.
- **Buttons/encoders:** enable them at firmware compile time and bind `mute`, `next`, or `prev` in the visual profile editor.
- **Demo mode:** validate UI behavior without changing system audio.

## 8. Desktop behavior

Closing the main window hides Ioruba instead of exiting. Use the tray action or **Ctrl+Alt+I** to restore it; choose **Quit** / **Sair** from the tray to end the process.

- KDE Plasma supports the tray natively.
- GNOME requires the AppIndicator/KStatusNotifierItem extension.
- Environments without a tray host can still use **Ctrl+Alt+I**.

Launch-on-login and update preferences are available in app settings. Signed in-app updates are offered by installed native builds when a newer release is available.

## 9. Data and reset

Ioruba stores state and logs in:

| OS | Directory |
| --- | --- |
| Linux | `~/.config/io.ioruba.desktop/` |
| macOS | `~/Library/Application Support/io.ioruba.desktop/` |
| Windows | `%APPDATA%\io.ioruba.desktop\` |

Important files:

- `ioruba-state.json` — profiles and app settings;
- `ioruba-watch.log` — persistent, size-limited watch events.

Back up the directory before recovery work. If the state is corrupt, close Ioruba and remove only `ioruba-state.json`; safe defaults are recreated at next launch.

## 10. Common problems

### No serial frames

- Confirm the current sketch is flashed.
- Confirm **115200 baud** in the profile and serial monitor.
- Use a USB data cable.
- Check `A0`, `A1`, and `A2` wiring for the reference build.
- Make sure no serial monitor is holding the port: `fuser -v /dev/ttyUSB0`.
- Try the Nano old-bootloader upload profile if flashing fails.

### Linux audio does not move

- Confirm `pactl info` succeeds.
- Keep application targets actively playing audio.
- Refresh the audio inventory.
- Check names with `pactl list short sink-inputs`.
- Inspect the latest per-target outcome and Watch entries.

### Tauri does not compile on Linux

Install the [current Tauri Linux prerequisites](https://v2.tauri.app/start/prerequisites/). On Arch Linux, the project commonly needs:

```bash
sudo pacman -S --needed \
  webkit2gtk-4.1 \
  gtk3 \
  librsvg \
  appmenu-gtk-module \
  libappindicator-gtk3 \
  xdotool
```

### AppImage bundling fails on recent Arch Linux

New Arch libraries can expose a `linuxdeploy`/`strip` incompatibility around `.relr.dyn`. Use the release binary for a local behavior smoke test, or build the public AppImage in CI/Ubuntu 22.04. Release CI validates extraction and launch with `scripts/validate-appimage.sh --require-launch`.

When copying a freshly built AppImage over a previous local install (e.g. `~/.local/bin/ioruba.AppImage`) for a smoke test, use `scripts/dev-deploy-appimage.sh <built.AppImage>` instead of a plain `cp`. A plain `cp` truncates the destination file in place; if an old instance is still running from it (FUSE-mounted under `/tmp/.mount_ioruba*`), the rewrite happens under its mmap'd pages and crashes it with `SIGBUS`/`SIGABRT` (this is exactly what produced the `ioruba-desktop`/`WebKitWebProcess` crash burst around the 1.9.0 release). The script copies to a temp file and renames atomically, so any already-running instance keeps reading its old, intact mapping until it is closed and relaunched.

### Windows or macOS application targets do not work

This is an explicit current limitation. Those platforms support default-output `master` volume only; application/source/sink targets return unsupported outcomes rather than pretending to apply.

## 11. Validate a downloaded release

Download the asset and `SHA256SUMS.txt` into one directory, then run:

```bash
sha256sum --check SHA256SUMS.txt --ignore-missing
```

GitHub provenance can also be verified:

```bash
gh attestation verify <downloaded-asset> --repo bernardopg/ioruba
```

Signed updater artifacts (`.sig` and `latest.json`) are verified by Tauri before an in-app installation.

## Next reads

- [README](README.md) — product, installation, architecture, and repository map
- [Hardware setup](docs/guides/hardware-setup.md) — boards, pin maps, buttons, and encoders
- [Nano setup](NANO_SETUP.md) — reference firmware flashing
- [Profile examples](docs/guides/profile-examples.md) — current JSON schema and target rules
- [Support playbook](docs/debug/support.md) — deeper troubleshooting and recovery
- [Testing](TESTING.md) — automated and manual validation matrix

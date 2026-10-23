[English](README.md) · [简体中文](README.zh-CN.md)

<p align="center">
  <img src="Resources/app_icon.png" width="128" height="128" alt="CellDock icon">
</p>

<h1 align="center">CellDock</h1>

<p align="center">
  Use cellular network, SMS, and calls on your Mac.
</p>

<p align="center">
  <sub>Screenshots · click to view full size</sub>
</p>

| SMS | Calls |
| :---: | :---: |
| <a href="screenshot/1. sms.png"><img src="screenshot/1. sms.png" width="320" alt="SMS"></a> | <a href="screenshot/2. call.png"><img src="screenshot/2. call.png" width="320" alt="Calls"></a> |

| In-Call | In-Call |
| :---: | :---: |
| <a href="screenshot/2.1 calling.png"><img src="screenshot/2.1 calling.png" width="320" alt="In-Call"></a> | <a href="screenshot/2.2 calling.png"><img src="screenshot/2.2 calling.png" width="320" alt="In-Call"></a> |

| Recordings | Proxy |
| :---: | :---: |
| <a href="screenshot/3.records.png"><img src="screenshot/3.records.png" width="320" alt="Recordings"></a> | <a href="screenshot/4. proxy.png"><img src="screenshot/4. proxy.png" width="320" alt="Proxy"></a> |

| Device | Settings |
| :---: | :---: |
| <a href="screenshot/5. device.png"><img src="screenshot/5. device.png" width="320" alt="Device"></a> | <a href="screenshot/6. settings.png"><img src="screenshot/6. settings.png" width="320" alt="Settings"></a> |

CellDock is a native macOS menu bar app that works with the QDC507 cellular module.
Plug in the module and you can use the cellular network directly on your Mac — send and
receive SMS, manage contacts, make calls, save call recordings, or share a module's
cellular connection as a SOCKS5 proxy — no browser-based service or extra communication
software required.

## Project status

The checked-in version metadata currently reads **0.6.0 (96)**. CellDock targets macOS 14
or later. The app build currently targets Apple Silicon; its bundled VoWiFi runtime is
Universal 2 (`arm64` and `x86_64`). Device features depend on modem firmware, SIM/eSIM,
carrier provisioning, and local network conditions, so support for one setup does not
guarantee the same behavior on another.

This repository currently publishes source code; no signed binary is attached to GitHub
Releases. Community archives built with the instructions below are not notarized.

## Features

### Multi-Module & Cellular Network

- Discovers and monitors multiple supported USB cellular modules at the same time.
- Choose a separate module for calls and for data; only one module serves as the system's
  cellular-first egress at a time.
- Set each module to **Cellular First**, **Keep Connected**, or **Off**. Modules kept
  connected remain usable by bound SOCKS5 proxies but are not used as macOS's default
  network egress.
- Enabling automatically gives cellular priority over Wi-Fi.
- Disabling restores the previous network order without affecting SMS or incoming calls.
- Each module remembers its cellular switch state; reconnecting a module restores its
  previous choice.
- Bounded automatic recovery when the ECM link, DHCP, or module restart misbehaves.
- Live display of carrier, network mode, signal strength, IP address, and connection stage.
- Optional real-time download/upload speeds in the menu bar (fixed width, two lines),
  off by default.

### SOCKS5 Proxy

- Create a separate SOCKS5 proxy per module so apps or LAN devices can select a specific
  cellular egress.
- Listen on localhost only or on the LAN; ports are auto-assigned from `1080` and can be
  changed.
- Supports no-auth and username/password authentication; LAN listeners require authentication.
- Each proxy starts and stops independently and reports connection count and status such as
  module offline, cellular off, link down, or port in use.
- Proxies bind to a stable module identity and re-resolve the network interface after the
  module is reinserted. Auth passwords are stored in the macOS Keychain.

> A LAN proxy exposes the cellular egress to other devices on the same network. Use a
> strong password and make sure your firewall and network are trustworthy.

### SMS

- Receive SMS in the background with macOS notifications.
- View full threads by conversation; copy text, reply, or compose new messages.
- Send Chinese text and long (concatenated) messages.
- Auto-detects verification codes; click to copy and mark as read.
- Messages are tagged with their source module; choose which available module sends each
  message.
- Deleted messages no longer appear in CellDock; if a message is still stored on the module,
  CellDock also tries to clear it.
- Optionally auto-delete verification-code messages 30 minutes after they are read.

### Calls & Recording

- Dial, answer, reject, mute, and hang up.
- Incoming calls show a notification and floating window with Answer and Decline buttons.
- In-call keypad for navigating automated phone menus.
- Use your Mac's microphone and speakers for calls.
- Keeps recent and missed calls, noting which module was used.
- Manual and user-confirmed automatic recording captures both parties and saves as M4A.
- The recording library offers waveforms, playback, seeking, speed control, volume, rename,
  export, and Reveal in Finder.

> Before recording a call, get consent from all participants and follow local laws.

### SIM, eSIM & Contacts

- View SIM status, ICCID, IMSI, own number, carrier, network mode, and signal information.
- Configure per module whether it accepts incoming calls; operations that require a module
  restart are clearly flagged.
- Auto-detects physical SIM and eUICC.
- On supported eUICCs, view the EID and profiles; download, enable, disable, rename, or
  delete eSIM profiles.
- Reads the macOS Contacts database to match names on SMS and calls.
- Create, edit, delete contacts and manage contact groups in CellDock.

### Menu Bar, Sound & Interface

- Hot-plug modules without restarting the app.
- The menu bar icon shows calls, missed calls, unread SMS, the current data module, or
  callable-module status.
- The menu bar panel lists unread SMS and missed calls per module and automatically hides
  empty sections.
- Customizable SMS sound and ringtone; defaults are `bleeps.wav` and `ring.mp3`.
- Simplified Chinese, English, 日本語, and Français, switchable instantly in Settings.
- Follows system, light, and dark themes.
- Presentation privacy mode hides contacts, numbers, message bodies, verification codes,
  and recording titles.
- Open a standard main window; closing it keeps the app running in the menu bar.
- Optionally hide the menu bar icon when no module is connected.
- Optionally launch at login, off by default.

## Compatibility and limitations

- Requires macOS 14 or later. The packaged app is built for Apple Silicon.
- Designed around the QDC507 cellular module. Other USB cellular modules may not expose
  the same interfaces or support the same features.
- Voice, SMS, data, physical SIM, and eSIM behavior depends on modem firmware, carrier
  provisioning, SIM/eSIM profile state, and regional network support.
- eSIM operations and modem-side changes can affect service. Review each prompt carefully
  and keep a working alternative connection available.
- A compatible module and active cellular service are required for hardware validation;
  a successful source build does not verify calls, messaging, or carrier behavior.

## Build from source

### Requirements

- macOS 14 or later with Xcode Command Line Tools and Swift 6.0 or later.
- Go 1.26.3 for the bundled VoWiFi runtime (`ThirdParty/vowifi-go/go.mod`). Its Go modules
  are vendored in the repository.
- A certificate-backed code-signing identity to create the community archive. Signing
  certificates and private keys are not included in this repository.

### Build and checks

```sh
git clone https://github.com/Nathanielguo/celldock-for-mac.git
cd celldock-for-mac
scripts/run_tests.sh

CELLDOCK_SIGNING_MODE=community \
CELLDOCK_CODESIGN_IDENTITY="<certificate name from your Keychain>" \
scripts/build_app.sh
```

The build script validates the signed app bundle and writes a ZIP archive under
`outputs/`. The community archive is not notarized, so macOS may show a security warning
when opening it. Build products and Go caches are excluded from Git.

To install the archive produced by the build, extract it and pass the app path to the
installer:

```sh
CELLDOCK_INSTALL_DIR="$(mktemp -d /tmp/celldock-install.XXXXXX)"
ditto -x -k outputs/CellDock-0.6.0-arm64-community-unnotarized.zip "$CELLDOCK_INSTALL_DIR"
CELLDOCK_APP_SOURCE="$CELLDOCK_INSTALL_DIR/CellDock.app" scripts/install_app.sh
```

The installer preserves an existing CellDock app as a timestamped backup. On first launch,
CellDock may request administrator authorization to install its privileged network helper.
The helper changes macOS network configuration for cellular-priority and proxy features.

## Project layout

| Path | Purpose |
| --- | --- |
| `Sources/CellDock` | Native macOS application |
| `Sources/CellDockNetworkHelper` and `Sources/CellDockNetworkIPC` | Privileged network helper and its IPC protocol |
| `Sources/CModemBridge`, `Sources/CUACProbe`, `Sources/CEuiccCore` | USB modem, audio, and eSIM interfaces |
| `ThirdParty/vowifi-go` | VoWiFi runtime source and vendored Go dependencies |
| `Resources` | App metadata, localizations, sounds, icons, and module voice payload sources |
| `Tests` and `scripts/run_tests.sh` | Local self-tests and validation helpers |
| `docs` | Security notes, module report, and third-party license notices |

## Reporting issues

When opening an issue, include the macOS version, module model and firmware, carrier, and
the steps needed to reproduce the problem. Remove personal data before sharing logs,
including phone numbers, IMEI/ICCID/IMSI values, message contents, APDU data, and account
or network credentials. Never attach signing certificates or private keys.

## Acknowledgments

Special thanks to the [moluncn/mavo](https://github.com/moluncn/mavo) project. CellDock
draws on mavo for its interface and feature design; we are grateful for the original
author's open-source work.

## Disclaimer

- CellDock is provided "as is", without any express or implied warranty. The author makes
  no guarantees about its suitability or performance for any particular purpose.
- The app modifies macOS network configuration (for example, making cellular the priority
  egress and installing a network helper), which may affect existing network connections.
  Make sure you understand these features before use.
- The availability of cellular data, SMS, calls, and eSIM features depends on module
  firmware, SIM card, carrier, and local network conditions. The author does not guarantee
  their availability or performance in every environment.
- Sharing a cellular connection to LAN devices through the SOCKS5 proxy exposes that egress
  to other devices on the same network. Assess the security risks yourself and configure
  authentication properly.
- Get consent from call participants before recording and follow local laws; also follow
  your carrier's terms of service when using features such as connection sharing.
- The author is not liable for any direct or indirect loss caused by using or being unable
  to use this software.

## License

CellDock's application code is licensed under a [non-commercial license](LICENSE): free to
use, modify, and distribute for personal and non-commercial purposes. **Any form of
commercial use is prohibited**; commercial use requires separate written authorization from
the author. Third-party components and their licenses are listed in
[THIRD_PARTY_NOTICES.md](docs/THIRD_PARTY_NOTICES.md).

# Third-party notices

The macOS application and its user-space PCM bridge were written independently.
The following projects were consulted for protocol behavior and test strategy;
their source code is not copied into those components:

- asterisk-chan-quectel, GPL-2.0 (protocol behavior only; no source vendored):
  <https://github.com/IchthysMaranatha/asterisk-chan-quectel>
- Quectel EC2x/EG9x Voice over USB and UAC application note:
  <https://auroraevernet.ru/upload/iblock/f57/xkjhy4olve0k1n8e0z43hq4nk5h604d2.pdf>
- warthog618/sms, MIT:
  <https://github.com/warthog618/sms>
- WWANManager, MIT:
  <https://github.com/patriczeq/WWANManager>
- Blue Robotics Cellphone Modem Manager, MIT:
  <https://github.com/bluerobotics/cellphone-modem-manager>

The eSIM implementation links the `euicc/` library from lpac v2.3.0,
commit `c2fcf5e`, under LGPL-2.1-only. CellDock provides its own modem AT/APDU
and HTTPS adapters and does not compile lpac's AGPL command-line application,
drivers, or utilities:

- lpac/libeuicc, LGPL-2.1-only OR commercial:
  <https://github.com/estkme-group/lpac/tree/v2.3.0/euicc>
- cJSON as bundled by lpac, MIT:
  <https://github.com/estkme-group/lpac/tree/v2.3.0/cjson>

Their complete corresponding source and license texts are present under
`Sources/CEuiccCore/Vendor/lpac`. Distributors of statically linked builds must
also satisfy LGPL-2.1 section 6 relinking requirements, or obtain lpac's
commercial license.

The optional QDC507 voice runtime bundles two loadable Linux kernel modules
derived from `the-modem-distro/quectel_eg25_kernel`, commit
`82ed00908b3e8efc3ff0de27d2b5a7c0524ecd7f`, under GPL-2.0:

- <https://github.com/the-modem-distro/quectel_eg25_kernel>

The release archive includes the GPL-2.0 license beside `CellDock.app`. The runtime
binaries are stored in the code-signed `Resources/ModuleVoice.payload` package.
This notice and the module build report remain in the source distribution
rather than the app bundle.

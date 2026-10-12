# Brightness

**Set the screen brightness with one big slider and four presets – and it stays set.**

On iOS 6 the brightness slider is buried in Settings, and changing `UIScreen.brightness` from an app gets undone by SpringBoard the next time you unlock. This app also writes the value to SpringBoard's own preference and tells it to reload, so the setting survives locking.

## What it can do

- One large slider and presets for 10, 30, 60 and 100 %.
- A sun icon that grows with the brightness.
- That's it – one screen, opens instantly.

## Runs on

iOS 6.1.6 · jailbroken iPod touch 4

## Install

Easiest via the **[Reboot App Store](https://github.com/SecondTrack/reboot)** right on the iPod. By hand: `.deb` from the [latest release](https://github.com/SecondTrack/helligkeit/releases/latest), `dpkg -i`, then `uicache`.

Build it yourself with [Theos](https://theos.dev): `make package` (iOS 6.0+, armv7).

## License

GPL-3.0 – see [LICENSE](LICENSE).
Not affiliated with Apple. iPod is a trademark of Apple Inc.

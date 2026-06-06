# PipeWire Migration

As of **v26.05.18** the Kiro Next live ISO uses PipeWire instead of PulseAudio for audio.

## What changed

**Removed:**
- `pulseaudio`
- `pulseaudio-alsa`
- `pulseaudio-bluetooth`

**Added:**
- `pipewire` — core daemon
- `pipewire-alsa` — ALSA compatibility layer
- `pipewire-audio` — audio session support
- `pipewire-pulse` — PulseAudio drop-in replacement (same socket, same clients)
- `wireplumber` — session/policy manager
- `pamixer` — CLI volume control (replaces `amixer` in ohmychadwm keybindings)
- `gst-plugin-pipewire` — GStreamer integration

## What this means for you

- All PulseAudio clients (pavucontrol, browsers, games) work unchanged via `pipewire-pulse`.
- Bluetooth audio works without `pulseaudio-bluetooth` — PipeWire handles it natively.
- Lower latency and better pro-audio support are available if you use JACK-aware software.
- `pavucontrol` is still included and works as the GUI mixer.
- Volume keys in ohmychadwm now call `pamixer` instead of `amixer` — this is intentional and required for PipeWire.

## Installed system

Calamares does not change the audio stack during install — what ships in the ISO is what you get. The `audit.sh` health checker verifies the PipeWire stack is complete and PulseAudio is absent.

## Rollback

If you need PulseAudio for a specific reason:

```bash
sudo pacman -R pipewire-pulse wireplumber pipewire-audio pipewire-alsa pipewire
sudo pacman -S pulseaudio pulseaudio-alsa pulseaudio-bluetooth
```

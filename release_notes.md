### Media Player Pro v1.3

Modern, high-performance media player based on [mpv](https://github.com/mpv-player/mpv).

#### What's New in v1.3:
- **TrueTheater GPU Video Enhancement Engine**:
  - **Single-Pass Master GLSL Shader** (`truetheater_enhance.glsl`): Real-time Contrast Adaptive Sharpening (CAS), Adaptive Local Tone Mapping (shadow lift & S-curve contrast without crushing blacks or clipping whites), and Skin-Tone Protected Vibrance (+4% non-skin boost while preserving natural skin tones).
  - **Single-Click ON/OFF Setting**: Simplified Settings menu with a single `✦ Video Enhancement: ON/OFF` toggle, persistent across restarts (`~/.config/media-player-pro/config.json`).
  - **HQ Scaling & Deband Pipeline**: Automatically engages `ewa_lanczossharp` chroma/luma scaling and deband filtering when active, reverting to lightweight defaults when off.
  - **Keyboard Shortcuts**: `Ctrl+E` to toggle enhancement on the fly with OSD feedback; `Ctrl+Shift+E` for split-screen 50% A/B before/after diagnostic comparison mode.
- **Interactive Button Hover Tooltips**: Floating frosted-glass tooltips appear above dock controls on mouse hover (Seek -7s, Play/Pause, Seek +7s, Playback Speed, Mute / Volume, and Settings).
- **Interactive Aspect Ratio Submenu**: Displays the currently active aspect ratio in Settings (e.g., `Auto`, `16:9`, `4:3`, `21:9`, `16:10`, `1:1`) and provides an interactive sub-selector to choose any ratio instantly.
- **Streamlined Control Bar**: Removed minimize/maximize window controls to provide a cleaner, distraction-free transparent playback dock.

#### Included Packages:
- **AppImage**: `Media_Player_Pro-1.3-x86_64.AppImage` (Universal portable bundle)
- **Debian / Ubuntu**: `media-player-pro_1.3_amd64.deb`
- **Fedora / RHEL**: `media-player-pro-1.3-1.x86_64.rpm`
- **Flatpak**: `media-player-pro-1.3.flatpak.tar.gz` (and Flatpak bundle manifest)

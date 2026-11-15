### Media Player Pro v1.4

Modern, high-performance media player based on [mpv](https://github.com/mpv-player/mpv).

#### What's New in v1.4:
- **Content-Focused & High-Contrast Settings Menu**:
  - Redesigned with a **100% solid deep obsidian backing** (`#080709`) to completely eliminate video background bleed-through and guarantee maximum legibility.
  - Replaced all small and dark-on-dark text with **solid pure white** (`#FFFFFF`) and bright silver (`#E8E8E8`) typography at `15px bold`.
  - High-visibility status badge pills with active vibrant red indicators (`[ ON ]`, active ratio) and crisp silver borders for inactive controls.
  - Prioritized content-first playback controls at the top: Video Enhancement, Aspect Ratio, Flip Horizontal, Rotate 90°, Audio Track, Subtitles, Video Statistics, Open File, and Version Info.
  - Expanded interactive click hitboxes for effortless mouse navigation.
- **Fixed Video Enhancement Toggle**:
  - Resolved mpv multi-script environment isolation by implementing explicit cross-script IPC messaging (`toggle_enhancement`, `set_enhancement`).
  - Added robust absolute shader path resolution across local and system installation directories (`truetheater_enhance.glsl`, `flip_horizontal.glsl`).
  - Video enhancement toggles reliably via mouse click in the Settings menu as well as `Ctrl+E`.
- **Keyboard Shortcuts for Video Transformations**:
  - `Ctrl+1`: Flip video horizontally (mirror view) with instant OSD feedback.
  - `Ctrl+2`: Rotate video by 90° clockwise (0° → 90° → 180° → 270°) with instant OSD feedback.

#### Included Packages:
- **AppImage**: `Media_Player_Pro-1.4-x86_64.AppImage` (Universal portable bundle)
- **Debian / Ubuntu**: `media-player-pro_1.4_amd64.deb`
- **Fedora / RHEL**: `media-player-pro-1.4-1.x86_64.rpm`
- **Flatpak**: `media-player-pro-1.4.flatpak.tar.gz` (and Flatpak bundle manifest)

### Media Player Pro v1.6

Modern, high-performance media player based on [mpv](https://github.com/mpv-player/mpv).

#### What's New in v1.6:
- **Double-Click Fullscreen Strictly Above Seek Bar**:
  - Double-clicking within the video viewport above the seek bar seamlessly toggles fullscreen on and off.
  - Double-clicking is suppressed on the seek bar, time display, and all lower dock controls (`◄◄`, `►►`, play/pause, volume, speed, settings, fullscreen buttons). Users can click seek and playback buttons rapidly and continuously without accidentally triggering fullscreen.
  - Dynamically adapts to window resizing and full-screen state transitions.
  - Double-clicks inside open menus (Settings popover, Speed selector, Resume playback prompt, Idle splash card) are prevented from toggling fullscreen.
- **Direct GitHub Update Button**:
  - Added a dedicated "⤓ Download Latest Update" option under the Settings menu.
  - Directly opens the official GitHub releases page in the user's default browser with full cross-platform fallback support (`xdg-open` / `gio open`).
- **Includes All v1.5 Capabilities**:
  - Dedicated frosted-glass Fullscreen button on the dock left of Settings.
  - 5-second precision media skipping (`◄◄ 5s` / `5s ►►`).
  - TrueTheater GPU Video Enhancement (AMD CAS sharpening + local tone mapping).

#### Included Packages:
- **AppImage**: `Media_Player_Pro-1.6-x86_64.AppImage` (Universal portable bundle)
- **Debian / Ubuntu**: `media-player-pro_1.6_amd64.deb`
- **Fedora / RHEL**: `media-player-pro-1.6-1.x86_64.rpm`
- **Flatpak**: `media-player-pro-1.6.flatpak.tar.gz` (and Flatpak bundle manifest)

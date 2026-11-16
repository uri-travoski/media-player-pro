### Media Player Pro v1.8

Modern, high-performance media player based on [mpv](https://github.com/mpv-player/mpv).

#### What's New in v1.8:
- **Native Cross-Desktop File Chooser (Wayland & X11)**:
  - Replaced legacy/inconsistent dialog scripts with a high-reliability native open/pick file dialog architecture supporting both Wayland and X11 across all major Linux distributions.
  - **KDE Plasma**: Automatically detects KDE/Plasma sessions and opens the native Qt / Dolphin file picker (`kdialog`).
  - **GNOME, Cinnamon, MATE, XFCE, Sway, Hyprland**: Automatically defaults to native `zenity` and XDG Desktop Portal integration.
  - **Comprehensive Media Filter**: Pre-filters for all major video and audio formats (`.mp4`, `.mkv`, `.avi`, `.mov`, `.webm`, `.flv`, `.wmv`, `.m4v`, `.ts`, `.mp3`, `.flac`, `.wav`, `.ogg`, `.m4a`, `.opus`, etc.).
  - **Smart Start Directory**: Automatically opens in the active media directory, standard `$HOME/Videos`, or `$HOME`.
  - **Graceful Fallback & Cancel Handling**: Includes multi-tier cascade (`zenity` $\rightarrow$ `kdialog` $\rightarrow$ `yad` $\rightarrow$ Python) with strict cancellation guards to avoid redundant popups.
- **Includes All Previous Capabilities**:
  - Matched remaining and played elapsed time text styles (pure white bold with drop shadow).
  - Double-click to toggle fullscreen strictly in the video canvas above the seekbar.
  - Streamlined frosted-glass playback dock with 5-second precision skip controls.
  - TrueTheater GPU Video Enhancement Engine.

#### Included Packages:
- **AppImage**: `Media_Player_Pro-1.8-x86_64.AppImage` (Universal portable bundle)
- **Debian / Ubuntu**: `media-player-pro_1.8_amd64.deb`
- **Fedora / RHEL**: `media-player-pro-1.8-1.x86_64.rpm`
- **Flatpak**: `media-player-pro-1.8.flatpak.tar.gz` (and Flatpak bundle manifest)

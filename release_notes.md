### Media Player Pro v1.5

Modern, high-performance media player based on [mpv](https://github.com/mpv-player/mpv).

#### What's New in v1.5:
- **Dedicated Fullscreen Toggle Button**:
  - Added a dedicated frosted-glass Fullscreen button directly on the playback dock to the left of the Settings button.
  - Automatically switches between dynamic enter-fullscreen and exit-fullscreen vector icons based on window state, with hover tooltips and keyboard hint (`f` / `ESC`).
- **Eliminated Accidental Fullscreen Toggles**:
  - Disabled `MBTN_LEFT_DBL` from triggering fullscreen across the dock controls, seek buttons, and menus.
  - Users can now click seek buttons or UI controls rapidly and continuously without accidentally toggling fullscreen.
- **5-Second Precision Media Navigation**:
  - Updated media skip controls from 7 seconds to **5 seconds** (`seek -5` / `seek 5`).
  - Synchronized left and right keyboard arrow keys, dock skip buttons (`◄◄` and `►►`), and hover tooltips to 5-second increments.

#### Included Packages:
- **AppImage**: `Media_Player_Pro-1.5-x86_64.AppImage` (Universal portable bundle)
- **Debian / Ubuntu**: `media-player-pro_1.5_amd64.deb`
- **Fedora / RHEL**: `media-player-pro-1.5-1.x86_64.rpm`
- **Flatpak**: `media-player-pro-1.5.flatpak.tar.gz` (and Flatpak bundle manifest)

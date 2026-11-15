### Media Player Pro v1.2

Modern, high-performance media player based on [mpv](https://github.com/mpv-player/mpv).

#### What's New in v1.2:
- **Smart Resume Memory**: Automatically tracks the last 20 unfinished videos. Opening an unfinished video displays an interactive frosted glass prompt offering `[ ▶ Resume at MM:SS ]` or `[ ↺ Start from Beginning ]`.
- **Vibrant Red Theme**: Replaced orange/amber with a sleek red-based color palette, glowing red seekbar line, volume slider, and scrubber thumb.
- **100% Transparent Bottom Bar**: Eliminated the background dock pill and backdrop rectangles so video playback remains completely visible and unobstructed right to the bottom edge.
- **Clean Media Skip Icons**: Replaced the circular arrows with dedicated double-triangle media skip glyphs (`◄◄` / `►►`), removing the text `"7s"` while retaining instant 7-second jumps.
- **New Frosted Glass App Icon**: Frosted glass surround with a vibrant red play button.
- **Full Wayland & X11 Dual Compatibility**: Robust GPU context prioritization (`wayland,x11egl,waylandvk,x11vk`) preventing DRM KMS conflicts across modern Linux compositors.
- **Instant Idle Screen**: Launching with zero arguments opens directly into an elegant idle splash screen with `[ 📂 Open Media File ]`.

#### Included Packages:
- **AppImage**: `Media_Player_Pro-1.2-x86_64.AppImage` (Universal portable bundle)
- **Debian / Ubuntu**: `media-player-pro_1.2_amd64.deb`
- **Fedora / RHEL**: `media-player-pro-1.2-1.x86_64.rpm`
- **Flatpak**: `media-player-pro-1.2.flatpak`

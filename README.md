# Media Player Pro (v1.1)

> **Media Player Pro** is a modern, high-performance Linux media player built on top of [mpv](https://github.com/mpv-player/mpv), featuring a complete frosted glass skin, non-obstructive playback controls, cursor-targeted zoom/pan, and a 3-level genuine video enhancement engine.

---

## ✨ Key Features

- **Frosted Glass Skin HUD**: Sleek, floating frosted glass dock with subtle glowing borders and transparent seek bar, keeping your view of the media completely unobstructed.
- **Precision 7s Navigation**: Quick-access **7-second backward (`-7s`)** and **7-second forward (`+7s`)** buttons on either side of the primary Play/Pause button.
- **Speed Play Dropup**: Instant playback rate switching with `0.25x`, `0.5x`, `1.0x (Normal)`, `1.25x`, `1.5x`, `2.0x`, `2.5x`, and `3.0x` presets.
- **Smooth Volume Slider**: Bottom-right volume track with interactive glowing handle, percentage readout, mute toggle, and mouse wheel volume adjustments.
- **Cursor-Targeted Video Zoom & Pan**:
  - `Ctrl + Mouse Wheel Up`: Smoothly zoom into the exact point where the mouse cursor is located.
  - `Ctrl + Mouse Wheel Down`: Zoom out from cursor position.
  - `Ctrl + Left Click Drag`: Pan the video viewport up, down, left, or right so the zoomed area can be centered.
  - `Ctrl + 0` / Middle Click: Reset zoom and pan back to 100% fit.
- **3 Genuine Video Enhancement Levels**:
  - **Level 1 (Balanced)**: High-quality Deband filter (eliminates compression banding and posterization) + AMD FidelityFX Contrast-Adaptive Sharpening (`cas=0.35`).
  - **Level 2 (High Clarity)**: Deep deband iterations + prominent CAS sharpening (`cas=0.60`) + anti-ringing Lanczos chroma scaling.
  - **Level 3 (Ultra Fidelity)**: Maximum deband threshold + super-resolution CAS sharpening (`cas=0.85`) + high-precision dithering.
  - **Off**: Neutral unadulterated video stream.
- **3-Second Autohide**: Controls and mouse pointer automatically fade out after 3 seconds of inactivity during playback, ensuring an immersion view. Moving the mouse instantly restores the HUD.
- **Window Controls**: Built-in Minimise and Maximise / Fullscreen controls.

---

## ⌨️ Shortcuts Reference

| Action | Mouse / Shortcut |
| :--- | :--- |
| **Play / Pause** | `Space` or Click Center Play Button |
| **Seek -7 Seconds** | `Left Arrow` or Click `↺ 7s` |
| **Seek +7 Seconds** | `Right Arrow` or Click `7s ↻` |
| **Volume Up / Down** | `Mouse Wheel Up / Down` or Volume Slider |
| **Toggle Mute** | `m` or Click Speaker Icon |
| **Zoom at Cursor** | `Ctrl + Mouse Wheel Up / Down` |
| **Pan Zoomed Video** | `Ctrl + Left Click Drag` |
| **Reset Zoom & Pan** | `Ctrl + 0` or `Ctrl + Middle Click` |
| **Cycle Video Enhancement** | `e` or Far-Right Settings Menu (`⚙`) |
| **Toggle Fullscreen** | `f` or Click Maximise Button (`🗖`) |
| **Exit Fullscreen** | `ESC` |

---

## 📦 Installation & Packages

Media Player Pro is distributed in 4 universal packaging formats available from the **[GitHub Releases](https://github.com/uri-travoski/media-player-pro/releases)** page:

### 1. AppImage (Universal Linux)
```bash
chmod +x Media_Player_Pro-1.1-x86_64.AppImage
./Media_Player_Pro-1.1-x86_64.AppImage video.mp4
```

### 2. Debian / Ubuntu (.deb)
```bash
sudo dpkg -i media-player-pro_1.1_amd64.deb
sudo apt-get install -f
```

### 3. Fedora / RHEL (.rpm)
```bash
sudo rpm -ivh media-player-pro-1.1-1.x86_64.rpm
```

### 4. Flatpak Bundle
```bash
flatpak install media-player-pro-1.1.flatpak
flatpak run org.mediaplayerpro.MediaPlayerPro video.mp4
```

---

## 🔨 Building from Source

```bash
git clone https://github.com/uri-travoski/media-player-pro.git
cd media-player-pro
make
sudo make install
```

---

## 📄 License

GPL-2.0-or-later. Based on [mpv](https://github.com/mpv-player/mpv).

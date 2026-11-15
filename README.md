# Media Player Pro (v1.5)

> **Media Player Pro** is a modern, high-performance Linux media player built on top of [mpv](https://github.com/mpv-player/mpv), featuring a sleek transparent skin with vibrant red accents, non-obstructive floating playback controls, watch history memory with interactive resume, cursor-targeted zoom/pan, interactive hover tooltips, aspect ratio picker, and a real-time TrueTheater GPU video enhancement engine.

---

## ✨ Key Features

- **100% Transparent Floating HUD**: Non-obstructive floating playback controls and transparent seek bar with glowing red progress line and scrubber thumb, keeping video completely unobstructed right to the bottom edge.
- **Interactive Button Hover Tooltips**: Floating frosted-glass tooltips dynamically display control labels above buttons when hovered (Seek -5s, Play/Pause, Seek +5s, Speed, Mute/Volume, Fullscreen, Settings).
- **TrueTheater GPU Video Enhancement Engine**:
  - **Single-Pass Master GLSL Shader** (`truetheater_enhance.glsl`): Real-time Contrast Adaptive Sharpening (CAS), Adaptive Local Tone Mapping (shadow lift & S-curve contrast without crushing blacks or clipping whites), and Skin-Tone Protected Vibrance.
  - **Single ON/OFF Setting**: One-click toggle in Settings, persistent across restarts (`~/.config/media-player-pro/config.json`).
  - **HQ Scalers & Deband**: Automatically coordinates `ewa_lanczossharp` scaling and debanding on the GPU pipeline.
  - **Split-Screen A/B Diagnostic Mode**: 50% split-screen before/after comparison shader toggleable with `Ctrl+Shift+E`.
- **Interactive Aspect Ratio Selector**: Settings menu displays the active aspect ratio (`Auto`, `16:9`, `4:3`, `21:9`, `16:10`, `1:1`) with an interactive flyout menu to change aspect ratios instantly.
- **Smart Resume Memory**: Automatically tracks the last 20 unfinished videos. Opening an unfinished video displays an interactive frosted glass prompt offering `[ ▶ Resume at MM:SS ]` or `[ ↺ Start from Beginning ]` (or press `Enter` / `Home` / `Esc`).
- **Precision 5s Media Skip Controls**: Dedicated media skip backward (`◄◄`) and forward (`►►`) buttons for instant 5-second jumps.
- **Speed Play Dropup**: Instant playback rate switching with `0.25x`, `0.5x`, `1.0x (Normal)`, `1.25x`, `1.5x`, `2.0x`, `2.5x`, and `3.0x` presets with red accent highlights.
- **Dedicated Fullscreen Toggle**: One-click dock button to toggle fullscreen mode smoothly with dynamic enter/exit vector icons.
- **Smooth Volume Slider**: Bottom-right volume track with interactive glowing red handle, percentage readout, mute toggle, and mouse wheel volume adjustments.
- **Cursor-Targeted Video Zoom & Pan**:
  - `Ctrl + Mouse Wheel Up`: Smoothly zoom into the exact point where the mouse cursor is located.
  - `Ctrl + Mouse Wheel Down`: Zoom out from cursor position.
  - `Ctrl + Left Click Drag`: Pan the video viewport up, down, left, or right so the zoomed area can be centered.
  - `Ctrl + 0` / Middle Click: Reset zoom and pan back to 100% fit.
- **Horizontal Flip & Rotation**:
  - `Ctrl + 1`: Instantly flip / mirror the video horizontally using GPU shader pipeline.
  - `Ctrl + 2`: Rotate video clockwise by 90° (cycles 0° → 90° → 180° → 270°).
- **Instant Idle Screen**: Launching with zero arguments opens directly into an elegant splash screen with an interactive `[ 📂 Open Media File ]` dialog button.
- **Wayland & X11 Dual Compatibility**: Seamless GPU context prioritization (`wayland,x11egl,waylandvk,x11vk`) preventing DRM KMS conflicts across modern Linux compositors.
- **3-Second Autohide**: Controls and mouse pointer automatically fade out after 3 seconds of inactivity during playback, ensuring an immersion view. Moving the mouse instantly restores the HUD.

---

## ⌨️ Shortcuts Reference

| Action | Mouse / Shortcut |
| :--- | :--- |
| **Play / Pause** | `Space` or Click Center Play Button |
| **Seek -7 Seconds** | `Left Arrow` or Click `◄◄` |
| **Seek +7 Seconds** | `Right Arrow` or Click `►►` |
| **Resume Unfinished Video** | Click `[ Resume ]` or Press `Enter` |
| **Restart from Beginning** | Click `[ Start Over ]` or Press `Home` |
| **Dismiss Resume Prompt** | Click `[ ✕ ]` or Press `Esc` |
| **Open File Dialog** | `Ctrl + O` or Click Idle Screen Button |
| **Volume Up / Down** | `Mouse Wheel Up / Down` or Volume Slider |
| **Toggle Mute** | `m` or Click Speaker Icon |
| **Zoom at Cursor** | `Ctrl + Mouse Wheel Up / Down` |
| **Pan Zoomed Video** | `Ctrl + Left Click Drag` |
| **Reset Zoom & Pan** | `Ctrl + 0` or `Ctrl + Middle Click` |
| **Flip Video Horizontally** | `Ctrl + 1` or Settings Menu (`⚙`) |
| **Rotate Video 90°** | `Ctrl + 2` or Settings Menu (`⚙`) |
| **Toggle Video Enhancement** | `Ctrl + E` or Settings Menu (`⚙`) |
| **Split-Screen A/B Diagnostic** | `Ctrl + Shift + E` |
| **Toggle Fullscreen** | Fullscreen Button or `f` |
| **Exit Fullscreen** | Fullscreen Button or `ESC` |

---

## 📦 Installation & Packages

Media Player Pro is distributed in 4 universal packaging formats available from the **[GitHub Releases](https://github.com/uri-travoski/media-player-pro/releases)** page:

### 1. AppImage (Universal Linux)
```bash
chmod +x Media_Player_Pro-1.5-x86_64.AppImage
./Media_Player_Pro-1.5-x86_64.AppImage video.mp4
```

### 2. Debian / Ubuntu (.deb)
```bash
sudo dpkg -i media-player-pro_1.5_amd64.deb
sudo apt-get install -f
```

### 3. Fedora / RHEL (.rpm)
```bash
sudo rpm -ivh media-player-pro-1.5-1.x86_64.rpm
```

### 4. Flatpak Bundle
```bash
flatpak install media-player-pro-1.5.flatpak
# or extract media-player-pro-1.5.flatpak.tar.gz
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

## 🧪 Video Enhancement Verification

To verify that the TrueTheater GPU enhancement engine is functioning correctly and review objective image processing metrics:

```bash
python3 scripts/test_enhancement.py
```

This renders lossless comparison frames and generates:
- `verification_output/comparison_ab.png` (Side-by-side comparison)
- `verification_output/diff_heatmap.png` (Pixel difference heatmap)
- Objective Laplacian variance edge sharpness (+35% CAS boost), dynamic range spread, and skin-tone preservation metrics.

---

## 📄 License

GPL-2.0-or-later. Based on [mpv](https://github.com/mpv-player/mpv).

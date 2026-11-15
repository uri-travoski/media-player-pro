# Media Player Pro (v1.2)

> **Media Player Pro** is a modern, high-performance Linux media player built on top of [mpv](https://github.com/mpv-player/mpv), featuring a sleek transparent skin with vibrant red accents, non-obstructive floating playback controls, watch history memory with interactive resume, cursor-targeted zoom/pan, and a 3-level genuine video enhancement engine.

---

## ✨ Key Features

- **100% Transparent Floating HUD**: Non-obstructive floating playback controls and transparent seek bar with glowing red progress line and scrubber thumb, keeping video completely unobstructed right to the bottom edge.
- **Smart Resume Memory**: Automatically tracks the last 20 unfinished videos. Opening an unfinished video displays an interactive frosted glass prompt offering `[ ▶ Resume at MM:SS ]` or `[ ↺ Start from Beginning ]` (or press `Enter` / `Home` / `Esc`).
- **Precision 7s Media Skip Controls**: Dedicated media skip backward (`◄◄`) and forward (`►►`) buttons for instant 7-second jumps without obstructing text.
- **Speed Play Dropup**: Instant playback rate switching with `0.25x`, `0.5x`, `1.0x (Normal)`, `1.25x`, `1.5x`, `2.0x`, `2.5x`, and `3.0x` presets with red accent highlights.
- **Smooth Volume Slider**: Bottom-right volume track with interactive glowing red handle, percentage readout, mute toggle, and mouse wheel volume adjustments.
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
- **Instant Idle Screen**: Launching with zero arguments opens directly into an elegant splash screen with an interactive `[ 📂 Open Media File ]` dialog button.
- **Wayland & X11 Dual Compatibility**: Seamless GPU context prioritization (`wayland,x11egl,waylandvk,x11vk`) preventing DRM KMS conflicts across modern Linux compositors.
- **3-Second Autohide**: Controls and mouse pointer automatically fade out after 3 seconds of inactivity during playback, ensuring an immersion view. Moving the mouse instantly restores the HUD.
- **Window Controls**: Built-in Minimise and Maximise / Fullscreen controls.

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
| **Cycle Video Enhancement** | `e` or Far-Right Settings Menu (`⚙`) |
| **Toggle Fullscreen** | `f` or Click Maximise Button (`🗖`) |
| **Exit Fullscreen** | `ESC` |

---

## 📦 Installation & Packages

Media Player Pro is distributed in 4 universal packaging formats available from the **[GitHub Releases](https://github.com/uri-travoski/media-player-pro/releases)** page:

### 1. AppImage (Universal Linux)
```bash
chmod +x Media_Player_Pro-1.2-x86_64.AppImage
./Media_Player_Pro-1.2-x86_64.AppImage video.mp4
```

### 2. Debian / Ubuntu (.deb)
```bash
sudo dpkg -i media-player-pro_1.2_amd64.deb
sudo apt-get install -f
```

### 3. Fedora / RHEL (.rpm)
```bash
sudo rpm -ivh media-player-pro-1.2-1.x86_64.rpm
```

### 4. Flatpak Bundle
```bash
flatpak install media-player-pro-1.2.flatpak
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

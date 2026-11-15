Name:           media-player-pro
Version:        1.3
Release:        1%{?dist}
Summary:        Modern Frosted Glass Media Player based on mpv
License:        GPLv2+
URL:            https://github.com/uri-travoski/media-player-pro
Source0:        media-player-pro-%{version}.tar.gz
BuildArch:      x86_64
Requires:       mpv, dejavu-sans-fonts

%description
Media Player Pro is a high-performance media player based on mpv with
a complete transparent/frosted glass skin, 7-second skip buttons,
speed dropup presets, cursor-targeted zoom and dragging, and genuine
video enhancements (deband + AMD FidelityFX Contrast Adaptive Sharpening).

%prep
%setup -q

%build
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
make install PREFIX=/usr DESTDIR=%{buildroot}

%files
%{_bindir}/media-player-pro
%{_datadir}/media-player-pro/
%{_datadir}/applications/media-player-pro.desktop
%{_datadir}/metainfo/media-player-pro.metainfo.xml
%{_datadir}/icons/hicolor/*/apps/media-player-pro.*

%post
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q %{_datadir}/icons/hicolor || true
fi

%changelog
* Sun Nov 15 2026 Uri Travoski <uri-travoski@users.noreply.github.com> - 1.3-1
- TrueTheater GPU video enhancement engine (CAS sharpening, adaptive lighting, skin vibrance)
- Interactive hover tooltips for all controls
- Interactive Aspect Ratio submenu and active ratio display
- Streamlined playback dock and controls cleanup

* Sat Nov 14 2026 Uri Travoski <uri-travoski@users.noreply.github.com> - 1.2-1
- Media Player Pro v1.2 release.

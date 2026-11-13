CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -D_GNU_SOURCE
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
APPNAME = media-player-pro

TARGET = $(APPNAME)
SRCS = src/main.c

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $(SRCS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 $(TARGET) $(DESTDIR)$(BINDIR)/$(APPNAME)
	
	install -d $(DESTDIR)$(DATADIR)/$(APPNAME)/scripts
	install -m 644 scripts/*.lua $(DESTDIR)$(DATADIR)/$(APPNAME)/scripts/
	
	install -d $(DESTDIR)$(DATADIR)/$(APPNAME)/config
	install -m 644 config/*.conf $(DESTDIR)$(DATADIR)/$(APPNAME)/config/
	
	install -d $(DESTDIR)$(DATADIR)/applications
	install -m 644 data/$(APPNAME).desktop $(DESTDIR)$(DATADIR)/applications/
	
	install -d $(DESTDIR)$(DATADIR)/metainfo
	install -m 644 data/$(APPNAME).metainfo.xml $(DESTDIR)$(DATADIR)/metainfo/
	
	install -d $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps
	install -m 644 data/icons/$(APPNAME).svg $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/
	
	for s in 16 32 48 64 128 256 512; do \
		if [ -f data/icons/$${s}x$${s}.png ]; then \
			install -d $(DESTDIR)$(DATADIR)/icons/hicolor/$${s}x$${s}/apps; \
			install -m 644 data/icons/$${s}x$${s}.png $(DESTDIR)$(DATADIR)/icons/hicolor/$${s}x$${s}/apps/$(APPNAME).png; \
		fi \
	done

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(APPNAME)
	rm -rf $(DESTDIR)$(DATADIR)/$(APPNAME)
	rm -f $(DESTDIR)$(DATADIR)/applications/$(APPNAME).desktop
	rm -f $(DESTDIR)$(DATADIR)/metainfo/$(APPNAME).metainfo.xml
	rm -f $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/$(APPNAME).svg

.PHONY: all clean install uninstall

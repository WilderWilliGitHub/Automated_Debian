#!/bin/bash

# Variablen für Dateinamen und Pfade
ISO_ORIGINAL="debian-12.7.0-amd64-netinst.iso"  # Name der Original-ISO
ISO_NEU="debian-12.7.0-amd64-preseed.iso"       # Name der neuen ISO mit Preseed
PRESEED_FILE="preseed.cfg"                      # Name der Preseed-Datei

# Verzeichnisse für die ISO-Mounts
MOUNT_DIR="iso_mount"
NEW_ISO_DIR="iso_new"

# Überprüfen, ob die Original-ISO und Preseed-Datei vorhanden sind
if [[ ! -f "$ISO_ORIGINAL" ]]; then
  echo "Die Datei $ISO_ORIGINAL wurde nicht gefunden."
  exit 1
fi

if [[ ! -f "$PRESEED_FILE" ]]; then
  echo "Die Datei $PRESEED_FILE wurde nicht gefunden."
  exit 1
fi

# Temporäre Verzeichnisse erstellen
mkdir -p "$MOUNT_DIR" "$NEW_ISO_DIR"

# Original-ISO mounten
sudo mount -o loop "$ISO_ORIGINAL" "$MOUNT_DIR"

# Dateien der Original-ISO ins neue Verzeichnis kopieren
cp -rT "$MOUNT_DIR" "$NEW_ISO_DIR"

# ISO unmounten
sudo umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

# Preseed-Datei ins neue ISO-Verzeichnis kopieren
cp "$PRESEED_FILE" "$NEW_ISO_DIR/preseed.cfg"

# Boot-Menü-Eintrag anpassen, damit Preseed automatisch verwendet wird
cat >> "$NEW_ISO_DIR/isolinux/isolinux.cfg" <<EOF

label auto
    menu label ^Automatische Installation mit Preseed
    kernel /install.amd/vmlinuz
    append auto=true priority=critical vga=788 file=/cdrom/preseed.cfg initrd=/install.amd/initrd.gz --- quiet
EOF

# Neue ISO mit Preseed-Datei erstellen
sudo genisoimage -o "$ISO_NEU" -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table "$NEW_ISO_DIR"

# Optional: ISO als Hybrid-ISO erstellen (falls für VMs erforderlich)
sudo isohybrid "$ISO_NEU"

# Aufräumen
rm -rf "$NEW_ISO_DIR"

echo "Die neue ISO-Datei wurde erfolgreich erstellt: $ISO_NEU"

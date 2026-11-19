#!/bin/sh
# Đo dung lượng các volume (gắn read-only) và ghi cho node-exporter đọc.
OUT=/textfile/volumes.prom
while true; do
  {
    echo '# HELP sms_volume_bytes Size of Docker volume in bytes'
    echo '# TYPE sms_volume_bytes gauge'
    for d in /vols/*; do
      n=$(basename "$d")
      kb=$(du -sk "$d" 2>/dev/null | cut -f1)
      echo "sms_volume_bytes{volume=\"$n\"} $(( ${kb:-0} * 1024 ))"
    done
  } > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
  sleep 60
done

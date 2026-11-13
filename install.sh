#!/bin/sh
# Установить overlay-autostart на VK Капсулу. Usage: ./install.sh [host:port]
# После установки любой S-скрипт в /etc/init.d, которого нет в /rom, стартует при
# загрузке (сейчас это S50dropbear и S96capsula-proxy).
set -e
cd "$(dirname "$0")"
DEV=${1:-10.0.0.227:5555}
HOST=S96stereoctl.sh            # штатный /rom-скрипт, чьё имя занимаем (см. shim)
S="adb -s $DEV"
adb connect "$DEV" >/dev/null 2>&1 || true

# host-скрипт обязан быть в /rom: иначе наш файл сам станет overlay-only и не запустится.
$S shell "[ -f /rom/etc/init.d/$HOST ]" </dev/null \
    || { echo "FAIL: нет /rom/etc/init.d/$HOST — выбери другой HOST в shim и тут"; exit 1; }

$S push "$HOST" /etc/init.d/"$HOST"
$S shell "chmod 755 /etc/init.d/$HOST" </dev/null
echo "--- при загрузке автостартуют (overlay-only S-скрипты):"
$S shell 'for i in /etc/init.d/S??*; do [ -f "$i" ] || continue; [ -f "/rom/etc/init.d/${i##*/}" ] && continue; echo "  $i"; done' </dev/null
echo "OK. Проверка: adb -s $DEV reboot, затем ps."

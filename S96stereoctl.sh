#!/bin/sh
# capsula overlay-autostart shim — ставится overlay-autostart/install.sh.
#
# Зачем: /etc/init.d/rcS раскрывает список S-скриптов ОДИН раз, до того как
# S23overlayfs.sh монтирует overlay (pivot: старый корень уходит в /rom). Скрипты,
# которые есть только в overlay (наш автозапуск: S50dropbear, S96capsula-proxy и
# любые будущие), в этот список не попадают и при загрузке не стартуют.
#
# Как: этот файл кладётся в overlay ПОВЕРХ штатного /rom/etc/init.d/S96stereoctl.sh.
# Его имя есть в /rom, поэтому rcS включает его в список и исполняет нашу копию
# (rcS делает `. $i` для *.sh в подоболочке). Мы:
#   1) запускаем все overlay-only S-скрипты (которых нет в /rom) — как это сделал бы rcS;
#   2) exec'аем настоящий /rom-скрипт с теми же аргументами.
# exec внутри форкнутой подоболочки rcS заменяет только её, не трогая rcS. Тело
# системного скрипта всегда берётся свежим из /rom, поэтому OTA его не затирает.
#
# Ретаргет на другой штатный скрипт: переименуй этот файл и поправь SHADOW (имя
# должно существовать в /rom/etc/init.d и идти не позже нужной точки запуска).
# Откат: rm /data/overlay/upper/etc/init.d/S96stereoctl.sh

SHADOW=/rom/etc/init.d/S96stereoctl.sh   # штатный скрипт, чьё имя мы заняли

if [ "$1" = start ] && [ -d /rom/etc/init.d ]; then
    for i in /etc/init.d/S??*; do
        [ -f "$i" ] || continue
        [ -f "/rom/etc/init.d/${i##*/}" ] && continue   # штатный — его запускает rcS
        case "$i" in
            *.sh) ( trap - INT QUIT TSTP; set start; . "$i" ) ;;
            *)    [ -x "$i" ] && "$i" start ;;
        esac
    done
fi

[ -x "$SHADOW" ] && exec "$SHADOW" "$@"

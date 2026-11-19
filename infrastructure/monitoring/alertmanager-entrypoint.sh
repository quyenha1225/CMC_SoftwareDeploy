#!/bin/sh
# Dựng cấu hình Alertmanager từ biến môi trường (.env), không lưu token trong file cấu hình.
set -eu
if [ -n "${ALERT_TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${ALERT_TELEGRAM_CHAT_ID:-}" ]; then
  sed -e "s|__TG_TOKEN__|${ALERT_TELEGRAM_BOT_TOKEN}|" \
      -e "s|__TG_CHAT_ID__|${ALERT_TELEGRAM_CHAT_ID}|" \
      /etc/alertmanager/alertmanager.tmpl.yml > /tmp/alertmanager.yml
  echo "Alertmanager: gui canh bao qua Telegram"
else
  cp /etc/alertmanager/alertmanager.null.yml /tmp/alertmanager.yml
  echo "Alertmanager: ALERT_TELEGRAM_BOT_TOKEN/CHAT_ID chua dat, chi hien canh bao, khong gui"
fi
exec /bin/alertmanager --config.file=/tmp/alertmanager.yml --storage.path=/alertmanager

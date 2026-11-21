#!/bin/sh
set -eu
umask 077
config=/tmp/alertmanager.yml

if [ -n "${ALERT_TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${ALERT_TELEGRAM_CHAT_ID:-}" ]; then
  sed -e "s|__TG_TOKEN__|${ALERT_TELEGRAM_BOT_TOKEN}|" \
      -e "s|__TG_CHAT_ID__|${ALERT_TELEGRAM_CHAT_ID}|" \
      /etc/alertmanager/alertmanager.tmpl.yml > "$config"
  echo "Alertmanager: Telegram enabled"
else
  cp /etc/alertmanager/alertmanager.null.yml "$config"
fi

if [ -r /run/secrets/discord_webhook_url ] &&
   grep -q '[^[:space:]]' /run/secrets/discord_webhook_url; then
  cat >> "$config" <<'YAML'
    discord_configs:
      - webhook_url_file: /run/secrets/discord_webhook_url
        username: SMS Monitoring
        send_resolved: true
        title: '[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }} ({{ .CommonLabels.severity }})'
        message: |
          {{ range .Alerts -}}
          **{{ .Status }}** {{ if .Labels.job }}{{ .Labels.job }}{{ end }} {{ .Labels.instance }}
          {{ .Annotations.summary }}
          {{ if .Annotations.description }}{{ .Annotations.description }}{{ end }}
          {{ end -}}
YAML
  echo "Alertmanager: Discord enabled"
fi

exec /bin/alertmanager --config.file="$config" --storage.path=/alertmanager

#!/bin/sh

SCRIPT_PATH="/etc/scripts/ledcontrol.sh"
SCRIPT_URL="https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/Scripts/ledcontrol.sh"
CRON_FILE="/etc/crontabs/root"
RC_LOCAL="/etc/rc.local"

echo "[*] Скачиваем скрипт ledcontrol.sh..."
wget -q -O "$SCRIPT_PATH" "$SCRIPT_URL"

if [ $? -ne 0 ]; then
  echo "Ошибка: не удалось скачать скрипт"
  exit 1
fi

chmod +x "$SCRIPT_PATH"
echo "[✓] Скрипт скачан и сделан исполняемым"

if ! grep -q "$SCRIPT_PATH on" "$CRON_FILE"; then
  echo "0 7 * * * $SCRIPT_PATH on" >> "$CRON_FILE"
  echo "[+] Задача включения добавлена в cron"
fi

if ! grep -q "$SCRIPT_PATH off" "$CRON_FILE"; then
  echo "0 23 * * * $SCRIPT_PATH off" >> "$CRON_FILE"
  echo "[+] Задача выключения добавлена в cron"
fi

if ! grep -q "$SCRIPT_PATH auto" "$CRON_FILE"; then
  echo "*/30 * * * * $SCRIPT_PATH auto" >> "$CRON_FILE"
  echo "[+] Задача автоматической работы добавлена в cron"
fi

/etc/init.d/cron restart
echo "[*] Сервис cron перезагружен"

if [ -f "$RC_LOCAL" ]; then
  if ! grep -q "$SCRIPT_PATH" "$RC_LOCAL"; then
    sed -i "/^exit 0/i $SCRIPT_PATH check" "$RC_LOCAL"
    echo "[+] Вызов скрипта добавлен в rc.local"
  else
    echo "[i] В rc.local уже есть вызов скрипта"
  fi
else
  echo "[!] Внимание: /etc/rc.local не найден. Добавление пропущено"
fi

echo "[✓] Установка завершена"

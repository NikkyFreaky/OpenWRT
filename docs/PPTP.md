# Установка PPTP-клиента

Нужно для работы таких VPN-клиентов, например как .pbk для получения доступа к корпоративной сети.

```bash
# Обновляем списки пакетов
opkg update

# Устанавливаем пакеты для поддержки PPTP-соединения
opkg install ppp-mod-pptp kmod-nf-nathelper-extra

# Перезапускаем фаервол
service firewall restart
```
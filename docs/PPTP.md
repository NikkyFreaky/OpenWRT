# Установка PPTP-клиента

Нужно для работы таких VPN-клиентов, например как .pbk для получения доступа к корпоративной сети.

### Установка на Openwrt 24
```bash
# Обновляем списки пакетов
opkg update

# Устанавливаем пакеты для поддержки PPTP-соединения
opkg install ppp-mod-pptp kmod-nf-nathelper-extra

# Перезапускаем фаервол
service firewall restart
```

### Установка на Openwrt 25
```bash
# Обновляем списки пакетов
apk update

# Устанавливаем пакеты для поддержки PPTP-соединения
apk add ppp-mod-pptp kmod-nf-nathelper-extra

# Перезапускаем фаервол
service firewall restart
```
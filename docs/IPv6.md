# Отключение IPv6

```bash
# Удаляем интерфейс IPv6 (WAN6)
uci delete network.wan6

# Отключаем IPv6 на локальном интерфейсе (LAN)
uci set network.lan.ipv6=0
uci delete network.lan.ip6assign

# Отключаем раздачу IPv6 адресов (DHCPv6)
uci delete dhcp.lan.dhcpv6
uci delete dhcp.lan.ra

# Применяем настройки
uci commit network
uci commit dhcp
/etc/init.d/network restart
/etc/init.d/odhcpd restart
```
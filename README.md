# OpenWRT Domains Scripts

Коллекция скриптов и списков доменов для OpenWRT роутеров.

## Структура репозитория

```
├── Scripts/           # Полезные скрипты для OpenWRT
│   └── ledcontrol.sh  # Управление LED-индикацией по расписанию
└── Services/          # Списки доменов для различных сервисов
    └── copilot.lst    # Домены для GitHub Copilot и Microsoft Edge
```

## Списки доменов

### GitHub Copilot / Microsoft Edge

Список доменов, необходимых для корректной работы GitHub Copilot и связанных сервисов Microsoft Edge.

**Прямая ссылка:** [copilot.lst](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT_domains_scripts/refs/heads/main/Services/copilot.lst)

Содержит 25 доменов, включая:
- api.githubcopilot.com
- copilot.microsoft.com  
- github.com API endpoints
- Microsoft Edge сервисы
- Telemetry и CDN домены

## Скрипты

### LED-индикация по расписанию

Скрипт для автоматического управления LED-индикацией роутера в зависимости от времени суток.

#### Возможности
- Включение/выключение LED по команде
- Автоматическое управление по времени
- Логирование всех операций
- Проверка текущего состояния LED

#### Установка

1. Создайте файл скрипта и сделайте его исполняемым:
```bash
touch /etc/ledcontrol.sh && chmod +x /etc/ledcontrol.sh
```

2. Откройте файл в текстовом редакторе:
```bash
vi /etc/ledcontrol.sh
```

3. Скопируйте содержимое из [ledcontrol.sh](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT_domains_scripts/refs/heads/main/Scripts/ledcontrol.sh)

#### Настройка расписания

1. Откройте веб-интерфейс LuCI
2. Перейдите в **System → Scheduled Tasks** (Система → Планировщик)
3. Добавьте следующие строки:
```cron
00 23 * * * /etc/ledcontrol.sh off
00 7 * * * /etc/ledcontrol.sh on
```
4. Нажмите **Save** (Сохранить)

По умолчанию LED будет выключаться в 23:00 и включаться в 7:00.

5. Перезапустите службу cron:
```bash
/etc/init.d/cron restart
```

#### Использование

```bash
# Включить LED
/etc/ledcontrol.sh on

# Выключить LED
/etc/ledcontrol.sh off

# Автоматическое управление по времени
/etc/ledcontrol.sh auto
```

#### Настройка времени

В скрипте можно изменить время включения/выключения, отредактировав переменные:
```bash
ON_TIME=700   # 7:00
OFF_TIME=2300 # 23:00
```

#### Системные требования

- OpenWRT с поддержкой sysfs LED управления
- Доступ к `/sys/class/leds/blue:status/`
- Права на запись в системный журнал

## Использование списков доменов

Списки доменов можно использовать для:
- Настройки DNS фильтрации
- Создания правил файрвола
- Настройки VPN маршрутизации
- Обхода блокировок провайдера

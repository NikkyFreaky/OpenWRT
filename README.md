# OpenWRT Domains Scripts

Коллекция скриптов, списков доменов и полезных команд для OpenWRT роутеров.

## Структура репозитория

```bash
├── docs/                # Документация по разным командам для OpenWRT
│   └── IPv6.md          # Команды для отключения IPv6
│   └── PPTP.md          # Команды для установки PPTP-клиента
├── scripts/             # Скрипты для OpenWRT
│   └── ledcontrol/      # Установщик, LED-профили и управление индикаторами
└── services/            # Списки доменов для различных сервисов
    ├── copilot.lst      # Домены для GitHub Copilot и Microsoft Edge
    ├── figma.lst        # Домены для Figma
    ├── github.lst       # Домены для GitHub
    ├── notion.lst       # Домены для Notion
    └── openwrt.lst      # Домены для OpenWRT
```

## Документация

### Команды для отключения IPv6

**Прямая ссылка:** [IPv6.md](https://github.com/NikkyFreaky/OpenWRT/blob/b8d29f57625a8faf30cab986e4c5a8665e1e4f34/docs/IPv6.md)

### Команды для установки PPTP-клиента

**Прямая ссылка:** [PPTP.md](https://github.com/NikkyFreaky/OpenWRT/blob/b8d29f57625a8faf30cab986e4c5a8665e1e4f34/docs/PPTP.md)

## Списки доменов

### GitHub Copilot / Microsoft Edge

Список доменов, необходимых для корректной работы GitHub Copilot и связанных сервисов Microsoft Edge.

**Прямая ссылка:** [copilot.lst](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/services/copilot.lst)

### Figma

Список доменов, необходимых для корректной работы Figma и связанных сервисов.

**Прямая ссылка:** [figma.lst](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/services/figma.lst)

### GitHub

Список доменов для полноценной работы GitHub и связанных сервисов (включая GitHub Pages, GitHub Actions, и другие интеграции).

**Прямая ссылка:** [github.lst](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/services/github.lst)

### Notion

Список доменов, необходимых для корректной работы Notion и связанных сервисов.

**Прямая ссылка:** [notion.lst](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/services/notion.lst)

### OpenWRT

Список доменов для OpenWRT и связанных сервисов (репозитории пакетов, обновления, документация).

**Прямая ссылка:** [openwrt.lst](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/services/openwrt.lst)

## Скрипты

### LED-индикация по расписанию

Скрипт для автоматического управления LED-индикацией роутера в зависимости от времени суток.

#### Возможности

- Включение/выключение LED по команде
- Автоматическое управление по времени
- Логирование всех операций
- Проверка текущего состояния LED

#### Поддерживаемое оборудование

<details>
    <summary>Список проверенного оборудования</summary>

- Xiaomi Router AX3000T
- Xiaomi Router AX3200 / Redmi AX6S
</details><br>

> [!NOTE]
> Список будет дополняться. Пишите на каком оборудовании проверили работоспособность скрипта в [обсуждении](https://github.com/NikkyFreaky/OpenWRT/discussions/4).

#### Автоматическая установка

Для установки или обновления скопируйте в терминал роутера одну команду:

```bash
wget -O - https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/scripts/ledcontrol/install.sh | sh
```

Установщик получает модель из `/tmp/sysinfo/model`, выбирает подходящий профиль LED и сохраняет все файлы в `/etc/scripts/ledcontrol/`. Поддерживаются Xiaomi Router AX3000T и Xiaomi Router AX3200 / Redmi AX6S. Для неизвестной модели он завершится до изменения скрипта и расписания.

Повторный запуск обновляет файлы и не дублирует собственные записи в cron и `rc.local`. Если ранее использовалась старая установка `/etc/scripts/ledcontrol.sh`, установщик удалит этот файл и заменит её записи планировщика и `rc.local`. После установки состояние LED сразу приводится в соответствие с текущим временем.

#### Настройка расписания

Установщик добавляет включение в 07:00, выключение в 23:00 и проверку режима каждые 30 минут. Если нужно другое расписание, измените две записи в LuCI: **System → Scheduled Tasks**. Автозапуск выполняет `auto` через пять секунд после загрузки роутера.

> [!TIP]  
> Можно добавить задачу альтернативно, через командную строку

```bash
crontab -e
```

По данному расписанию LED будет выключаться в 23:00 и включаться в 7:00. Дополнительная задача `auto` проверяет состояние каждые 30 минут.

> [!WARNING]  
> Если меняете время включения/выключения, изменяйте его как в планировщике, так и в самом скрипте.

5. Перезапустите службу cron:
   ```bash
   /etc/init.d/cron restart
   ```

#### Использование

```bash
# Включить LED
/etc/scripts/ledcontrol/ledcontrol.sh on

# Выключить LED
/etc/scripts/ledcontrol/ledcontrol.sh off

# Автоматическое управление по времени
/etc/scripts/ledcontrol/ledcontrol.sh auto
```

#### Полезные команды

- Проверка логов скрипта:

  ```bash
  logread | grep ledcontrol
  ```

- Проверка состояния LED:

  ```bash
  cat /sys/class/leds/blue:status/trigger
  cat /sys/class/leds/blue:status/brightness
  ```

- Проверка cron-задач:
  ```bash
  crontab -l
  ```

#### Настройка времени

В `/etc/scripts/ledcontrol/ledcontrol.sh` можно изменить время включения/выключения, отредактировав переменные:

```bash
ON_TIME=700   # 7:00
OFF_TIME=2300 # 23:00
```

# OpenWRT Domains Scripts

Коллекция скриптов, списков доменов и полезных команд для OpenWRT роутеров.

## Структура репозитория

```bash
├── docs/                # Документация по разным командам для OpenWRT
│   └── IPv6.md          # Команды для отключения IPv6
│   └── PPTP.md          # Команды для установки PPTP-клиента
├── scripts/             # Скрипты для OpenWRT
│   └── ledcontrol/      # Установщик, LuCI-интерфейс и управление индикаторами
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
wget -O - "https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/main/scripts/ledcontrol/install.sh?cachebust=$(date +%s)" | sh
```

Установщик находит доступные LED в `/sys/class/leds/` и формирует конфигурацию для текущего устройства в `/etc/scripts/ledcontrol/ledcontrol.conf`. Он восстанавливает штатные UCI-триггеры из `/etc/config/system`. Для индикаторов без UCI-настроек он использует штатный алиас Device Tree `led-running`: это позволяет выбрать правильный цвет многоцветного индикатора. Если такого алиаса нет, постоянно включается только однозначный одиночный LED с назначением `power`, `status`, `system` или `running`. Поэтому скрипт не зависит от заранее подготовленного списка моделей и не включает одновременно цвета одного индикатора.

Повторный запуск обновляет файлы и управляет расписанием через службу `/etc/init.d/ledcontrol`. Он не создаёт записей в cron или `rc.local`; при миграции удаляются только ранее созданные LED Control строки. Если ранее использовалась старая установка `/etc/scripts/ledcontrol.sh`, установщик удалит этот файл и связанные с ним записи. После установки состояние LED сразу приводится в соответствие с текущим временем.

При включении скрипт восстанавливает настройки LED из `/etc/config/system`, поэтому пользовательские UCI-триггеры сохраняются. На LED без UCI-настроек он не назначает предполагаемые триггеры: включает только LED, выбранный при установке как штатный `led-running` либо как однозначный одиночный индикатор.

#### Удаление

Для полного удаления LED Control выполните:

```bash
wget -O - "https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/main/scripts/ledcontrol/install.sh?cachebust=$(date +%s)" | sh -s -- uninstall
```

Команда остановит и отключит службу LED Control, восстановит штатную службу LED, удалит файлы скрипта, LuCI-страницу и перевод, настройки `/etc/config/ledcontrol` и ранее созданные LED Control записи cron и `rc.local`.

#### Настройка расписания

Служба LED Control проверяет выбранный режим каждые пять минут и запускает `auto` через пять секунд после загрузки роутера. В LuCI откройте **Services → LED Control**, включите переключатель **Automatic mode**, выберите часы включения и выключения и сохраните настройки. Автоматический режим включён по умолчанию; ручное включение или выключение LED отключает его, чтобы служба не отменила выбранное состояние через пять минут.

Интерфейс LED Control автоматически использует русский перевод, когда в общих настройках LuCI выбран русский язык. Для остальных языков отображается английский интерфейс.

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

- Проверка службы:
  ```bash
  /etc/init.d/ledcontrol status
  ```

#### Настройка времени

Время включения и выключения хранится в UCI-конфигурации `/etc/config/ledcontrol`:

```bash
uci set ledcontrol.settings.on_hour='7'
uci set ledcontrol.settings.off_hour='23'
uci commit ledcontrol
```

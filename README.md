# OpenWRT Domains Scripts

Коллекция скриптов и списков доменов для OpenWRT роутеров.

## Структура репозитория

```bash
├── scripts/             # Полезные скрипты для OpenWRT
│   └── ledcontrol.sh    # Управление LED-индикацией по расписанию
└── services/            # Списки доменов для различных сервисов
    ├── copilot.lst      # Домены для GitHub Copilot и Microsoft Edge
    ├── figma.lst        # Домены для Figma
    ├── github.lst       # Домены для GitHub
    ├── notion.lst       # Домены для Notion
    └── openwrt.lst      # Домены для OpenWRT
```

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

Для автоматической установки скрипта можете воспользоваться командами:

```bash
mkdir -p /etc/scripts && wget -q -O /etc/scripts/ledcontrol.sh https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/scripts/ledcontrol.sh && chmod +x /etc/scripts/ledcontrol.sh
echo -e "0 7 * * * /etc/scripts/ledcontrol.sh on\n0 23 * * * /etc/scripts/ledcontrol.sh off\n*/30 * * * * /etc/scripts/ledcontrol.sh auto" >> /etc/crontabs/root && /etc/init.d/cron restart && [ -f /etc/rc.local ] && chmod +x /etc/rc.local && sed -i "/^exit 0/i (sleep 5 && /etc/scripts/ledcontrol.sh auto) &\n" /etc/rc.local || echo "rc.local не найден"
```

#### Ручная установка

1. Создайте директорию для скриптов в `/etc`:

   ```bash
   mkdir -p /etc/scripts
   ```

2. Создайте файл скрипта и сделайте его исполняемым:

   ```bash
   touch /etc/scripts/ledcontrol.sh && chmod +x /etc/scripts/ledcontrol.sh
   ```

3. Откройте файл в текстовом редакторе:

   ```bash
   vi /etc/scripts/ledcontrol.sh
   ```

4. Скопируйте содержимое из [ledcontrol.sh](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/scripts/ledcontrol.sh)

5. Сделайте файл `/etc/rc.local` исполняемым и откройте его:

   ```bash
   chmod +x /etc/rc.local && vi /etc/rc.local
   ```

> [!TIP]  
> Можно открыть `/etc/rc.local` через веб-интерфейс LuCI в **System → Startup** (Система → Автозапуск), вкладка Local Startup.

6. Добавьте следующую строку до `exit 0`:

   ```bash
   (sleep 5 && /etc/scripts/ledcontrol.sh auto) &
   ```

> [!NOTE]  
> Эта строка нужна для запуска скрипта после перезагрузки роутера с 5-секундной задержкой, чтобы все системы успели загрузиться.

#### Настройка расписания

1. Откройте веб-интерфейс LuCI
2. Перейдите в **System → Scheduled Tasks** (Система → Планировщик)
3. Добавьте следующие строки:

   ```cron
   00 23 * * * /etc/scripts/ledcontrol.sh off
   00 7 * * * /etc/scripts/ledcontrol.sh on
   */30 * * * * /etc/scripts/ledcontrol.sh auto
   ```

4. Нажмите **Save** (Сохранить)

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
/etc/scripts/ledcontrol.sh on

# Выключить LED
/etc/scripts/ledcontrol.sh off

# Автоматическое управление по времени
/etc/scripts/ledcontrol.sh auto
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

В скрипте можно изменить время включения/выключения, отредактировав переменные:

```bash
ON_TIME=700   # 7:00
OFF_TIME=2300 # 23:00
```

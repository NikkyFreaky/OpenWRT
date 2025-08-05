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

<details>
  <summary>GitHub Copilot / Microsoft Edge</summary><br>
    
  Список доменов, необходимых для корректной работы GitHub Copilot и связанных сервисов Microsoft Edge.
- **Прямая ссылка:** [copilot.lst](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/Services/copilot.lst)
</details>

## Скрипты

<details>
  <summary>LED-индикация по расписанию</summary><br>
  
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
</details><br>

> [!NOTE]  
> Список будет дополняться. Пишите на каком оборудовании проверили работоспособность скрипта в [обсуждении](https://github.com/NikkyFreaky/OpenWRT/discussions/4).

### Установка

1. Создайте файл скрипта и сделайте его исполняемым:

   ```bash
   touch /etc/ledcontrol.sh && chmod +x /etc/ledcontrol.sh
   ```

2. Откройте файл в текстовом редакторе:

   ```bash
   vi /etc/ledcontrol.sh
   ```

3. Скопируйте содержимое из [ledcontrol.sh](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/Scripts/ledcontrol.sh)

4. Сделайте файл `/etc/rc.local` исполняемым и откройте его:

   ```bash
   chmod +x /etc/rc.local && vi /etc/rc.local
   ```

   > [!TIP]  
   > Можно открыть `/etc/rc.local` через веб-интерфейс LuCI в System → Startup (Система → Автозапуск), вкладка Local Startup.

5. Добавьте следующую строку до `exit 0`:

   ```bash
   (sleep 5 && /etc/ledcontrol.sh auto) &
   ```

   > [!NOTE]  
   > Эта строка нужна для запуска скрипта после перезагрузки роутера с 5-секундной задержкой, чтобы все системы успели загрузиться.

#### Настройка расписания

1. Откройте веб-интерфейс LuCI
2. Перейдите в **System → Scheduled Tasks** (Система → Планировщик)
3. Добавьте следующие строки:

   ```cron
   00 23 * * * /etc/ledcontrol.sh off
   00 7 * * * /etc/ledcontrol.sh on
   */30 * * * * /etc/ledcontrol.sh auto
   ```

4. Нажмите **Save** (Сохранить)

   > [!TIP]  
   > Можно добавить задачу альтернативно, через командную строку
   >
   > ```bash
   > crontab -e
   > ```

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
/etc/ledcontrol.sh on

# Выключить LED
/etc/ledcontrol.sh off

# Автоматическое управление по времени
/etc/ledcontrol.sh auto
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

</details>

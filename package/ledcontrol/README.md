# Пакеты LED Control для OpenWrt

Рецепт собирает три архитектурно-независимых пакета для OpenWrt:

- `ledcontrol` — исполняемый скрипт, настройки UCI, поиск LED и init-служба;
- `luci-app-ledcontrol` — страница LuCI и список прав доступа RPCD;
- `luci-i18n-ledcontrol-ru` — необязательный русский перевод LuCI.

`ledcontrol` — пакет без компилируемого исходного кода, поэтому ему не нужна
сборка для конкретной архитектуры. Он использует службу, управляемую procd:
через пять секунд после загрузки она запускает проверку расписания каждые пять
минут. При первой установке пакет определяет доступные LED и записывает
конфигурацию в `/etc/scripts/ledcontrol/ledcontrol.conf`. Файл
`/etc/config/ledcontrol` является conffile и сохраняется при обновлении и
удалении пакета.

## Сборка с OpenWrt SDK

Добавьте этот репозиторий как feed, установите пакет и соберите его:

```sh
echo 'src-git ledcontrol https://github.com/NikkyFreaky/OpenWRT.git' >> feeds.conf.default
./scripts/feeds update ledcontrol
./scripts/feeds install -p ledcontrol ledcontrol
make package/ledcontrol/{clean,compile} V=s
```

Готовые пакеты появятся в каталоге `bin/packages/`. Для OpenWrt 25.12 и новее
используются файлы `.apk` и команда `apk add`; для OpenWrt 24.10 и старее —
файлы `.ipk` и команда `opkg install`. Сначала установите основной пакет, затем
при необходимости добавьте LuCI и пакет перевода.

При установке пакет удаляет из cron и `rc.local` только известные устаревшие
строки LED Control. Новые установки не добавляют записей ни в один из этих
файлов. GitHub Actions автоматически собирает APK для 25.12 и IPK для 24.10 и
23.05; результаты доступны как отдельные артефакты запуска.

## Автоматическая установка пакета

После создания первого release с версионным тегом выполните на роутере одну команду:

```sh
wget -O - https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/main/scripts/ledcontrol/install-package.sh | sh
```

Установщик определяет ветку OpenWrt и пакетный менеджер, затем скачивает из
последнего GitHub Release подходящие для 25.12, 24.10 или 23.05 пакеты
`ledcontrol`, `luci-app-ledcontrol` и русский перевод. Пакеты не содержат
нативного кода и имеют архитектуру `all`, поэтому отдельная проверка модели
или процессорной архитектуры не требуется.

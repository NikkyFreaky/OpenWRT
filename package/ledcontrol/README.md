# Пакеты LED Control для OpenWrt

Рецепт собирает три архитектурно-независимых APK-пакета для OpenWrt 25.12:

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

Готовые файлы `.apk` появятся в каталоге `bin/packages/`. На роутере с OpenWrt
25.12 сначала установите основной пакет, затем при необходимости добавьте LuCI
и пакет перевода командой `apk add`.

При установке пакет удаляет из cron и `rc.local` только известные устаревшие
строки LED Control. Новые установки не добавляют записей ни в один из этих
файлов.

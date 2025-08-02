# Прямые ссылки на списки

<details>
  <summary>Copilot</summary>
  
  - [RAW](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT_domains_scripts/refs/heads/main/Services/copilot.lst)

</details>

# Скрипты

<details>
  <summary>LED-индикация по расписанию</summary>

  1. Создаем файл со скриптом и делаем его исполняемым:
  ```
  touch /etc/ledcontrol.sh & chmod +x /etc/ledcontrol.sh
  ```
  
  3. Открываем файл в текстовом редакторе:
  ```
  vi /etc/ledcontrol.sh
  ```
  
  4. Вставляем в него содержимое [скрипта](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT_domains_scripts/refs/heads/main/Scripts/ledcontrol.sh).
  
  5. Затем в веб-интерфейсе LuCI заходим в **scheduled tasks** (планировщик), расположенный в System→Scheduled tasks (Система→Планировщик), добавляем расписание включения и отключения LED-индикации:
  ```
  00 23 * * * /etc/ledcontrol.sh off
  00 7 * * * /etc/ledcontrol.sh on
  ```
  И нажимаем **Save** (сохранить).
  
  По данному расписанию LED-индикация будет выключаться в 23:00 и включаться в 7:00.
  
  6. Перезапускаем cron, чтобы добавить новые задачи:
  ```
  /etc/init.d/cron restart
  ```
</details>

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
  
  2. Открываем файл в текстовом редакторе:
     ```
     vi /etc/ledcontrol.sh
     ```
  
  3. Вставляем в него содержимое [скрипта](https://raw.githubusercontent.com/NikkyFreaky/OpenWRT_domains_scripts/refs/heads/main/Scripts/ledcontrol.sh).

  4. Делаем файл `/etc/rc.local` исполняемым:
     ```
     chmod +x /etc/rc.local & vi /etc/rc.local
     ```
    
  5. И добавляем в него следующую строку до `exit 0`:
     ```
     (sleep 5 && /etc/ledcontrol.sh auto) &
     ```
     Она нужна для запуска нашего скрипта после перезагрузки/включения роутера. Вызов срабатывает с 5-ти секундной задержкой, чтобы все системы роутера успели загрузиться.
  
  6. Затем в веб-интерфейсе LuCI заходим в **scheduled tasks** (планировщик), расположенный в System→Scheduled tasks (Система→Планировщик), добавляем расписание включения и отключения LED-индикации:
     ```
     00 23 * * * /etc/ledcontrol.sh off
     00 7 * * * /etc/ledcontrol.sh on
     */30 * * * * /etc/ledcontrol.sh auto
     ```
     И нажимаем **Save** (сохранить).

     По данному расписанию LED-индикация будет выключаться в 23:00 и включаться в 7:00. Если хотите поменять время включения/выключения, то менять его надо в планировщике и в самом скрипте.
  
  7. Перезапускаем cron, чтобы добавить новые задачи:
     ```
     /etc/init.d/cron restart
     ```

     ### **Команды:**

      - Проверка логов скрипта: ```logread | grep ledcontrol```
       
</details>

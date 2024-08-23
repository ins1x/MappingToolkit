<h1 align="center">Mapping Toolkit</h1>
<p align="center">
    <a href="https://www.sa-mp.mp/"><img src="https://img.shields.io/badge/made%20for-GTA%20SA--MP-blue"></a>
    <a href="https://gta-samp.ru/"><img src="https://img.shields.io/badge/Server-Absolute%20Play-red"></a>
    <a href="https://training-server.com/"><img src="https://img.shields.io/badge/Server-TRAINING%20SANDBOX%20-yellow"></a>
</p>

###### The following description is in Russian, because it is the main language of the user base.

![logo](https://github.com/ins1x/MappingToolkit/raw/main/moonloader/resource/mappingtoolkit/demo.gif)

### Краткое описание скрипта
Ассистент для мапперов и организаторов мероприятий.  
Основная задача данного скрипта - сделать процесс маппинга в внутриигровом редакторе карт максимально приятным, и дать больше возможностей организаторам мероприятий. 

Потенциально читерские возможности не используются - это не мультичит!   
Больше информации по маппингу и редактору карт в [wiki](https://github.com/ins1x/MappingToolkit/wiki).   

## Возможности
Ассистент дает вам больше возможностей для маппинга и разработки ваших проектов. Функционал достаточно обширен, и регулярно обновляется. Для управления всеми возможностями предоставлен удобный графического интерфейс на [imgui](https://www.blast.hk/threads/19292/). Ассистент предоставляет дополнительные функции для работы с текстурами и объектами, исправляет некоторые баги игры, дополняет серверные команды и диалоги. 

На текущий момент поддерживаются все сервера [Absolute Play](https://sa-mp.ru/) и [TRAINING SANDBOX](https://training-server.com/). Может работать и на других проектах, но часть функционала будет недоступна. Перед его использованием убедитесь что его функционал не запрещен на вашем сервере!  

[Посмотреть список всех возможностей](https://github.com/ins1x/MappingToolkit/wiki/%D0%92%D0%BE%D0%B7%D0%BC%D0%BE%D0%B6%D0%BD%D0%BE%D1%81%D1%82%D0%B8)  

[![YouTube Demo](https://img.shields.io/badge/YouTube_DEMO-%23FF0000.svg?style=for-the-badge&logo=YouTube&logoColor=white)](https://www.youtube.com/watch?v=h6jbmV0viDU)


## Требования
- Вам потребуется рабочая копия игры GTA San Andreas с верисей gta_sa.exe v1.0 US
- [Клиент SA-MP версии 0.3.7 R1](https://samp.romzes.com/files/sa-mp-0.3.7-install.exe)
- [ASI Loader](https://www.gtagarage.com/mods/show.php?id=21709), [CLEO 4.1](https://cleo.li/ru), [Moonloader 0.26](https://www.blast.hk/threads/13305/), [SAMPFUNCS 5.4.1](https://www.blast.hk/threads/17/)

> Можно использовать более новые версии клиента и sampfuncs, но часть функционала построенного на мемхаках работать не будет (например смена эффектов)

Зависимости Moonloader:
* lua imgui - https://www.blast.hk/threads/19292/
* lib.samp.events - https://github.com/THE-FYP/SAMP.Lua
* lua-requests - https://luarocks.org/modules/jakeg/lua-requests

> модуль **lua-requests** используется только для проверки версий, поэтому установка этого модуля необязательна для работы скрипта

## Установка

[Скачайте актуальную версию](https://github.com/ins1x/MappingToolkit/releases) и скопируйте содержимое архива **MappingToolkit.zip** в папку **moonloader** в корне игры. Важно перенести все файлы, включая папки /config и /resource ! 

Для **Absolute Play** рекомендуется использовать совместно с [AbsoluteFix](https://github.com/ins1x/moonloader-scripts/tree/main/absolutefix)  

> Если у вас нет папки **moonloader** в корне игры, следует установить вышеописанные в  требованиях компоненты.

 [![](https://img.shields.io/badge/%20%20DOWNLOAD%20%20-696969?style=for-the-badge)](https://github.com/ins1x/MappingToolkit/releases) 

После установки запустите игру и подключитесь к серверу  
В игре нажмите **ALT + X** или введите команду **/toolkit**

> Если скрипт не запустился, в папке moonloader есть файл moonloader.log с информацией о проблеме 

Если вы столкнулись с проблемой c запуском либо использованием скрипта, то ознакомьтесь с документацией ниже:   
* [FAQ - Ответы на часто задаваемы вопросы по скрипту](https://github.com/ins1x/MappingToolkit/wiki/FAQ-%D0%BF%D0%BE-MappingToolkit)  
* [Описание всех доступных настроек (/moonloader/config/mappingtoolkit.ini)](https://github.com/ins1x/MappingToolkit/wiki/%D0%9A%D0%BE%D0%BD%D1%84%D0%B8%D0%B3%D1%83%D1%80%D0%B0%D1%86%D0%B8%D1%8F)

## Disclaimer 
Скрипт может работать на других серверах, но перед его использованием убедитесь что его функционал не запрещен на вашем сервере! Некоторые возможности работают только на версии [клиента 0.3.7 R1](https://resamp.ru/), но это не мешает использовать ассистент на других версиях.

---------------------------------------------

[![forum training](https://img.shields.io/badge/Forum-TRAINING_SANDBOX-yellow)](https://forum.training-server.com/d/19708-luamappingtoolkit/)
[![github](https://img.shields.io/badge/Wiki-Github-black)](https://github.com/ins1x/MappingToolkit/wiki)
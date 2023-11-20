# Absolute Event Helper

![logo](https://github.com/ins1x/AbsEventHelper/raw/main/moonloader/resource/abseventhelper/demo.gif)

#### ENGLISH
Lua script Assistant for mappers and event makers on [Absolute Play](https://sa-mp.ru/) servers.   
The main task of this script - is make the mapping process in the in-game map editor as pleasant  
as possible, and to give more opportunities to event organizers.  
Find more about mapping on server at [forum.gta-samp.ru](https://forum.gta-samp.ru/index.php?/topic/1016832-%D0%BC%D0%B8%D1%80%D1%8B-%D0%BE%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D1%8B-%D1%80%D0%B5%D0%B4%D0%B0%D0%BA%D1%82%D0%BE%D1%80%D0%B0-%D0%BA%D0%B0%D1%80%D1%82/).  

#### RUS
LUA ассистент для мапперов и организаторов мероприятий на серверах [Absolute Play](https://sa-mp.ru/).  
Основная задача данного скрипта - сделать процесс маппинга в внутриигровом редакторе карт максимально  
приятным, и дать больше возможностей организаторам мероприятий.  
Больше информации по маппингу на сервере [forum.gta-samp.ru](https://forum.gta-samp.ru/index.php?/topic/1016832-%D0%BC%D0%B8%D1%80%D1%8B-%D0%BE%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D1%8B-%D1%80%D0%B5%D0%B4%D0%B0%D0%BA%D1%82%D0%BE%D1%80%D0%B0-%D0%BA%D0%B0%D1%80%D1%82/).   

> Рекомендуется использовать совместно с [AbsoluteFix](https://github.com/ins1x/AbsoluteFix)

## Возможности
- Удобный графический интерфейс на [imgui](https://www.blast.hk/threads/19292/)
- Информация по лимитам и возможностям редактора карт
- FAQ по редактору карт с часто задаваемыми вопросами и ошибками
- Чат биндер для проведения мероприятий
- Список необходимых объектов и эффектов
- Сохранение списка ваших избранных объектов в файл
- Удобный поиск по цветовой палитре и тест по RGB
- Удобный поиск транспорта по названию
- Предпросмотр текстур и спецсимволов
- Сохранение и использование точек для телепорта по /тпк
- Рендер объектов в области стрима
- Предпросмотр текущих координат объекта при перемещении
- Сохранение ид модели последнего объекта
- Таблица игроков с возможностью сохранения в файл
- Меню для быстрого управления игроками в мире (/стат, /и, /тп)
- Шаблоны для быстрых ответов игрокам
- Сообщение если из таблицы игроков кто-то вылетел или вышел из игры
- Подсчет игроков, транспорта и объектов в области стрима
- Отключение коллизии у объектов в области стрима
- Изменение прорисовки и дистанции тумана
- Обработка некоторых частых ошибок в мире и вывод уведомлений

> [DEMO на YouTube](https://youtu.be/LBtIJf_7b6o)

## Требования
- Вам потребуется рабочая копия игры GTA San Andreas с верисей gta_sa.exe v1.0 US
- [Клиент SA-MP версии 0.3.7 R1](https://samp.romzes.com/files/sa-mp-0.3.7-install.exe)
- [ASI Loader](https://www.gtagarage.com/mods/show.php?id=21709)
- [CLEO 4.1](https://cleo.li/ru) 
- [Moonloader 0.26](https://www.blast.hk/threads/13305/)  
- [SAMPFUNCS 5.4.1](https://www.blast.hk/threads/17/)

> Если вы играете на чистой сборке с Samp Addon, используйте отдельную сборку.

** Зависимости Moonloader **
* lua imgui - https://www.blast.hk/threads/19292/
* lib.samp.events - https://github.com/THE-FYP/SAMP.Lua

Протестировано на *SA-MP 0.3.7-R1, Moonloader 0.26, sampfuncs 5.4.1-final*  

## Как использовать
* Скопировать содержимое архива AbsEventHelper.zip в папку moonloader в корне игры
* Запустить GTA. В игре нажмите **ALT + X** или введите команду /abshelper
* Если скрипт не запустился, в папке moonloader есть файл moonloader.log с информацией о проблеме

## О поддержке Samp Addon 
Скрипт *не работает с включенным античитом* Samp Addon, так как разработчик аддона фильтрует все скрипты
по белому списку. А так же на Абсолютовской версии SAMPFUNCS DL. Категорически не рекомендуется использовать этот скрипт вне виртуального мира и редактора карт!  

## Credits 
* [EvgeN 1137](https://www.blast.hk/members/1), [hnnssy](https://www.blast.hk/members/66797), [FYP](https://github.com/THE-FYP) - Moonloader  
* [FYP](https://github.com/THE-FYP) - imgui, SAMP lua библиотеки
* [Gorskin](https://vk.com/gorskinscripts) - полезные сниппеты и мемхаки
* [Pawnokit](https://pawnokit.ru/) - [картинки спецсимволов](https://pawnokit.ru/ru/spec_symbols)
* [KepchiK](https://www.blast.hk/members/229239/) - функции дистанции камеры
  
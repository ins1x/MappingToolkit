# Absolute Event Helper

![logo](https://github.com/ins1x/AbsEventHelper/raw/main/moonloader/resource/abseventhelper/demo.png)

#### ENGLISH
Lua script Assistant for mappers and event makers on [Absolute Play DM](https://sa-mp.ru/) server.   
The main task of this script - is make the mapping process in the in-game map editor as pleasant  
as possible, and to give more opportunities to event organizers.  
Find more about mapping on server at [forum.gta-samp.ru](https://forum.gta-samp.ru/index.php?/topic/1016832-%D0%BC%D0%B8%D1%80%D1%8B-%D0%BE%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D1%8B-%D1%80%D0%B5%D0%B4%D0%B0%D0%BA%D1%82%D0%BE%D1%80%D0%B0-%D0%BA%D0%B0%D1%80%D1%82/).  

> The script partially restores the functionality of the [Samp Addon](https://sa-mp.ru/sampaddon).  

#### RUS
LUA ассистент для мапперов и организаторов мероприятий на сервере [Absolute Play DM](https://sa-mp.ru/).  
Основная задача данного скрипта - сделать процесс маппинга в внутриигровом редакторе карт максимально  
приятным, и дать больше возможностей организаторам мероприятий.  
Больше информации по маппингу на сервере [forum.gta-samp.ru](https://forum.gta-samp.ru/index.php?/topic/1016832-%D0%BC%D0%B8%D1%80%D1%8B-%D0%BE%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D1%8B-%D1%80%D0%B5%D0%B4%D0%B0%D0%BA%D1%82%D0%BE%D1%80%D0%B0-%D0%BA%D0%B0%D1%80%D1%82/).  

> Этот скрипт так же восстанавливает некоторые функции [Samp Addon](https://sa-mp.ru/sampaddon).  

## Возможности
- Удобный графический интерфейс на [imgui](https://www.blast.hk/threads/19292/)
- Информация по лимитам и возможностям редактора карт
- Чат биндер для проведения мероприятий
- Активация горячих клавиш и антиафк без аддона
- Список избранных объектов и эффектов
- Удобный поиск по цветовой палитре
- Удобный поиск транспорта по названию
- Предпросмотр текстур и спецсимволов
- Быстрые заметки 
- Сохранение и спользование точек для телепорта по /тпк
- Чат фильтр подключений/отключений игроков
- Рендер объектов в области стрима
- Таблица игроков в области стрима
- Отключение коллизии у объектов в области стрима
- Отключение различных эффектов дыма, пыли и теней
- Включает некоторые фиксы как в samp addon

## Как использовать
- Установить [Moonloader](https://www.blast.hk/threads/13305/)  
- Установить [SAMPFUNCS](https://www.blast.hk/threads/17/)  
- Скопировать содержимое архива в папку moonloader  

> В игре нажмите ALT + X или введите команду /abshelper

## Зависимости
* lua imgui - https://www.blast.hk/threads/19292/
* lib.samp.events - https://github.com/THE-FYP/SAMP.Lua

Протестировано на *SA-MP 0.3.7-R1, Moonloader 0.26, sampfuncs 5.4.1-final*  
Скрипт будет работать и на других версиях клиента, основные меню и функции универсальны  
Но функции работающие с памятью игры могут неккоректно работать, imgui конфликтует с [ENB](http://enbdev.com/download_mod_gtasa.htm)  

## Credits 
* [EvgeN 1137](https://www.blast.hk/members/1), [hnnssy](https://www.blast.hk/members/66797), [FYP](https://github.com/THE-FYP) - Moonloader  
* [FYP](https://github.com/THE-FYP) - imgui, SAMP lua библиотеки
* [Gorskin](https://vk.com/gorskinscripts) - полезные сниппеты и мемхаки
* [Pawnokit](https://pawnokit.ru/) - [картинки спецсимволов](https://pawnokit.ru/ru/spec_symbols)

## Disclaimer
Автор не является оффициальным представителем, разработчиком либо частью команды проекта Absolute Play.  
Скрипт не заменяет samp addon, не использует его возможности, и не копирует его функционал.  
Фиксы как в samp addon были подобраны из открытых источников, и не являются результатом реверса samp addon.  
  
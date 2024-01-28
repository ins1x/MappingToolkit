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
Больше информации по маппингу и редактору карт на сервере [forum.gta-samp.ru](https://forum.gta-samp.ru/index.php?/topic/1016832-%D0%BC%D0%B8%D1%80%D1%8B-%D0%BE%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5-%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D1%8B-%D1%80%D0%B5%D0%B4%D0%B0%D0%BA%D1%82%D0%BE%D1%80%D0%B0-%D0%BA%D0%B0%D1%80%D1%82/).   

> Рекомендуется использовать совместно с [AbsoluteFix](https://github.com/ins1x/AbsoluteFix)

## Возможности

### Координаты
- Отображение координат игрока, его направления, и метки в ESC
- Определение местности и района в котором вы находитесь
- Сохранение текущих координат и телепорт к сохраненным
- Отображение координат текущего объекта
- Расстояние до метки на карте, и сохраненной позиции
- Провалиться под текстуры, либо вернуться на ближайшую поверхность
- Спавн, респавн, наблюдение, заморозка, разворозка
- Плавный и быстрый телепорт по координатам

### Стрим
- Подсчет игроков, транспорта и объектов в области стрима
- Рестрим
- Изменение прорисовки и дистанции тумана
- Скрытие либо изменение прорисовки NameTags
- Скрытие 3D текстов

### Камера
- Отображение координат камеры
- Управление дистанцией камеры игрока
- Установка фиксированной камеры по заданным значениям
- Изменение FOV (Field of View)
- Возврат и разблокировка камеры
- Переключение HUD

### Объекты
- Список большинства необходимых и часто используемых объектов и эффектов
- Сохранение списка ваших избранных объектов в файл
- Рендер объектов в области стрима
- Предпросмотр текущих координат объекта при перемещении
- Сохранение ид модели последнего объекта
- Отключение коллизии у объектов в области стрима
- Удаление объекта из стрима по модели
- Телепорт к текущему объекту
- Если последний объект не найден, выведет ид последнего редактируемого объекта
- Поиск объекта по имени через сайт https://dev.prineside.com
- Поиск объекта рядом по позиции через сайт https://dev.prineside.com
- Проверка на багнутые объекты, предупреждение при их использовании

### Информация
- Информация по возможностям редактора карт Absolute Play
- FAQ по редактору карт с часто задаваемыми вопросами и ошибками
- Удобный поиск по цветовой палитре RGB
- Информация по стандартным лимитам SAMP и редактора карт
- Информация по командам редактора, клиента, и сервера
- Предпросмотр текстур и спецсимволов
- Список прозрачных поверхностей для ретекстура с сортировкой по размеру

### Мероприятия
- Чат биндер для проведения мероприятий
- Готовые профили мероприятий для биндера
- Таблица игроков в стриме с подробной информацией
- Сохранение списка игроков на мероприятии в файл
- Меню для быстрого управления игроками в мире
- Шаблоны для быстрых ответов игрокам
- Выбор случайного игрока, либо игрока с наибольшем уровнем
- Сообщение если из таблицы игроков кто-то вылетел или вышел из игры
- Удобный поиск транспорта по названию
- Таблица со списком транспорта в стриме
- Вызов транспорта по имени

### Прочее
- Обработка некоторых частых ошибок в мире и вывод уведомлений
- Изменение погоды и времени + доступны различные пресеты
- Для разработчиков логгирование текстдравов, диалогов и пикапов
- В читмире нв абсолюте включаются доп опции для респавна и выбора класса
- Отображение id текстдравов и диалогов (опционально)
- При редактировании текста либо выборе цвета копирует рандом цвет из диалога
- Удобный интерфейс для поиска в логах включая сайт AbsolutePlay
- Исправление некторых багов редактора карт на Absolute Play

> [DEMO на YouTube](https://www.youtube.com/watch?v=Okwpc8DcLo4)

## Требования
- Вам потребуется рабочая копия игры GTA San Andreas с верисей gta_sa.exe v1.0 US
- [Клиент SA-MP версии 0.3.7 R1](https://samp.romzes.com/files/sa-mp-0.3.7-install.exe)
- [ASI Loader](https://www.gtagarage.com/mods/show.php?id=21709)
- [CLEO 4.1](https://cleo.li/ru) 
- [Moonloader 0.26](https://www.blast.hk/threads/13305/)  
- [SAMPFUNCS 5.4.1](https://www.blast.hk/threads/17/)

Зависимости Moonloader:
* lua imgui - https://www.blast.hk/threads/19292/
* lib.samp.events - https://github.com/THE-FYP/SAMP.Lua

## Как использовать
* Скопировать содержимое архива AbsEventHelper.zip в папку moonloader в корне игры
* Запустить GTA. В игре нажмите **ALT + X** или введите команду /abshelper
* Если скрипт не запустился, в папке moonloader есть файл moonloader.log с информацией о проблеме

## О поддержке Samp Addon 
Скрипт *не работает с включенным античитом* Samp Addon, так как разработчик аддона фильтрует все скрипты
по белому списку. А так же на Абсолютовской версии SAMPFUNCS DL. Категорически не рекомендуется использовать этот скрипт вне виртуального мира и редактора карт!  

---------------------------------------------

blasthk: https://www.blast.hk/threads/200619/  
git: https://github.com/ins1x/AbsEventHelper/  
forum: https://forum.gta-samp.ru/index.php?/topic/1101593-absolute-event-helper/  
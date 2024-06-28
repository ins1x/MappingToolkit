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

> Для **Absolute Play** рекомендуется использовать совместно с [AbsoluteFix](https://github.com/ins1x/moonloader-scripts/tree/main/absolutefix)

## Возможности
Ассистент дает вам больше возможностей для маппинга и разработки ваших проектов. Функционал достаточно обширен, и регулярно обновляется. Для управления всеми возможностями предоставлен удобный графического интерфейс на [imgui](https://www.blast.hk/threads/19292/). Ассистент предоставляет дополнительные функции для работы с текстурами и объектами, исправляет некоторые баги игры, дополняет серверные команды и диалоги. 

На текущий момент поддерживаются все сервера [Absolute Play](https://sa-mp.ru/) и [TRAINING SANDBOX](https://training-server.com/). Может работать и на других проектах, но часть функционала будет недоступна. Перед его использованием убедитесь что его функционал не запрещен на вашем сервере! 

### Мероприятия
- Удобные меню для подготовки, управления и завершения МП
- Отображение текущего сервера, времени и времени запуска МП
- Авто-отправка всех заданных правил в чат
- Авто-анонс мероприятия в объявления
- Сохранение списка игроков на мероприятии (даже при вылете список игроков у вас сохранится в папке со скриптом)
- Шаблоны для быстрых ответов игрокам /ответ
- Выбор капитанов из случайного игрока, либо игрока с наибольшим уровнем
- Возможность указать спонсоров мероприятия
- Сообщение если из таблицы игроков кто-то вылетел или вышел из игры
- Статистика по игрокам онлайн
- Черный список игроков
- Быстрые команды с биндами для МП
- Проверка игроков (поиск афкашников, лагеров, с оружием и.т.д)
- Меню для быстрого управления игроками в мире
- Варнинги на подозрительных игроков (лагеры, с нелегальным оружием, пополнение хп и брони, нахождение под текстурами)

### Объекты
- Список большинства необходимых и часто используемых объектов и эффектов
- Сохранение списка ваших избранных объектов в файл
- Рендер объектов в области стрима (отображение modelid объектов)
- Рендер-линейка по условию с указанием дистанции (по модели объекта)
- Предпросмотр текущих координат объекта при перемещении
- Сохранение ид модели последнего объекта
- Сохранение последней выбранной текстуры
- Отключение коллизии у объектов в области стрима
- Удаление объекта из стрима по модели
- Маркер на последний объект
- Телепорт к последнему объекту /ogoto
- Скрыть либо показать последний объект
- Изменение дистанции прорисовки объектов по ид модели
- Изменение масштаба объекта (визуально)
- Если последний объект не найден, выведет ид последнего редактируемого объекта
- Поиск объекта по имени через сайт https://dev.prineside.com
- Поиск объекта рядом по позиции через сайт https://dev.prineside.com
- Проверка на багнутые объекты, предупреждение при их использовании
- Отображение индексов материалов объекта /sindex
- Смена цвета для объекта /ocolor
- Сделать объект полупрозрачным /oalpha

### Информация
- Информация по возможностям редактора карт Absolute Play и TRAINING
- FAQ по редактору карт с часто задаваемыми вопросами и ошибками
- Удобный поиск по цветовой палитре RGB
- Информация по стандартным лимитам SAMP, GTA, и редактора карт
- Информация по командам редактора, клиента, чата и сервера
- Список прозрачных поверхностей для ретекстура с сортировкой по размеру
- Список наиболее часто используемых текстур
- /osearch - поиск объектов по части названия
- Просмотр характеристик транспорта
- Удобный поиск транспорта по названию

### Координаты
- Отображение координат игрока, его направления, и метки в ESC
- Определение местности и района в котором вы находитесь
- Сохранение текущих координат и телепорт к сохраненным (/savepos, /gopos)
- Отображение координат текущего объекта
- Расстояние до метки на карте, и сохраненной позиции
- Возможность провалиться под текстуры, либо вернуться на ближайшую поверхность
- Телепорт по координатам для редакторов (системный - не чит)
- Пошаговый телепорт для редакторов (системный - не чит)

### Чат
- Скрытие глобального чата
- Уведомления при упоминании в чате по ид либо нику
- Возможность останавливать чат при открытом поле ввода
- Очистка чата для себя
- Копирование ид и никнеймов игроков рядом в чат
- Быстрое открытие чатлога
- Антикапс для всех сообщений в чате
- Копирование последнего кликнутого по TAB игрока в буффер
- Копирование ников и ид игроков рядом
- Скрытие IP адресов игроков
- Вы можете фильтровать чат по списку правил (chatfilter.txt)

### Дополнения для Absolute Play
- Обработка некоторых частых ошибок в мире и вывод уведомлений
- При редактировании текста либо выборе цвета копирует рандом цвет из диалога
- Удобный интерфейс для поиска в логах включая сайт AbsolutePlay
- Исправление некоторых багов редактора карт на Absolute Play
- Фикс горячих клавиш редактора карт (работают как с аддоном)
- Фикс переключения текстдравов при выборе объектов
- При смене текстуры выводит название текстур
- Сохраняет последнюю использованную текстуру
- Дополнение информации в некоторых диалогах на Absolute Play
- Информация по доступным на Absolute Play шрифтам
- Информация по доступным на Absolute Play текстурам
- /tsearch - поиск текстуры по части названия (только среди доступных на сервере)

### Дополнения для TRAINING
- Авто-скип диалога правил при входе на сервер
- Авто-установка времени и погоды при входе в мир
- Бинд основных меню /world и /vw на клавишу ` M `
- Бинд редактирования объекта на клавишу ` N `
- Бинд закрытия-открытия транспорта на клавишу ` L ` и тюнинг меню на `H + N`
- Антикапс для ADS объявлений в чате (опционально)
- При вводе /oedit, /osel, /ogh без параметров (id), будет указан последний объект
- При вводе /oadd без параметров будет выводиться modelid последнего объекта
- Дополнено меню редактирования объектов различными опциями (/omenu)
- Дополнено основное меню /vw и меню игрока /menu
- Исправление различных мелких багов сервера 
- Напоминание о необходимости сохранить мир (опционально)
- Список всех командных блоков с описанием
- Меню для управления игроками в мире
- Режим разработчика включается автоматически при создании мира
- При использовании /texture /stexture /tsearch без параметров выведет последнюю использованную текстуру
- /cbsearch <TEXT> поиск информации по командным блокам
- /tlist показывает список использованных текстур за текущую сессию
- /tpaste <id> применить последнюю текстуру на объект
- При вводе /cb автоматически поставит в поле ввода радиус 0.1
- /otext при смене цвета приведет примеры цветов
- /saveworld, /loadworld - сохранить/загрузить мир командой

### Прочее
- Изменение погоды и времени + доступны различные пресеты
- Управление различными эффектами игры и полное их отключение
- Управление дистанцией камеры игрока (без полета камерой)
- Отображение координат и установка фиксированной камеры по заданным значениям
- Изменение FOV (Field of View)
- Возврат и разблокировка камеры
- Переключение HUD
- Изменение дистанции тумана и дальности прорисовки объектов
- Скрытие NameTags и 3D текстов
- Рестрим (только для Absolute Play и Training)
- Таблица игроков в стриме с подробной информацией
- Таблица со списком транспорта в стриме
- Таблица со списком объектов в области стрима
- Нижняя панель с отображением необходимой информации (опционально)
- В режиме стримера скрывает IP адреса игроков в чате, моб.телефоны в чате, ваши пароли и секретки в диалогах

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

<!--- [![blast.hk](https://img.shields.io/badge/Homepage-blasthk-blue)](https://www.blast.hk/threads/200619/) --> 
[![forum absolute](https://img.shields.io/badge/Forum-Absolute_Play-red)](https://forum.gta-samp.ru/index.php?/topic/1101593-mapping-toolkit/)
[![forum training](https://img.shields.io/badge/Forum-TRAINING_SANDBOX-yellow)](https://forum.training-server.com/d/19708-luamappingtoolkit/)
[![github](https://img.shields.io/badge/Wiki-Github-black)](https://github.com/ins1x/MappingToolkit/wiki)
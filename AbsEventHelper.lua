script_author("1NS")
script_name("Absolute Events Helper")
script_description("Assistant for mappers and event makers on Absolute DM")
script_dependencies('imgui', 'lib.samp.events', 'vkeys', 'memory')
script_url("vk.com/1nsanemapping")
script_version("0.2")
local hostip = "193.84.90.23"

require 'lib.moonloader'
local keys = require 'vkeys'
local tag = "{00BFFF}Absolute {FFD700}Events {FFFFFF}Helper"
local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
font = renderCreateFont("Arial", 8, 5)
 
local sizeX, sizeY = getScreenResolution()
local main_window_state = imgui.ImBool(false)
local moonloaderVersion = getMoonloaderVersion()
local v = nil

local show_favorites = imgui.ImBool(false)
local show_credits = imgui.ImBool(false)
local show_hotkeys = imgui.ImBool(false)
local show_settings = imgui.ImBool(false)
local show_colors = imgui.ImBool(false)
local show_worldlimits = imgui.ImBool(false)
local show_effects = imgui.ImBool(false)
local show_info = imgui.ImBool(false)
local show_chatfucns = imgui.ImBool(false)

local checkbox_chatfilter = imgui.ImBool(true)
local checkbox_antiafk = imgui.ImBool(true)
local checkbox_keybinds = imgui.ImBool(true)
local checkbox_showobjects = imgui.ImBool(false)

local sliderdrawdist = imgui.ImInt(450)
local sliderfog = imgui.ImInt(200)
local bind_textbuffer1 = imgui.ImBuffer(256)
local bind_textbuffer2 = imgui.ImBuffer(256)
local bind_textbuffer3 = imgui.ImBuffer(256)
local bind_textbuffer4 = imgui.ImBuffer(256)
local bind_textbuffer5 = imgui.ImBuffer(256)
local bind_adtextbuffer = imgui.ImBuffer(256)

bind_adtextbuffer.v = u8'Заходите на МП "Название МП" в мир , приз ничего'
bind_textbuffer2.v = u8"Кто будет мешать проведени и драться - кикну"
bind_textbuffer3.v = u8"Не тупим разбегаемся по карте"
bind_textbuffer4.v = u8"Запрещено использовать текстурыне баги"
bind_textbuffer5.v = u8"Запрещено объеденяться больше двух игроков"
		  
local color = imgui.ImFloat4(1, 0, 0, 1)
local antiafk = true
local chatfilter = true
local keybinds = true
local effects = true
local disablealleffects = false
local fps = 0
local fps_counter = 0
local showobjects = false
local tpposX, tpposY, tpposZ

local function starts_with(str, start)
   return str:sub(1, #start) == start
end 

-- imgui
function imgui.OnDrawFrame()
   if main_window_state.v then
      imgui.SetNextWindowSize(imgui.ImVec2(440, 400), imgui.Cond.FirstUseEver)
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin("Absolute Events Helper", main_window_state)
	  
	  if imgui.Button(u8"Информация") then
		 show_info.v = not show_info.v
	  end
	  
	  imgui.SameLine()
	  if imgui.Button(u8"Горячие клавиши") then
		 show_hotkeys.v = not show_hotkeys.v
	  end
	
	  imgui.SameLine()
	  if imgui.Button(u8"Настройки") then
		 show_settings.v = not show_settings.v
	  end
	  
	  imgui.SameLine()
	  if imgui.Button(u8"О скрипте") then
		 show_credits.v = not show_credits.v
	  end
	  
	  imgui.SameLine()
	  if imgui.Button(u8"Скрыть") then
		 main_window_state.v = not main_window_state.v 
      end
	    
	  --local id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	  --local nickname = sampGetPlayerNickname(id)
	  local servername = sampGetCurrentServerName()
	  imgui.Text(string.format(u8"Сервер: %s", servername))
	
	  local positionX, positionY, positionZ = getCharCoordinates(PLAYER_PED)
	  imgui.Text(string.format(u8"Позиция x: %.1f, y: %.1f, z: %.1f Интерьер: %i",
	  positionX, positionY, positionZ, getActiveInterior()))
	  
	  imgui.Text(string.format(u8"Направление: %s", direction()))
	  imgui.Text(string.format(u8"FPS: %i", fps))
	  
	  local streamedplayers = sampGetPlayerCount(true) - 1
	  imgui.Text(string.format(u8"Игроков в стриме: %i Транспорта: %i",
	  streamedplayers, getVehicleInStream()))
	  
	  local closestcarid = getClosestCarId()
	  imgui.Text(string.format(u8"Ближайший транспорт: %i", closestcarid))
	  
	  imgui.SameLine()
	  if imgui.Button(u8"Заказать машину") then
	     if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/vfibye2") end
	  end
	  
	  imgui.SameLine()
	  if imgui.Button(u8"Флип") then
	      if isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/f") end
		  --if isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsCursorActive() then
		  --if isKeyDown(VK_DELETE) then
		  --		addToCarRotationVelocity(storeCarCharIsInNoSave(PLAYER_PED), 0.0, -0.15, 0.0)
		  -- elseif isKeyDown(VK_END) then
		  --	addToCarRotationVelocity(storeCarCharIsInNoSave(PLAYER_PED), 0.0, 0.15, 0.0)
		  -- end
		  --end
	  end
	  
	  imgui.Separator()
	  -----------------------------------------------------------------------
	  
	  imgui.Text(u8"615-18300 [GTASA], 18632-19521 [SAMP]")
	  if imgui.Button(u8"Избранные объекты") then
		 show_favorites.v = not show_favorites.v
	  end
	  
	  imgui.SameLine()
	  if imgui.Button(u8"Эффекты") then
		 show_effects.v = not show_effects.v
	  end
	  
	  imgui.SameLine()
	  imgui.Checkbox(u8("Показывать ID объектов рядом"), checkbox_showobjects)
	  if checkbox_showobjects.v then
		 if not showobjects then 
		    showobjects = true
		 end
	  end
	  
	  imgui.Separator()
	  -----------------------------------------------------------------------
	  
	  imgui.Text(" ")
	  if imgui.Button(u8"Получить координаты", imgui.ImVec2(250, 20)) then
	     if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
		    sampSendChat("/коорд")
			tpposX, tpposY, tpposZ = getCharCoordinates(PLAYER_PED)
			sampAddChatMessage("Координаты сохранены", 0x0FFFFFF)
		 end
	  end
	  
	  if imgui.Button(u8"Телепорт по кординатам", imgui.ImVec2(250, 20)) then
	     --sampSendChat("/тпк " .. tpposX, tpposY, tpposZ, 0x0FFFFFF)
		 if tpposX then
	        sampSendChat(string.format("/ngr %f %f %f", tpposX, tpposY, tpposZ), 0x0FFFFFF)
		    sampAddChatMessage(string.format("Вы были телепортированны на сохранненые координаты %f %f %f"
			,tpposX, tpposY, tpposZ), 0x0FFFFFF)
		 else
		    sampAddChatMessage("Координаты не были сохранены. Нажмите коорд", 0x0FFFFFF)
		 end
	  end
	  
	  if imgui.Button(u8"Прыгнуть вперед", imgui.ImVec2(250, 20)) then
		 if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/ghsu") end
	  end
	  
	  if imgui.Button(u8"Чат", imgui.ImVec2(250, 20)) then
	     show_chatfucns.v = not show_chatfucns.v
	  end
	  
      imgui.End()
   end
   
   if show_info.v then
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 6),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
      imgui.Begin(u8"Информация", show_info)
	  
	  if imgui.Button(u8"Лимиты", imgui.ImVec2(200, 20)) then
		 show_worldlimits.v = not show_worldlimits.v
	  end
	  
	  if imgui.Button(u8"Цвета", imgui.ImVec2(200, 20)) then
		 show_colors.v = not show_colors.v
	  end
	  
      imgui.End()
   end
	
   if show_favorites.v then
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 8, sizeY / 4),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
      imgui.Begin(u8"Избранные", show_favorites)
      imgui.Text(u8"Большие прозрачные объекты для текста: 19481, 19480, 19482, 19477")
      imgui.Text(u8"Маленькие объекты для текста: 19476, 2662")
      imgui.Text(u8"Бетонные блоки: 18766, 18765, 18764, 18763, 18762")
      imgui.Text(u8"Горы: вулкан 18752, песочница 18751, песочные горы ландшафт 19548")
      imgui.Text(u8"Платформы: тонкая платформа 19552, 19538, решетчатая 18753, 18754")
      imgui.Text(u8"Стены: 19355, 19435(маленькая), 19447(длинная), 19391(дверь), 19408(окно)")
	  imgui.Separator()
	  imgui.TextColoredRGB("Не нашли нужный объект? посмотрите на {007DFF}dev.prineside.com")
      imgui.End()
   end
	
   if show_effects.v then	  
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 8, sizeY / 4),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
      imgui.Begin(u8"Эффекты", show_effects)
	  imgui.Text(u8"Огонь большой 18691, средний огонь 18692, пламя+дым (исчезает) 18723")
	  imgui.Text(u8"Огонь от огнемета 18694, огонь от машины 18690")
	  imgui.Text(u8"Пар от вентиляции 18736, дым от сигареты 18673, дым с фабрики 18748")
	  imgui.Text(u8"Белый дым 18725, черный дым 18726, большой серый дым 18727")
	  imgui.Text(u8"Большой взрыв 18682, средний взрыв 18683, маленький взрыв 18686")
	  imgui.Text(u8"Спрей 18729, кровь 18668, огнетушитель 18687, слезоточивый 18732")
	  imgui.Text(u8"Рябь на воде 18741, брызги воды 18744")
	  imgui.Text(u8"Фонтан 18739, гидрант 18740")
      imgui.Text(u8"Искры 18717, горящие дрова 19632")
      imgui.Text(u8"Неон красный 18647, синий 18648, зеленый 18649")
	  imgui.Text(u8"Неон желтый 18650, розовый 18651, белый 18652")
      imgui.Text(u8"Сигнальный огонь 18728, нитро 18702, флейм 18693")
	  
	  imgui.Separator()
	  if imgui.Button(u8"Отключить дым из труб и прочие эффекты факелов и дыма",
	  imgui.ImVec2(450, 20)) then
		 effects = not effects
		 if effects then
            memory.hex2bin('8B4E08E88B900000', 0x4A125D, 8)
		 else 
		    memory.fill(0x4A125D, 0x90, 8, true)
		 end
	  end 
	  
	  -- nop all effects render
	  if imgui.Button(u8"Отключить все эффекты (вернуть обратно только релогом)", imgui.ImVec2(450, 20)) then
		 if not disablealleffects then
	        memory.fill(0x53EAD3, 0x90, 5, true)
			disablealleffects = true
		 end
	  end
	  
      imgui.End()
	end
	
	if show_colors.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 6, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   
       imgui.Begin(u8"Цветовая палитра", show_colors)
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
	   imgui.Button("{FF0000}  RED    ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.0, 1.0))
	   imgui.Button("{008000}  GREEN ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 1.0, 1.0))
	   imgui.Button("{0000FF}  BLUE  ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 0.0, 1.0))
	   imgui.Button("{FFFF00}  YELLOW", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 1.0, 1.0))
	   imgui.Button("{FF00FF}  PINK  ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 1.0, 1.0))
	   imgui.Button("{00FFFF}  AQUA  ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 0.0, 1.0))
	   imgui.Button("{00FF00}  LIME  ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.5, 1.0))
	   imgui.Button("{800080}  PURPLE", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.0, 1.0))
	   imgui.Button("{800000}  MAROON", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.0, 1.0))
	   imgui.Button("{808000}  OLIVE ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.5, 1.0))
	   imgui.Button("{008080}  TEAL  ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.6, 0.0, 1.0))
	   imgui.Button("{FF9900}  ORANGE", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.89, 0.76, 1.0))
	   imgui.Button("{FFE4C4}  BISQUE", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
	   imgui.Button("{FFFFFF}  WHITE ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
	   imgui.Button("{000000}  GREY  ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
	   imgui.Button("{000000}  BLACK ", imgui.ImVec2(300, 20))
	   imgui.PopStyleColor()
	   
	   imgui.TextColoredRGB("Другие цвета {007DFF}https://encycolorpedia.ru/websafe")
	   
	   imgui.Text(u8"RR — красная часть цвета, GG — зеленая, BB — синяя, AA — альфа")
	   imgui.ColorEdit4("", color)
	   imgui.SameLine()
	   imgui.Text("HEX: " ..intToHex(join_argb(color.v[4] * 255, color.v[1] * 255,
	   color.v[2] * 255, color.v[3] * 255)))
	   
	   imgui.End()
	end
	
	if show_chatfucns.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 6, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   imgui.SetNextWindowSize(imgui.ImVec2(440, 350), imgui.Cond.FirstUseEver)
	   imgui.Begin(u8"Чат", show_chatfucns)
	   
	   imgui.Text(u8"Здесь вы можете настроить чат-бинды для мероприятия")
	   
	   if imgui.InputText("##Bind1", bind_textbuffer1) then 
		  --bind_textbuffer1 = u8:decode(bind_textbuffer1.v)
		  --u8:decode(bind_textbuffer1.v)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [1]") then
	      u8:decode(bind_textbuffer1.v)
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer1.v)))
	   end
	   
	   if imgui.InputText("##Bind2", bind_textbuffer2) then 
		  --u8:decode(bind_textbuffer2.v)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [2]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer2.v)))
	   end
	   
	   if imgui.InputText("##Bind3", bind_textbuffer3) then 
		  --u8:decode(bind_textbuffer2.v)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [3]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer3.v)))
	   end
	   
	   if imgui.InputText("##Bind4", bind_textbuffer4) then 
		  --u8:decode(bind_textbuffer2.v)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [4]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer4.v)))
	   end
	   
	   if imgui.InputText("##Bind5", bind_textbuffer5) then 
		  --u8:decode(bind_textbuffer2.v)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [5]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer5.v)))
	   end
	   
	   imgui.Text(" ")
	   if imgui.InputText("##BindAd", bind_adtextbuffer) then 
		  --u8:decode(bind_textbuffer2.v)
	   end
	   
	   if imgui.Button(u8"Дать объявление в общий чат") then
	      sampSendChat(string.format("* %s", u8:decode(bind_adtextbuffer.v)))
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Дать объявление в /об") then
	      sampSendChat(string.format("/об %s", u8:decode(bind_adtextbuffer.v)))
	   end
	   
	   imgui.Text(" ")
	   imgui.Separator()
	   
	   if imgui.Button(u8"Очистить все бинды") then
	      bind_textbuffer1.v = " "
	      bind_textbuffer2.v = " "
	      bind_textbuffer3.v = " "
	      bind_textbuffer4.v = " "
	      bind_textbuffer5.v = " "
		  bind_adtextbuffer.v = " "
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Очистить себе чат") then
		  memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
          memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
          memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
	   end
	
	   imgui.End()
	end
	   
	if show_hotkeys.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
       imgui.Begin(u8"Горячие клавиши", show_hotkeys)
	   
	   imgui.TextColoredRGB("Доступные только с {FF0000}SAMP ADDON:")
       imgui.TextColoredRGB("{00FF00}Клавиша N{FFFFFF} — меню редактора карт (в полете)")
       imgui.TextColoredRGB("{00FF00}Клавиша J{FFFFFF} — полет в наблюдении (/полет)")
       imgui.TextColoredRGB("{00FF00}Боковые клавиши мыши{FFFFFF} — отменяют и сохраняют редактирование объекта")
       imgui.Text(" ")
       imgui.TextColoredRGB("В режиме редактирования:")
       imgui.TextColoredRGB("{00FF00}Зажатие клавиши ALT{FFFFFF} — скрыть объект")
       imgui.TextColoredRGB("{00FF00}Зажатие клавиши CTRL{FFFFFF} — визуально увеличить объект")
       imgui.TextColoredRGB("{00FF00}Зажатие клавиши SHIFT{FFFFFF} — плавное перемещение объекта")
       imgui.TextColoredRGB("{00FF00}Клавиша RMB (Правая кл.мыши){FFFFFF}  — вернуть объект на исходную позицию")
       imgui.TextColoredRGB("{00FF00}Клавиша Enter{FFFFFF}  — сохранить редактируемый объект")
       imgui.Text(" ")
       imgui.TextColoredRGB("В режиме выделения:")
       imgui.TextColoredRGB("{00FF00}Клавиша RMB (Правая кл.мыши){FFFFFF}  — скопирует номер модели объекта")
       imgui.TextColoredRGB("{00FF00}Клавиша SHIFT{FFFFFF} — переключение между объектами")
       imgui.Text(" ")
	   imgui.Text(u8"Восстановленые скриптом и доступные без SAMP ADDON:")
       imgui.TextColoredRGB("{00FF00}J{FFFFFF} - полет в мире")
       imgui.TextColoredRGB("{00FF00}Z{FFFFFF} - починить транспорт")
       imgui.TextColoredRGB("{00FF00}U{FFFFFF} - анимации")
       imgui.TextColoredRGB("{00FF00}M{FFFFFF} - домашний транспорт")
       imgui.TextColoredRGB("{00FF00}K{FFFFFF} - заказать транспорт")
       imgui.TextColoredRGB("{00FF00}H{FFFFFF} - перевернуть транспорт")
	   imgui.Separator()
	   imgui.Text(u8"Если у вас установлен SAMP ADDON вы можете отключить фикс горячих клавиши в настройках")
       imgui.End()
	end
	
    if show_worldlimits.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 10, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
       imgui.Begin(u8"Лимиты", show_worldlimits)
	   imgui.Text(u8"Каждый игрок от 20 уровня может при наличии свободных слотов создать свой мир для строительства.")
	   imgui.Text(u8"Если все слоты уже были заняты, вы можете воспользоваться любым открытым миром.")
	   imgui.TextColoredRGB("Для создания мира необходимо иметь {00FF00}100 ОА (Очков апгрейда) и 1.000.000$.{FFFFFF}")
       imgui.TextColoredRGB("По умолчанию в мире можно создавать только {00FF00}50 объектов, лимит можно расширить до {00FF00}300{FFFFFF}.")
	   imgui.TextColoredRGB("VIP игроки могут расширять лимит до {00FF00}2000 объектов.{FFFFFF}")
	   imgui.TextColoredRGB("Стоимость расширения мира {00FF00}20 ОА и 500.000$ за 10 объектов.{FFFFFF}") 
	   imgui.TextColoredRGB("Максимальное количество созданных миров {00FF00}500{FFFFFF}.")
	   imgui.TextColoredRGB("При отсутствии на сервере {FF0000}90 дней мир удаляется{FFFFFF}")
	   imgui.Separator()
       imgui.Text(u8"Лимиты в мире")
       imgui.TextColoredRGB("макс. объектов: {00FF00}300 (VIP 2000)")
       imgui.TextColoredRGB("макс. объектов в одной точке: {00FF00}200 ")
       imgui.TextColoredRGB("макс. пикапов: {00FF00}500")
       imgui.TextColoredRGB("макс. маркеров для гонок: {00FF00}40")
       imgui.TextColoredRGB("макс. транспорта: {00FF00}50")
       imgui.TextColoredRGB("макс. слотов под гонки: {00FF00}5")
       imgui.TextColoredRGB("макс. виртуальных миров: {00FF00}500")
	   imgui.Separator()
	   imgui.Text(u8"В радиусе 150 метров нельзя создавать более 200 объектов.")
	   imgui.Text(u8"Максимальная длина текста на объектах в редакторе миров - 50 символов")
       imgui.End()
	end
	
	if show_settings.v then	  
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	 
       imgui.Begin(u8"Настройки", show_settings)
       imgui.Checkbox(u8("Фильтр подключений в чате"), checkbox_chatfilter)
	   if checkbox_chatfilter.v then
	      chatfilter = not chatfilter
       end
	  
   	   imgui.Checkbox(u8("Анти-афк"), checkbox_antiafk)
	   if checkbox_antiafk.v then
	      antiafk = not antiafk
	   end
		
	   imgui.Checkbox(u8("Фикс горячих клавиш"), checkbox_keybinds)
	   if checkbox_keybinds.v then
	      keybinds = not keybinds
	   end
	   
	   -- Thanks samp++
	   -- imgui.Text(u8"Дальность прорисовки:")
	   -- if imgui.SliderInt(u8"##Drawdist", sliderdrawdist, 50, 3000) then
		  -- sliderdrawdist = sliderdrawdist.v
		  -- memory.setfloat(12044272, sliderdrawdist, true)
	   -- end
		
		-- imgui.Text(u8"Дальность тумана:")
		-- if imgui.SliderInt(u8"##fog", sliderfog, -390, 390) then
		   -- sliderfog = sliderfog.v
		   -- memory.setfloat(13210352, sliderfog, true)
		-- end
			
       imgui.End()
	end
	
	if show_credits.v then	  
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   
       imgui.Begin(u8"О скрипте", show_credits)
       imgui.Text(u8"Автор: 1NS (Git: in1x)")
	   --imgui.Text(string.format(u8"Demo version: %s", os.date("%x")))
       imgui.Text(u8"Помошник для мапперов и организаторов мероприятий на Absolute DM")
       imgui.Text(u8"Homepage: Русскоязычное сообщество мапперов: vk.com\1nsanemapping")
       imgui.Text(u8"Credits:")
       imgui.Text(u8"FYP - imgui and SAMP lua library")
       imgui.Text(u8"MOL - antiafk")
       imgui.Text(u8"Gorskin - useful memory hacks")
       imgui.End()
	end
	
end

function main()
   if not isSampLoaded() or not isSampfuncsLoaded() then return end
      while not isSampAvailable() do wait(100) end
	  sampAddChatMessage("" .. tag, 0xFFFFFF)
	  local ip, port = sampGetCurrentServerAddress()
	  if not ip:find(hostip) then
	     keybinds = false
	     -- sampAddChatMessage("Keybinds work only Absolute DM", 0x00FF0000)
	  end
	  while true do
	  wait(0)
	  
	  -- Imgui menu
	  imgui.Process = main_window_state.v
	  
	  -- chatfilter
	  function sampev.onServerMessage(color, text)
		if chatfilter then 
			--if starts_with(text, "Игрок") then
			if text:find("подключился к серверу") or text:find("вышел с сервера") then
				chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
				chatlog:write(os.date("[%H:%M:%S] ")..text)
				chatlog:write("\n")
				chatlog:close()
				return false
			end
		end
	  end
		
	  -- chatfix
	  if isKeyJustPressed(0x54) and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
	     sampSetChatInputEnabled(true)
	  end
	  
	  -- antiafk 
      if antiafk then
         writeMemory(7634870, 1, 1, 1)
         writeMemory(7635034, 1, 1, 1)
         memory.fill(7623723, 144, 8)
         memory.fill(5499528, 144, 6)
	  end
	  
	  -- Absolute Play Key Binds
	  -- Sets hotkeys that are only available with the samp addon
	  if keybinds then
         if isKeyJustPressed(VK_Z) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/xbybnm") end
	 
         if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/vfibye2") end

         if isKeyJustPressed(VK_M) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/vfibye") end
	  
         if isKeyJustPressed(VK_U) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/anim") end
	  
         if isKeyJustPressed(VK_J) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/gjktn") end
	  
         if isKeyJustPressed(VK_H) and isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/f") end
	   
         --if isKeyJustPressed(VK_N) and not sampIsChatInputActive() and not sampIsDialogActive() and not --isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendDialogResponse(1422, 0, 0, " --") end
      end
	  
      if isKeyJustPressed(VK_X) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
         if showobjects then showobjects = false end
		 main_window_state.v = not main_window_state.v 
      end
	  
	  sampRegisterChatCommand("abshelp", function ()
         main_window_state.v = not main_window_state.v 
	  end)
	  
	  if showobjects then
	     for _, v in pairs(getAllObjects()) do
		    if isObjectOnScreen(v) then
			   local _, x, y, z = getObjectCoordinates(v)
			   local x1, y1 = convert3DCoordsToScreen(x,y,z)
			   local model = getObjectModel(v)
			   renderFontDrawText(font, "{80FFFFFF}" .. model, x1, y1, -1)
			end
		 end
	  end
		
   end
end

function direction()
   if sampIsLocalPlayerSpawned() then
      local angel = math.ceil(getCharHeading(PLAYER_PED))
      if angel then
         if (angel >= 0 and angel <= 30) or (angel <= 360 and angel >= 330) then
            return u8"Север"
         elseif (angel > 80 and angel < 100) then
            return u8"Запад"
         elseif (angel > 260 and angel < 280) then
            return u8"Восток"
         elseif (angel >= 170 and angel <= 190) then
            return u8"Юг"
         elseif (angel >= 31 and angel <= 79) then
            return u8"Северо-запад"
         elseif (angel >= 191 and angel <= 259) then
            return u8"Юго-восток"
         elseif (angel >= 81 and angel <= 169) then
            return u8"Юго-запад"
         elseif (angel >= 259 and angel <= 329) then
            return u8"Северо-восток"
         else
            return angel
         end
      else
         return u8"Неизвестно"
      end
   else
      return u8"Неизвестно"
   end
end

function getClosestCarId()
   local minDist = 9999
   local closestId = -1
   local x, y, z = getCharCoordinates(PLAYER_PED)
   for i, k in ipairs(getAllVehicles()) do
      local streamed, carId = sampGetVehicleIdByCarHandle(k)
      if streamed then
         local xi, yi, zi = getCarCoordinates(k)
         local dist = math.sqrt( (xi - x) ^ 2 + (yi - y) ^ 2 + (zi - z) ^ 2 )
         if dist < minDist then
            minDist = dist
            closestId = carId
         end
      end
   end
   return closestId
end

function getVehicleInStream()
	local stream = 0
	for i = 0, 2000 do
		local result, car = sampGetCarHandleBySampVehicleId(i)
		if result then
			stream = stream + 1
		end
	end
	return stream
end

function getObjectsInStream()
	local count = 0
    for _ in pairs(getAllObject()) do count = count + 1 end
    return count
end

lua_thread.create(function()
    while true do
        wait(1000)
        fps = fps_counter
        fps_counter = 0
    end
end)

function onD3DPresent()
    fps_counter = fps_counter + 1
end

function join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end

function intToHex(int)
    return '{'..string.sub(bit.tohex(int), 3, 8)..'}'
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end
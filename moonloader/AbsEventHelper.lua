script_author("1NS")
script_name("Absolute Events Helper")
script_description("Assistant for mappers and event makers on Absolute DM")
script_dependencies('imgui', 'lib.samp.events', 'vkeys', 'memory')
script_properties("work-in-pause")
script_url("https://github.com/ins1x/AbsEventHelper")
script_version("1.1")
-- script_moonloader(16) moonloader v.0.26

require 'lib.moonloader'
local keys = require 'vkeys'
local tag = "{00BFFF}Absolute {FFD700}Events {FFFFFF}Helper"
local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

------------------------[ cfg ] -------------------
local inicfg = require 'inicfg'
local configIni = "AbsEventHelper.ini"
local ini = inicfg.load({
   settings =
   {
      antiafk = true,
      chatfilter = true,
      keybinds = true,
	  addonfixes = true,
	  noeffects = false,
	  showhud = true,
	  nopostfx = false,
	  drawdist = "450",
      fog = "200",
   },
   binds =
   {
      textbuffer1 = " ",
	  textbuffer2 = " ",
	  textbuffer3 = " ",
	  textbuffer4 = " ",
	  textbuffer5 = " ",
	  textbuffer6 = " ",
	  textbuffer7 = " ",
	  adtextbuffer = " "
   }
}, configIni)
inicfg.save(ini, configIni)

function save()
    inicfg.save(ini, configIni)
end
---------------------------------------------------------

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
local show_info = imgui.ImBool(false)
local show_chatbinds = imgui.ImBool(false)
local show_vehs = imgui.ImBool(false)
local show_notepad = imgui.ImBool(false)
local show_textures = imgui.ImBool(false)
local show_fonts = imgui.ImBool(false)
local show_players = imgui.ImBool(false)
local show_cmds = imgui.ImBool(false)
local show_coords = imgui.ImBool(false)
local show_faq = imgui.ImBool(false)

local checkbox_antiafk = imgui.ImBool(ini.settings.antiafk)
local checkbox_chatfilter = imgui.ImBool(ini.settings.chatfilter)
local checkbox_keybinds = imgui.ImBool(ini.settings.keybinds)
local checkbox_addonfixes = imgui.ImBool(ini.settings.addonfixes)
local checkbox_noeffects = imgui.ImBool(ini.settings.noeffects)
local checkbox_showhud = imgui.ImBool(ini.settings.showhud)
local checkbox_nopostfx = imgui.ImBool(ini.settings.nopostfx)
local checkbox_showobjects = imgui.ImBool(false)
local checkbox_objectcollision = imgui.ImBool(false)

local color = imgui.ImFloat4(1, 0, 0, 1)
local sliderfog = imgui.ImInt(ini.settings.fog)
local sliderdrawdist = imgui.ImInt(ini.settings.drawdist)
local vehiclename_buffer = imgui.ImBuffer(128)
local bind_textbuffer1 = imgui.ImBuffer(256)
local bind_textbuffer2 = imgui.ImBuffer(256)
local bind_textbuffer3 = imgui.ImBuffer(256)
local bind_textbuffer4 = imgui.ImBuffer(256)
local bind_textbuffer5 = imgui.ImBuffer(256)
local bind_textbuffer6 = imgui.ImBuffer(256)
local bind_textbuffer7 = imgui.ImBuffer(256)
local bind_adtextbuffer = imgui.ImBuffer(256)
local rgb_texttbuffer = imgui.ImBuffer(256)
local note_textbuffer = imgui.ImBuffer(1024)

bind_textbuffer1.v = u8(ini.binds.textbuffer1)
bind_textbuffer2.v = u8(ini.binds.textbuffer2)
bind_textbuffer3.v = u8(ini.binds.textbuffer3)
bind_textbuffer4.v = u8(ini.binds.textbuffer4)
bind_textbuffer5.v = u8(ini.binds.textbuffer5)
bind_textbuffer6.v = u8(ini.binds.textbuffer6)
bind_textbuffer7.v = u8(ini.binds.textbuffer7)
bind_adtextbuffer.v = u8(ini.binds.adtextbuffer)

-- If the server changes IP, change it here
local hostip = "193.84.90.23"
local tpposX, tpposY, tpposZ
local disablealleffects = false
local disableObjectCollision = false
local showobjects = false
local removelogo = false

local objects_tab = 1
local hotkeys_tab = 1
local cmds_tab = 1

local fps = 0
local fps_counter = 0
local vehinfomodelid = 0 

local objectsDel = {}
local playersTable = {}

VehicleNames = {
	"Landstalker", "Bravura", "Buffalo", "Linerunner", "Pereniel", "Sentinel", "Dumper",
	"Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus", "Voodoo", "Pony",
	"Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi",
	"Washington", "Bobcat", "Mr Whoopee", "BF Injection", "Hunter", "Premier", "Enforcer",
	"Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer",
	"Previon", "Coach", "Cabbie", "Stallion", "Rumpo", "RC Bandit","Romero",
	"Packer", "Monster Truck", "Admiral", "Squalo", "Seasparrow","Pizzaboy",
	"Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic","Flatbed", "Yankee",
	"Caddy", "Solair", "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway",
	"RC Baron", "RC Raider", "Glendale", "Oceanic", "Sanchez", "Sparrow", "Patriot",
	"Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton",
	"Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer",
	"Maverick", "News Chopper", "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax",
	"Hotring", "Sandking", "Blista Compact", "Police Maverick", "Boxville",
	"Benson", "Mesa", "RC Goblin", "Hotring Racer", "Hotring Racer", "Bloodring Banger",
	"Rancher", "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle",
	"Cropdust", "Stunt", "Tanker", "RoadTrain", "Nebula", "Majestic", "Buccaneer",
	"Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck",
	"Fortune", "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine",
	"Feltzer", "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex",
	"Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder",
	"Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada",
	"Yosemite", "Windsor", "Monster Truck", "Monster Truck", "Uranus", "Jester",
	"Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma",
	"Savanna", "Bandito", "Freight", "Trailer", "Kart", "Mower", "Duneride",
	"Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford","BF-400",
	"Newsvan", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
	"Trailer", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car (LS)",
	"Police Car (SF)", "Police Car (LV)", "Police Ranger", "Picador", "S.W.A.T. Van",
	"Alpha", "Phoenix", "Glendale", "Sadler", "Luggage Trailer", "Luggage Trailer",
	"Stair Trailer", "Boxville", "Farm Plow", "Utility Trailer"
}

function imgui.OnDrawFrame()
   if main_window_state.v then
      imgui.SetNextWindowSize(imgui.ImVec2(295, 430), imgui.Cond.FirstUseEver)
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin("Absolute Events Helper", main_window_state)
	
	  if imgui.Button(u8"Настройки") then
		 show_settings.v = not show_settings.v
	  end
	  
	  imgui.SameLine()
	  if imgui.Button(u8"Скрыть все окна") then
	     show_favorites.v = false
		 show_credits.v = false
		 show_hotkeys.v = false
		 show_settings.v = false
		 show_colors.v = false
		 show_textures.v = false
	     show_worldlimits.v = false
		 show_info.v = false
		 show_chatbinds.v = false
		 show_vehs.v = false
		 show_notepad.v = false
		 show_fonts.v = false
		 show_players.v  = false
		 show_cmds.v  = false
		 show_coords.v  = false
		 show_faq.v  = false
      end
	  
	  imgui.SameLine()
	  if imgui.Button(u8"Свернуть") then
		 main_window_state.v = not main_window_state.v 
      end
      
	  _, pID = sampGetPlayerIdByCharHandle(playerPed)
	  local name = sampGetPlayerNickname(pID)
	  local ucolor = sampGetPlayerColor(pID)

	  imgui.TextColoredRGB(string.format("Логин: {%0.6x}%s (%d)",
	  bit.band(ucolor,0xffffff), name, pID))
	  if imgui.IsItemClicked() then
	  	 setClipboardText(pID)
		 printStringNow("ID copied to clipboard", 1000)
	  end
	  
      imgui.SameLine()
      imgui.Text(string.format("FPS: %i", fps))
	  if imgui.IsItemClicked() then
	  	 setClipboardText(string.format("FPS: %i", fps))
		 printStringNow("FPS copied to clipboard", 1000)
	  end
	  
	  local streamedplayers = sampGetPlayerCount(true) - 1
	  imgui.Text(string.format(u8"Игроков в стриме: %i Транспорта: %i",
	  streamedplayers, getVehicleInStream()))
	  
	  if imgui.Checkbox(u8("Отключить коллизию у объектов"), checkbox_objectcollision) then 
	     if checkbox_objectcollision.v then
            disableObjectCollision = true
         else
            disableObjectCollision = false
			find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
            result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
            if result then
		       for k, v in pairs(objectsDel) do
                  if doesObjectExist(v) then setObjectCollision(v, true) end
               end
            end
         end
	  end
	  
      imgui.SameLine()
      imgui.TextQuestion("( ? )", u8"Применимо только для объектов в области стрима")

	  if imgui.Checkbox(u8("Показывать ID объектов"), checkbox_showobjects) then 
		 if checkbox_showobjects.v  then
            showobjects = true
         else
            showobjects = false
         end
	  end
	  
      imgui.SameLine()
      imgui.TextQuestion("( ? )", u8"Применимо только для объектов в области стрима")

	  imgui.Text(" ")
	  
	  if imgui.Button(u8"Информация", imgui.ImVec2(250, 25)) then
		 show_info.v = not show_info.v
	  end
	  
	  if imgui.Button(u8"Чат-Бинд", imgui.ImVec2(250, 25)) then
	     show_chatbinds.v = not show_chatbinds.v
	  end
	  
	  if imgui.Button(u8"Транспорт", imgui.ImVec2(250, 25)) then
		 show_vehs.v = not show_vehs.v
	  end
	  
	  if imgui.Button(u8"Игроки", imgui.ImVec2(250, 25)) then
		 show_players.v = not show_players.v
	  end
	  
      if imgui.Button(u8"Координаты", imgui.ImVec2(250, 25)) then
		 show_coords.v = not show_coords.v
	  end
	  
	  if imgui.Button(u8"Заметки", imgui.ImVec2(250, 25)) then
		 show_notepad.v = not show_notepad.v
	  end
	  
	  local ip, port = sampGetCurrentServerAddress()
	  if not ip:find(hostip) then
	     imgui.TextColoredRGB("{FF0000}Некоторые функции будут недоступны")
	     imgui.TextColoredRGB("{FF0000}Скрипт предназначен для работы на Absolute Play DM")
	  end
	  
      imgui.End()
   end
   
   if show_info.v then
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.5, sizeY / 8),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
      imgui.Begin(u8"Информация", show_info)
	  
	  if imgui.Button(u8"Лимиты", imgui.ImVec2(200, 25)) then
		 show_worldlimits.v = not show_worldlimits.v
	  end
	  
	  if imgui.Button(u8"Цвета", imgui.ImVec2(200, 25)) then
		 show_colors.v = not show_colors.v
	  end
	  
	  if imgui.Button(u8"Текстуры", imgui.ImVec2(200, 25)) then
	     show_textures.v = not show_textures.v
	  end
	  
	  if imgui.Button(u8"Шрифты", imgui.ImVec2(200, 25)) then
		 show_fonts.v = not show_fonts.v
	  end
	  
	  if imgui.Button(u8"Команды", imgui.ImVec2(200, 25)) then
		 show_cmds.v = not show_cmds.v
	  end
	  
	  if imgui.Button(u8"Избранные объекты", imgui.ImVec2(200, 25)) then
		 show_favorites.v = not show_favorites.v
	  end
	  
	  if imgui.Button(u8"FAQ по редактору карт", imgui.ImVec2(200, 25)) then
		 show_faq.v = not show_faq.v
	  end
	  
	  if imgui.Button(u8"Горячие клавиши", imgui.ImVec2(200, 25)) then
		 show_hotkeys.v = not show_hotkeys.v
	  end
	  
	  if imgui.Button(u8"О скрипте", imgui.ImVec2(200, 25)) then
		 show_credits.v = not show_credits.v
	  end
	  
      imgui.End()
   end
   
   if show_textures.v then
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 3.5, sizeY / 10),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
      imgui.Begin(u8"Текстуры", show_textures)
	  
	  if imgui.Button(u8"1-60", imgui.ImVec2(200, 25)) then
	     hideAllTextureImages()
		 show_texture1 = not show_texture1
	  end
	  
	  if imgui.Button(u8"60-120", imgui.ImVec2(200, 25)) then
	     hideAllTextureImages()
		 show_texture2 = not show_texture2
	  end
	  
	  if imgui.Button(u8"120-180", imgui.ImVec2(200, 25)) then
	     hideAllTextureImages()
	     show_texture3 = not show_texture3
	  end
	
	  if imgui.Button(u8"180-240", imgui.ImVec2(200, 25)) then
	     hideAllTextureImages()
		 show_texture4 = not show_texture4
	  end
	  
	  if imgui.Button(u8"240-302", imgui.ImVec2(200, 25)) then
	     hideAllTextureImages()
		 show_texture5 = not show_texture5
	  end
	  
	  if imgui.Button(u8"Скрыть все", imgui.ImVec2(200, 25)) then
		 hideAllTextureImages()
		 show_textures.v = false
	  end
	  
      imgui.End()
   end
   
   if show_fonts.v then
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 3.5, sizeY / 10),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
      imgui.Begin(u8"Шрифты", show_fonts)
	  
	  if imgui.Button(u8"GTAWeapon3", imgui.ImVec2(200, 25)) then
	     hideAllFontsImages()
		 show_fontsimg1 = not show_fontsimg1
	  end
	  
	  if imgui.Button(u8"WebdingsEN", imgui.ImVec2(200, 25)) then
	     hideAllFontsImages()
		 show_fontsimg2 = not show_fontsimg2
	  end
	  
	  if imgui.Button(u8"WebdingsRU", imgui.ImVec2(200, 25)) then
	     hideAllFontsImages()
	     show_fontsimg3 = not show_fontsimg3
	  end
	
	  if imgui.Button(u8"WingdingsEN", imgui.ImVec2(200, 25)) then
	     hideAllFontsImages()
		 show_fontsimg4 = not show_fontsimg4
	  end
	  
	  if imgui.Button(u8"fWingdingsRU", imgui.ImVec2(200, 25)) then
		 hideAllFontsImages()
		 show_fontsimg5 = not show_fontsimg5
	  end
	  
	  if imgui.Button(u8"Скрыть все", imgui.ImVec2(200, 25)) then
		 hideAllFontsImages()
         show_fonts.v = false
	  end
	  
      imgui.End()
   end
   
   if show_favorites.v then
      imgui.SetNextWindowSize(imgui.ImVec2(530, 340), imgui.Cond.FirstUseEver)
	  imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 8, sizeY / 4),
	  imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
      imgui.Begin(u8"Объекты", show_favorites)
	  
	  if imgui.Button(u8"Основные") then objects_tab = 1 end 
	  imgui.SameLine()
	  if imgui.Button(u8"Специальные") then objects_tab = 2 end
	  imgui.SameLine()
	  if imgui.Button(u8"Эффекты") then objects_tab = 3 end
	  imgui.SameLine()
	  if imgui.Button(u8"Освещение") then objects_tab = 4 end
	  
	  if objects_tab == 1 then
	     imgui.Text(u8"Большие прозрачные объекты для текста: 19481, 19480, 19482, 19477")
         imgui.Text(u8"Маленькие объекты для текста: 19476, 2662")
         imgui.Text(u8"Бетонные блоки: 18766, 18765, 18764, 18763, 18762")
         imgui.Text(u8"Горы: вулкан 18752, песочница 18751, песочные горы ландшафт 19548")
         imgui.Text(u8"Платформы: тонкая платформа 19552, 19538, решетчатая 18753, 18754")
         imgui.Text(u8"Поверхности: 19531, 4242, 4247, 8171, 5004, 16685")
         imgui.Text(u8"Стены: 19355, 19435(маленькая), 19447(длинная), 19391(дверь), 19408(окно)")
	  elseif objects_tab == 2 then
		 imgui.Text(u8"Коровка 19833, Веревка 19087, Веревка длин. 19089")
         imgui.Text(u8"Стекло (Разрушаемое) 3858, стекло от травы 3261, сено 3374")
         imgui.Text(u8"Факел с черепом 3524, факел 3461, красный стоп сигнал 3877")
         imgui.Text(u8"Попуг 19079, восточная лампа 3534")
         imgui.Text(u8"Водяная бочка 1554, ржавая бочка 1217, взрыв. бочка 1225")
         imgui.Text(u8"Черная бездна 13656, стеклянный блок 18887")
         imgui.Text(u8"Партикл воды с колизией 19603, большой 19604")
         imgui.Text(u8"Финиш гонки 18761")
	  elseif objects_tab == 3 then
	     imgui.Text(u8"Огонь большой 18691, средний огонь 18692, пламя+дым (исчезает) 18723")
	     imgui.Text(u8"Огонь от огнемета 18694, огонь от машины 18690")
	     imgui.Text(u8"Пар от вентиляции 18736, дым от сигареты 18673, дым с фабрики 18748")
	     imgui.Text(u8"Белый дым 18725, черный дым 18726, большой серый дым 18727")
	     imgui.Text(u8"Большой взрыв 18682, средний взрыв 18683, маленький взрыв 18686")
	     imgui.Text(u8"Спрей 18729, кровь 18668, огнетушитель 18687, слезоточивый 18732")
	     imgui.Text(u8"Рябь на воде 18741, брызги воды 18744")
	     imgui.Text(u8"Фонтан 18739, гидрант 18740, водопад 19841, вода 19842")
         imgui.Text(u8"Искры 18717, горящие дрова 19632")
         imgui.Text(u8"Сигнальный огонь 18728, лазер 18643, нитро 18702, флейм 18693")
	  elseif objects_tab == 4 then
	     imgui.Text(u8"Неон красный 18647, синий 18648, зеленый 18649")
	     imgui.Text(u8"Неон желтый 18650, розовый 18651, белый 18652")
	     imgui.Text(u8"Свет.шар (не моргает) белый 19281, красн. 19282, зел. 19283, синий 19284")
	     imgui.Text(u8"Свет.шар (моргает быстро) белый 19285, красн. 19286, зел. 19287, син. 19288")
	     imgui.Text(u8"Свет.шар (моргает медленно) белый 19289, красн. 19290, зел. 19291, син. 19292")
	     imgui.Text(u8"Свет.шар (моргает медленно) фиолетовый 19293, желтый 19294")
	     imgui.Text(u8"Свет.шар (большой не моргает) бел. 19295, красн. 19296, зел. 19297, син. 19298")
	  end
	   
	  imgui.Text(u8"")
	  imgui.Separator()
	  imgui.TextColoredRGB("Не нашли нужный объект? посмотрите на {007DFF}dev.prineside.com")
	  if imgui.IsItemClicked() then
		 setClipboardText("dev.prineside.com")
		 printStringNow("url copied to clipboard", 1000)
	  end
      imgui.End()
   end
	
	if show_colors.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 6, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   
       imgui.Begin(u8"Цветовая палитра", show_colors)
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
	   if imgui.Button("{FF0000}  RED    ", imgui.ImVec2(300, 20)) then
	      setClipboardText("{FF0000}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.0, 1.0))
	   if imgui.Button("{008000}  GREEN ", imgui.ImVec2(300, 20)) then 
	      setClipboardText("{008000}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 1.0, 1.0))
	   if imgui.Button("{0000FF}  BLUE  ", imgui.ImVec2(300, 20)) then
	      setClipboardText("{0000FF}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 0.0, 1.0))
	   if imgui.Button("{FFFF00}  YELLOW", imgui.ImVec2(300, 20)) then
	      setClipboardText("{FFFF00}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 1.0, 1.0))
	   if imgui.Button("{FF00FF}  PINK  ", imgui.ImVec2(300, 20)) then
	      setClipboardText("{FF00FF}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 1.0, 1.0))
	   if imgui.Button("{00FFFF}  AQUA  ", imgui.ImVec2(300, 20)) then
	      setClipboardText("{00FFFF}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 0.0, 1.0))
	   if imgui.Button("{00FF00}  LIME  ", imgui.ImVec2(300, 20)) then 
	      setClipboardText("{00FF00}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.5, 1.0))
	   if imgui.Button("{800080}  PURPLE", imgui.ImVec2(300, 20)) then
	      setClipboardText("{800080}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.0, 1.0))
	   if imgui.Button("{800000}  MAROON", imgui.ImVec2(300, 20)) then
	      setClipboardText("{800000}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.0, 1.0))
	   if imgui.Button("{808000}  OLIVE ", imgui.ImVec2(300, 20)) then
	      setClipboardText("{808000}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.5, 1.0))
	   if imgui.Button("{008080}  TEAL  ", imgui.ImVec2(300, 20)) then
		  setClipboardText("{008080}")
		  printStringNow("copied to clipboard", 1000)
	   end	   
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.6, 0.0, 1.0))
	   if imgui.Button("{FF9900}  ORANGE", imgui.ImVec2(300, 20)) then
	      setClipboardText("{FF9900}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.89, 0.76, 1.0))
	   if imgui.Button("{FFE4C4}  BISQUE", imgui.ImVec2(300, 20)) then
	      setClipboardText("{FFE4C4}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
	   if imgui.Button("{FFFFFF}  WHITE ", imgui.ImVec2(300, 20)) then 
	      setClipboardText("{FFFFFF}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
	   if imgui.Button("{808080}  GREY  ", imgui.ImVec2(300, 20)) then 
	      setClipboardText("{808080}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
	   if imgui.Button("{000000}  BLACK ", imgui.ImVec2(300, 20)) then
	      setClipboardText("{000000}")
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.PopStyleColor()
	   
	   imgui.Text(u8"Тест RGB текста, например введите: {00FF00}Текст")
	   if imgui.InputText("##RGBtext", rgb_texttbuffer) then
	   end
	   imgui.TextColoredRGB(rgb_texttbuffer.v)
	   
	   imgui.SameLine()
	   if imgui.Button("Copy") then
	      setClipboardText(rgb_texttbuffer.v)
		  printStringNow("Text copied to clipboard", 1000)
	   end
	   
	   imgui.TextColoredRGB("Другие цвета {007DFF}https://encycolorpedia.ru/websafe")
	   if imgui.IsItemClicked() then
	  	  setClipboardText("https://encycolorpedia.ru/websafe")
		  printStringNow("Url copied to clipboard", 1000)
	   end
	  
	   imgui.Text(u8"RR — красная часть цвета, GG — зеленая, BB — синяя, AA — альфа")
	   imgui.ColorEdit4("", color)
	   imgui.SameLine()
	   imgui.Text("HEX: " ..intToHex(join_argb(color.v[4] * 255, color.v[1] * 255,
	   color.v[2] * 255, color.v[3] * 255)))
	   if imgui.IsItemClicked() then
		  setClipboardText(tostring(intToHex(join_argb(color.v[4] * 255, color.v[1] * 255,
	      color.v[2] * 255, color.v[3] * 255))))
		  printStringNow("copied to clipboard", 1000)
	   end
	   imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Нажмите чтобы скопировать цвет в буффер обмена")

	   imgui.End()
	end
    
	if show_chatbinds.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 6, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   imgui.SetNextWindowSize(imgui.ImVec2(490, 510), imgui.Cond.FirstUseEver)
	   imgui.Begin(u8"Чат", show_chatbinds)
	   
	   imgui.Text(u8"Здесь вы можете настроить чат-бинды для мероприятия")
	   imgui.TextColoredRGB("{00FF00}@ номер игрока - {bababa}заменит id на никнейм игрока")
	   
	   if imgui.InputText("##Bind1", bind_textbuffer1) then 
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [1]") then
	      u8:decode(bind_textbuffer1.v)
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer1.v)))
	   end
	   
	   if imgui.InputText("##Bind2", bind_textbuffer2) then 
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [2]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer2.v)))
	   end
	   
	   if imgui.InputText("##Bind3", bind_textbuffer3) then 
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [3]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer3.v)))
	   end
	   
	   if imgui.InputText("##Bind4", bind_textbuffer4) then 
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [4]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer4.v)))
	   end
	   
	   if imgui.InputText("##Bind5", bind_textbuffer5) then 
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [5]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer5.v)))
	   end
	   
	   if imgui.InputText("##Bind6", bind_textbuffer6) then 
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [6]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer6.v)))
	   end
	   
	   if imgui.InputText("##Bind7", bind_textbuffer7) then 
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Отправить в мчат [7]") then
	      sampSendChat(string.format("/мчат %s", u8:decode(bind_textbuffer7.v)))
	   end
	   
	   imgui.Text(" ")
	   imgui.Text(u8"Объявления")
	   if imgui.InputText("##BindAd", bind_adtextbuffer) then 
	   end
	   
	   if imgui.Button(u8"Дать объявление в общий чат") then
	      sampSendChat(string.format("* %s", u8:decode(bind_adtextbuffer.v)))
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Дать объявление в /об") then
	      sampSendChat(string.format("/об %s", u8:decode(bind_adtextbuffer.v)))
	   end
	   
	   imgui.Text(" ")
	   
       if imgui.Button(u8("Сохранить")) then
	      ini.binds.textbuffer1 = u8:decode(bind_textbuffer1.v)
	      ini.binds.textbuffer2 = u8:decode(bind_textbuffer2.v)
	      ini.binds.textbuffer3 = u8:decode(bind_textbuffer3.v)
	      ini.binds.textbuffer4 = u8:decode(bind_textbuffer4.v)
	      ini.binds.textbuffer5 = u8:decode(bind_textbuffer5.v)
	      ini.binds.textbuffer6 = u8:decode(bind_textbuffer6.v)
	      ini.binds.textbuffer7 = u8:decode(bind_textbuffer7.v)
	      ini.binds.adtextbuffer = u8:decode(bind_adtextbuffer.v)
		  save()          
          printStringNow("Saved", 1000)
       end
	   
	   imgui.SameLine()
	   if imgui.Button(u8("Перегрузить")) then
	      bind_textbuffer1.v = u8(ini.binds.textbuffer1)
          bind_textbuffer2.v = u8(ini.binds.textbuffer2)
          bind_textbuffer3.v = u8(ini.binds.textbuffer3)
          bind_textbuffer4.v = u8(ini.binds.textbuffer4)
          bind_textbuffer5.v = u8(ini.binds.textbuffer5)
          bind_textbuffer6.v = u8(ini.binds.textbuffer6)
          bind_textbuffer7.v = u8(ini.binds.textbuffer7)
          bind_adtextbuffer.v = u8(ini.binds.adtextbuffer)        
          printStringNow("Reloaded", 1000)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Очистить все бинды") then
	      bind_textbuffer1.v = " "
	      bind_textbuffer2.v = " "
	      bind_textbuffer3.v = " "
	      bind_textbuffer4.v = " "
	      bind_textbuffer5.v = " "
	      bind_textbuffer6.v = " "
	      bind_textbuffer7.v = " "
		  bind_adtextbuffer.v = " "
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Очистить себе чат") then
		  memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
          memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
          memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
	   end
	   
	   if imgui.Button(u8"Скопировать послед сообщение из чата в буффер") then
	       text, prefix, color, pcolor = sampGetChatString(99)
		   setClipboardText(text)
	   end
  	   imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Копирует последнюю строчку из чата (Только латиница)")

	   imgui.End()
	end
	
	if show_players.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 4, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   imgui.SetNextWindowSize(imgui.ImVec2(560, 540), imgui.Cond.FirstUseEver)
	   imgui.Begin(u8"Игроки", show_players)
	   
	   imgui.Text(u8"Перед началом мероприятия обновите список игроков, и сохраните")
	   
	   if imgui.Button(u8"Обновить список игроков", imgui.ImVec2(250, 25)) then
		  playersTable = {}
		  
		  for k, v in ipairs(getAllChars()) do
			 local res, id = sampGetPlayerIdByCharHandle(v)
			 if res then
				table.insert(playersTable, id)
			 end
		  end
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Сохранить список игроков", imgui.ImVec2(250, 25)) then
	      ptablefile = io.open(getGameDirectory().."/moonloader/resource/abseventhelper/players.txt", "w")
	      for k, v in pairs(playersTable) do
              ptablefile:write(string.format("[%d]%s lvl: %i \n",
			  v, sampGetPlayerNickname(v), sampGetPlayerScore(v) ))
		  end
		  ptablefile:close()
		  printStringNow("Saved moonloader/resource/abseventhelper/players.txt", 4000)
	   end
	   
	   imgui.Text(u8"Нажмите на id чтобы скопировать в буффер id игрока")
	   imgui.Text(u8"Нажмите на никнейм чтобы открыть меню игрока")
	   imgui.Text(u8" ")
	   
	   imgui.Separator()
	   imgui.Columns(5)
	   imgui.Text("[ID]")
	   imgui.NextColumn()
	   imgui.Text("Nickname")
	   imgui.NextColumn()
	   imgui.Text("Level")
	   imgui.NextColumn()
	   imgui.Text("HP (Armour)")
	   imgui.NextColumn()
	   imgui.Text("Ping")
	   imgui.Columns(1)
	   imgui.Separator()
		  
	   for k, v in pairs(playersTable) do
	      local health = sampGetPlayerHealth(v)
		  local armor = sampGetPlayerArmor(v)
		  local ping = sampGetPlayerPing(v)
		  local nickname = sampGetPlayerNickname(v)
		  local score = sampGetPlayerScore(v)
		  local ucolor = sampGetPlayerColor(v)
		  
		  imgui.Columns(5)
		  imgui.TextColoredRGB(string.format("[%d]", v ))
		  if imgui.IsItemClicked() then
			 setClipboardText(v)
			 printStringNow("copied to clipboard", 1000)
		  end
		  imgui.SetColumnWidth(-1, 50)
		  imgui.NextColumn()
		  imgui.TextColoredRGB(string.format("{%0.6x} %s", bit.band(ucolor,0xffffff), nickname))
		  if imgui.IsItemClicked() then
			 sampSendChat(string.format("/и %i", v))
		  end
		  imgui.SetColumnWidth(-1, 200)
		  imgui.NextColumn()
		  if(score < 20) then
		     imgui.TextColoredRGB(string.format("{FF0000}%i", score))
		  else 
		     imgui.TextColoredRGB(string.format("%i", score))
	      end
		  imgui.NextColumn()
		  imgui.TextColoredRGB(string.format("%i (%i)", health, armor))
		  imgui.NextColumn()
		  if(ping > 90) then
		     imgui.TextColoredRGB(string.format("{FF0000}%i", ping))
		  else
		     imgui.TextColoredRGB(string.format("%i", ping))
		  end
		  imgui.Columns(1)
          imgui.Separator()
	   end
		  
	   imgui.End()
	end
	
    if show_vehs.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 8),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   imgui.SetNextWindowSize(imgui.ImVec2(360, 240), imgui.Cond.FirstUseEver)
	   imgui.Begin(u8"Транспорт", show_vehs)
	   
	   -- https://wiki.multitheftauto.com/wiki/Vehicle_IDs
	   imgui.InputText("##BindVehs", vehiclename_buffer)
	   
	   imgui.SameLine()
	   imgui.Text(string.format(u8"ID: %i", vehinfomodelid))
	   
	   local closestcarid = getClosestCarId()
	   imgui.Text(string.format(u8"Ближайший транспорт: %i (внутренний ID)", closestcarid))
	   
	   if isCharInAnyCar(PLAYER_PED) then 
          local carhandle = storeCarCharIsInNoSave(PLAYER_PED)
          local carmodel = getCarModel(carhandle)
		  imgui.Text(string.format(u8"Вы в транспорте: %s(%i)  хп: %i",
		  VehicleNames[carmodel-399], carmodel, getCarHealth(carhandle)))
		  imgui.Text(string.format(u8"Цвет %d и %d", getCarColours(carhandle)))
       end
	   
	   if imgui.Button(u8"Найти ID транспорта по имени", imgui.ImVec2(320, 25)) then
		  for k, vehname in ipairs(VehicleNames) do
		     if vehname:lower():find(u8:decode(vehiclename_buffer.v:lower())) then
			    vehinfomodelid = 399+k
				setClipboardText(vehinfomodelid)
			    printStringNow(vehinfomodelid, 1000)
			 end 
		  end
	   end
	   
	   if imgui.Button(u8"Заказать машину по имени", imgui.ImVec2(320, 25)) then
	      if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not  isSampfuncsConsoleActive() then
		     for k, vehname in ipairs(VehicleNames) do
		        if vehname:lower():find(u8:decode(vehiclename_buffer.v:lower())) then
			       vehinfomodelid = 399+k
			    end 
		     end
			 sampSendChat(string.format(u8"/vfibye2 %i", vehinfomodelid))
		  end
	   end
	   
	   if imgui.Button(u8"Заказать машину из списка", imgui.ImVec2(320, 25)) then
	      if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/vfibye2") end
	   end
	   
	   imgui.End()
	end
	
	if show_hotkeys.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
       imgui.Begin(u8"Горячие клавиши", show_hotkeys)
	   
	   if imgui.Button(u8"Доступные только с SAMP ADDON") then hotkeys_tab = 1 end 
	   imgui.SameLine()
	   if imgui.Button(u8"Восстановленые скриптом") then hotkeys_tab = 2 end
	  
	   if hotkeys_tab == 1 then
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
	   elseif hotkeys_tab == 2 then
	      imgui.TextColoredRGB("Восстановленые скриптом и доступные без {00FF00}SAMP ADDON:")
          imgui.TextColoredRGB("{00FF00}J{FFFFFF} - полет в мире")
          imgui.TextColoredRGB("{00FF00}Z{FFFFFF} - починить транспорт")
          imgui.TextColoredRGB("{00FF00}U{FFFFFF} - анимации")
          imgui.TextColoredRGB("{00FF00}M{FFFFFF} - домашний транспорт")
          imgui.TextColoredRGB("{00FF00}K{FFFFFF} - заказать транспорт")
		  imgui.Text(" ")
		  imgui.TextColoredRGB("Дополнительные бинды:")
          imgui.TextColoredRGB("{00FF00}H{FFFFFF} - перевернуть транспорт")
	   end
	   
       imgui.End()
	end
	
	if show_cmds.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
       imgui.Begin(u8"Команды", show_cmds)
	   
	   if imgui.Button(u8"Серверные команды") then cmds_tab = 1 end 
	   imgui.SameLine()
	   if imgui.Button(u8"Команды хелпера") then cmds_tab = 2 end
	  
	   if cmds_tab == 1 then
          imgui.TextColoredRGB("{00FF00}/menu{FFFFFF} — вызвать главное меню")
          imgui.TextColoredRGB("{00FF00}/мир <номер мира>{FFFFFF} — войти в мир по номеру")
          imgui.TextColoredRGB("{00FF00}/мчат <текст>{FFFFFF} — сказать игрокам в мире")
          imgui.TextColoredRGB("{00FF00}/об <текст>{FFFFFF} — дать объявление")
          imgui.TextColoredRGB("{00FF00}/прыг{FFFFFF} — прыгнуть вперед")
          imgui.TextColoredRGB("{00FF00}/полет{FFFFFF} — уйти в режим полета в мире")
          imgui.TextColoredRGB("{00FF00}/стат <id игрока>{FFFFFF} — показать статистику игрока")
          imgui.TextColoredRGB("{00FF00}/и <id игрока>{FFFFFF} — меню игрока")
          imgui.TextColoredRGB("{00FF00}/id <часть имени>{FFFFFF} — найти id по части имени")
          imgui.TextColoredRGB("{00FF00}/тпк <x y z>{FFFFFF} — телепорт по координатам")
          imgui.TextColoredRGB("{00FF00}/коорд{FFFFFF} - узнать текущие координаты")
          imgui.TextColoredRGB("{00FF00}/выход либо /exit{FFFFFF} — выйти из мира")
          imgui.Text(" ")
     
	   elseif cmds_tab == 2 then
          imgui.TextColoredRGB("{00FF00}/abshelper{FFFFFF} — открыть главное меню хелпера")
		  imgui.TextColoredRGB("{00FF00}/note{FFFFFF} — открыть заметки")
		  imgui.TextColoredRGB("{00FF00}/chatbinds{FFFFFF} — настройки чат-биндов")
		  imgui.TextColoredRGB("{00FF00}/players{FFFFFF} — таблица игроков")
		  imgui.TextColoredRGB("{00FF00}/vehicles{FFFFFF} — таблица транспорта")
		  imgui.TextColoredRGB("{00FF00}/onjectrender{FFFFFF} — рендер объектов")
		  imgui.Text(" ")
	   end
	   
       imgui.End()
	end
	
	if show_faq.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 10, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   imgui.SetNextWindowSize(imgui.ImVec2(640, 480), imgui.Cond.FirstUseEver)
       imgui.Begin(u8"FAQ", show_faq)
	   
	   if imgui.CollapsingHeader(u8'Что такое "мир" и зачем он нужен?') then
		  imgui.Text(u8"Мир это виртуальное пространство, в котором игрок при помощи редактора карт\nможет создавать свои карты используя GTA:SA и SA:MP объекты.\nВ мире владельцу предоставляются достаточно широкие функции \nдля воплощения своих идей и проведения мероприятий.\n")
	   end	
	   
	   if imgui.CollapsingHeader(u8'Как создать мир?') then
		  imgui.Text(u8"Каждый игрок от 20 уровня может при наличии свободных слотов создать свой мир.\nДля создания мира необходимо иметь 100 ОА и 1.000.000$.\n")
	   end	
	   
	   if imgui.CollapsingHeader(u8'Свободных слотов нет. Что делать?') then
		  imgui.Text(u8"Большинство новичков просто хотят создать свой мир для пвп, для пвп не нужен свой мир.\nНа сервере полно миров открытых для редактирования, в них доступны все\nнеобходимые ф-ции такие как выдача оружия,пополнение хп и брони,\nсоздание объектов и прочее. Если все же вы собираетесь строить что-либо интересное, то\nнужно либо ждать вайпа мира что происходит крайне редко, либо покупать мир у игрока.")
	   end	
	   
	   if imgui.CollapsingHeader(u8'Как повысить кол-во объектов?') then
		  imgui.Text(u8"По умолчанию в мире можно создавать только 50 объектов (можно расширить до 300).\nСтоимость расширения мира 20 ОА и 500.000$ за 10 объектов.\nVIP игроки могут расширить до 2000 объектов.\nТаким образом чтобы прокачать мир до 300 объектов нужно 600 ОА и 15.000.000$\nполный апгрейд до 2000 объектов стоит 4000 ОА и 100.000.000$\n")
	   end	
	   
       if imgui.CollapsingHeader(u8'Как изменить время-погоду в мире?') then
		  imgui.Text(u8"Y - Редактор карт - Управление мирами - выбрать время / выбрать погоду.\n")
	   end	
	   
	   if imgui.CollapsingHeader(u8'Как изменить точку появления в мире?') then
		  imgui.Text(u8"Y - Редактор карт - Управление мирами - Выбрать точку появления.\nПо умолчанию доступно только 4 точки.\nУстановить произвольную позицию доступно только VIP игрокам.\nУстанавливать произвольную точку появления нельзя в воде, над водой, на большой высоте.\n")
	   end	
	   
	   if imgui.CollapsingHeader(u8'Как быстро выровнять объект, зачем вообще выравнивать объекты по координатам?') then
		  imgui.Text(u8"Быстро выровнять объект можно через меню N - выровнять объект по координатам.\n Выравнивать объекты необходимо чтобы потом их можно было ровно свести между собой.\n")
	   end	

	   if imgui.CollapsingHeader(u8'Как быстро выделить нужный объект?') then
		  imgui.Text(u8"Используйте функцию N - выделить объект.\nЕсли проблематично выделить объект попробуйте перейти в режим полета.\nЛибо подойдите максимально близко к центру объекта\nи выберите N - выделить объект стоящий рядом.")
	   end
	   
	   if imgui.CollapsingHeader(u8'Как создать прозрачный объект?') then
          imgui.Text(u8"Например нужно создать прозрачную стену через которую игроки не смогут пройти.\n Создаем любой объект подходящий по размерам и форме далее\n N - Редактировать объект - выделить объект\n выделяем объект и в меню редактирования выбираем Изменить текст\nполе ввода текста при этом оставляем пустым - сохраняем.")
	   end
	   
       if imgui.CollapsingHeader(u8'Как повысить репутацию миру и для чего она вообще нужна?') then
          imgui.Text(u8"N - Информация о мире - Репутация.\nВ отличии от репутации игрока, в мире можно только повышать репутацию\n(повышать ее могут игроки любого уровня).\nРепутация мира влияет на отображение в рейтинге (Y - Редактор карт - Миры по рейтингу).\nОтображение в рейтинге напрямую влияет на количество посетителей.")
	   end
       
	   if imgui.CollapsingHeader(u8'Как формируется рейтинг?') then
          imgui.Text(u8"Рейтинг формируется не только исходя из количества репутаций.\nОчки рейтинга даются за количество объектов в мире.\nЗа каждые 10 созданных объектов идет +1 очко в рейтинг 1 репутация тоже дает 1 очко.\nМир будет отображаться в топ-листе по рейтингу только если у игрока VIP аккаунт.\n")
	   end
	   
	   if imgui.CollapsingHeader(u8'Мир пропал из рейтинга, как это произошло и почему?') then
          imgui.Text(u8"Закрытые и запароленные миры не отображаются в рейтинге.\n(После снятия пароля мир появится в списке не моментально)\nУ вас могла закончиться VIP.\nВозможно ваш мир уже не входит в топ 50 по количеству очков.")
	   end

	   if imgui.CollapsingHeader(u8'Как телепортироваться в мире?') then
          imgui.Text(u8"В мире классические телепорты через меню недоступны.\nДля быстрого перемещения между локациями можно использовать телепорт по метке.\n(Данная опция доступна только VIP игрокам).\nЛибо вы можете сохранить координаты командой /коорд\nи использовать телепорт по координатам /тпк.\nВажно: Это работает при условии что телепорт и вызов ТС не запрещен владельцем мира.")
	   end
       
	   if imgui.CollapsingHeader(u8'Как узнать какой объект использовался?') then
          imgui.Text(u8"N - Информация об объекте. Даже если в мире закрыто редактирование\nпри наведении на объект покажет его ID, Type, Distace.\nгде Type и будет модель объекта.\nУвидеть номер текстуры, шрифт, цвет могут только редакторы.")
	   end

	   if imgui.CollapsingHeader(u8'Как создать надпись?') then
          imgui.Text(u8"Для этого нужно используют специальные объекты без коллизии.\nНаложить текст через меню N - Редактировать объект - Изменить текст.\nНаиболее часто используемые 19481, 19480, 19482, 19477")
	   end

	   if imgui.CollapsingHeader(u8'Как вставить спецсимвол?') then
          imgui.Text(u8"В тексте можно использовать различные шрифты и спецсимволы.\nСоздайте объект на котором следует размещать текст (например 19482).\nЗатем нажмите N - редактировать объект - изменить текст - шрифт текста - например Webdings\nТаблицу спецсимволов можно посмотреть на https://pawnokit.ru/ru/spec_symbols \nНе стесняйтесь их использовать, в отличие от эмодзи они работают с любым клиентом. ")
	   end
	   
	   if imgui.CollapsingHeader(u8'Как продать мир?') then
          imgui.Text(u8"Продажа мира с сохранением объектов на сервере -  не предусмотрена.\nПри продаже владелец удаляет мир, а покупатель его берет по базовой цене.\nПри этом все настройки, объекты и репутации в мире безвозвратно удаляются.\n")
	   end	   

	   if imgui.CollapsingHeader(u8'Через какое время мир будет удален?') then
          imgui.Text(u8"Мир удаляется спустя месяц отсутствия активности игрока, либо действий в мире.\n Таким образом просто заходить на аккаунт для сохранения мира недостаточно.\n")
	   end

  	   if imgui.CollapsingHeader(u8'Как узнать кто владелец мира и посмотреть информацию о мире?') then
          imgui.Text(u8"N - Информация о мире. Здесь вы можете увидеть\nсколько объектов использовано кто владелец, разрешены ли оружия и транспорт ")
	   end

	   if imgui.CollapsingHeader(u8'Как удалить пикапы по радиусу?') then
          imgui.Text(u8"При первом использовании опции удаления пикапа оружия удалит пикап рядом\nпри удалении последующих предложит радиусное удаление.")
	   end

	   if imgui.CollapsingHeader(u8'Как отключить регенерацию в мире?') then
          imgui.Text(u8"Y - Редактор карт - Управление мирами - Регенерация.")
	   end

	   if imgui.CollapsingHeader(u8'Как разрешить редактировать мир?') then
          imgui.Text(u8"TAB - кликнуть по игроку которому хотим разрешить редактирование - разрешить редактировать мир.\nРазрешить редактирование может только владелец находясь в своем мире")
	   end

	   if imgui.CollapsingHeader(u8'Какие функции доступны владельцу мира, но не доступны редакторам?') then
          imgui.Text(u8"- разрешить изменять объекты всем игрокам")
          imgui.Text(u8"- запретить входить в мир, в том числе и выставить пароль на вход")
          imgui.Text(u8"- разрешить/запретить использовать оружие")
          imgui.Text(u8"- выбрать точку появления")
          imgui.Text(u8"- разрешить вызов т/c, телепортацию по метке")
          imgui.Text(u8"- настроить время суток и погоду")
          imgui.Text(u8"- дать название миру")
          imgui.Text(u8"- разрешить/запретить регенерацию")
	   end
	   
	   imgui.Text(u8"Ошибки и баги")
	   
	   if imgui.CollapsingHeader(u8'Ошибка. В этой области создано слишком много объектов') then
          imgui.Text(u8"Такая ошибка появляется если вы создали много объектов в одной области.\nВ радиусе 150 метров нельзя создавать больше 200 объектов.\nЭто сигнал о том что ваша локация перегружена объектами, и стоит провести оптимизацию и очистить эту область.\n")
	   end
	   
	   if imgui.CollapsingHeader(u8'Ошибка. Создано максимум объектов') then
          imgui.Text(u8"Нужно увеличить лимит. Y - Редактор карт - Управление мирами - Повышение лимита объектов. ")
	   end
	   
	   if imgui.CollapsingHeader(u8'Ошибка. Максимальное количество созданных миров - 500') then
          imgui.Text(u8"Невозможно создать мир, нет свободных слотов.\nМожно ждать пока освободится слот, либо купить мир у игрока.")
	   end
	   
	   if imgui.CollapsingHeader(u8'Ошибка. Античит отправил тебя на место появления') then
          imgui.Text(u8"Это может происходить если вы без аддона уходите в афк на большой высоте, либо если вы находитесь афк над водой.")
	   end

	   if imgui.CollapsingHeader(u8'Ошибка. Транспорт мира не создан. Транспорта в мире нет') then
          imgui.Text(u8"Может появиться если вы не создали транспорт через меню транспорта, но пытаетесь при этом применить к нему какие-либо действия.")
	   end	   
	   
	   if imgui.CollapsingHeader(u8'Ошибка. Установи 0.3DL чтоб включать полет в этом месте') then
          imgui.Text(u8"Необходимо устанавливать новый DL клиент с samp-ru, либо уходить в полет с другой точки где мало объектов рядом (выйти из зоны стрима).")
	   end
	   
	   if imgui.CollapsingHeader(u8'При создании нового или копировании объекта, он не выделяется автоматически') then
          imgui.Text(u8"Такой эффект может наблюдаться при большом количестве объектов в мире\nили нажатии ESC в полете либо меню. Его уже исправили в клиенте от абс.\nДля временного решения можете использовать функцию - выделить объект стоящий рядом.\n")
	   end
	   
	   if imgui.CollapsingHeader(u8'Объект рябит(мерцает) на стыке') then
          imgui.Text(u8"Необходимо передвинуть объект на стыке чуть выше или в сторону")
	   end
	   
	   if imgui.CollapsingHeader(u8'В полете не работает меню на N') then
          imgui.Text(u8"Необходимо установите samp addon\n(команду для вызова меню разработчик не предоставил)")
	   end
	   
	   if imgui.CollapsingHeader(u8'Транспорт не удаляется') then
          imgui.Text(u8"В своем мире через меню управления транспортом\nвы можете удалять только созданный вами транспорт.\nЗаказной и домашний транспорт игроков удален при этом не будет.\nВы можете выставить 0 хп транспорту рядом\nэто не удалит транспорт но позволит отправить его на точку спавна.\nЧтобы после взрыва транспорт удалился включите опцию\n(N - Транспорт - Удаление созданного транспорт а после взрыва)")
	   end

	   if imgui.CollapsingHeader(u8'У игроков есть оружие на руках, но они не могут его использовать. (как на зоне новичков).') then
          imgui.Text(u8"Отключите зеленую зону.  N - Оружие - Зеленая зона.")
	   end	   

	   if imgui.CollapsingHeader(u8'Маркер ближайшего пикапа не пропадает после удаления.') then
          imgui.Text(u8"Просто перезайдите в мир чтобы маркер исчез.")
	   end	 
	   
	   if imgui.CollapsingHeader(u8'Маркеры от гонки не скрываются после завершения редактирования.') then
          imgui.Text(u8"Вы завершили создание гонки и хотите скрыть маркеры.\nДля того чтобы скрыть маркеры от созданной гонки выберите подменю список гонок — выбрать слот.")
	   end	 
	   
	   imgui.TextColoredRGB("Оригинал темы посмотрите на форуме {007DFF}https://forum.sa-mp.ru/index.php?/topic/1016828-миры-редактор-карт-faq/")
	   if imgui.IsItemClicked() then
		 setClipboardText("https://forum.sa-mp.ru/index.php?/topic/1016828-миры-редактор-карт-faq/")
		 printStringNow("url copied to clipboard", 1000)
	   end
	   
	   imgui.End()
	end
	   
    if show_worldlimits.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 10, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  
       imgui.Begin(u8"Лимиты", show_worldlimits)
	   imgui.Text(u8"Каждый игрок от 20 уровня может при наличии свободных слотов создать свой мир для строительства.")
	   imgui.TextColoredRGB("Для создания мира необходимо иметь {00FF00}100 ОА (Очков апгрейда) и 1.000.000$.{FFFFFF}")
       imgui.TextColoredRGB("По умолчанию в мире можно создавать только {00FF00}50 объектов, лимит можно расширить до {00FF00}300{FFFFFF}.")
	   imgui.TextColoredRGB("VIP игроки могут расширять лимит до {00FF00}2000 объектов.{FFFFFF}")
	   imgui.TextColoredRGB("Стоимость расширения мира {00FF00}20 ОА и 500.000$ за 10 объектов.{FFFFFF}") 
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
	   imgui.TextColoredRGB("Максимальная длина текста на объектах в редакторе миров - {00FF00}50 символов")
       imgui.End()
	end
	
	if show_settings.v then	  
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	 
       imgui.Begin(u8"Настройки", show_settings)
       if imgui.Checkbox(u8("Фильтр подключений в чате"), checkbox_chatfilter) then
	      if checkbox_chatfilter.v then
	         ini.settings.chatfilter = not ini.settings.chatfilter
			 save()
          end
	   end
	   
       imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Убирает сообщения о подключениях-отключениях игроков в общм чате")
	   
   	   if imgui.Checkbox(u8("Анти-афк"), checkbox_antiafk) then 
	      if checkbox_antiafk.v then
			 ini.settings.antiafk = not ini.settings.antiafk
			 save()
		  end
	   end
	   
       imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"При сворачивании окна игрок не быдет уходить в афк")

	   if imgui.Checkbox(u8("Фикс горячих клавиш аддона"), checkbox_keybinds) then 
	      if checkbox_keybinds.v then
	         ini.settings.keybinds = not ini.settings.keybinds
			 save()
	      end
	   end
       imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Восстанавливает стандартные горячие клавиши доступные с samp addon")

       if imgui.Checkbox(u8("Включить фиксы samp addon"), checkbox_addonfixes) then 
	     if checkbox_addonfixes.v then
	         ini.settings.addonfixes = not ini.settings.addonfixes
			 save()
	      end
	   end
       imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Включает фиксы как в samp аддоне")
	   
	   if imgui.Checkbox(u8"Отключить эффекты", checkbox_noeffects) then
		  if checkbox_noeffects.v then
		     ini.settings.noeffects = not ini.settings.noeffects
			 save() 
	      end
	   end
	   
       imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Отключает эффекты дыма, пыли, тени (требуется релог)")

	   if imgui.Checkbox(u8(ini.settings.showhud and 'Скрыть' or 'Показать')..u8" HUD",
	   checkbox_showhud) then
	      ini.settings.showhud = not ini.settings.showhud
		  save()
		  if ini.settings.showhud then
			 displayHud(true)
             memory.setint8(0xBA676C, 0)
	      else
		     displayHud(false)
             memory.setint8(0xBA676C, 2)
			 -- remove server logo
			 sampTextdrawDelete(2048)
             sampTextdrawDelete(420)
		  end
	   end
       imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Скрывает HUD и логотип Absolute DM ")
	   
	   if imgui.Checkbox(u8"Активировать nopostfx", checkbox_nopostfx) then
	      ini.settings.nopostfx = not ini.settings.nopostfx
		  save()
	      memory.fill(0x53EAD3, 0x90, 5, true)
	   end
       imgui.SameLine()
       imgui.TextQuestion("( ? )", u8"Отключает пост-обработку (PostFX), рекомендуется использовать только для тестов (вернуть обратно только релогом)")
	   
	   -- Thanks samp++
	   imgui.Text(u8"Дальность прорисовки:")
	   if imgui.SliderInt(u8"##Drawdist", sliderdrawdist, 50, 3000) then
		  ini.settings.drawdist = sliderdrawdist.v
		  save()
		  memory.setfloat(12044272, ini.settings.drawdist, true)
	   end
		
	   imgui.Text(u8"Дальность тумана:")
	   if imgui.SliderInt(u8"##fog", sliderfog, -390, 390) then
		  ini.settings.fog = sliderfog.v
		  save()
		  memory.setfloat(13210352, ini.settings.fog, true)
	   end
	   
	   if imgui.Button(u8"Перегрузить скрипт", imgui.ImVec2(200, 25)) then
		  thisScript():reload()
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Выгрузить скрипт", imgui.ImVec2(200, 25)) then
	      sampAddChatMessage("Скрипт AbsEventHelper успешно выгружен.", -1)
		  sampAddChatMessage("Для запуска используйте комбинацию клавиш CTRL + R.", -1)
		  thisScript():unload()
	   end
       
	   if imgui.Button(u8"Проверить обновления", imgui.ImVec2(200, 25)) then
	      os.execute('explorer "https://github.com/ins1x/AbsEventHelper"')
		  printStringNow("Url opened in default webbrowser", 3000)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Обновить конфиг", imgui.ImVec2(200, 25)) then
		  inicfg.save(ini, configIni)
	   end
	   
       imgui.End()
	end
	
	if show_coords.v then	  
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   
       imgui.Begin(u8"Координаты", show_coords)
       
       local positionX, positionY, positionZ = getCharCoordinates(PLAYER_PED)
	   imgui.Text(string.format(u8"Позиция x: %.1f, y: %.1f, z: %.1f",
	   positionX, positionY, positionZ))
	  
	   imgui.Text(string.format(u8"Направление: %s", direction()))

       if imgui.Button(u8"Получить координаты", imgui.ImVec2(250, 25)) then
	      if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
		     sampSendChat("/коорд")
			 tpposX, tpposY, tpposZ = getCharCoordinates(PLAYER_PED)
			 setClipboardText(math.floor(tpposX) .. ' ' .. math.floor(tpposY) .. ' ' .. math.floor(tpposZ))
			 sampAddChatMessage("Координаты сохранены в буфер", 0x0FFFFFF)
			 sampAddChatMessage(string.format("Интерьер: %i", getActiveInterior()), 0x0FFFFFF)
		  end
	   end
	  
	   if imgui.Button(u8"Телепорт по кординатам", imgui.ImVec2(250, 25)) then
		  if tpposX then
	         sampSendChat(string.format("/ngr %f %f %f", tpposX, tpposY, tpposZ), 0x0FFFFFF)
		     sampAddChatMessage(string.format("Вы были телепортированны на сохранненые координаты %f %f %f"
			,tpposX, tpposY, tpposZ), 0x0FFFFFF)
		  else
		     sampAddChatMessage("Координаты не были сохранены. Нажмите коорд", 0x0FFFFFF)
		  end
	   end
	  
	   if imgui.Button(u8"Прыгнуть вперед", imgui.ImVec2(250, 25)) then
		  if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/ghsu") end
	   end

       imgui.End()
	end

	if show_credits.v then	  
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 4),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   
       imgui.Begin(u8"О скрипте v".. thisScript().version, show_credits)
       imgui.Text(u8"Автор: 1NS (Git: in1x)")
       imgui.Text(u8"Помошник для мапперов и организаторов мероприятий на Absolute DM")
	   imgui.TextColoredRGB("Homepage: {007DFF}github.com/ins1x/AbsEventHelper")
	   if imgui.IsItemClicked() then
	  	  setClipboardText("github.com/ins1x/AbsEventHelper")
		  printStringNow("Url copied to clipboard", 1000)
	   end
       imgui.TextColoredRGB("Русскоязычное сообщество мапперов: {007DFF}vk.com/1nsanemapping")
	   if imgui.IsItemClicked() then
	  	  setClipboardText("vk.com/1nsanemapping")
		  printStringNow("Url copied to clipboard", 1000)
	   end
       imgui.TextColoredRGB("Сайт Absolute Play: {007DFF}gta-samp.ru")
	   if imgui.IsItemClicked() then
	  	  setClipboardText("gta-samp.ru")
		  printStringNow("Url copied to clipboard", 1000)
	   end
       imgui.TextColoredRGB("Чат Absolute Play DM: {007DFF}dsc.gg/absdm")
	   if imgui.IsItemClicked() then
	  	  setClipboardText("dsc.gg/absdm")
		  printStringNow("Url copied to clipboard", 1000)
	   end
	   imgui.Text(u8"Disclaimer: Автор не является частью команды проекта Absolute Play")
	   imgui.Text(" ")
       imgui.Text(u8"Credits:")
	   imgui.Text(u8"EvgeN 1137, hnnssy, FYP - Moonloader")
       imgui.Text(u8"FYP - imgui, SAMP lua library")
       imgui.Text(u8"Gorskin - useful code snippets and memory hacks")
       imgui.Text(u8"Pawnokit.ru - specsymbols images")
       imgui.End()
	end 
	
	if show_notepad.v then
	   imgui.SetNextWindowPos(imgui.ImVec2(sizeY / 4, sizeY / 2),
	   imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   imgui.SetNextWindowSize(imgui.ImVec2(310, 210), imgui.Cond.FirstUseEver)
	   imgui.Begin(u8"Блокнот", show_notepad)
	   
	   imgui.InputTextMultiline('##bufftext', note_textbuffer, imgui.ImVec2(285, 125))

	   if imgui.Button(u8"Сохранить", imgui.ImVec2(85, 25)) then
	      file = io.open(getGameDirectory().."//moonloader//resource//abseventhelper//notes.txt", "w")
          file:write(note_textbuffer.v)
          file:close()
		  printStringNow("Saved moonloader/resource/abseventhelper/notes.txt", 4000)
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Очистить", imgui.ImVec2(85, 25)) then
	      note_textbuffer.v = u8" "
	   end
	   
	   imgui.SameLine()
	   if imgui.Button(u8"Скрыть", imgui.ImVec2(85, 25)) then
	      show_notepad.v = not show_notepad.v
	   end
	   
	   imgui.End()
	end 
end

function main()
   if not isSampLoaded() or not isSampfuncsLoaded() then return end
      while not isSampAvailable() do wait(100) end
	  sampAddChatMessage("" .. tag, 0xFFFFFF)
	  local ip, port = sampGetCurrentServerAddress()
	  if not ip:find(hostip) then
	     ini.settings.keybinds = false
	     -- sampAddChatMessage("Keybinds work only Absolute DM", 0x00FF0000)
	  end
	
	  if not doesDirectoryExist("moonloader/resource/abseventhelper") then 
	     createDirectory("moonloader/resource/abseventhelper")
	  end
	  
	  local texture1 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\texture1.jpg')
	  local texture2 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\texture2.jpg')
	  local texture3 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\texture3.jpg')
	  local texture4 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\texture4.jpg')
	  local texture5 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\texture5.jpg')
	  
	  -- Rights to the images belong to the pawnokit project
	  -- https://pawnokit.ru/ru/spec_symbols
	  local fontsimg1 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\fGTAWeapon3.jpg')
	  local fontsimg2 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\fWebdingsEN.jpg')
	  local fontsimg3 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\fWebdingsRU.jpg')
	  local fontsimg4 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\fWingdingsEN.jpg')
	  local fontsimg5 = renderLoadTextureFromFile(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\fWingdingsRU.jpg')
	  
      -- commands section
	  sampRegisterChatCommand("abshelper", function ()
         main_window_state.v = not main_window_state.v 
	  end)
	  
	  sampRegisterChatCommand("note", function ()
         main_window_state.v = true
         show_notepad.v = not show_notepad.v 
	  end)

      sampRegisterChatCommand("chatbinds", function ()
         main_window_state.v = true
         show_chatbinds.v = not show_chatbinds.v 
	  end)

      sampRegisterChatCommand("players", function ()
         main_window_state.v = true
         show_players.v = not show_players.v 
	  end)

      sampRegisterChatCommand("vehicles", function ()
         main_window_state.v = true
         show_vehs.v = not show_vehs.v 
	  end)
	  
	  sampRegisterChatCommand("objectrender", function ()
         showobjects = not showobjects
	  end)
      
	  -- set drawdist and figdist
	  memory.setfloat(12044272, ini.settings.drawdist, true)
      memory.setfloat(13210352, ini.settings.fog, true)
	  
	  -- dirty hack nop F1 and F4 keys functions
	  require('memory').setuint8(getModuleHandle('samp.dll') + 0x67450, 0xC3, true)
	  memory.write(sampGetBase()+0x797E, 0, 1, true)
	  
	  if(ini.settings.addonfixes) then
	     -- other fixes
		 memory.write(0x745BC9, 0x9090, 2, false) --SADisplayResolutions(1920x1080// 16:9)
         memory.fill(0x460773, 0x90, 7, false) --CJFix
		 memory.setuint32(0x736F88, 0, false) -- the helicopter doesn't explode many times
		 memory.write(8931716, 0, 4, false) -- fix blackroads
		 
	     -- fps fix
         memory.write(0x53E94C, 0, 1, false) --del fps delay 14 ms
         memory.setuint32(12761548, 1051965045, false) -- car speed fps fix
		 
		 -- birds on
		 memory.write(5497200, 232, 1, false)
         memory.write(5497201, 1918619, 4, false)
		 
		 -- interior reflections
		 memory.write(0x555854, 0x90909090, 4, false)
         memory.write(0x555858, 0x90, 1, false)
		 
		 -- interior run
		 memory.write(5630064, -1027591322, 4, false)
         memory.write(5630068, 4, 2, false)
		 
		 -- fixing spawn with a bottle
		 memory.fill(0x4217F4, 0x90, 21, false)
         memory.fill(0x4218D8, 0x90, 17, false)
         memory.fill(0x5F80C0, 0x90, 10, false)
         memory.fill(0x5FBA47, 0x90, 10, false)
	  end
	  
	  if(ini.settings.noeffects) then
	     -- no smoke and decorative flame
	     memory.hex2bin('8B4E08E88B900000', 0x4A125D, 8)
		 
		 -- nodust
		 memory.write(7205311, 1056964608, 4, false)
		 memory.write(7205316, 1065353216, 4, false)
		 memory.write(7205321, 1065353216, 4, false)
		 memory.write(7205389, 1056964608, 4, false)
		 memory.write(7204123, 1050253722, 4, false)
		 memory.write(7204128, 1065353216, 4, false)
		 memory.write(7204133, 1060320051, 4, false)
		 memory.write(5527777, 1036831949, 4, false)
		 memory.write(4846974, 1053609165, 4, false)
		 memory.write(4846757, 1053609165, 4, false)
		 
		 -- noshadows
         memory.write(5497177, 233, 1, false)
		 memory.write(5489067, 492560616, 4, false)
		 memory.write(5489071, 0, 1, false)
		 memory.write(6186889, 33807, 2, false)
		 memory.write(7388587, 111379727, 4, false)
		 memory.write(7388591, 0, 2, false)
		 memory.write(7391066, 32081167, 4, false)
		 memory.write(7391070, -1869611008, 4, false)
	  end
	  
	  if(ini.settings.nopostfx) then
	     memory.fill(0x53EAD3, 0x90, 5, true)
	  end
	  --- END init
	  while true do
	  wait(0)
	  
	  local imgX, imgY = 770, 480 -- image size
	  
	  if(show_textures.v) then
		  if show_texture1 then
			 renderDrawTexture(texture1, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2,imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_texture2 then
			 renderDrawTexture(texture2, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_texture3 then
			 renderDrawTexture(texture3, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_texture4 then
			 renderDrawTexture(texture4, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_texture5 then
			 renderDrawTexture(texture5, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
	  end
	  
	  local imgX, imgY = 500, 450 -- image size
	  
	  if(show_fonts.v) then
	      if show_fontsimg1 then
			 renderDrawTexture(fontsimg1, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_fontsimg2 then
			 renderDrawTexture(fontsimg2, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_fontsimg3 then
			 renderDrawTexture(fontsimg3, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_fontsimg4 then
			 renderDrawTexture(fontsimg4, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
		  
		  if show_fontsimg5 then
			 renderDrawTexture(fontsimg5, (sizeX - imgX) / 2,
			 (sizeY - imgY) / 2, imgX, imgY, 0, 0xffffffff)
		  end
	   end
	   
	  -- Imgui menu
	  imgui.Process = main_window_state.v
	  
	  -- chatfix
	  if isKeyJustPressed(0x54) and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
	     sampSetChatInputEnabled(true)
	  end
	  
	  -- antiafk 
      if ini.settings.antiafk then
         writeMemory(7634870, 1, 1, 1)
         writeMemory(7635034, 1, 1, 1)
         memory.fill(7623723, 144, 8)
         memory.fill(5499528, 144, 6)
	  else
	     memory.setuint8(7634870, 0, false)
         memory.setuint8(7635034, 0, false)
         memory.hex2bin('0F 84 7B 01 00 00', 7623723, 8)
         memory.hex2bin('50 51 FF 15 00 83 85 00', 5499528, 6)
	  end
	  
	  -- Absolute Play Key Binds
	  -- Sets hotkeys that are only available with the samp addon
	  if ini.settings.keybinds then
         if isKeyJustPressed(VK_Z) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/xbybnm") end
	 
         if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/vfibye2") end

         if isKeyJustPressed(VK_M) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/vfibye") end
	  
         if isKeyJustPressed(VK_U) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/anim") end
	  
         if isKeyJustPressed(VK_J) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then sampSendChat("/gjktn") end
	  
         if isKeyJustPressed(VK_H) and isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then  sampSendChat("/f") end
		 
      end
	  
	  -- ALT+X (Activation combination)
      if isKeyDown(VK_MENU) and isKeyJustPressed(VK_X) and not sampIsChatInputActive() and not    sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
         if showobjects then showobjects = false end
		 main_window_state.v = not main_window_state.v 
      end
	  
	  -- Objects render
	  if showobjects and not isPauseMenuActive() then
	     for _, v in pairs(getAllObjects()) do
		    if isObjectOnScreen(v) then
			   local _, x, y, z = getObjectCoordinates(v)
			   local x1, y1 = convert3DCoordsToScreen(x,y,z)
			   local model = getObjectModel(v)
			   renderFontDrawText(font, "{80FFFFFF}" .. model, x1, y1, -1)
			end
		 end
	  end
	  
	  -- Collision
	  if disableObjectCollision then
         find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
         result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
         if result then
		    setObjectCollision(objectHandle, false)
			table.insert(objectsDel, objectHandle, objectHandle)			
			--setObjectCollisionDamageEffect(objectHandle, false)
         end
      end
	  
	  -- END main
   end
end

function sampev.onPlayerQuit(id, reason)
   local nick = sampGetPlayerNickname(id)
   
   if reason == 0 then reas = 'Выход'
   elseif reason == 1 then reas = 'Кик/бан'
   elseif reason == 2 then reas = 'Вышло время подключения'
   end
   
   for key, value in ipairs(playersTable) do
	   if key then 
	      sampAddChatMessage("Игрок " .. nick .. " вышел по причине " .. reas, 0xFFFF00)
	   end
   end
end

function sampev.onServerMessage(color, text)
   if ini.settings.chatfilter then 
      if text:find("подключился к серверу") or text:find("вышел с сервера") then
		 --if text:find("соклан") then return true	end
		 chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
		 chatlog:write(os.date("[%H:%M:%S] ")..text)
		 chatlog:write("\n")
	     chatlog:close()
	     return false
	  end
		
	  if text:find("выхода из читмира") then
		 return false
	  end
   end
end

function sampev.onScriptTerminate(script, quitGame)
    if script == thisScript() then
        if not sampIsDialogActive() then
            showCursor(false)
        end
        sampAddChatMessage("Скрипт аварийно завершил свою работу. Для перезагрузки нажмите CTRL + R.", -1)
    end
end

-- END hooks

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

function hideAllFontsImages()
   show_fontsimg1 = false
   show_fontsimg2 = false
   show_fontsimg3 = false
   show_fontsimg4 = false
   show_fontsimg5 = false
end

function hideAllTextureImages()
   show_texture1 = false
   show_texture2 = false
   show_texture3 = false
   show_texture4 = false
   show_texture5 = false
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

function imgui.TextQuestion(label, description)
    imgui.TextDisabled(label)

    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
                imgui.TextUnformatted(description)
            imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function apply_custom_style()
   imgui.SwitchContext()
   local style = imgui.GetStyle()
   local colors = style.Colors
   local clr = imgui.Col
   local ImVec4 = imgui.ImVec4

   style.WindowPadding = imgui.ImVec2(15, 15)
   style.WindowRounding = 1.5
   style.FramePadding = imgui.ImVec2(5, 5)
   style.FrameRounding = 4.0
   style.ItemSpacing = imgui.ImVec2(12, 8)
   style.ItemInnerSpacing = imgui.ImVec2(8, 6)
   style.IndentSpacing = 25.0
   style.ScrollbarSize = 15.0
   style.ScrollbarRounding = 9.0
   style.GrabMinSize = 5.0
   style.GrabRounding = 3.0

   colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
   colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
   colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
   colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
   colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
   colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
   colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
   colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
   colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
   colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
   colors[clr.TitleBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
   colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
   colors[clr.TitleBgActive] = ImVec4(0.07, 0.07, 0.09, 1.00)
   colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
   colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
   colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
   colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
   colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
   colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
   colors[clr.CheckMark] = ImVec4(0.80, 0.80, 0.83, 0.31)
   colors[clr.SliderGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
   colors[clr.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
   colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
   colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
   colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
   colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
   colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
   colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
   colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
   colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
   colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
   colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
   colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
   colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
   colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
   colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
   colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
   colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
   colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
   colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
apply_custom_style()
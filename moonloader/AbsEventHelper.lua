script_author("1NS")
script_name("Absolute Events Helper")
script_description("Assistant for mappers and event makers on Absolute Play")
script_dependencies('imgui', 'lib.samp.events', 'vkeys')
script_properties("work-in-pause")
script_url("https://github.com/ins1x/AbsEventHelper")
script_version("2.5")
-- script_moonloader(16) moonloader v.0.26

-- Activaton: ALT + X (show main menu)
-- Lot of functions only work on Absolute Play servers
-- Blast.hk thread: https://www.blast.hk/threads/200619/

require 'lib.moonloader'
local keys = require 'vkeys'
local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local memory = require 'memory'
local vector3D = require 'vector3d'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

------------------------[ cfg ] -------------------
local inicfg = require 'inicfg'
local configIni = "AbsEventHelper.ini"
local ini = inicfg.load({
   settings =
   {
      showhud = true,
      noabsunload = false,
      autoupdplayerstable = false,
      disconnectreminder = true,
      lockserverweather = false,
      usecustomcamdist = false,
	  showobjectrot = false,
      drawdist = "450",
      fog = "200",
	  camdist = "1",
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
      textbuffer8 = " ",
      textbuffer9 = " ",
      textbuffer10 = " ",
      adtextbuffer = " "
   }
}, configIni)
inicfg.save(ini, configIni)

function save()
    inicfg.save(ini, configIni)
end
---------------------------------------------------------

objectsrenderfont = renderCreateFont("Arial", 7, 5)
local sizeX, sizeY = getScreenResolution()
local v = nil
local color = imgui.ImFloat4(1, 0, 0, 1)
local lastObjectCoords = {x=0.0, y=0.0, z=0.0, rx=0.0, ry=0.0, rz=0.0}
local lastRemovedObjectCoords = {x=0.0, y=0.0, z=0.0, rx=0.0, ry=0.0, rz=0.0}
local gamestates = {'None', 'Wait Connect', 'Await Join', 'Connected', 'Restarting', 'Disconnected'}
local gamestate = imgui.ImInt(0)
local fixcam = {x = 0.0, y = 0.0, z = 0.0}
local tpcpos = {x = 0.0, y = 0.0, z = 0.0}
local tpc = { 
   public = {x = 0, y = 0, z = 0},
   private = {x = 0, y = 0, z = 0},
   static = {x = 0, y = 0, z = 0}
}

local dialog = {
   main = imgui.ImBool(false),
   textures = imgui.ImBool(false),
   playerstat = imgui.ImBool(false),
   extendedtab = imgui.ImBool(false),
   objectinfo = imgui.ImBool(false),
   fastanswer = imgui.ImBool(false)
}

local checkbox = {
   showhud = imgui.ImBool(ini.settings.showhud),
   noabsunload = imgui.ImBool(ini.settings.noabsunload),
   autoupdplayerstable = imgui.ImBool(ini.settings.autoupdplayerstable),
   disconnectreminder = imgui.ImBool(ini.settings.disconnectreminder),
   lockserverweather = imgui.ImBool(ini.settings.lockserverweather),
   usecustomcamdist = imgui.ImBool(ini.settings.usecustomcamdist),
   radarblips = imgui.ImBool(false),
   showobjectrot = imgui.ImBool(ini.settings.showobjectrot),
   showobjects = imgui.ImBool(false),
   showclosestobjects = imgui.ImBool(false),
   drawlinetomodelid = imgui.ImBool(false),
   vehstream = imgui.ImBool(true),
   noempyvehstream = imgui.ImBool(true),
   heavyweaponwarn = imgui.ImBool(true),
   nametagwh = imgui.ImBool(false),
   hideobject = imgui.ImBool(false),
   lockfps = imgui.ImBool(false),
   changefov = imgui.ImBool(false),
   fixcampos = imgui.ImBool(false),
   teleportcoords = imgui.ImBool(false),
   tpcprotect = imgui.ImBool(false),
   logtextdraws = imgui.ImBool(false),
   logdialogresponse = imgui.ImBool(false),
   logobjects = imgui.ImBool(false),
   logtxd = imgui.ImBool(false),
   pickeduppickups = imgui.ImBool(false),
   showtextdrawsid = imgui.ImBool(false),
   nophealth = imgui.ImBool(false),
   vehloads = imgui.ImBool(false),
   shadows = imgui.ImBool(false),
   noeffects = imgui.ImBool(false),
   nofactorysmoke = imgui.ImBool(false),
   nowater = imgui.ImBool(false),
   aniso = imgui.ImBool(false),
   postfx = imgui.ImBool(true),
   grassfix = imgui.ImBool(false),
   blur = imgui.ImBool(false),
   sunfix = imgui.ImBool(false),
   nightvision = imgui.ImBool(false),
   infraredvision = imgui.ImBool(false),
   lightmap = imgui.ImBool(false),
   hidealltextdraws = imgui.ImBool(false),
   objectcollision = imgui.ImBool(false),
   changemdo = imgui.ImBool(false),
   test = imgui.ImBool(false)
}

local input = {
   hideobjectid = imgui.ImInt(615),
   mdomodel = imgui.ImInt(0),
   mdodist = imgui.ImInt(100),
   rendselectedmodelid = imgui.ImInt(0),
   closestobjectmodel = imgui.ImInt(0)
}

local slider = {
   fog = imgui.ImInt(ini.settings.fog),
   drawdist = imgui.ImInt(ini.settings.drawdist),
   weather = imgui.ImInt(0),
   time = imgui.ImInt(12),
   fov = imgui.ImInt(0),
   camdist = imgui.ImInt(ini.settings.camdist)
}

local tabmenu = {
   main = 1,
   objects = 1,
   settings = 1,
   info = 1,
   cmds = 1
}

local textbuffer = {
   vehiclename = imgui.ImBuffer(128),
   bind1 = imgui.ImBuffer(256),
   bind2 = imgui.ImBuffer(256),
   bind3 = imgui.ImBuffer(256),
   bind4 = imgui.ImBuffer(256),
   bind5 = imgui.ImBuffer(256),
   bind6 = imgui.ImBuffer(256),
   bind7 = imgui.ImBuffer(256),
   bind8 = imgui.ImBuffer(256),
   bind9 = imgui.ImBuffer(256),
   bind10 = imgui.ImBuffer(256),
   bindad = imgui.ImBuffer(256),
   findplayer = imgui.ImBuffer(32),
   findlog = imgui.ImBuffer(128),
   ckeckplayer = imgui.ImBuffer(32),
   objectid = imgui.ImBuffer(6),
   rgb = imgui.ImBuffer(256),
   fixcamx = imgui.ImBuffer(12),
   fixcamy = imgui.ImBuffer(12),
   fixcamz = imgui.ImBuffer(12),
   tpcx = imgui.ImBuffer(12),
   tpcy = imgui.ImBuffer(12),
   tpcz = imgui.ImBuffer(12),
   note = imgui.ImBuffer(1024),
   texturesbuff = imgui.ImBuffer(1024)
}

local combobox = {
   item1 = imgui.ImInt(0),
   item2 = imgui.ImInt(0),
   item3 = imgui.ImInt(0),
   item4 = imgui.ImInt(0),
   item5 = imgui.ImInt(0),
   item6 = imgui.ImInt(0),
   item7 = imgui.ImInt(0),
   item8 = imgui.ImInt(0),
   item9 = imgui.ImInt(0),
   item10 = imgui.ImInt(0),
   profiles = imgui.ImInt(0),
   selecttable = imgui.ImInt(0),
   objects = imgui.ImInt(6),
   itemad = imgui.ImInt(0),
   logs = imgui.ImInt(0)
}

-- If the server changes IP, change it here
local ipAbsolutePlay = "193.84.90.23"
local isAbsolutePlay = false
local ipTraining = "46.174.50.168"
local isTraining = false

local isSampAddonInstalled = false
local isAbsfixInstalled = false
local isPlayerSpectating = false
local disableObjectCollision = false
local prepareTeleport = false
local smoothTeleport = false
local prepareJump = false
local showobjects = false
local showrenderline = false
local countobjects = true
local ENBSeries = false
local chosenplayer = nil
local tabselectedplayer = nil
local lastObjectModelid = nil
local lastRemovedObjectModelid = nil
local lastObjectId = nil
local lastObject = nil
local lastObjectlibraryName = nil
local lastObjecttextureName = nil
local lastObjecttexturesrcID = nil
local hide3dtexts = false
local nameTag = true
local nameTagWh = false
local currentEditmode = 0 
local isSelectObject = false
local isTexturesListOpened = false
local hideEditObject = false
local scaleEditObject = false
local lastObjectBlip = nil
local lastObjectHidden = true
local lastWorldNumber = 0 -- is not same GetVirtualWorldId
--local hideTextdraws = true
local removedBuildings = 0;
streamedObjects = 0

local fps = 0
local fps_counter = 0
local vehinfomodelid = 0 

local objectsCollisionDel = {}
local playersTable = {}
local vehiclesTable = {}
local hiddenObjects = {}
vehiclesTotal = 0
playersTotal = 0

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

AbsTxdNames = {
   "invalid", "vent_64", "alleydoor3", "sw_wallbrick_01", "sw_door11",
   "newall4-4", "rest_wall4", "crencouwall1", "mp_snow", "mottled_grey_64HV",
   "marblekb_256128", "Marble2", "Marble", "DinerFloor", "concretebig3_256",
   "Bow_Abattoir_Conc2", "barbersflr1_LA", "ws_green_wall1", "ws_stationfloor",
   "Slabs", "Road_blank256HV", "gun_ceiling3", "dts_elevator_carpet2",
   "cj_white_wall2", "cj_sheetmetal2", "CJ_RUBBER", "CJ_red_COUNTER", "CJ_POLISHED",
   "cj_juank_1", "CJ_G_CHROME", "cj_chromepipe", "CJ_CHROME2", "CJ_CHIP_M2",
   "CJ_BLACK_RUB2", "ceiling_256", "bigbrick", "airportmetalwall256", "CJ_BANDEDMETAL",
   "sky33_64hv", "plainwoodoor2", "notice01_128", "newall15128", "KeepOut_64",
   "HospitalCarPark_64", "hospitalboard_128a", "fire_exit128", "dustyconcrete128",
   "cutscenebank128", "concretenew256", "banding9_64HV", "AmbulanceParking_64",
   "Alumox64", "tenwhite128", "tarmac_64HV", "sandytar_64HV", "LO1road_128",
   "indsmallwall64", "Grass_128HV", "firewall", "rack", "metal6", "metal5",
   "metal2", "metal1", "Grass", "dinerfloor01_128", "concretebig3_256",
   "wallmix64HV", "Road_yellowline256HV", "newallktenb1128", "newallkb1128",
   "newall9-1", "newall10_seamless", "forestfloor3", "bricksoftgrey128",
   "tenbeigebrick64", "tenbeige128", "indtena128", "artgal_128", "alleypave_64V",
   "taxi_256128", "walldirtynewa256128", "wallbrown02_64HV", "TENterr2_128",
   "TENdbrown5_128", "TENdblue2_128", "tenabrick64", "indtena128", "indten2btm128",
   "chipboardgrating64HV", "waterclear256", "sw_grass01", "newgrnd1brntrk_128",
   "grassdeep1blnd", "grassdeep1", "desertstones256grass", "cuntbrnclifftop",
   "cuntbrncliffbtmbmp", "planks01", "Gen_Scaffold_Wood_Under", "crate128",
   "cj_crates", "newall2_16c128", "ws_oldwall1", "telepole128", "sw_shedwindow1",
   "steel128", "skyclouds", "rocktb128", "plaintarmac1", "newall9b_16c128",
   "LoadingDoorClean", "metaldoor01_256", "des_sherrifwall1", "corrRoof_64HV",
   "concretenewb256", "chevron_red_64HVa", "Bow_stained_wall", "beigehotel_128",
   "warnsigns2", "BLOCK", "sw_sand", "sandnew_law", "rocktq128_dirt", "rocktbrn128",
   "des_dirt1", "desertstones256", "cw2_mounttrailblank", "bonyrd_skin2", "sam_camo",
   "a51_intdoor", "a51_blastdoor", "washapartwall1_256", "ws_carparkwall2", "girder2_grey_64HV",
   "jumptop1_64", "ammotrn92crate64", "nopark128", "iron", "ADDWOOD", "tatty_wood_1",
   "nf_blackbrd", "brk_ball1", "brk_Ball2", "cargo_gir3", "cargo_pipes", "cargo_ceil2",
   "cargo_top1", "cargo_floor2", "cargo_floor1", "cargo_gir2", "ws_carrierdeckbase",
   "ab_wood1", "wall1", "motel_wall4", "mp_diner_ceilingdirt", "mp_burn_wall1",
   "frate64_yellow", "frate_doors64yellow", "frate64_red", "frate_doors128red",
   "frate_doors64", "frate64_blue", "ct_stall1", "liftdoorsac128", "Metalox64",
   "redmetal", "snpedtest1", "banding8_64", "skip_rubble1", "metpat64",
   "walldirtynewa256", "skipY", "vendredmetal", "hazardtile13-128x128", "metalox64",
   "cj_lightwood", "metalalumox1", "wood1", "rockbrown1", "foil1-128x128", "foil2-128x128",
   "foil3-128x128", "foil4-128x128", "foil5-128x128", "mp_bobbie_pompom", "mp_bobbie_pompom1",
   "mp_bobbie_pompom2", "goldplated1", "gen_log", "stonefloortile13", "dts_elevator_door",
   "dts_elevator_woodpanel", "dts_elevator_carpet2", "dt_officflr2", "conc_wall2_128H",
   "sl_stapldoor1", "ws_gayflag1", "brick008", "yello007", "metal013", "knot_wood128",
   "stonewalltile1-5", "stonewalltile1-3", "stonewall4", "metallamppost4", "DanceFloor1",
   "hazardtile19-2", "concreteoldpainted1", "hazardtile15-3", "sampeasteregg",
   "stonewalltile1-2", "silk5-128x128", "silk6-128x128", "silk8-128x128", "silk9-128x128",
   "silk7-128x128", "wrappingpaper4-2", "wrappingpaper1", "wrappingpaper16", "wrappingpaper20",
   "wrappingpaper28", "CJ-COUCHL1", "metaldrumold1", "metalplate23-3", "gtasavectormap1",
   "gtasamapbit1", "gtasamapbit2", "gtasamapbit3", "gtasamapbit4", "rustyboltpanel",
   "planks01", "wallgarage", "floormetal1", "WoodPanel1", "redrailing", "roadguides",
   "cardboard4", "cardboard4-16", "cardboard4-2", "cardboard4-12", "cardboard4-21",
   "knot_woodpaint128", "knot_wood128", "telepole2128", "hazardwall2", "bboardblank_law",
   "ab_sheetSteel", "scratchedmetal", "ws_wetdryblendsand2", "multi086", "wood020",
   "metal1_128", "bluefoil", "truchettiling3-4", "beetles1", "lava1", "garbagepile1",
   "concrete12", "samppicture1", "samppicture2", "samppicture3", "samppicture4", "rocktb128",
   "lavalake", "easter_egg01", "easter_egg02", "easter_egg03", "easter_egg04", "easter_egg05",
   "711_walltemp", "ab_clubloungewall", "ab_corwallupr", "cj_lightwood", "cj_white_wall2",
   "cl_of_wltemp", "copbtm_brown", "gym_floor5", "kb_kit_wal1", "la_carp3",
   "motel_wall3", "mp_carter_bwall", "mp_carter_wall", "mp_diner_woodwall",
   "mp_motel_bluew", "mp_motel_pinkw", "mp_motel_whitewall", "mp_shop_floor2",
   "stormdrain3_nt", "des_dirt1", "desgreengrass", "des_ranchwall1", "des_wigwam",
   "des_wigwamdoor", "des_dustconc", "sanruf", "des_redslats", "duskyred_64",
   "des_ghotwood1", "Tablecloth", "StainedGlass", "Panel", "bistro_alpha"
}

AbsFontNames = {
   "Verdana","Comic Sans MS","Calibri",
   "Cambria","Impact","Times New Roman",
   "Palatino Linotype","Lucida Sans Unicode",
   "Lucida Console","Georgia","Franklin Gothic Medium",
   "Courier New","Corbel","Consolas",
   "Candara","Trebuchet MS","Tahoma",
   "Sylfaen","Segoe UI","Webdings",
   "Wingdings","Symbol","GTAWEAPON3"
}

function commandparser(args)
   if args:find('(.+) (.+)') then
      -- local cmd, name = args:match('(.+) (.+)')
	  -- if cmd:find("add") then
	     -- if name and string.len(name) < 3 then 
		    -- local id = tonumber(name)
		    -- if sampIsPlayerConnected(id) then
		       -- local nickname = sampGetPlayerNickname(id)
			   -- addfriend(nickname)
			   -- return
			-- end
		 -- end
	     -- addfriend(name)
	  -- end
   else
      if args:find('(.+)') then
	     local cmd = args:match('(.+)')
         if cmd then
	  	    if cmd:find("slap") then
               if sampIsLocalPlayerSpawned() then
                  local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                  setCharCoordinates(PLAYER_PED, posX, posY, posZ+1.0)
               end
			   return
	        end
            if cmd:find("jump") then
               if sampIsLocalPlayerSpawned() then
                  JumpForward()
               end
			   return
	        end
            if cmd:find("cc") then
               ClearChat()
			   return
	        end
            if cmd:find("render") then
               checkbox.showobjects.v = not checkbox.showobjects.v
			   return
	        end
            if cmd:find("recon") then
               Recon()
			   return
	        end
            if cmd:find("restream") then
               Restream()
			   return
	        end
	        if cmd:find("help") then
			   return
	        end
	     end
	  else
         dialog.main.v = not dialog.main.v
      end
      dialog.main.v = not dialog.main.v
   end
end

function main()
   if not isSampLoaded() or not isSampfuncsLoaded() then return end
      while not isSampAvailable() do wait(100) end
      local ip, port = sampGetCurrentServerAddress()
      if not ip:find(ipAbsolutePlay) then
	     isAbsolutePlay = false
         if ini.settings.noabsunload then
            thisScript():unload()
         else
            if ip:find(ipTraining) then
               isTraining = true
            end
		    sampAddChatMessage("{880000}Absolute Events Helper.\
		    {FFFFFF}Открыть меню: {CDCDCD}ALT + X", 0xFFFFFF)
		 end
      else
	     isAbsolutePlay = true
         sampAddChatMessage("{880000}Absolute Events Helper.\
		 {FFFFFF}Открыть меню: {CDCDCD}ALT + X", 0xFFFFFF)
      end
      
	  -- Load chat binds
	  reloadBindsFromConfig()
	  
      -- ENB check
      if doesFileExist(getGameDirectory() .. "\\enbseries.asi") or 
      doesFileExist(getGameDirectory() .. "\\d3d9.dll") then
         ENBSeries = true
      end
      
	  -- SAMP Addon check
	  if doesFileExist(getGameDirectory() .. "\\samp.asi") then
         isSampAddonInstalled = true
      end
	  
	  if doesFileExist(getGameDirectory() .. "\\moonloader\\AbsoluteFix.lua") then
	     isAbsfixInstalled = true
	  end
	  
      if not doesDirectoryExist("moonloader/resource/abseventhelper") then 
         createDirectory("moonloader/resource/abseventhelper")
      end
      
      if doesFileExist(getGameDirectory() .. '\\moonloader\\resource\\abseventhelper\\objects.txt') then
         favfile = io.open(getGameDirectory() ..
         "//moonloader//resource//abseventhelper//objects.txt", "r")
         textbuffer.note.v = favfile:read('*a')
         favfile:close()
      end
      
      sampRegisterChatCommand("abs", commandparser)
	  
      -- set drawdist and figdist
      memory.setfloat(12044272, ini.settings.drawdist, true)
      memory.setfloat(13210352, ini.settings.fog, true)
		
      --- END init
      while true do
      wait(0)
      
      -- Imgui menu
      if not ENBSeries then imgui.Process = dialog.main.v end
      
	  -- Camera distantion set
	  if ini.settings.usecustomcamdist then
	     setCameraDistanceActivated(1)
		 setCameraDistance(ini.settings.camdist)
	  end
	  
	  -- preset time and weather
	  if ini.settings.lockserverweather then
	     setTime(slider.time.v)
         setWeather(slider.weather.v)
	  end
	  
      -- Hide dialogs on ESC
      if isKeyJustPressed(VK_ESCAPE) and not sampIsChatInputActive() 
      and not sampIsDialogActive() and not isPauseMenuActive() 
      and not isSampfuncsConsoleActive() then 
         if dialog.main.v then dialog.main.v = false end
         if dialog.fastanswer.v then dialog.fastanswer.v = false end
         if dialog.textures.v then dialog.textures.v = false end
         if dialog.playerstat.v then dialog.playerstat.v = false end
         if dialog.extendedtab.v then dialog.extendedtab.v = false end
         if dialog.objectinfo.v then dialog.objectinfo.v = false end
      end 
      
	  -- In onSendEditObject copy object modelid on RMB
	  if isKeyJustPressed(VK_RBUTTON) and currentEditmode == 2 and not sampIsChatInputActive() 
      and not sampIsDialogActive() and not isPauseMenuActive() 
      and not isSampfuncsConsoleActive() then 
	     setClipboardText(lastObjectModelid)
		 sampAddChatMessage("modelid скопирован в буфер обмена", -1)
	  end
	  
	  -- hide edited object on hold ALT key
      if isKeyDown(VK_MENU) and currentEditmode > 0 and not sampIsChatInputActive() 
      and not sampIsDialogActive() and not isPauseMenuActive() 
      and not isSampfuncsConsoleActive() then
	     hideEditObject = true
	  else
		 hideEditObject = false
	  end
	  
	  -- upscale edited object on hold CTRL key
	  if isKeyDown(VK_CONTROL) and currentEditmode > 0 and not sampIsChatInputActive() 
      and not sampIsDialogActive() and not isPauseMenuActive() 
      and not isSampfuncsConsoleActive() then
	     scaleEditObject = true
	  else
		 scaleEditObject = false
	  end
	  
	  -- if isKeyJustPressed(VK_N) and not sampIsChatInputActive() 
      -- and not sampIsDialogActive() and not isPauseMenuActive() 
      -- and not isSampfuncsConsoleActive() then 
	     -- if lastObject then
		    -- local result, positionX, positionY, positionZ = getObjectCoordinates(lastObject)
	        -- sampSendEditObject(false, lastObject, 1, positionX, positionY, positionZ, 0.0, 0.0, 0,0)
		 -- end	
	  --end
	 
      -- ALT+X (Main menu activation)
      if isKeyDown(VK_MENU) and isKeyJustPressed(VK_X) 
	  and not sampIsChatInputActive() and not sampIsDialogActive()
	  and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
         dialog.main.v = not dialog.main.v 
      end
      
      -- CTRL+O (Objects render activation)
      if isKeyDown(VK_CONTROL) and isKeyJustPressed(VK_O)
	  and not sampIsChatInputActive() and not isPauseMenuActive()
	  and not isSampfuncsConsoleActive() then 
         checkbox.showobjects.v= not checkbox.showobjects.v
      end
      
	  if not isAbsfixInstalled then
	     -- Switching textdraws with arrow buttons, mouse buttons, pgup-pgdown keys
	     if isKeyJustPressed(VK_LEFT) or isKeyJustPressed(VK_XBUTTON1) 
		 or isKeyJustPressed(VK_PRIOR) and sampIsCursorActive() 
		 and not sampIsChatInputActive() and not sampIsDialogActive() 
		 and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
		    sampSendClickTextdraw(36)
		 end
	  
	     if isKeyJustPressed(VK_RIGHT) or isKeyJustPressed(VK_XBUTTON2) 
		 or isKeyJustPressed(VK_NEXT) and sampIsCursorActive()
		 and not sampIsChatInputActive() and not sampIsDialogActive()
		 and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
		    sampSendClickTextdraw(37)
		 end
	  end
	  
      if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive()
	  and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
         isTexturesListOpened = false
      end
      
	  -- Count streamed obkects
	  if countobjects then
	     streamedObjects = 0
	     for _, v in pairs(getAllObjects()) do
		    if isObjectOnScreen(v) then
			   streamedObjects = streamedObjects + 1
			end
		 end
	  end
	  
      -- Objects render
      if checkbox.showobjects.v and not isPauseMenuActive() then
         for _, v in pairs(getAllObjects()) do
            if isObjectOnScreen(v) then
               local _, x, y, z = getObjectCoordinates(v)
			   local px, py, pz = getCharCoordinates(PLAYER_PED)
			   if getDistanceBetweenCoords3d(px, py, pz, x, y, z) >= 2 then
			      local x1, y1 = convert3DCoordsToScreen(x,y,z)
                  renderFontDrawText(objectsrenderfont, "{80FFFFFF}" .. getObjectModel(v), x1, y1, -1)
			   end
            end
         end
      end
      
	  if checkbox.drawlinetomodelid.v and not isPauseMenuActive() then
	     for _, v in pairs(getAllObjects()) do
            if isObjectOnScreen(v) then
			   local model = getObjectModel(v)
               local _, x, y, z = getObjectCoordinates(v)
			   local px, py, pz = getCharCoordinates(PLAYER_PED)
			   local x1, y1 = convert3DCoordsToScreen(x,y,z)
			   local x10, y10 = convert3DCoordsToScreen(px,py,pz)
			   local distance = string.format("%.0f", getDistanceBetweenCoords3d(x, y, z, px, py, pz))
			   if model ~= 2680 and model ~= 1276 -- ignore hidden packages
			   and model == input.rendselectedmodelid.v then
                  renderFontDrawText(objectsrenderfont, "{CCFFFFFF} " .. getObjectModel(v) .." distace: ".. distance, x1, y1, -1)
				  renderDrawLine(x10, y10, x1, y1, 1.0, '0xCCFFFFFF')
			   end
            end
         end
	  end 
	  
      -- Collision
      if disableObjectCollision then
         find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
         result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
         if result then
            setObjectCollision(objectHandle, false)
            table.insert(objectsCollisionDel, objectHandle, objectHandle)            
            --setObjectCollisionDamageEffect(objectHandle, false)
         end
      end
      
	  if checkbox.changefov.v then
	     if slider.fov.v >= 1 and slider.fov.v <= 179 then 
	        cameraSetLerpFov(slider.fov.v, slider.fov.v, 999988888, true)
		 else
		    slider.fov.v = 70
	     end
	  end
	  
	  -- Show TD index
	  if checkbox.showtextdrawsid.v then
         for id = 1, 2048 do
            if sampTextdrawIsExists(id) then
               local x, y = sampTextdrawGetPos(id)
               local xw, yw = convertGameScreenCoordsToWindowScreenCoords(x, y)
               renderFontDrawText(objectsrenderfont, 'ID: ' .. id, xw, yw, -1)
            end
         end
      end
	  
	  if checkbox.fixcampos.v then
		 setFixedCameraPosition(fixcam.x, fixcam.y, fixcam.z, 0.0, 0.0, 0.0)
		 pointCameraAtPoint(fixcam.x, fixcam.y, fixcam.z, 2) 
	  end
	  
	  -- smoothTeleport 
	  if smoothTeleport and isCharOnFoot(playerPed) then
         freezeCharPosition(playerPed, true)
		 local step = 2
		 local movingSpeed = 10
         local result, id = sampGetPlayerIdByCharHandle(playerPed)		 
         local myPosition = {getOffsetFromCharInWorldCoords(playerPed, 0.0, 0.0, 0.2855)}
		 tpc.static.x, tpc.static.y, tpc.static.z = tpc.private.x - myPosition[1], tpc.private.y - myPosition[2], tpc.private.z - myPosition[3];
         tpc.public.x, tpc.public.y, tpc.public.z = tpc.public.x - myPosition[1], tpc.public.y - myPosition[2], tpc.public.z - myPosition[3];
         local vectorPlayer = vector3D(tpc.static.x, tpc.static.y, tpc.static.z)
	 	 vectorPlayer:normalize()
         local data = allocateMemory(68)
         sampStorePlayerOnfootData(id, data)
         setStructFloatElement(data, 38, 0.0, true)
         setStructFloatElement(data, 42, 0.0, true)
         setStructFloatElement(data, 38, 0.02, true)
         setStructFloatElement(data, 42, 0.02, true)
         sampSendOnfootData(data)
         freeMemory(data)
         setCharCoordinates(playerPed, myPosition[1] + vectorPlayer.x *  step, myPosition[2] + vectorPlayer.y *  step, myPosition[3] + vectorPlayer.z *  step)
         wait(movingSpeed)
         if getDistanceBetweenCoords3d(tpc.private.x, tpc.private.y, tpc.private.z, myPosition[1], myPosition[2], myPosition[3]) < 2 then
            local lastPosition = {getCharCoordinates(playerPed)}
            setCharCoordinates(playerPed, lastPosition[1], lastPosition[2], lastPosition[3] + 0.02)
            freezeCharPosition(playerPed, false)
            smoothTeleport = false
			tpcpos.x = lastPosition[1]
			tpcpos.y = lastPosition[2]
			tpcpos.z = lastPosition[3] + 0.02
         end
      end
      -- END main
   end
end

-- function imgui.BeforeDrawFrame()
-- end

function imgui.OnDrawFrame()
   if dialog.main.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 4, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin("Absolute Events Helper", dialog.main)
      
      imgui.Columns(2, "mainmenucolumns", false)
      imgui.SetColumnWidth(-1, 440)
      
      if imgui.Button(u8"Основное") then tabmenu.main = 1 end
      imgui.SameLine()
      if imgui.Button(u8"Чат-Бинд") then tabmenu.main = 2 end
      imgui.SameLine()
      if imgui.Button(u8"Мероприятие") then tabmenu.main = 3 end
      imgui.SameLine()
      if imgui.Button(u8"Информация") then tabmenu.main = 4 end

      imgui.NextColumn()
      
      imgui.SameLine()
      imgui.Text("                           ")
	  imgui.SameLine()
      
      imgui.Text(string.format("FPS: %i", fps))
      if imgui.IsItemClicked() then
         runSampfuncsConsoleCommand("fps")
      end
      
	  imgui.SameLine()
      if imgui.Button(u8"Свернуть") then
         dialog.main.v = not dialog.main.v 
      end
      imgui.SameLine()
      --imgui.TextColoredRGB("{424242}( ? )")
      imgui.TextQuestion("( ? )", u8"О скрипте")
      if imgui.IsItemClicked() then 
         tabmenu.main = 4
         tabmenu.info = 1
      end
      imgui.Columns(1)

      -- Child form (Change main window size here)
      imgui.BeginChild('##main',imgui.ImVec2(640, 430),true)
      
      if tabmenu.main == 1 then

         imgui.Columns(2)
         imgui.SetColumnWidth(-1, 455)

         if tabmenu.settings == 1 then
			
		    local positionX, positionY, positionZ = getCharCoordinates(PLAYER_PED)
			local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		    local score = sampGetPlayerScore(id)
		 
            imgui.TextColoredRGB(string.format("Ваша позиция на карте x: %.1f, y: %.1f, z: %.1f",
            positionX, positionY, positionZ))
	        if imgui.IsItemClicked() then
               setClipboardText(string.format(u8"%.1f, %.1f, %.1f", positionX, positionY, positionZ))
               sampAddChatMessage("Позиция скопирован в буфер обмена", -1)
            end
			
		    if tpcpos.x then
			   if tpcpos.x ~= 0 then
                  imgui.TextColoredRGB(string.format("Сохраненая позиция x: %.1f, y: %.1f, z: %.1f",
                  tpcpos.x, tpcpos.y, tpcpos.z))
	              if imgui.IsItemClicked() then
                    setClipboardText(string.format(u8"%.1f, %.1f, %.1f", tpcpos.x, tpcpos.y, tpcpos.z))
                    sampAddChatMessage("Позиция скопирован в буфер обмена", -1)
                  end
			   end
			end
			
		    local bTargetResult, bX, bY, bZ = getTargetBlipCoordinates()
		    if bTargetResult then
		       imgui.Text(string.format(u8"Позиция метки на карте x: %.1f, y: %.1f, z: %.1f",
               bX, bY, bZ))
			   if imgui.IsItemClicked() then
			      setClipboardText(string.format(u8"%.1f, %.1f, %.1f", bX, bY, bZ))
				  sampAddChatMessage("Позиция скопирован в буфер обмена", -1)
			   end
		    end 
		    
			if tpcpos.x then
			   if tpcpos.x ~= 0 then
			      imgui.TextColoredRGB(string.format("Расстояние до сохраненной позиции %.1f m.",
                  getDistanceBetweenCoords3d(positionX, positionY, positionZ, tpcpos.x, tpcpos.y, tpcpos.z)))
			   end	  
			end
			
			local bTargetResult, bX, bY, bZ = getTargetBlipCoordinates()
		    if bTargetResult then
		       imgui.Text(string.format(u8"Расстояние до метки на карте %.1f m.",
               getDistanceBetweenCoords3d(positionX, positionY, positionZ, bX, bY, bZ)))
		    end 
			
			zone = getZoneName(positionX, positionY, positionZ)
			if zone then 
			   imgui.Text(string.format(u8"Район: %s", zone))
			   if lastWorldNumber > 0 then
			      imgui.SameLine()
			      imgui.Text(string.format(u8"Последний мир: №%s", lastWorldNumber))
			      if imgui.IsItemClicked() then
			         sampAddChatMessage("Выбран мир №"..lastWorldNumber, -1)
			         sampSendChat("/мир "..lastWorldNumber)
			      end
			   end
			else
			   if lastWorldNumber > 0 then 
			      imgui.Text(string.format(u8"Последний мир: №%s", lastWorldNumber))
			      if imgui.IsItemClicked() then
			         sampAddChatMessage("Выбран мир №"..lastWorldNumber, -1)
			         sampSendChat("/мир "..lastWorldNumber)
			      end
			   end
			end
			
			imgui.Spacing()
			
            if imgui.Button(u8"Получить координаты", imgui.ImVec2(200, 25)) then
               if not sampIsChatInputActive() and not sampIsDialogActive() 
			   and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
               -- if isAbsolutePlay then sampSendChat("/коорд") end
			      tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(PLAYER_PED)
                  setClipboardText(string.format("%.1f %.1f %.1f", tpcpos.x, tpcpos.y, tpcpos.z))
                  sampAddChatMessage("Координаты скопированы в буфер обмена", -1)
                  sampAddChatMessage(string.format("Интерьер: %i Координаты: %.1f %.1f %.1f",
			      getActiveInterior(), tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Сохранить позицию", imgui.ImVec2(200, 25)) then         
			   tpcpos.x = positionX
			   tpcpos.y = positionY
			   tpcpos.z = positionZ
			   textbuffer.tpcx.v = string.format("%.1f", tpcpos.x)
			   textbuffer.tpcy.v = string.format("%.1f", tpcpos.y)
			   textbuffer.tpcz.v = string.format("%.1f", tpcpos.z)
			   tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(PLAYER_PED)
			   setClipboardText(string.format(u8"%.1f %.1f %.1f", tpcpos.x, tpcpos.y, tpcpos.z))
			   sampAddChatMessage(string.format("Координаты сохранены. %.1f %.1f %.1f", tpcpos.x, tpcpos.y, tpcpos.z), -1)
            end
            
			if imgui.Button(u8"Прыгнуть вперед", imgui.ImVec2(200, 25)) then
               prepareJump = true
			   if sampIsLocalPlayerSpawned() then
				  JumpForward()
			   end
            end
			imgui.SameLine()
			if imgui.Button(u8"Прыгнуть вверх", imgui.ImVec2(200, 25)) then
		       if sampIsLocalPlayerSpawned() then
		          local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                  setCharCoordinates(PLAYER_PED, posX, posY, posZ+10.0)
		       end
            end
			
	        if imgui.Button(u8"Провалиться под текстуры", imgui.ImVec2(200, 25)) then
		       if sampIsLocalPlayerSpawned() then
		          local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                  setCharCoordinates(PLAYER_PED, posX, posY, posZ-3.0)
		       end
            end
	        imgui.SameLine()
	        if imgui.Button(u8"Вернуться на поверхность", imgui.ImVec2(200, 25)) then
               local result, x, y, z = getNearestRoadCoordinates()
		       local anticheatMaxAllowedDist = 10.0
               if result then
                  local dist = getDistanceBetweenCoords3d(x, y, z, getCharCoordinates(PLAYER_PED))
                  if dist < anticheatMaxAllowedDist then 
			         setCharCoordinates(PLAYER_PED, x, y, z + 3.0)
			         --sampAddChatMessage(("(%i %i %i)"):format(x,y,z), -1)
                     sampAddChatMessage("Вы телепортированны на ближайшую поверхность", -1)
			      else
			         sampAddChatMessage(("Ближайшая поверхность слишком далеко (%d m.)"):format(dist), 0x0FF0000)
			         local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                     setCharCoordinates(PLAYER_PED, posX, posY, posZ+3.0)
			      end
               else
                  sampAddChatMessage("Не нашлось ни одной поверхности рядом", 0x0FF0000)
			      local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                  setCharCoordinates(PLAYER_PED, posX, posY, posZ+3.0)
               end
            end
			
			if imgui.Checkbox(u8("Включить телепорт на координаты"), checkbox.teleportcoords) then
			   tpcpos.x = positionX
               tpcpos.y = positionY
               tpcpos.z = positionZ
	           textbuffer.tpcx.v = string.format("%.1f", tpcpos.x)
			   textbuffer.tpcy.v = string.format("%.1f", tpcpos.y)
			   textbuffer.tpcz.v = string.format("%.1f", tpcpos.z)
		    end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Активирует телепорт по заданным координатам")
		 
		    if checkbox.teleportcoords.v then
			   
			   imgui.Text("x:")
			   imgui.SameLine()
		       imgui.PushItemWidth(70)
		       if imgui.InputText("##TpcxBuffer", textbuffer.tpcx) then
			      tpcpos.x = tonumber(textbuffer.tpcx.v)
			   end
			   imgui.PopItemWidth()
			   imgui.SameLine()
			   imgui.Text("y:")
			   imgui.SameLine()
			   imgui.PushItemWidth(70)
			   if imgui.InputText("##TpcyBuffer", textbuffer.tpcy) then
			      tpcpos.y = tonumber(textbuffer.tpcy.v)
			   end
			   imgui.PopItemWidth()
			   imgui.SameLine()
			   imgui.Text("z:")
			   imgui.SameLine()
			   imgui.PushItemWidth(70)
			   if imgui.InputText("##TpczBuffer", textbuffer.tpcz) then
			      tpcpos.z = tonumber(textbuffer.tpcz.v)
			   end
			   imgui.PopItemWidth()
			   
			   imgui.SameLine()
			   imgui.TextQuestion("[=]", u8"Вставить послед. сохраненную позицию")
			   if imgui.IsItemClicked() then
			      if tpcpos.x then
			         textbuffer.tpcx.v = string.format("%.1f", tpcpos.x)
			         textbuffer.tpcy.v = string.format("%.1f", tpcpos.y)
			         textbuffer.tpcz.v = string.format("%.1f", tpcpos.z)
			      end
			   end
			   imgui.SameLine()
			   imgui.TextQuestion("[o]", u8"Вставить координаты с метки на карте")
			   if imgui.IsItemClicked() then
			   local bTargetResult, bX, bY, bZ = getTargetBlipCoordinates()
		          if bTargetResult then
			         textbuffer.tpcx.v = string.format("%.1f", bX)
			         textbuffer.tpcy.v = string.format("%.1f", bY)
			         textbuffer.tpcz.v = string.format("%.1f", bZ)
			      end
			   end
			   
			   if imgui.Button(u8"Телепорт по координатам", imgui.ImVec2(200, 25)) then
			   	  freezeCharPosition(playerPed, false)
				  smoothTeleport = false
	              if isAbsolutePlay then
                     if checkbox.tpcprotect.v then
					    if isCharOnFoot(PLAYER_PED) then
						   tpc.private.x, tpc.private.y, tpc.private.z = tpcpos.x, tpcpos.y, tpcpos.z;
                           tpc.public.x, tpc.public.y, tpc.public.z = tpcpos.x, tpcpos.y, tpcpos.z;
						   smoothTeleport = true
						   --setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z)
						end
					 else
                        if tpcpos.x then
                           prepareTeleport = true
                           sampSendChat(string.format("/ngr %f %f %f", tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
                           sampAddChatMessage(string.format("Телепорт на координаты: %.1f %.1f %.1f",
                           tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
                        else
                           prepareTeleport = false
                           sampAddChatMessage("Координаты не были сохранены", 0x0FFFFFF)
						end
                     end
		          else
				     if checkbox.tpcprotect.v then
					    if isCharOnFoot(PLAYER_PED) and tpcpos.x then
						   setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z)
						end
						sampAddChatMessage(string.format("Телепорт на координаты: %.1f %.1f %.1f",
                        tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
					 else
					    if isCharOnFoot(PLAYER_PED) and tpcpos.x then
					       --local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
						   smoothTeleport = true
						   tpc.private.x, tpc.private.y, tpc.private.z = tpcpos.x, tpcpos.y, tpcpos.z;
                           tpc.public.x, tpc.public.y, tpc.public.z = tpcpos.x, tpcpos.y, tpcpos.z;
					       --setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z)
						   sampAddChatMessage(string.format("Телепорт на координаты: %.1f %.1f %.1f",
                           tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
						end   
					 end
		          end
               end
			   if not isAbsolutePlay then
			      imgui.SameLine()
			      imgui.Checkbox(u8("Снять защиту"), checkbox.tpcprotect)
			      imgui.SameLine()
                  imgui.TextQuestion("( ? )", u8"Снимет все ограничения (Триггерит античит)")
			   end
			   
		    end
			
			imgui.Spacing()
			imgui.Text(isPlayerSpectating and u8('В наблюдении: Да') or u8('В наблюдении: Нет'))
            --imgui.SameLine()
			if imgui.Button(u8'Выйти из спектатора', imgui.ImVec2(200, 25)) then
		       if isAbsolutePlay then
			      if isPlayerSpectating then 
			         setVirtualKeyDown(VK_RETURN, true)
			      end
			   end
               sampSendChat("/spec")
            end
            
            imgui.SameLine()
            if imgui.Button(u8'Войти в спектатор', imgui.ImVec2(200, 25)) then
		       if isAbsolutePlay then
			      if not isPlayerSpectating then 
				     if chosenplayer and sampIsPlayerConnected(chosenplayer) then
			            sampSendChat("/набл "..chosenplayer)
				     else
					    if getClosestPlayerId() ~= -1 then
			               sampSendChat("/набл "..getClosestPlayerId())
			            else
					       sampSendChat("/полет")
						end
					 end
			      end
			   end
		    end
	 	 
		    if imgui.Button(u8'Заспавниться', imgui.ImVec2(200, 25)) then
			   if isAbsolutePlay then
			      if score == 0 then
				     sampSpawnPlayer()
			         restoreCameraJumpcut()
				  else 
				     sampAddChatMessage("В чит-мир захотел? Используй эмуляцию", -1)
			      end
			   else
			      sampSpawnPlayer()
			      restoreCameraJumpcut()
			   end
		    end
			imgui.SameLine()
		    if imgui.Button(u8'Заспавниться (Эмуляция)', imgui.ImVec2(200, 25)) then
			   if isAbsolutePlay then
			      local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
				  setCharCoordinates(PLAYER_PED, posX, posY, posZ+0.2)
			      freezeCharPosition(PLAYER_PED, false)
			      setPlayerControl(PLAYER_HANDLE, true)
			      restoreCameraJumpcut()
			      clearCharTasksImmediately(PLAYER_PED)
			   else
			      sampSpawnPlayer()
				  restoreCameraJumpcut()
			   end
		    end
			
			if imgui.Button(u8'Заморозить на позиции', imgui.ImVec2(200, 25)) then
			   freezeCharPosition(PLAYER_PED, true)
			end
			imgui.SameLine()
			if imgui.Button(u8'Разморозить', imgui.ImVec2(200, 25)) then
			   freezeCharPosition(PLAYER_PED, false)
			   setPlayerControl(PLAYER_HANDLE, true)
			   clearCharTasksImmediately(PLAYER_PED)
			end
		 imgui.Spacing()
		
	  elseif tabmenu.settings == 2 then
		 
         if lastObject and doesObjectExist(lastObject) then
            if dialog.objectinfo.v then 
               if imgui.Button("(>>)") then
                  dialog.objectinfo.v = not dialog.objectinfo.v
               end
            else
               if imgui.Button("(<<)") then
                  dialog.objectinfo.v = not dialog.objectinfo.v
               end
            end             
            imgui.SameLine()
         end   
         if lastObjectModelid then
            imgui.Text(string.format(u8"Последний modelid объекта: %i", lastObjectModelid))
            if imgui.IsItemClicked() then
               setClipboardText(lastObjectModelid)
			   sampAddChatMessage("modelid скопирован в буфер обмена", -1)
            end
		 else 
		    imgui.Text(u8"Последний modelid объекта: не выбран")
         end
		 
		 imgui.Text(string.format(u8"Удаленные стандартные объекты (removeBuilding): %i", removedBuildings))
		 if countobjects then
            imgui.Text(string.format(u8"Объектов в области в стрима: %i", streamedObjects))
         end
         
         imgui.Spacing()
		 
         if imgui.Checkbox(u8("Показывать modelid объектов"), checkbox.showobjects) then 
            if checkbox.drawlinetomodelid.v then checkbox.drawlinetomodelid.v = false end
		 end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Применимо только для объектов в области стрима (CTRL + O)")
        
		if imgui.Checkbox(u8("Найти объекты рядом по ID модели"), checkbox.drawlinetomodelid) then
		   if checkbox.showobjects.v then checkbox.showobjects.v = false end
		end
		imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Рисует линию к объекту с указанием расстояния")
              
	    if checkbox.drawlinetomodelid.v then 
		   if lastObjectModelid and input.rendselectedmodelid.v == 0 then 
		      input.rendselectedmodelid.v = lastObjectModelid
		   end
		   
	       imgui.Text(u8"modelid объекта: ")
           imgui.SameLine()
           imgui.PushItemWidth(55)
           imgui.InputInt('##INPUT_REND_SELECTED', input.rendselectedmodelid, 0)
		   imgui.PopItemWidth()
		   imgui.SameLine()
           imgui.SameLine()
           imgui.TextQuestion("( ? )", u8"Введите modelid от 615-18300 [GTASA], 18632-19521 [SAMP]")
	    end
	  
     	if imgui.Checkbox(u8("Найти ближайший объект по ID модели"), checkbox.showclosestobjects) then
	    end
	    imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Найдет ближайший объект по ID модели")
		
		if checkbox.showclosestobjects.v then
           imgui.Text(u8"modelid объекта: ")
		   imgui.SameLine()
		   imgui.PushItemWidth(55)
	       imgui.InputInt('##INPUT_CLOOBJECTID', input.closestobjectmodel, 0)
           imgui.PopItemWidth()
		   
		   if lastObjectModelid and input.closestobjectmodel.v == 0 then 
		      input.closestobjectmodel.v = lastObjectModelid
		   end
		   
		   if string.len(input.closestobjectmodel.v) > 0 then
              local result, distance, x, y, z = GetNearestObject(input.closestobjectmodel.v)
              if result then 
			     imgui.Text(string.format(u8'Объект находится на расстоянии %.2f метров от вас', distance), -1)
			  end	 
		   end
		end
		
	 	if imgui.Checkbox(u8("Скрыть объекты по ID модели"), checkbox.hideobject) then 
	       if not checkbox.hideobject.v then
		      if hiddenObjects[1] ~= nil then
                 for i = 1, #hiddenObjects do
                    table.remove(hiddenObjects, i)
				 end
              end
		   end
	    end
	    imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Скроет объект по ID модели (modelid). Действует при обновлении зоны стрима")
	   
	    if checkbox.hideobject.v then 
		   if lastObjectModelid and input.hideobjectid.v == 615 then 
		      input.hideobjectid.v = lastObjectModelid
		   end
		   
	       imgui.Text(u8"modelid объекта: ")
           imgui.SameLine()
           imgui.PushItemWidth(55)
           imgui.InputInt('##INPUT_HIDEOBJECT_ID', input.hideobjectid, 0)
		   imgui.PopItemWidth()
		   imgui.SameLine()
		   if imgui.Button(u8"Скрыть объект", imgui.ImVec2(110, 25)) then 
		      if string.len(input.hideobjectid.v) > 0 then 
                 if(tonumber(input.hideobjectid.v) < 615 or tonumber(input.hideobjectid.v) > 19521) then
			 	    sampAddChatMessage("Объект не был добавлен, так как вы ввели некорректный id!", -1)
				 else
			        table.insert(hiddenObjects, tonumber(input.hideobjectid.v))
				    sampAddChatMessage(string.format("Вы скрыли все объекты с modelid: %i",
                    tonumber(input.hideobjectid.v)), -1)
                 end
				 sampAddChatMessage("Изменения будут видны после обновления зоны стрима!", -1)
    		  else
			     sampAddChatMessage("Объект не был добавлен, так как вы не ввели id!", -1)
			  end
		   end
           imgui.SameLine()
           imgui.TextQuestion("( ? )", u8"Введите modelid от 615-18300 [GTASA], 18632-19521 [SAMP]")
	    end
	    
	    if imgui.Checkbox(u8("Дальность прорисовки объекта по ID модели"), checkbox.changemdo) then
	    end
	    imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Изменяет далльность прорисовки объекта (визуально)")
		
		if checkbox.changemdo.v then
           imgui.Text(u8"modelid объекта: ")
		   imgui.SameLine()
		   imgui.PushItemWidth(55)
	       imgui.InputInt('##INPUT_MDOMODELID', input.mdomodel, 0)
		   imgui.SameLine()
		   imgui.Text(u8"дистанция: ")
		   imgui.SameLine()
		   imgui.PushItemWidth(35)
		   imgui.InputInt('##INPUT_MDODIST', input.mdodist, 0)
		   
		   if lastObjectModelid and input.mdomodel.v == 0 then 
		      input.mdomodel.v = lastObjectModelid
		   end
		   
		   imgui.SameLine()
		   if imgui.Button(u8"Применить") then
		      if string.len(input.mdomodel.v) > 0 and string.len(input.mdodist.v) > 0 then
                 memory.setfloat(getMDO(input.mdomodel.v), input.mdodist.v, true)
		      end
		   end
		end
	    
		if imgui.Checkbox(u8("Показывать координаты объекта при перемещении"), checkbox.showobjectrot) then
		   save()
		end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Показывает координаты объекта при перемещении в редакторе карт")
		
        if imgui.Checkbox(u8("Отключить коллизию у объектов"), checkbox.objectcollision) then 
           if checkbox.objectcollision.v then
           disableObjectCollision = true
        else
           disableObjectCollision = false
           find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
           result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
           if result then
              for k, v in pairs(objectsCollisionDel) do
                 if doesObjectExist(v) then 
				    setObjectCollision(v, true)
					end
                 end
              end
           end		
        end
        
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Применимо только для объектов в области стрима")
		
		if imgui.Button(u8"ТП к последнему объекту", imgui.ImVec2(250, 25)) then
		   if lastObjectModelid and lastObjectCoords.x ~= 0 and doesObjectExist(lastObject) then
		      if isAbsolutePlay then
		         sampSendChat(string.format("/ngr %f %f %f",
			     lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z), 0x0FFFFFF)
			  else
			     setCharCoordinates(PLAYER_PED, lastObjectCoords.x, lastObjectCoords.x, lastObjectCoords.z+0.2)
			  end
			  sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..lastObjectModelid, -1)
		   else
		      sampAddChatMessage("Не найден последний объект", -1)
		   end
		end
		
		if imgui.Button(u8(lastObjectBlip and "Убрать метку с объекта" or "Метку на последний объект"), imgui.ImVec2(250, 25)) then
		   if lastObject and doesObjectExist(lastObject) then
		       if lastObjectBlip then
			      removeBlip(lastObjectBlip)
				  lastObjectBlip = nil
			   else
		          lastObjectBlip = addBlipForObject(lastObject)
			   end
		   else
		      sampAddChatMessage("Не найден последний объект", -1)
		   end
		end
		
	    if imgui.Button(u8(lastObjectHidden and "Скрыть" or "Показать")..u8" последний объект", imgui.ImVec2(250, 25)) then
		   if lastObject and doesObjectExist(lastObject) then
		      if lastObjectHidden then
		         setObjectVisible(lastObject, false)
				 lastObjectHidden = false
			  else
			     setObjectVisible(lastObject, true)
				 lastObjectHidden = true
			  end
		   else
		      sampAddChatMessage("Не найден последний объект", -1)
		   end
		end
         
		-- if imgui.Button(u8"Восстановить удаленный объект", imgui.ImVec2(250, 25)) then
		   -- if isAbsolutePlay then
		      -- if lastRemovedObjectModelid then
			     -- undoMode = not undoMode 
			  -- end
		   -- end
		-- end
		imgui.Spacing()
		
	  elseif tabmenu.settings == 3 then

		 local angle = math.ceil(getCharHeading(PLAYER_PED))
         imgui.Text(string.format(u8"Направление: %s  %i°", direction(), angle))
	     local camX, camY, camZ = getActiveCameraCoordinates()
		 imgui.Text(string.format(u8"Камера x: %.1f, y: %.1f, z: %.1f",
         camX, camY, camZ))
		 if imgui.IsItemClicked() then
            setClipboardText(string.format(u8"%.1f, %.1f, %.1f", camX, camY, camZ))
            sampAddChatMessage("Позиция скопирован в буфер обмена", -1)
         end
		 
		 if imgui.Checkbox(u8("Зафиксировать камеру на координатах"), checkbox.fixcampos) then
		    if checkbox.fixcampos.v then
               fixcam.x = camX 			
               fixcam.y = camY 			
               fixcam.z = camZ
			   textbuffer.fixcamx.v = string.format("%.1f", fixcam.x)
			   textbuffer.fixcamy.v = string.format("%.1f", fixcam.y)
			   textbuffer.fixcamz.v = string.format("%.1f", fixcam.z)
			else restoreCamera() end
		 end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Зафиксирует положение камеры на указанные значеня")
		 
		 if checkbox.fixcampos.v then		
			imgui.Text("x:")
			imgui.SameLine()
		    imgui.PushItemWidth(70)
		    if imgui.InputText("##FixcamxBuffer", textbuffer.fixcamx) then
			   fixcam.x = tonumber(textbuffer.fixcamx.v)
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Text("y:")
			imgui.SameLine()
			imgui.PushItemWidth(70)
			if imgui.InputText("##FixcamyBuffer", textbuffer.fixcamy) then
			   fixcam.y = tonumber(textbuffer.fixcamy.v)
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Text("z:")
			imgui.SameLine()
			imgui.PushItemWidth(70)
			if imgui.InputText("##FixcamzBuffer", textbuffer.fixcamz) then
			   fixcam.z = tonumber(textbuffer.fixcamz.v)
			end
			imgui.PopItemWidth()
		 end
		 
		 if imgui.Checkbox(u8("Разблокировать изменение дистанции камеры"), checkbox.usecustomcamdist) then 
		    ini.settings.usecustomcamdist = not ini.settings.usecustomcamdist
            if ini.settings.usecustomcamdist then
		       setCameraDistanceActivated(1)
			   setCameraDistance(ini.settings.camdist)
		    else
	           setCameraDistanceActivated(0)
			   setCameraDistance(0)
		    end
		    save()
	     end
	     imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Разблокирует изменение положения камеры на произвольные значеня")
		 
	  	 if ini.settings.usecustomcamdist then
	        imgui.TextColoredRGB("Дистанция камеры {51484f} (по-умолчанию 1)")
			if imgui.IsItemClicked() then
		       slider.camdist.v = 1
			   ini.settings.camdist = slider.camdist.v
			   save()
		    end
	        if imgui.SliderInt(u8"##camdist", slider.camdist, -100, 250) then
               ini.settings.camdist = slider.camdist.v
               setCameraDistanceActivated(1)		  
		       setCameraDistance(ini.settings.camdist)
               save()
               memory.setfloat(13210352, ini.settings.camdist, true)
            end
	     end
		 
		 if imgui.Checkbox(u8("Разблокировать изменение FOV"), checkbox.changefov) then 
		    if not checkbox.changefov.v then slider.fov.v = 70 end
			cameraSetLerpFov(slider.fov.v, slider.fov.v, 999988888, true)
		 end 
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Рвзблокирует изменения значение поля зрения(FOV).")
		 
		 if checkbox.changefov.v then
		    imgui.TextColoredRGB("FOV {51484f} (по-умолчанию 70)")
			if imgui.IsItemClicked() then
		       slider.changefov.v = 1
		       cameraSetLerpFov(slider.fov.v, slider.fov.v, 999988888, true)
		    end
		    if imgui.SliderInt(u8"##fovslider", slider.fov, 1, 179) then
               cameraSetLerpFov(slider.fov.v, slider.fov.v, 999988888, true)
            end
		 end
		 
		 if imgui.Button(u8"Вернуть камеру", imgui.ImVec2(250, 25)) then
		    if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
		    restoreCamera()
		 end
		 
		 if imgui.Button(u8"Камеру позади игрока", imgui.ImVec2(250, 25)) then
            if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
		    setCameraBehindPlayer()
		 end
		 
		 if imgui.Button(u8(ini.settings.showhud and 'Скрыть' or 'Показать')..u8" HUD", 
         imgui.ImVec2(250, 25)) then
            ini.settings.showhud = not ini.settings.showhud
            save()
            if ini.settings.showhud then
               displayHud(true)
               memory.setint8(0xBA676C, 0)
            else
               displayHud(false)
               memory.setint8(0xBA676C, 2)
            end
         end
		 -- if imgui.Button(u8"Закрепить камеру перед игроком", imgui.ImVec2(250, 25)) then
		    -- setCameraInFrontOfChar(PLAYER_PED)
		 -- end
		 imgui.Spacing()
	  elseif tabmenu.settings == 4 then
	  
	     if countobjects then
            imgui.Text(string.format(u8"Объектов в области в стрима: %i", streamedObjects))
         end
         imgui.Text(string.format(u8"Игроков в области стрима: %i",
         sampGetPlayerCount(true) - 1))
      
         imgui.Text(string.format(u8"Транспорта в области стрима: %i",
         getVehicleInStream()))
	  
	     imgui.Spacing()
	     imgui.TextColoredRGB("Дистанция прорисовки {51484f} (по-умолчанию 450)")
		 if imgui.IsItemClicked() then
		    slider.drawdist.v = 450
		    memory.setfloat(12044272, slider.drawdist.v, true)
		 end
         if imgui.SliderInt(u8"##Drawdist", slider.drawdist, 50, 3000) then
            ini.settings.drawdist = slider.drawdist.v
            save()
            memory.setfloat(12044272, ini.settings.drawdist, true)
         end
        
         imgui.TextColoredRGB("Дистанция тумана {51484f} (по-умолчанию 200)")
		 if imgui.IsItemClicked() then
		    slider.fog.v = 200
			memory.setfloat(13210352, slider.fog.v, true)
		 end
         if imgui.SliderInt(u8"##fog", slider.fog, -390, 390) then
            ini.settings.fog = slider.fog.v
            save()
            memory.setfloat(13210352, ini.settings.fog, true)
         end
		 
		 if imgui.Checkbox(u8(nameTagWh and 'Вернуть' or 'Увеличить')..u8" прорисовку NameTags", checkbox.nametagwh) then 
            if nameTagWh then
			   nameTagWh = false
               nameTagOn()
            else
			   nameTagWh = true
               nameTagOn()
            end
	     end
	     imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Увеличит дальность прорисовки nameTag над игроком")
         
		 imgui.Checkbox(u8("Показать скрытые клисты"), checkbox.radarblips)
	     imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Показзывает на радаре скрытых игроков")
		 
		 if imgui.Checkbox(u8'Vehicle LODs', checkbox.vehloads) then
		    if checkbox.vehloads.v then
			   memory.write(5425646, 1, 1, false)
			else
			   memory.write(5425646, 0, 1, false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отображение лодов транспорта")
		 
	     if imgui.Button(u8(hide3dtexts and 'Показать' or 'Скрыть')..u8" 3D тексты", 
         imgui.ImVec2(250, 25)) then
            hide3dtexts = not hide3dtexts
		    sampAddChatMessage("Изменения видны после респавна либо обновления зоны стрима", -1)
         end
	     imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Скрывает 3d тексты из стрима (для скринов)")
		 
	     if imgui.Button(u8(nameTag and 'Скрыть' or 'Показать')..u8" NameTags", 
         imgui.ImVec2(250, 25)) then
            if nameTag then
               nameTagOff()
            else
               nameTagOn()
            end
         end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Скрывает никнейм и информацию над игроком (nameTag)")
		 
         if imgui.Button(u8"Рестрим", imgui.ImVec2(250, 25)) then
            Restream()
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Обновить зону стрима путем выхода из зоны стрима, и возврата через 5 сек")
		 imgui.Spacing()
		 
	  elseif tabmenu.settings == 5 then
	  
	     if imgui.Checkbox(u8("Блокировать изменение погоды и времени"), checkbox.lockserverweather) then          
            ini.settings.lockserverweather = not ini.settings.lockserverweather
            if ini.settings.lockserverweather then
               setTime(slider.time.v)
               setWeather(slider.weather.v)
               patch_samp_time_set(true)
            else
               patch_samp_time_set(false)
            end
            save()
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Блокирует изменение погоды и времени сервером")
	   
	     imgui.PushItemWidth(320)
         imgui.Text(u8'Время:')
         if imgui.SliderInt('##slider.time', slider.time, 0, 24) then 
            setTime(slider.time.v) 
         end
         imgui.Spacing()
         imgui.Text(u8'Погода')
         if imgui.SliderInt('##slider.weather', slider.weather, 0, 45) then 
            setWeather(slider.weather.v) 
         end
         imgui.PopItemWidth()
		 
		 imgui.Text(u8"Пресеты погоды: ")
		 if imgui.Button(u8"Солнечная", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 0
            setWeather(slider.weather.v) 		   
         end
		 imgui.SameLine()
		 if imgui.Button(u8"Облачная", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 12
            setWeather(slider.weather.v) 		   
         end
		 if imgui.Button(u8"Дождливая", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 16
            setWeather(slider.weather.v)
         end
		 imgui.SameLine()
		 if imgui.Button(u8"Туманная", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 9
            setWeather(slider.weather.v)
         end
		 if imgui.Button(u8"Песочная буря", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 19
            setWeather(slider.weather.v)
         end
		 imgui.SameLine()
		 if imgui.Button(u8"Зеленая", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 20
            setWeather(slider.weather.v)
         end
		 if imgui.Button(u8"Монохромная", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 44
            setWeather(slider.weather.v)
         end
		 imgui.SameLine()
		 if imgui.Button(u8"Темная", imgui.ImVec2(150, 25)) then
		    slider.weather.v = 45
            setWeather(slider.weather.v)
         end
		 
		 imgui.Spacing()
	     imgui.TextColoredRGB("Галерея погоды")
		 imgui.SameLine()
		 imgui.Link("https://dev.prineside.com/ru/gtasa_weather_id/", "dev.prineside.com")
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Данная галерея содержит снимки из игры GTA San Andreas, сделанные при разной погоде и времени суток. ")
		 imgui.Spacing()
	
      elseif tabmenu.settings == 6 then
         if imgui.Checkbox(u8'Тени мира', checkbox.shadows) then
		    if checkbox.shadows.v then
			   memory.write(5497177, 233, 1, false)
               memory.write(5489067, 492560616, 4, false)
               memory.write(5489071, 0, 1, false)
               memory.write(6186889, 33807, 2, false)
               memory.write(7388587, 111379727, 4, false)
               memory.write(7388591, 0, 2, false)
               memory.write(7391066, 32081167, 4, false)
               memory.write(7391070, -1869611008, 4, false)
			else
			   memory.write(5497177, 195, 1, false)
               memory.fill(5489067, 144, 5, false)
               memory.write(6186889, 59792, 2, false)
               memory.fill(7388587, 144, 6, false)
               memory.fill(7391066, 144, 9, false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Переключает тени мира")
	     
		 -- Gorskin https://www.blast.hk/threads/13380/post-1110222
		 if imgui.Checkbox(u8'Отключить все эффекты игры', checkbox.noeffects) then
		    if checkbox.noeffects.v then
			   memory.fill(0x53EAD3, 0x90, 5, true) 
			else
			   memory.hex2bin("E898F6FFFF", 0x53EAD3, 5) 
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отключает эффекты дыма, пыли, тени")
		 
		 if imgui.Checkbox(u8'Отрисовка травы и растений', checkbox.grassfix) then
		    if checkbox.grassfix.v then
			   memory.hex2bin("E8420E0A00", 0x53C159, 5) 
			   memory.protect(0x53C159, 5, memory.unprotect(0x53C159, 5)) 
			else
			   memory.fill(0x53C159, 0x90, 5, true)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Возвращает траву из одиночной игры")
		 
		 -- Gorskin https://www.blast.hk/threads/13380/post-1107000
		 if imgui.Checkbox(u8'Оттключить дым из труб и огонь с факелов', checkbox.nofactorysmoke) then
		    if checkbox.nofactorysmoke.v then
			   memory.fill(0x4A125D, 0x90, 8, true)
			   writeMemory(0x539F00, 4, 0x0024C2, true)
			else
			   memory.hex2bin('8B4E08E88B900000', 0x4A125D, 8)
			   writeMemory(0x539F00, 4, 0x6C8B5551, true)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отключает дым из труб на заводах и прочие эффекты по типу факелов, горящих черепов. (Требуется рестрим)")
		 
		 if imgui.Checkbox(u8'Пост-обработка (PostFX)', checkbox.postfx) then
		    if checkbox.postfx.v then
               memory.write(7358318, 1448280247, 4, false)
               memory.write(7358314, -988281383, 4, false)
			else
			   memory.write(7358318, 2866, 4, false)
               memory.write(7358314, -380152237, 4, false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отключает постобработку (PostFX)")
		 
		 if imgui.Checkbox(u8'Анизотропная фильтрация текстур', checkbox.aniso) then
		    if checkbox.aniso.v then
			    if readMemory(0x730F9C, 1, false) ~= 0 then
                memory.write(0x730F9C, 0, 1, false)
                loadScene(1337, 1337, 1337)
                callFunction(0x40D7C0, 1, 1, -1)
                end
			else
			    if readMemory(0x730F9C, 1, false) ~= 1 then
                memory.write(0x730F9C, 1, 1, false)
                loadScene(1337, 1337, 1337)
                callFunction(0x40D7C0, 1, 1, -1)
                end
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Исправление ряби на текстурах")
		 
		 if imgui.Checkbox(u8'Blur эффект', checkbox.blur) then
		    if checkbox.blur.v then
		       memory.fill(0x704E8A, 0xE8, 1, true)
			   memory.fill(0x704E8B, 0x11, 1, true)
			   memory.fill(0x704E8C, 0xE2, 1, true)
			   memory.fill(0x704E8D, 0xFF, 1, true)
			   memory.fill(0x704E8E, 0xFF, 1, true)
		    else
			   memory.fill(0x704E8A, 0x90, 1, true)
			   memory.fill(0x704E8B, 0x90, 1, true)
			   memory.fill(0x704E8C, 0x90, 1, true)
			   memory.fill(0x704E8D, 0x90, 1, true)
			   memory.fill(0x704E8E, 0x90, 1, true)
		    end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Переключает размытость при передвижении в транспорте с увеличением скорости")
		 
		 if imgui.Checkbox(u8'Sun эффект', checkbox.sunfix) then
		    if checkbox.sunfix.v then
			   memory.hex2bin("E865041C00", 0x53C136, 5) 
			   memory.protect(0x53C136, 5, memory.unprotect(0x53C136, 5))
			else
			   memory.fill(0x53C136, 0x90, 5, true)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Возвращает солнце из одиночной игры")
		 
		 if imgui.Checkbox(u8'Nightvision', checkbox.nightvision) then
		    if checkbox.nightvision.v then
			   setNightVision(true)
			else
			   setNightVision(false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Включает эффект ночного зрения")
		 
		 if imgui.Checkbox(u8'InfraredVision', checkbox.infraredvision) then
		    if checkbox.infraredvision.v then
			   setInfraredVision(true)
			else
			   setInfraredVision(false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Включает эффект инфракрасного зрения")
		 
		 -- https://github.com/JuniorDjjr/GraphicsTweaker/tree/master/GraphicsTweaker
		 if imgui.Checkbox(u8'LightMap', checkbox.lightmap) then
		    if checkbox.lightmap.v then
			   -- local value = memory.read(0x73558B, 2, true)
			   -- print(value)
			   memory.fill(0x73558B, 0x90, 2, true)
			else
			   -- local value = memory.read(0x73558B, 2, true)
			   -- print(value)
			   memory.write(0x73558B, 15476, 2, true)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Все окружение становится светлым в любое время и погоду.")
		 
		 -- By 4elove4ik
		 if imgui.Checkbox(u8'NoWater', checkbox.nowater) then
		    if checkbox.nowater.v then
			   memory.fill(0x53DD31, 0x90, 5, false)
               memory.fill(0x53E004, 0x90, 5, false)
               memory.fill(0x53E142, 0x90, 5, false)
			else
			   memory.setuint32(0x53DD31,  0x1B191AE8, false)
               memory.setuint8(0x53DD31 + 0x4, 0x00, false)

               memory.setuint32(0x53E004, 0x1B1647E8, false)
               memory.setuint8(0x53E004 + 0x4, 0x00, false)
 
               memory.setuint32(0x53E142, 0x1B1509E8, false)
               memory.setuint8(0x53E142 + 0x4, 0x00, false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отключает воду (Визуально)")
		 
		 imgui.Spacing()
	  elseif tabmenu.settings == 7 then
	     
		 local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		 local score = sampGetPlayerScore(id)
		 local ip, port = sampGetCurrentServerAddress()
         
         if not ip:find(ipAbsolutePlay) then
            if ip:find(ipTraining) then
               imgui.TextColoredRGB(u8"TRAINING " ..tostring(ip) ..":".. tostring(port).. "  ".. os.date('%d.%m.%Y %X'))
            else
            imgui.TextColoredRGB(u8"SERVER " ..tostring(ip) ..":".. tostring(port).. "  ".. os.date('%d.%m.%Y %X'))
            end
         else
            imgui.TextColoredRGB(u8"Absolute Play " ..tostring(ip) ..":".. tostring(port).. "  ".. os.date('%d.%m.%Y %X'))
         end
         
	     imgui.Text(u8'Ваш текущий Gamestate: '..gamestates[sampGetGamestate() + 1])
		 imgui.PushItemWidth(200)
		 imgui.Combo(u8'##Gamestates', gamestate, gamestates)
		 imgui.SameLine()
		 if imgui.Button(u8'Сменить') then
			sampSetGamestate(gamestate.v)
		 end
		 if imgui.CollapsingHeader(u8"Логгировать в консоли:") then
            imgui.Checkbox(u8'Логгировать в консоли нажатые текстдравы', checkbox.logtextdraws)
            imgui.Checkbox(u8'Логгировать в консоли поднятые пикапы', checkbox.pickeduppickups)
            imgui.Checkbox(u8'Логгировать в консоли ответы на диалоги', checkbox.logdialogresponse)
            imgui.Checkbox(u8'Логгировать в консоли выбранные объекты', checkbox.logobjects)
            imgui.Checkbox(u8'Логгировать в консоли установку текстуры', checkbox.logtxd)
         end
         
		 imgui.Checkbox(u8'Отображать ID текстдравов', checkbox.showtextdrawsid)
		 if imgui.Checkbox(u8'Скрыть все текстдравы', checkbox.hidealltextdraws) then
		    for i = 0, 2048 do
               sampTextdrawDelete(i)
            end
		 end
		 if isAbsolutePlay then
		    local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local score = sampGetPlayerScore(id)
		    if score == 0 then
		       imgui.Checkbox(u8'Отключить урон', checkbox.nophealth)
			   if imgui.Button(u8'Выбор класса', imgui.ImVec2(200, 25)) then
			      local skin = getCharModel(PLAYER_PED)
	              sampRequestClass(skin)
				  --setPlayerModel(skin)
			   end
	        end
		 end
		
		 if imgui.Button(u8'Скрыть диалог', imgui.ImVec2(200, 25)) then
			enableDialog(false)
		 end
		 imgui.Text(u8'Последний ID диалога: ' .. sampGetCurrentDialogId())
	  
	     imgui.Spacing()
         if imgui.Button(u8"Выгрузить скрипт", imgui.ImVec2(150, 25)) then
            sampAddChatMessage("AbsEventHelper успешно выгружен.", -1)
            sampAddChatMessage("Для запуска используйте комбинацию клавиш CTRL + R.", -1)
            thisScript():unload()
         end
	     
		 imgui.SameLine()
		 if imgui.Button(u8"Реконнект (5 сек)", imgui.ImVec2(150, 25)) then
		    Recon()
	     end
		 
         if imgui.Checkbox(u8("Выгружать скрипт на других серверах"), checkbox.noabsunload) then
            if checkbox.noabsunload.v then
               ini.settings.noabsunload = not ini.settings.noabsunload
               save()
            end
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Выгружает скрипт при подключении не на Absolute Play")
	     imgui.Spacing()
      end -- end tabmenu.settings
      imgui.NextColumn()
	  
	  if imgui.Button(u8"Координаты",imgui.ImVec2(150, 25)) then tabmenu.settings = 1 end 
	  if imgui.Button(u8"Объекты",imgui.ImVec2(150, 25)) then tabmenu.settings = 2 end 
	  if imgui.Button(u8"Камера",imgui.ImVec2(150, 25)) then tabmenu.settings = 3 end 
	  if imgui.Button(u8"Стрим",imgui.ImVec2(150, 25)) then tabmenu.settings = 4 end 
	  if imgui.Button(u8"Погода",imgui.ImVec2(150, 25)) then tabmenu.settings = 5 end 
	  if imgui.Button(u8"Эффекты",imgui.ImVec2(150, 25)) then tabmenu.settings = 6 end 
	  if imgui.Button(u8"Прочее",imgui.ImVec2(150, 25)) then tabmenu.settings = 7 end 
	  
      imgui.Spacing()
      imgui.Columns(1)

      elseif tabmenu.main == 2 then

      --imgui.Text(u8"Здесь вы можете настроить чат-бинды для мероприятия.     ")
      imgui.ColorEdit4("##ColorEdit4lite", color, imgui.ColorEditFlags.NoInputs)   
	  imgui.SameLine()
	  imgui.Text(u8"Профиль: ")
	  imgui.SameLine()
	  imgui.PushItemWidth(100)
	  if imgui.Combo(u8'##ComboBoxProfiles', combobox.profiles, 
	  {'Default', 'Race', 'Derby', 'Survival', 'PvP', 'Death-Roof', 'TDM', 'Hide-n-Seek', 'Quiz'}, 9) then
         if combobox.profiles.v then cleanBindsForm() end
         if combobox.profiles.v == 0 then
		    reloadBindsFromConfig()
		    sampAddChatMessage('Загружен профиль Default из конфига', -1)
         end
         if combobox.profiles.v == 1 then
		    textbuffer.bind1.v = u8("Разрешено использовать починку транспорта")
            textbuffer.bind2.v = u8("Разрешено в случае смерти продолжить игру начиная от спавна")
            textbuffer.bind3.v = u8("Разрешено в случае вылета за границы трассы, продолжить игру начиная от места вылета")
            textbuffer.bind4.v = u8("Разрешено при поломке транспорта и невозможноcти починки, заказать его еще раз")
            textbuffer.bind5.v = u8("Разрешено на данном мероприятии играть без samp addon и последней версии клиента")
            textbuffer.bind6.v = u8("Запрещено находиться в афк после начала мероприятия")
            textbuffer.bind7.v = u8("Запрещено использовать телепорт и текстурные баги")
            textbuffer.bind8.v = u8("За первое место приз - , за второе - , за третье -")
            textbuffer.bindad.v = u8("Заходите на МП 'Гонки' в мир , приз ")
			sampAddChatMessage('Загружен профиль Race', -1)
         end
         if combobox.profiles.v == 2 then
		    textbuffer.bind1.v = u8("Запрещено использовать текстурные баги")
		    textbuffer.bind2.v = u8("Запрещено покидать транспорт - дисквалификация")
		    textbuffer.bind3.v = u8("Вы выбываете с игры в случае вылета за пределы арены")
		    textbuffer.bind4.v = u8("Вы выбываете с игры в случае уничтожения транспорта")
		    textbuffer.bind5.v = u8("Победит последний выживший игрок")
            textbuffer.bindad.v = u8("Заходите на МП 'Дерби' в мир , приз ")
			sampAddChatMessage('Загружен профиль Derby', -1)
		 end
         if combobox.profiles.v == 3 then
		    textbuffer.bind1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
            textbuffer.bind2.v = u8("Запрещены объединения более 2-х игроков")
            textbuffer.bind3.v = u8("Не мешаем другим игрокам, ждем начала")
            textbuffer.bind4.v = u8("")
            textbuffer.bind5.v = u8("Запрещено находиться в афк после начала мероприятия")
            textbuffer.bind6.v = u8("Начали! Желаю удачи всем игрокам")
            textbuffer.bind7.v = u8("Разрешены объеденения - не больше двух игроков")
            textbuffer.bind8.v = u8("Приз не может быть разделен при обоюдном согласии двух оставшихся команд")
            textbuffer.bindad.v = u8("Заходите на МП 'Выживание' в мир , приз ")
            sampAddChatMessage('Загружен профиль Survival', -1)
         end
         if combobox.profiles.v == 4 then
		    textbuffer.bind1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
		    textbuffer.bind2.v = u8("После получения оружия ждем отсчета")
		    textbuffer.bind3.v = u8("Начинаем только после окончания отсчета!")
		    textbuffer.bind4.v = u8("Если вы выстрелили раньше отсчета - дисквалификация")
		    textbuffer.bind5.v = u8("Если вы прошли во второй тур и находитесь афк - дисквалификация")
		    textbuffer.bind6.v = u8("Обман организатора - черный список МП")
		    textbuffer.bindad.v = u8("Заходите на МП 'Кемпа' в мир , приз ")
		    sampAddChatMessage('Загружен профиль PvP', -1)
		 end
		 if combobox.profiles.v == 5 then
		    textbuffer.bind1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
		    textbuffer.bind2.v = u8("Игроки которые упали с крыши - выбывают")
		    textbuffer.bind3.v = u8("Использование анимок и спец.действий запрещено!")
		    textbuffer.bind4.v = u8("Кто хочет быть пилотом?")
		    textbuffer.bind5.v = u8("Кто хочет быть водилой поливалки?")
		    textbuffer.bind6.v = u8("Запрещено запрыгивать на транспорт организаторов")
		    textbuffer.bindad.v = u8("Заходите на МП 'Смертельная крыша' в мир , приз ")
		    sampAddChatMessage('Загружен профиль Death-Roof', -1)
		 end
         if combobox.profiles.v == 6 then
		    textbuffer.bind1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
            textbuffer.bind2.v = u8("За попытку обмана организатора - ЧС мероприятий")
            textbuffer.bind3.v = u8("Увидели лагера или нарушителя пишите в лс")
            textbuffer.bind4.v = u8("Не мешаем другим игрокам, ждем начала")
            textbuffer.bind5.v = u8("Запрещено находиться в афк после начала мероприятия")
            textbuffer.bind6.v = u8("Начали! Желаю удачи всем игрокам")
            textbuffer.bind7.v = u8("Всем вернуться на спавн!")
            textbuffer.bind8.v = u8("Приз выдается в равном размере каждому участнику победившей команды")
            textbuffer.bind9.v = u8("Победившая команда - не выходите с мира, дождитесь выдачи призовых!")
            textbuffer.bind10.v = u8(" ")
            textbuffer.bindad.v = u8("Заходите на МП TDM в мир , приз ")
            sampAddChatMessage('Загружен профиль TDM', -1)
         end
		 if combobox.profiles.v == 7 then
		    textbuffer.bind1.v = u8("Запрещено прятаться в текстурах и объектах")
		    textbuffer.bind2.v = u8("Запрещено использовать баги и недоработки игры для победы")
			textbuffer.bind3.v = u8("Увидели нарушителя пишите в лс организатору")
			textbuffer.bind4.v = u8("Не мешаем другим игрокам, ждем начала")
            textbuffer.bind5.v = u8("Запрещено находиться в афк после начала мероприятия")
            textbuffer.bind6.v = u8("Все спрятались?")
            textbuffer.bind7.v = u8("Начали! Желаю удачи всем игрокам")
			textbuffer.bind8.v = u8("Всем вернуться на спавн!")
			textbuffer.bind9.v = u8("Победитель может быть только - один!")
		    textbuffer.bindad.v = u8("Заходите на МП Прятки в мир , приз ")
            sampAddChatMessage('Загружен профиль Hide-n-Seek', -1)
		 end
		 if combobox.profiles.v == 8 then
		    textbuffer.bind1.v = u8("Правила: организатор задает вопрос, а вы должны дать ответ быстрее всех")
		    textbuffer.bind2.v = u8("Кто первый ответ на заданный вопрос, получает балл")
		    textbuffer.bind3.v = u8("Игра продолжается пока кто-либо не наберет 3 балла")
		    textbuffer.bind4.v = u8("Не рекомендуется флудить и спамить в чат")
		    textbuffer.bind5.v = u8("Вопросы будут на тему ")
		    textbuffer.bind6.v = u8("Гугол, Яндекс и ChatGPT вам не помошники, вопросы специфические =)")
		    textbuffer.bind10.v = u8("Все готовы?")
		    textbuffer.bindad.v = u8("Проходит МП 'Викторина' на тему , приз ")
            sampAddChatMessage('Загружен профиль Quiz', -1)
		 end
      end
	  imgui.PopItemWidth()
       
       
       imgui.SameLine()
       if imgui.TooltipButton("[CC]", imgui.ImVec2(40, 25), u8:encode("Очистить чат")) then 
          ClearChat()
       end
       imgui.SameLine()
       if imgui.TooltipButton("[R]", imgui.ImVec2(40, 25), u8:encode("Перезагрузить бинды")) then 
         reloadBindsFromConfig()        
         sampAddChatMessage("Бинды были успешно презагружены из конфига", -1)
       end
       imgui.SameLine()
	   if imgui.TooltipButton("[S]", imgui.ImVec2(40, 25), u8:encode("Сохранить бинды")) then 
         ini.binds.textbuffer1 = u8:decode(textbuffer.bind1.v)
         ini.binds.textbuffer2 = u8:decode(textbuffer.bind2.v)
         ini.binds.textbuffer3 = u8:decode(textbuffer.bind3.v)
         ini.binds.textbuffer4 = u8:decode(textbuffer.bind4.v)
         ini.binds.textbuffer5 = u8:decode(textbuffer.bind5.v)
         ini.binds.textbuffer6 = u8:decode(textbuffer.bind6.v)
         ini.binds.textbuffer7 = u8:decode(textbuffer.bind7.v)
         ini.binds.textbuffer8 = u8:decode(textbuffer.bind8.v)
         ini.binds.textbuffer9 = u8:decode(textbuffer.bind9.v)
         ini.binds.textbuffer10 = u8:decode(textbuffer.bind10.v)
         ini.binds.adtextbuffer = u8:decode(textbuffer.bindad.v)
         save()          
         sampAddChatMessage("Бинды были успешно сохранены", -1)
       end
       imgui.SameLine()
       if imgui.TooltipButton(u8"[C]", imgui.ImVec2(40, 25), u8:encode("Очистить бинды")) then
          cleanBindsForm()
       end
       imgui.SameLine()
       if imgui.TooltipButton(u8"chatlog", imgui.ImVec2(60, 25), u8:encode("Открыть лог чата chatlog.txt")) then
	      os.execute('explorer '..getFolderPath(5) ..'\\GTA San Andreas User Files\\SAMP\\chatlog.txt')
	   end
	   
       -- line 1
       imgui.PushItemWidth(70)
       imgui.Combo('  1', combobox.item1, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind1", textbuffer.bind1) then 
       end
       
       -- if imgui.IsItemHovered() and imgui.IsMouseDown(1) then
          -- imgui.Text('Hovered and RMB down')
       -- end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind1") then
          if combobox.item1.v == 0 then
             u8:decode(textbuffer.bind1.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind1.v)))
          end
          if combobox.item1.v == 1 then
             u8:decode(textbuffer.bind1.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind1.v)))
          end
       end
       -- line 2
       imgui.PushItemWidth(70)
       imgui.Combo('  2', combobox.item2, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind2", textbuffer.bind2) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind2") then
          if combobox.item2.v == 0 then
             u8:decode(textbuffer.bind2.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind2.v)))
          end
          if combobox.item2.v == 1 then
             u8:decode(textbuffer.bind2.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind2.v)))
          end
       end
       -- line 3
       imgui.PushItemWidth(70)
       imgui.Combo('  3', combobox.item3, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind3", textbuffer.bind3) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind3") then
          if combobox.item3.v == 0 then
             u8:decode(textbuffer.bind3.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind3.v)))
          end
          if combobox.item3.v == 1 then
             u8:decode(textbuffer.bind3.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind3.v)))
          end
       end
       -- line 4
       imgui.PushItemWidth(70)
       imgui.Combo('  4', combobox.item4, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind4", textbuffer.bind4) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind4") then
          if combobox.item4.v == 0 then
             u8:decode(textbuffer.bind4.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind4.v)))
          end
          if combobox.item4.v == 1 then
             u8:decode(textbuffer.bind4.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind4.v)))
          end
       end
       -- line 5
       imgui.PushItemWidth(70)
       imgui.Combo('  5', combobox.item5, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind5", textbuffer.bind5) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind5") then
          if combobox.item5.v == 0 then
             u8:decode(textbuffer.bind5.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind5.v)))
          end
          if combobox.item5.v == 1 then
             u8:decode(textbuffer.bind5.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind5.v)))
          end
       end
       -- line 6
       imgui.PushItemWidth(70)
       imgui.Combo('  6', combobox.item6, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind6", textbuffer.bind6) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind6") then
          if combobox.item6.v == 0 then
             u8:decode(textbuffer.bind6.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind6.v)))
          end
          if combobox.item6.v == 1 then
             u8:decode(textbuffer.bind6.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind6.v)))
          end
       end
       -- line 7
       imgui.PushItemWidth(70)
       imgui.Combo('  7', combobox.item7, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind7", textbuffer.bind7) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind7") then
          if combobox.item7.v == 0 then
             u8:decode(textbuffer.bind7.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind7.v)))
          end
          if combobox.item7.v == 1 then
             u8:decode(textbuffer.bind7.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind7.v)))
          end
       end
       -- line 8
       imgui.PushItemWidth(70)
       imgui.Combo('  8', combobox.item8, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind8", textbuffer.bind8) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind8") then
          if combobox.item8.v == 0 then
             u8:decode(textbuffer.bind8.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind8.v)))
          end
          if combobox.item8.v == 1 then
             u8:decode(textbuffer.bind8.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind8.v)))
          end
       end
       -- line 9
       imgui.PushItemWidth(70)
       imgui.Combo('  9', combobox.item9, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind9", textbuffer.bind9) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind9") then
          if combobox.item9.v == 0 then
             u8:decode(textbuffer.bind9.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind9.v)))
          end
          if combobox.item9.v == 1 then
             u8:decode(textbuffer.bind9.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind9.v)))
          end
       end
	   -- line 10
       imgui.PushItemWidth(70)
       imgui.Combo('10', combobox.item10, {u8'мчат', u8'общий'}, 2)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##Bind10", textbuffer.bind10) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBind10") then
          if combobox.item10.v == 0 then
             u8:decode(textbuffer.bind10.v)
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bind10.v)))
          end
          if combobox.item10.v == 1 then
             u8:decode(textbuffer.bind10.v)
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bind10.v)))
          end
       end
       -- last line
       imgui.PushItemWidth(70)
       imgui.Combo('    ', combobox.itemad, {u8'объявление', u8'общий', u8'мчат'}, 3)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       if imgui.InputText("##BindAd", textbuffer.bindad) then 
       end
       
       imgui.SameLine()
       if imgui.Button(u8"[>]##SendchatBindAd") then
          if combobox.itemad.v == 0 then
             sampSendChat(string.format("/об %s", u8:decode(textbuffer.bindad.v)))
          end
          if combobox.itemad.v == 1 then
             sampSendChat(string.format("* %s", u8:decode(textbuffer.bindad.v)))
          end
          if combobox.itemad.v == 2 then
             sampSendChat(string.format("/мчат %s", u8:decode(textbuffer.bindad.v)))
          end
       end
       
	   imgui.TextColoredRGB("* {00FF00}@ номер игрока - {bababa}заменит id на никнейм игрока. Цветной текст указывать через скобки (FF0000)")
       --imgui.Separator()
       
      elseif tabmenu.main == 3 then
       
	   if dialog.extendedtab.v then
	      if imgui.Button("[ >> ]") then
	         dialog.extendedtab.v = not dialog.extendedtab.v
	      end
	   else
	      if imgui.Button("[ << ]") then
	         dialog.extendedtab.v = not dialog.extendedtab.v
	      end
       end	   
	   imgui.SameLine()
	   --imgui.TextQuestion("( ? )", u8"Открыть расширенные настройки")
	   --imgui.SameLine()
	   imgui.Text(u8"Выберите таблицу:")
	   imgui.SameLine()
	   imgui.PushItemWidth(120)
	   imgui.Combo(u8'##ComboBoxSelecttable', combobox.selecttable, 
	   {u8'Игроки', u8'Транспорт'}, 2)
	   imgui.PopItemWidth()
	   
	   if combobox.selecttable.v == 0 then
          if next(playersTable) == nil then -- if playersTable is empty
             imgui.Text(u8"Перед началом мероприятия обновите список игроков, и сохраните")
          end
          
          if imgui.TooltipButton(u8"Обновить", imgui.ImVec2(100, 25), u8:encode("Обновить таблицу")) then
             playersTable = {}       
             playersTotal = 0
             
             for k, v in ipairs(getAllChars()) do
                local res, id = sampGetPlayerIdByCharHandle(v)
                if res then
                   table.insert(playersTable, id)
                   playersTotal = playersTotal + 1
                end
             end
          end
       
          imgui.SameLine()
          if imgui.TooltipButton(u8"Сохранить", imgui.ImVec2(100, 25), u8:encode("Сохранить таблицу")) then 
             ptablefile = io.open(getGameDirectory().."/moonloader/resource/abseventhelper/players.txt", "a")
             ptablefile:write("\n")
             ptablefile:write(string.format("%s \n", os.date("%d.%m.%y %H:%M:%S")))
             local counter = 0
             for k, v in pairs(playersTable) do
                ptablefile:write(string.format("%d [id:%d] %s lvl: %i \n",
                counter + 1, v, sampGetPlayerNickname(v), sampGetPlayerScore(v)))
                counter = counter + 1
             end
             ptablefile:write(string.format("Total: %d \n", counter))
             ptablefile:close()
             sampAddChatMessage("Список игроков сохранен в moonloader/resource/abseventhelper/players.txt", -1)
          end
          
          imgui.SameLine()
          if imgui.TooltipButton(u8"Очистить", imgui.ImVec2(100, 25), u8:encode("Очистить таблицу")) then
             playersTable = {}       
             playersTotal = 0
			 if dialog.playerstat.v then dialog.playerstat.v = false end
			 chosenplayer = nil
          end
          imgui.SameLine()
          imgui.Text(u8"Найти в таблице:")
       
          imgui.SameLine()
          imgui.PushItemWidth(170)
          if imgui.InputText("##FindPlayer", textbuffer.findplayer) then 
             for k, v in pairs(playersTable) do
                local nickname = sampGetPlayerNickname(v)
                if nickname == u8:decode(textbuffer.findplayer.v) then
                   printStringNow("finded", 1000)
                   chosenplayer = sampGetPlayerIdByNickname(nickname)
                end
             end
          end
          imgui.PopItemWidth()
       
          if chosenplayer then
             local nickname = sampGetPlayerNickname(chosenplayer)
             local ucolor = sampGetPlayerColor(chosenplayer)
             imgui.TextColoredRGB(string.format("Выбран игрок: {%0.6x} %s[%d]",
             bit.band(ucolor,0xffffff), nickname, chosenplayer))
          else
		     imgui.TextColoredRGB("{FF0000}Красным{CDCDCD} в таблице отмечены подозрительные игроки (малый лвл, большой пинг)")
		  end
       
          --imgui.Spacing()
          imgui.Separator()
          imgui.Columns(5)
          imgui.TextQuestion("[ID]", u8"Нажмите на id чтобы скопировать в буффер id игрока")
          imgui.NextColumn()
          imgui.TextQuestion("Nickname", u8"Нажмите на никнейм чтобы открыть меню игрока")
          imgui.NextColumn()
          imgui.Text("Score")
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
                sampAddChatMessage("Скопирован в буфер обмена", -1)
             end
             imgui.SetColumnWidth(-1, 50)
             imgui.NextColumn()
		     if sampIsPlayerPaused(v) then
	            imgui.TextColoredRGB("{FF0000}[AFK]")
	            imgui.SameLine()
	         end
             --imgui.TextColoredRGB(string.format("{%0.6x} %s", bit.band(ucolor,0xffffff), nickname))
             imgui.Selectable(u8(nickname))
             if imgui.IsItemClicked() then
                chosenplayer = v
                printStringNow("You have chosen a player ".. nickname, 1000)
			    if not dialog.playerstat.v then dialog.playerstat.v = true end
             end
             imgui.SetColumnWidth(-1, 250)
             imgui.NextColumn()
             if (score < 20) then
                imgui.TextColoredRGB(string.format("{FF0000}%i", score))
             else 
                imgui.TextColoredRGB(string.format("%i", score))
             end
             imgui.SetColumnWidth(-1, 70)
             imgui.NextColumn()
             if health >= 9000 then
             imgui.TextColoredRGB("{FF0000}Бессмертный")
             elseif health <= 100 then
                imgui.TextColoredRGB(string.format("%i (%i)", health, armor))
             else
                imgui.TextColoredRGB(string.format("{FF0000}%i (%i)", health, armor))
             end
			 imgui.SetColumnWidth(-1, 100)
             imgui.NextColumn()
             if (ping > 90) then
                imgui.TextColoredRGB(string.format("{FF0000}%i", ping))
             else
                imgui.TextColoredRGB(string.format("%i", ping))
             end
             imgui.NextColumn()
             imgui.Columns(1)
             imgui.Separator()
          end
    
          imgui.Text(u8"Всего игроков в таблице: ".. playersTotal)
      
          if checkbox.heavyweaponwarn.v then
             for k, v in ipairs(getAllChars()) do
                local res, id = sampGetPlayerIdByCharHandle(v)
                if res then
                   local nick = sampGetPlayerNickname(id)
                   if isCurrentCharWeapon(v, 38) then 
                      imgui.TextColoredRGB(string.format("{FF0000}Игрок %s[%d] с миниганом!", nick, id))
                   end
                   if isCurrentCharWeapon(v, 35) then 
                      imgui.TextColoredRGB(string.format("{FF0000}Игрок %s[%d] с RPG!", nick, id))
                   end
                end
             end
          end
      
	  elseif combobox.selecttable.v == 1 then
         --elseif tabmenu.main == 4 then
         imgui.Columns(2, "vehtableheader", false)
         imgui.SetColumnWidth(-1, 320)
         -- https://wiki.multitheftauto.com/wiki/Vehicle_IDs
         imgui.Text(u8"Найти ID транспорта по имени:")
         if imgui.InputText("##BindVehs", textbuffer.vehiclename) then 
            for k, vehname in ipairs(VehicleNames) do
               if vehname:lower():find(u8:decode(textbuffer.vehiclename.v:lower())) then
                  vehinfomodelid = 399+k
               end
            end
         end 
       
         imgui.SameLine()
         if textbuffer.vehiclename.v == "" then
            imgui.Spacing()
         else
            imgui.Text(string.format(u8"ID: %i", vehinfomodelid))
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Введите имя транспорта, например Infernus")
       
         local closestcarhandle, closestcarid = getClosestCar()
         if closestcarhandle then
            local closestcarmodel = getCarModel(closestcarhandle)
            imgui.Text(string.format(u8"Ближайший т/с: %s [id: %i] (%i)",
            VehicleNames[closestcarmodel-399], closestcarmodel, closestcarid))
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"В скобках указан внутренний ID (/dl)")
         else
            imgui.Text(u8"Нет транспорта в зоне стрима")
         end
       
         if isCharInAnyCar(PLAYER_PED) then 
            local carhandle = storeCarCharIsInNoSave(PLAYER_PED)
            local carmodel = getCarModel(carhandle)
            imgui.Text(string.format(u8"Вы в транспорте: %s(%i)  хп: %i",
            VehicleNames[carmodel-399], carmodel, getCarHealth(carhandle)))
         end
       
         imgui.NextColumn()
         if imgui.Button(u8"Заказать машину по имени", imgui.ImVec2(200, 25)) then
            if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not  isSampfuncsConsoleActive() then
               for k, vehname in ipairs(VehicleNames) do
                  if vehname:lower():find(u8:decode(textbuffer.vehiclename.v:lower())) then
                     vehinfomodelid = 399+k
                  end 
               end
               if isAbsolutePlay then 
			      sampSendChat(string.format(u8"/vfibye2 %i", vehinfomodelid))
			   else
                  sampSendChat(string.format(u8"/v %i", vehinfomodelid))
			   end
            end
         end
	     -- imgui.SameLine()
	     -- if imgui.Button(u8"Найти ID траспорта онлайн", imgui.ImVec2(190, 25)) then
	        -- os.execute('explorer "https://wiki.multitheftauto.com/wiki/Vehicle_IDs"')
	     -- end
	     if imgui.Button(u8"Заказать машину из списка", imgui.ImVec2(200, 25)) then
	        if isAbsolutePlay then
               if not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
			       sampSendChat("/vfibye2")
				   dialog.main.v = not dialog.main.v
		       end
            end
	     end
		 
		 if imgui.Button(u8"Информация о модели (онлайн)", imgui.ImVec2(200, 25)) then
		    if vehinfomodelid then
               if vehinfomodelid > 400 and vehinfomodelid < 611 then 
	              os.execute(string.format('explorer "http://gta.rockstarvision.com/vehicleviewer/#sa/%d"', vehinfomodelid))
               else
                  sampAddChatMessage("Некорректный ид транспорта", -1)
               end
			end
	     end
	     -- imgui.SameLine()
	     -- if imgui.Button(u8"Handling.cfg (онлайн)", imgui.ImVec2(190, 25)) then
	     -- os.execute('explorer "https://github.com/ins1x/useful-samp-stuff/blob/main/docs/server/VehicleHandling.txt"')
	     -- end
	   
         imgui.Columns(1)
         imgui.Checkbox(u8("Показать список транспорта в стриме"), checkbox.vehstream)
         --imgui.Checkbox(u8("Скрывать пустой транспорт"), checkbox.noempyvehstream)
         if checkbox.vehstream.v then
            
			vehiclesTable = {}
            vehiclesTotal = 0
          
            for k, v in ipairs(getAllVehicles()) do
               local streamed, id = sampGetVehicleIdByCarHandle(v)
               if streamed then
			  	  table.insert(vehiclesTable, v)
                  vehiclesTotal = vehiclesTotal + 1
               end
            end
			
            imgui.Separator()
            imgui.Columns(4)
            imgui.TextQuestion("ID", u8"Внутренний ID (/dl)")
            imgui.NextColumn()
            imgui.Text("Vehicle")
            imgui.NextColumn()
            imgui.SetColumnWidth(-1, 350)
            imgui.Text("Driver")
            imgui.NextColumn()
            imgui.Text("Health")
            imgui.NextColumn()
            imgui.Columns(1)
            imgui.Separator()
          
            for k, v in ipairs(getAllVehicles()) do
               local health = getCarHealth(v)
               local carmodel = getCarModel(v)
               local streamed, id = sampGetVehicleIdByCarHandle(v)
               local ped = getDriverOfCar(v)
               local res, pid = sampGetPlayerIdByCharHandle(ped)
			   local vehmodelname = nil
			   
               imgui.Columns(4)
               imgui.TextColoredRGB(string.format("%i", id))
               imgui.SetColumnWidth(-1, 50)
               imgui.NextColumn()
			   if carmodel == 447 or carmodel == 425 or carmodel == 432 or carmodel == 520 then
                  vehmodelname = string.format("{FF0000}%s", VehicleNames[carmodel-399])
			   elseif carmodel == 476 or carmodel == 430 or carmodel == 406 or carmodel == 592 then
			      vehmodelname = string.format("{FF8C00}%s", VehicleNames[carmodel-399])
			   elseif carmodel == 601 or carmodel == 407 then
			      vehmodelname = string.format("{1E90FF}%s", VehicleNames[carmodel-399])
			   else
			      vehmodelname = string.format("%s", VehicleNames[carmodel-399])
			   end
			   
			   imgui.TextColoredRGB(vehmodelname)
			   if imgui.IsItemClicked() then 
				  textbuffer.vehiclename.v = tostring(VehicleNames[carmodel-399])
				  vehinfomodelid = carmodel
			   end
			   
               imgui.NextColumn()
               if res then 
				  imgui.Selectable(string.format(u8"%s", sampGetPlayerNickname(pid)))
                  if imgui.IsItemClicked() then
                     chosenplayer = pid
                     printStringNow("You have chosen a player ".. sampGetPlayerNickname(pid), 1000)
			         if not dialog.playerstat.v then dialog.playerstat.v = true end
                  end
               else
                  imgui.Text(u8"пустой")
               end
               imgui.NextColumn()
               if health > 10000 then
                  imgui.TextColoredRGB("{ff0000}GM")
               elseif health > 1000 then
                  imgui.TextColoredRGB(string.format("{ff0000}%i", health))
               elseif health < 450 then
                  imgui.TextColoredRGB(string.format("{ff8c00}%i", health))
               else 
                  imgui.TextColoredRGB(string.format("%i", health))
               end
               imgui.Columns(1)
               imgui.Separator()
            end
          
            if checkbox.vehstream.v then
               imgui.Text(u8"Всего транспорта в таблице: ".. vehiclesTotal)
            end
         end
	  end

      elseif tabmenu.main == 4 then
      imgui.Columns(2)
      imgui.SetColumnWidth(-1, 510)
      
      if tabmenu.info == 1 then
         imgui.Text(u8"Absolute Events Helper v".. thisScript().version)
         imgui.TextColoredRGB("Ассистент для мапперов и организаторов мероприятий на серверах {007DFF}Absolute Play.")
		 if imgui.IsItemClicked() then
            setClipboardText(ipAbsolutePlay)
			sampAddChatMessage("IP скопирован в буфер обмена", -1)
         end
         imgui.Text(u8"Скрипт позволит сделать процесс маппинга в внутриигровом редакторе карт")
         imgui.Text(u8"максимально приятным, и даст больше возможностей организаторам мероприятий")
         imgui.Text(u8"Скрипт распостраняется только с открытым исходным кодом")
		 if isAbsolutePlay then
            imgui.Text(u8"Категорически не рекомендуется использовать этот скрипт вне редактора карт!")
		 end
		 imgui.TextColoredRGB("Протестировать скрипт можно на Absolute DM Play в мире №10 {007DFF}(/мир 10)")
		 if imgui.IsItemClicked() then
            if isAbsolutePlay then sampSendChat("/мир 10") end
         end
         imgui.Text(u8"")
         
		 if isAbsfixInstalled then
		    imgui.TextColoredRGB("Спасибо что используете ")
			imgui.SameLine()
 		    imgui.Link("https://github.com/ins1x/useful-samp-stuff/tree/main/luascripts/absolutefix", "AbsoluteFix")
		 end
		 
         imgui.Text("Homepage:")
		 imgui.SameLine()
		 imgui.Link("https://github.com/ins1x/AbsEventHelper", "ins1x/AbsEventHelper")
		 
		 imgui.Text(u8"Сайт Absolute Play:")
		 imgui.SameLine()
		 imgui.Link("https://gta-samp.ru", "gta-samp.ru")
         
		 imgui.Text(u8"Blast.hk thread:")
		 imgui.SameLine()
		 imgui.Link("https://www.blast.hk/threads/200619/", "https://www.blast.hk")
		 
		 imgui.Text(u8"YouTube:")
		 imgui.SameLine()
		 imgui.Link("https://www.youtube.com/@1nsanemapping", "1nsanemapping")
		 
		 if imgui.Button(u8"Check updates",imgui.ImVec2(150, 25)) then
		    os.execute('explorer https://github.com/ins1x/AbsEventHelper/releases')
		 end
         imgui.Spacing()
		--imgui.Text(u8"Disclaimer: Автор не является частью команды проекта Absolute Play")
      elseif tabmenu.info == 2 then
         if isAbsolutePlay then
            imgui.Text(u8"Каждый игрок от 20 уровня может при наличии свободных слотов создать мир.")
            imgui.TextColoredRGB("Для создания мира необходимо иметь {00FF00}100 ОА (Очков апгрейда) и 1.000.000$.{FFFFFF}")
            imgui.TextColoredRGB("По-умолчанию в мире можно создавать только {00FF00}50 объектов")
            imgui.TextColoredRGB("Данный лимит можно расширить до {00FF00}300 объектов")
            imgui.TextColoredRGB("VIP игроки могут расширять лимит до {00FF00}2000 объектов.{FFFFFF}")
            imgui.TextColoredRGB("Стоимость расширения мира {00FF00}20 ОА и 500.000$ за 10 объектов.{FFFFFF}") 
            imgui.Spacing()
		 end
		 if imgui.CollapsingHeader(u8"Лимиты в SAMP:") then
		    imgui.TextColoredRGB("Игроки: 1000, Транспорт 2000")
            imgui.TextColoredRGB("Объекты: 1000 (для 0.3.7), 2000 (для 0.3.DL)")
            imgui.TextColoredRGB("Пикапы: {00FF00}4096")
            imgui.TextColoredRGB("Иконки на карте: {00FF00}100")
            imgui.TextColoredRGB("3d-тексты: {00FF00}1024")
            imgui.TextColoredRGB("Актёры: {00FF00}1000")
            imgui.TextColoredRGB("Гангзоны: {00FF00}1024")
		 end
		 if imgui.CollapsingHeader(u8"Streamer:") then
            imgui.TextColoredRGB("STREAMER_OBJECT_SD {00FF00}300.0")
            imgui.TextColoredRGB("STREAMER_OBJECT_DD {00FF00}300.0")
            imgui.TextColoredRGB("STREAMER_PICKUP_SD {00FF00}200.0")
            imgui.TextColoredRGB("STREAMER_CP_SD {00FF00}200.0")
            imgui.TextColoredRGB("STREAMER_RACE_CP_SD {00FF00}200.0")
            imgui.TextColoredRGB("STREAMER_MAP_ICON_SD {00FF00}200.0")
            imgui.TextColoredRGB("STREAMER_3D_TEXT_LABEL_SD {00FF00}200.0")
            imgui.TextColoredRGB("STREAMER_ACTOR_SD {00FF00}200.0")
		 end
		 if imgui.CollapsingHeader(u8"Лимиты в мире:") then
            if isAbsolutePlay then
               imgui.TextColoredRGB("макс. объектов: {00FF00}300 (VIP 2000)")
               imgui.TextColoredRGB("макс. объектов в одной точке: {00FF00}200 ")
               imgui.TextColoredRGB("макс. пикапов: {00FF00}500")
               imgui.TextColoredRGB("макс. маркеров для гонок: {00FF00}40")
               imgui.TextColoredRGB("макс. транспорта: {00FF00}50")
               imgui.TextColoredRGB("макс. слотов под гонки: {00FF00}5")
               imgui.TextColoredRGB("макс. виртуальных миров: {00FF00}500")
            end
            if isTraining then
               imgui.TextColoredRGB("Слоты сохранения игровых миров: {00FF00}3 > 10")
               imgui.TextColoredRGB("Объекты: {00FF00}300 > 3500")
               imgui.TextColoredRGB("Пикапы(проходы): {00FF00}20 > 100")
               imgui.TextColoredRGB("Актеры: {00FF00}50 > 200")
               imgui.TextColoredRGB("Транспорт: {00FF00}30 > 80")
            end
         end
         imgui.Text(u8"В радиусе 150 метров нельзя создавать более 200 объектов.")
         imgui.TextColoredRGB("Максимальная длина текста на объектах в редакторе миров - {00FF00}50 символов")
         
		 -- imgui.Text("")
		 -- imgui.TextColoredRGB("Лимиты в SA:MP на {007DFF}https://www.open.mp/docs/scripting/resources/limits")
         -- if imgui.IsItemClicked() then
            -- os.execute('explorer "https://www.open.mp/docs/scripting/resources/limits"')
         -- end

      elseif tabmenu.info == 3 then

         imgui.Text(u8"Цветовая палитра")
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
         if imgui.Button("{FF0000}  RED    ", imgui.ImVec2(120, 25)) then
            setClipboardText("{FF0000}")
		    sampAddChatMessage("Цвет {FF0000}RED{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.0, 1.0))
         imgui.SameLine()
         if imgui.Button("{008000}  GREEN ", imgui.ImVec2(120, 25)) then 
            setClipboardText("{008000}")
			sampAddChatMessage("Цвет {008000}GREEN{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 1.0, 1.0))
         imgui.SameLine()
         if imgui.Button("{0000FF}  BLUE  ", imgui.ImVec2(120, 25)) then
            setClipboardText("{0000FF}")
			sampAddChatMessage("Цвет {0000FF}BLUE{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
       -- next line
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 0.0, 1.0))
         if imgui.Button("{FFFF00}  YELLOW", imgui.ImVec2(120, 25)) then
            setClipboardText("{FFFF00}")
			sampAddChatMessage("Цвет {FFFF00}YELLOW{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
         
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 1.0, 1.0))
         imgui.SameLine()
         if imgui.Button("{FF00FF}  PINK  ", imgui.ImVec2(120, 25)) then
            setClipboardText("{FF00FF}")
			sampAddChatMessage("Цвет {FF00FF}PINK{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
         
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 1.0, 1.0))
         imgui.SameLine()
         if imgui.Button("{00FFFF}  AQUA  ", imgui.ImVec2(120, 25)) then
            setClipboardText("{00FFFF}")
			sampAddChatMessage("Цвет {00FFFF}AQUA{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
       -- next line
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 0.0, 1.0))
         if imgui.Button("{00FF00}  LIME  ", imgui.ImVec2(120, 25)) then 
            setClipboardText("{00FF00}")
			sampAddChatMessage("Цвет {00FF00}LIME{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.5, 1.0))
         imgui.SameLine()
         if imgui.Button("{800080}  PURPLE", imgui.ImVec2(120, 25)) then
            setClipboardText("{800080}")
			sampAddChatMessage("Цвет {800080}PURPLE{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.0, 1.0))
         imgui.SameLine()
         if imgui.Button("{800000}  MAROON", imgui.ImVec2(120, 25)) then
            setClipboardText("{800000}")
			sampAddChatMessage("Цвет {800000}MAROON{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
       -- next line
        
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.0, 1.0))
         if imgui.Button("{808000}  OLIVE ", imgui.ImVec2(120, 25)) then
            setClipboardText("{808000}")
			sampAddChatMessage("Цвет {808000}OLIVE{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.5, 1.0))
         imgui.SameLine()
         if imgui.Button("{008080}  TEAL  ", imgui.ImVec2(120, 25)) then
            setClipboardText("{008080}")
			sampAddChatMessage("Цвет {008080}TEAL{FFFFFF} скопирован в буфер обмена", -1)
         end     
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.6, 0.0, 1.0))
         imgui.SameLine()
         if imgui.Button("{FF9900}  ORANGE", imgui.ImVec2(120, 25)) then
            setClipboardText("{FF9900}")
			sampAddChatMessage("Цвет {FF9900}ORANGE{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         -- next line
         
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
         if imgui.Button("{FFFFFF}  WHITE ", imgui.ImVec2(120, 25)) then 
            setClipboardText("{FFFFFF}")
			sampAddChatMessage("Цвет WHITE скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
         imgui.SameLine()
         if imgui.Button("{808080}  GREY  ", imgui.ImVec2(120, 25)) then 
            setClipboardText("{808080}")
			sampAddChatMessage("Цвет {808080}GREY{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
         imgui.SameLine()
         if imgui.Button("{000000}  BLACK ", imgui.ImVec2(120, 25)) then
            setClipboardText("{000000}")
			sampAddChatMessage("Цвет {000000}BLACK{FFFFFF} скопирован в буфер обмена", -1)
         end
         imgui.PopStyleColor()
       
         imgui.Text(u8"Тест RGB текста, например введите: {00FF00}Текст")
         if imgui.InputText("##RGBtext", textbuffer.rgb) then
         end
         imgui.TextColoredRGB(textbuffer.rgb.v)
       
         imgui.SameLine()
         if imgui.Button(u8"Скопировать") then
            setClipboardText(textbuffer.rgb.v)
			sampAddChatMessage("Текст скопирован в буфер обмена", -1)
         end
       
         imgui.Text(u8"RR — красная часть цвета, GG — зеленая, BB — синяя, AA — альфа")
         imgui.ColorEdit4("##ColorEdit4", color)
         imgui.SameLine()
		 local hexcolor = tostring(intToHex(join_argb(color.v[4] * 255,
		 color.v[1] * 255, color.v[2] * 255, color.v[3] * 255)))
         imgui.Text("HEX: " .. hexcolor)
         if imgui.IsItemClicked() then
            setClipboardText(hexcolor)
            sampAddChatMessage("Цвет скопирован в буфер обмена", -1)
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Нажмите чтобы скопировать цвет в буффер обмена")
		 
		 if isCharInAnyCar(PLAYER_PED) then 
            local carhandle = storeCarCharIsInNoSave(PLAYER_PED)
            imgui.TextColoredRGB(string.format("Цвет текущего т/с %d и %d", getCarColours(carhandle)))
         end
		 
		 imgui.Spacing()
		 imgui.TextColoredRGB("Цвета транспорта")
		 imgui.SameLine()
		 imgui.Link("https://www.open.mp/docs/scripting/resources/vehiclecolorid", "www.open.mp")
         		 
		 imgui.TextColoredRGB("Другие цвета")
		 imgui.SameLine()
		 imgui.Link("https://encycolorpedia.ru/websafe", "encycolorpedia.ru")
         
      elseif tabmenu.info == 4 then
      
		 if imgui.CollapsingHeader(u8'Доступные текстуры на Absolute Play:') then
            --imgui.InputTextMultiline('##bufftextures', textbuffer.texturesbuff, imgui.ImVec2(480, 150))
            if isAbsolutePlay then
               local texturelink
               local texturename
               imgui.Spacing()
               imgui.Link("https://textures.xyin.ws/", "1.No texture")
               for k, txdname in pairs(AbsTxdNames) do
                  if k % 3 ~= 0 then imgui.SameLine() end
                  texturelink = string.format("https://textures.xyin.ws/?page=textures&limit=10&search=%s", AbsTxdNames[k+1])
                  texturename = string.format("%d.%s", k+1, AbsTxdNames[k+1])
                  imgui.Link(texturelink, texturename)
               end
            end
		 end
		 
		 if imgui.CollapsingHeader(u8'Популярные шрифты') then
            if isAbsolutePlay then
               local fontlink
               imgui.Spacing()
               for k, fontname in pairs(AbsFontNames) do
                  fontlink = string.format("https://flamingtext.ru/Font-Search?q=%s", fontname)
                  imgui.Link(fontlink, fontname)
               end
            end
            imgui.Spacing()
            imgui.Text(u8"Пример использования:")
            imgui.TextColoredRGB(u8'SetObjectMaterialText(string, "TEST", 0, 140, "webdings", 150, 0, -65536, 0, 1);')
            if isAbsolutePlay then 
			   imgui.TextColoredRGB("Максимальный размер шрифта 200")
			else
			   imgui.TextColoredRGB("Максимальный размер шрифта 255")
            end
         end
		 if imgui.CollapsingHeader(u8'Поверхности для текста') then
		    imgui.TextColoredRGB("Прозрачные ровные плоские поверхности без коллизий, для SetObjectMaterialText")
		    imgui.TextColoredRGB("{00FF00}19480{FFFFFF} - Размер (радиус):{00FF00} 11.070")
			if imgui.IsItemClicked() then
                setClipboardText("19480")
                sampAddChatMessage("19480 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19481{FFFFFF} - Размер (радиус):{00FF00} 19.582")
			if imgui.IsItemClicked() then
                setClipboardText("19481")
                sampAddChatMessage("19481 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19479{FFFFFF} - Размер (радиус):{00FF00} 8.096")
			if imgui.IsItemClicked() then
                setClipboardText("19479")
                sampAddChatMessage("19479 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19482{FFFFFF} - Размер (радиус):{00FF00} 3.108")
			if imgui.IsItemClicked() then
                setClipboardText("19482")
                sampAddChatMessage("19482 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19477{FFFFFF} - Размер (радиус):{00FF00} 1.555")
			if imgui.IsItemClicked() then
                setClipboardText("19477")
                sampAddChatMessage("19477 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19483{FFFFFF} - Размер (радиус):{00FF00} 1.436")
			if imgui.IsItemClicked() then
                setClipboardText("19483")
                sampAddChatMessage("19483 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19476{FFFFFF} - Размер (радиус):{00FF00} 0.529")
			if imgui.IsItemClicked() then
                setClipboardText("19476")
                sampAddChatMessage("19476 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19475{FFFFFF} - Размер (радиус):{00FF00} 0.130")
			if imgui.IsItemClicked() then
                setClipboardText("19475")
                sampAddChatMessage("19475 - Скопирован в буфер обмена", -1)
            end
		    imgui.TextColoredRGB("{00FF00}19480{FFFFFF} - Размер (радиус):{00FF00} 0.141")
			if imgui.IsItemClicked() then
                setClipboardText("19480")
                sampAddChatMessage("19480 - Скопирован в буфер обмена", -1)
            end
		 end
		 if imgui.CollapsingHeader(u8'Размеры текста') then
		    imgui.TextColoredRGB("Для SetObjectMaterialText существует два типа параметров: ")
			imgui.TextColoredRGB("выравнивание текста материала, и размеры текста материала.")
			imgui.TextColoredRGB("Размеры текста указаны в таблице:")
		    imgui.TextColoredRGB("10  - OBJECT_MATERIAL_SIZE_32x32")
		    imgui.TextColoredRGB("20  - OBJECT_MATERIAL_SIZE_64x32")
		    imgui.TextColoredRGB("30  - OBJECT_MATERIAL_SIZE_64x64")
		    imgui.TextColoredRGB("40  - OBJECT_MATERIAL_SIZE_128x32")
		    imgui.TextColoredRGB("50  - OBJECT_MATERIAL_SIZE_128x64")
		    imgui.TextColoredRGB("60  - OBJECT_MATERIAL_SIZE_128x128")
		    imgui.TextColoredRGB("70  - OBJECT_MATERIAL_SIZE_256x32")
		    imgui.TextColoredRGB("80  - OBJECT_MATERIAL_SIZE_256x64")
		    imgui.TextColoredRGB("90  - OBJECT_MATERIAL_SIZE_256x128")
		    imgui.TextColoredRGB("100 - OBJECT_MATERIAL_SIZE_256x256")
		    imgui.TextColoredRGB("110 - OBJECT_MATERIAL_SIZE_512x64")
		    imgui.TextColoredRGB("120 - OBJECT_MATERIAL_SIZE_512x128")
		    imgui.TextColoredRGB("130 - OBJECT_MATERIAL_SIZE_512x256")
		    imgui.TextColoredRGB("140 - OBJECT_MATERIAL_SIZE_512x512")
		 end
		 
		 imgui.Spacing()
		 imgui.TextColoredRGB("Список всех спецсимволов")
		 imgui.SameLine()
		 imgui.Link("https://pawnokit.ru/ru/spec_symbols", "pawnokit.ru")
		 
		 imgui.TextColoredRGB("Список всех текстур GTA:SA")
		 imgui.SameLine()
		 imgui.Link("https://textures.xyin.ws/?page=textures&p=1&limit=100", "textures.xyin.ws")
		 
		 imgui.TextColoredRGB("TXD textures list")
		 imgui.SameLine()
		 imgui.Link("https://dev.prineside.com/gtasa_samp_game_texture/view/", "dev.prineside.com")
		
         imgui.TextColoredRGB("Браузер спрайтов")
		 imgui.SameLine()
		 imgui.Link("https://pawnokit.ru/ru/txmngr", "pawnokit.ru")
         
		 imgui.TextColoredRGB("Вики по функцииям")
		 imgui.SameLine()
		 imgui.Link("https://www.open.mp/docs/scripting/functions/SetObjectMaterialText", "SetObjectMaterialText")
		 imgui.SameLine()
		 imgui.Link("https://www.open.mp/docs/scripting/functions/SetObjectMaterial", "SetObjectMaterial")
		 
      elseif tabmenu.info == 5 then
         
		 imgui.Text(u8"Выберите категорию: ")
		 imgui.SameLine()
         if imgui.Combo(u8'##ComboBoxObjects', combobox.objects, 
	     {u8'Основные', u8'Специальные', u8'Эффекты', u8'Освещение',
		 u8'Интерьер', u8'Избранные', u8'Поиск (Онлайн)'}, 7) then
		 end
		 
		 imgui.Spacing()
		 
         if combobox.objects.v == 0 then
            imgui.Text(u8"Большие прозрачные объекты для текста: 19481, 19480, 19482, 19477")
            --imgui.Selectable(u8"Большие прозрачные объекты для текста: 19481, 19480, 19482, 19477")
            imgui.Text(u8"Маленькие объекты для текста: 19475, 19476, 2662")
            imgui.Text(u8"Бетонные блоки: 18766, 18765, 18764, 18763, 18762")
            imgui.Text(u8"Горы: вулкан 18752, песочница 18751, песочные горы ландшафт 19548")
            imgui.Text(u8"Платформы: тонкая платформа 19552, 19538, решетчатая 18753, 18754")
            imgui.Text(u8"Поверхности: 19531, 4242, 4247, 8171, 5004, 16685")
            imgui.Text(u8"Стены: 19353, 19426(маленькая), 19445(длинная), 19383(дверь), 19399(окно)")
            imgui.Text(u8"Окружение: темная материя 13656, скайбокс 3933, плейрум 3924")
            imgui.Text(u8"Покрытие: грязь 11385, растения 19790")
         elseif combobox.objects.v == 1 then
            imgui.Text(u8"Веревка 19087, Веревка длин. 19089")
            imgui.Text(u8"Стекло (Разрушаемое) 3858, стекло от травы 3261, сено 3374")
            imgui.Text(u8"Факел с черепом 3524, факел 3461,3525")
            imgui.Text(u8"Водяная бочка 1554, ржавая бочка 1217, взрыв. бочка 1225")
            imgui.Text(u8"Cтеклянный блок 18887, финиш гонки 18761, большой череп 8483, 6865")
            imgui.Text(u8"Вертушка на потолок 16780")
            imgui.Text(u8"Партикл воды с колизией 19603, большой 19604, мал. 9831, круглый 6964")
            imgui.Text(u8"Фонари(уличные): красный 3877, трицвета 3472, восточный 1568 и 3534")
         elseif combobox.objects.v == 2 then
            imgui.Text(u8"Огонь большой 18691, средний огонь 18692, пламя+дым (исчезает) 18723")
            imgui.Text(u8"Огонь от огнемета 18694, огонь от машины 18690")
            imgui.Text(u8"Пар от вентиляции 18736, дым от сигареты 18673, дым с фабрики 18748")
            imgui.Text(u8"Белый дым 18725, черный дым 18726, большой серый дым 18727")
            imgui.Text(u8"Большой взрыв 18682, средний взрыв 18683, маленький взрыв 18686")
            imgui.Text(u8"Спрей 18729, огнетушитель 18687, слезоточивый 18732")
            imgui.Text(u8"Рябь на воде 18741, брызги воды 18744")
            imgui.Text(u8"Фонтан 18739, гидрант 18740, водопад 19841, вода 19842")
            imgui.Text(u8"Искры 18717, горящие дрова 19632")
            imgui.Text(u8"Сигнальный огонь 18728, лазер 18643, нитро 18702, флейм 18693")
            imgui.Text(u8"Кровь от ранения 18668, лужа крови 19836")
         elseif combobox.objects.v == 3 then
            imgui.Text(u8"Неон красный 18647, синий 18648, зеленый 18649")
            imgui.Text(u8"Неон желтый 18650, розовый 18651, белый 18652")
            imgui.Text(u8"Свет.шар (не моргает) белый 19281, красн. 19282, зел. 19283, синий 19284")
            imgui.Text(u8"Свет.шар (моргает быстро) белый 19285, красн. 19286, зел. 19287, син. 19288")
            imgui.Text(u8"Свет.шар (моргает медленно) белый 19289, красн. 19290, зел. 19291, син. 19292")
            imgui.Text(u8"Свет.шар (моргает медленно) фиолетовый 19293, желтый 19294")
            imgui.Text(u8"Свет.шар (большой не моргает) бел. 19295, красн. 19296, зел. 19297, син. 19298")
         elseif combobox.objects.v == 4 then
            imgui.Text(u8"Попугай 19079, восточная лампа 3534, свечи: 2868,2869")
            imgui.Text(u8"Разбросанная одежда: 2843-2846, из борделя 14520-14521, 14863-14864")
            imgui.Text(u8"Вино: 19820-19824, две бутылки: 3119, стаканы 1667, 19818-19819, 1670")
            imgui.Text(u8"Сигареты: 19896, 19897, 3044, 1485, 1665")
            imgui.Text(u8"Книги: 2813, 2816, 2824, 2826, 2827, 2852-2855, стелаж 14455")
            imgui.Text(u8"Ковры: 2815, 2817, 2818, 2833-2836, 2841, 2842, 2847, 2631-2632")
            imgui.Text(u8"Чистая посуда: 2822, 2829, 2831, 2832, 2849, 2862-2865")
            imgui.Text(u8"Грязная посуда: 2812, 2820, 2830, 2848, 2850, 2851")
            imgui.Text(u8"Картины: 2255-2289, 3962-3964, 14860, 14812, 14737")
         elseif combobox.objects.v == 5 then
            imgui.Text(u8"Здесь вы можете сохранить ваши объекты в избранное")
            imgui.InputTextMultiline('##bufftext', textbuffer.note, imgui.ImVec2(480, 150))

            if imgui.Button(u8"Сохранить избранные в файл", imgui.ImVec2(200, 25)) then
               favfile = io.open(getGameDirectory() ..
               "//moonloader//resource//abseventhelper//objects.txt", "a")
               --favfile:write("\n")
               --favfile:write(string.format("%s \n", os.date("%d.%m.%y %H:%M:%S")))
               favfile:write(textbuffer.note.v)
               favfile:close()
               sampAddChatMessage("Saved moonloader/resource/abseventhelper/objects.txt", -1)
            end
         
            imgui.SameLine()
            if imgui.Button(u8"Загрузить избранные из файла", imgui.ImVec2(200, 25)) then
               favfile = io.open(getGameDirectory() ..
               "//moonloader//resource//abseventhelper//objects.txt", "r")
               textbuffer.note.v = favfile:read('*a')
               favfile:close()
            end
         elseif combobox.objects.v == 6 then
	        imgui.TextColoredRGB("Инструменты {007DFF}Prineside DevTools (Online)")
			imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Все запросы перенаправляет в ваш браузер")
		    imgui.Text(u8"Введите ключевое слово, ID или название модели:")
	        imgui.PushItemWidth(220)
	        if imgui.InputText("##CheckObject", textbuffer.objectid) then
            end
            imgui.PopItemWidth()
		 
		    imgui.SameLine()
	        if imgui.Button(u8"Найти",imgui.ImVec2(65, 25)) then
		       if string.len(textbuffer.objectid.v) > 3 then
                  local link = 'explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/search/?q='.. u8:decode(textbuffer.objectid.v)..'"'
		          os.execute(link)
		       end
	        end 
	  
	        if imgui.Button(u8"Найти объекты рядом по текущей позиции",imgui.ImVec2(300, 25)) then
		       if sampIsLocalPlayerSpawned() then
                  local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                  local link = string.format('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/mapsearch/?x=%i&y=%i', posX, posY)
		          os.execute(link)
		       end
	        end
		 
		    if lastObjectModelid then
		       if imgui.Button(u8"Вставить последний объект id: "..lastObjectModelid, imgui.ImVec2(300, 25)) then
	              textbuffer.objectid.v = tostring(lastObjectModelid)
		       end
	        end
         end
	
         imgui.Text(u8"______________________________________________________________________")
	     if isAbsolutePlay then
 	        imgui.TextColoredRGB("Описание работы редактора карт ")
            imgui.SameLine()
			imgui.Link("https://forum.gta-samp.ru/index.php?/topic/1016832-миры-описание-работы-редактора-карт/", "forum.gta-samp.ru")
         end
		 
         imgui.TextColoredRGB("Не нашли нужный объект? посмотрите на")
		 imgui.SameLine()
		 imgui.Link("https://dev.prineside.com/ru/gtasa_samp_model_id/", "dev.prineside.com")
               
         imgui.TextColoredRGB("Карта объектов которые не видны редакторами карт")
		 imgui.SameLine()
		 imgui.Link("https://map.romzes.com/", "map.romzes.com")
         
         imgui.TextColoredRGB("Список всех разрушаемых объектов на ")
         imgui.SameLine()
         imgui.Link("https://dev.prineside.com/ru/gtasa_samp_model_id/customsearch/?c%5B%5D=1&s=id-asc&bc=-1&bb=1&bt=-1&ba=-1", "dev.prineside.com/customsearch")
           
      elseif tabmenu.info == 6 then
		 imgui.Spacing()
         if imgui.CollapsingHeader(u8"Основные команды:") then
            imgui.TextColoredRGB("{00FF00}/abs{FFFFFF} - открыть главное меню хелпера")
            imgui.TextColoredRGB("{00FF00}/abs {FFFF00}slap{FFFFFF} - слапнуть себя")
            imgui.TextColoredRGB("{00FF00}/abs {FFFF00}jump{FFFFFF} - прыгнуть вперед")
            imgui.TextColoredRGB("{00FF00}/abs {FFFF00}cc{FFFFFF} - очистить себе чат")
            imgui.TextColoredRGB("{00FF00}/abs {FFFF00}render{FFFFFF} - показывать ид объектов (CTRL+O)")
            imgui.TextColoredRGB("{00FF00}/abs {FFFF00}recon{FFFFFF} - рекконект")
            imgui.TextColoredRGB("{00FF00}/abs {FFFF00}restream{FFFFFF} - рестрим")
         end
	     if imgui.CollapsingHeader(u8"Клиентские команды:") then
            imgui.TextColoredRGB("{00FF00}/headmove{FFFFFF} - вкл/выкл поворот головы скина по направлению камеры")
            imgui.TextColoredRGB("{00FF00}/timestamp{FFFFFF} - вкл/выкл показ времени в чате у каждого сообщения")
            imgui.TextColoredRGB("{00FF00}/pagesize [10-20]{FFFFFF} - устанавливает кол-во строк в чате")
			imgui.TextColoredRGB("{00FF00}/fontsize{FFFFFF} - изменение шрифта, его размера и толщины")
            imgui.TextColoredRGB("{00FF00}/save{FFFFFF} - сохраняет ваши координаты на карте в файл savedposition.txt")
			imgui.TextColoredRGB("{00FF00}/rs{FFFFFF} - сохраняет ваши координаты в rawposition.txt файл")
            imgui.TextColoredRGB("{00FF00}/fpslimit [20-90]{FFFFFF} - устанавливает максимальное кол-во FPS для вашего клиента")
            imgui.TextColoredRGB("{00FF00}/dl{FFFFFF} - вкл/выкл информацию о ближайшей машине в виде 3D текста")
            imgui.TextColoredRGB("{00FF00}/ctd{FFFFFF} - Позволяет включить клиентский дебаг цели, на которую направлена камера.")
            imgui.TextColoredRGB("{00FF00}/interior{FFFFFF} - выводит в чат ваш текущий интерьер")
            imgui.TextColoredRGB("{00FF00}/mem{FFFFFF} - отображает сколько использует памяти SA-MP")
            imgui.TextColoredRGB("{00FF00}/audiomsg{FFFFFF} - отключает сведения об URL песни(звука) в чате")
            imgui.TextColoredRGB("{00FF00}/nametagstatus{FFFFFF} - вкл/выкл показ песочных часов во время AFK.")
            imgui.TextColoredRGB("{00FF00}/hudscalefix{FFFFFF} - Исправляет размер HUD'a, ссылаясь на разрешение экрана клиента")
			imgui.TextColoredRGB("{00FF00}/quit (/q){FFFFFF} - вернуться в суровую реальность")
						
            --imgui.Text(u8"Оригинал темы на")
            --imgui.SameLine()
	        --imgui.Link("https://www.open.mp/ru/docs/client/ClientCommands", "open.mp")
		 end
         if imgui.CollapsingHeader(u8"Серверные команды:") then
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
            imgui.Spacing()
         end 
		 if imgui.CollapsingHeader(u8"Горячие клавиши:") then
		    imgui.TextColoredRGB("{00FF00}Клавиша N{FFFFFF} — меню редактора карт (в полете)")
            imgui.TextColoredRGB("{00FF00}Клавиша J{FFFFFF} — полет в наблюдении (/полет)")
            imgui.TextColoredRGB("{00FF00}Боковые клавиши мыши{FFFFFF} — отменяют и сохраняют редактирование объекта")
            imgui.TextColoredRGB("{FFFFFF}Используйте {00FF00}клавишу бега{FFFFFF}, для перемещения камеры вовремя редактирования")
            imgui.Spacing()
            imgui.TextColoredRGB("В режиме редактирования:")
            imgui.TextColoredRGB("{00FF00}Зажатие клавиши ALT{FFFFFF} — скрыть объект")
            imgui.TextColoredRGB("{00FF00}Зажатие клавиши CTRL{FFFFFF} — визуально увеличить объект")
            imgui.TextColoredRGB("{FF0000}Зажатие клавиши SHIFT{FFFFFF} — плавное перемещение объекта")
            imgui.TextColoredRGB("{00FF00}Клавиша Enter{FFFFFF}  — сохранить редактируемый объект")
            imgui.Spacing()
            imgui.TextColoredRGB("В режиме выделения:")
			imgui.TextColoredRGB("{00FF00}Клавиша RMB (Правая кл.мыши){FFFFFF}  — скопирует номер модели объекта")
            imgui.TextColoredRGB("{FF0000}Клавиша SHIFT{FFFFFF} — переключение между объектами")
			imgui.Spacing()
            imgui.TextColoredRGB("* {FF0000}Красным цветом{cdcdcd} обозначены функции доступные только с SAMP Addon")
		 end
		 
		 imgui.Spacing()
		 
		 imgui.TextColoredRGB("Команды SAMPFUNCS")
		 imgui.SameLine()
		 imgui.Link("https://wiki.blast.hk/sampfuncs/console", "https://wiki.blast.hk/sampfuncs/console")
         
		 imgui.TextColoredRGB("Команды RCON")
		 imgui.SameLine()
		 imgui.Link("https://www.open.mp/docs/server/ControllingServer", "https://www.open.mp/docs/")
         
		 if isAbsolutePlay then 
		    if isAbsfixInstalled then
			   imgui.TextColoredRGB("Стандартные горячие клавиши восстановлены")
			   imgui.SameLine()
			   imgui.Link("https://github.com/ins1x/useful-samp-stuff/tree/main/luascripts/absolutefix", "AbsoluteFix")
            else
			   imgui.TextColoredRGB("Чтобы восстановить все стандартные горячие клавиши установите")
			   imgui.SameLine()
			   imgui.Link("https://github.com/ins1x/useful-samp-stuff/tree/main/luascripts/absolutefix", "AbsoluteFix")
			end
		 end
		 
      elseif tabmenu.info == 7 then

	   imgui.Spacing()
	   imgui.Text(u8"Общее")
	   imgui.Spacing()
	   
	   if imgui.CollapsingHeader(u8'Что такое виртуальный мир?') then
          imgui.Text(u8"Виртуальный мир это функция которая позволяет отделить игрока от других игроков\nпоместив его в отдельный виртуальный экземпляр мира.\nПричем функция не просто делает игроков невидимыми, а вообще не обрабатывает\nтранспортные средства или другие объекты из других виртуальных миров.")
       end
	   
       if imgui.CollapsingHeader(u8'Что такое стример (streamer)?') then
          imgui.Text(u8"Это плагин который отображает объекты, пикапы, контрольные точки,\nзначки карт, 3D-текст и актеров с заданными пользователем тактами сервера.\n\n")
       end
	   
	   if imgui.CollapsingHeader(u8'Как исправить рябь на стыках?') then
          imgui.Text(u8"Рябь на стыках появляется в следствие наложения объектов.\nДля исправления нужно сместить объект чуть в сторону,\nлибо ниже (достаточно сдвинуть на 0.0001).\nМногие ошибочно считают что flickr устранит это мерцание — нет,\nплагин не решает проблему плохо сведенных между собой объектов")
       end
	   
	   if imgui.CollapsingHeader(u8'Как убрать засветы и тени?') then
          imgui.Text(u8"Их скрывают при помомщи Невидимых текстур.\nОдна из таких текстур - ID 19962 (Index 8955 в «Texture Studio»)\nДанная текстура очень полезна при сокрытии некоторых несовершенств\nдефолтных объектов GTA SA и при создании каких-либо новых объектов.")
       end
	   
	   if imgui.CollapsingHeader(u8'Как создается зеркальный пол?') then
	      imgui.Text(u8"В GTA есть стандартные интерьеры, в которых такой пол встречается.\nИ вокруг них есть небольшая зона, в которой есть зеркальное отражение.\nНазываются они cull zones.\nВ МapСonstructor возможно их все вывести на экран и чётко увидеть их границы\nТо есть, чтоб получить зеркальный пол, Вам нужно:\n- 1. Создать объект в области cull zone.\n- 2. Наложить на него текстуру и сделать её немного прозрачной.\n")
       end
	   
	   if imgui.CollapsingHeader(u8'Статические и динамические объекты в чем разница?') then
	      imgui.Text(u8"Чтобы понять разницу нужно немного углубиться в кодовую базу.\nВ SA:MP cтатический объект создается через функцию CreateObject,\nа динамический CreateDynamicObject.\nДинамические объекты начинают прорисовываться на определенном расстоянии\nзаданном в настройках стримера, а статические как указано в настройках сервера.\nМожно создать всего 1000 статических объектов!\nОсновные понятия:\n- Динамические объекты - это объекты, пикапы, иконки, 3D тексты\nзоны, чекпоинты в целом обрабатываемые стримером.\n- Динамические зоны - виртуальная зона, представляет собой\nтолько точки в пространстве объединенные в логическую зону.")
	   end
	   
	   if imgui.CollapsingHeader(u8'Как создать движущийся текст?') then
	      imgui.Text(u8"Создать объект 7313(vgsN_scrollsgn01) и наложить текст на него\nлибо использовать объект воды из водопада 19842(WaterFallWater1).")
	   end

       if imgui.CollapsingHeader(u8'Создание прозрачных/Невидимых объектов') then
	      imgui.Text(u8"Создаются через функцию SetObjectMaterial.\nУказываем имя библиотеки с текстурой и текстуры как 'none'.\nПараметр materialcolor устанавливаем в 0x00000000 (0).\nMaterialIndex - обозначает ID слоя материала объекта.\nИногда объекты имеют 2 и более различных типов текстур.\nЭто означает, что есть 2 и более слотов (слоёв) в индексах.\nВ таком случае необходимо указывать прозрачность каждому слою.")
	   end

	   imgui.Spacing()
        if isAbsolutePlay then
           imgui.Text(u8"Редактор карт на Absolute Play")
           imgui.Spacing()
	   
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
           
           imgui.Spacing()
           imgui.Text(u8"Ошибки и баги")
           imgui.Spacing()
           
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
		end 
      elseif tabmenu.info == 8 then
		 
	     imgui.Text(u8"Интерфейс взаимодействия с сайтом")
		 imgui.SameLine()
	     imgui.Link("https://forum.gta-samp.ru/index.php?/forum/23-absolute-dm-play/", "Absolute Play DM")	  
		 imgui.SameLine()
		 imgui.TextQuestion("( ? )", u8"Все действия редиректит в браузер")
		 
		 if imgui.Button(u8"Логи действий администрации",imgui.ImVec2(230, 25)) then
		    os.execute('explorer https://gta-samp.ru/adminhistory-deathmatch')
		 end
         imgui.SameLine()
		 if imgui.Button(u8"Логи смены никнеймов",imgui.ImVec2(230, 25)) then
		    os.execute('explorer https://gta-samp.ru/nickchange-deathmatch')
		 end 
		 
		 if imgui.Button(u8"История регистрации аккаунтов",imgui.ImVec2(230, 25)) then
		    os.execute('explorer https://gta-samp.ru/reg-deathmatch')
		 end
		 imgui.SameLine()
		 if imgui.Button(u8"Полный список правил",imgui.ImVec2(230, 25)) then
		    os.execute('explorer https://forum.sa-mp.ru/index.php?/topic/802952-%D0%BF%D1%80%D0%B0%D0%B2%D0%B8%D0%BB%D0%B0-dm-%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0/')
		 end
		 
		 if imgui.Button(u8"Администрация онлайн",imgui.ImVec2(230, 25)) then
		    sampSendChat("/admin")
			dialog.main.v = not dialog.main.v 
		 end
		 imgui.SameLine()
		 if imgui.Button(u8"Список администрации на сайте",imgui.ImVec2(230, 25)) then
		    os.execute('explorer "https://forum.gta-samp.ru/index.php?/topic/655150-%D1%81%D0%BF%D0%B8%D1%81%D0%BE%D0%BA-%D0%B0%D0%B4%D0%BC%D0%B8%D0%BD%D0%BE%D0%B2/"') 
		 end
		 
		 imgui.Text("")
		 imgui.Text(u8"Поиск в логе действий администрации по ключевому слову:")
		 imgui.PushItemWidth(385)
		 if imgui.InputText("##FindLogs", textbuffer.findlog) then
         end
		 imgui.PopItemWidth()
		 imgui.SameLine()
		 if imgui.Button(u8"Найти",imgui.ImVec2(70, 25)) then
     	    if string.len(textbuffer.findlog.v) > 0 then
               local link = string.format('explorer "https://gta-samp.ru/adminhistory-deathmatch?year=%i&month=%i&searchtext=%s"',
			   os.date('%Y'),os.date('%m'), u8:decode(textbuffer.findlog.v))
			   os.execute(link)
			   print(link)
			end
		 end
		 --imgui.Text(os.date('%H:%M:%S'))
		 
		 imgui.Text(u8"Узнать историю аккаунта:")
		 if chosenplayer then
            local nickname = sampGetPlayerNickname(chosenplayer)
            local ucolor = sampGetPlayerColor(chosenplayer)
            
			imgui.SameLine()
            imgui.Selectable(string.format(u8"Игрок в сети: %s[%d]", nickname, chosenplayer))
			if imgui.IsItemClicked() then
			   if not dialog.playerstat.v then dialog.playerstat.v = true end
			end
		 end
		 imgui.PushItemWidth(150)
		 if imgui.InputText("##CheckPlayer", textbuffer.ckeckplayer) then
		    for k, v in ipairs(getAllChars()) do
               local res, id = sampGetPlayerIdByCharHandle(v)
               if res then
                  local nickname = sampGetPlayerNickname(id)
                  if nickname == u8:decode(textbuffer.ckeckplayer.v) then
                     chosenplayer = sampGetPlayerIdByNickname(nickname)
				  end
			   end
            end
         end
		 imgui.PopItemWidth()
		 imgui.SameLine()
		 if imgui.Button(u8"по никнейму",imgui.ImVec2(150, 25)) then
			if string.len(textbuffer.ckeckplayer.v) > 0 then
               local link = 'explorer "https://gta-samp.ru/server-deathmatch?Nick='..u8:decode(textbuffer.ckeckplayer.v)..'"'
			   os.execute(link)
			end
		 end 
		 imgui.SameLine()
		 if imgui.Button(u8"по номеру аккаунта",imgui.ImVec2(150, 25)) then
			if string.len(textbuffer.ckeckplayer.v) > 0 and tonumber(textbuffer.ckeckplayer.v) then
               local link = 'explorer "https://gta-samp.ru/server-deathmatch?Accid='..u8:decode(textbuffer.ckeckplayer.v)..'"'
			   os.execute(link)
			end
		 end 
		 
		 imgui.Spacing()
		 imgui.Text(u8"Стандартные логи:")
		 
		 imgui.PushItemWidth(150)
		 imgui.Combo(u8'##ComboBoxLogslist', combobox.logs,
         {"moonloader.log", "modloader.log", "sampfuncs.log", "chatlog.txt", "cleo.log"})
		 
		 imgui.SameLine()
		 if imgui.Button(u8"показать",imgui.ImVec2(150, 25)) then
		    local file
			if combobox.logs.v == 0 then
		       file = getGameDirectory().. "\\moonloader\\moonloader.log"
			elseif combobox.logs.v == 1 then
			   file = getGameDirectory().. "\\modloader\\modloader.log"
			elseif combobox.logs.v == 2 then
			   file = getGameDirectory().. "\\SAMPFUNCS\\SAMPFUNCS.log"
			elseif combobox.logs.v == 3 then
			   file = getFolderPath(5)..'\\GTA San Andreas User Files\\SAMP\\chatlog.txt'
			elseif combobox.logs.v == 4 then
			   file = getGameDirectory().. "\\cleo.log"
			end
			
		    if doesFileExist(file) then
               os.execute('explorer '.. file)
			end
		 end
		
      end -- end tabmenu.info
		 
      imgui.NextColumn()

      if imgui.Button(u8"Объекты", imgui.ImVec2(100,25)) then tabmenu.info = 5 end
      if imgui.Button(u8"Лимиты", imgui.ImVec2(100,25)) then tabmenu.info = 2 end
      if imgui.Button(u8"Цвета", imgui.ImVec2(100,25)) then tabmenu.info = 3 end
      if imgui.Button(u8"Ретекстур", imgui.ImVec2(100,25)) then tabmenu.info = 4 end
      -- if imgui.Button(u8"Текстуры", imgui.ImVec2(100,25)) then 
	     -- dialog.textures.v = not dialog.textures.v
	  -- end
      if imgui.Button(u8"Команды", imgui.ImVec2(100,25)) then tabmenu.info = 6 end
      if imgui.Button(u8"FAQ", imgui.ImVec2(100,25)) then tabmenu.info = 7 end
      if isAbsolutePlay then
         if imgui.Button(u8"Админлог", imgui.ImVec2(100,25)) then tabmenu.info = 8 end
      end   
      if imgui.Button(u8"About", imgui.ImVec2(100, 25)) then tabmenu.info = 1 end

      imgui.Columns(1)

      end --end tabmenu.main
      imgui.EndChild()

      local ip, port = sampGetCurrentServerAddress()
      if not ip:find(ipAbsolutePlay) then
         if ip:find(ipTraining) then
            imgui.TextColoredRGB("{FF0000}Некоторые функции будут недоступны. Скрипт предназначен для Absolute Play")
         end
      end

      imgui.End()
   end
   
   -- Child dialogs
   if dialog.fastanswer.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 4, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Быстрые ответы", dialog.fastanswer)
       
      local nickname = sampGetPlayerNickname(chosenplayer)
      local ucolor = sampGetPlayerColor(chosenplayer)
          
      imgui.TextColoredRGB(string.format("Ответить игроку: {%0.6x} %s[%d]",
      bit.band(ucolor,0xffffff), nickname, chosenplayer))
         
      if imgui.Button(u8"Мир закрыт", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " мероприятие уже началось - мир закрыт")
      end
      if imgui.Button(u8"Пароль от мира", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " пароль от мира - 666 заходи")
      end
      if imgui.Button(u8"Перезайди в мир", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " перезайди в мир")
      end
      if imgui.Button(u8"Не мешай игрокам - кикну", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " не мешай игрокам  - кикну")
      end
      if imgui.Button(u8"Не мешай организаторам мп", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " не мешай организаторам мп")
      end
      if imgui.Button(u8"Займи свободный транспорт", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " займи свободный транспорт")
      end
      if imgui.Button(u8"Садись в машину", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " садись в машину")
      end
      if imgui.Button(u8"Разрешил телепорт и починку", imgui.ImVec2(250, 25)) then
         sampSendChat("/лс " .. chosenplayer .. " разрешил телепорт и починку")
      end
      imgui.End()
   end
   
   if dialog.playerstat.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.25, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Статистика игрока", dialog.playerstat)
	  
	  local nickname = sampGetPlayerNickname(chosenplayer)
      local ucolor = sampGetPlayerColor(chosenplayer)
      local health = sampGetPlayerHealth(chosenplayer)
      local armor = sampGetPlayerArmor(chosenplayer)
      local ping = sampGetPlayerPing(chosenplayer)
	  local weapon, ammo, skin
	  local	pX, pY, pZ, distance
	  local zone = nil
	  
	  for k, handle in ipairs(getAllChars()) do
         local res, id = sampGetPlayerIdByCharHandle(handle)
         if res then
            if id == chosenplayer then
				pX, pY, pZ = getCharCoordinates(handle)
				skinid = getCharModel(handle)
				weapon = getCurrentCharWeapon(handle)
				ammo = getAmmoInCharWeapon(handle, weapon)
				zone = getZoneName(pX, pY, pZ)
		    end
		 end
      end
	  
	  if sampIsPlayerPaused(chosenplayer) then
	     imgui.TextColoredRGB("{FF0000}[AFK]")
	     imgui.SameLine()
	  end
	  
      imgui.TextColoredRGB(string.format("Ник: {%0.6x}%s",
      bit.band(ucolor,0xffffff), nickname))
	  if imgui.IsItemClicked() then
	     setClipboardText(nickname)
         sampAddChatMessage("Ник скопирован в буфер обмена", -1)
	  end
	  imgui.SameLine()
	  imgui.Text(string.format("id: [%d]",chosenplayer))
      if imgui.IsItemClicked() then
	     setClipboardText(chosenplayer)
         sampAddChatMessage("ID скопирован в буфер обмена", -1)
	  end
	  
	  if health > 250.0 and isAbsolutePlay then
	     imgui.TextColoredRGB("{FF0000}Бессмертный")
	  else
	     imgui.TextColoredRGB(string.format("Хп: %.1f броня: %.1f", 
	     health, armor))
	  end
	  
	  if isAbsolutePlay then
         imgui.Text(u8"Уровень: ".. sampGetPlayerScore(chosenplayer))
	  else
	     imgui.Text(u8"Score: ".. sampGetPlayerScore(chosenplayer))
	  end
	  
	  if (ping > 90) then
         imgui.TextColoredRGB(string.format("Пинг: {FF0000}%i", ping))
      else
         imgui.TextColoredRGB(string.format("Пинг: %i", ping))
      end
	  
	  imgui.Text(u8("Скин: ".. skinid))
	  
	  if weapon == 0 then 
	     imgui.Text(u8"Нет оружия на руках")
	  else
	     if ammo then 
	        imgui.TextColoredRGB(string.format("Оружие в руках: %d (%d)", 
	        weapon, ammo))
	     end
	  end
	  
	  local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
	  distance = getDistanceBetweenCoords3d(posX, posY, posZ, pX, pY, pZ)
	  imgui.TextColoredRGB(string.format("Дистанция: %.1f m.", distance))
	  
	  if zone then 
	     imgui.Text(string.format(u8"Район: %s", zone))
	  end
	  
      if imgui.Button(u8"статистика", imgui.ImVec2(150, 25)) then
		 if isAbsolutePlay then
            sampSendChat("/стат " .. chosenplayer)
		 else
		    sampSendChat("/stats " .. chosenplayer)
		 end
		 dialog.main.v = false
      end
          
      if imgui.Button(u8"наблюдать", imgui.ImVec2(150, 25)) then
	     if isAbsolutePlay then
            sampSendChat("/набл " .. chosenplayer)
	     else
		    sampSendChat("/spec " .. chosenplayer)
		 end
      end
          
      if imgui.Button(u8"меню игрока", imgui.ImVec2(150, 25)) then
	     if isAbsolutePlay then
            sampSendChat("/и " .. chosenplayer)
		 end
		 dialog.main.v = false
      end
          
      if imgui.Button(u8"тп к игроку", imgui.ImVec2(150, 25)) then
         for k, v in ipairs(getAllChars()) do
            local res, id = sampGetPlayerIdByCharHandle(v)
            if res then
               if id == chosenplayer then
                  local pposX, pposY, pposZ = getCharCoordinates(v)
	        	  if isAbsolutePlay then
                     sampSendChat(string.format("/ngr %f %f %f",
			         pposX+0.5, pposY+0.5, pposZ), 0x0FFFFFF)
				  else
				     setCharCoordinates(PLAYER_PED, posX+0.5, posY+0.5, posZ)
				  end
                end
            else
               sampAddChatMessage("Доступно только в редакторе карт", 0x0FFFFFF)
            end
          end
       end
          
       if imgui.Button(u8"ответ", imgui.ImVec2(150, 25)) then
          dialog.fastanswer.v = not dialog.fastanswer.v
       end
	   
	  imgui.End()
   end

   if dialog.objectinfo.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 15, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Информация о объекте", dialog.objectinfo)
      
      if lastObject and doesObjectExist(lastObject) then
         imgui.TextColoredRGB("modelid: {3f70d6}".. lastObjectModelid)
         imgui.TextColoredRGB("id: {3f70d6}".. lastObjectId)
         if not lastObjectCoords.x ~= nil then
	        imgui.TextColoredRGB(string.format("{3f70d6}x: %.1f, {e0364e}y: %.1f, {26b85d}z: %.1f", lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z))
         end   
	     if not lastObjectCoords.rx ~= nil then
            imgui.TextColoredRGB(string.format("{4f70d6}rx: %.1f, {f0364e}ry: %.1f, {36b85d}rz: %.1f", lastObjectCoords.rx, lastObjectCoords.ry, lastObjectCoords.rz))
         end   
	     imgui.TextColoredRGB(string.format("angle: {3f70d6}%.1f", getObjectHeading(lastObject)))
	     --imgui.TextColoredRGB("объект "..(isObjectOnScreen(lastObject) and 'на экране' or 'не на экране'))
	     if not isObjectOnScreen(lastObject) then 
            imgui.TextColoredRGB("{ff0000}объект вне зоны прямой видимости")
         end
         if isAbsolutePlay and lastObjecttextureName ~= nil then
            for k, txdname in pairs(AbsTxdNames) do
               if txdname == lastObjecttextureName then
                  imgui.TextColoredRGB("texture internalid: {3f70d6}" .. k-1)
                  break
               end
            end
	        imgui.TextColoredRGB("txdname: {3f70d6}".. lastObjecttextureName .. " ("..lastObjectlibraryName..") ")
         end
         
         imgui.Spacing()  
         if imgui.TooltipButton(u8"Инфо по объекту (online)",imgui.ImVec2(200, 25), u8"Посмотреть подробную информацию по объекту на Prineside DevTools") then		    
            local link = 'explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/search/?q=' .. lastObjectModelid..'"'
		    os.execute(link)
	     end
         
         if imgui.Button(u8"В буффер обмена", imgui.ImVec2(200, 25)) then
            if not lastObjectCoords.rx ~= nil then
               setClipboardText(string.format("%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f", lastObjectModelid, lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z, lastObjectCoords.rx, lastObjectCoords.ry, lastObjectCoords.rz))
            else
               setClipboardText(string.format("%i, %.2f, %.2f, %.2f", lastObjectModelid, lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z))
            end
            sampAddChatMessage("Текcт скопирован в буфер обмена", -1)
	     end
         
         if imgui.Button(u8"Экспортировать", imgui.ImVec2(200, 25)) then
            if lastObjecttextureName ~= nil then
               if not lastObjectCoords.rx ~= nil then
                  sampAddChatMessage(string.format("tmpobjid = CreateObject(%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f);", lastObjectModelid, lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z, lastObjectCoords.rx, lastObjectCoords.ry, lastObjectCoords.rz), -1)
               else
                  sampAddChatMessage(string.format("tmpobjid = CreateObject(%i, %.2f, %.2f, %.2f);", lastObjectModelid, lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z), -1)
               end
               sampAddChatMessage(string.format('SetObjectMaterial(tmpobjid, 0, %i, %s, %s, 0xFFFFFFFF);', lastObjecttexturesrcID, lastObjectlibraryName, lastObjecttextureName), -1) 
            else 
               if not lastObjectCoords.rx ~= nil then
                  sampAddChatMessage(string.format("CreateObject(%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)", lastObjectModelid, lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z, lastObjectCoords.rx, lastObjectCoords.ry, lastObjectCoords.rz), -1)
               else
                  sampAddChatMessage(string.format("CreateObject(%i, %.2f, %.2f, %.2f)", lastObjectModelid, lastObjectCoords.x, lastObjectCoords.y, lastObjectCoords.z), -1)
               end
            end
	     end
         imgui.Spacing()   
      end
	  imgui.End()
   end
   
   if dialog.extendedtab.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 15, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Расширенные настройки", dialog.extendedtab)
	  	  
	  imgui.Checkbox(u8("Автоообновление списка игроков"), checkbox.autoupdplayerstable)
	  if checkbox.autoupdplayerstable.v then
	 	 playersTable = {}       
	 	 playersTotal = 0
	  
		for k, v in ipairs(getAllChars()) do
		   local res, id = sampGetPlayerIdByCharHandle(v)
		   if res then
		 	   table.insert(playersTable, id)
		 	   playersTotal = playersTotal + 1
		    end
	 	 end
	  end
	 
	  if imgui.Checkbox(u8("Уведомлять о дисконнекте игрока"), checkbox.disconnectreminder) then
	 	 if checkbox.disconnectreminder.v then
			sampAddChatMessage("При вылете игроков с сервера будет выводить уведомление", -1)
		 else
			sampAddChatMessage("Отключены уведомления о вылете игроков с сервера", -1)
		 end
	  end
	  
	  imgui.Checkbox(u8("Уведомлять о тяжелом оружии"), checkbox.heavyweaponwarn)
	  
	  if imgui.Button(u8"Получить id и ники игроков рядом", imgui.ImVec2(230, 25)) then
		 local pidtable = {}
		 local resulstring
		 for k, v in ipairs(getAllChars()) do
		    local res, id = sampGetPlayerIdByCharHandle(v)
		    if res then
			   local nickname = sampGetPlayerNickname(id)
			   table.insert(pidtable, string.format("%s[%d] ", nickname, id))
			   resulstring = table.concat(pidtable)
			   setClipboardText(resulstring)
			   sampAddChatMessage("Ид и ники игроков рядом скопированы в буфер обмена", -1)
		    end
		 end
	  end
	  
      if imgui.Button(u8"Последний кликнутый игрок в TAB", imgui.ImVec2(230, 25)) then
		 if tabselectedplayer ~= nil then
            setClipboardText(tabselectedplayer)
            sampAddChatMessage("id последнего кликнутого игрока в TAB скопирован в буфер обмена", -1)
         else
            sampAddChatMessage("Нет последнего кликнтуого игрока в TAB", -1)
         end
	  end
      
	  if imgui.Button(u8"Объявить победителей МП", imgui.ImVec2(230, 25)) then
		 local pidtable = {}
		 local resulstring
		 for k, v in ipairs(getAllChars()) do
		    local res, id = sampGetPlayerIdByCharHandle(v)
		    if res and v ~= playerPed then
			   local nickname = sampGetPlayerNickname(id)
			   table.insert(pidtable, string.format("%s[%d] ", nickname, id))
			   resulstring = table.concat(pidtable)
			   setClipboardText(resulstring)
			   sampSetChatInputEnabled(true)
			   sampSetChatInputText('* Победители МП " " '..resulstring..' .Поздравляем!')
			   sampAddChatMessage("Текст скопирован в строку чата", -1)
			   dialog.main.v = not dialog.main.v 
		    end
		 end
	  end
	  
	  if imgui.Button(u8"Игрок с наибольшим уровнем", imgui.ImVec2(230, 25)) then
		 local maxscore = {score = 0, id = 0}
		 local _, playerid = sampGetPlayerIdByCharHandle(playerPed)
		 for k, v in ipairs(getAllChars()) do
		    local res, id = sampGetPlayerIdByCharHandle(v)
			local score = sampGetPlayerScore(v)
		    if res and v ~= playerPed then
			   if score > maxscore.score then
			      maxscore.score = score
				  maxscore.id = id
			   end
		    end
		 end
		 if maxscore.score > 0 then
		    setClipboardText(sampGetPlayerNickname(maxscore.id).. "[" .. maxscore.id .. "]")--maxscore.id
		    sampAddChatMessage("Ид и ник игрока ".. sampGetPlayerNickname(maxscore.id) .." с наибольшим уровнем скопирован в буфер обмена", -1)
		 else
		    sampAddChatMessage("Нет других игроков рядом, кого выбирать?", -1)
		 end
	  end
	  
	  if imgui.Button(u8"Выбрать случайного игрока", imgui.ImVec2(230, 25)) then
	 	 if next(playersTable) == nil then -- if playersTable is empty
		    printStringNow("Update players table before", 1000) 
		    sampAddChatMessage("Сперва обнови список игроков!", -1) 
		 else
		    local rand = math.random(playersTotal)
		    chosenplayer = playersTable[rand]                
		    sampAddChatMessage("Случайный игрок: ".. sampGetPlayerNickname(playersTable[rand]), -1)
		 end
	  end
	  
	  if imgui.Button(u8"Вывести список лагеров", imgui.ImVec2(230, 25)) then
	     local counter = 0
		 if next(playersTable) == nil then -- if playersTable is empty
		    sampAddChatMessage("Сперва обнови список игроков!", -1) 
		 else
	        for k, v in pairs(playersTable) do
		       local ping = sampGetPlayerPing(v)
               local nickname = sampGetPlayerNickname(v)
			   if (ping > 70) then
			      counter = counter + 1
			      sampAddChatMessage(string.format("Лагер %s(%i) ping: %i", nickname, v, ping), 0xFF0000)
               end
		    end
		    if counter == 0 then
		       sampAddChatMessage("Лагеры не найдены", -1)
		    end
	     end
	  end
      
	  if imgui.Button(u8"Вывести список игроков AFK", imgui.ImVec2(230, 25)) then
	     local counter = 0
		 if next(playersTable) == nil then -- if playersTable is empty
		    sampAddChatMessage("Сперва обнови список игроков!", -1) 
		 else
	        for k, v in pairs(playersTable) do
               local nickname = sampGetPlayerNickname(v)
		       if sampIsPlayerPaused(v) then
			      counter = counter + 1
	              sampAddChatMessage(string.format("AFK %s(%i)", nickname, v), 0xFF0000)
	           end
		    end
		    if counter == 0 then
		       sampAddChatMessage("АФКашники не найдены", -1)
		    end
		 end
	  end
	  
	  if imgui.Button(u8"Статистика по игрокам в сети", imgui.ImVec2(230, 25)) then
	     local totalonline = 0
		 local olds = 0
		 local newbies = 0
         
	     for i = 0, sampGetMaxPlayerId(false) do
            if sampIsPlayerConnected(i) then 
			   totalonline = totalonline + 1
			   local score = sampGetPlayerScore(i)
			   if score > 100 then
			      olds = olds + 1
			   elseif score >= 3 and score <= 100 then 
			      newbies = newbies + 1
			   end
			end
         end
		 sampAddChatMessage("Игроков в сети "..totalonline.." из них новички "..newbies.." а "..olds.." постояльцы (боты: "..(totalonline-newbies-olds)..")", -1)
	  end
	  imgui.End()
   end
   
end

function sampev.onSetWeather(weatherId)
   if ini.settings.lockserverweather then
      forceWeatherNow(slider.weather.v)
   end
end

function sampev.onSetPlayerTime(hour, minute)
   if ini.settings.lockserverweather then
      setTimeOfDay(slider.time.v, 0)
   end
end

function sampev.onPlayerQuit(id, reason)
   if id == chosenplayer then chosenplayer = nil end
   local nick = sampGetPlayerNickname(id)
   
   if reason == 0 then reas = 'Выход'
   elseif reason == 1 then reas = 'Кик/бан'
   elseif reason == 2 then reas = 'Вышло время подключения'
   end
   
   if checkbox.disconnectreminder.v then
      for key, value in ipairs(playersTable) do
         if value == id then 
            sampAddChatMessage("Игрок " .. nick .. " вышел по причине: " .. reas, 0x00FF00)
            table.remove(playersTable, key)
         end
      end
   end
end

function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
   if checkbox.logdialogresponse.v then
      print(dialogId, button, listboxId, input)
   end
   
   if isAbsolutePlay then
      isTexturesListOpened = false
      -- if player wxit from world without command drop lastWorldNumber var 
      if dialogId == 1405 and listboxId == 5 and button == 1 then
         lastWorldNumber = 0
      end
       
	  -- Get current world number from server dialogs
	  if dialogId == 1426 and listboxId == 65535 and button == 1 then
         if tonumber(input) > 0 and tonumber(input) < 500 then
		    lastWorldNumber = tonumber(input)
	     end
      end
	  
	  if dialogId == 1406 and button == 1 then
	     local world = tonumber(string.sub(input, 0, 3))
	     if world then
		    lastWorldNumber = world
		 end
	  end
	  
      if dialogId == 1403 and listboxId == 2 and button == 1 then
         if lastObjecttextureName ~= nil then
            for k, txdname in pairs(AbsTxdNames) do
               if txdname == lastObjecttextureName then
                  sampAddChatMessage("Последняя использованная текстура: " .. k-1, 0xFF00FF00)
                  break
               end
            end
         end
      end
      
      if dialogId == 1400 and listboxId == 4 and button == 1 then
         if lastObjecttextureName ~= nil then
            for k, txdname in pairs(AbsTxdNames) do
               if txdname == lastObjecttextureName then
                  sampAddChatMessage("Последняя использованная текстура: " .. k-1, 0xFF00FF00)
                  break
               end
            end
         end
      end
      
      if dialogId == 1400 and listboxId == 4 and button == 1 then
         isTexturesListOpened = true
      end
      if dialogId == 1403 and listboxId == 2 and button == 1 then
         isTexturesListOpened = true
      end
      
	  if dialogId == 1429 and button == 1 then
		 local startpos = input:find("№")
		 local endpos = startpos + 3
		 local world = tonumber(string.sub(input, startpos+1, endpos))
		 print(world, startpos, endpos)
	     if world then
		    lastWorldNumber = world
		 end
	  end
      
	  if dialogId == 1412 and listboxId == 2 and button == 1 then
	     sampAddChatMessage("Вы изменили разрешение на редактирование мира для всех игроков!", 0xFF0000)
	  end
	  
	  -- if dialogId == 1403 or dialogId == 1411 and button == 1 then
	     -- if lastObjectModelid then 
		    -- lastRemovedObjectModelid = lastObjectModelid
			-- lastRemovedObjectCoords.x = lastObjectCoords.x
			-- lastRemovedObjectCoords.y = lastObjectCoords.y
			-- lastRemovedObjectCoords.z = lastObjectCoords.z
		 -- end
	  -- end
	  
	  -- if dialogId == 1401 and button == 1 then
	     -- if undoMode then
		    -- if lastObject and doesObjectExist(lastObject) then
		       -- setObjectCoordinates(lastObject, lastRemovedObjectCoords.x, lastRemovedObjectCoords.y, lastRemovedObjectCoords.z)
			-- end
		 -- end
	  -- end

   end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
   if isAbsolutePlay then
      -- save random color from text editing dialog to clipboard
      -- moved to absolutefix
      -- if dialogId == 1496 then
         -- local randomcolor = string.sub(text, string.len(text)-6, #text-1)
		 -- printStringNow("color "..randomcolor.." copied to clipboard",1000)
	     -- setClipboardText(randomcolor)
      -- end
      
      if dialogId == 1407 then
         return {dialogId, style, title, button1, button2, text.."\nПодробнее на https://forum.sa-mp.ru/index.php?/topic/1016828-миры-редактор-карт-faq"}
      end
      
      if dialogId == 1401 then
         local newtext = 
         "615-18300   GTA-SA \n"..
         "18632-19521 SA-MP\n"..
         "19477-19482 Text \n\n"..
         "Номера объектов можно найти на сайте:\n"..
         "https://dev.prineside.com/ru/gtasa_samp_model_id/\n"..
         "\nВведи номер объекта: \n"
         return {dialogId, style, title, button1, button2, newtext}
      end
   end
   
   -- TRAINING Skip rules dialog
   if dialogId == 32700 and style == 0 and button1 == "Принимаю" then
      sampSendDialogResponse(32700, 1, nil)
      sampCloseCurrentDialogWithButton(1)
   end
   
   if checkbox.logdialogresponse.v then
      print(dialogId, style, title, button1, button2, text)
   end
end

function sampev.onServerMessage(color, text)  
   -- Some functions are prohibited on Arizona (Autounload)
   if text:find('Добро пожаловать на Arizona Role Play!') then
      thisScript():unload()
   end
   
   if text:find("У тебя нет прав") then
      if prepareJump then 
         JumpForward()
         prepareJump = false
      end
      if prepareTeleport then sampAddChatMessage("В мире телепортация отключена", 0x00FF00) end
      return false
   end
   
   if text:find("Последнего созданного объекта не существует") then
      if lastObjectModelid then
         sampAddChatMessage("Последний использованный объект: "..lastObjectModelid, 0x00FF00)
	  end
   end
   
   if text:find("Управляющим мира смертельный урон не наносится") then
      sampAddChatMessage("N - Оружие - Отключить сужающуюся зону урона", -1)
   end
   
   if text:find("Установи 0.3DL чтобы включать полёт в этом месте") then
      sampAddChatMessage("Необходимо уходить в полет с другой точки где мало объектов рядом (выйти из зоны стрима)", 0x00FF00)
   end
   
   if text:find("Ты уже находишься в редакторе миров") then
      sampSendChat("/exit")
   end
   
   if text:find("В этой области создано слишком много объектов") then
      sampAddChatMessage("Вы создали много объектов в одной области.", 0x00FF00)
      sampAddChatMessage("В радиусе 150 метров нельзя создавать больше 200 объектов.", 0x00FF00)
      return false
   end
   
   if text:find("Это не твой мир, редактировать его ты не можешь") then
      return false
   end
end

function sampev.onSendCommand(command)
   if command:find('(.+) (.+)') then
      local cmd, arg = command:match('(.+) (.+)')
      
	  -- Get world id (not virtual world id)
	  if cmd:find("vbh") or cmd:find("мир") then
	     local id = tonumber(arg)
		 if id then 
		    if id > 0 and id <= 500 then 
		       lastWorldNumber = id
			end
	     end
	  end
	  
      if cmd:find("vfibye2") or cmd:find("машину2") then 
         isTexturesListOpened = false
      end
      
	  if cmd:find("ds[jl") or cmd:find("exit") or cmd:find("выход") then
		 lastWorldNumber = 0
	  end
   end
   
   -- if command:find("@tab") then
      -- if tabselectedplayer ~= nil then
         -- command.gsub(command, "@tab", tabselectedplayer)
      -- end
   -- end
end

function onExitScript()
	if nameTagWh then
	   nameTagWh = false
	   nameTagOn()
	end
	if not sampIsDialogActive() then
	   showCursor(false)
	end
	setCameraDistanceActivated(0)
	setCameraDistance(0)
	patch_samp_time_set(false)
end

function sampev.onScriptTerminate(script, quitGame)
    if script == thisScript() then
       sampAddChatMessage("Скрипт AbsEventHelper аварийно завершил свою работу. Для перезагрузки нажмите CTRL + R.", -1)
    end
end

function sampev.onCreateObject(objectId, data)
   if not AbsoluteFix then
      -- Fix Crash the game when creating a crane object 1382
      if data.modelId == 1382 then return false end
   end
   
   -- Hide objects from hiddenObjects list
   if hiddenObjects[1] ~= nil then
      for i = 1, #hiddenObjects do
          if data.modelId == hiddenObjects[i] then return false end
      end
   end
   
end

function sampev.onSetObjectMaterial(id, data)
   if id == lastObjectId then 
      lastObjectlibraryName = data.libraryName
      lastObjecttextureName = data.textureName
      lastObjecttexturesrcID = data.modelId
   end
   if checkbox.logtxd.v then
      print(id, data.materialId, data.modelId, data.libraryName, data.textureName, data.color)
   end
end

function sampev.onSendEditObject(playerObject, objectId, response, position, rotation)
   local object = sampGetObjectHandleBySampId(objectId)
   local modelId = getObjectModel(object)
   lastObject = object
   lastObjectId = objectId
   lastObjectModelid = modelId
   lastObjectCoords.x = position.x
   lastObjectCoords.y = position.y
   lastObjectCoords.z = position.z
   lastObjectCoords.rx = rotation.x
   lastObjectCoords.ry = rotation.y
   lastObjectCoords.rz = rotation.z
   
   currentEditmode = response
   
   if checkbox.showobjectrot.v then
      printStringNow(string.format("x:~b~~h~%0.2f, ~w~y:~r~~h~%0.2f, ~w~z:~g~~h~%0.2f~n~ ~w~rx:~b~~h~%0.2f, ~w~ry:~r~~h~%0.2f, ~w~rz:~g~~h~%0.2f",
	  position.x, position.y, position.z, rotation.x, rotation.y, rotation.z), 1000)
   end
   
   if response > 0 then
      if hideEditObject then
	     setObjectVisible(object, false)
      else
	     setObjectVisible(object, true)
	  end
	  
	  if scaleEditObject then
	     setObjectScale(object, 1.35)
	  else
	     setObjectScale(object, 1.0)
	  end
   else 
      setObjectVisible(object, true)
	  setObjectScale(object, 1.0)
   end
end

function sampev.onSendEnterEditObject(type, objectId, model, position)
   local object = sampGetObjectHandleBySampId(objectId)
   local modelId = getObjectModel(object)
   lastObject = object
   lastObjectId = objectId
   lastObjectModelid = modelId
   lastObjectCoords.x = position.x
   lastObjectCoords.y = position.y
   lastObjectCoords.z = position.z
   
   if model == 3586 or model == 3743 then
      sampAddChatMessage("Объект "..model.." пропадет только после релога (баг SAMP)", 0x0FF0000)
   end
   if model == 8979 or model == 8980 then
      sampAddChatMessage("Объект "..model.." пропадет только после релога (баг SAMP)", 0x0FF0000)
   end
   if model == 1269 or model == 1270 then 
      sampAddChatMessage("Из объекта "..model.." визуально выпадают деньги как в оригинальной игре (баг SAMP)", 0x0FF0000)
   end
   if model == 16637 then
      sampAddChatMessage("Создание/удаление объекта "..model.." может привести к крашу 0x0044A503 (баг SAMP)", 0x0FF0000)
   end
   if model == 3426 then
      sampAddChatMessage("Этот объект "..model.." неккоректно отображается под поверхностью, в воде, либо при повороте (баг SAMP)", 0x0FF0000)
   end
   
   if checkbox.logobjects.v then
      print(type, objectId, model)
   end
end

function sampev.onPlayerStreamIn(id, team, model, position, rotation, color, fight)
   if checkbox.radarblips.v then
	  local ucolor = sampGetPlayerColor(id)
	  local aa, rr, gg, bb = explode_argb(ucolor)
      newcolor = join_argb(0, rr, gg, bb)
	  return {id, team, model, position, rotation, newcolor, fight}
   end
end

function sampev.onCreate3DText(id, color, position, distance, testLOS,
attachedPlayerId, attachedVehicleId, text)
   if hide3dtexts then 
      return {id, color, position, 0.5, testLOS, attachedPlayerId, attachedVehicleId, text}
   else
      return {id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text}
   end
end

function sampev.onTogglePlayerSpectating(state)
   isPlayerSpectating = state
end

function sampev.onSendClickPlayer(playerId, source)
   tabselectedplayer = playerId
end

function sampev.onShowTextDraw(id, data)
   if isAbsolutePlay and isTexturesListOpened then
      if id >= 2053 and id <= 2100 then
         local index = tonumber(data.text)
         if index ~= nil then
            local txdlabel = data.text.."~n~~n~"..tostring(AbsTxdNames[index+1])
            data.text = txdlabel
            data.letterWidth = 0.12
            data.letterHeight = 0.7
            return{id, data}    
         end
      end
   end
   
   if checkbox.hidealltextdraws.v then
      return false
   end
end

function sampev.onSendClickTextDraw(textdrawId)
   if checkbox.logtextdraws.v then
      local posX, posY = sampTextdrawGetPos(textdrawId)
      sampfuncsLog(("Textdraw ID: %s, Model: %s, x : %s, y: %s,"):format(textdrawId, sampTextdrawGetModelRotationZoomVehColor(textdrawId), posX, posY))
   end
   -- if textdrawId >= 2053 and textdrawId <= 2099 then
      -- local model, rotX, rotY, rotZ, zoom, clr1, clr2 = sampTextdrawGetModelRotationZoomVehColor(textdrawId)
      -- sampTextdrawSetModelRotationZoomVehColor(textdrawId, model, rotX, rotY, rotZ+90.0, zoom, clr1, clr2)
   -- end   
end

function sampev.onSendPickedUpPickup(id)
   if checkbox.pickeduppickups.v then
	  sampfuncsLog('Pickup: ' .. id)
   end
end

function sampev.onRemoveBuilding(modelId, position, radius)
   removedBuildings = removedBuildings + 1;
end

function sampev.onSetPlayerHealth(health)
   if checkbox.nophealth.v then
	  return false
   end
end

-- END hooks

-- Macros
function direction()
   if sampIsLocalPlayerSpawned() then
      local angle = math.ceil(getCharHeading(PLAYER_PED))
      if angle then
         if (angle >= 0 and angle <= 30) or (angle <= 360 and angle >= 330) then
            return u8"Север"
         elseif (angle > 80 and angle < 100) then
            return u8"Запад"
         elseif (angle > 260 and angle < 280) then
            return u8"Восток"
         elseif (angle >= 170 and angle <= 190) then
            return u8"Юг"
         elseif (angle >= 31 and angle <= 79) then
            return u8"Северо-запад"
         elseif (angle >= 191 and angle <= 259) then
            return u8"Юго-восток"
         elseif (angle >= 81 and angle <= 169) then
            return u8"Юго-запад"
         elseif (angle >= 259 and angle <= 329) then
            return u8"Северо-восток"
         else
            return angle
         end
      else
         return u8"Неизвестно"
      end
   else
      return u8"Неизвестно"
   end
end

function JumpForward()
   if sampIsLocalPlayerSpawned() then
      local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
      local angle = math.ceil(getCharHeading(PLAYER_PED))
      local dist = 2.0
      if angle then
         if (angle >= 0 and angle <= 30 or (angle <= 360 and angle >= 330)) then
            setCharCoordinates(PLAYER_PED, posX, posY+dist, posZ)
         elseif (angle > 80 and angle < 100) then
            setCharCoordinates(PLAYER_PED, posX-dist, posY+dist, posZ)
         elseif (angle > 260 and angle < 280) then
            setCharCoordinates(PLAYER_PED, posX+dist, posY, posZ)
         elseif (angle >= 170 and angle <= 190) then
            setCharCoordinates(PLAYER_PED, posX-dist, posY-dist, posZ)
         elseif (angle >= 31 and angle <= 79) then
            setCharCoordinates(PLAYER_PED, posX, posY-dist, posZ) 
         elseif (angle >= 191 and angle <= 259) then
            setCharCoordinates(PLAYER_PED, posX+dist, posY-dist, posZ)
         elseif (angle >= 81 and angle <= 169) then
            setCharCoordinates(PLAYER_PED, posX-dist, posY, posZ)
         elseif (angle >= 259 and angle <= 329) then
            setCharCoordinates(PLAYER_PED, posX+dist, posY+dist, posZ)
         end
      end
   end
end

function getClosestPlayerId()
    local closestId = -1
    mydist = 30
    local x, y, z = getCharCoordinates(PLAYER_PED)
    for i = 0, 999 do
        local streamed, pedID = sampGetCharHandleBySampPlayerId(i)
        if streamed and getCharHealth(pedID) > 0 and not sampIsPlayerPaused(pedID) then
            local xi, yi, zi = getCharCoordinates(pedID)
            local dist = getDistanceBetweenCoords3d(x, y, z, xi, yi, zi)
            if dist <= mydist then
                mydist = dist
                closestId = i
            end
        end
    end
    return closestId
end

function getClosestCar()
   -- return 2 values: car handle and car id
   local minDist = 9999
   local closestId = -1
   local closestHandle = false
   local x, y, z = getCharCoordinates(PLAYER_PED)
   for i, k in ipairs(getAllVehicles()) do
      local streamed, carId = sampGetVehicleIdByCarHandle(k)
      if streamed then
         local xi, yi, zi = getCarCoordinates(k)
         local dist = math.sqrt( (xi - x) ^ 2 + (yi - y) ^ 2 + (zi - z) ^ 2 )
         if dist < minDist then
            minDist = dist
            closestId = carId
            closestHandle = k
         end
      end
   end
   return closestHandle, closestId
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

function GetNearestObject(modelid)
    local objects = {}
    local x, y, z = getCharCoordinates(playerPed)
    for i, obj in ipairs(getAllObjects()) do
        if getObjectModel(obj) == modelid then
            local result, ox, oy, oz = getObjectCoordinates(obj)
            table.insert(objects, {getDistanceBetweenCoords3d(ox, oy, oz, x, y, z), ox, oy, oz})
        end
    end
    if #objects <= 0 then return false end
    table.sort(objects, function(a, b) return a[1] < b[1] end)
    return true, unpack(objects[1])
end

function getNearestRoadCoordinates(radius)
    local A = { getCharCoordinates(PLAYER_PED) }
    local B = { getClosestStraightRoad(A[1], A[2], A[3], 0, radius or 600) }
    if B[1] ~= 0 and B[2] ~= 0 and B[3] ~= 0 then
        return true, B[1], B[2], B[3]
    end
    return false
end

function setCameraDistanceActivated(activated) --KepchiK
	memory.setuint8(0xB6F028 + 0x38, activated)
	memory.setuint8(0xB6F028 + 0x39, activated)
end

function setCameraDistance(distance) -- KepchiK
	memory.setfloat(0xB6F028 + 0xD4, distance)
	memory.setfloat(0xB6F028 + 0xD8, distance)
	memory.setfloat(0xB6F028 + 0xC0, distance)
	memory.setfloat(0xB6F028 + 0xC4, distance)
end

function ClearChat()
   memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
   memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
   memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
end

function Recon()
   lua_thread.create(function()
   sampDisconnectWithReason(quit)
   wait(5000)
   local ip, port = sampGetCurrentServerAddress()
   sampConnectToServer(ip, port) 
   end)
end

function Restream()
   lua_thread.create(function()
   sampAddChatMessage('Начинается процесс рестрима', -1)
   tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(PLAYER_PED)
   if isAbsolutePlay then
      sampSendChat(string.format("/ngr %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z+1000.0), 0x0FFFFFF)
   else
      setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z+1000.0)
   end
   wait(5000)
   if isAbsolutePlay then
      sampSendChat(string.format("/ngr %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
   else
      setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z)
   end
   sampAddChatMessage('рестрим завершен', -1)
   end)
end

function enableDialog(bool)
   memory.setint32(sampGetDialogInfoPtr()+40, bool and 1 or 0, true)
   sampToggleCursor(bool)
end

function sampGetPlayerIdByNickname(nick)
    local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(id) then return id end
    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then return i end
    end
end

function doesFileExist(path)
   local f=io.open(path,"r")
   if f~=nil then io.close(f) return true else return false end
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

function explode_argb(argb)
   local a = bit.band(bit.rshift(argb, 24), 0xFF)
   local r = bit.band(bit.rshift(argb, 16), 0xFF)
   local g = bit.band(bit.rshift(argb, 8), 0xFF)
   local b = bit.band(argb, 0xFF)
   return a, r, g, b
end
	
function intToHex(int)
    return '{'..string.sub(bit.tohex(int), 3, 8)..'}'
end


function cleanBindsForm()
   textbuffer.bind1.v = " "
   textbuffer.bind2.v = " "
   textbuffer.bind3.v = " "
   textbuffer.bind4.v = " "
   textbuffer.bind5.v = " "
   textbuffer.bind6.v = " "
   textbuffer.bind7.v = " "
   textbuffer.bind8.v = " "
   textbuffer.bind9.v = " "
   textbuffer.bind10.v = " "
   textbuffer.bindad.v = " "
end

function reloadBindsFromConfig()
   textbuffer.bind1.v = u8(ini.binds.textbuffer1)
   textbuffer.bind2.v = u8(ini.binds.textbuffer2)
   textbuffer.bind3.v = u8(ini.binds.textbuffer3)
   textbuffer.bind4.v = u8(ini.binds.textbuffer4)
   textbuffer.bind5.v = u8(ini.binds.textbuffer5)
   textbuffer.bind6.v = u8(ini.binds.textbuffer6)
   textbuffer.bind7.v = u8(ini.binds.textbuffer7)
   textbuffer.bind8.v = u8(ini.binds.textbuffer8)
   textbuffer.bind9.v = u8(ini.binds.textbuffer9)
   textbuffer.bind10.v = u8(ini.binds.textbuffer10)
   textbuffer.bindad.v = u8(ini.binds.adtextbuffer)
end

function nameTagOn()
    local pStSet = sampGetServerSettingsPtr();
    NTdist = memory.getfloat(pStSet + 39)
    NTwalls = memory.getint8(pStSet + 47)
    NTshow = memory.getint8(pStSet + 56)
	if nameTagWh then
		memory.setfloat(pStSet + 39, 1488.0)
		memory.setint8(pStSet + 47, 0)
	else 
		memory.setfloat(pStSet + 39, 70.0)
	end
    memory.setint8(pStSet + 56, 1)
    nameTag = true
end

function nameTagOff()
    local pStSet = sampGetServerSettingsPtr();
    memory.setfloat(pStSet + 39, NTdist)
    memory.setint8(pStSet + 47, NTwalls)
    memory.setint8(pStSet + 56, NTshow)
    nameTag = false
end

function patch_samp_time_set(enable) -- by hnnssy and FYP
    if enable and default == nil then
        default = readMemory(sampGetBase() + 0x9C0A0, 4, true)
        writeMemory(sampGetBase() + 0x9C0A0, 4, 0x000008C2, true)
    elseif enable == false and default ~= nil then
        writeMemory(sampGetBase() + 0x9C0A0, 4, default, true)
        default = nil
    end
end

function setTime(time)
    patch_samp_time_set(false)
    memory.write(0xB70153, time, 1, false)
    patch_samp_time_set(true)
end

function setWeather(weatherId)
    memory.write(0xC81320, weatherId, 2, false)
end

-- https://www.blast.hk/threads/13380/post-1110222
function getMDO(id_obj) -- by Gorskin 
   -- print(memory.getfloat(getMDO(objectid), true))
   local mem_obj = callFunction(4210080, 1, 1, id_obj)
   return mem_obj + 24
end

-- https://www.blast.hk/threads/13380/post-376878
-- ampRegisterChatCommand("editobject", function(param)  editObjectBySampId(tonumber(param), false)
-- function editObjectBySampId(id, playerobj) 
   -- if isSampAvailable() then
   -- local ffi = require("ffi")
      -- ffi.cast("void (__thiscall*)(unsigned long, short int, unsigned long)", sampGetBase() + 0x6DE40)(readMemory(sampGetBase() + 0x21A0C4, 4), id, playerobj and 1 or 0)
   -- end
-- end

-- imgui fuctions
function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

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

function imgui.TooltipButton(label, size, description)
   local result = imgui.Button(label, size, description)
   if imgui.IsItemHovered() then
      imgui.BeginTooltip()
      imgui.PushTextWrapPos(600)
      imgui.TextUnformatted(description)
      imgui.PopTextWrapPos()
      imgui.EndTooltip()
   end
   return result
end

function imgui.Link(link, text)
   text = text or link
   local tSize = imgui.CalcTextSize(text)
   local p = imgui.GetCursorScreenPos()
   local DL = imgui.GetWindowDrawList()
   local col = { 0xFFFF7700, 0xFFFF9900 }
   if imgui.InvisibleButton("##" .. link, tSize) then os.execute('explorer "' .. link ..'"');print(link) end
   local color = imgui.IsItemHovered() and col[1] or col[2]
   DL:AddText(p, color, text)
   DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)
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

function getZoneName(x, y, z)
    -- modified code snippet by ШPEK
    local streets = {{"Avispa Country Club", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
    {"Easter Bay Airport", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
    {"Avispa Country Club", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
    {"Easter Bay Airport", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
    {"Garcia", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
    {"Shady Cabin", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
    {"East Los Santos", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
    {"LVA Freight Depot", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
    {"Blackfield Intersection", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
    {"Avispa Country Club", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
    {"Temple", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
    {"Unity Station", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
    {"LVA Freight Depot", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
    {"Los Flores", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
    {"Starfish Casino", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
    {"Easter Bay Chemicals", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
    {"Downtown Los Santos", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
    {"Esplanade East", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
    {"Market Station", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
    {"Linden Station", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
    {"Montgomery Intersection", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
    {"Frederick Bridge", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
    {"Yellow Bell Station", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
    {"Downtown Los Santos", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
    {"Jefferson", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
    {"Mulholland", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
    {"Avispa Country Club", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
    {"Jefferson", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
    {"Julius Thruway West", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
    {"Jefferson", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
    {"Julius Thruway North", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
    {"Rodeo", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
    {"Cranberry Station", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
    {"Downtown Los Santos", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
    {"Redsands West", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
    {"Little Mexico", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
    {"Blackfield Intersection", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
    {"Los Santos International", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
    {"Beacon Hill", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
    {"Rodeo", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
    {"Richman", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
    {"Downtown Los Santos", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
    {"The Strip", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
    {"Downtown Los Santos", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
    {"Blackfield Intersection", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
    {"Conference Center", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
    {"Montgomery", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
    {"Foster Valley", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
    {"Blackfield Chapel", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
    {"Los Santos International", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
    {"Mulholland", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
    {"Yellow Bell Gol Course", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
    {"The Strip", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
    {"Jefferson", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
    {"Mulholland", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
    {"Aldea Malvada", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
    {"Las Colinas", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
    {"Las Colinas", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
    {"Richman", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
    {"LVA Freight Depot", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
    {"Julius Thruway North", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
    {"Willowfield", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
    {"Julius Thruway North", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
    {"Temple", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
    {"Little Mexico", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
    {"Queens", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
    {"Las Venturas Airport", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
    {"Richman", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
    {"Temple", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
    {"East Los Santos", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
    {"Julius Thruway East", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
    {"Willowfield", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
    {"Las Colinas", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
    {"Julius Thruway East", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
    {"Rodeo", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
    {"Las Brujas", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
    {"Julius Thruway East", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
    {"Rodeo", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
    {"Vinewood", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
    {"Rodeo", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
    {"Julius Thruway North", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
    {"Downtown Los Santos", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
    {"Rodeo", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
    {"Jefferson", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
    {"Hampton Barns", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
    {"Temple", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
    {"Kincaid Bridge", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
    {"Verona Beach", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
    {"Commerce", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
    {"Mulholland", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
    {"Rodeo", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
    {"Mulholland", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
    {"Mulholland", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
    {"Julius Thruway South", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
    {"Idlewood", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
    {"Ocean Docks", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
    {"Commerce", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
    {"Julius Thruway North", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
    {"Temple", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
    {"Glen Park", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
    {"Easter Bay Airport", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
    {"Martin Bridge", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
    {"The Strip", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
    {"Willowfield", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
    {"Marina", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
    {"Las Venturas Airport", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
    {"Idlewood", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
    {"Esplanade East", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
    {"Downtown Los Santos", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
    {"The Mako Span", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
    {"Rodeo", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
    {"Pershing Square", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
    {"Mulholland", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
    {"Gant Bridge", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
    {"Las Colinas", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
    {"Mulholland", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
    {"Julius Thruway North", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
    {"Commerce", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
    {"Rodeo", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
    {"Roca Escalante", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
    {"Rodeo", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
    {"Market", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
    {"Las Colinas", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
    {"Mulholland", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
    {"King's", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
    {"Redsands East", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
    {"Downtown", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
    {"Conference Center", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
    {"Richman", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
    {"Ocean Flats", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
    {"Greenglass College", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
    {"Glen Park", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
    {"LVA Freight Depot", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
    {"Regular Tom", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
    {"Verona Beach", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
    {"East Los Santos", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
    {"Caligula's Palace", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
    {"Idlewood", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
    {"Pilgrim", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
    {"Idlewood", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
    {"Queens", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
    {"Downtown", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
    {"Commerce", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
    {"East Los Santos", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
    {"Marina", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
    {"Richman", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
    {"Vinewood", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
    {"East Los Santos", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
    {"Rodeo", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
    {"Easter Tunnel", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
    {"Rodeo", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
    {"Redsands East", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
    {"The Clown's Pocket", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
    {"Idlewood", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
    {"Montgomery Intersection", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
    {"Willowfield", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
    {"Temple", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
    {"Prickle Pine", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
    {"Los Santos International", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
    {"Garver Bridge", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
    {"Garver Bridge", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
    {"Kincaid Bridge", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
    {"Kincaid Bridge", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
    {"Verona Beach", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
    {"Verdant Bluffs", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
    {"Vinewood", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
    {"Vinewood", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
    {"Commerce", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
    {"Market", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
    {"Rockshore West", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
    {"Julius Thruway North", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
    {"East Beach", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
    {"Fallow Bridge", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
    {"Willowfield", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
    {"Chinatown", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
    {"El Castillo del Diablo", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
    {"Ocean Docks", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
    {"Easter Bay Chemicals", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
    {"The Visage", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
    {"Ocean Flats", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
    {"Richman", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
    {"Green Palms", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
    {"Richman", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
    {"Starfish Casino", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
    {"East Beach", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
    {"Jefferson", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
    {"Downtown Los Santos", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
    {"Downtown Los Santos", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
    {"Garver Bridge", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
    {"Julius Thruway South", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
    {"East Los Santos", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
    {"Greenglass College", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
    {"Las Colinas", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
    {"Mulholland", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
    {"Ocean Docks", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
    {"East Los Santos", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
    {"Ganton", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
    {"Avispa Country Club", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
    {"Willowfield", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
    {"Esplanade North", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
    {"The High Roller", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
    {"Ocean Docks", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
    {"Last Dime Motel", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
    {"Bayside Marina", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
    {"King's", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
    {"El Corona", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
    {"Blackfield Chapel", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
    {"The Pink Swan", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
    {"Julius Thruway West", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
    {"Los Flores", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
    {"The Visage", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
    {"Prickle Pine", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
    {"Verona Beach", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
    {"Robada Intersection", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
    {"Linden Side", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
    {"Ocean Docks", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
    {"Willowfield", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
    {"King's", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
    {"Commerce", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
    {"Mulholland", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
    {"Marina", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
    {"Battery Point", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
    {"The Four Dragons Casino", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
    {"Blackfield", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
    {"Julius Thruway North", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
    {"Yellow Bell Gol Course", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
    {"Idlewood", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
    {"Redsands West", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
    {"Doherty", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
    {"Hilltop Farm", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
    {"Las Barrancas", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
    {"Pirates in Men's Pants", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
    {"City Hall", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
    {"Avispa Country Club", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
    {"The Strip", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
    {"Hashbury", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
    {"Los Santos International", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
    {"Whitewood Estates", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
    {"Sherman Reservoir", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
    {"El Corona", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
    {"Downtown", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
    {"Foster Valley", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
    {"Las Payasadas", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
    {"Valle Ocultado", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
    {"Blackfield Intersection", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
    {"Ganton", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
    {"Easter Bay Airport", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
    {"Redsands East", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
    {"Esplanade East", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
    {"Caligula's Palace", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
    {"Royal Casino", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
    {"Richman", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
    {"Starfish Casino", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
    {"Mulholland", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
    {"Downtown", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
    {"Hankypanky Point", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
    {"K.A.C.C. Military Fuels", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
    {"Harry Gold Parkway", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
    {"Bayside Tunnel", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
    {"Ocean Docks", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
    {"Richman", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
    {"Randolph Industrial Estate", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
    {"East Beach", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
    {"Flint Water", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
    {"Blueberry", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
    {"Linden Station", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
    {"Glen Park", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
    {"Downtown", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
    {"Redsands West", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
    {"Richman", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
    {"Gant Bridge", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
    {"Lil' Probe Inn", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
    {"Flint Intersection", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
    {"Las Colinas", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
    {"Sobell Rail Yards", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
    {"The Emerald Isle", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
    {"El Castillo del Diablo", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
    {"Santa Flora", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
    {"Playa del Seville", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
    {"Market", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
    {"Queens", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
    {"Pilson Intersection", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
    {"Spinybed", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
    {"Pilgrim", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
    {"Blackfield", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
    {"'The Big Ear'", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
    {"Dillimore", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
    {"El Quebrados", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
    {"Esplanade North", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
    {"Easter Bay Airport", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
    {"Fisher's Lagoon", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
    {"Mulholland", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
    {"East Beach", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
    {"San Andreas Sound", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
    {"Shady Creeks", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
    {"Market", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
    {"Rockshore West", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
    {"Prickle Pine", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
    {"Easter Basin", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
    {"Leafy Hollow", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
    {"LVA Freight Depot", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
    {"Prickle Pine", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
    {"Blueberry", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
    {"El Castillo del Diablo", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
    {"Downtown", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
    {"Rockshore East", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
    {"San Fierro Bay", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
    {"Paradiso", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
    {"The Camel's Toe", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
    {"Old Venturas Strip", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
    {"Juniper Hill", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
    {"Juniper Hollow", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
    {"Roca Escalante", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
    {"Julius Thruway East", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
    {"Verona Beach", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
    {"Foster Valley", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
    {"Arco del Oeste", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
    {"Fallen Tree", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
    {"The Farm", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
    {"The Sherman Dam", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
    {"Esplanade North", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
    {"Financial", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
    {"Garcia", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
    {"Montgomery", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
    {"Creek", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
    {"Los Santos International", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
    {"Santa Maria Beach", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
    {"Mulholland Intersection", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
    {"Angel Pine", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
    {"Verdant Meadows", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
    {"Octane Springs", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
    {"Come-A-Lot", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
    {"Redsands West", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
    {"Santa Maria Beach", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
    {"Verdant Bluffs", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
    {"Las Venturas Airport", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
    {"Flint Range", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
    {"Verdant Bluffs", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
    {"Palomino Creek", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
    {"Ocean Docks", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
    {"Easter Bay Airport", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
    {"Whitewood Estates", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
    {"Calton Heights", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
    {"Easter Basin", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000},
    {"Los Santos Inlet", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
    {"Doherty", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
    {"Mount Chiliad", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
    {"Fort Carson", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
    {"Foster Valley", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
    {"Ocean Flats", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
    {"Fern Ridge", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
    {"Bayside", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
    {"Las Venturas Airport", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
    {"Blueberry Acres", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
    {"Palisades", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
    {"North Rock", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
    {"Hunter Quarry", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
    {"Los Santos International", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
    {"Missionary Hill", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
    {"San Fierro Bay", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
    {"Restricted Area", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
    {"Mount Chiliad", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
    {"Mount Chiliad", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
    {"Easter Bay Airport", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
    {"The Panopticon", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
    {"Shady Creeks", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
    {"Back o Beyond", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
    {"Mount Chiliad", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083},
    {"Tierra Robada", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
    {"Flint County", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
    {"Whetstone", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
    {"Bone County", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
    {"Tierra Robada", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
    {"San Fierro", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
    {"Las Venturas", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
    {"Red County", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
    {"Los Santos", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}}
    for i, v in ipairs(streets) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end
	-- If unknown location
	if getActiveInterior() ~= 0 then 
	   return "Interior "..getActiveInterior()
	else
       return "Uncharted lands"
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
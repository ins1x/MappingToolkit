script_author("1NS")
script_name("Absolute Events Helper")
script_description("Assistant for mappers and event makers")
script_dependencies('imgui', 'lib.samp.events')
script_properties("work-in-pause")
script_url("https://github.com/ins1x/AbsEventHelper")
script_version("2.7.4")
-- script_moonloader(16) moonloader v.0.26
-- sa-mp version: 0.3.7 R1
-- Activaton: ALT + X (show main menu) or command /abs
-- Blast.hk thread: https://www.blast.hk/threads/200619/

require 'lib.moonloader'
local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

-------------- [ cfg ] ---------------
local inicfg = require 'inicfg'
local configIni = "AbsEventHelper.ini"
local ini = inicfg.load({
   settings =
   {
      showhud = true,
      showbackgroundbar = false,
      hotkeys = true,
      disconnectreminder = false,
      lockserverweather = false,
      usecustomcamdist = false,
	  showobjectrot = false,
      restoreobjectpos = false,
      chatmentions = false,
      debug = false,
      drawdist = "450",
      fog = "200",
	  camdist = "1",
   },
   binds =
   {
      customrule1 = " ",
      customrule2 = " ",
      customrule3 = " ",
      customrule4 = " ",
      customrule5 = " ",
      customrule6 = " ",
      customrule7 = " ",
      customrule8 = " "
   }
}, configIni)
inicfg.save(ini, configIni)
--------------------------------------

objectsrenderfont = renderCreateFont("Arial", 7, 5)
backgroundfont = renderCreateFont("Tahoma", 7, 5)

local sizeX, sizeY = getScreenResolution()
local v = nil
local color = imgui.ImFloat4(1, 0, 0, 1)
local lastRemovedObjectCoords = {x=0.0, y=0.0, z=0.0, rx=0.0, ry=0.0, rz=0.0}
local gamestates = {'None', 'Wait Connect', 'Await Join', 'Connected', 'Restarting', 'Disconnected'}
local editmodes = {"None", "Edit", "Clone", "Remove", "Retexture"}
local gamestate = imgui.ImInt(0)

local isAbsolutePlay = false
local isTraining = false
local isSampAddonInstalled = false
local isAbsfixInstalled = false
local isPlayerSpectating = false
local isWorldHoster = false
local disableObjectCollision = false
local prepareTeleport = false
local prepareJump = false
local showobjects = false
local showrenderline = false
local countobjects = true
local ENBSeries = false
local chosenplayer = nil
local chosenvehicle = nil
local tabselectedplayer = nil
local lastRemovedObjectModelid = nil
local hide3dtexts = false
local editResponse = 0 
local isSelectObject = false
local isTexturesListOpened = false
local isSampObjectsListOpened = false
local hideEditObject = false
local scaleEditObject = false
local lastWorldNumber = 0 -- is not same GetVirtualWorldId
local lastClickedTextdrawId = 0
local removedBuildings = 0
local mpStartedDTime = nil
local mpStarted = false
local autoAnnounce = false
local isChatFreezed = false
local isWarningsActive = false
local chosenplayerMarker = nil
local lastPmMessage = nil
local editDialogOpened = false
local editMode = 0

local fps = 0
local fps_counter = 0
local vehinfomodelid = 0 

local objectsCollisionDel = {}
local playersTable = {}
local vehiclesTable = {}
local hiddenObjects = {}
local chatbuffer = {}
-- should be global!
vehiclesTotal = 0
playersTotal = 0
streamedObjects = 0 

local legalweapons = {0, 1}
local fixcam = {x = 0.0, y = 0.0, z = 0.0}
local tpcpos = {x = 0.0, y = 0.0, z = 0.0}
local worldspawnpos = {x = 0.0, y = 0.0, z = 0.0}
local tpc = { 
   public = {x = 0, y = 0, z = 0},
   private = {x = 0, y = 0, z = 0},
   static = {x = 0, y = 0, z = 0}
}

local dialog = {
   main = imgui.ImBool(false),
   textures = imgui.ImBool(false),
   playerstat = imgui.ImBool(false),
   vehstat = imgui.ImBool(false),
   extendedtab = imgui.ImBool(false),
   objectinfo = imgui.ImBool(false),
   fastanswer = imgui.ImBool(false)
}

local checkbox = {
   showhud = imgui.ImBool(ini.settings.showhud),
   disconnectreminder = imgui.ImBool(ini.settings.disconnectreminder),
   lockserverweather = imgui.ImBool(ini.settings.lockserverweather),
   usecustomcamdist = imgui.ImBool(ini.settings.usecustomcamdist),
   showobjectrot = imgui.ImBool(ini.settings.showobjectrot),
   restoreobjectpos = imgui.ImBool(ini.settings.restoreobjectpos),
   chatmentions = imgui.ImBool(ini.settings.chatmentions),
   showbackgroundbar = imgui.ImBool(ini.settings.showbackgroundbar),
   hotkeys = imgui.ImBool(ini.settings.hotkeys),
   showobjects = imgui.ImBool(false),
   showclosestobjects = imgui.ImBool(false),
   drawlinetomodelid = imgui.ImBool(false),
   noempyvehstream = imgui.ImBool(true),
   hideobject = imgui.ImBool(false),
   hidechat = imgui.ImBool(false),
   lockfps = imgui.ImBool(false),
   changefov = imgui.ImBool(false),
   fixcampos = imgui.ImBool(false),
   teleportcoords = imgui.ImBool(false),
   logtextdraws = imgui.ImBool(false),
   logdialogresponse = imgui.ImBool(false),
   logobjects = imgui.ImBool(false),
   log3dtexts = imgui.ImBool(false),
   logtxd = imgui.ImBool(false),
   logmessages = imgui.ImBool(false),
   pickeduppickups = imgui.ImBool(false),
   showtextdrawsid = imgui.ImBool(false),
   vehloads = imgui.ImBool(false),
   shadows = imgui.ImBool(false),
   noeffects = imgui.ImBool(false),
   nofactorysmoke = imgui.ImBool(false),
   nowater = imgui.ImBool(false),
   underwater = imgui.ImBool(false),
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
   findveh = imgui.ImBool(false),
   healthcheck = imgui.ImBool(false),
   donators = imgui.ImBool(false),
   freezechat = imgui.ImBool(false),
   globalchatoff = imgui.ImBool(false),
   playerwarnings = imgui.ImBool(false),
   objectscale = imgui.ImBool(false),
   stepteleport = imgui.ImBool(false),
   freezepos = imgui.ImBool(false),
   searchobjectsext = imgui.ImBool(false),
   test = imgui.ImBool(false)
}

local warnings = {
   undermap = true,
   hprefill = true,
   laggers = true,
   afk = true,
   illegalweapons = true,
   hprefil = true,
   armourrefill = true,
   heavyweapons = true
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
   scale = imgui.ImFloat(1.0),
   camdist = imgui.ImInt(ini.settings.camdist)
}

local tabmenu = {
   main = 1,
   objects = 1,
   settings = 1,
   info = 1,
   mp = 1,
   cmds = 1
}

local textbuffer = {
   vehiclename = imgui.ImBuffer(128),
   mpname = imgui.ImBuffer(128),
   mpprize = imgui.ImBuffer(32),
   mpdonators = imgui.ImBuffer(128),
   mphp = imgui.ImBuffer(6),
   mparmour = imgui.ImBuffer(6),
   rule1 = imgui.ImBuffer(256),
   rule2 = imgui.ImBuffer(256),
   rule3 = imgui.ImBuffer(256),
   rule4 = imgui.ImBuffer(256),
   rule5 = imgui.ImBuffer(256),
   rule6 = imgui.ImBuffer(256),
   rule7 = imgui.ImBuffer(256),
   rule8 = imgui.ImBuffer(256),
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
   sms = imgui.ImBuffer(256),
   tpstep = imgui.ImBuffer(2),
   note = imgui.ImBuffer(1024)
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
   chatselect = imgui.ImInt(0),
   profiles = imgui.ImInt(0),
   selecttable = imgui.ImInt(0),
   objects = imgui.ImInt(6),
   weaponselect = imgui.ImInt(0),
   itemad = imgui.ImInt(0),
   sitelogsource = imgui.ImInt(0),
   fastanswers = imgui.ImInt(0),
   logs = imgui.ImInt(0)
}

local LastObjectData = {
   handle = nil,
   id = nil,
   modelid = nil,
   localid = nil,
   txdname = nil,
   txdlibname = nil,
   txdmodel = nil,
   blip = false,
   hidden = true,
   startpos = {x=0.0, y=0.0, z=0.0},
   position = {x=0.0, y=0.0, z=0.0},
   rotation = {x=0.0, y=0.0, z=0.0}
}

absServersNames = {
   'Deathmatch', 'Platinum', 'Titanium', 'Chromium', 'Aurum', 'Litium'
}

profilesNames = {
   'Custom', 'Race', 'Derby', 'Survival', 'PvP', 'Death-Roof', 'TDM',
   'Hide-n-Seek', 'Quiz', 'King', 'Hunt', 'Rodeo', 'Road Rash'
}

fastAnswers = {
   u8"Мероприятие уже начато - вход на МП был закрыт",
   u8"Вынужден был удалить вас с МП из-за ваших лагов",
   u8"Не мешайте игрокам - кикну",
   u8"Не мешайте проведению МП - кикну",
   u8"Заходите в мир №10",
   u8"Вам необходимо перезайти в мир",
   u8"Займите свободный транспорт",
   u8"Вы тут?"
}  

weaponNames = {
	[0] = 'Fists',
	[1] = 'Brass Knuckles',
	[2] = 'Golf Club',
	[3] = 'Nightstick',
	[4] = 'Knife',
	[5] = 'Baseball Bat	',
	[6] = 'Shovel',
	[7] = 'Pool Cue',
	[8] = 'Katana',
	[9] = 'Chainsaw',
	[10] = 'Purple Dildo',
	[11] = 'Dildo',
	[12] = 'Vibrator',
	[13] = 'Silver Vibrator',
	[14] = 'Flowers',
	[15] = 'Cane',
	[16] = 'Grenade',
	[17] = 'Tear Gas',
	[18] = 'Molotov Cocktail',
	[19] = '##',
	[20] = '##',
	[21] = '##',
	[22] = 'Pistol',
	[23] = 'Silent Pistol',
	[24] = 'Desert Eagle',
	[25] = 'Shotgun',
	[26] = 'Sawnoff Shotgun',
	[27] = 'Combat Shotgun',
	[28] = 'Micro SMG/Uzi',
	[29] = 'MP5',
	[30] = 'AK-47',
	[31] = 'M4',
	[32] = 'Tec-9',
	[33] = 'Contry Riffle',
	[34] = 'Sniper Riffle',
	[35] = 'RPG',
	[36] = 'HS Rocket',
	[37] = 'Flame Thrower',
	[38] = 'Minigun',
	[39] = 'Satchel charge',
	[40] = 'Detonator',
	[41] = 'Spraycan',
	[42] = 'Fire Extiguisher',
	[43] = 'Camera',
	[44] = 'Nigh Vision Goggles',
	[45] = 'Thermal Goggles',
	[46] = 'Parachute'
}

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

AbsParticleNames = {
   [18643] = "Красный лазер",
   [18647] = "Красный неон",
   [18648] = "Синий неон",
   [18649] = "Зеленый неон",
   [18650] = "Желтый неон",
   [18651] = "Розовый неон",
   [18652] = "Белый неон",
   [18653] = "Красный прожектор",
   [18654] = "Зеленый прожектор",
   [18655] = "Синий прожектор",
   [18668] = "Кровь",
   [18669] = "Брызги воды",
   [18670] = "Вспышка камеры",
   [18671] = "Дым белый густой",
   [18672] = "Льющийся цемент",
   [18673] = "Дым от сигаретты",
   [18674] = "Летящие облака",
   [18675] = "Вспышка дыма",
   [18676] = "Струя воды",
   [18677] = "Небольшой дым исчезающий",
   [18678] = "Ломающаяся коробка ",
   [18679] = "Ломающаяся коробка2",
   [18680] = "Выстрел",
   [18681] = "Взрыв тип1 маленький",
   [18682] = "Взрыв тип2 огромный",
   [18683] = "Взрыв тип3 огромный",
   [18684] = "Взрыв тип4 огромный",
   [18685] = "Взрыв тип5 огромный",
   [18686] = "Взрыв тип7 маленький",
   [18687] = "Пена огнетушителя",
   [18688] = "Огонь1 маленький",
   [18689] = "Огонь2 с дымом маленький",
   [18690] = "Огонь3 с дымом средний",
   [18691] = "Огонь4 средний",
   [18692] = "Огонь5 маленький",
   [18693] = "Огонь6 очень маленький",
   [18694] = "Огонь из огнемета",
   [18695] = "Эфект выстрела одиночный",
   [18696] = "Дым от выстрела одиночный",
   [18697] = "Пыль из под вертолета",
   [18698] = "Спавнер мух",
   [18699] = "Огонь от джетпака",
   [18700] = "Нитро",
   [18701] = "Огонь свечи",
   [18702] = "Большое нитро",
   [18703] = "Дым маленький",
   [18704] = "Дым маленький с искрами",
   [18705] = "Струя мочи",
   [18706] = "Белый фонтан крови",
   [18707] = "Водопад",
   [18708] = "Пузырьки воздуха при плавании",
   [18709] = "Ломающееся стекло",
   [18710] = "Густой дым постоянный",
   [18711] = "Ломающееся стекло 2",
   [18712] = "Гильзы при стрельбе",
   [18713] = "Дым большой белый",
   [18714] = "Дым2 большой белый",
   [18715] = "Дым большой серый",
   [18716] = "Дым маленький серый",
   [18717] = "Искры при стрельбе",
   [18718] = "Искры при стрельбе 2",
   [18719] = "След на воде",
   [18720] = "Падающие капли воды",
   [18721] = "Высокий водопад",
   [18722] = "Рвота",
   [18723] = "Дым большой черный клубящийся",
   [18724] = "Взрыв со стеклами",
   [18725] = "Дым маленький переменный",
   [18726] = "Дым маленький черный",
   [18727] = "Дым средний переменный",
   [18728] = "Свет сигнальной ракеты",
   [18729] = "Краска из баллончика",
   [18730] = "Выстрел танка",
   [18731] = "Дымовая шашка1",
   [18732] = "Дымовая шашка2",
   [18733] = "Падающие листья ",
   [18734] = "Падающие листья2",
   [18735] = "Дым маленький серый",
   [18736] = "Дым 2 маленький серый",
   [18737] = "Большие клубы пыли",
   [18738] = "Фонтан с паузой",
   [18739] = "Фонтан постоянный",
   [18740] = "Сбитый пожарный гидрант",
   [18741] = "Круги на воде",
   [18742] = "Большие брызги",
   [18743] = "Средний всплеск воды",
   [18744] = "Большой всплеск воды",
   [18745] = "Маленький всплеск воды1",
   [18746] = "Маленький всплеск воды2",
   [18747] = "Брызги водопада",
   [18748] = "Дым от заводской трубы",
   [18828] = "Спиральная труба",
   [18863] = "Маленький снег",
   [18864] = "Большой снег",
   [18881] = "Скайдайв2",
   [18888] = "Прозрачный блок2",
   [18889] = "Прозрачный блок3",
   [19080] = "Синий лазер",
   [19081] = "Розовый лазер",
   [19082] = "Оранжевый лазер",
   [19083] = "Зеленый лазер",
   [19084] = "Желтый лазер",
   [19121] = "Белый светящийся столб",
   [19122] = "Синий светящийся столб",
   [19123] = "Зеленый светящийся столб",
   [19124] = "Красный светящийся столб",
   [19125] = "Желтый светящийся столб",
   [19143] = "Белый прожектор",
   [19144] = "Красный прожектор",
   [19145] = "Зеленый прожектор",
   [19146] = "Синий прожектор",
   [19147] = "Желтый прожектор",
   [19148] = "Розовый прожектор",
   [19149] = "Голубой прожектор",
   [19150] = "Белый мигающий прожектор",
   [19151] = "Карсный мигающий прожектор",
   [19152] = "Зеленый мигающий прожектор",
   [19153] = "Синий мигающий прожектор",
   [19154] = "Желтый мигающий прожектор",
   [19155] = "Розовый мигающий прожектор",
   [19156] = "Голубой мигающий прожектор",
   [19281] = "Белый шар",
   [19282] = "Красный шар",
   [19283] = "Зеленый шар",
   [19284] = "Синий шар",
   [19285] = "Белый быстро моргающий шар",
   [19286] = "Красный быстро моргающий шар",
   [19287] = "Зеленый быстро моргающий шар",
   [19288] = "Синий быстро моргающий шар",
   [19289] = "Белый медленно моргающий шар",
   [19290] = "Красный медленно моргающий шар",
   [19291] = "Зеленый медленно моргающий шар",
   [19292] = "Синий медленно моргающий шар",
   [19293] = "Фиолетовый медленно моргающий шар",
   [19294] = "Желтый медленно моргающий шар",
   [19295] = "Белый большой шар",
   [19296] = "Красный большой шар",
   [19297] = "Зеленый большой шар",
   [19298] = "Синий большой шар",
   [19299] = "Луна",
   [19300] = "blankmodel",
   [19349] = "Монокль",
   [19350] = "Усы",
   [19351] = "Усы2",
   [19374] = "Невидимая стена",
   [19382] = "Невидимая стена",
   [19475] = "Небольшая поверхность для текста",
   [19476] = "Небольшая поверхность для текста",
   [19477] = "Средняя поверхность для текста",
   [19478] = "Поверхность для текста",
   [19479] = "Большая поверхность для текста",
   [19480] = "Маленькая поверхность для текста",
   [19481] = "Большая поверхность для текста",
   [19483] = "Средняя поверхность для текста",
   [19482] = "Средняя поверхность для текста",
   [19803] = "Мигалки эвакуатора",
   [19895] = "Аварийка"
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

sampObjectModelNames =
{
   [320] = "airtrain_vlo", [321] = "gun_dildo1", [322] = "gun_dildo2", [323] = "gun_vibe1", [324] = "gun_vibe2", 
   [325] = "flowera", [326] = "gun_cane", [327] = "gun_boxwee", [328] = "gun_boxbig", [330] = "cellphone", 
   [331] = "brassknuckle", [333] = "golfclub", [334] = "nitestick", [335] = "knifecur", [336] = "bat", 
   [337] = "shovel", [338] = "poolcue", [339] = "katana", [341] = "chnsaw", [342] = "grenade", 
   [343] = "teargas", [344] = "molotov", [345] = "missile", [346] = "colt45", [347] = "silenced", 
   [348] = "desert_eagle", [349] = "chromegun", [350] = "sawnoff", [351] = "shotgspa", [352] = "micro_uzi", 
   [353] = "mp5lng", [354] = "flare", [355] = "ak47", [356] = "m4", [357] = "cuntgun", 
   [358] = "sniper", [359] = "rocketla", [360] = "heatseek", [361] = "flame", [362] = "minigun", 
   [363] = "satchel", [364] = "bomb", [365] = "spraycan", [366] = "fire_ex", [367] = "camera", 
   [368] = "nvgoggles", [369] = "irgoggles", [370] = "jetpack", [371] = "gun_para", [372] = "tec9", 
   [373] = "armour", [615] = "veg_tree3", [616] = "veg_treea1", [617] = "veg_treeb1", [618] = "veg_treea3", 
   [619] = "veg_palwee03", [620] = "veg_palm04", [621] = "veg_palm02", [622] = "veg_palm03", [623] = "veg_palwee01", 
   [624] = "veg_palwee02", [625] = "veg_palmkb1", [626] = "veg_palmkb2", [627] = "veg_palmkb3", [628] = "veg_palmkb4", 
   [629] = "veg_palmkb5", [630] = "veg_palmkb8", [631] = "veg_palmkb9", [632] = "veg_palmkb7", [633] = "veg_palmkb10", 
   [634] = "veg_palmkbb11", [635] = "veg_fern_balcny_kb1", [636] = "veg_fern_balcny_kb2", [637] = "kb_planterbox", [638] = "kb_planter+bush", 
   [639] = "veg_ivy_balcny_kb3", [640] = "kb_planter+bush2", [641] = "veg_palmkb13", [642] = "kb_canopy_test", [643] = "kb_chr_tbl_test", 
   [644] = "pot_02", [645] = "veg_palmbig14", [646] = "veg_palmkb14", [647] = "new_bushsm", [648] = "veg_palm01", 
   [649] = "sjmpalm", [650] = "sjmcacti2", [651] = "sjmcacti1", [652] = "sjmpalmbig", [653] = "sjmcacti03", 
   [654] = "pinetree08", [655] = "pinetree06", [656] = "pinetree05", [657] = "pinetree02", [658] = "pinetree04", 
   [659] = "pinetree01", [660] = "pinetree03", [661] = "pinetree07", [664] = "firtree2", [669] = "sm_veg_tree4", 
   [670] = "sm_firtallded", [671] = "sm_bushytree", [672] = "sm_veg_tree5", [673] = "sm_bevhiltree", [674] = "sm_des_josh_lrg1", 
   [675] = "josh_ball", [676] = "sm_des_josh_sml1", [677] = "sm_des_agave1", [678] = "sm_des_agave2", [679] = "sm_des_cact_bsh", 
   [680] = "sm_des_josh_lrg2", [681] = "sm_des_josh_sm2", [682] = "sm_des_cactflr", [683] = "sm_fir_group", [684] = "sm_fir_log02", 
   [685] = "sm_fir_scabby", [686] = "sm_fir_dead", [687] = "sm_fir_", [688] = "sm_fir_scabg", [689] = "sm_fir_copse1", 
   [690] = "sm_fir_copse2", [691] = "sm_veg_tree4_big", [692] = "sm_des_bush1", [693] = "sm_redwood_", [694] = "sm_redwoodgrp", 
   [695] = "sm_fir_scabtg", [696] = "sm_fir_scabt", [697] = "sm_fir_tall", [698] = "sm_firtbshg", [700] = "sm_veg_tree6", 
   [701] = "sm_tumblewd48p", [702] = "sm_tumbleweed", [703] = "sm_veg_tree7_big", [704] = "bg_fir_dead", [705] = "sm_veg_tree7vbig", 
   [706] = "sm_vegvbbig", [707] = "sm_bushvbig", [708] = "sm_veg_tree4_vbig", [709] = "sm_vegvbbigbrn", [710] = "vgs_palm01", 
   [711] = "vgs_palm02", [712] = "vgs_palm03", [713] = "veg_bevtree1", [714] = "veg_bevtree2", [715] = "veg_bevtree3", 
   [716] = "sjmpalmbigpv", [717] = "sm_bevhiltreepv", [718] = "vgs_palm04", [719] = "veg_largefurs07", [720] = "veg_largefurs01", 
   [721] = "veg_largefurs02", [722] = "veg_largefurs03", [723] = "veg_largefurs04", [724] = "veg_largefurs05", [725] = "veg_largefurs06", 
   [726] = "tree_hipoly19", [727] = "tree_hipoly04", [728] = "tree_hipoly06", [729] = "tree_hipoly07", [730] = "tree_hipoly08", 
   [731] = "tree_hipoly09", [732] = "tree_hipoly10", [733] = "tree_hipoly11", [734] = "tree_hipoly14", [735] = "tree_hipoly09b", 
   [736] = "ceasertree01_lvs", [737] = "aw_streettree3", [738] = "aw_streettree2", [739] = "sjmpalmtall", [740] = "vgs_palmvtall", 
   [741] = "pot_01", [742] = "pot_03", [743] = "kb_pot_1", [744] = "sm_scrub_rock4", [745] = "sm_scrub_rock5", 
   [746] = "sm_scrub_rock2", [747] = "sm_scrub_rock3", [748] = "sm_scrb_grp1", [749] = "sm_scrb_column3", [750] = "sm_scrb_column2", 
   [751] = "sm_scrb_column1", [752] = "sm_cunt_rock1", [753] = "sm_descactiigrpb", [754] = "sm_des_cactiigrp", [755] = "sm_des_pcklypr3", 
   [756] = "sm_des_pcklypr2", [757] = "sm_des_pcklypr1", [758] = "sm_scrub_rock6", [759] = "sm_bush_large_1", [760] = "sm_bush_small_1", 
   [761] = "sm_drybrush_sm1", [762] = "new_bushtest", [763] = "Ash1_hi", [764] = "Cedar3_hi", [765] = "Cedar2_hi", 
   [766] = "Cedar1_hi", [767] = "Elmtreegrn_hi", [768] = "Elmtreegrn2_hi", [769] = "Locust_hi", [770] = "Pinebg_hi", 
   [771] = "sprucetree_hi", [772] = "Elmred_hi", [773] = "Elmdead_hi", [774] = "Elmsparse_hi", [775] = "Elmwee_hi", 
   [776] = "Hazelweetree_hi", [777] = "Hazeltall_hi", [778] = "Elmred_hism", [779] = "Pinebg_hism", [780] = "Elmsparse_hism", 
   [781] = "Elmwee_hism", [782] = "Elmtreegrn_hism", [789] = "hashburytree4sfs", [790] = "sm_fir_tallgroup", [791] = "vbg_fir_copse", 
   [792] = "aw_streettree1", [800] = "genVEG_bush07", [801] = "genVEG_bush01", [802] = "genVEG_bush08", [803] = "genVEG_bush09", 
   [804] = "genVEG_bush10", [805] = "genVEG_bush11", [806] = "genVEG_tallgrass", [807] = "p_rubble", [808] = "genVEG_bush12", 
   [809] = "genVEG_bush13", [810] = "genVEG_bush14", [811] = "genVEG_bush15", [812] = "genVEG_bush16", [813] = "genVEG_bush17", 
   [814] = "genVEG_bush18", [815] = "genVEG_bush19", [816] = "p_rubble03", [817] = "veg_Pflowers01", [818] = "genVEG_tallgrass02", 
   [819] = "genVEG_tallgrass03", [820] = "genVEG_tallgrass04", [821] = "genVEG_tallgrass05", [822] = "genVEG_tallgrass06", [823] = "genVEG_tallgrass07", 
   [824] = "genVEG_tallgrass08", [825] = "genVEG_bushy", [826] = "genVEG_tallgrass10", [827] = "genVEG_tallgrass11", [828] = "p_rubble2", 
   [829] = "DEAD_TREE_3", [830] = "DEAD_TREE_2", [831] = "DEAD_TREE_5", [832] = "DEAD_TREE_4", [833] = "DEAD_TREE_6", 
   [834] = "DEAD_TREE_7", [835] = "DEAD_TREE_8", [836] = "DEAD_TREE_10", [837] = "DEAD_TREE_1", [838] = "DEAD_TREE_9", 
   [839] = "DEAD_TREE_11", [840] = "DEAD_TREE_12", [841] = "DEAD_TREE_13", [842] = "DEAD_TREE_14", [843] = "DEAD_TREE_15", 
   [844] = "DEAD_TREE_16", [845] = "DEAD_TREE_17", [846] = "DEAD_TREE_18", [847] = "DEAD_TREE_19", [848] = "DEAD_TREE_20", 
   [849] = "CJ_urb_rub_3", [850] = "CJ_urb_rub_1", [851] = "CJ_urb_rub_2", [852] = "CJ_urb_rub_4", [853] = "CJ_urb_rub_5", 
   [854] = "CJ_urb_rub_3b", [855] = "genVEG_tallgrass01", [856] = "genVEG_tallgrass12", [857] = "procweegrs", [858] = "sand_josh2", 
   [859] = "sand_plant04", [860] = "sand_plant01", [861] = "sand_plant02", [862] = "sand_plant05", [863] = "sand_plant03", 
   [864] = "sand_combush1", [865] = "sand_combush02", [866] = "sand_combush03", [867] = "p_rubble04col", [868] = "p_rubble05col", 
   [869] = "veg_Pflowerswee", [870] = "veg_Pflowers2wee", [871] = "veg_procfpatchwee", [872] = "gen_tallgrsnew", [873] = "veg_procfpatch", 
   [874] = "veg_procgrasspatch", [875] = "veg_procfpatch01", [876] = "veg_Pflowers03", [877] = "veg_Pflowers04", [878] = "veg_Pflowers02", 
   [879] = "p_rubble04bcol", [880] = "p_rubble0bcol", [881] = "sm_fir_scabg_PO", [882] = "Ash_PO", [883] = "Cedar3_PO", 
   [884] = "Cedar2_PO", [885] = "Cedar1_PO", [886] = "Elmtreegrn_PO", [887] = "Elmtreegrn2_PO", [888] = "Locust_PO", 
   [889] = "Pinebg_PO", [890] = "Elmred_PO", [891] = "Elmdead_PO", [892] = "Hazelweetree_PO", [893] = "Elmredsm_PO", 
   [894] = "Elmsparsesm_PO", [895] = "Elmweesm_PO", [896] = "searock06", [897] = "searock01", [898] = "searock02", 
   [899] = "searock03", [900] = "searock04", [901] = "searock05", [902] = "Starfish", [903] = "seaweed", 
   [904] = "sand_josh1", [905] = "rockbrkq", [906] = "p_rubblebig", [910] = "BUST_CABINET_4", [911] = "BUST_CABINET_1", 
   [912] = "BUST_CABINET_2", [913] = "BUST_CABINET_3", [914] = "GRILL", [915] = "AIRCON_FAN", [916] = "FRUITCRATE2", 
   [917] = "FRUITCRATE1", [918] = "CJ_FLAME_Drum", [919] = "AIRCON", [920] = "Y_GENERATOR", [921] = "CJ_IND_LIGHT", 
   [922] = "Packing_carates1", [923] = "Packing_carates2", [924] = "FRUITCRATE3", [925] = "RACK2", [926] = "RUBBISH_BOX2", 
   [927] = "Piping_Detail", [928] = "RUBBISH_BOX1", [929] = "GENERATOR", [930] = "O2_Bottles", [931] = "RACK3", 
   [932] = "H_WHEELCHAIR", [933] = "CJ_CABLEROLL", [934] = "GENERATOR_BIG", [935] = "CJ_Drum", [936] = "CJ_DF_WORKTOP_2", 
   [937] = "CJ_DF_WORKTOP", [938] = "CJ_DF_LIGHT", [939] = "CJ_DF_UNIT", [940] = "CJ_DF_LIGHT_2", [941] = "CJ_DF_WORKTOP_3", 
   [942] = "CJ_DF_UNIT_2", [943] = "GENERATOR_LOW", [944] = "Packing_carates04", [945] = "WS_CF_LAMPS", [946] = "bskball_lax", 
   [947] = "bskballhub_lax01", [948] = "Plant_Pot_10", [949] = "Plant_Pot_4", [950] = "Plant_Pot_12", [951] = "CJ_VIEW_TELE2", 
   [952] = "GENERATOR_BIG_d", [953] = "CJ_OYSTER", [954] = "cj_horse_Shoe", [955] = "CJ_EXT_SPRUNK", [956] = "CJ_EXT_CANDY", 
   [957] = "CJ_LIGHT_FIT_EXT", [958] = "CJ_CHIP_MAKER", [959] = "CJ_CHIP_MAKER_BITS", [960] = "CJ_ARM_CRATE", [961] = "CJ_ARM_CRATE_top", 
   [962] = "CJ_T_TICKET_PED", [963] = "CJ_T_TICKET", [964] = "CJ_METAL_CRATE", [966] = "bar_gatebar01", [967] = "bar_gatebox01", 
   [968] = "barrierturn", [969] = "Electricgate", [970] = "fencesmallb", [971] = "subwaygate", [972] = "tunnelentrance", 
   [973] = "sub_roadbarrier", [974] = "tall_fence", [975] = "Columbiangate", [976] = "phils_compnd_gate", [977] = "newtowerdoor1", 
   [978] = "sub_roadright", [979] = "sub_roadleft", [980] = "airportgate", [981] = "helix_barrier", [982] = "fenceshit", 
   [983] = "fenceshit3", [984] = "fenceshit2", [985] = "gate_autoR", [986] = "gate_autoL", [987] = "elecfence_BAR", 
   [988] = "ws_apgate", [989] = "ac_apgate", [990] = "bar_barrier12", [991] = "bar_barriergate1", [992] = "bar_barrier10b", 
   [993] = "bar_barrier10", [994] = "lhouse_barrier2", [995] = "bar_barrier16", [996] = "lhouse_barrier1", [997] = "lhouse_barrier3", 
   [998] = "Gdyn_barrier17", [1000] = "spl_b_mar_m", [1001] = "spl_b_bab_m", [1002] = "spl_b_bar_m", [1003] = "spl_b_mab_m", 
   [1004] = "bnt_b_sc_m", [1005] = "bnt_b_sc_l", [1006] = "rf_b_sc_r", [1007] = "wg_l_b_ssk", [1008] = "nto_b_l", 
   [1009] = "nto_b_s", [1010] = "nto_b_tw", [1011] = "bnt_b_sc_p_m", [1012] = "bnt_b_sc_p_l", [1013] = "lgt_b_rspt", 
   [1014] = "spl_b_bar_l", [1015] = "spl_b_bbr_l", [1016] = "spl_b_bbr_m", [1017] = "wg_r_b_ssk", [1018] = "exh_b_ts", 
   [1019] = "exh_b_t", [1020] = "exh_b_l", [1021] = "exh_b_m", [1022] = "exh_b_s", [1023] = "spl_b_bbb_m", 
   [1024] = "lgt_b_sspt", [1025] = "wheel_or1", [1026] = "wg_l_a_s", [1027] = "wg_r_a_s", [1028] = "exh_a_s", 
   [1029] = "exh_c_s", [1030] = "wg_r_c_s", [1031] = "wg_l_c_s", [1032] = "rf_a_s", [1033] = "rf_c_s", 
   [1034] = "exh_a_l", [1035] = "rf_c_l", [1036] = "wg_l_a_l", [1037] = "exh_c_l", [1038] = "rf_a_l", 
   [1039] = "wg_l_c_l", [1040] = "wg_r_a_l", [1041] = "wg_r_c_l", [1042] = "wg_l_lr_br1", [1043] = "exh_lr_br2", 
   [1044] = "exh_lr_br1", [1045] = "exh_c_f", [1046] = "exh_a_f", [1047] = "wg_l_a_f", [1048] = "wg_l_c_f", 
   [1049] = "spl_a_f_r", [1050] = "spl_c_f_r", [1051] = "wg_r_a_f", [1052] = "wg_r_c_f", [1053] = "rf_c_f", 
   [1054] = "rf_a_f", [1055] = "rf_a_st", [1056] = "wg_l_a_st", [1057] = "wg_l_c_st", [1058] = "spl_a_st_r", 
   [1059] = "exh_c_st", [1060] = "spl_c_st_r", [1061] = "rf_c_st", [1062] = "wg_r_a_st", [1063] = "wg_r_c_st", 
   [1064] = "exh_a_st", [1065] = "exh_a_j", [1066] = "exh_c_j", [1067] = "rf_a_j", [1068] = "rf_c_j", 
   [1069] = "wg_l_a_j", [1070] = "wg_l_c_j", [1071] = "wg_r_a_j", [1072] = "wg_r_c_j", [1073] = "wheel_sr6", 
   [1074] = "wheel_sr3", [1075] = "wheel_sr2", [1076] = "wheel_lr4", [1077] = "wheel_lr1", [1078] = "wheel_lr3", 
   [1079] = "wheel_sr1", [1080] = "wheel_sr5", [1081] = "wheel_sr4", [1082] = "wheel_gn1", [1083] = "wheel_lr2", 
   [1084] = "wheel_lr5", [1085] = "wheel_gn2", [1086] = "stereo", [1087] = "hydralics", [1088] = "rf_a_u", 
   [1089] = "exh_c_u", [1090] = "wg_l_a_u", [1091] = "rf_c_u", [1092] = "exh_a_u", [1093] = "wg_l_c_u", 
   [1094] = "wg_r_a_u", [1095] = "wg_r_c_u", [1096] = "wheel_gn3", [1097] = "wheel_gn4", [1098] = "wheel_gn5", 
   [1099] = "wg_r_lr_br1", [1100] = "misc_c_lr_rem1", [1101] = "wg_r_lr_rem1", [1102] = "wg_r_lr_sv", [1103] = "rf_lr_bl2", 
   [1104] = "exh_lr_bl1", [1105] = "exh_lr_bl2", [1106] = "wg_l_lr_rem2", [1107] = "wg_r_lr_bl1", [1108] = "wg_l_lr_bl1", 
   [1109] = "bbb_lr_slv1", [1110] = "bbb_lr_slv2", [1111] = "bnt_lr_slv1", [1112] = "bnt_lr_slv2", [1113] = "exh_lr_slv1", 
   [1114] = "exh_lr_slv2", [1115] = "fbb_lr_slv1", [1116] = "fbb_lr_slv2", [1117] = "fbmp_lr_slv1", [1118] = "wg_l_lr_slv1", 
   [1119] = "wg_l_lr_slv2", [1120] = "wg_r_lr_slv1", [1121] = "wg_r_lr_slv2", [1122] = "wg_l_lr_rem1", [1123] = "misc_c_lr_rem2", 
   [1124] = "wg_r_lr_rem2", [1125] = "misc_c_lr_rem3", [1126] = "exh_lr_rem1", [1127] = "exh_lr_rem2", [1128] = "rf_lr_bl1", 
   [1129] = "exh_lr_sv1", [1130] = "rf_lr_sv1", [1131] = "rf_lr_sv2", [1132] = "exh_lr_sv2", [1133] = "wg_l_lr_sv", 
   [1134] = "wg_l_lr_t1", [1135] = "exh_lr_t2", [1136] = "exh_lr_t1", [1137] = "wg_r_lr_t1", [1138] = "spl_a_s_b", 
   [1139] = "spl_c_s_b", [1140] = "rbmp_c_s", [1141] = "rbmp_a_s", [1142] = "bntr_b_ov", [1143] = "bntl_b_ov", 
   [1144] = "bntr_b_sq", [1145] = "bntl_b_sq", [1146] = "spl_c_l_b", [1147] = "spl_a_l_b", [1148] = "rbmp_c_l", 
   [1149] = "rbmp_a_l", [1150] = "rbmp_a_f", [1151] = "rbmp_c_f", [1152] = "fbmp_c_f", [1153] = "fbmp_a_f", 
   [1154] = "rbmp_a_st", [1155] = "fbmp_a_st", [1156] = "rbmp_c_st", [1157] = "fbmp_c_st", [1158] = "spl_c_j_b", 
   [1159] = "rbmp_a_j", [1160] = "fbmp_a_j", [1161] = "rbmp_c_j", [1162] = "spl_a_j_b", [1163] = "spl_c_u_b", 
   [1164] = "spl_a_u_b", [1165] = "fbmp_c_u", [1166] = "fbmp_a_u", [1167] = "rbmp_c_u", [1168] = "rbmp_a_u", 
   [1169] = "fbmp_a_s", [1170] = "fbmp_c_s", [1171] = "fbmp_a_l", [1172] = "fbmp_c_l", [1173] = "fbmp_c_j", 
   [1174] = "fbmp_lr_br1", [1175] = "fbmp_lr_br2", [1176] = "rbmp_lr_br1", [1177] = "rbmp_lr_br2", [1178] = "rbmp_lr_rem2", 
   [1179] = "fbmp_lr_rem1", [1180] = "rbmp_lr_rem1", [1181] = "fbmp_lr_bl2", [1182] = "fbmp_lr_bl1", [1183] = "rbmp_lr_bl2", 
   [1184] = "rbmp_lr_bl1", [1185] = "fbmp_lr_rem2", [1186] = "rbmp_lr_sv2", [1187] = "rbmp_lr_sv1", [1188] = "fbmp_lr_sv2", 
   [1189] = "fbmp_lr_sv1", [1190] = "fbmp_lr_t2", [1191] = "fbmp_lr_t1", [1192] = "rbmp_lr_t1", [1193] = "rbmp_lr_t2", 
   [1207] = "tiny_rock", [1208] = "washer", [1209] = "vendmach", [1210] = "briefcase", [1211] = "fire_hydrant", 
   [1212] = "Money", [1213] = "mine", [1214] = "bollard", [1215] = "bollardlight", [1216] = "phonebooth1", 
   [1217] = "barrel2", [1218] = "barrel1", [1219] = "palette", [1220] = "cardboardbox2", [1221] = "cardboardbox4", 
   [1222] = "barrel3", [1223] = "lampost_coast", [1224] = "woodenbox", [1225] = "barrel4", [1226] = "lamppost3", 
   [1227] = "dump1", [1228] = "roadworkbarrier1", [1229] = "bussign1", [1230] = "cardboardbox", [1231] = "Streetlamp2", 
   [1232] = "Streetlamp1", [1233] = "noparkingsign1", [1234] = "phonesign", [1235] = "wastebin", [1236] = "rcyclbank01", 
   [1237] = "strtbarrier01", [1238] = "trafficcone", [1239] = "info", [1240] = "health", [1241] = "adrenaline", 
   [1242] = "bodyarmour", [1243] = "bouy", [1244] = "petrolpump", [1245] = "newramp", [1246] = "line", 
   [1247] = "bribe", [1248] = "bonus", [1249] = "faketarget", [1250] = "smashbarpost", [1251] = "smashbar", 
   [1252] = "barrelexpos", [1253] = "camerapickup", [1254] = "killfrenzy", [1255] = "lounger", [1256] = "Stonebench1", 
   [1257] = "bustopm", [1258] = "Mpostbox1", [1259] = "BillBd1", [1260] = "BillBd3", [1262] = "MTraffic4", 
   [1263] = "MTraffic3", [1264] = "BlackBag1", [1265] = "BlackBag2", [1267] = "BillBd2", [1269] = "parkingmeter", 
   [1270] = "parkingmeterg", [1271] = "gunbox", [1272] = "property_locked", [1273] = "property_fsale", [1274] = "bigdollar", 
   [1275] = "clothesp", [1276] = "package1", [1277] = "pickupsave", [1278] = "sub_floodlite", [1279] = "craigpackage", 
   [1280] = "parkbench1", [1281] = "parktable1", [1282] = "Barrierm", [1283] = "MTraffic1", [1284] = "MTraffic2", 
   [1285] = "newstandnew5", [1286] = "newstandnew4", [1287] = "newstandnew3", [1288] = "newstandnew2", [1289] = "newstandnew1", 
   [1290] = "lamppost2", [1291] = "postbox1", [1292] = "postbox1_d", [1293] = "papermachn01", [1294] = "mlamppost", 
   [1295] = "doublestreetlght1", [1296] = "doublestreetlght1_d", [1297] = "lamppost1", [1298] = "lamppost1_d", [1299] = "smashboxpile", 
   [1300] = "bin1", [1301] = "heli_magnet", [1302] = "vendmachfd", [1303] = "dyn_quarryrock03", [1304] = "dyn_quarryrock02", 
   [1305] = "dyn_quarryrock01", [1306] = "tlgraphpolegen", [1307] = "telgrphpoleall", [1308] = "telgrphpole02", [1309] = "BigBillBrd", 
   [1310] = "pikupparachute", [1311] = "gen_roadsign1", [1312] = "gen_roadsign2", [1313] = "killfrenzy2plyr", [1314] = "twoplayer", 
   [1315] = "trafficlight1", [1316] = "hoop", [1317] = "Cylinder", [1318] = "arrow", [1319] = "ws_ref_bollard", 
   [1320] = "ws_roadwarning_05", [1321] = "ws_roadwarning_01", [1322] = "ws_roadwarning_02", [1323] = "ws_roadwarning_03", [1324] = "ws_roadwarning_04", 
   [1327] = "junk_tyre", [1328] = "BinNt10_LA", [1329] = "BinNt13_LA", [1330] = "BinNt14_LA", [1331] = "BinNt01_LA", 
   [1332] = "BinNt02_LA", [1333] = "BinNt03_LA", [1334] = "BinNt04_LA", [1335] = "BinNt05_LA", [1336] = "BinNt06_LA", 
   [1337] = "BinNt07_LA", [1338] = "BinNt08_LA", [1339] = "BinNt09_LA", [1340] = "chillidogcart", [1341] = "icescart_prop", 
   [1342] = "noodlecart_prop", [1343] = "CJ_Dumpster3", [1344] = "CJ_Dumpster2", [1345] = "CJ_Dumpster", [1346] = "CJ_PHONE_KIOSK2", 
   [1347] = "CJ_WASTEBIN", [1348] = "CJ_O2Tanks", [1349] = "CJ_SHTROLLY", [1350] = "CJ_TRAFFIC_LIGHT4", [1351] = "CJ_TRAFFIC_LIGHT5", 
   [1352] = "CJ_TRAFFIC_LIGHT3", [1353] = "CJ_AIRCON", [1354] = "CJ_AIRCON_FAN", [1355] = "CJ_FRUITCRATE1", [1356] = "CJ_FRUITCRATE2", 
   [1357] = "CJ_FRUITCRATE3", [1358] = "CJ_SKIP_Rubbish", [1359] = "CJ_BIN1", [1360] = "CJ_BUSH_PROP3", [1361] = "CJ_BUSH_PROP2", 
   [1362] = "CJ_FIREBIN_(L0)", [1363] = "CJ_PHONE_KIOSK", [1364] = "CJ_BUSH_PROP", [1365] = "CJ_BIG_SKIP1", [1366] = "CJ_FIREHYDRANT", 
   [1367] = "CJ_POSTBOX", [1368] = "CJ_BLOCKER_BENCH", [1369] = "CJ_WHEELCHAIR1", [1370] = "CJ_FLAME_Drum_(F)", [1371] = "CJ_HIPPO_BIN", 
   [1372] = "CJ_Dump2_LOW", [1373] = "traincross1", [1374] = "traincross2", [1375] = "tramstop_SF", [1376] = "ContainerCrane_03", 
   [1377] = "ContainerCrane_01", [1378] = "ContainerCrane_04", [1379] = "MagnoCrane_02", [1380] = "MagnoCrane_01", [1381] = "MagnoCrane_04", 
   [1382] = "MagnoCrane_03", [1383] = "TwrCrane_M_04", [1384] = "TwrCrane_M_01", [1385] = "TwrCrane_M_02", [1386] = "ContainerCrane_02", 
   [1387] = "TwrCrane_M_03", [1388] = "TwrCrane_S_04", [1389] = "TwrCrane_S_01", [1390] = "TwrCrane_S_02", [1391] = "TwrCrane_S_03", 
   [1392] = "TwrCrane_L_04", [1393] = "TwrCrane_L_01", [1394] = "TwrCrane_L_02", [1395] = "TwrCrane_L_03", [1407] = "DYN_F_R_WOOD_1", 
   [1408] = "DYN_F_WOOD_2", [1409] = "CJ_Dump1_LOW", [1410] = "DYN_F_R_WOOD_1b", [1411] = "DYN_MESH_1", [1412] = "DYN_MESH_2", 
   [1413] = "DYN_MESH_3", [1414] = "DYN_COR_SHEET", [1415] = "DYN_DUMPSTER", [1416] = "DYN_UNIT", [1417] = "DYN_CUPBOARD", 
   [1418] = "DYN_F_WOOD_3", [1419] = "DYN_F_IRON_1", [1420] = "DYN_AIRCON", [1421] = "DYN_BOXES", [1422] = "DYN_ROADBARRIER_5", 
   [1423] = "DYN_ROADBARRIER_4", [1424] = "DYN_ROADBARRIER_2", [1425] = "DYN_ROADBARRIER_3", [1426] = "DYN_SCAFFOLD", [1427] = "CJ_ROADBARRIER", 
   [1428] = "DYN_LADDER", [1429] = "DYN_TV", [1430] = "CJ_Dump1_LOW01", [1431] = "DYN_BOX_PILE", [1432] = "DYN_TABLE_2", 
   [1433] = "DYN_TABLE_1", [1434] = "DYN_ROADBARRIER_5a", [1435] = "DYN_ROADBARRIER_5b", [1436] = "DYN_SCAFFOLD_2", [1437] = "DYN_LADDER_2", 
   [1438] = "DYN_BOX_PILE_2", [1439] = "DYN_DUMPSTER_1", [1440] = "DYN_BOX_PILE_3", [1441] = "DYN_BOX_PILE_4", [1442] = "DYN_FIREBIN0", 
   [1443] = "DYN_STREET_SIGN_1", [1444] = "DYN_STREET_SIGN_2", [1445] = "DYN_FF_STAND", [1446] = "DYN_F_R_WOOD_4", [1447] = "DYN_MESH_4", 
   [1448] = "DYN_CRATE_1", [1449] = "DYN_CRATE_2", [1450] = "DYN_CRATE_3", [1451] = "DYN_COUP", [1452] = "DYN_OUTHOUSE", 
   [1453] = "DYN_H_BALE1", [1454] = "DYN_H_BALE2", [1455] = "DYN_GLASS", [1456] = "DYN_F_R_WOOD_2", [1457] = "DYN_OUTHOUSE_2", 
   [1458] = "DYN_CART", [1459] = "DYN_ROADBARRIER_6", [1460] = "DYN_F_R_WOOD_3", [1461] = "DYN_LIFE_P", [1462] = "DYN_woodpile", 
   [1463] = "DYN_WOODPILE2", [1464] = "DYN_SCAFFOLD_3", [1465] = "DYN_SCAFFOLD_4", [1466] = "DYN_SCAFFOLD_5", [1467] = "DYN_SCAFFOLD_3b", 
   [1468] = "DYN_MESH_05", [1469] = "DYN_SCAFFOLD_4b", [1470] = "DYN_PORCH_3", [1471] = "DYN_PORCH_2", [1472] = "DYN_PORCH_1", 
   [1473] = "DYN_PORCH_1b", [1474] = "DYN_PORCH_2b", [1475] = "DYN_PORCH_3b", [1476] = "DYN_PORCH_4", [1477] = "DYN_PORCH_4b", 
   [1478] = "DYN_post_box", [1479] = "DYN_GAZ_1", [1480] = "DYN_GAZ_2", [1481] = "DYN_BAR_B_Q", [1482] = "DYN_GARRAGE1", 
   [1483] = "DYN_GARRAGE2", [1484] = "CJ_BEAR_BOTTLE", [1485] = "CJ_CIGGY", [1486] = "DYN_BEER_1", [1487] = "DYN_WINE_1", 
   [1488] = "DYN_SPIRIT_1", [1489] = "DYN_SALE_POST", [1490] = "tag_01", [1491] = "Gen_doorINT01", [1492] = "Gen_doorINT02", 
   [1493] = "Gen_doorSHOP01", [1494] = "Gen_doorINT03", [1495] = "Gen_doorEXT01", [1496] = "Gen_doorSHOP02", [1497] = "Gen_doorEXT02", 
   [1498] = "Gen_doorEXT03", [1499] = "Gen_doorINT05", [1500] = "Gen_doorEXT05", [1501] = "Gen_doorEXT04", [1502] = "Gen_doorINT04", 
   [1503] = "DYN_RAMP", [1504] = "Gen_doorEXT06", [1505] = "Gen_doorEXT07", [1506] = "Gen_doorEXT08", [1507] = "Gen_doorEXT09", 
   [1508] = "DYN_GARAGE_DOOR", [1509] = "DYN_WINE_3", [1510] = "DYN_ASHTRY", [1511] = "DYN_SPIRIT_02", [1512] = "DYN_WINE_03", 
   [1513] = "DYN_SWEETIE_TRAY", [1514] = "DYN_FF_TILL", [1515] = "DYN_SLOT_PROP", [1516] = "DYN_TABLE_03", [1517] = "DYN_WINE_BREAK", 
   [1518] = "DYN_TV_2", [1519] = "DYN_SCAFF_cover", [1520] = "DYN_WINE_BOUNCE", [1521] = "DYN_SCAFF2_cover", [1522] = "Gen_doorSHOP3", 
   [1523] = "Gen_doorEXT10", [1524] = "tag_front", [1525] = "tag_kilo", [1526] = "tag_rifa", [1527] = "tag_rollin", 
   [1528] = "tag_seville", [1529] = "tag_temple", [1530] = "tag_vagos", [1531] = "tag_azteca", [1532] = "Gen_doorEXT11", 
   [1533] = "Gen_doorEXT12", [1534] = "CJ_WIN_POP2", [1535] = "Gen_doorEXT14", [1536] = "Gen_doorEXT15", [1537] = "Gen_doorEXT16", 
   [1538] = "sl_dtdoor1", [1539] = "lamotsig1_LACJ", [1540] = "vegasmotsignCJ", [1541] = "CJ_BEER_TAPS_1", [1542] = "CJ_BEER_TAPS_2", 
   [1543] = "CJ_BEER_B_2", [1544] = "CJ_BEER_B_1", [1545] = "CJ_B_OPTIC1", [1546] = "CJ_PINT_GLASS", [1547] = "CJ_B_PISH_T", 
   [1548] = "CJ_DRIP_TRAY", [1549] = "CJ_ASHTRAY_b", [1550] = "CJ_MONEY_BAG", [1551] = "DYN_WINE_BIG", [1552] = "vegasmashfnce", 
   [1553] = "vegasmashfnce_Gate", [1554] = "CJ_WATER_BARRIER", [1555] = "Gen_doorEXT17", [1556] = "Gen_doorEXT18", [1557] = "Gen_doorEXT19", 
   [1558] = "CJ_CARDBRD_PICKUP", [1559] = "diamond_3", [1560] = "Gen_doorEXT7_11L", [1561] = "Gen_doorEXT7_11R", [1562] = "ab_jetseat", 
   [1563] = "ab_jetseat_hrest", [1564] = "ab_jetLiteGlass", [1565] = "ab_jetLite", [1566] = "CJ_WS_DOOR", [1567] = "Gen_wardrobe", 
   [1568] = "chinalamp_sf", [1569] = "ADAM_V_DOOR", [1570] = "CJ_NOODLE_3", [1571] = "CJ_NOODLE_1", [1572] = "CJ_AIR_TROLLY", 
   [1574] = "trashcan", [1575] = "drug_white", [1576] = "drug_orange", [1577] = "drug_yellow", [1578] = "drug_green", 
   [1579] = "drug_blue", [1580] = "drug_red", [1581] = "keycard", [1582] = "pizzabox", [1583] = "tar_gun2", 
   [1584] = "tar_gun1", [1585] = "tar_civ2", [1586] = "tar_civ1", [1587] = "tar_frame", [1588] = "tar_top", 
   [1589] = "tar_upright", [1590] = "tar_upleft", [1591] = "tar_downleft", [1592] = "tar_downright", [1593] = "plc_stinger", 
   [1594] = "chairsntable", [1595] = "satdishbig", [1596] = "satdishsml", [1597] = "cntrlrsac1", [1598] = "beachball", 
   [1599] = "fish1single", [1600] = "fish2single", [1601] = "fish3s", [1602] = "jellyfish", [1603] = "jellyfish01", 
   [1604] = "fish3single", [1605] = "fish1s", [1606] = "fish2s", [1607] = "dolphin", [1608] = "shark", 
   [1609] = "turtle", [1610] = "sandcastle1", [1611] = "sandcastle2", [1612] = "submarine", [1613] = "nt_firehose_01", 
   [1614] = "nt_alarm1_01", [1615] = "nt_alarm2_01", [1616] = "nt_securecam1_01", [1617] = "nt_aircon1_01", [1618] = "nt_aircon1_02", 
   [1619] = "nt_vent1_01", [1620] = "nt_vent2_01", [1621] = "nt_vent3_01", [1622] = "nt_securecam2_01", [1623] = "nt_aircon3_01", 
   [1624] = "nt_cablebox1_01", [1625] = "nt_cablebox2_01", [1626] = "nt_cablebox3_01", [1627] = "nt_alarm3_01", [1628] = "nt_cablebox4_01", 
   [1629] = "nt_cablebox5_01", [1630] = "nt_cablebox6_01", [1631] = "waterjump2", [1632] = "waterjump1", [1633] = "landjump", 
   [1634] = "landjump2", [1635] = "nt_aircon1dbl", [1636] = "rcbomb", [1637] = "od_pat_hutb", [1638] = "od_pat_hut", 
   [1639] = "od_vbnet", [1640] = "beachtowel04", [1641] = "beachtowel03", [1642] = "beachtowel02", [1643] = "beachtowel01", 
   [1644] = "lotion", [1645] = "lounge_wood_up", [1646] = "lounge_towel_up", [1647] = "lounge_wood_dn", [1648] = "od_groyne01", 
   [1649] = "wglasssmash", [1650] = "petrolcanm", [1651] = "od_copwindows", [1652] = "fencehaiti", [1653] = "fencehaitism", 
   [1654] = "dynamite", [1655] = "waterjumpx2", [1656] = "Esc_step", [1657] = "htl_fan_rotate_nt", [1658] = "htl_fan_static_nt", 
   [1659] = "htl_fan_static_dy", [1660] = "ramp", [1661] = "htl_fan_rotate_dy", [1662] = "nt_roadblockCI", [1663] = "swivelchair_B", 
   [1664] = "propwinebotl2", [1665] = "propashtray1", [1666] = "propbeerglass1", [1667] = "propwineglass1", [1668] = "propvodkabotl1", 
   [1669] = "propwinebotl1", [1670] = "propcollecttable", [1671] = "swivelchair_A", [1672] = "Gasgrenade", [1673] = "roadsign", 
   [1675] = "wshxrefhse1", [1676] = "washgaspump", [1677] = "wshxrefhse2", [1679] = "chairsntableml", [1681] = "ap_learjet1_01", 
   [1682] = "ap_radar1_01", [1683] = "ap_jumbo_01", [1684] = "portakabin", [1685] = "blockpallet", [1686] = "petrolpumpnew", 
   [1687] = "gen_roofbit1", [1688] = "gen_roofbit2", [1689] = "gen_roofbit3", [1690] = "gen_roofbit4", [1691] = "gen_roofbit5", 
   [1692] = "roofstuff18", [1693] = "roofstuff12", [1694] = "roofstuff13", [1695] = "roofstuff14", [1696] = "roofstuff15", 
   [1697] = "roofstuff16", [1698] = "Esc_step8", [1700] = "kb_bed_test1", [1701] = "kb_bed_test2", [1702] = "kb_couch06", 
   [1703] = "kb_couch02", [1704] = "kb_chair03", [1705] = "kb_chair04", [1706] = "kb_couch03", [1707] = "kb_couch01", 
   [1708] = "kb_chair02", [1709] = "kb_couch08", [1710] = "kb_couch07", [1711] = "kb_chair01", [1712] = "kb_couch05", 
   [1713] = "kb_couch04", [1714] = "kb_swivelchair1", [1715] = "kb_swivelchair2", [1716] = "kb_slot_stool", [1717] = "telly_low_test", 
   [1718] = "snesish", [1719] = "LOW_CONSOLE", [1720] = "rest_chair", [1721] = "est_chair1", [1722] = "off_chairnu", 
   [1723] = "mrk_seating1", [1724] = "mrk_seating1b", [1725] = "mrk_bed1", [1726] = "mrk_seating2", [1727] = "mrk_seating2b", 
   [1728] = "mrk_seating3", [1729] = "mrk_seating3b", [1730] = "SWANK_CABINET_3", [1731] = "CJ_MLIGHT3", [1732] = "CJ_Juke_Box", 
   [1733] = "CJ_WASHINGMAC", [1734] = "CJ_MLIGHT2", [1735] = "CJ_EASYCHAIR1", [1736] = "CJ_Stags_head", [1737] = "MED_DINNING_5", 
   [1738] = "CJ_Radiator_old", [1739] = "SWANK_DIN_CHAIR_5", [1740] = "LOW_CABINET_3", [1741] = "LOW_CABINET_1", [1742] = "Med_BOOKSHELF", 
   [1743] = "MED_CABINET_3", [1744] = "MED_SHELF", [1745] = "MED_BED_3", [1746] = "SWANK_1_FootStool", [1747] = "LOW_TV_2", 
   [1748] = "LOW_TV_3", [1749] = "MED_TV_3", [1750] = "MED_TV_2", [1751] = "MED_TV_4", [1752] = "SWANK_TV_3", 
   [1753] = "SWANK_COUCH_1", [1754] = "SWANK_SINGLE_1", [1755] = "MED_SINGLE_2", [1756] = "LOW_COUCH_4", [1757] = "LOW_COUCH_5", 
   [1758] = "LOW_SINGLE_4", [1759] = "LOW_SINGLE_1", [1760] = "MED_COUCH_2", [1761] = "SWANK_COUCH_2", [1762] = "SWANK_SINGLE_2", 
   [1763] = "LOW_COUCH_1", [1764] = "LOW_COUCH_2", [1765] = "LOW_SINGLE_2", [1766] = "MED_COUCH_1", [1767] = "MED_SINGLE_1", 
   [1768] = "LOW_COUCH_3", [1769] = "LOW_SINGLE_3", [1770] = "LOW_DINNING_2", [1771] = "CJ_bunk_bed1", [1772] = "CJ_HOT_DOG1", 
   [1773] = "CJ_COOKER2", [1774] = "CJ_Monketshopsign", [1775] = "CJ_SPRUNK1", [1776] = "CJ_CANDYVENDOR", [1777] = "CJ_COOKER1", 
   [1778] = "CJ_MOP_PAIL", [1779] = "CJ_TICKETMACHINE", [1780] = "CJ_THIN_FRIGE", [1781] = "MED_TV_1", [1782] = "MED_VIDEO_2", 
   [1783] = "SWANK_VIDEO_2", [1784] = "LOW_VIDEO_2", [1785] = "LOW_VIDEO_1", [1786] = "SWANK_TV_4", [1787] = "MED_VIDEO_1", 
   [1788] = "SWANK_VIDEO_1", [1789] = "CJ_chambermaid", [1790] = "SWANK_VIDEO_3", [1791] = "SWANK_TV_2", [1792] = "SWANK_TV_1", 
   [1793] = "LOW_BED_2", [1794] = "LOW_BED_3", [1795] = "SWANK_BED_2", [1796] = "LOW_BED_4", [1797] = "SWANK_BED_3", 
   [1798] = "SWANK_BED_1", [1799] = "MED_BED_4", [1800] = "LOW_BED_1", [1801] = "SWANK_BED_4", [1802] = "MED_BED_2", 
   [1803] = "MED_BED_7", [1804] = "MED_BED_1", [1805] = "CJ_BARSTOOL", [1806] = "MED_OFFICE_CHAIR", [1807] = "CJ_MEDIUMPOTS1", 
   [1808] = "CJ_WATERCOOLER2", [1809] = "MED_HI_FI", [1810] = "CJ_FOLDCHAIR", [1811] = "MED_DIN_CHAIR_5", [1812] = "LOW_BED_5", 
   [1813] = "COFFEE_LOW_5", [1814] = "COFFEE_MED_1", [1815] = "COFFEE_LOW_2", [1816] = "COFFEE_LOW_3", [1817] = "COFFEE_MED_2", 
   [1818] = "COFFEE_SWANK_2", [1819] = "COFFEE_SWANK_4", [1820] = "COFFEE_LOW_4", [1821] = "COFFEE_LOW_1", [1822] = "COFFEE_SWANK_6", 
   [1823] = "COFFEE_MED_5", [1824] = "craps_table", [1825] = "kb_table_chairs1", [1826] = "kb_table1", [1827] = "man_sdr_tables", 
   [1828] = "man_sdr_rug", [1829] = "man_safenew", [1830] = "kb_bandit1", [1831] = "kb_bandit2", [1832] = "kb_bandit3", 
   [1833] = "kb_bandit4", [1834] = "kb_bandit6", [1835] = "kb_bandit5", [1836] = "kb_bandit7", [1837] = "kb_bandit9", 
   [1838] = "kb_bandit11", [1839] = "k_hifi_1", [1840] = "speaker_2", [1841] = "speaker_1", [1842] = "shop_shelf05", 
   [1843] = "shop_shelf02", [1844] = "shop_shelf03", [1845] = "shop_shelf10", [1846] = "shop_shelf04", [1847] = "shop_shelf06", 
   [1848] = "shop_shelf07", [1849] = "shop_shelf09", [1850] = "shop_shelf08", [1851] = "dice1", [1852] = "dice02", 
   [1853] = "pkr_chp_hi04", [1854] = "pkr_chp_hi05", [1855] = "pkr_chp_hi03", [1856] = "pkr_chp_hi02", [1857] = "pkr_chp_hi01", 
   [1858] = "pkr_chp_hi06", [1859] = "pkr_chp_med04", [1860] = "pkr_chp_med06", [1861] = "pkr_chp_med05", [1862] = "pkr_chp_med03", 
   [1863] = "pkr_chp_med02", [1864] = "pkr_chp_med01", [1865] = "pkr_chplo06", [1866] = "pkr_chplo05", [1867] = "pkr_chplo04", 
   [1868] = "pkr_chplo03", [1869] = "pkr_chplo02", [1870] = "pkr_chplo01", [1871] = "pkr_chp_vlo04", [1872] = "pkr_chp_vlo01", 
   [1873] = "pkr_chp_vlo02", [1874] = "pkr_chp_vlo03", [1875] = "pkr_chp_vlo05", [1876] = "pkr_chp_vlo06", [1877] = "chip_stack02", 
   [1878] = "chip_stack03", [1879] = "chip_stack04", [1880] = "chip_stack05", [1881] = "chip_stack06", [1882] = "chip_stack01", 
   [1883] = "shop_shelf01", [1884] = "shop_dblshlf", [1885] = "shop_baskets", [1886] = "shop_sec_cam", [1887] = "shop_shelf11", 
   [1888] = "shop_shelf12", [1889] = "shop_dblshlf01", [1890] = "shop_dblshlf02", [1891] = "shop_dblshlf03", [1892] = "security_gatsh", 
   [1893] = "shoplight1", [1894] = "garys_luv_ramp", [1895] = "wheel_o_fortune", [1896] = "wheel_table", [1897] = "wheel_support", 
   [1898] = "clicker", [1899] = "pkr_chp_vlo07", [1900] = "pkr_chplo07", [1901] = "chip_stack07", [1902] = "chip_stack08", 
   [1903] = "chip_stack09", [1904] = "chip_stack10", [1905] = "pkr_chplo08", [1906] = "pkr_chplo09", [1907] = "pkr_chplo10", 
   [1908] = "pkr_chplo11", [1909] = "pkr_chp_vlo08", [1910] = "pkr_chp_vlo09", [1911] = "chip_stack11", [1912] = "pkr_chp_vlo10", 
   [1913] = "pkr_chp_vlo11", [1914] = "pkr_chp_vlo12", [1915] = "pkr_chp_med07", [1916] = "pkr_chp_med08", [1917] = "pkr_chp_med09", 
   [1918] = "pkr_chp_med10", [1919] = "pkr_chplo12", [1920] = "pkr_chp_med11", [1921] = "chip_stack12", [1922] = "pkr_chp_med12", 
   [1923] = "pkr_chp_hi07", [1924] = "pkr_chp_hi08", [1925] = "pkr_chp_hi09", [1926] = "pkr_chp_hi10", [1927] = "pkr_chp_hi11", 
   [1928] = "pkr_chp_hi12", [1929] = "wheel_wee01", [1930] = "chip_stack13", [1931] = "chip_stack14", [1932] = "chip_stack15", 
   [1933] = "chip_stack16", [1934] = "pkr_chp_hi13", [1935] = "pkr_chp_hi14", [1936] = "pkr_chp_hi15", [1937] = "pkr_chp_hi16", 
   [1938] = "pkr_chp_hi17", [1939] = "pkr_chp_hi18", [1940] = "chip_stack18", [1941] = "chip_stack17", [1942] = "kg50", 
   [1943] = "kg20", [1944] = "kg10", [1945] = "kg5", [1946] = "baskt_ball_hi", [1947] = "CHIPS_TEMP", 
   [1948] = "slot_4chris", [1949] = "barrier_4andy", [1950] = "kb_beer", [1951] = "kb_beer01", [1952] = "turn_arm_R", 
   [1953] = "turn_plater_R", [1954] = "turn_table_R", [1955] = "turn_armL", [1956] = "turn_platerL", [1957] = "turn_tableL", 
   [1958] = "mxr_mix_body", [1959] = "shop_till", [1960] = "record2", [1961] = "record3", [1962] = "record1", 
   [1963] = "est_desk", [1964] = "est_dsk_stuf", [1965] = "imcmptrkdrl_LAS", [1966] = "imcompmovedr1_las", [1967] = "imcmptrkdrr_LAS", 
   [1968] = "dinerseat_2", [1969] = "dinerseat_3", [1970] = "dinerseat_1", [1971] = "kb_flykiller", [1972] = "kb_cuntopdisp2", 
   [1973] = "kb_cuntopdisp1", [1974] = "kb_golfball", [1975] = "e_test", [1976] = "w_test", [1977] = "vendin3", 
   [1978] = "roulette_tbl", [1979] = "wheel_wee", [1980] = "wilshire7dr1_law", [1981] = "shlf1_cab_mid", [1982] = "shlf2_cab_mid", 
   [1983] = "shlf4_cab_mid", [1984] = "shlf5_till", [1985] = "punchbagnu", [1986] = "shlf2_cab_rt", [1987] = "shlf4_cablft", 
   [1988] = "shlf4_cab_rt", [1989] = "kb_coolerlft2", [1990] = "kb_coolerlft", [1991] = "shlf1_cablft1", [1992] = "shlf2_cablft", 
   [1993] = "shlf3_cab_mid2", [1994] = "shlf3_cablft", [1995] = "shlf3_cab_rt", [1996] = "shlf1_cab_rt", [1997] = "hos_trolley", 
   [1998] = "officedesk1l", [1999] = "officedesk2", [2000] = "filing_cab_nu", [2001] = "nu_plant_ofc", [2002] = "water_coolnu", 
   [2003] = "cr_safe_body", [2004] = "cr_safe_door", [2005] = "cr_safe_cash", [2006] = "cr_safe_dial", [2007] = "filing_cab_nu01", 
   [2008] = "officedesk1", [2009] = "officedesk2l", [2010] = "nu_plant3_ofc", [2011] = "nu_plant2_ofc", [2012] = "shop_shelf13", 
   [2013] = "kit_cab_sink", [2014] = "kit_cab_mid", [2015] = "kit_cab_rght", [2016] = "kit_cab_lft", [2017] = "kit_cab_cookr", 
   [2018] = "kit_cab_washin", [2019] = "kit_cab_frdg", [2020] = "mrk_sidebrd1", [2021] = "mrk_bdsdecab1", [2022] = "kit_cab_crnr", 
   [2023] = "mrk_stnd_lmp", [2024] = "mrk_liv_tble", [2025] = "mrk_wrobe_tmp", [2026] = "mrk_shade_tmp", [2027] = "dinerseat_4", 
   [2028] = "SWANK_CONSOLE", [2029] = "SWANK_DINNING_1", [2030] = "MED_DINNING_1", [2031] = "MED_DINNING_3", [2032] = "MED_DINNING_2", 
   [2033] = "CJ_sawnoff2", [2034] = "CJ_sawnoff", [2035] = "CJ_M16", [2036] = "CJ_psg1", [2037] = "CJ_PISTOL_AMMO", 
   [2038] = "AMMO_BOX_S2", [2039] = "AMMO_BOX_S1", [2040] = "AMMO_BOX_M1", [2041] = "AMMO_BOX_M2", [2042] = "AMMO_BOX_M3", 
   [2043] = "AMMO_BOX_M4", [2044] = "CJ_MP5K", [2045] = "CJ_BBAT_NAILS", [2046] = "CJ_GUNCUPBOARD", [2047] = "CJ_FLAG1", 
   [2048] = "CJ_FLAG2", [2049] = "CJ_TARGET1", [2050] = "CJ_TARGET2", [2051] = "CJ_TARGET4", [2052] = "CJ_TOMMY_HAT", 
   [2053] = "CJ_JERRY_HAT", [2054] = "CJ_CAPT_HAT", [2055] = "CJ_TARGET5", [2056] = "CJ_TARGET6", [2057] = "Flame_tins", 
   [2058] = "CJ_Gun_docs", [2059] = "CJ_GUNSTUFF1", [2060] = "CJ_SANDBAG", [2061] = "CJ_SHELLS1", [2062] = "CJ_OilDrum2", 
   [2063] = "CJ_GREENSHELVES", [2064] = "CJ_FEILDGUN", [2065] = "CJ_M_FILEING1", [2066] = "CJ_M_FILEING2", [2067] = "CJ_M_FILEING3", 
   [2068] = "CJ_cammo_NET", [2069] = "CJ_MLIGHT7", [2070] = "CJ_MLIGHT6", [2071] = "CJ_MLIGHT5", [2072] = "CJ_MLIGHT4", 
   [2073] = "CJ_MLIGHT1", [2074] = "CJ_MLIGHT8", [2075] = "CJ_MLIGHT9", [2076] = "CJ_MLIGHT10", [2077] = "CJ_MLIGHT11", 
   [2078] = "SWANK_CABINET_1", [2079] = "SWANK_DIN_CHAIR_2", [2080] = "SWANK_DINNING_2", [2081] = "COFFEE_SWANK_3", [2082] = "COFFEE_MED_3", 
   [2083] = "COFFEE_MED_4", [2084] = "MED_CABINET_1", [2085] = "SWANK_DINNING_3", [2086] = "SWANK_DINNING_4", [2087] = "MED_CABINET_2", 
   [2088] = "LOW_CABINET_4", [2089] = "SWANK_CABINET_2", [2090] = "SWANK_BED_5", [2091] = "TV_WARD_Med_1", [2092] = "SWANK_CABINET_5", 
   [2093] = "TV_WARD_Low", [2094] = "SWANK_CABINET_4", [2095] = "LOW_CABINET_2", [2096] = "CJ_RockingChair", [2097] = "Bath_high", 
   [2098] = "CJ_SLOTCOVER1", [2099] = "MED_HI_FI_1", [2100] = "MED_HI_FI_2", [2101] = "MED_HI_FI_3", [2102] = "LOW_HI_FI_2", 
   [2103] = "LOW_HI_FI_1", [2104] = "SWANK_HI_FI", [2105] = "CJ_MLIGHT14", [2106] = "CJ_MLIGHT15", [2107] = "CJ_MLIGHT12", 
   [2108] = "CJ_MLIGHT13", [2109] = "LOW_DINNING_3", [2110] = "LOW_DINNING_4", [2111] = "LOW_DINNING_5", [2112] = "MED_DINNING_4", 
   [2113] = "baskgamenet", [2114] = "basketball", [2115] = "LOW_DINNING_1", [2116] = "LOW_DINNING_6", [2117] = "SWANK_DINNING_5", 
   [2118] = "SWANK_DINNING_6", [2119] = "MED_DINNING_6", [2120] = "MED_DIN_CHAIR_4", [2121] = "LOW_DIN_CHAIR_2", [2122] = "SWANK_DIN_CHAIR_3", 
   [2123] = "SWANK_DIN_CHAIR_4", [2124] = "SWANK_DIN_CHAIR_1", [2125] = "MED_DIN_CHAIR_1", [2126] = "COFFEE_SWANK_5", [2127] = "CJ_K1_FRIDGE_UNIT", 
   [2128] = "CJ_K1_TALL_UNIT", [2129] = "CJ_K1_LOW_UNIT", [2130] = "CJ_K1_SINK", [2131] = "CJ_KITCH2_FRIDGE", [2132] = "CJ_KITCH2_SINK", 
   [2133] = "CJ_KITCH2_R", [2134] = "CJ_KITCH2_M", [2135] = "CJ_K3_COOKER", [2136] = "CJ_K3_SINK", [2137] = "CJ_K3_LOW_UNIT3", 
   [2138] = "CJ_K3_LOW_UNIT1", [2139] = "CJ_K3_LOW_UNIT2", [2140] = "CJ_K3_TALL_UNIT1", [2141] = "CJ_KITCH2_L", [2142] = "CJ_K4_LOW_UNIT2", 
   [2143] = "CJ_K4_LOW_UNIT1", [2144] = "CJ_COOKER3", [2145] = "CJ_K3_UNIT06", [2146] = "CJ_TROLLY1", [2147] = "CJ_KITCH1_FRIDGE", 
   [2148] = "CJ_K4_LOW_UNIT03", [2149] = "CJ_MICROWAVE1", [2150] = "CJ_SINK1", [2151] = "CJ_K5_LOW_UNIT2", [2152] = "CJ_K5_LOW_UNIT3", 
   [2153] = "CJ_K5_UNIT1", [2154] = "CJ_K5_LOW_UNIT1", [2155] = "CJ_K5_LOW_UNIT4", [2156] = "CJ_K6_LOW_UNIT1", [2157] = "CJ_K6_LOW_UNIT2", 
   [2158] = "CJ_KITCH1_L", [2159] = "CJ_K6_LOW_UNIT4", [2160] = "CJ_K6_LOW_UNIT3", [2161] = "MED_OFFICE_UNIT_4", [2162] = "MED_OFFICE_UNIT_1", 
   [2163] = "MED_OFFICE_UNIT_2", [2164] = "MED_OFFICE_UNIT_5", [2165] = "MED_OFFICE_DESK_1", [2166] = "MED_OFFICE_DESK_2", [2167] = "MED_OFFICE_UNIT_7", 
   [2168] = "partition", [2169] = "MED_OFFICE3_DESK_1", [2170] = "CJ_KITCH1_COOKER", [2171] = "MED_OFFICE4_DESK_1", [2172] = "MED_OFFICE2_DESK_1", 
   [2173] = "MED_OFFICE_DESK_3", [2174] = "MED_OFFICE4_DESK_2", [2175] = "MED_OFFICE4_DESK_3", [2176] = "Casino_light4", [2177] = "Casino_light3", 
   [2178] = "Casino_light2", [2179] = "Casino_light1", [2180] = "MED_OFFICE5_DESK_3", [2181] = "MED_OFFICE5_DESK_2", [2182] = "MED_OFFICE5_DESK_1", 
   [2183] = "MED_OFFICE3_DESK_09", [2184] = "MED_OFFICE6_DESK_2", [2185] = "MED_OFFICE6_DESK_1", [2186] = "PHOTOCOPIER_1", [2187] = "partition2", 
   [2188] = "blck_jack", [2189] = "poker_tbl", [2190] = "PC_1", [2191] = "MED_OFFICE2_CAB", [2192] = "FAN_1", 
   [2193] = "MED_OFFICE2_DESK_2", [2194] = "Plant_Pot_2", [2195] = "Plant_Pot_3", [2196] = "WORK_LAMP1", [2197] = "FILLING_CABINET", 
   [2198] = "MED_OFFICE2_DESK_3", [2199] = "MED_OFFICE6_MC_1", [2200] = "MED_OFFICE5_UNIT_1", [2201] = "PRINTER_1", [2202] = "PHOTOCOPIER_2", 
   [2203] = "Plant_Pot_1", [2204] = "MED_OFFICE8_CABINET", [2205] = "MED_OFFICE8_DESK_1", [2206] = "MED_OFFICE8_DESK_02", [2207] = "MED_OFFICE7_DESK_1", 
   [2208] = "MED_OFFICE7_UNIT_1", [2209] = "MED_OFFICE9_DESK_1", [2210] = "MED_OFFICE9_UNIT_1", [2211] = "MED_OFFICE9_UNIT_2", [2212] = "burgerhigh", 
   [2213] = "burgerlow", [2214] = "burgermed", [2215] = "clucklow", [2216] = "cluckmed", [2217] = "cluckhigh", 
   [2218] = "pizzalow", [2219] = "pizzamed", [2220] = "pizzahigh", [2221] = "rustylow", [2222] = "rustyhigh", 
   [2223] = "rustymed", [2224] = "CJ_Sphere_TV", [2225] = "SWANK_HI_FI_2", [2226] = "LOW_HI_FI_3", [2227] = "SWANK_HI_FI_3", 
   [2228] = "CJ_SHOVEL", [2229] = "SWANK_SPEAKER", [2230] = "SWANK_SPEAKER_2", [2231] = "SWANK_SPEAKER_3", [2232] = "MED_SPEAKER_4", 
   [2233] = "SWANK_SPEAKER_4", [2234] = "COFFEE_LOW_6", [2235] = "COFFEE_MED_6", [2236] = "COFFEE_SWANK_1", [2237] = "CJ_SHOVEL2", 
   [2238] = "CJ_LAVA_LAMP", [2239] = "CJ_MLIGHT16", [2240] = "Plant_Pot_8", [2241] = "Plant_Pot_5", [2242] = "Plant_Pot_7", 
   [2243] = "Plant_Pot_6", [2244] = "Plant_Pot_9", [2245] = "Plant_Pot_11", [2246] = "Plant_Pot_14", [2247] = "Plant_Pot_15", 
   [2248] = "Plant_Pot_16", [2249] = "Plant_Pot_18", [2250] = "Plant_Pot_19", [2251] = "Plant_Pot_20", [2252] = "Plant_Pot_21", 
   [2253] = "Plant_Pot_22", [2254] = "Frame_Clip_1", [2255] = "Frame_Clip_2", [2256] = "Frame_Clip_3", [2257] = "Frame_Clip_4", 
   [2258] = "Frame_Clip_5", [2259] = "Frame_Clip_6", [2260] = "Frame_SLIM_1", [2261] = "Frame_SLIM_2", [2262] = "Frame_SLIM_3", 
   [2263] = "Frame_SLIM_4", [2264] = "Frame_SLIM_5", [2265] = "Frame_SLIM_6", [2266] = "Frame_WOOD_5", [2267] = "Frame_WOOD_3", 
   [2268] = "Frame_WOOD_2", [2269] = "Frame_WOOD_4", [2270] = "Frame_WOOD_6", [2271] = "Frame_WOOD_1", [2272] = "Frame_Fab_5", 
   [2273] = "Frame_Fab_1", [2274] = "Frame_Fab_6", [2275] = "Frame_Fab_4", [2276] = "Frame_Fab_3", [2277] = "Frame_Fab_2", 
   [2278] = "Frame_Thick_2", [2279] = "Frame_Thick_6", [2280] = "Frame_Thick_1", [2281] = "Frame_Thick_5", [2282] = "Frame_Thick_4", 
   [2283] = "Frame_Thick_3", [2284] = "Frame_6", [2285] = "Frame_1", [2286] = "Frame_5", [2287] = "Frame_4", 
   [2288] = "Frame_3", [2289] = "Frame_2", [2290] = "SWK_COUCH_1", [2291] = "SWK_SINGLE_1", [2292] = "SWK_SINGLE_1b", 
   [2293] = "SWK_1_FStool", [2294] = "CJ_K_COOKER1", [2295] = "CJ_BEANBAG", [2296] = "TV_UNIT_1", [2297] = "TV_UNIT_2", 
   [2298] = "SWANK_BED_7", [2299] = "SWANK_BED_6", [2300] = "MED_BED_8", [2301] = "MED_BED_9", [2302] = "LOW_BED_06", 
   [2303] = "CJ_K3_WASH_MAC", [2304] = "CJ_K1_LOW_CORNER", [2305] = "CJ_K3_C_UNIT", [2306] = "SWANK_CABINET_4D", [2307] = "SWANK_CABINET_4b", 
   [2308] = "MED_OFFICE4_DESK_4", [2309] = "MED_OFFICE_CHAIR2", [2310] = "MIKE_DIN_CHAIR", [2311] = "CJ_TV_TABLE2", [2312] = "CJ_TELE_2", 
   [2313] = "CJ_TV_TABLE1", [2314] = "CJ_TV_TABLE3", [2315] = "CJ_TV_TABLE4", [2316] = "CJ_TELE_4", [2317] = "CJ_TELE_3", 
   [2318] = "CJ_TELE_1", [2319] = "CJ_TV_TABLE5", [2320] = "CJ_TELE_5", [2321] = "CJ_TV_TABLE6", [2322] = "CJ_TELE_6", 
   [2323] = "CJ_BEDROOM1", [2324] = "reel2", [2325] = "kb_bandit_U", [2326] = "reel3", [2327] = "reel1", 
   [2328] = "LOW_CABINET_1_S", [2329] = "LOW_CABINET_1_L", [2330] = "CJ_BEDROOM1_W", [2331] = "CJ_BED_FURN_1", [2332] = "KEV_SAFE", 
   [2333] = "CJ_BED_FURN_1b", [2334] = "CJ_KITCH1_M", [2335] = "CJ_KITCH1_R", [2336] = "CJ_KITCH1_SINK", [2337] = "CJ_KITCH1_WASHER", 
   [2338] = "CJ_KITCH1_CORNER", [2339] = "CJ_KITCH2_COOKER", [2340] = "CJ_KITCH2_WASHER", [2341] = "CJ_KITCH2_CORNER", [2342] = "donut_disp", 
   [2343] = "CJ_BARB_CHAIR_2", [2344] = "CJ_REMOTE", [2345] = "Plant_Pot_23", [2346] = "CJ_HIFI_TABLE", [2347] = "CJ_Wheel_1", 
   [2348] = "CJ_Wheel_02", [2349] = "CJ_Wheel_03", [2350] = "CJ_BARSTOOL_2", [2351] = "CJ_DYN_PLUNGE_1", [2352] = "CJ_DYN_PLUNGE_2", 
   [2353] = "cluck_healthy", [2354] = "burger_healthy", [2355] = "pizza_healthy", [2356] = "police_OFF_CHAIR", [2357] = "DUNC_DINNING", 
   [2358] = "AMMO_BOX_c2", [2359] = "AMMO_BOX_c5", [2360] = "CJ_ICE_FRIDGE_2", [2361] = "CJ_ICE_FRIDGE_1", [2362] = "CJ_SWEETIE_TRAY_1", 
   [2363] = "CJ_SHOP_SIGN_1", [2364] = "CJ_SHOP_SIGN_2", [2365] = "SHOPPING_BASKET", [2366] = "CJ_DUDS_RAIL", [2367] = "Shop_counter_2", 
   [2368] = "Shop_counter_1", [2369] = "CJ_Till", [2370] = "Shop_set_1_Table", [2371] = "CLOTHES_RAIL", [2372] = "CLOTHES_RAIL2", 
   [2373] = "CLOTHES_RAIL3", [2374] = "CJ_Tshirt", [2375] = "Shop_set_2_Unit1", [2376] = "Shop_set_2_Unit2", [2377] = "CJ_jean_dark", 
   [2378] = "CJ_jean_light", [2379] = "Shop_set_2_Unit3", [2380] = "CJ_Suits", [2381] = "CJ_8_SWEATER", [2382] = "CJ_8_JEANS_Light", 
   [2383] = "CJ_6_SWEATER", [2384] = "CJ_8_JEANS_DARK", [2385] = "Shop_set_2_Unit4", [2386] = "CJ_SWEATER_F_1", [2387] = "Shop_set_2_Unit5", 
   [2388] = "CJ_DUDS_RAIL_2", [2389] = "CJ_4_SWEATERS", [2390] = "CJ_4way_clothes", [2391] = "CJ_jean_CREAM", [2392] = "CJ_8_JEANS_MED", 
   [2393] = "CJ_DUDS_RAIL_3", [2394] = "CJ_CLOTHES_STEP_1", [2395] = "CJ_SPORTS_WALL", [2396] = "CJ_4_S_SWEATER", [2397] = "CJ_TRACKIES_dark", 
   [2398] = "CJ_TRACKIES_LIGHT", [2399] = "CJ_4_S_SWEATER_2", [2400] = "CJ_SPORTS_WALL01", [2401] = "CJ_TRACKIES_WHITE", [2402] = "CJ_SPORTS_BAGS", 
   [2403] = "Shop_set_2_SHOE", [2404] = "CJ_SURF_BOARD", [2405] = "CJ_SURF_BOARD2", [2406] = "CJ_SURF_BOARD3", [2407] = "CJ_F_TORSO", 
   [2408] = "CJ_F_LEG_1", [2409] = "CJ_F_LEG_2", [2410] = "CJ_SURF_BOARD4", [2411] = "CJ_F_TORSO_1", [2412] = "CJ_DETECTOR", 
   [2413] = "Shop_counter_3a", [2414] = "Shop_counter_3b", [2415] = "CJ_FF_FRYER", [2416] = "CJ_FF_DISP", [2417] = "CJ_FF_COOKER", 
   [2418] = "CJ_FF_WORKTOP", [2419] = "CJ_FF_WORKTOP_2", [2420] = "CJ_FF_BUCKET", [2421] = "CJ_FF_MICROW", [2422] = "CJ_FF_TILL", 
   [2423] = "CJ_FF_CONTER_1b", [2424] = "CJ_FF_CONTER_1", [2425] = "CJ_FF_JUICE", [2426] = "CJ_FF_PIZZA_OVEN", [2427] = "CJ_FF_JUICE_L", 
   [2428] = "CJ_FF_STAND1", [2429] = "CJ_FF_CUP_DISP", [2430] = "CJ_FF_LIST1", [2431] = "CJ_FF_LIST2", [2432] = "CJ_FF_LIST3", 
   [2433] = "CJ_FF_DISP1", [2434] = "CJ_FF_CONTER_2b", [2435] = "CJ_FF_CONTER_2", [2436] = "CJ_FF_DISP2", [2437] = "CJ_CUP_PILE", 
   [2438] = "CJ_SLUSH_MAC", [2439] = "CJ_FF_CONTER_3", [2440] = "CJ_FF_CONTER_3b", [2441] = "CJ_FF_CONTER_4", [2442] = "CJ_FF_CONTER_4b", 
   [2443] = "CJ_FF_FRIGE", [2444] = "CJ_FF_CONTER_4c", [2445] = "CJ_FF_CONTER_4d", [2446] = "CJ_FF_CONTER_5", [2447] = "CJ_FF_CONTER_5c", 
   [2448] = "CJ_FF_CONTER_5d", [2449] = "CJ_FF_CONTER_5e", [2450] = "CJ_FF_CONTER_5b", [2451] = "CJ_FF_WORKTOP_3", [2452] = "CJ_FF_FRIDGE2", 
   [2453] = "CJ_PIZZA_DISPf", [2454] = "CJ_FF_CONTER_8b", [2455] = "CJ_FF_CONTER_8", [2456] = "CJ_FF_STAND02", [2457] = "CJ_FF_CONTER_8c", 
   [2458] = "CJ_HOBBY_C_3", [2459] = "CJ_HOBBY_C_4", [2460] = "CJ_HOBBY_C_1", [2461] = "CJ_HOBBY_C_2", [2462] = "CJ_HOBBY_SHELF", 
   [2463] = "CJ_HOBBY_SHELF_2", [2464] = "MODEL_BOX1", [2465] = "MODEL_BOX2", [2466] = "MODEL_BOX3", [2467] = "CJ_HOBBY_C_5", 
   [2468] = "MODEL_BOX4", [2469] = "MODEL_PLANES_3", [2470] = "MODEL_PLANES_4", [2471] = "MODEL_TRAINS2", [2472] = "MODEL_PLANES_1", 
   [2473] = "MODEL_PLANES_2", [2474] = "MODEL_TRAINS1", [2475] = "CJ_HOBBY_SHELF_3", [2476] = "MODEL_BOX11", [2477] = "MODEL_BOX5", 
   [2478] = "MODEL_BOX6", [2479] = "MODEL_BOX8", [2480] = "MODEL_BOX9", [2481] = "MODEL_BOX10", [2482] = "CJ_HOBBY_SHELF_4", 
   [2483] = "MODEL_BOX13", [2484] = "MODEL_YAUGHT", [2485] = "MODEL_CAR_1", [2486] = "MODEL_CAR", [2487] = "HOBBY_KITE", 
   [2488] = "MANHUNT_TOY_1", [2489] = "MANHUNT_TOY_2", [2490] = "VICE_TOY_1", [2491] = "MODEL_STAND", [2492] = "MANHUNT_TOY2_1", 
   [2493] = "VICE_TOY2_1", [2494] = "MANHUNT_TOY2_2", [2495] = "VICE_TOY_2", [2496] = "VICE_TOY2_2", [2497] = "HOBBY_KITE2", 
   [2498] = "HOBBY_KITE3", [2499] = "HOBBY_KITE4", [2500] = "CJ_FF_COFFEE", [2501] = "Train_toy_1", [2502] = "CJ_HOBBY_SHELF_5", 
   [2503] = "Train_toy_2", [2504] = "Train_toy_3", [2505] = "MODEL_toy_1", [2506] = "MODEL_toy_2", [2507] = "MODEL_toy_3", 
   [2508] = "MODEL_toy_4", [2509] = "CJ_HOBBY_SHELF_6", [2510] = "MODEL_PLANE_BIG2", [2511] = "MODEL_PLANE_BIG1", [2512] = "MODEL_PLANE_BIG3", 
   [2513] = "MODEL_TRAINS3", [2514] = "CJ_TOILET1", [2515] = "CJ_BS_SINK", [2516] = "CJ_BATH1", [2517] = "CJ_SHOWER1", 
   [2518] = "CJ_B_SINK2", [2519] = "CJ_BATH2", [2520] = "CJ_SHOWER2", [2521] = "CJ_TOILET2", [2522] = "CJ_BATH3", 
   [2523] = "CJ_B_SINK3", [2524] = "CJ_B_SINK4", [2525] = "CJ_TOILET4", [2526] = "CJ_BATH4", [2527] = "CJ_SHOWER4", 
   [2528] = "CJ_TOILET3", [2529] = "CJ_OFF2_LIC_2_L", [2530] = "CJ_OFF2_LIC_2_R", [2531] = "CJ_OFF2_LIC_1_M", [2532] = "CJ_OFF2_LIC_1_R", 
   [2533] = "CJ_OFF2_LIC_1_L", [2534] = "CJ_OFF2_LIC_2_M", [2535] = "CJ_SS_1_M", [2536] = "CJ_SS_1_L", [2537] = "CJ_SS_1_R", 
   [2538] = "CJ_SS_2_R", [2539] = "CJ_SS_2_M", [2540] = "CJ_SS_2_L", [2541] = "CJ_SS_3_M", [2542] = "CJ_SS_3_L", 
   [2543] = "CJ_SS_4_M", [2544] = "CJ_SS_4_L", [2545] = "CJ_SS_4_R", [2546] = "CJ_SS_7_M", [2547] = "CJ_SS_6_R", 
   [2548] = "CJ_SS_6_M", [2549] = "CJ_SS_6_L", [2550] = "CJ_SS_7_R", [2551] = "CJ_SS_7_L", [2552] = "CJ_SS_8_R", 
   [2553] = "CJ_SS_8_L", [2554] = "CJ_SS_8_M", [2555] = "CJ_SS_5_M", [2556] = "CJ_SS_5_L", [2557] = "CJ_SS_5_R", 
   [2558] = "CURTAIN_1_CLOSED", [2559] = "CURTAIN_1_OPEN", [2560] = "CURTAIN_2_OPEN", [2561] = "CURTAIN_2_CLOSED", [2562] = "Hotel_dresser_2", 
   [2563] = "HOTEL_S_BEDSET_1", [2564] = "HOTEL_D_BEDSET_1", [2565] = "HOTEL_D_BEDSET_3", [2566] = "HOTEL_S_BEDSET_3", [2567] = "ab_warehouseShelf", 
   [2568] = "Hotel_dresser_3", [2569] = "Hotel_dresser_1", [2570] = "Hotel_dresser_4", [2571] = "Hotel_SINGLE_1", [2572] = "Hotel_SINGLE_2", 
   [2573] = "Hotel_dresser_6", [2574] = "Hotel_dresser_5", [2575] = "HOTEL_S_BEDSET_8", [2576] = "Hotel_dresser_8", [2577] = "CJ_SEX_COUNTER", 
   [2578] = "CJ_SEX_SHELF_1", [2579] = "CJ_SEX_SHELF_2", [2580] = "SEX_1", [2581] = "CJ_SEX_V_RACK", [2582] = "CJ_SEX_VIDEO_1", 
   [2583] = "CJ_SEX_VIDEO_2", [2584] = "CJ_sex_dildo", [2585] = "CJ_SEX_SHELF_3", [2586] = "CJ_SEX_COUNTER2", [2587] = "SEX_2", 
   [2588] = "SEX_3", [2589] = "ab_carcass", [2590] = "ab_hook", [2591] = "ab_partition1", [2592] = "ab_slotTable", 
   [2593] = "roleplay_rack", [2594] = "roleplay_outfits", [2595] = "CJ_SHOP_TV_VIDEO", [2596] = "CJ_SEX_TV", [2597] = "DILDO_rack1", 
   [2598] = "DILDO_rack2", [2599] = "CJ_SEX_SHOP_SIGN", [2600] = "CJ_VIEW_TELE", [2601] = "CJ_JUICE_CAN", [2602] = "Police_cell_Toilet", 
   [2603] = "Police_Cell_Bed", [2604] = "CJ_POLICE_COUNTER", [2605] = "POLCE_DESK1", [2606] = "CJ_POLICE_COUNTER2", [2607] = "POLCE_DESK2", 
   [2608] = "POLCE_SHELF", [2609] = "CJ_P_FILEING1", [2610] = "CJ_P_FILEING2", [2611] = "POLICE_NB1", [2612] = "POLICE_NB2", 
   [2613] = "POLICE_WASTEBIN", [2614] = "CJ_US_FLAG", [2615] = "POLICE_NB3", [2616] = "POLICE_NB04", [2617] = "Hotel_SINGLE_3", 
   [2618] = "CJ_SLOT_PROPg", [2619] = "mp_ammoambient", [2620] = "CJ_TRAINER_ERIS", [2621] = "CJ_TRAINER_HEAT", [2622] = "CJ_TRAINER_PRO", 
   [2623] = "CJ_PRO_COUNTER", [2624] = "CJ_SHOE_CORNER01", [2625] = "CJ_SHOE_URBAN2", [2626] = "CJ_URB_COUNTER", [2627] = "gym_treadmill", 
   [2628] = "gym_bench2", [2629] = "gym_bench1", [2630] = "gym_bike", [2631] = "gym_mat1", [2632] = "gym_mat02", 
   [2633] = "crack_walkway1", [2634] = "ab_vaultDoor", [2635] = "CJ_PIZZA_TABLE", [2636] = "CJ_PIZZA_CHAIR", [2637] = "CJ_PIZZA_TABLE2", 
   [2638] = "CJ_PIZZA_CHAIR2", [2639] = "CJ_PIZZA_CHAIR3", [2640] = "NEIL_SLOT", [2641] = "CJ_BURGER_POSTER", [2642] = "CJ_BURGER_POSTER2", 
   [2643] = "CJ_BURGER_POSTER3", [2644] = "CJ_BURG_TABLE", [2645] = "CJ_PIZZA_POSTER", [2646] = "CJ_PIZZA_POSTER2", [2647] = "CJ_BS_CUP", 
   [2648] = "CJ_STEAL_TV", [2649] = "CJ_aircon2", [2650] = "CJ_Skate_wall2", [2651] = "CJ_Skate_wall1", [2652] = "CJ_SKATE_CUBES", 
   [2653] = "CJ_aircon3", [2654] = "CJ_shoe_box", [2655] = "CJ_BANNER1", [2656] = "CJ_BANNER02", [2657] = "CJ_BANNER03", 
   [2658] = "CJ_BANNER04", [2659] = "CJ_BANNER05", [2660] = "CJ_BANNER06", [2661] = "CJ_BANNER07", [2662] = "CJ_BANNER08", 
   [2663] = "CJ_BS_BAG", [2664] = "CJ_SUBURB_DOOR", [2665] = "CJ_FF_LIST04", [2666] = "CJ_PIZ_POSTER2", [2667] = "CJ_PIZ_POSTER1", 
   [2668] = "CJ_PIZ_POSTER3", [2669] = "CJ_CHRIS_CRATE", [2670] = "PROC_RUBBISH_1", [2671] = "PROC_RUBBISH_3", [2672] = "PROC_RUBBISH_4", 
   [2673] = "PROC_RUBBISH_5", [2674] = "PROC_RUBBISH_2", [2675] = "PROC_RUBBISH_6", [2676] = "PROC_RUBBISH_8", [2677] = "PROC_RUBBISH_7", 
   [2678] = "CJ_CHRIS_CRATE_LD", [2679] = "CJ_CHRIS_CRATE_RD", [2680] = "CJ_Padlock", [2681] = "CJ_COIN_OP", [2682] = "PIZZA_MENU", 
   [2683] = "PIZZA_S_P", [2684] = "CJ_food_post", [2685] = "CJ_food_post1", [2686] = "CJ_food_post2", [2687] = "CJ_food_post3", 
   [2688] = "CJ_food_post4", [2689] = "CJ_HOODIE_2", [2690] = "CJ_FIRE_EXT", [2691] = "CJ_BANNER09", [2692] = "CJ_BANNER10", 
   [2693] = "CJ_BANNER11", [2694] = "CJ_shoe_box2", [2695] = "CJ_BANNER12", [2696] = "CJ_BANNER13", [2697] = "CJ_BANNER14", 
   [2698] = "CJ_DUDS_RAIL01", [2699] = "CJ_DUDS_RAIL02", [2700] = "CJ_SEX_TV2", [2701] = "CJ_PRO_LIGHT", [2702] = "CJ_PIZZA_1", 
   [2703] = "CJ_BURG_1", [2704] = "CJ_HOODIE_3", [2705] = "CJ_HOODIE_04", [2706] = "CJ_HOODIE_05", [2707] = "CJ_LIGHT_FIT", 
   [2708] = "ZIP_SHELF1", [2709] = "Pain_Killer", [2710] = "WATCH_PICKUP", [2711] = "Tatoo_needle", [2712] = "CJ_MOP", 
   [2713] = "cj_bucket", [2714] = "CJ_OPEN_SIGN_2", [2715] = "CJ_DON_POSTER", [2716] = "CJ_DON_POSTER3", [2717] = "CJ_DON_POSTER2", 
   [2718] = "CJ_FLY_KILLER", [2719] = "CJ_BANNER15", [2720] = "CJ_BANNER16", [2721] = "CJ_BANNER17", [2722] = "CJ_BANNER18", 
   [2723] = "LM_stripStool", [2724] = "LM_stripChair", [2725] = "LM_stripTable", [2726] = "LM_stripLamp", [2727] = "DS_SIGN", 
   [2728] = "DS_BACKLIGHT", [2729] = "CJ_BINC_POST3", [2730] = "CJ_BINC_POST2", [2731] = "CJ_BINC_POST", [2732] = "CJ_ZIP_POST_2", 
   [2733] = "CJ_ZIP_POST_1", [2734] = "CJ_ZIP_POST_3", [2735] = "CJ_ZIP_POST_4", [2736] = "CJ_ZIP_POST_05", [2737] = "POLICE_NB_car", 
   [2738] = "CJ_TOILET_BS", [2739] = "CJ_B_SINK1", [2740] = "cj_bs_light", [2741] = "CJ_SOAP_DISP", [2742] = "CJ_HANDDRIER", 
   [2743] = "CJ_STAT_1", [2744] = "CJ_STAT_2", [2745] = "CJ_STAT_3", [2746] = "CJ_DONUT_CHAIR", [2747] = "CJ_donut_TABLE", 
   [2748] = "CJ_DONUT_CHAIR2", [2749] = "CJ_hairspray", [2750] = "CJ_hair_dryer", [2751] = "CJ_hairsCREAM", [2752] = "CJ_hairspray2", 
   [2753] = "CJ_FF_TILL_que", [2754] = "OTB_machine", [2755] = "Dojo_Wall", [2756] = "CJ_S1_base", [2757] = "CJ_S1_Larm", 
   [2758] = "CJ_S1_Rarm", [2759] = "CJ_S1_Head", [2760] = "CJ_S1_torso", [2761] = "CJ_S1_legs", [2762] = "CJ_CHICK_TABLE", 
   [2763] = "CJ_CHICK_TABLE_2", [2764] = "CJ_PIZZA_TABLE03", [2765] = "CJ_CB_LIST1", [2766] = "CJ_CB_LIST2", [2767] = "CJ_CB_TRAY", 
   [2768] = "CJ_CB_BURG", [2769] = "CJ_CJ_BURG2", [2770] = "CJ_CB_BIN", [2771] = "CJ_OTB_TILL_Q", [2772] = "CJ_esculator", 
   [2773] = "CJ_AIRPRT_BAR", [2774] = "CJ_AIRP_PILLARS", [2775] = "CJ_AIRPRT_MON", [2776] = "LEE_stripCHAIR2", [2777] = "LEE_stripCHAIR1", 
   [2778] = "CJ_COIN_OP_1", [2779] = "CJ_COIN_OP_2", [2780] = "CJ_SMOKE_MACH", [2781] = "CJ_AIR_TICKET", [2782] = "CJ_OYSTER_2", 
   [2783] = "cj_bandit_6", [2784] = "ab_slotTable6", [2785] = "CJ_SLOT_BANK", [2788] = "CJ_BURG_CHAIR", [2789] = "CJ_DEPART_BOARD", 
   [2790] = "CJ_ARRIVE_BOARD", [2791] = "CJ_index_BOARD", [2792] = "CJ_AIR_D_1", [2793] = "CJ_AIR_D_2", [2794] = "CJ_AIR_D_3", 
   [2795] = "CJ_AIR_D_4", [2796] = "CJ_AIR_D_6", [2797] = "CJ_AIR_D_5", [2798] = "CJ_EX_PEDALS", [2799] = "castable2", 
   [2800] = "castable2top", [2801] = "castable1top", [2802] = "castable1", [2803] = "CJ_MEAT_BAG_1", [2804] = "CJ_MEAT_1", 
   [2805] = "CJ_MEAT_BAG_2", [2806] = "CJ_MEAT_2", [2807] = "CJ_BURG_CHAIR_NA", [2808] = "CJ_PIZZA_CHAIR4", [2809] = "CJ_STAT_1_BIT", 
   [2810] = "CJ_STAT_2_bit", [2811] = "GB_romanpot01", [2812] = "GB_platedirty01", [2813] = "GB_novels01", [2814] = "GB_takeaway01", 
   [2815] = "gb_livingrug01", [2816] = "gb_bedmags01", [2817] = "gb_bedrug01", [2818] = "gb_bedrug02", [2819] = "gb_bedclothes01", 
   [2820] = "GB_kitchdirt01", [2821] = "gb_foodwrap01", [2822] = "GB_kitchplatecln01", [2823] = "gb_kitchtakeway01", [2824] = "GB_novels02", 
   [2825] = "GB_novels03", [2826] = "GB_novels04", [2827] = "GB_novels05", [2828] = "gb_ornament02", [2829] = "GB_platedirty02", 
   [2830] = "GB_platedirty04", [2831] = "GB_platedirty03", [2832] = "GB_platedirty05", [2833] = "gb_livingrug02", [2834] = "gb_livingrug03", 
   [2835] = "gb_livingrug04", [2836] = "gb_livingrug05", [2837] = "GB_takeaway02", [2838] = "GB_takeaway03", [2839] = "GB_takeaway04", 
   [2840] = "GB_takeaway05", [2841] = "gb_bedrug03", [2842] = "gb_bedrug04", [2843] = "gb_bedclothes02", [2844] = "gb_bedclothes03", 
   [2845] = "gb_bedclothes04", [2846] = "gb_bedclothes05", [2847] = "gb_bedrug05", [2848] = "GB_kitchdirt02", [2849] = "GB_kitchdirt03", 
   [2850] = "GB_kitchdirt04", [2851] = "GB_kitchdirt05", [2852] = "gb_bedmags02", [2853] = "gb_bedmags03", [2854] = "gb_bedmags04", 
   [2855] = "gb_bedmags05", [2856] = "gb_foodwrap02", [2857] = "gb_kitchtakeway02", [2858] = "gb_kitchtakeway03", [2859] = "gb_kitchtakeway04", 
   [2860] = "gb_kitchtakeway05", [2861] = "gb_foodwrap03", [2862] = "GB_kitchplatecln02", [2863] = "GB_kitchplatecln03", [2864] = "GB_kitchplatecln04", 
   [2865] = "GB_kitchplatecln05", [2866] = "gb_foodwrap04", [2867] = "gb_foodwrap05", [2868] = "gb_ornament03", [2869] = "gb_ornament04", 
   [2870] = "gb_ornament05", [2871] = "CJ_SS_3_R", [2872] = "CJ_COIN_OP_3", [2873] = "CJ_SUBURB_DOOR_2", [2874] = "CJ_SLUSH_CUPDUM", 
   [2875] = "CJ_GAP_DOOR_", [2876] = "CJ_PRO_DOOR_01", [2877] = "CJ_BINCO_DOOR", [2878] = "CJ_Victim_DOOR", [2879] = "CJ_DS_DOOR", 
   [2880] = "CJ_BURG_2", [2881] = "CJ_PIZZA_2", [2882] = "Object01", [2885] = "xref_garagedoor", [2886] = "sec_keypad", 
   [2887] = "a51_spotbulb", [2888] = "a51_spothousing", [2889] = "a51_spotbase", [2890] = "kmb_skip", [2891] = "kmb_packet", 
   [2892] = "temp_stinger", [2893] = "kmb_ramp", [2894] = "kmb_rhymesbook", [2895] = "fun_flower_law", [2896] = "casket_law", 
   [2897] = "funtarp_law", [2898] = "funturf_law", [2899] = "temp_stinger2", [2900] = "temp_cardbox", [2901] = "kmb_marijuana", 
   [2902] = "kmb_smokecan", [2903] = "kmb_parachute", [2904] = "warehouse_door1", [2905] = "kmb_deadleg", [2906] = "kmb_deadarm", 
   [2907] = "kmb_deadtorso", [2908] = "kmb_deadhead", [2909] = "kmb_frontgate", [2910] = "temp_road", [2911] = "kmb_petroldoor", 
   [2912] = "temp_crate1", [2913] = "kmb_bpress", [2914] = "kmb_rcflag", [2915] = "kmb_dumbbell2", [2916] = "kmb_dumbbell", 
   [2917] = "a51_crane", [2918] = "kmb_mine", [2919] = "kmb_holdall", [2920] = "police_barrier", [2921] = "kmb_cam", 
   [2922] = "kmb_keypad", [2923] = "bottle_bank", [2924] = "kmb_crash3door", [2925] = "dyno_box_B", [2926] = "dyno_box_A", 
   [2927] = "a51_blastdoorR", [2928] = "a51_intdoor", [2929] = "a51_blastdoorL", [2930] = "chinaTgate", [2931] = "kmb_jump1", 
   [2932] = "kmb_container_blue", [2933] = "pol_comp_gate", [2934] = "kmb_container_red", [2935] = "kmb_container_yel", [2936] = "kmb_rock", 
   [2937] = "kmb_plank", [2938] = "shutter_vegas", [2939] = "ramp_bot", [2940] = "ramp_top", [2941] = "temp_till", 
   [2942] = "kmb_atm1", [2943] = "kmb_atm2", [2944] = "freight_SFW_door", [2945] = "kmb_netting", [2946] = "cr_door_03", 
   [2947] = "cr_door_01", [2948] = "cr_door_02", [2949] = "kmb_lockeddoor", [2950] = "BREAK_WALL_2A", [2951] = "a51_labdoor", 
   [2952] = "kmb_gimpdoor", [2953] = "kmb_paper_code", [2954] = "kmb_ot", [2955] = "imy_compin", [2956] = "immmcran", 
   [2957] = "chinaTgarageDoor", [2958] = "cutscene_beer", [2959] = "rider1_door", [2960] = "kmb_beam", [2961] = "fire_break", 
   [2962] = "fire_break_glass", [2963] = "freezer_door", [2964] = "k_pooltablesm", [2965] = "k_pooltriangle01", [2966] = "mobile1993b", 
   [2967] = "mobile1993a", [2968] = "cm_box", [2969] = "level_ammobox", [2970] = "dts_bbdoor", [2971] = "k_smashboxes", 
   [2972] = "k_cargo4", [2973] = "k_cargo2", [2974] = "k_cargo1", [2975] = "k_cargo3", [2976] = "green_gloop", 
   [2977] = "kmilitary_crate", [2978] = "kmilitary_base", [2979] = "reel02", [2980] = "kb_bandit10", [2981] = "reel03", 
   [2982] = "reel01", [2983] = "will_valve", [2984] = "portaloo", [2985] = "minigun_base", [2986] = "lxr_motelvent", 
   [2987] = "lxr_motel_doorsim", [2988] = "comp_wood_gate", [2989] = "imy_skylight", [2990] = "wongs_gate", [2991] = "imy_bbox", 
   [2992] = "roulette_marker", [2993] = "kmb_goflag", [2994] = "kmb_trolley", [2995] = "k_poolballstp01", [2996] = "k_poolballstp02", 
   [2997] = "k_poolballstp03", [2998] = "k_poolballstp04", [2999] = "k_poolballstp05", [3000] = "k_poolballstp06", [3001] = "k_poolballstp07", 
   [3002] = "k_poolballspt01", [3003] = "k_poolballcue", [3004] = "k_poolq2", [3005] = "smash_box_stay", [3006] = "smash_box_brk", 
   [3007] = "chopcop_torso", [3008] = "chopcop_armR", [3009] = "chopcop_armL", [3010] = "chopcop_legR", [3011] = "chopcop_legL", 
   [3012] = "chopcop_head", [3013] = "cr_ammobox", [3014] = "cr_guncrate", [3015] = "cr_cratestack", [3016] = "cr_ammobox_nonbrk", 
   [3017] = "arch_plans", [3018] = "target_rleg", [3019] = "target_lleg", [3020] = "target_ltorso", [3021] = "target_rtorso", 
   [3022] = "target_rarm", [3023] = "target_larm", [3024] = "target_head", [3025] = "target_frame", [3026] = "para_pack", 
   [3027] = "ciggy", [3028] = "Katana_LHand", [3029] = "cr1_door", [3030] = "wongs_erection", [3031] = "wong_dish", 
   [3032] = "bd_window_shatter", [3033] = "md_lockdoor", [3034] = "bd_window", [3035] = "tmp_bin", [3036] = "ct_gatexr", 
   [3037] = "warehouse_door2b", [3038] = "ct_lanterns", [3039] = "ct_stall1", [3040] = "ct_stall2", [3041] = "ct_table", 
   [3042] = "ct_vent", [3043] = "kmb_container_open", [3044] = "CIGAR", [3045] = "CIGAR_glow", [3046] = "kb_barrel", 
   [3047] = "jet_baggage_Door", [3048] = "cement_in_hole", [3049] = "des_quarrygate", [3050] = "des_quarrygate2", [3051] = "lift_dr", 
   [3052] = "db_ammo", [3053] = "INDUS_MAGNET", [3054] = "DYN_WREKING_BALL", [3055] = "kmb_shutter", [3056] = "mini_magnet", 
   [3057] = "kb_barrel_exp", [3058] = "storm_drain_cover", [3059] = "imy_shash_wall", [3060] = "para_collision", [3061] = "ad_flatdoor", 
   [3062] = "container_door", [3063] = "BREAK_WALL_3A", [3064] = "BREAK_WALL_1A", [3065] = "BBALL_col", [3066] = "ammotrn_obj", 
   [3067] = "kmb_atm3", [3068] = "cargo_rear", [3069] = "d9_ramp", [3070] = "kmb_goggles", [3071] = "kmb_dumbbell_R", 
   [3072] = "kmb_dumbbell_L", [3073] = "kmb_container_broke", [3074] = "d9_runway", [3075] = "impexp_door", [3076] = "ad_roadmark1", 
   [3077] = "nf_blackboard", [3078] = "ad_finish", [3079] = "ad_roadmark2", [3080] = "ad_jump", [3081] = "fake_mule_col", 
   [3082] = "ammo_capsule", [3083] = "md_poster", [3084] = "trdcsgrgdoor_lvs", [3085] = "nf_list_1", [3086] = "wanted_cross_off", 
   [3087] = "nf_list_2", [3088] = "nf_list_3", [3089] = "ab_casdorLok", [3090] = "nf_ped_coll", [3091] = "imy_track_barrier", 
   [3092] = "dead_tied_cop", [3093] = "cuntgirldoor", [3094] = "k_pooltableb", [3095] = "a51_jetdoor", [3096] = "bb_pickup", 
   [3097] = "BREAK_WALL_2B", [3098] = "BREAK_WALL_1B", [3099] = "BREAK_WALL_3B", [3100] = "k_poolballspt02", [3101] = "k_poolballspt03", 
   [3102] = "k_poolballspt04", [3103] = "k_poolballspt05", [3104] = "k_poolballspt06", [3105] = "k_poolballspt07", [3106] = "k_poolball8", 
   [3107] = "wongs_erection2", [3108] = "basejump_target", [3109] = "imy_la_door", [3110] = "md_billbolaeb", [3111] = "st_arch_plan", 
   [3112] = "TriMainLite", [3113] = "CARRIER_DOOR_SFSE", [3114] = "CARRIER_LIFT2_SFSE", [3115] = "CARRIER_LIFT1_SFSE", [3116] = "acwinch1", 
   [3117] = "a51_ventcoverb", [3119] = "cs_ry_props", [3120] = "BBALL_ingame", [3121] = "munch_donut", [3122] = "k_poolq", 
   [3123] = "Katana_Anim", [3124] = "Sniper_Anim", [3125] = "Wd_Fence_Anim", [3126] = "TATTOO_KIT", [3127] = "BD_Fire1_o", 
   [3128] = "BBALL_Net", [3129] = "Smlplane_door", [3130] = "MTSafe", [3131] = "PARACHUTE", [3132] = "jet_door", 
   [3133] = "pedals", [3134] = "quarry_barrel", [3135] = "cat2_safe_col", [3167] = "trailer_large1_01", [3168] = "trailer2_01", 
   [3169] = "trailer_large2_01", [3170] = "trailer_large3_01", [3171] = "trailer5_01", [3172] = "trailer6_01", [3173] = "trailer_large4_01", 
   [3174] = "sm_airstrm_sml_", [3175] = "sm_airstrm_med_", [3178] = "Shack02", [3187] = "nt_gasstation", [3193] = "st5base", 
   [3214] = "quarry_crusher", [3221] = "drv_in_spkrs", [3241] = "conhoos2", [3242] = "conhoos1", [3243] = "tepee_room_", 
   [3244] = "pylon_big1_", [3246] = "des_westrn7_", [3249] = "des_westsaloon_", [3250] = "des_westrn9_", [3252] = "des_oldwattwr_", 
   [3253] = "des_westrn11_", [3255] = "ref_oiltank01", [3256] = "refchimny01", [3257] = "refinerybox1", [3258] = "refthinchim1", 
   [3259] = "refcondens1", [3260] = "oldwoodpanel", [3261] = "grasshouse", [3262] = "privatesign1", [3263] = "privatesign2", 
   [3264] = "privatesign3", [3265] = "privatesign4", [3267] = "mil_samsite", [3268] = "mil_hangar1_", [3269] = "bonyrd_block1_", 
   [3270] = "bonyrd_block2_", [3271] = "bonyrd_block3_", [3272] = "substa_transf1_", [3273] = "substa_transf2_", [3274] = "substa_grid_", 
   [3275] = "cxreffence", [3276] = "cxreffencesld", [3277] = "mil_sambase", [3278] = "des_warewin", [3279] = "a51_spottower", 
   [3280] = "a51_panel", [3281] = "mtb_banner1", [3282] = "cxreffencemsh", [3283] = "conhoos3", [3284] = "conhoos5", 
   [3285] = "conhoos4", [3286] = "cxrf_watertwr", [3287] = "cxrf_oiltank", [3292] = "cxf_payspray_", [3293] = "des_payspint", 
   [3294] = "cxf_spraydoor1", [3302] = "cxrf_corpanel", [3303] = "des_bighus03", [3304] = "des_bighus02", [3305] = "des_bighus01", 
   [3306] = "swburbhaus02", [3307] = "swburbhaus01", [3308] = "swburbhaus03", [3309] = "swburbhaus04", [3310] = "sw_woodhaus04", 
   [3311] = "sw_woodhaus01a", [3312] = "sw_woodhaus02", [3313] = "sw_woodhaus03", [3314] = "sw_bigburb_04", [3315] = "sw_bigburb_03", 
   [3316] = "sw_bigburb_02", [3317] = "sw_bigburb_01", [3330] = "cxrf_brigleg", [3331] = "cxrf_whitebrig", [3334] = "BIG_COCK_SIGN", 
   [3335] = "CE_roadsign1", [3336] = "cxrf_frway1sig", [3337] = "cxrf_desertsig", [3350] = "torino_mic", [3351] = "sw_bigburbsave", 
   [3352] = "burbdoorRENAME_ME", [3353] = "sw_bigburbsave2", [3354] = "burbdoor2REF", [3355] = "cxrf_savhus1_", [3356] = "cxrf_savhus2_", 
   [3359] = "cxrf_savhusgar1_", [3361] = "cxref_woodstair", [3362] = "des_ruin2_", [3363] = "des_ruin1_", [3364] = "des_ruin3_", 
   [3374] = "SW_haybreak02", [3375] = "CE_dblbarn01", [3378] = "CE_beerpile01", [3379] = "CE_hairpinR", [3380] = "CE_hairpinL", 
   [3381] = "cxrf_redarch", [3383] = "a51_labtable1_", [3384] = "a51_halbox_", [3385] = "a51_light1_", [3386] = "a51_srack2_", 
   [3387] = "a51_srack3_", [3388] = "a51_srack4_", [3389] = "a51_srack1_", [3390] = "a51_sdsk_ncol1_", [3391] = "a51_sdsk_ncol2_", 
   [3392] = "a51_sdsk_ncol3_", [3393] = "a51_sdsk_ncol4_", [3394] = "a51_sdsk_2_", [3395] = "a51_sdsk_3_", [3396] = "a51_sdsk_4_", 
   [3397] = "a51_sdsk_1_", [3398] = "cxrf_floodlite_", [3399] = "cxrf_a51_stairs", [3400] = "cxrf_a51sect", [3401] = "cxrf_a51sect2", 
   [3402] = "sw_tempbarn01", [3403] = "sw_logcover", [3406] = "cxref_woodjetty", [3407] = "CE_mailbox1", [3408] = "CE_mailbox2", 
   [3409] = "grassplant", [3410] = "cxrf_Aldea", [3411] = "cunteRB01", [3412] = "cunteRB03", [3414] = "CE_oldhut1", 
   [3415] = "CE_loghut1", [3417] = "CE_loghut02", [3418] = "CE_oldhut02", [3419] = "CE_logbarn02", [3425] = "nt_windmill", 
   [3426] = "nt_noddonkbase", [3427] = "derrick01", [3428] = "oilplodbitbase", [3430] = "vegasbooth01", [3431] = "vgsclubox01", 
   [3432] = "htlcnpy02_lvs", [3433] = "htlcnpy01_lvs", [3434] = "skllsgn01_lvs", [3435] = "motel01sgn_lvs", [3436] = "motel03_lvs", 
   [3437] = "ballypllr01_lvs", [3438] = "ballyring01_lvs", [3439] = "aprtree01_lvs", [3440] = "arptpillar01_lvs", [3441] = "luxorpillar02_lvs", 
   [3442] = "vegasxrexhse1", [3443] = "vegasxrexhse2", [3444] = "shabbyhouse02_lvs", [3445] = "vegasxrexhse08", [3446] = "vegasxrexhse10", 
   [3447] = "vgstlgraphpole", [3448] = "shamcprkin", [3449] = "vegashsenew1", [3450] = "vegashseplot1", [3451] = "vegashsenew2", 
   [3452] = "bballintvgn1", [3453] = "bballintvgn2", [3454] = "vgnhseing15", [3455] = "vgnhseblk1", [3456] = "vgnhseblk3", 
   [3457] = "vgnhseblk2", [3458] = "vgncarshade1", [3459] = "vgntelepole1", [3460] = "vegaslampost", [3461] = "tikitorch01_lvs", 
   [3462] = "csrangel_lvs", [3463] = "vegaslampost2", [3464] = "shabbyhouse03_lvs", [3465] = "vegspetrolpump", [3466] = "shabbyhouse01_lvs", 
   [3467] = "vegstreetsign1", [3468] = "vegstreetsign2", [3469] = "vegenmotel1", [3470] = "vegasaircon1", [3471] = "vgschinalion1", 
   [3472] = "circuslampost03", [3473] = "vegenmotel12", [3474] = "Freightcrane1", [3475] = "vgsn_fncelec_pst", [3483] = "vegasxrexhse09", 
   [3484] = "vegasxrexhse03", [3485] = "vegasxrexhse04", [3486] = "vegasxrexhse05", [3487] = "vegasxrexhse06", [3488] = "vegasxrexhse07", 
   [3489] = "HANGAR1_08_LVS", [3491] = "vegasS_hanger2", [3493] = "vgsn_carpark01", [3494] = "luxorpillar04_lvs", [3496] = "vgsxrefbballnet", 
   [3497] = "vgsxrefbballnet2", [3498] = "wdpillar01_lvs", [3499] = "wdpillar02_lvs", [3501] = "vgsxrefpartm1", [3502] = "vgsN_con_tube", 
   [3503] = "vgsNscffple", [3504] = "vgsN_portaloo", [3505] = "VgsN_nitree_y01", [3506] = "VgsN_nitree_y02", [3507] = "VgsN_nitree_g01", 
   [3508] = "VgsN_nitree_g02", [3509] = "VgsN_nitree_r01", [3510] = "VgsN_nitree_r02", [3511] = "VgsN_nitree_b01", [3512] = "VgsN_nitree_b02", 
   [3513] = "vgs_roadsign1", [3514] = "vgs_roadsign02", [3515] = "vgsfountain", [3516] = "vgsstriptlights1", [3517] = "ceasertree02_lvs", 
   [3518] = "vgsN_rooflity", [3519] = "vgsN_rooflitb", [3520] = "vgsN_flwrbdsm", [3521] = "vgsn_RBStiff", [3522] = "vgsn_flwbdcrb", 
   [3524] = "skullpillar01_lvs", [3525] = "exbrtorch01", [3526] = "vegasairportlight", [3528] = "vgsEdragon", [3529] = "vgsN_constrbeam", 
   [3530] = "vgsN_constrbeam2", [3531] = "trdflwrbedq", [3532] = "triadbush", [3533] = "trdpillar01", [3534] = "trdlamp01", 
   [3550] = "vgsn_fncelec_msh", [3554] = "visagesign04", [3555] = "compmedhos2_LAe", [3556] = "compmedhos3_LAe", [3557] = "compmedhos4_LAe", 
   [3558] = "compmedhos5_LAe", [3564] = "lastran1_LA01", [3565] = "lasdkrt1_LA01", [3566] = "lasntrk1", [3567] = "lasnfltrail", 
   [3568] = "lasntrk2", [3569] = "lasntrk3", [3570] = "lasdkrt2", [3571] = "lasdkrt3", [3572] = "lasdkrt4", 
   [3573] = "lasdkrtgrp1", [3574] = "lasdkrtgrp2", [3575] = "lasdkrt05", [3576] = "DockCrates2_LA", [3577] = "DockCrates1_LA", 
   [3578] = "DockBarr1_LA", [3580] = "compbigho2_LAe", [3582] = "compmedhos1_LAe", [3583] = "compbigho3_LAe", [3584] = "compproj01_LA", 
   [3585] = "lastran1_LA02", [3586] = "escl_LA", [3587] = "nwsnpedhus1_LAS", [3588] = "sanped_hse1_LAs", [3589] = "compfukhouse3", 
   [3590] = "compfukhouse2", [3593] = "la_fuckcar2", [3594] = "la_fuckcar1", [3595] = "Dingbat01Aex_LA", [3596] = "Dingbat02Aex_LA", 
   [3597] = "Dingbat01Bex_LA", [3598] = "hillhouse01_LA", [3599] = "hillhouse02_LA", [3600] = "hillhouse06_LA", [3601] = "hillhouse04_LA", 
   [3602] = "hillhouse05_LA", [3603] = "bevman_LAW2", [3604] = "bevmangar_LAW2", [3605] = "bevman3_LAW2", [3606] = "bevbrkhus1", 
   [3607] = "bevman2_LAW2", [3608] = "hillhouse08_LA", [3609] = "hillhouse13_LA", [3612] = "hillhouse12_LA", [3613] = "hillhouse10_LA", 
   [3614] = "hillhouse09_LA", [3615] = "sanmonbhut1_LAW2", [3616] = "midranhus2_LAS", [3617] = "midranhus_LAS", [3618] = "nwlaw2husjm3_Law2", 
   [3619] = "nwlaw2husjm4_Law2", [3620] = "redockrane_LAS", [3621] = "rbigcrate_LAS", [3622] = "rdwarhus", [3623] = "rdwarhus2", 
   [3624] = "nwwarhus", [3625] = "crgostntrmp", [3626] = "dckwrkhut", [3627] = "dckcanpy", [3628] = "smallprosjmt_LAS", 
   [3629] = "arhang_LAS", [3630] = "crdboxes2_LAs", [3631] = "oilcrat_LAS", [3632] = "imoildrum_LAS", [3633] = "imoildrum4_LAS", 
   [3634] = "nwccumphus1_LAS", [3635] = "nwccumphus2_LAS", [3636] = "indust1las_LAS", [3637] = "indust1las2_LAS", [3638] = "elecstionv_LAS", 
   [3639] = "GlenPHouse01_LAx", [3640] = "GlenPHouse02_LAx", [3641] = "GlenPHouse04_LAx", [3642] = "GlenPHouse03_LAx", [3643] = "LA_chem_piping", 
   [3644] = "idlebuild01_LAx", [3646] = "ganghous05_LAx", [3648] = "ganghous02_LAx", [3649] = "ganghous01_LAx", [3651] = "ganghous04_LAx", 
   [3653] = "BeachApartA1_LAx", [3655] = "ganghous03_LAx", [3657] = "airseata_LAS", [3658] = "airlastrola_LAS", [3659] = "airfinfoa_LAS", 
   [3660] = "lasairfbed_LAS", [3661] = "projects01_LAx", [3663] = "lasstepsa_LAS", [3664] = "lasblastde_LAS", [3665] = "airyelrm_LAS", 
   [3666] = "airuntest_las", [3671] = "centuBal01_LAx", [3673] = "laxrf_refinerybase", [3674] = "laxrf_refineryalpha", [3675] = "laxrf_refinerypipe", 
   [3676] = "lawnhouseredA", [3677] = "lawnhousegreyLS", [3678] = "lawnhousegreyRS", [3684] = "Lawnapartmnt", [3689] = "rdwarhusbig", 
   [3694] = "ryder_holes", [3697] = "project2lae2", [3698] = "barrio3B_LAe", [3700] = "DrugDealHs1_LAe", [3702] = "barrio6B_LAe2", 
   [3704] = "barrio6a_LAe2", [3707] = "rdwarhusmed", [3711] = "BeachApartA5b", [3713] = "BeachApartA5a", [3715] = "Arch_sign", 
   [3717] = "sanclifbal1_LAx", [3722] = "laxrf_scrapbox", [3724] = "laxrf_cargotop", [3741] = "CEhillhse14", [3743] = "escl_SingleLA", 
   [3749] = "ClubGate01_LAx", [3752] = "ferseat01_LAx", [3753] = "dockwall_LAS2", [3754] = "lamotsig1_LA", [3755] = "las2warhus_las2", 
   [3757] = "lamotsig2_LA", [3759] = "vencanhou01_LAx", [3761] = "industshelves", [3762] = "CEnwlaw4", [3763] = "CE_radarmast3", 
   [3764] = "TCEnewhillhus02", [3765] = "TCEmulhouse04_Law01", [3771] = "CEhillhse14_alpha", [3776] = "ci_bstage", [3781] = "Lan2officeflrs", 
   [3783] = "LAs2Xref01_LAx", [3785] = "bulkheadlight", [3786] = "missile_05_SFXR", [3787] = "missile_02_SFXR", [3788] = "missile_03_SFXR", 
   [3789] = "missile_09_SFXR", [3790] = "missile_01_SFXR", [3791] = "missile_10_SFXR", [3792] = "missile_08_SFXR", [3793] = "missile_06_SFXR", 
   [3794] = "missile_07_SFXR", [3795] = "missile_04_SFXR", [3796] = "acbox1_SFS", [3797] = "missile_11_SFXR", [3798] = "acbox3_SFS", 
   [3799] = "acbox2_SFS", [3800] = "acbox4_SFS", [3801] = "sfx_lite04", [3802] = "sfx_plant03", [3803] = "sfx_alarms03", 
   [3804] = "sfxref_aircon11", [3805] = "sfxref_aircon12", [3806] = "sfx_winplant07", [3807] = "sfx_flag02", [3808] = "sfx_alarms04", 
   [3809] = "sfx_lite05", [3810] = "sfx_plant04", [3811] = "sfx_winplant08", [3812] = "sfxref_aircon13", [3813] = "sfxref_aircon14", 
   [3814] = "hangar1_SFXREF", [3816] = "bighangar1_SFx", [3818] = "sf_frwaysig", [3819] = "bleacher_SFSx", [3820] = "box_hse_09_SFXRF", 
   [3821] = "box_hse_02_SFXRF", [3822] = "box_hse_03_SFXRF", [3823] = "box_hse_11_SFXRF", [3824] = "box_hse_10_SFXRF", [3825] = "box_hse_01_SFXRF", 
   [3826] = "box_hse_06_SFXRF", [3827] = "box_hse_07_SFXRF", [3828] = "box_hse_05_SFXRF", [3829] = "box_hse_04_SFXRF", [3830] = "box_hse_08_SFXRF", 
   [3842] = "box_hse_14_SFXRF", [3843] = "box_hse_12_SFXRF", [3844] = "box_hse_15_SFXRF", [3845] = "box_hse_13_SFXRF", [3850] = "carshowbann_SFSX", 
   [3851] = "carshowwin_SFSX", [3852] = "sf_jump", [3853] = "Gay_lamppost", [3854] = "GAY_telgrphpole", [3855] = "GAY_TRAFFIC_LIGHT", 
   [3856] = "sf_frwaysig_half", [3857] = "ottosmash3", [3858] = "ottosmash1", [3859] = "ottosmash04", [3860] = "marketstall04_SFXRF", 
   [3861] = "marketstall01_SFXRF", [3862] = "marketstall02_SFXRF", [3863] = "marketstall03_SFXRF", [3864] = "WS_floodlight", [3865] = "concpipe_SFXRF", 
   [3866] = "demolish1_SFXRF", [3867] = "ws_scaffolding_SFX", [3872] = "WS_floodbeams", [3873] = "Silicon04_SFS", [3875] = "SFtelepole", 
   [3876] = "sf_roofmast", [3877] = "sf_rooflite", [3878] = "headstones_SFSx", [3879] = "ws_jetty_SFX", [3881] = "airsecbooth_SFSe", 
   [3882] = "airsecboothint_SFSe", [3884] = "samsite_SFXRF", [3885] = "sambase_SFXRF", [3886] = "ws_jettynol_SFX", [3887] = "demolish4_SFXRF", 
   [3890] = "lib_street09", [3891] = "lib_street08", [3892] = "lib_street10", [3893] = "lib_street05", [3894] = "lib_street11", 
   [3895] = "lib_street14", [3897] = "lib_street03", [3898] = "lib_street15", [3899] = "lib_street04", [3900] = "lib_street12", 
   [3902] = "lib_street16", [3903] = "lib_street07", [3905] = "lib_street02", [3906] = "lib_street01", [3907] = "lib_street06", 
   [3910] = "trackshad05", [3911] = "lib_street13", [3914] = "snowover02", [3915] = "snowover03", [3916] = "snowover04", 
   [3917] = "lib_street17", [3918] = "snowover01", [3919] = "lib_main_bistrotop", [3920] = "lib_veg3", [3921] = "lib_counchs", 
   [3922] = "rest_chair2", [3923] = "libstreetfar", [3924] = "playroom", [3925] = "bridge_1", [3926] = "d_sign", 
   [3927] = "d_sign01", [3928] = "helipad", [3929] = "d_rock", [3930] = "d_rock01", [3931] = "d_rock02", 
   [3932] = "hanger", [3933] = "fake_sky", [3934] = "helipad01", [3935] = "statue", [3936] = "bwire_fence", 
   [3937] = "bwire_fence01", [3938] = "rczero4_base01", [3939] = "hanger01", [3940] = "comms01", [3941] = "comms02", 
   [3942] = "bistrobar", [3943] = "mid_staircase", [3944] = "bistro_blok", [3945] = "alpha_fence", [3946] = "plants01", 
   [3947] = "rc_track_a", [3948] = "bistrogarden", [3949] = "rc_track_b", [3950] = "rc_zero_c", [3951] = "rc_water", 
   [3952] = "rc_track_d", [3953] = "rc_track_e", [3954] = "rc_track_f", [3955] = "rc_track_g", [3956] = "rc_track_h", 
   [3957] = "rc_track_i", [3958] = "warehooseboxes", [3959] = "rczero_alpha", [3960] = "rczero4_base02", [3961] = "Boxkitch", 
   [3962] = "lee_Plane07", [3963] = "lee_Plane08", [3964] = "lee_Plane09", [3965] = "lee_Object11", [3966] = "lee_object01", 
   [3967] = "AIRPORT_int2", [3968] = "AIRPORT_FRONT", [3969] = "BAG_BELT2", [3970] = "CJ_CUSTOM_BAR", [3971] = "CJ_BAG_RECLAIM", 
   [3972] = "mon1", [3973] = "CJ_BAG_DET", [3975] = "PoliceSt01_LAn", [3976] = "PoliceSt02_LAn", [3977] = "LAriverSec1_LAn", 
   [3978] = "LAriverSec3_LAn", [3979] = "bonaventura_LAn", [3980] = "LAcityhall1_LAn", [3981] = "LAriverSec4a_LAn", [3982] = "LAriverSec5a_LAn", 
   [3983] = "peublomiss2_LAn", [3984] = "churchprog1_LAn", [3985] = "PershingSq1_LAn", [3986] = "mis1_LAn", [3987] = "fightplaza2_LAn", 
   [3988] = "cityhallblock2_LAn", [3989] = "bonaplazagr_LAn", [3990] = "GSFreeway6_LAn", [3991] = "GSFreeway7_LAn", [3992] = "Roads03_LAn", 
   [3993] = "Roads04_LAn", [3994] = "Roads06_LAn", [3995] = "Roads07_LAn", [3996] = "Roads08_LAn", [3997] = "cityhallblok_LAn", 
   [3998] = "court1_LAn", [4000] = "twintjail2_LAn", [4001] = "BailBonds1_LAn", [4002] = "LAcityhall2_LAn", [4003] = "LAcityhallTrans_LAn", 
   [4004] = "LAcityhall3_LAn", [4005] = "decoblok2_LAn", [4006] = "eastcolumb1_LAn", [4007] = "wellsfargo1_LAn", [4008] = "decoblok1_LAn", 
   [4010] = "figfree1_LAn", [4011] = "figfree2_LAn", [4012] = "TermAnexGrd1_LAn", [4013] = "bonavenBase_LAn", [4014] = "bonaplaza_LAn", 
   [4015] = "bonaventuraGL_LAn", [4016] = "fighotbase_LAn", [4017] = "offblokA_LAn", [4018] = "newbuildsm02", [4019] = "newbuildsm01", 
   [4020] = "fighotblok1_LAn", [4021] = "Officessml1_lan", [4022] = "Foodmart1_lan", [4023] = "newdbbuild_lan04", [4027] = "langrasspatch", 
   [4028] = "lanstap", [4029] = "LAriverSec5b_LAn", [4030] = "LAriverSec4b_LAn", [4032] = "carimp_LAn", [4033] = "fightplaza1_LAn", 
   [4034] = "fightplaza1tra_LAn", [4048] = "LAcityhall4_LAn", [4058] = "fighotblok2_LAn", [4059] = "fighotblok3_LAn", [4060] = "fighotblok4_LAn", 
   [4079] = "twintjail1_LAn", [4084] = "JUD_LAN", [4085] = "supports01_LAn", [4086] = "supports02_LAn", [4087] = "supports03_LAn", 
   [4088] = "supports04_LAn", [4089] = "supports05_LAn", [4090] = "supports06_LAn", [4091] = "supports07_LAn", [4099] = "twintjailfence_LAn", 
   [4100] = "meshfence1_LAn", [4101] = "expo_LAn", [4102] = "expoalpha_LAn", [4103] = "staples_LAn", [4106] = "shpfireesc_LAn", 
   [4107] = "Roads01_LAn", [4108] = "Roads01b_LAn", [4109] = "LAriverSec5_LAn", [4110] = "Lan_embank1", [4112] = "build01_LAn", 
   [4113] = "LanOfficeBlok1", [4114] = "lanBlocknew2", [4117] = "figfree3_LAn", [4120] = "LAn_fescalpha1", [4121] = "LAn_fescalpha02", 
   [4122] = "ctyhllblk2land_LAn", [4123] = "cityhallblock1_LAn", [4125] = "GSFreeway1_LAn", [4127] = "GSFreeway2_LAn", [4128] = "GSFreeway3_LAn", 
   [4129] = "GSFreeway4_LAn", [4131] = "GSFreeway5_LAn", [4133] = "GSFreeway8_LAn", [4139] = "Roads09_LAn", [4141] = "Hotelexterior1_LAn", 
   [4142] = "Roads10_LAn", [4144] = "Roads11_LAn", [4146] = "Roads12_LAn", [4148] = "Roads13_LAn", [4150] = "Roads14_LAn", 
   [4152] = "Roads15_LAn", [4154] = "Roads16_LAn", [4156] = "Roads17_LAn", [4158] = "Roads18_LAn", [4160] = "Roads19_LAn", 
   [4163] = "Roads24_LAn", [4165] = "Roads21_LAn", [4168] = "Roads23_LAn", [4170] = "LAn_fescalpha04", [4171] = "LAn_fescalpha05", 
   [4172] = "plantbeds1_LAn01", [4173] = "plantbeds1_LAn02", [4174] = "plantbeds1_LAn04", [4175] = "plantbeds1_LAn05", [4176] = "BailBonds2_LAn", 
   [4178] = "BailBonds3_LAn", [4180] = "LAn_fescalpha06", [4182] = "Roads22_LAn", [4183] = "expoalpha_LAn02", [4184] = "hotelferns2_LAn", 
   [4185] = "hotelferns3_LAn", [4186] = "PershingSq2_LAn", [4188] = "bventuraENV_LAn", [4189] = "twintjail1alpha_LAn", [4190] = "SDfences1_LAn", 
   [4192] = "PoliceStalphas_LAn", [4193] = "officeblok1_Lan", [4195] = "SDfences2_LAn", [4196] = "SDfences3_LAn", [4197] = "LAnAlley1_LAn", 
   [4198] = "LAriverSec3b_LAn", [4199] = "garages1_LAn", [4201] = "SDfences4_LAn", [4202] = "SDfences5_LAn", [4203] = "LAriverSec1b_LAn", 
   [4205] = "wefargoalphas_LAn", [4206] = "PershingPool_LAn", [4207] = "Roads02_LAn", [4209] = "Roads20_LAn", [4212] = "lanitewin1_LAN", 
   [4213] = "lanitewin1_LAN03", [4214] = "lanitewin3_LAN", [4215] = "lanitewin4_LAN", [4216] = "lanitewin5_LAN", [4217] = "lanitewin6_LAN", 
   [4218] = "lanitewin7_LAN", [4219] = "lanitewin8_LAN", [4220] = "lanitewin9_LAN", [4221] = "lanitewin91_LAN", [4222] = "lanitewin92_LAN", 
   [4227] = "graffiti_lan01", [4230] = "billbrdlan_08", [4231] = "LAn_fescalpha03", [4232] = "carimp2_LAn", [4233] = "Roads05_LAn", 
   [4235] = "billbrdlan_03", [4238] = "billbrdlan_10", [4239] = "billbrdlan_11", [4240] = "sbsbedlaw2", [4241] = "sbsbed4law2", 
   [4242] = "sbsbed5law2", [4243] = "sbsbed8law2", [4244] = "sbsbed9law2", [4245] = "sbsbed1law2", [4246] = "sbsbed3law2", 
   [4247] = "sbsbed6law2", [4248] = "sbsbed7law2", [4249] = "sbsbed91law2", [4250] = "sbcne_seafloor01", [4251] = "sbcne_seafloor02", 
   [4252] = "sbcne_seafloor03", [4253] = "sbcne_seafloor05", [4254] = "sbCE_groundPALO09", [4255] = "sbcne_seafloor04", [4256] = "sbcne_seafloor06", 
   [4257] = "sbseabed_sfe03", [4258] = "sbseabed_sfe05", [4259] = "sbseabed_sfe01", [4260] = "sbseabed_sfe69", [4261] = "sbseabed_SFN02", 
   [4262] = "sbseabed_SFN03", [4263] = "sbseabed_SFNcunt", [4264] = "sbseabed1_SFW", [4265] = "sbseabed2_SFW", [4266] = "sbseabed6_SFW", 
   [4267] = "sbseabed2_las2", [4268] = "sbseabed3_las20", [4269] = "sbseabed1_las2", [4270] = "sbseabed5_las2", [4271] = "sbseabed6las2", 
   [4272] = "sbseabed8_las2", [4273] = "sbseabed7_las2", [4274] = "sbseabed86_las2", [4275] = "sbseabed9_las20", [4276] = "sbseabed91_las2", 
   [4277] = "sbseabed93_LAS", [4278] = "sbseabed92_LAS", [4279] = "sbseabed94_LAS", [4280] = "sbseabed95_LAS", [4281] = "sbseabed96_LAS", 
   [4282] = "sbseabed97_LAS", [4283] = "sbseabed99_LAS", [4284] = "sbseabed98_LAS", [4285] = "sbseabed81_LAS", [4286] = "sbseabed85_LAS", 
   [4287] = "sbseabed84_LAS", [4288] = "sbseabed83_LAS", [4289] = "sbseabed82_LAS", [4290] = "sbcs_landbit_46", [4291] = "sbcs_landbit_54", 
   [4292] = "sbcs_landbit_63", [4293] = "sbcs_landbit_72", [4294] = "sbcs_landbit_77", [4295] = "sbcs_landbit_78", [4296] = "sbcs_seabit_new", 
   [4297] = "sbcs_seabit1_new", [4298] = "sbcs_seabit2_new", [4299] = "sbcs_seabit3_new", [4300] = "sbcs_seabit4_new", [4301] = "sbcs_seabit5_new", 
   [4302] = "sbcs_seabit6_new", [4303] = "sbcs_seabit7_new", [4304] = "sbcs_seabit8_new", [4305] = "sbcs_seabit9_new", [4306] = "sbcs_seabit11_new", 
   [4307] = "sbcs_seabit10_new", [4308] = "sbcs_seabit12_new", [4309] = "sbcs_seabit13_new", [4310] = "sbcs_seabit14_new", [4311] = "sbcs_seabit15_new", 
   [4312] = "sbcs_seabit16_new", [4313] = "sbcs_seabit17_new", [4314] = "sbseabed_CN01", [4315] = "sbseabed_CN03", [4316] = "sbseabed_CN04", 
   [4317] = "sbcn_seafloor03", [4318] = "sbcn_seafloor04", [4319] = "sbcn_seafloor01", [4320] = "sbcn_seafloor05", [4321] = "sbcn_seafloor06", 
   [4322] = "sbcn_seafloor07", [4323] = "sbxseabed_CN02", [4324] = "sbxseabed_CN05", [4325] = "sbxseabed_CN06", [4326] = "sbxseabed_CN07", 
   [4327] = "sbcn_seafloor08", [4328] = "sbcn_seafloor09", [4329] = "sbcn_seafloor10", [4330] = "sbcn2_seafloor01", [4331] = "sbcn2_seafloor02", 
   [4332] = "sbcn2_seafloor03", [4333] = "sbcn2_seafloor04", [4334] = "sbvgsEseafloor03", [4335] = "sbseabed_05_SFSe", [4336] = "sbseabed_10_SFSe", 
   [4337] = "sbseabed_09_SFSe", [4338] = "sbseabed_08_SFSe", [4339] = "sbseabed_07_SFSe", [4340] = "sbseabed_11_SFSe", [4341] = "sbseabed_03_SFSe", 
   [4342] = "sbseabed_02_SFSe", [4343] = "sbseabed_01_SFSe", [4344] = "sbseabed01_LAW", [4345] = "sbvgsSseafloor05", [4346] = "sbvgsSseafloor04", 
   [4347] = "sbcw_seabed01", [4348] = "sbcw_seabed02", [4349] = "sbcw_seabed03", [4350] = "sbcw_seabed04", [4351] = "sbcw_seabed05", 
   [4352] = "sbcw_seabed06", [4353] = "sbcuntwland27b", [4354] = "sbcuntwland28b", [4355] = "sbcuntwland30b", [4356] = "sbcuntwland43b", 
   [4357] = "sbcuntwland44b", [4358] = "sbcuntwland28bb", [4359] = "sbcuntwland30bb", [4360] = "sbObject01", [4361] = "sbObject02", 
   [4362] = "sbObject03", [4363] = "sbObject04", [4364] = "sbObject05", [4365] = "sbObject06", [4366] = "sbObject07", 
   [4367] = "sbObject08", [4368] = "sbObject09", [4369] = "sbObject10", [4370] = "sbObject11", [4371] = "sbObject12", 
   [4372] = "beach04_sv", [4373] = "sv_roadscoast01", [4374] = "beach04b_sv", [4504] = "cuntw_roadblockld", [4505] = "cuntw_roadblock01ld", 
   [4506] = "cuntw_roadblock02ld", [4507] = "cuntw_roadblock03ld", [4508] = "cuntw_roadblock04ld", [4509] = "cuntw_roadblock05ld", [4510] = "sfw_roadblock1ld", 
   [4511] = "sfw_roadblock2ld", [4512] = "sfw_roadblock3ld", [4513] = "sfn_roadblockld", [4514] = "cn2_roadblock01ld", [4515] = "cn2_roadblock02ld", 
   [4516] = "cn2_roadblock03ld", [4517] = "cn2_roadblock04ld", [4518] = "CE_Makospan1ld", [4519] = "CE_Fredbarld", [4520] = "CE_Fredbar01ld", 
   [4521] = "CE_Flintwat01ld", [4522] = "CE_Flintintld", [4523] = "sfse_roadblock1", [4524] = "sfse_roadblock3", [4525] = "sfse_roadblock4", 
   [4526] = "sfse_roadblock5", [4527] = "sfse_roadblock2", [4533] = "sbseabed_SFN03bb", [4535] = "sbseabed_SFN01", [4538] = "sbCE_grndPALCST05", 
   [4540] = "sbcn_seafloor02", [4550] = "LibrTow1_LAn", [4551] = "LAriverSec2_LAn", [4552] = "amubloksun1_LAn", [4553] = "road12_LAn2", 
   [4554] = "LibBase1_LAn", [4555] = "figfree4_LAn", [4556] = "sky4plaz1_LAn", [4557] = "road10_LAn2", [4558] = "LacmEntr1_LAn", 
   [4559] = "LacmaBase1_LAn", [4560] = "LacmCanop1_LAn", [4562] = "LAplaza2_LAn", [4563] = "LAskyscrap1_LAn", [4564] = "LAskyscrap2_LAn", 
   [4565] = "bunksteps1_LAn", [4567] = "road07_LAn2", [4568] = "ground01_LAn2", [4569] = "stolenbuilds05", [4570] = "stolenbuilds08", 
   [4571] = "stolenbuilds09", [4572] = "stolenbuilds11", [4573] = "stolenbuilds12", [4574] = "stolenbuilds13", [4575] = "fireescapes1_lan2", 
   [4576] = "lan2newbuild1", [4584] = "halgroundlan2", [4585] = "towerlan2", [4586] = "skyscrapn201", [4587] = "skyscrapn203", 
   [4588] = "roofshitlan2", [4589] = "road15_LAn2", [4590] = "grasspatchlan2", [4591] = "lan2shit03", [4592] = "lan2shit04", 
   [4593] = "lan2buildblk01", [4594] = "lan2buildblk02", [4595] = "cpark05_LAN2", [4596] = "cspGM_LAN2", [4597] = "crprkblok4_LAN2", 
   [4598] = "crprkblok2_LAN2", [4599] = "csp2GM_LAN2", [4600] = "LAdtbuild10_LAn", [4601] = "LAn2_gm1", [4602] = "LAskyscrap4_LAn", 
   [4603] = "sky4plaz2_LAn", [4604] = "build4plaz_LAn2", [4605] = "skyscrapn203_gls", [4636] = "cparkgmaumk_LAN", [4637] = "cpark_muck_lan2", 
   [4638] = "paypark_lan01", [4639] = "paypark_lan02", [4640] = "paypark_lan03", [4641] = "paypark_lan04", [4642] = "paypark_lan", 
   [4643] = "LAplaza2b_LAn2", [4644] = "road06_LAn2", [4645] = "road14_LAn2", [4646] = "road13_LAn2", [4647] = "road11_LAn2", 
   [4648] = "road05_LAn2", [4649] = "road01_LAn2", [4650] = "road02_LAn2", [4651] = "road03_LAn2", [4652] = "road04_LAn2", 
   [4653] = "Freeway7_LAn2", [4654] = "road09_LAn2", [4656] = "Freeway1_LAn2", [4658] = "Freeway2_LAn2", [4660] = "Freeway3_LAn2", 
   [4662] = "Freeway4_LAn2", [4664] = "Freeway5_LAn2", [4666] = "Freeway6_LAn2", [4679] = "Freeway8_LAn2", [4681] = "LAdtbuild6_LAn2", 
   [4682] = "LAdtbuild3_LAn2", [4683] = "LAdtbuild2_LAn2", [4684] = "LAalley1_LAn2", [4685] = "LAalley2_LAn2", [4690] = "skyscrapn202", 
   [4691] = "csp3GM_LAN2", [4692] = "Freeway9_LAn2", [4694] = "Freeway10_LAn2", [4695] = "Freeway11_LAn2", [4697] = "crprkblok1_LAN2", 
   [4700] = "cpark01_LAN2", [4701] = "cpark02_LAN2", [4702] = "cpark03_LAN2", [4703] = "cpark04_LAN2", [4708] = "LAdtbuild1_LAn2", 
   [4710] = "road08_LAn2", [4711] = "amublokalpha_LAn2", [4712] = "LibPlaza1_LAn", [4714] = "Lacmaalphas1_LAn", [4715] = "LTSLAsky1_LAn2", 
   [4716] = "LTSLAsky2_LAn2", [4717] = "LTSLAsky3_LAn2", [4718] = "gm_build4_LAn2", [4720] = "LTSLAsky1b_LAn", [4721] = "LTSLAsky2b_LAn2", 
   [4722] = "LTSLAsky3b_LAn2", [4723] = "LTSLAsky4_LAn2", [4724] = "librarywall_lan2", [4725] = "LTSLAsky6_LAn2", [4726] = "libtwrhelipd_LAn2", 
   [4727] = "libtwrhelipda_LAn2", [4729] = "billbrdlan2_01", [4730] = "billbrdlan2_03", [4731] = "billbrdlan2_05", [4732] = "billbrdlan2_06", 
   [4733] = "billbrdlan2_07", [4734] = "billbrdlan2_08", [4735] = "billbrdlan2_09", [4736] = "billbrdlan2_10", [4737] = "fireescapes3_lan2", 
   [4738] = "fireescapes2_lan2", [4739] = "LTSLAbuild1_LAn2", [4740] = "LTSLAbuild2_LAn2", [4741] = "LTSLAbuild3_LAn2", [4742] = "LTSLAbuild4_LAn2", 
   [4743] = "LTSLAsky5_LAn2", [4744] = "LTSLAbuild5_LAn2", [4745] = "LTSLAbuild6_LAn2", [4746] = "LTSLAsky7_LAn2", [4747] = "LTSLAsky8_LAn2", 
   [4748] = "LTSLAbuild7_LAn2", [4749] = "LTSLAbuild8_LAn2", [4750] = "LTSLAbuild9_LAn2", [4751] = "LTSLAbuild10_LAn2", [4752] = "LTSLAbuild11_LAn2", 
   [4806] = "BTOLAND8_LAS", [4807] = "LAroads_20gh_LAs", [4808] = "LAroadss_30_LAs", [4809] = "LAroads_05_LAs", [4810] = "hillpalos04_LAs", 
   [4811] = "clifftest02", [4812] = "clifftest05", [4813] = "clifftest07", [4814] = "clifftest09", [4815] = "clifftestgrnd2", 
   [4816] = "ROCKLIFF1_LAS", [4817] = "TRNTRK7_LAS", [4818] = "TRNTRK8_LAS", [4819] = "TRNTRK5_LAS", [4820] = "BTOLAND1_LAS", 
   [4821] = "BTOLAND2_LAS", [4822] = "NWCSTRD1_LAS", [4823] = "lasgrifroad", [4824] = "lasgrifsteps2", [4825] = "griffithoblas", 
   [4826] = "grifftop2", [4827] = "LAroads_20ghi_LAs", [4828] = "lasairprt5", [4829] = "lasairprt4", [4830] = "lasairprt3", 
   [4831] = "airpurt2_las", [4832] = "airtwer_Las", [4833] = "airpurtder_las", [4834] = "airoad1d_LAS", [4835] = "airoad1b_LAS", 
   [4836] = "LAroadsx_04_LAs", [4837] = "LApedhusrea_LAs", [4838] = "airpurtderfr_las", [4839] = "bchcostrd3_LAS", [4840] = "bchcostrd4_LAS", 
   [4841] = "bchcostrd1_LAS", [4842] = "Beach1_LAs0fg", [4843] = "Beach1_LAs0fhy", [4844] = "Beach1_LAs04", [4845] = "hillpalos02_LAs", 
   [4846] = "LAcityped1_LAs", [4847] = "Beach1_LAs0gj", [4848] = "sanpedbeaut", [4849] = "snpdmshfnc3_LAS", [4850] = "snpedshpblk07", 
   [4851] = "hillpalos01_LAs", [4852] = "hillpalos03_LAs", [4853] = "traincano_LAS", [4854] = "lasundrairprt2", [4855] = "lasundrairprt1", 
   [4856] = "lasundrairprt3", [4857] = "snpedmtsp1_LAS", [4858] = "snpedland1_LAS", [4859] = "snpedland2_LAS", [4860] = "unionstwar_LAS", 
   [4861] = "snpedhuair2_LAS", [4862] = "airtun2_LAS", [4863] = "airtun1_LAS", [4864] = "airtun3_LAS", [4865] = "lasrnway2_LAS", 
   [4866] = "lasrnway1_LAS", [4867] = "lasrnway3_LAS", [4868] = "LAroads_23_LAs", [4869] = "lasrnway8_LAS", [4870] = "airpurt2ax_las", 
   [4871] = "airpurt2bx_las", [4872] = "LAroads_042e_LAs", [4873] = "unionstwarc2_LAS", [4874] = "Helipad1_las", [4875] = "hillpalos06_LAs", 
   [4876] = "hillpalos08_LAs", [4877] = "dwntwnbit4_LAS", [4878] = "obcity1_LAS", [4879] = "hillpaloswal1_LAs", [4880] = "dwntwnbit2_LAS", 
   [4881] = "uninstps_LAS01", [4882] = "lasbrid1_LAS", [4883] = "bchcostair_LAS", [4884] = "lastranentun1_LAS", [4885] = "lastranentun4_LAS", 
   [4886] = "gngspwnhus1_LAS", [4887] = "dwntwnbit1_LAS", [4888] = "dwntwnbit3_LAS", [4889] = "dwntwnbit2b_LAS", [4890] = "lasairprterm2_LAS", 
   [4891] = "billboard_LAS", [4892] = "kbsgarage2_LAS", [4894] = "dwntwnbit1b_LAS", [4895] = "lstrud_LAS", [4896] = "clifftest12", 
   [4897] = "Beach1a1_LAs", [4898] = "clifftestgrnd", [4981] = "snpedteew1_LAS", [4982] = "snpedteew3_LAS", [4983] = "snpedteew1vv_LAS", 
   [4984] = "snpedteew3gt_LAS", [4985] = "Cylinder03", [4986] = "odfwer_LAS", [4988] = "lasbillbrd1_las", [4990] = "airprtwlkto1_LAS", 
   [4991] = "lasairprterm1_LAS", [4992] = "airplants_LAS", [4993] = "airplnt2_LAS", [4994] = "airbillb_LAS", [4995] = "airsinage_LAS", 
   [4996] = "airsinage2_LAS", [4997] = "airsinage3_LAS", [4998] = "airsinage4_LAS", [4999] = "airsinage6_LAS", [5000] = "airsinage5_LAS", 
   [5001] = "lasrunwall2_LAS", [5002] = "lasrnway4_LAS", [5003] = "lasrnway5_LAS", [5004] = "lasrnway6_LAS", [5005] = "lasrunwall1_LAS", 
   [5006] = "airprtwlkto2_LAS", [5007] = "lasrunwall3_LAS", [5009] = "lasrnway7_LAS", [5013] = "LAroakt1_30_LAs", [5016] = "snpdPESS1_LAS", 
   [5017] = "lastripx1_LAS", [5020] = "mul_LAS", [5021] = "LAroadsbrk_05_LAs", [5023] = "grifovrhang2_LAS", [5024] = "snpedtee_LAS", 
   [5025] = "snpedtedc_LAS", [5026] = "lstrudct1_LAS", [5028] = "obcity1ct1_LAS", [5030] = "lasrunwall1ct_LAS", [5031] = "snpedteairt_LAS", 
   [5032] = "las_runsigns_LAS", [5033] = "unmainstat_LAS", [5034] = "lasairprtcut4", [5036] = "BTOLAND1ct_LAS", [5038] = "airtun2ct_LAS", 
   [5040] = "unionliq_LAS", [5042] = "bombshop_LAs", [5043] = "bombdoor_LAs", [5044] = "las_runsignsx_LAS", [5046] = "bchcostrd4fuk_LAS", 
   [5051] = "airobarsjm_LAS", [5052] = "BTOROAD1vb_LAS", [5056] = "modLAS", [5057] = "lanitewin1_LAS", [5058] = "lanitewin2_LAS", 
   [5059] = "lanitewin3_LAS", [5060] = "crlsafhus_LAS", [5061] = "lascarl", [5062] = "hillpawfnce_LAs", [5064] = "TRNTRK5z_LAS", 
   [5066] = "mondoshave_LAS", [5068] = "airctsjm1_las", [5069] = "ctscene1_las", [5070] = "sjmctfnce1_las", [5071] = "sjmctfnce2_las", 
   [5072] = "sjmctfnce3_las", [5073] = "sjmctfnce4_las", [5074] = "sjmctfnce5_las", [5075] = "sjmctfnce6_las", [5076] = "sjmctfnce7_las", 
   [5077] = "sjmctfnce8_las", [5078] = "ctscene2_las", [5079] = "sjmbarct1_LAS", [5080] = "sjmbarct2_LAS", [5081] = "rdcrashbar1_LAs", 
   [5082] = "rdcrashbar2_LAs", [5083] = "alphbrk1_las", [5084] = "alphbrk2_las", [5086] = "alphbrk3_las", [5087] = "alphbrk4_las", 
   [5088] = "alphbrk5_las", [5089] = "alphbrk6_las", [5105] = "Stordralas2", [5106] = "Roadsbx_las2", [5107] = "chemplant2_las2", 
   [5108] = "LADocks2_las2", [5109] = "sanpdmdock3_las2", [5110] = "mexcrnershp2_las2", [5111] = "IndusLand2_las2", [5112] = "LAroads_26_las2", 
   [5113] = "BlockAA_las2", [5114] = "Beach1_las2", [5115] = "las2chemdock1", [5116] = "las2stripbar1", [5117] = "TRNTRK4_las2", 
   [5118] = "TRNTRK3_las2", [5119] = "TRNTRK4A_las2", [5120] = "BTOROAD3_las2", [5121] = "BTOLAND6_las2", [5122] = "BTOLAND5_las2", 
   [5123] = "NEWCOMP2_las2", [5124] = "NWCSTRD2_las2", [5125] = "NWCSTRD3_las2", [5126] = "dockcranescale0", [5127] = "imcomp1trk", 
   [5128] = "BTOROAD1mnk_las2", [5129] = "imracompint_las2", [5130] = "imcompstrs02", [5131] = "imrancomp1_las2", [5132] = "las2dkwar107", 
   [5133] = "bchcostrd6_las2", [5134] = "snpedshprk_las2", [5135] = "brkwrhus02", [5136] = "snpedshprk1_las2", [5137] = "brkwrhus3_las2", 
   [5138] = "snpdoldwrhs2_las2", [5139] = "sanpedro4_las2", [5140] = "snpedtatshp", [5141] = "BTOROADxtra_las2", [5142] = "las2plaza1bit", 
   [5143] = "las2chendock04", [5144] = "las2jmscum11", [5145] = "sanpdmdock2_las2", [5146] = "sanpdmdock1_las2", [5147] = "sanpedbigbrid_las2", 
   [5148] = "bigstormbrid_las2", [5149] = "scumest1_las2", [5150] = "SCUMWIRES1_las2", [5151] = "carganghud_las2", [5152] = "stuntramp1_las2", 
   [5153] = "stuntramp7_las2", [5154] = "dk_cargoshp03d", [5155] = "dk_cargoshp05d", [5156] = "dk_cargoshp24d", [5157] = "dk_cargoshpd25d", 
   [5158] = "dk_cargoshp76d", [5160] = "dkcargohull2d", [5166] = "dkcargohull2bd", [5167] = "dkcargohull2cd", [5168] = "cluckinbell1_las2", 
   [5169] = "imnrmpy1_las2", [5170] = "imnrmpy2_las2", [5171] = "dockoff01_LAs2", [5172] = "Beach1spt_las2", [5173] = "las2jmscum12", 
   [5174] = "sanpedmexq4_las2", [5175] = "sanpedmexq3_las2", [5176] = "sanpdmdocka_las2", [5177] = "las2stripsshp1", [5178] = "cutrdn1_las2", 
   [5179] = "mexcrnershp_las2", [5180] = "nwspltbild2_las2", [5181] = "nwspltbild3_las2", [5182] = "nwspltbild4_las2", [5183] = "nwspltbild1_las2", 
   [5184] = "mdock1a_las2", [5185] = "brkwrhusfuk_las2", [5186] = "nwsnpdnw_las2", [5187] = "mexcrnrxc_las2", [5188] = "nwrrdssplt_las2", 
   [5189] = "ctddwwnblk_las2", [5190] = "scrapfnce_las2", [5191] = "nwdkbridd_las2", [5192] = "chemgrnd_las2", [5231] = "snpedteew2_las2", 
   [5232] = "snpedteew9_las2", [5233] = "snpedteew8_las2", [5234] = "SCUMWFIRES1_las20", [5243] = "RiverBridls_las2", [5244] = "lasntrk1im03", 
   [5250] = "bchcostrd6v_las2", [5259] = "las2dkwar01", [5260] = "las2dkwar02", [5261] = "las2dkwar03", [5262] = "las2dkwar04", 
   [5265] = "SCUMWFIRES1_las01", [5266] = "snpedteew8_las01", [5267] = "sanpedmexq1_las2", [5268] = "imracompral_las2", [5269] = "las2dkwar05", 
   [5270] = "StormDraifr1_las2", [5271] = "LAroads_24_las2", [5272] = "TRNTRK2_las2", [5273] = "BTOLAND4_las2", [5274] = "StormDraifr2_las2", 
   [5275] = "TRNTRK4A_las201", [5276] = "NEWCOMPRD_las2", [5277] = "NEWCMPTRK_las2", [5278] = "NEWCOMP1_las2", [5279] = "nwsnpdgrnd1_las2", 
   [5290] = "SCUMWIRES1_las03", [5291] = "snpedscrsap_las01", [5292] = "snpedteew8_las03", [5293] = "snpedteew8_las04", [5294] = "snpedteew8_las05", 
   [5295] = "snpedteew8_las06", [5296] = "LAroads_26a_las01", [5297] = "LAroads_26b_las01", [5298] = "bigstormbridb_las2", [5299] = "las2_brigtower", 
   [5301] = "balcony_kbolt01", [5302] = "burg_lkupdoor", [5306] = "chemfence_las2", [5308] = "balcony_kbolt02", [5309] = "las2lnew3_las2", 
   [5310] = "las2lnew2_las2", [5311] = "las2lnew1_las2", [5312] = "snpedteevbg_las2", [5313] = "newlas2sh_LAS2", [5314] = "NEWCOMfuk_las2", 
   [5322] = "stormd_fill1_LAS2", [5323] = "dockfenceq_las2", [5324] = "dockfencew_las2", [5325] = "dockfencee_las2", [5326] = "dockfencer_las2", 
   [5327] = "stormful2_LAS2", [5328] = "stormful2s_LAS2", [5329] = "BTOROADsp3_las2", [5330] = "BTOROAsp2_las2", [5333] = "sanpedbigslt_las2", 
   [5337] = "induswire1_las2", [5338] = "Beach1fnce_las2", [5339] = "Bealpha1_las2", [5340] = "modlas2", [5341] = "crlsafhus_LAS2", 
   [5342] = "BTOLAND5m_las2", [5343] = "BTOLAND5n_las2", [5347] = "TRNTRK3p_las2", [5349] = "BTOLAND6q_las2", [5351] = "snpedteew8_las07", 
   [5353] = "NWCSTRD4_las2", [5355] = "Stordrablas2", [5358] = "las2jmscumTR12", [5363] = "NWCSTRtr_las2", [5364] = "NEWCOMtr_las2", 
   [5366] = "alphbrk1_las2", [5367] = "alphbrk2_las2", [5368] = "alphbrk3_las2", [5369] = "alphbrk4_las2", [5370] = "alphbrk5_las2", 
   [5371] = "alphbrk6_las2", [5372] = "alphbrk7_las2", [5373] = "alphbrk8_las2", [5374] = "alphbrk9_las2", [5375] = "alphbrk91_las2", 
   [5390] = "laeskateparkLA", [5391] = "laeroad01", [5392] = "laestripmall1", [5393] = "laeshop1", [5394] = "xstpdnam_LAE", 
   [5395] = "laecomptonbrij3", [5396] = "laeRailBrijBlok", [5397] = "laeclubBlock1", [5398] = "laetraintunn02", [5399] = "laetraintunn01", 
   [5400] = "laeskatetube1", [5401] = "laegarages1nw", [5402] = "laehospground1", [5403] = "laehospital1", [5404] = "laestormdrain01", 
   [5405] = "laeBlakWesTran2", [5406] = "laecrackmotel4", [5407] = "laelasruff201", [5408] = "laeexaminerbuild1", [5409] = "laepetrol1a", 
   [5410] = "laecumpstreet", [5411] = "laeroadsblk", [5412] = "laelasjmscubit", [5413] = "laecrackmotel1", [5414] = "laeJeffers02", 
   [5415] = "laeskateparkTrans", [5416] = "laeganghous205", [5417] = "laenwblk2", [5418] = "lae711block01", [5419] = "laestormdrain02", 
   [5420] = "laestormdrain03", [5421] = "laesmokeshse", [5422] = "laespraydoor1", [5423] = "laeJeffers03", [5424] = "laeJeffers04", 
   [5425] = "laeJeffers05", [5426] = "laeJeffers06", [5427] = "laeJeffers09", [5428] = "laeJeffers10", [5429] = "xwhattfk_LAE", 
   [5430] = "laeIdlewood11", [5431] = "laeroad02", [5432] = "laeroad03", [5433] = "laeroad04", [5434] = "laeroad05", 
   [5435] = "laeroad06", [5436] = "fukxroad07", [5437] = "laeroad08", [5438] = "laeroad09", [5439] = "laeroad10", 
   [5440] = "laeroad11", [5441] = "laeroad12", [5442] = "laeroad13", [5443] = "laeGlenPark02", [5444] = "laeChicano02", 
   [5445] = "laeChicano01", [5446] = "laeChicano03", [5447] = "laeChicano04", [5448] = "laeChicano05", [5449] = "laeChicanoTr1", 
   [5450] = "laeChicano06", [5451] = "laeChicano07", [5452] = "laeChicano09", [5453] = "laeChicano10", [5456] = "laeroad14", 
   [5457] = "laeGlenPark01", [5458] = "laeMacPark01", [5459] = "laeJeffers01", [5461] = "laeGlenPark05", [5462] = "laeGlenPark04", 
   [5463] = "laebuildsit01", [5464] = "laeGlenPark04Tr", [5465] = "laeGlenPark05Nt", [5467] = "laehospitalTr", [5469] = "laeRoads11Tr", 
   [5470] = "laeRoads10Tr", [5471] = "laeIdlewood01", [5472] = "frecrsbrid_LAE", [5473] = "laeidlebrijTr", [5474] = "laeIdlewood02", 
   [5475] = "laeIdleProj02", [5476] = "laeIdleProj01", [5477] = "laerailtrack1", [5478] = "laerailtrack2", [5479] = "laerailtrack3", 
   [5480] = "laerailtrack4", [5481] = "laebridge", [5482] = "laeroad16", [5483] = "laeroad17", [5484] = "laeroad18", 
   [5485] = "laeroad20", [5486] = "laeroad21", [5487] = "laeroad22", [5488] = "laeroad23", [5489] = "laeroad24", 
   [5490] = "laeroad25", [5491] = "laeroad26", [5492] = "laeroad27", [5493] = "laeroad28", [5494] = "laeroad29", 
   [5495] = "laeroad30", [5496] = "laeroad31", [5497] = "laeroad32", [5498] = "laeroad33", [5499] = "laeroad34", 
   [5500] = "laeroad35", [5501] = "laeroad36", [5502] = "laeroad37", [5503] = "laeroad38", [5504] = "laeroad39", 
   [5505] = "laeroad40", [5506] = "laeroad41", [5507] = "laeroad42", [5508] = "laeroad43", [5509] = "laeroad44", 
   [5510] = "laeroad45", [5511] = "laeroad46", [5512] = "laeroad47", [5513] = "laerail6", [5518] = "Idlewood05_LAe", 
   [5519] = "Idlewood04_LAe", [5520] = "BDupsHouse_LAe", [5521] = "Idlewofuk06_LAe", [5522] = "Idlewood06Tr_LAe", [5528] = "laeroadct43", 
   [5532] = "laesprayshop", [5565] = "laectru_LAE", [5624] = "laeHillsctst03", [5626] = "laecompmedhos518", [5627] = "lasbrid1SJM_LAe", 
   [5628] = "laenwblkB1", [5629] = "LAEalpha6", [5630] = "blockalphalae", [5631] = "apartmntalpha", [5632] = "motelalpha", 
   [5633] = "LAEalpha1", [5634] = "LAEalpha2", [5635] = "LAEalpha3", [5636] = "LAEalpha4", [5637] = "LAEalpha5", 
   [5638] = "LAEalpha7", [5639] = "LAEdirtapha", [5640] = "laemacpark02", [5641] = "LAEalpha5b", [5642] = "laeChicano11", 
   [5643] = "laeChicano08", [5644] = "laebuildsit01a", [5650] = "laeroad03b", [5652] = "stormdraindrt1_LAe", [5654] = "laeJeffers06alphas", 
   [5655] = "laeChicano01b", [5656] = "laeChicano01c", [5660] = "laeskateP_alphas", [5661] = "LTSlaehospital1", [5662] = "LTSlaeChicano02", 
   [5663] = "graffiti01_lae", [5665] = "LTSlaeGlenPark04", [5668] = "laebridgeb", [5674] = "laerailtrack2b", [5676] = "Motel2laealphas", 
   [5677] = "laeJeffersalpha", [5678] = "Lae_smokecutscene", [5679] = "laetraintunn03", [5681] = "carwashalphas_lae", [5682] = "laeJeffers10alphas", 
   [5703] = "road_lawn23", [5704] = "archwindshop_laW", [5705] = "filmstud1", [5706] = "studiobld03_laW", [5707] = "road_lawn03", 
   [5708] = "hospital_law", [5709] = "shop03_laW01", [5710] = "cem01_law", [5711] = "cem02_law", [5712] = "cemint01_law", 
   [5713] = "grave01_law", [5714] = "grave03_law", [5715] = "grave08_law", [5716] = "manns01_LAwN", [5717] = "Sunset20_LAwN", 
   [5718] = "sunset16_LAwN", [5719] = "holbuild01_law", [5720] = "holbuild02_law", [5721] = "holbuild04_law", [5722] = "manns05_LAwN", 
   [5723] = "manns04_LAwN", [5724] = "holsign03n_law", [5725] = "holpacific2_law", [5726] = "Lawn_holbuild21", [5727] = "holbuild10_law", 
   [5728] = "dummybuild46_law", [5729] = "MelBlok02_LAwN", [5730] = "MelBlok03_LAwN", [5731] = "MelBlok05_LAwN", [5732] = "donut01_LAwN", 
   [5733] = "melrose07_law", [5734] = "melrose09_law", [5735] = "studoff_law", [5736] = "studoff02_law", [5737] = "archshop07_laW02", 
   [5738] = "hothol02_law01", [5739] = "tallbldgrn", [5740] = "tall2", [5741] = "lawnstuff21", [5742] = "lawnstuff15", 
   [5743] = "grndLAwn", [5744] = "road_lawn32", [5745] = "road_lawn07", [5746] = "road_lawn08", [5747] = "road_lawn01", 
   [5748] = "road_lawn09", [5749] = "road_lawn10", [5750] = "road_lawn11", [5751] = "road_lawn12", [5752] = "road_lawn13", 
   [5753] = "road_lawn37", [5754] = "road_lawn15", [5755] = "road_lawn36", [5756] = "road_lawn33", [5757] = "road_lawn18", 
   [5758] = "road_lawn19", [5759] = "road_lawn20", [5760] = "MelBlok09_LAwN", [5761] = "MelBlok06_LAwN", [5762] = "foodmartlawn", 
   [5763] = "bigbuillawn", [5764] = "lawnwires01", [5765] = "sunset15_LAwN", [5766] = "capitRec2_LAwN", [5767] = "capitRec1_LAwN", 
   [5768] = "TaftBldg1_LAwN", [5769] = "VineBlock1_LAwN", [5770] = "TaftBldgTran_LAwN", [5771] = "melrose10_law", [5772] = "RailTunn01_LAwN", 
   [5773] = "TrainStat01_LAwN", [5774] = "garage01_LAwN", [5775] = "standard01_LAwN", [5776] = "standardTra_LAwN", [5777] = "tombston01_LAwN", 
   [5778] = "gravecov01_LAwN", [5779] = "garagDoor1_LAwN", [5780] = "MelBlok11Tr_LAwN", [5781] = "MelBlok11_LAwN", [5782] = "MelBlok12_LAwN", 
   [5783] = "MelWir02_LAwN", [5784] = "MelBlok08_LAwN", [5785] = "MelBlok02Tr_LAwN", [5786] = "shutters01_LAwN", [5787] = "MelBlok01_LAwN", 
   [5788] = "MelBlok01T_LAwN", [5789] = "melrose01Tr_law", [5790] = "shopboards01_LAwn", [5791] = "shutters02_LAwN", [5792] = "fredricks01_LAwN", 
   [5793] = "road_lawn02", [5794] = "road_lawn06", [5795] = "road_lawn14", [5796] = "road_lawn38", [5797] = "road_lawn21", 
   [5798] = "road_lawn35", [5799] = "road_lawn29", [5800] = "road_lawn30", [5801] = "road_lawn28", [5802] = "road_lawn34", 
   [5803] = "road_hillLAwn12", [5804] = "road_lawn25", [5805] = "road_lawn22", [5806] = "road_lawn17", [5807] = "road_lawn16", 
   [5808] = "road_lawn39", [5809] = "lawngrndaa", [5810] = "lawnmalstrip", [5811] = "lawnmallsign1", [5812] = "grasspatchlawn", 
   [5813] = "lawnshop1", [5814] = "lawncluckbel", [5815] = "lawngrnda", [5816] = "odrampbit", [5817] = "odrampbit01", 
   [5818] = "posters02_LAwN", [5819] = "lawnbuildg", [5820] = "odrampbit02", [5821] = "odrampbit03", [5822] = "lhroofst14", 
   [5823] = "lawnalley", [5835] = "ci_astage", [5836] = "ci_watertank", [5837] = "ci_guardhouse1", [5838] = "ci_watertank01", 
   [5844] = "lawnmart_alpha", [5845] = "lawngrndasas", [5846] = "posters01_LAwN", [5847] = "lawnbushb", [5848] = "mainblk_LAwN", 
   [5853] = "sunset21_LAwN", [5854] = "lawnbillbrd2", [5855] = "lawncrates", [5856] = "lawnspraydoor1", [5857] = "Lawn_buyable1", 
   [5859] = "road_lawn24", [5860] = "road_lawn27", [5861] = "road_lawn05", [5862] = "road_lawn31", [5863] = "filmstud4", 
   [5864] = "filmstud3", [5865] = "filmstud2", [5866] = "road40_LAwN", [5868] = "sunset16Tr_LAwN", [5870] = "sunset17_LAwN", 
   [5871] = "Graveyard01_LAwN", [5872] = "GraveyardTr_LAwN", [5873] = "manns03Tr_LAwN", [5874] = "manns03_LAwN", [5875] = "manns02_LAwN", 
   [5876] = "LTSmanns_LAwN", [5877] = "VineBlokTran_LAwN", [5878] = "VineBlock2_LAwN", [5881] = "skyscr02_LAwN", [5882] = "skyscr01_LAwN", 
   [5885] = "skyscr03_LAwN", [5886] = "spray01_LAwN", [5887] = "FredBlock_LAwN", [5888] = "FredBlokTran_LAwN", [5891] = "hblues02_LAwN", 
   [5892] = "hblues01_LAwN", [5893] = "hblues01Tr_LAwN", [5896] = "sunset22_LAwN", [5986] = "Chateau01_LAwN", [5987] = "sunset19_LAwN", 
   [5990] = "LTSEld01_LAwN", [5991] = "LTSrec01_LAwN", [5992] = "LTSReg01_LAwN", [5993] = "lawnmalstripTR", [5994] = "road_lawn26", 
   [5995] = "road_lawn04", [5998] = "sunset18Tr_LAwN", [5999] = "sunset18_LAwN", [6001] = "LTSsunset18_LAwN", [6006] = "newbit01_LAwN", 
   [6007] = "newbit02_LAwN", [6010] = "lawnboigashot25", [6035] = "lawroads_law12", [6036] = "filler01_laW", [6037] = "filler02_laW", 
   [6038] = "wilshire2_law", [6039] = "wilshire5_law", [6040] = "wilshire7_law", [6041] = "wilshire6_law", [6042] = "venblue01_law", 
   [6043] = "wilshire1w_law", [6044] = "wilshire2w_law", [6045] = "wilshire5w_law", [6046] = "hedge01_law", [6047] = "wilshire1_law", 
   [6048] = "mall_laW", [6049] = "beachwall_law", [6050] = "beachhut01_law", [6051] = "mallglass_laW", [6052] = "artcurve_law", 
   [6053] = "stepshop_law", [6054] = "lawroads_law02", [6055] = "lawroads_law03", [6056] = "jettysign_law", [6057] = "wdpanelhs09_law", 
   [6058] = "wdpanelhs08_law", [6059] = "offven02_law", [6060] = "plaza2top_law", [6061] = "plaza2bot_law", [6062] = "Miami_atm", 
   [6063] = "staplaz_law", [6064] = "LAbeach_03bx", [6065] = "LAbeach_04bx", [6066] = "vengym_law", [6087] = "offven01_law", 
   [6088] = "offven05_law", [6094] = "bevgrnd03b_law", [6095] = "offvensp02_law", [6096] = "offvensp03_law", [6098] = "gzbuild2_law", 
   [6099] = "gaz3_law", [6100] = "gaz1_law", [6101] = "gaz2_law", [6102] = "gaz4_LAW", [6103] = "gaz5_LAW", 
   [6104] = "gaz18_LAW", [6110] = "plazadrawlast_LAW", [6111] = "lawroads_law05", [6112] = "lawroads_law06", [6113] = "lawroads_law07", 
   [6114] = "lawroads_law08", [6115] = "lawroads_law09", [6116] = "lawroads_law10", [6117] = "lawroads_law11", [6118] = "lawroads_law01", 
   [6119] = "lawroads_law13", [6120] = "lawroads_law14", [6121] = "lawroads_law15", [6122] = "lawroads_law16", [6123] = "lawroads_law17", 
   [6124] = "lawroads_law18", [6125] = "lawroads_law19", [6126] = "lawroads_law20", [6127] = "lawroads_law21", [6128] = "lawroads_law22", 
   [6129] = "lawroads_law23", [6130] = "mallb_laW", [6132] = "gaz8_law", [6133] = "gaz9_law", [6134] = "gaz11_law", 
   [6135] = "gaz13_law", [6136] = "gaz15_law", [6137] = "gaz12_law", [6138] = "gaz10_law", [6145] = "gaz16_law", 
   [6148] = "gaz19_law", [6150] = "gaz7_LAW", [6151] = "gaz21_LAW", [6152] = "gaz20_law", [6157] = "gaz22_law", 
   [6158] = "gaz24_law", [6159] = "gaz25_law", [6160] = "gaz23_law", [6165] = "burggrnd1_law", [6186] = "gaz5_LAW01", 
   [6187] = "gaz26_law", [6188] = "gaz_pier2", [6189] = "gaz_pier1", [6192] = "nitelites_LAW02", [6193] = "nitelites_LAW01", 
   [6194] = "nitelites_LAW05", [6195] = "nitelites_LAW03", [6196] = "nitelites_LAW04", [6199] = "gaz27_LAW", [6203] = "LAland_08", 
   [6204] = "lawplaza_alpha", [6205] = "ja_gerrartlaw", [6209] = "beachbnt", [6210] = "beachbunt2", [6211] = "offven01_law01", 
   [6212] = "offven05_law01", [6213] = "venlaw_grnd", [6214] = "LAW_alphaveg", [6217] = "law_vengrnd", [6223] = "gaz2bld_law", 
   [6225] = "lawroads_law04", [6227] = "canalWest01_LAw", [6228] = "CanalBrij02_LAw", [6229] = "canalEast01_LAw", [6230] = "canaljetty_LAw", 
   [6231] = "CanalRoad01_LAw", [6232] = "canal_arch", [6233] = "canal_floor", [6234] = "canal_floor2", [6235] = "canal_arch01", 
   [6236] = "canal_floor3", [6237] = "venice_alpha", [6248] = "RailTunn01_LAw", [6249] = "RailTunn02_LAw", [6250] = "RailTunn03_LAw", 
   [6251] = "RailTunn04_LAw", [6252] = "RailTunn05_LAw", [6257] = "burger01_LAw", [6280] = "Beach01_LAw2", [6281] = "Beach02_LAw2", 
   [6282] = "venice03_laW2", [6283] = "pier04b_LAw2", [6284] = "santahouse02_law2", [6285] = "santahouse04_law2", [6286] = "santahouse05_law2", 
   [6287] = "Pier02c_LAw2", [6288] = "Pier02b_LAw2", [6289] = "pier03b_LAw2", [6290] = "RailTunn02_LAw2", [6291] = "Roads30_LAw2", 
   [6292] = "RailTunn01_LAw2", [6293] = "lawborder2b_LAW2", [6294] = "santahousegrp_law2", [6295] = "sanpedlithus_LAw2", [6296] = "veropolice_LAW2", 
   [6297] = "Beachut01_LAw2", [6298] = "ferris01_LAw2", [6299] = "pier03c_LAw2", [6300] = "Pier04_LAw2", [6301] = "Roads11_LAw2", 
   [6302] = "Roads14_LAw2", [6303] = "Roads16_LAw2", [6304] = "Roads19_LAw2", [6305] = "Roads23_LAw2", [6306] = "Roads24_LAw2", 
   [6307] = "Roads26_LAw2", [6308] = "Roads28_LAw2", [6309] = "Roads29_LAw2", [6310] = "Roads08_LAw2", [6311] = "Roads33_LAw2", 
   [6312] = "BeaCliff03_LAw2", [6313] = "BeaCliff01_LAw2", [6314] = "Roads31_LAw2", [6315] = "BeaLand01_LAw2", [6316] = "Roads02_LAw2", 
   [6317] = "Roads07_LAw2", [6318] = "Roads12_LAw2", [6319] = "Roads17_LAw2", [6320] = "Roads15_LAw2", [6321] = "Roads18_LAw2", 
   [6322] = "Roads20_LAw2", [6323] = "Roads21_LAw2", [6324] = "Roads22_LAw2", [6325] = "Roads01_LAw2", [6326] = "Roads34_LAw2", 
   [6327] = "Roads35_LAw2", [6328] = "sunset12_LAw2", [6329] = "Roads27_LAw2", [6330] = "Roads06_LAw2", [6331] = "Roads05_LAw2", 
   [6332] = "rodeo01_LAw2", [6333] = "Roads25_LAw2", [6334] = "rodeo02_LAw2", [6336] = "rodeo03_LAw2", [6337] = "sunset01_LAw2", 
   [6338] = "sunset02_LAw2", [6340] = "rodeo06_LAw2", [6341] = "century02_LAw2", [6342] = "century01_LAw2", [6343] = "GeoPark01_LAw2", 
   [6344] = "GeoParkTr_LAw2", [6345] = "Roads04_LAw2", [6347] = "BeaCliff04_LAw2", [6349] = "SunBils02_LAw2", [6350] = "SunBils01_LAw2", 
   [6351] = "rodeo05_LAw2", [6352] = "rodeo05Tr_LAw2", [6353] = "SunBils04_LAw2", [6354] = "Sunset04_LAw2", [6355] = "Sunset05_LAw2", 
   [6356] = "Sunset06_LAw2", [6357] = "Sunset04Tr_LAw2", [6362] = "Roads34Tr_LAw2", [6363] = "sunset02Tr_LAw2", [6364] = "sunset07_LAw2", 
   [6366] = "sunset08_LAw2", [6368] = "sunset03_LAw2", [6369] = "sunset09_LAw2", [6370] = "rodeo06Tr_LAw2", [6371] = "rodeo04_LAw2", 
   [6372] = "rodeo04Tr_LAw2", [6373] = "sunset11_LAw2", [6385] = "rodeo02Tr_LAw2", [6386] = "century02Tr_LAw2", [6387] = "century03_LAw2", 
   [6388] = "SanClifft02_LAw2", [6389] = "SanClift01_LAw2", [6390] = "SanClifft04_LAw2", [6391] = "SanClifft05_LAw2", [6393] = "SanCliff04Tr_LAw2", 
   [6397] = "SanCliff02Tr_LAw2", [6398] = "BeaCliff06_LAw2", [6399] = "BeaCliff06Tr_LAw2", [6400] = "spraydoor_LAw2", [6403] = "BeaCliff01Tr_LAw2", 
   [6404] = "venice01b_LAw2", [6405] = "venice03Tr_laW2", [6406] = "venice04_LAw2", [6407] = "venice04Tr_LAw2", [6411] = "venice01bT_LAw2", 
   [6412] = "sunitwin01_LAw2", [6413] = "sunset07Tr_LAw2", [6416] = "lawborder2a_LAW2", [6417] = "lawborder2c_LAW2", [6421] = "BeaLanTr02_LAw2", 
   [6422] = "rdsign01_LAw2", [6427] = "Roads03_LAw2", [6428] = "Roads32_LAw2", [6430] = "BeaLanTr01_LAw01", [6431] = "BeaLanTr03_LAw2", 
   [6436] = "santahouseTr_law2", [6443] = "BeaCliff02_LAw2", [6444] = "BeaCliff02Tr_LAw2", [6448] = "Pier01_LAw2", [6449] = "Pier02_LAw2", 
   [6450] = "Pier03_LAw2", [6451] = "Pier01Tr_LAw2", [6457] = "Pier02Tr_LAw2", [6458] = "pier03Tr_LAw2", [6461] = "ferris01Tr_LAw2", 
   [6462] = "pier04a_LAw2", [6466] = "pier04Tr_LAw2", [6487] = "countclub01_LAw2", [6488] = "countclub02_LAw2", [6489] = "countclubTr_LAw2", 
   [6490] = "tvstudio01_LAw2", [6497] = "sunset10_LAw2", [6499] = "sunset12Tr_LAw2", [6501] = "RailTunn03_LAw2", [6502] = "RailTunn04_LAw2", 
   [6507] = "Roads09_LAw2", [6508] = "Roads10_LAw2", [6509] = "Roads36_LAw2", [6513] = "tunblock_LAw2", [6514] = "tunent01_LAw2", 
   [6516] = "tvstudioTr_LAw2", [6517] = "santagard_LAw2", [6518] = "LTS01_LAw2", [6519] = "LTS02_LAw2", [6520] = "LTS04_LAw2", 
   [6521] = "LTS03_LAw2", [6522] = "country_law2", [6524] = "rdsign01_LAw03", [6863] = "vgsNbuild07", [6864] = "vrockcafe", 
   [6865] = "steerskull", [6866] = "circusconstruct03", [6867] = "vegasplant06", [6868] = "smlbuildvgas05", [6869] = "vegastemp1", 
   [6871] = "courthse_vgn", [6872] = "vgn_corpbuild1", [6873] = "vgn_corpbuild3", [6874] = "vgn_corpbuild2", [6875] = "vgn_corpbuild4", 
   [6876] = "VegasNedge12", [6877] = "VegasNedge02", [6878] = "VegasNroad055", [6879] = "VegasNroad070", [6880] = "VegasNroad071", 
   [6881] = "VegasNroad072", [6882] = "vgnorthland04", [6883] = "vgnorthland06", [6884] = "vgnorthland07", [6885] = "VegasNedge03", 
   [6886] = "VegasNedge04", [6887] = "VegasNedge05", [6888] = "VegasNedge06", [6897] = "VegasNroad622", [6898] = "VegasNroad623", 
   [6899] = "VegasNroad624", [6900] = "VegasNroad625", [6907] = "vgndwntwnshop1", [6908] = "vgndwntwnshop2", [6909] = "vgnprtlstation", 
   [6910] = "vgnprtlstation_01", [6912] = "vgsNrailroad02", [6913] = "vgsNrailroad03", [6914] = "vgsNrailroad05", [6915] = "vgsNrailroad12", 
   [6916] = "VegasNedge07", [6917] = "vgsNrailroad25", [6919] = "vgnlowbuild01", [6920] = "vgnlowbuild11", [6921] = "vgnlowbuild12", 
   [6922] = "vgnlowbuild13", [6923] = "vgnlowbuild14", [6924] = "vgnlowbuild21", [6925] = "vgnlowbuild235", [6926] = "vgnhseing68", 
   [6928] = "vegasplant03", [6929] = "vegasplant04", [6930] = "vegasplant05", [6931] = "vegasplant01", [6932] = "vegasplant07", 
   [6933] = "vegasplant08", [6934] = "vegasplant09", [6944] = "vgnshopnmall02", [6945] = "VegasNroad0711", [6946] = "vgnwalgren1", 
   [6947] = "vgnmall258", [6948] = "VegasNedge08", [6949] = "VegasNedge09", [6950] = "vegasNroad096", [6951] = "VegasNroad032", 
   [6952] = "VegasNroad027", [6953] = "VegasNroad026", [6954] = "vrockglass", [6955] = "vgnlowwall03", [6956] = "VegasNroad712", 
   [6957] = "vgnshopnmall03", [6958] = "vgnmallsigns14", [6959] = "vegasNbball1", [6960] = "vegasNbball2", [6961] = "vgsNwedchap3", 
   [6962] = "vgsNwedchap1", [6963] = "vgsNwedchap2", [6964] = "venefountwat02", [6965] = "venefountain02", [6966] = "vegasNbank1", 
   [6967] = "vgnsqrefnce1", [6968] = "vgnsqrefnce2", [6969] = "vgnsqrefnce3", [6970] = "vgsNbnkmsh", [6971] = "vgn_corpbuild31", 
   [6972] = "shamparklvl1", [6973] = "shamheliprt1", [6974] = "VegasNedge10", [6975] = "shamheliprt2", [6976] = "shamheliprt04", 
   [6977] = "stripshopn1", [6978] = "starboatsign1", [6979] = "vgnorthland13", [6980] = "trainstuff07_SFS02", [6981] = "vgsNtraintunnel04", 
   [6982] = "vgsNtraintunnel01", [6983] = "vgsNtraintunnel02", [6984] = "vgsNtraintunnel03", [6985] = "casinoblock2", [6986] = "vgngamblsign1", 
   [6987] = "casinoblock5", [6988] = "casinoblock3", [6989] = "casinoblock4", [6990] = "VegasNroad797", [6991] = "VegasNroad798", 
   [6993] = "vgncircus2", [6994] = "vgncircus1", [6997] = "strfshcpark69", [6999] = "VegasNroad08202", [7009] = "vgnpolicebuild2", 
   [7010] = "vgnpolicecpark", [7011] = "courthse_vgn01", [7012] = "circusconstruct01", [7013] = "circusconstruct02", [7014] = "circusconstruct04", 
   [7015] = "circusconstruct05", [7016] = "circusconstruct06", [7017] = "circusconstruct07", [7018] = "circusconstruct08", [7019] = "vgnhseing111", 
   [7020] = "vgnhseing112", [7021] = "vgnhseing113", [7022] = "vegasNnewfence2", [7023] = "vgngatesecurity", [7024] = "vegasplant069", 
   [7025] = "plantbox1", [7026] = "vegnewhousewal05", [7027] = "vgnamunation1", [7028] = "vegnewhousewal01", [7029] = "vegnewhousewal02", 
   [7030] = "vegnewhousewal03", [7031] = "vegnewhousewal04", [7032] = "vgnhseland04", [7033] = "vgnhsegate02", [7034] = "vgnhsewall04", 
   [7035] = "vgsNwrehse17", [7036] = "VegasNroad0162", [7037] = "vgnwalburger1", [7038] = "vegasplantwal1", [7039] = "vegasplantwal02", 
   [7040] = "vgnplcehldbox01", [7041] = "VegasNroad004", [7042] = "VegasNedge11", [7043] = "VegasNedge01", [7044] = "vgnorthcoast07", 
   [7045] = "vgnorthcoast06", [7046] = "vgnorthcoast05", [7047] = "vgnorthcoast04", [7048] = "vgnorthcoast03", [7049] = "vgnorthcoast02", 
   [7050] = "VegasNedge13", [7051] = "VegasNedge14", [7052] = "VegasNroad079", [7053] = "VegasNedge15", [7054] = "VegasNroad083", 
   [7055] = "VegasNroad084", [7056] = "VegasNroad085", [7057] = "VegasNroad086", [7064] = "VegasNroad08204", [7069] = "VegasNedge16", 
   [7071] = "casinoblock41_dy", [7072] = "vegascowboy3", [7073] = "vegascowboy1", [7075] = "vgsN_telewire01", [7076] = "vgsN_telewire02", 
   [7077] = "vgsN_telewire03", [7078] = "vgsN_telewire07", [7079] = "vgsN_telewire08", [7080] = "vgsN_telewire09", [7081] = "vgsN_telewire10", 
   [7082] = "vgsN_telewire12", [7083] = "vgsN_telewire13", [7084] = "vgsN_telewire14", [7085] = "vgsN_telewire15", [7086] = "vgsN_telewire16", 
   [7087] = "vgsN_telewire17", [7088] = "casinoshops1", [7089] = "newscafldvegs02", [7090] = "vegasflag1", [7091] = "vegasflag02", 
   [7092] = "vegasflag03", [7093] = "weddingsifgn1", [7094] = "vegaschurchy1", [7095] = "vgsplntground", [7096] = "vrockstairs", 
   [7097] = "vrockneon", [7098] = "VegasNedge17", [7099] = "VegasNedge18", [7100] = "VegasNedge19", [7101] = "VegasNedge20", 
   [7102] = "plantbox12", [7103] = "vgnplantwalk", [7104] = "plantbox13", [7105] = "vegasplant0692", [7153] = "shamheliprt05", 
   [7172] = "plantbox_04", [7184] = "vgnpolicebuild1", [7186] = "plantbox15", [7187] = "vgsN_WHse_post", [7188] = "vgsN_WHse_post01", 
   [7189] = "vgsN_WHse_post02", [7190] = "vgsN_WHse_post03", [7191] = "vegasNnewfence2b", [7192] = "vegasNnewfence2c", [7196] = "vgnNtrainfence01", 
   [7197] = "vgnNtrainfence02", [7198] = "vgnNtrainfence03", [7200] = "vgnlowbuild239", [7201] = "vegasplant_msh1", [7202] = "vgnNmallfence01", 
   [7203] = "vgnorthland05", [7204] = "vgnmall258_rail", [7205] = "vegaschurchy1_rail", [7206] = "VgsNnitlit02", [7207] = "VgsNnitlit03", 
   [7208] = "VgsNnitlit04", [7209] = "vgnNtrainfence04", [7210] = "vgnNtrainfence05", [7212] = "vgnlowwall03_al", [7213] = "vgnpolicecpark3", 
   [7217] = "vgnorthland08", [7218] = "VegasNedge21", [7220] = "casinoblock41_nt", [7221] = "VgsNnitlit01", [7222] = "VgsNnitlit05", 
   [7223] = "vgnlowbuild01fnc", [7224] = "vgnhseing68fnc", [7226] = "vgncircus2neon", [7227] = "stripshopn1fnc", [7228] = "smlbuildvgas05fnc", 
   [7229] = "vegasplantwal02fnc", [7230] = "ClwnPockSgn_n", [7231] = "ClwnPockSgn_d", [7232] = "ClwnPockSgn", [7233] = "ringmaster", 
   [7234] = "vgsNshopchap1", [7236] = "vegasplant03b", [7238] = "vegasplant02", [7240] = "vrockcafehtl", [7242] = "circusconstruct02b", 
   [7243] = "vgncircus1b", [7244] = "vgnpolicecparkug", [7245] = "vegasNbank1ug", [7246] = "vgs_roadsign03", [7247] = "VegasNedge22", 
   [7248] = "vgnorthcoast02b", [7249] = "vgnorthcoast03b", [7250] = "vgnorthcoast04b", [7251] = "vgnorthcoast05b", [7252] = "vgnorthcoast06b", 
   [7253] = "vgnorthcoast07b", [7254] = "VegasNedge23", [7263] = "casinoblock3_dy", [7264] = "casinoblock3_nt", [7265] = "casinoblock5_dy", 
   [7266] = "casinoblock5_nt", [7268] = "vgsN_frntneon_nt", [7269] = "smlbuildvgas05b", [7271] = "vgsN_casadd01", [7272] = "vgsN_casadd02", 
   [7273] = "vgsN_frent_shps", [7276] = "vegasplant01al", [7277] = "vgnlowbuild239_al", [7280] = "VgsNnitlit06", [7287] = "VgsN_safehse_res", 
   [7288] = "vgs_fmtcasgn", [7289] = "casinoblock2_dy", [7290] = "casinoblock2_nt", [7291] = "vegasplant10", [7292] = "vgsn_mallwall", 
   [7294] = "vgsN_polNB01", [7295] = "vgnNtrainfence05b", [7296] = "vgnNtrainfence04b", [7297] = "vgnNtrainfence03b", [7298] = "vgnNtrainfence01b", 
   [7299] = "vgnNtrainfence02b", [7300] = "vgsN_addboard01", [7301] = "vgsN_addboard03", [7302] = "vgsN_addboard04", [7303] = "vgsN_addboard05", 
   [7304] = "vgnmallsigns02", [7305] = "vgnmallsigns03", [7306] = "vgnmallsigns04", [7307] = "vgnmallsigns05", [7308] = "vgnmallsigns06", 
   [7309] = "vgsN_addboard02", [7310] = "vgsN_addboard06", [7311] = "vgsN_carwash", [7312] = "vgsN_carwash01", [7313] = "vgsN_scrollsgn01", 
   [7314] = "vgsN_frntneon_dy", [7315] = "vgsn_blucasign", [7317] = "plantbox17", [7319] = "vgnlowbuild12a", [7320] = "VegasNroadsp08202", 
   [7321] = "VegasNroadsp08203", [7324] = "VegasNroadsp079", [7326] = "VegasNroadVrkRbt", [7327] = "VegasNroadspl079", [7331] = "VGSN_burgsht_neon", 
   [7332] = "VGSN_burgsht_neon01", [7333] = "VgsNnitlit08", [7334] = "VegasNroadslpt002", [7335] = "VegasNroadslpt003", [7336] = "VegasNroadslpt004", 
   [7337] = "VegasNroadslpt001", [7344] = "vgsn_pipeworks", [7347] = "vgsn_pipeworks01", [7353] = "vegasn_motorway", [7355] = "vegasn_motorway1", 
   [7357] = "vegasn_nland", [7359] = "vegasn_nland2", [7361] = "casinoblock4al", [7362] = "vegasNroad096b", [7364] = "VegasN_motway5", 
   [7366] = "sham_superlod", [7367] = "vgsNelec_fence_01", [7368] = "vgsNelec_fence_05", [7369] = "vgsNelec_fence_04", [7370] = "vgsNelec_fence_03", 
   [7371] = "vgsNelec_fence_02", [7377] = "vgsNelec_fence_04a", [7378] = "vgsNelec_fence_03a", [7379] = "vgsNelec_fence_02a", [7380] = "vgsNelec_fence_01a", 
   [7381] = "vgsNelec_fence_05a", [7383] = "VegasNroad071b", [7387] = "vgnboigashot15", [7388] = "vrockpole", [7389] = "vgnboigashot25", 
   [7390] = "vgngassign96", [7391] = "vgngassign102", [7392] = "vegcandysign1", [7415] = "vgswlcmsign1", [7416] = "vegasstadgrnd", 
   [7417] = "vegastadium", [7418] = "ballparkbarrier", [7419] = "mallcarpark_vgn01", [7420] = "vegasgolfcrs08", [7421] = "vegasgolfcrs01", 
   [7422] = "vegasgolfcrs02", [7423] = "glfcrsgate1_vgs", [7424] = "vgnmall1", [7425] = "golfsign1_vgn", [7426] = "elcidhotel_vgn", 
   [7427] = "vegasWedge16", [7428] = "vegasNroad03", [7429] = "vegasNroad04", [7430] = "vegasNroad05", [7431] = "vegasNroad06", 
   [7432] = "vegasNroad07", [7433] = "vegasNroad09", [7434] = "vegasWedge02", [7435] = "vegasNroad15", [7436] = "vegasNroad24", 
   [7437] = "vegasNroad25", [7438] = "vegasWedge03", [7439] = "vegasWedge04", [7440] = "vegasNroad34", [7441] = "vegasNroad35", 
   [7442] = "vegasNroad36", [7443] = "vegasNroad37", [7444] = "vgswindustroad05", [7445] = "vegasNroad39", [7446] = "vegasNroad40", 
   [7447] = "vegasWedge05", [7448] = "vegasWcoast05", [7449] = "vegasWcoast01", [7450] = "vegasWcoast02", [7451] = "vegasWedge06", 
   [7452] = "vegasWedge07", [7453] = "vegasNland02", [7454] = "vegasNland03", [7455] = "vegasNland04", [7456] = "vegasNland05", 
   [7457] = "vegasWedge08", [7458] = "vegasWedge09", [7459] = "vegasNland08", [7460] = "vegasNland09", [7461] = "vegasNland10", 
   [7462] = "vegasNland11", [7463] = "vegasNland12", [7464] = "vegasNland13", [7465] = "vegasNland14", [7466] = "vegasNland15", 
   [7467] = "vegasNland16", [7468] = "vegasNland17", [7469] = "vegasNland18", [7470] = "vegasWedge10", [7471] = "vegasWedge31", 
   [7472] = "vegasWedge12", [7473] = "vegasWedge13", [7474] = "vegasNland23", [7475] = "vegasWedge14", [7476] = "vegasNroad43", 
   [7477] = "vegasNroad44", [7478] = "vegasNroad45", [7479] = "vegasNroad46", [7480] = "vegasWedge15", [7481] = "vegasNroad48", 
   [7482] = "vegasNroad49", [7483] = "vegasNroad50", [7484] = "vegasNroad51", [7485] = "vegasWedge01", [7486] = "vgswindustroad01", 
   [7488] = "vgncarpark1", [7489] = "vgnhseing34", [7490] = "vegasnorthwrehse1", [7491] = "vgnhseing25", [7492] = "vgnhseing40", 
   [7493] = "vgnabatbuild", [7494] = "vgnhseing42", [7495] = "vgnhseing43", [7496] = "vgnhseing44", [7497] = "vgnorthwrehse14", 
   [7498] = "vegaswrailroad01", [7499] = "vegaswrailroad02", [7500] = "vegaswrailroad03", [7501] = "vegaswrailroad04", [7502] = "vegaswrailroad05", 
   [7503] = "vegaswrailroad06", [7504] = "glfcrsgate2_vgn", [7505] = "glfcrsgate3_vgn", [7506] = "vgnlowbuild057", [7507] = "vgnlowbuild09", 
   [7508] = "vgnlowbuild17", [7509] = "vgnlowbuild20", [7510] = "vgnlowbuild236", [7511] = "vegaswtrainstat", [7512] = "vegaswtrainstat2", 
   [7513] = "vgnwrehse69", [7514] = "vgnwrewall1", [7515] = "vegasnfrates1", [7516] = "vegasnfrates02", [7517] = "vgnwreland1", 
   [7518] = "vgnhseing82", [7519] = "vgnhseland1", [7520] = "vgnlowbuild203", [7521] = "vgnlowbuild202", [7522] = "vgnhsegate1", 
   [7523] = "vgnhseland2", [7524] = "vgnhsewall3", [7525] = "vgnfirestat", [7526] = "vgncarshow1", [7527] = "vegasnfrates03", 
   [7528] = "downvgnbild1", [7529] = "vgnlowbuild18", [7530] = "vgngebuild1", [7531] = "vgnlowmall2", [7532] = "vgnlowwall1", 
   [7533] = "newaprtmntsvgN08", [7534] = "newaprtmntsvgN07", [7535] = "newaprtmntsvgN03", [7536] = "newaprtmntsvgN14", [7537] = "newaprtmntsvgN09", 
   [7538] = "newaprtmntsvgN16", [7539] = "burgerland1", [7540] = "burgerland02", [7541] = "vgntelwires04", [7542] = "vgntelwires05", 
   [7543] = "vgntelwires08", [7544] = "vegasNroad22", [7545] = "vegasNroad17", [7546] = "vegasNroad01", [7547] = "vegasNroad18", 
   [7548] = "vegasWedge17", [7549] = "vegasNroad23", [7550] = "vegasNroad21", [7551] = "vegasNroad20", [7552] = "vegasNroad19", 
   [7553] = "vegasWedge18", [7554] = "vgnhseing89", [7555] = "bballcpark1", [7556] = "bballcpark2", [7557] = "vegasWcoast04", 
   [7558] = "vegasWedge19", [7559] = "vegasWedge20", [7560] = "vgnfrsttfence", [7561] = "vegasnfrates04", [7562] = "vegastwires01", 
   [7563] = "vegastwires02", [7564] = "vegastwires03", [7565] = "vegastwires04", [7566] = "vegastwires05", [7567] = "vegastwires06", 
   [7568] = "vegastwires07", [7569] = "vegastwires08", [7570] = "vgntelwires17", [7571] = "vegastwires09", [7572] = "vegastwires10", 
   [7573] = "vegastwires11", [7574] = "vegastwires12", [7575] = "vegastwires13", [7576] = "vegastwires14", [7577] = "vegastwires15", 
   [7578] = "vegastwires16", [7579] = "vgncnstructlnd", [7580] = "vegasNroad57", [7581] = "mirageroad1", [7582] = "miragebuild04", 
   [7583] = "visagesign1", [7584] = "miragebuild01", [7585] = "miragebuild05", [7586] = "miragebuild07", [7587] = "miragebuild03", 
   [7588] = "miragebuild02", [7589] = "miragebuild08", [7590] = "miragebuild09", [7591] = "miragebuild10", [7592] = "miragebuild11", 
   [7593] = "miragebuild12", [7595] = "miragehedge1", [7596] = "tamomotel1", [7597] = "gingersign1", [7598] = "vgntelwires18", 
   [7599] = "stripshopstat", [7600] = "vegasgolfcrs03", [7601] = "vegasgolfcrs04", [7602] = "vegasgolfcrs05", [7603] = "vegasgolfcrs06", 
   [7604] = "vegasgolfcrs07", [7605] = "vegasNroad08", [7606] = "vegasbigsign1", [7607] = "vgntelwires19", [7608] = "vgntelwires20", 
   [7609] = "vgntelwires21", [7610] = "vgsmallsign1", [7611] = "vegasstadwall01", [7612] = "vegasstadwall05", [7613] = "vegasstadwall04", 
   [7614] = "vegasstadwall03", [7615] = "vegasstadwall02", [7616] = "vgnballparkland", [7617] = "vgnbballscorebrd", [7618] = "vgnwrehse14barb", 
   [7619] = "vgnabartoirinter2", [7620] = "vegasnfrates05", [7621] = "vegasnfrates06", [7622] = "vegasnfrates07", [7623] = "vegaswtrainfence06", 
   [7624] = "vegaswtrainfence07", [7625] = "vgnhseing129", [7626] = "vgnhseland03", [7627] = "vgnabatoir", [7628] = "vgnwrehse14barb01", 
   [7629] = "vegasNroad56", [7630] = "venetiancpark01", [7631] = "vegasWedge11", [7632] = "vegasWedge22", [7633] = "vegasWedge23", 
   [7634] = "vegasWedge24", [7635] = "venetiancpark02", [7636] = "venetiancpark03", [7637] = "vegastwires18", [7638] = "vegastwires19", 
   [7639] = "vegastwires21", [7640] = "vegastwires31", [7641] = "vegastwires32", [7642] = "vegastwires33", [7643] = "vegastwires34", 
   [7644] = "vegastwires35", [7645] = "vegastwires36", [7646] = "vegastwires45", [7647] = "vegastwires46", [7648] = "vegastwires47", 
   [7649] = "vegastwires48", [7650] = "vgnusedcar2", [7651] = "vgnusedcar1", [7652] = "bunting1", [7653] = "bunting02", 
   [7654] = "bunting04", [7655] = "bunting06", [7656] = "bunting08", [7657] = "plasticsgate1", [7658] = "vgnbuild1new", 
   [7659] = "vgngymsteps", [7660] = "venetiancpark04", [7661] = "venetiancpark05", [7662] = "miragehedge14", [7663] = "vgncarshow2", 
   [7664] = "glfcrsgate5_vgs", [7665] = "glfcrsgate4_vgs", [7666] = "vgswlcmsign2", [7681] = "vegasnotxrefhse1", [7692] = "vgnhseing8282", 
   [7696] = "vgngebuild102", [7707] = "vgwbom2", [7708] = "vegaswestbmb02", [7709] = "vgwbom1", [7729] = "vegasWedge25", 
   [7730] = "vegasWedge21", [7731] = "vegasWedge26", [7755] = "vegasNroad31", [7832] = "vgnabartoirinter", [7834] = "vegasnfrates08", 
   [7836] = "vegasnfrates09", [7837] = "vegaswtrainfence08", [7838] = "vegaswtrainfence01", [7839] = "vegaswtrainfence02", [7840] = "vegaswtrainfence03", 
   [7841] = "vegaswtrainfence04", [7842] = "vegaswtrainfence05", [7849] = "vegasNroad62", [7852] = "vegasNroad63", [7854] = "vegasNroad64", 
   [7861] = "vgnhseing8283", [7862] = "vgntelwires22", [7863] = "vgswindustroad08", [7864] = "vgswindustroad07", [7865] = "vegasWedge27", 
   [7866] = "vgswindustroad04", [7867] = "vgswindustroad03", [7868] = "vegasWedge28", [7878] = "vegasNroad242", [7880] = "vgswstbbllgrnd", 
   [7881] = "vegasNroad65", [7882] = "vegasWedge30", [7884] = "vgnmall1_2", [7885] = "vegasglfhse1", [7889] = "vegasWedge29", 
   [7891] = "vgwspry1", [7892] = "visageneon", [7893] = "vegascrashbar04", [7894] = "vegascrashbar05", [7900] = "vgwestbillbrd1", 
   [7901] = "vgwestbillbrd02", [7902] = "vgwestbillbrd03", [7903] = "vgwestbillbrd04", [7904] = "vgwestbillbrd05", [7905] = "vgwestbillbrd06", 
   [7906] = "vgwestbillbrd07", [7907] = "vgwestbillbrd08", [7908] = "vgwestbillbrd09", [7909] = "vgwestbillbrd10", [7910] = "vgwestbillbrd11", 
   [7911] = "vgwestbillbrd12", [7912] = "vgwestbillbrd13", [7913] = "vgwestbillbrd14", [7914] = "vgwestbillbrd15", [7915] = "vgwestbillbrd16", 
   [7916] = "vegaswaterfall02", [7917] = "vegasglfhse2", [7918] = "vgnlowmall3", [7919] = "downvgnbild12", [7920] = "vgwstnewall6903", 
   [7921] = "vgwstnewall6904", [7922] = "vgwstnewall6905", [7923] = "vgwstnewall6902", [7924] = "vgwstnewall6901", [7925] = "vgstreetdirt1", 
   [7926] = "vgnabatoir2", [7927] = "vgswsvehse1", [7929] = "vgwsavehse2", [7930] = "vgwsavehsedor", [7931] = "vgswsvehse04", 
   [7932] = "vgsnotxrefhse02", [7933] = "vegascrashbar06", [7934] = "vgnbuild1new2", [7938] = "vegasNroad2469", [7939] = "glfcrsgate29_vgn", 
   [7940] = "vegirlfrhouse02", [7942] = "vegstadneon", [7943] = "burgershotneon1", [7944] = "burgershotneon02", [7945] = "vegaswedge111", 
   [7947] = "vegaspumphouse1", [7950] = "vegaspumphouse02", [7952] = "miragehedge09", [7953] = "miragehedge04", [7954] = "miragehedge0436", 
   [7955] = "vgwbitodirt", [7956] = "vgwcuntwall1", [7963] = "vegasWedge17b", [7965] = "vegasNroad23b", [7967] = "vegasNroad22b", 
   [7969] = "vegasNroad17b", [7971] = "vgnprtlstation03", [7972] = "vgnboigashot10", [7973] = "vgnboigashot23", [7978] = "airport01_lvS", 
   [7979] = "blastdef01_lvS", [7980] = "airprtbits12_lvS", [7981] = "smallradar02_lvS", [7982] = "gatesB_lvS", [7983] = "vegascollege_lvS", 
   [7984] = "airprtcrprk01_lvS", [7985] = "shop13_lvs", [7986] = "plants01_lvs", [7987] = "vegasSedge09", [7988] = "VegasSroad025", 
   [7989] = "VegasSroad026", [7990] = "VegasSroad027", [7991] = "VegasSroad035", [7992] = "VegasSroad053", [7993] = "VegasSroad060", 
   [7994] = "vegasSedge23", [7995] = "VegasSroad088", [7996] = "vgsSairportland03", [7997] = "vgsSairportland02", [7998] = "vegasSedge26", 
   [7999] = "vgsSairportland04", [8000] = "vgsSairportland05", [8001] = "VegasSland36", [8002] = "vegasSedge20", [8003] = "vegasSedge22", 
   [8004] = "VegasSland40", [8005] = "VegasSland41", [8006] = "vegasSedge25", [8007] = "VegasSland44", [8008] = "vegasSedge24", 
   [8009] = "VegasSroad100", [8010] = "VegasSroad104", [8033] = "vgsSairportland01", [8034] = "flghtschl01_lvs", [8035] = "vegasSedge30", 
   [8036] = "VegasSroad106", [8037] = "crprkgrnd01_lvs", [8038] = "arprtermnl01_lvs", [8039] = "VegasSroad107", [8040] = "airprtcrprk02_lvS", 
   [8041] = "apbarriergate06_lvS", [8042] = "apbarriergate07_lvS", [8043] = "vegasSedge11", [8044] = "aptcanopy_lvs", [8045] = "vegasSedge03", 
   [8046] = "VegasSroad046", [8047] = "VegasSroad017", [8048] = "VegasSroad047", [8049] = "VegasSroad076", [8050] = "vegasSedge14", 
   [8051] = "vegasSedge13", [8052] = "vegasSedge15", [8053] = "vegasSedge16", [8054] = "vegasSedge17", [8055] = "vegasSedge18", 
   [8056] = "vegasSedge19", [8057] = "hseing01_lvs", [8058] = "vgswrehse06", [8059] = "vgswrehse07", [8060] = "vgswrehse03", 
   [8061] = "vgswrehse04", [8062] = "vgswrehse17", [8063] = "vgswrehse16", [8064] = "vgswrehse05", [8065] = "vgswrehse09", 
   [8066] = "hseing03_lvs", [8067] = "hseing02_lvs", [8068] = "hseing04_lvs", [8069] = "hseing05_lvs", [8070] = "VegasSroad122", 
   [8071] = "wrhsegrnd02_lvs", [8072] = "vegasSedge21", [8073] = "vgsfrates02", [8074] = "vgsfrates03", [8075] = "vgsfrates04", 
   [8076] = "vgsfrates05", [8077] = "vgsfrates06", [8078] = "vgsfrates07", [8079] = "hospital01_lvs", [8080] = "VegasSroad128", 
   [8081] = "vgstwires20_lvs", [8082] = "vgstwires21_lvs", [8083] = "vgstwires22_lvs", [8084] = "vgstwires24_lvs", [8085] = "vgstwires23_lvs", 
   [8086] = "vgstwires25_lvs", [8087] = "vgstwires26_lvs", [8091] = "VegasSland58", [8128] = "vgsSrdbrdg_lvs", [8130] = "vgschurch01_lvs", 
   [8131] = "vgschurch02_lvs", [8132] = "vgschurch03_lvs", [8133] = "VegasSland59", [8134] = "vgschrchgrnd_lvs", [8135] = "VegasSroad130", 
   [8136] = "vgSbikeschl04", [8137] = "VegasSroad132", [8147] = "vgsSelecfence01", [8148] = "vgsSelecfence02", [8149] = "vgsSelecfence03", 
   [8150] = "vgsSelecfence04", [8151] = "vgsSelecfence05", [8152] = "vgsSelecfence06", [8153] = "vgsSelecfence07", [8154] = "vgsSelecfence08", 
   [8155] = "vgsSelecfence09", [8165] = "vgsSelecfence10", [8167] = "apgate1_VegS01", [8168] = "Vgs_guardhouse01", [8169] = "vgs_guardhseflr", 
   [8171] = "vgsSairportland06", [8172] = "vgsSairportland07", [8173] = "vgs_concwall01", [8174] = "vgs_concwall02", [8175] = "vgs_concwall03", 
   [8176] = "vgs_concwall04", [8177] = "vgs_concwall05", [8178] = "vgs_concwall06", [8185] = "vgsSredbrix02", [8186] = "vgsSredbrix03", 
   [8187] = "vgsSredbrix04", [8188] = "vgsSredbrix05", [8189] = "vgsSredbrix06", [8194] = "vgsScorrag_fence01", [8198] = "vegasSedge01", 
   [8199] = "vegasSedge27", [8200] = "VegasSland12", [8201] = "stadium_lvs", [8202] = "VegasSland56", [8206] = "vgsSstadrail03", 
   [8207] = "vgsSstadrail05", [8208] = "vgsSstadrail06", [8209] = "vgsSelecfence11", [8210] = "vgsSelecfence12", [8212] = "vegasSedge29", 
   [8213] = "vgsSspagjun02", [8214] = "vgsSspagjun03", [8215] = "vgsSspagjun04", [8216] = "vgsSspagjun05", [8217] = "vgsSspagjun06", 
   [8218] = "vgsSspagjun07", [8219] = "vgsSspagjun08", [8228] = "vgSbikeschl03", [8229] = "vgSbikeschl02", [8230] = "vgSbikeschl01", 
   [8231] = "vgSbikeschl05", [8232] = "vgSbikeschl06", [8236] = "VegasSroad131", [8237] = "vgsbikeschint", [8240] = "vgssbighanger1", 
   [8242] = "vegasSedge10", [8244] = "vegasSedge02", [8245] = "vegasSedge05", [8246] = "vegasSedge12", [8247] = "pltschlhnger69_lvs", 
   [8249] = "pltschlhnger70_lvs", [8251] = "pltschlhnger02_lvs", [8253] = "pltschlhnger01_lvs", [8254] = "vgswrehse10", [8255] = "vgswrehse13", 
   [8256] = "vegasSedge28", [8260] = "vgswrehse18", [8262] = "vgsSelecfence13", [8263] = "vgsSelecfence14", [8264] = "VegasSland34", 
   [8281] = "airport02_lvs", [8283] = "vgschrchgrnd02_lvs", [8285] = "vgschrchgrnd03_lvs", [8286] = "vgschrchgrnd05_lvs", [8287] = "vgschrchgrnd04_lvs", 
   [8288] = "VegasSland56b", [8290] = "vgsSspagjun09", [8292] = "vgsbboardsigns01", [8293] = "vgsbboardsigns02", [8294] = "vgsbboardsigns03", 
   [8300] = "vgswrehse08", [8302] = "jumpbox01_lvs01", [8305] = "VegasSroad1072", [8306] = "VegasSland562", [8308] = "vegas_grasect01", 
   [8310] = "vgsbboardsigns06", [8311] = "vgsSelecfence15", [8313] = "vgsSelecfence16", [8314] = "vgsSelecfence17", [8315] = "vgsSelecfence18", 
   [8319] = "vegstadplants1", [8320] = "vegstadrail69", [8321] = "vegstadplants2", [8322] = "vgsbboardsigns08", [8323] = "vgsbboardsigns09", 
   [8324] = "vgsbboardsigns10", [8325] = "vgsbboardsigns12", [8326] = "vgsbboardsigns13", [8327] = "vgsbboardsigns14", [8328] = "vgsbboardsigns15", 
   [8329] = "vgsbboardsigns16", [8330] = "vgsbboardsigns17", [8331] = "vgsbboardsigns18", [8332] = "vgsbboardsigns19", [8333] = "stadium02_lvs", 
   [8335] = "vgsfrates08", [8337] = "vgsfrates10", [8339] = "vgsfrates11", [8341] = "vgsfrates12", [8342] = "vgsSelecfence119", 
   [8343] = "vgsSairportland09", [8344] = "vgsSairportland10", [8345] = "gatesB_lvS01", [8350] = "vgsSairportland11", [8351] = "vgsSairportland12", 
   [8352] = "vgsSairportland16", [8353] = "vgsSairportland13", [8354] = "vgsSairportland17", [8355] = "vgsSairportland18", [8356] = "vgsSairportland15", 
   [8357] = "vgsSairportland14", [8368] = "vgsSspagjun10", [8369] = "vgsSelecfence05b", [8370] = "aptcanopyday_lvs", [8371] = "aptcanopynit_lvs01", 
   [8372] = "airportneon", [8373] = "VegasS_jetty01", [8375] = "airprtbits14_lvS", [8377] = "VegasSroad0522a", [8378] = "vgsbighngrdoor", 
   [8380] = "vegasSedge1919", [8382] = "vgsSspagjun06b", [8383] = "vgsSspagjun06c", [8386] = "vgsSspagjun09b", [8388] = "vegasSedge29b", 
   [8390] = "multicarpark01_lvS", [8391] = "ballys03_lvs", [8392] = "ballys02_lvs", [8393] = "ballys01_lvs", [8394] = "vgsbox10sgn_lvS", 
   [8395] = "vgEpyrmd_dy", [8396] = "sphinx02_lvs", [8397] = "luxorpillar01_lvs", [8398] = "luxorland01_lvS", [8399] = "nightclub01_lvs", 
   [8400] = "nightclub02_lvs", [8401] = "shop05_lvs", [8402] = "vgshpgrnd01_lvS", [8403] = "shop03_lvs", [8404] = "vgshpgrnd03_lvS", 
   [8405] = "vgshpgrnd02_lvS", [8406] = "carparksign01_lvs", [8407] = "carparkhut01_lvs", [8408] = "carparksign02_lvs", [8409] = "gnhotel01_lvs", 
   [8410] = "carparkhut02_lvs", [8411] = "gnhotel02_lvs", [8412] = "wddngchplsign_lvs", [8416] = "bballcourt02_lvs", [8417] = "bballcourt01_lvs", 
   [8418] = "vgshpgrnd04_lvS", [8419] = "vgsbldng01_lvs", [8420] = "arprtcrprk04_lvS", [8421] = "pirtehtl02_lvS", [8422] = "pirtehtl01_lvS", 
   [8423] = "prtskllsgn02_lvs", [8424] = "vagbond01_lvs", [8425] = "villa_inn01_lvs", [8426] = "vlla_innfnc1_lvs", [8427] = "villa_inn03_lvs", 
   [8428] = "villa_inn02_lvs", [8429] = "vlla_innfnc2_lvs", [8430] = "vlla_innfnc3_lvs", [8431] = "nucarpark01_lvs", [8432] = "shop06_lvs", 
   [8433] = "residnce01_lvs", [8434] = "vgsoffice01_lvs", [8435] = "shop11_lvs", [8436] = "shop12_lvs", [8437] = "residntial01_lvs", 
   [8438] = "VegasEroad003", [8439] = "vgsEedge12", [8440] = "vgsEedge15", [8441] = "vgsEedge16", [8442] = "VegasEroad009", 
   [8443] = "VegasEroad010", [8444] = "VegasEroad011", [8445] = "vgsEedge13", [8446] = "VegasEroad013", [8447] = "VegasEroad019", 
   [8448] = "VegasEroad020", [8449] = "VegasEroad021", [8450] = "VegasEroad022", [8451] = "VegasEroad031", [8452] = "VegasEroad032", 
   [8453] = "VegasEroad033", [8454] = "VegasEroad034", [8455] = "VegasEroad041", [8456] = "VegasEroad058", [8457] = "vgsEedge19", 
   [8458] = "VegasEroad075", [8459] = "vgsEland02_lvs", [8460] = "vgsEland03_lvs", [8461] = "vgsEland04_lvs", [8462] = "vgsEland06_lvs", 
   [8463] = "vgsEland07_lvs", [8464] = "vgsEland08_lvs", [8465] = "vgsEcoast07", [8466] = "vgsEcoast08", [8467] = "vgsEland11_lvs", 
   [8468] = "vgsEland12_lvs", [8469] = "vgsEedge25", [8470] = "vgsEedge27", [8471] = "VegasEroad092", [8472] = "VegasEroad094", 
   [8473] = "VegasEroad095", [8474] = "VegasEroad096", [8475] = "VegasEroad097", [8476] = "VegasEroad098", [8477] = "VegasEroad099", 
   [8480] = "csrspalace01_lvs", [8481] = "csrsfence01_lvs", [8482] = "csrspalace02_lvs", [8483] = "pirateland02_lvS", [8484] = "pirateland03_lvS", 
   [8485] = "ballysbase_lvs", [8486] = "vgsEedge21", [8487] = "ballyswtr01_lvs", [8488] = "flamingo02_lvs", [8489] = "flamingo01_lvs", 
   [8490] = "flamingo03_lvs", [8491] = "flamingo04_lvs", [8492] = "flamingo05_lvs", [8493] = "pirtshp01_lvs", [8494] = "lowbuild01_lvs", 
   [8495] = "mall01_lvs", [8496] = "lowbuild03_lvs", [8497] = "vgsEland16_lvs", [8498] = "exclbr_hotl01_lvS", [8499] = "exclbr_hotl02_lvS", 
   [8500] = "excalibur01_lvS", [8501] = "casroyale01_lvs", [8502] = "casroyldge01_lvs", [8503] = "shop08_lvs", [8504] = "shop10_lvs", 
   [8505] = "shop14_lvs", [8506] = "shop16_lvs", [8507] = "shop15_lvs", [8508] = "genshop01_lvs", [8509] = "shop09_lvs", 
   [8510] = "VegasEroad112", [8511] = "VegasEroad111", [8512] = "VegasEroad113", [8513] = "residnce01_lvs01", [8514] = "VegasEroad110", 
   [8515] = "vgsEland01_lvs", [8516] = "shop07_lvs", [8517] = "VegasEroad114", [8518] = "vgsEedge26", [8519] = "VegasEroad015", 
   [8520] = "VegasEroad045", [8521] = "VegasEroad071", [8522] = "VegasEroad093", [8523] = "VegasEroad072", [8524] = "VegasEroad042", 
   [8525] = "VegasEroad043", [8526] = "vgbndsign01_lvs", [8527] = "vagbond02_lvs", [8528] = "vagbond03_lvs", [8529] = "vgsEland17_lvs", 
   [8530] = "vgbndsign02_lvs", [8531] = "vgsEland18_lvs", [8532] = "vgsEland19_lvs", [8533] = "vgsEedge10", [8534] = "tikimotel01_lvs", 
   [8535] = "tikimotel02_lvs", [8536] = "tikisign01_lvs", [8537] = "tikisign02_lvs", [8538] = "vgsrailroad03", [8539] = "vgsrailroad04", 
   [8540] = "vgsrailroad05", [8541] = "vgsrailroad06", [8542] = "vgsrailroad07", [8543] = "vgsEedge11", [8544] = "vgsEhseing06", 
   [8545] = "vgsEwrehse01", [8546] = "vgsEwrehse02", [8547] = "fctrygrnd01_lvs", [8548] = "trainsign01_lvs", [8549] = "fctryfnce01_lvs", 
   [8550] = "laconcha_lvs", [8551] = "lacnchasgn_lvs", [8552] = "VegasEroad123", [8553] = "vgsEland21_lvs", [8554] = "vgsEland22_lvs", 
   [8555] = "vgsEcrthse", [8556] = "vgshsegate04", [8557] = "vgshseing27", [8558] = "vgshseing28", [8559] = "vgshsewall06", 
   [8560] = "vgEhseland05", [8561] = "VegasEroad124", [8562] = "VegasEroad127", [8563] = "lacnchasgn2_lvs", [8564] = "vgsEland29_lvs", 
   [8565] = "vgsEbuild03_lvs", [8566] = "vgsEbuild02_lvs", [8567] = "vgsEbuild04_lvs", [8568] = "vgsEbuild05_lvs", [8569] = "vgsEbuild12_lvs", 
   [8570] = "vgsEbuild09_lvs", [8571] = "vgsEbuild11_lvs", [8572] = "vgsSstairs02_lvs", [8573] = "balcony01_lvs", [8574] = "shpfrnt01_lvs", 
   [8575] = "vgstrainstation", [8576] = "balcony02_lvs", [8577] = "trnstngrnd01_lvs", [8578] = "vgstrainstation3", [8579] = "balcony03_lvs", 
   [8580] = "vgsSstairs05_lvs", [8581] = "vgsEbuild06_lvs", [8582] = "vgsEedge01", [8583] = "vgsEcoast02", [8584] = "vgsEcoast03", 
   [8585] = "vgsEcoast04", [8586] = "vgsrailroad11", [8587] = "vgsrailroad13", [8588] = "vgsrailroad15", [8589] = "lwbldstuff03_lvs", 
   [8590] = "filmrllprop01_lvs", [8591] = "olympic01_lvs", [8592] = "olympcrail01_lvs", [8593] = "vgsEwires01_lvs", [8594] = "vgsEwires02_lvs", 
   [8595] = "vgsEwires19_lvs", [8596] = "vgsEwires03_lvs", [8597] = "tikimtl02rail_lvs", [8607] = "vgsEwires05_lvs", [8608] = "vgsEwires04_lvs", 
   [8609] = "VegasEroad008", [8610] = "VegasEroad023", [8611] = "VegasEroad036", [8612] = "VegasEroad037", [8613] = "vgsSstairs03_lvs", 
   [8614] = "vgsSstairs01_lvs", [8615] = "vgsSstairs04_lvs", [8616] = "VegasEroad130", [8617] = "bush01_lvs", [8618] = "ceasersign_lvs", 
   [8619] = "bush02_lvs", [8620] = "exclbrsign01_lvS", [8621] = "exclbrsign02_dy", [8622] = "VegasEroad131", [8623] = "bush03_lvs", 
   [8624] = "vgsrailroad16", [8625] = "vgsEedge04", [8626] = "vgsEedge03", [8627] = "vgsrailroad23", [8628] = "vgsrailroad22", 
   [8629] = "vgsrailroad19", [8630] = "vgsrailroad20", [8631] = "vgsrailroad21", [8632] = "vgsrailroad24", [8633] = "vgsrailroad26", 
   [8634] = "vgsrailroad25", [8635] = "vgsrailbuild01", [8636] = "tikimtlwall01_lvs", [8637] = "VegasEroad134", [8638] = "vgsEedge09", 
   [8639] = "chnatwnmll01_lvs", [8640] = "chnatwnmll02_lvs", [8641] = "chnatwnmll03_lvs", [8642] = "chnatwnmll04_lvs", [8643] = "vgsEbuild01_lvs", 
   [8644] = "exclbrsign03_lvS", [8645] = "shbbyhswall01_lvs", [8646] = "shbbyhswall02_lvs", [8647] = "shbbyhswall03_lvs", [8648] = "shbbyhswall04_lvs", 
   [8649] = "shbbyhswall05_lvs", [8650] = "shbbyhswall06_lvs", [8651] = "shbbyhswall07_lvs", [8652] = "shbbyhswall12_lvs", [8653] = "shbbyhswall08_lvs", 
   [8654] = "vgsEland23_lvs", [8655] = "vgsEland24_lvs", [8656] = "shbbyhswall09_lvs", [8657] = "shbbyhswall10_lvs", [8658] = "shabbyhouse11_lvs", 
   [8659] = "shbbyhswall11_lvs", [8660] = "bush04_lvs", [8661] = "gnhtelgrnd_lvs", [8662] = "nucrprkwall_lvs", [8663] = "triadcasno01_lvs", 
   [8664] = "casrylegrnd_lvs", [8665] = "chnatwnmll06_lvs", [8666] = "chnatwnmll07_lvs", [8667] = "chnatwnmll08_lvs", [8668] = "chnatwnmll11_lvs", 
   [8669] = "chnatwnmll13_lvs", [8670] = "chnatwnmll12_lvs", [8671] = "vgsEland26_lvs", [8672] = "vgsEedge06", [8673] = "csrsfence03_lvs", 
   [8674] = "csrsfence02_lvs", [8675] = "wddngchpl02_lvs", [8676] = "wdngchplsgn2_lvs", [8677] = "vgsEland09_lvs", [8678] = "wdngchplgrnd01_lvs", 
   [8679] = "bush05_lvs", [8680] = "chnatwnfnc02_lvs", [8681] = "chnatwnfnc03_lvs", [8682] = "chnatwnfnc04_lvs", [8683] = "chnatwnfnc05_lvs", 
   [8684] = "chnatwnfnc06_lvs", [8685] = "chnatwnfnc07_lvs", [8686] = "chnatwnfnc01_lvs", [8687] = "vgelwbld15_lvs", [8688] = "vgelwbld16_lvs", 
   [8689] = "vgelwbld17_lvs", [8710] = "bnuhotel01_lvs", [8824] = "vgsEedge05", [8825] = "vgsEstrphdge01", [8826] = "vgsEstrphdge02", 
   [8827] = "vgsEstrphdge03", [8828] = "vgsEstrphdge04", [8832] = "pirtebrdg01_lvS", [8833] = "prtbrdgrope_lvS", [8834] = "prtbrdgrope2_lvS", 
   [8835] = "pirtetrees01_lvS", [8836] = "pirtetrees02_lvS", [8837] = "pirtetrees03_lvS", [8838] = "vgEhshade01_lvs", [8839] = "vgsEcarshow1", 
   [8840] = "vgsEflgs1_lvs", [8841] = "rsdncarprk01_lvs", [8842] = "vgsE24hr_lvs", [8843] = "arrows01_lvs", [8844] = "vgsEedge23", 
   [8845] = "flamingrnd_lvs", [8846] = "bush06_lvs", [8849] = "vgelwbld18_lvs", [8850] = "vgelwbldgrd_lvs", [8851] = "vgEplntr01_lvs", 
   [8852] = "bush07_lvs", [8853] = "vgEplntr02_lvs", [8854] = "vgEplntr03_lvs", [8855] = "vgEplntr04_lvs", [8856] = "vgEplntr06_lvs", 
   [8857] = "vgsEcoast06", [8858] = "vgsrailroad09", [8859] = "vgsEcoast05", [8860] = "vgsrailroad14", [8865] = "vgEplntr07_lvs", 
   [8866] = "vgEplntr08_lvs", [8867] = "vgsEcnstrct01", [8868] = "vgsEcnstrct02", [8869] = "vgsEcnstrct05", [8870] = "vgsEcnstrct03", 
   [8871] = "vgsEcnstrct04", [8872] = "vgEscfldples01", [8873] = "vgsEcnstrct12", [8874] = "vgsEcnstrct13", [8875] = "vgsEcnstrct14", 
   [8876] = "vgsEcnstrct15", [8877] = "vgsEcnstrct10", [8878] = "vgsEcnstrct11", [8879] = "vgsEcnstrct08", [8880] = "vgsEcnstrct09", 
   [8881] = "excalibur02_lvS", [8882] = "excalibur03_lvS", [8883] = "vgsEfrght01", [8884] = "vgsEfrght02", [8885] = "vgsEfrght03", 
   [8886] = "vgsEfrght04", [8887] = "bush08_lvs", [8888] = "bush09_lvs", [8889] = "vgsEstrphdge33", [8932] = "VegasEroad136", 
   [8947] = "vgElkup", [8948] = "lckupgrgdoor_lvs", [8954] = "vgsEspras01", [8955] = "vgsEspray01", [8957] = "vgsEspdr01", 
   [8969] = "vgsEwires06_lvs", [8979] = "vgsEesc02", [8980] = "vgsEesc01", [8981] = "prtwires_lvs", [8982] = "vgsEstrphdge34", 
   [8983] = "vgsEedge02", [8989] = "bush10_lvs", [8990] = "bush11_lvs", [8991] = "bush12_lvs", [9000] = "vgsEedge17", 
   [9001] = "vgsEedge20", [9002] = "vgsEedge22", [9003] = "vgsEedge24", [9004] = "VegasEroad051", [9005] = "VegasEroad050", 
   [9006] = "VegasEroad086", [9007] = "VegasEroad049", [9008] = "VegasEroad048", [9019] = "luxortrees01_lvS", [9020] = "vgsEcnstfnc01", 
   [9021] = "vegasEroad068", [9022] = "vegasEroad067", [9023] = "VegasEroad069", [9024] = "vegasEroad070", [9025] = "vegasEroad065", 
   [9026] = "VegasEroad066", [9027] = "vegasEroad064", [9028] = "VegasEroad063", [9029] = "vgsEtrainfence01", [9030] = "vgsEtrainfence02", 
   [9031] = "vgsEtrainfence03", [9032] = "vgsEtrainfence04", [9033] = "vgsEtrainfence05", [9034] = "tikitrees01_lvS", [9035] = "tikitrees02_lvS", 
   [9036] = "tikibrdg01_lvs", [9037] = "csrspalace03_lvs", [9039] = "csrspalace04_lvs", [9041] = "prthotelfnc01", [9042] = "VegasEroad137", 
   [9043] = "luxorpillar03_lvs", [9044] = "pirateland05_lvS", [9045] = "pirateland04_lvS", [9046] = "vgsEland31_lvs", [9047] = "vgsEland32_lvs", 
   [9052] = "pirateland06_lvS", [9054] = "chnatwnmll14_lvs", [9055] = "chnatwnmll15_lvs", [9056] = "vgsEedge07", [9057] = "vgsEedge08", 
   [9062] = "arprtcrprk05_lvS", [9064] = "vgsEland36_lvs", [9065] = "vgsEland35_lvs", [9066] = "vgsEland37_lvs", [9070] = "casroyale02_lvs", 
   [9071] = "casroyale03_lvs", [9072] = "casroyale04_lvs", [9076] = "sphinx01_lvs", [9078] = "excalibur04_lvS", [9080] = "excalibur05_lvS", 
   [9082] = "vgsEcnstrct17", [9083] = "vgsEcnstrct18", [9086] = "vgEhseland06", [9087] = "vgEhseland07", [9088] = "VgsEnitlit01", 
   [9089] = "VgsEnitlit02", [9090] = "vgEferryland", [9093] = "cmdgrgdoor_lvs", [9094] = "csrElights_dy", [9095] = "csrElights_nt", 
   [9098] = "vgsEsvhse01", [9099] = "vgsEsvehse1", [9100] = "luxorlight_dy", [9101] = "luxorlight_nt", [9104] = "vgEpyrmd_nt", 
   [9106] = "vgsEamuntn", [9108] = "vgsEtrainfence06", [9109] = "vgsEtrainfence07", [9110] = "vgsEtrainfence08", [9111] = "vgsEtrainfence09", 
   [9112] = "vgsEtrainfence10", [9113] = "vgbndfnce", [9114] = "wddngchpl01_lvs", [9115] = "VegasEroad138", [9116] = "VegasEroad139", 
   [9117] = "VegasEroad140", [9118] = "VegasEroad141", [9119] = "vgsEedge14", [9120] = "VegasEroad143", [9121] = "flmngoneon01", 
   [9122] = "triadneon01", [9123] = "ballyneon01", [9124] = "crsplcneon", [9125] = "lxorneon", [9126] = "cmtneon01", 
   [9127] = "cmtneon02", [9128] = "lxorneon2", [9129] = "pirtneon", [9131] = "shbbyhswall13_lvs", [9132] = "triadcasign_lvs", 
   [9135] = "sbvgsEseafloor01", [9136] = "sbvgsEseafloor02", [9137] = "sbvgsEseafloor04", [9138] = "sbvgsEseafloor05", [9139] = "sbvgsEseafloor06", 
   [9140] = "sbvgsEseafloor07", [9150] = "VegasEroad144", [9152] = "bush13_lvs", [9153] = "bush14_lvs", [9154] = "triadwires", 
   [9159] = "pirtshp02_lvs", [9162] = "shop01_lvs", [9163] = "shop04_lvs", [9164] = "vgsrailbuild02", [9165] = "vgsrailbuild03", 
   [9166] = "vgsrailbuild04", [9167] = "vgsrailbuild05", [9168] = "vgsrailbuild06", [9169] = "vgsEprtlstation1", [9171] = "vgsEprtlstation2", 
   [9173] = "vgsEedge18", [9174] = "tislandbrdge01_lvs", [9175] = "VgsEnitlit03", [9184] = "vgEastbillbrd08", [9185] = "vgEastbillbrd07", 
   [9186] = "vgEastbillbrd05", [9187] = "vgEastbillbrd04", [9188] = "vgEastbillbrd02", [9189] = "vgEastbillbrd06", [9190] = "vgEastbillbrd01", 
   [9191] = "vgEastbillbrd03", [9192] = "vgegassgn01_lvs", [9193] = "vgegassgn03_lvs", [9205] = "road04sfn", [9206] = "land2_sfN10", 
   [9207] = "land2_sfN01", [9208] = "land2_sfN19", [9209] = "land_SFN06", [9210] = "land2_sfN11", [9211] = "land2_sfN09", 
   [9212] = "land2_sfN13", [9213] = "land2_sfN15", [9214] = "land2_sfN12", [9215] = "land2_sfN17", [9216] = "land_SFN13", 
   [9217] = "land2_sfN16", [9218] = "land_SFN15", [9219] = "land2_sfN14", [9220] = "Villa_SFN_CHRIS_01", [9221] = "Villa_SFN_CHRIS_02", 
   [9222] = "road08sfn", [9223] = "land_sfn21", [9224] = "cock_sfn02", [9225] = "land_sfn22", [9226] = "land_sfn18", 
   [9227] = "moresfnshit20", [9228] = "moresfnshit22", [9229] = "sfn_coast03", [9230] = "sfn_coast01", [9231] = "road01sfn", 
   [9232] = "road06sfn", [9233] = "road07sfn", [9234] = "land_sfn20", [9235] = "land2_sfN18", [9236] = "cock_sfn07", 
   [9237] = "lighhouse_SFN", [9238] = "moresfnshit28", [9239] = "track01_SFN", [9240] = "track02_SFN", [9241] = "copbits_sfn", 
   [9242] = "cock_sfn06", [9243] = "hrborbuild_SFN02", [9244] = "hrborbuild_SFN01", [9245] = "cstguard_SFN01", [9246] = "cock_sfn09", 
   [9247] = "hrbrmstr_SFN01", [9248] = "cock_sfn08", [9249] = "beach_sfn01", [9250] = "road02sfn", [9251] = "road03sfn", 
   [9252] = "road05sfn", [9253] = "sfn_coast04", [9254] = "carpark_sfn01", [9255] = "carpark_sfn02", [9256] = "cock_sfn14", 
   [9257] = "sfn_coast05", [9258] = "preshoosml02_SFN", [9259] = "preshoosbig02_SFN", [9260] = "hrborbuild_SFN03", [9261] = "land_sfn19", 
   [9262] = "hway_SFN01", [9264] = "hway_SFN03", [9265] = "hway_SFN04", [9266] = "hway_SFN05", [9267] = "hway_SFN06", 
   [9269] = "GGbridgeend_SFN", [9270] = "preshoosbig01_SFN01", [9271] = "preshoos03_SFN01", [9272] = "preshoos03_SFN02", [9273] = "preshoos01_SFN03", 
   [9274] = "preshoos03_SFN03", [9275] = "preshoosml02_SFN01", [9276] = "land_SFN17", [9277] = "bigsfnlite02", [9278] = "bigsfnlite05", 
   [9279] = "bigsfnlite08", [9280] = "bigsfnlite10", [9281] = "bigsfnlite12", [9282] = "bigsfnlite14", [9283] = "bigsfnlite16", 
   [9284] = "land2_sfN02", [9285] = "land2_sfN04", [9286] = "land2_sfN03", [9287] = "land2_sfN06", [9288] = "land2_sfN05", 
   [9289] = "land2_sfN20", [9290] = "land2_sfN07", [9291] = "land2_sfN08", [9292] = "sfn_crashbar06", [9293] = "sfn_crashbar01", 
   [9294] = "sfn_crashbar02", [9295] = "sfn_crashbar03", [9296] = "sfn_crashbar04", [9297] = "sfn_crashbar05", [9298] = "sfn_crashbar07", 
   [9299] = "sfn_clothesSHOP_cm1", [9300] = "sfn_town02", [9301] = "tempobj_SFN04", [9302] = "sfn_town01", [9303] = "sfn_town03", 
   [9304] = "land_sfn23", [9305] = "ground01_SFN_CM", [9306] = "sfn_cm_grNd02", [9307] = "SFN_SHOPBITS01", [9308] = "SFN_DOORWAY02", 
   [9309] = "SFN_CM_GRNDSHOP", [9310] = "chapel_SFN", [9311] = "SFN_newland_cm02", [9312] = "SFN_newland_cm03", [9313] = "SFN_newland_cm01", 
   [9314] = "advert01_sfn", [9315] = "carpark01_sfs_cm", [9316] = "shopstairsSFN1", [9317] = "hedge02_SFN_CM", [9318] = "hedge03SFN_CM", 
   [9319] = "preshoos03_SFN04", [9320] = "preshoosbig02_SFN01", [9321] = "garage_sfn01", [9322] = "preshoos03_SFN05", [9323] = "moresfnshit29", 
   [9324] = "preshoosbig02_SFN02", [9325] = "preshoos03_SFN06", [9326] = "preshoos03_SFN07", [9327] = "moresfnshit30", [9328] = "moresfnshit31", 
   [9329] = "sfn_coast06", [9330] = "SFN_wall_cm01", [9331] = "SFN_PRESHEDGE1", [9332] = "SFN_wall_cm02", [9333] = "SFNhedge_PRES02", 
   [9334] = "hedge09_SFN_CM", [9335] = "SFN_hedge_cm_010", [9336] = "hedge04_SFN_CM", [9337] = "SFN_WALL_cm2", [9338] = "land_sfn19B", 
   [9339] = "SFNvilla001_CM", [9340] = "SFNfence_CM01", [9341] = "Villa_SFN_CHRIS_04", [9342] = "land2_sfN09a", [9343] = "SFN_fence_cm2", 
   [9344] = "SFNhdge_presi_cm10", [9345] = "SFN_PIER_grassbit", [9346] = "SFNLand_villaCM1", [9347] = "SFNpres_hdge_10", [9348] = "sfn_hedge05_cm", 
   [9349] = "SFNfence_pres_5", [9350] = "SFN_pres_hedge9", [9351] = "SFN_STAIRS_bit", [9352] = "cables", [9353] = "land_SFN17a", 
   [9361] = "boatoffice_sfn", [9362] = "boatoffice2_sfn", [9437] = "sbedsfn4_SFN", [9438] = "sbedsfn1_SFN", [9439] = "sbedsfn2_SFN", 
   [9440] = "sbedsfn3_SFN", [9476] = "hway_SFN02", [9482] = "chinagate", [9483] = "land_16_sfw", [9484] = "land_46_sfw", 
   [9485] = "road_SFW02", [9486] = "road_SFW03", [9487] = "road_SFW04", [9488] = "road_SFW05", [9489] = "road_SFW06", 
   [9490] = "road_SFW07", [9491] = "road_SFW08", [9492] = "road_SFW09", [9493] = "road_SFW10", [9494] = "tempbuild_sfw41", 
   [9495] = "tempbuild_sfw42", [9496] = "sboxbld4_sfw02", [9497] = "sboxbld4_sfw69", [9498] = "sboxbld4_sfw70", [9499] = "sboxbld4_sfw71", 
   [9500] = "sboxbld4_sfwa", [9501] = "sfwbox_sfw27", [9502] = "sfwbox_sfw43", [9503] = "sboxbld4_sfw72", [9504] = "sboxbld4_sfw73", 
   [9505] = "gard_sfw01", [9506] = "bigboxtmp02", [9507] = "bigboxtmp03", [9508] = "bigboxtmp09", [9509] = "bigboxtmp05", 
   [9510] = "bigboxtmp06", [9511] = "bigboxtmp07", [9512] = "bigboxtmp08", [9513] = "bigboxtmp1", [9514] = "supasave_sfw", 
   [9515] = "bigboxtmp18", [9516] = "bigboxtmp17", [9517] = "bigboxtmp16", [9518] = "bigboxtmp15", [9519] = "bigboxtmp20", 
   [9520] = "boxbuildsfw_31", [9521] = "morboxes03", [9522] = "morboxes04", [9523] = "newvic2_sfw", [9524] = "blokmod1_sfw", 
   [9525] = "boigas_sfw03", [9526] = "boigas_sfw02", [9527] = "boigas_sfw01", [9528] = "boigas_sfw04", [9529] = "blokmod3_sfw", 
   [9530] = "sandbch_sfw02", [9547] = "blokcut_sfw04", [9549] = "sfw_boxwest10", [9550] = "sfw_boxwest04", [9551] = "sandbch_sfw04", 
   [9552] = "sandbch_sfw03", [9553] = "sandbch_sfw69", [9554] = "park3_sfw", [9555] = "park1_sfw", [9556] = "park2_sfw", 
   [9557] = "lake_sfw", [9558] = "cables_sfw", [9559] = "fescape_sfw07", [9560] = "fescape_sfw08", [9561] = "fescape_sfw09", 
   [9562] = "fescape_sfw02", [9563] = "fescape_sfw04", [9564] = "firscape_sfw04", [9565] = "fescape_sfw06", [9566] = "fescape_sfw01", 
   [9567] = "cables_sfw01", [9568] = "cables_sfw24", [9569] = "cables_sfw28", [9570] = "road_SFW11", [9571] = "road_SFW12", 
   [9572] = "blokmod3_sfw04", [9573] = "newvic1_sfw", [9575] = "archbrij_SFW", [9576] = "frway_box1", [9577] = "frway_box2", 
   [9578] = "blokmod2_sfw01", [9579] = "blokmod2_sfw03", [9580] = "sboxbld4_sfw83", [9581] = "sboxbld4_sfw84", [9582] = "temp_SFW35", 
   [9583] = "freight_SFW15", [9584] = "freight_SFW31", [9585] = "freight_SFW33", [9586] = "freight_deck_SFW", [9587] = "freight_box_SFW01", 
   [9588] = "freightbox_inSFw", [9589] = "frght_BOXES08", [9590] = "freight_interiorsfw", [9591] = "road_SFW13", [9592] = "sfw_boxwest12", 
   [9593] = "hosbibal_sfw", [9594] = "fescape_sfw03", [9595] = "tempbuild_sfw22", [9596] = "land_04_sfw", [9597] = "sandbch_sfw01", 
   [9598] = "sfw_boxwest02", [9599] = "vicbig_sfw1", [9600] = "road_SFW14", [9601] = "road_SFW15", [9602] = "road_SFW16", 
   [9603] = "road_16_sfw", [9604] = "frght_BOXES19", [9605] = "land_01_sfw", [9606] = "land_34_sfw", [9607] = "land_22_sfw", 
   [9608] = "ggate_park_sfw", [9609] = "land_37_sfw", [9610] = "land_42_sfw", [9611] = "land_43_sfw", [9612] = "ferrybit1_sfw", 
   [9613] = "ferrybit3_sfw", [9614] = "donuts2_sfw", [9615] = "donuts_sfw", [9616] = "land_20_sfw", [9617] = "boigagr_sfw", 
   [9618] = "scaff1_SFw", [9623] = "toll_SFW", [9624] = "spraysfw", [9625] = "spdr_sfw", [9652] = "road_SFW17", 
   [9653] = "road_SFW18", [9680] = "tramstat_SFW", [9682] = "carspaces1_sfw", [9683] = "ggbrig_07_sfw", [9685] = "ggbrig_02_sfw", 
   [9689] = "ggbrig_05_sfw", [9690] = "ggbrig_06_sfw", [9693] = "ggbrig_03_sfw", [9694] = "ggbrig_01_sfw", [9696] = "ggbrig_04_sfw", 
   [9697] = "carspaces3_sfw", [9698] = "BRIDGE_argh", [9699] = "road_SFW19", [9700] = "road_SFW20", [9701] = "road_SFW21", 
   [9702] = "road_SFW22", [9703] = "road_SFW23", [9704] = "road_SFW24", [9705] = "tunnel_sfw", [9706] = "road_SFW25", 
   [9707] = "road_SFW26", [9708] = "road_SFW27", [9709] = "road_SFW01", [9710] = "road_SFW29", [9711] = "road_SFW30", 
   [9712] = "road_SFW31", [9713] = "road_SFW32", [9714] = "road_SFW33", [9715] = "road_SFW34", [9716] = "road_sfw55", 
   [9717] = "road_SFW35", [9718] = "road_SFW36", [9719] = "road_SFW37", [9720] = "road_SFW38", [9721] = "road_SFW39", 
   [9722] = "road_SFW40", [9723] = "road_SFW41", [9724] = "road_SFW42", [9725] = "road_SFW43", [9726] = "road_SFW44", 
   [9727] = "road_SFW45", [9728] = "road_SFW46", [9729] = "road_SFW47", [9730] = "road_SFW48", [9731] = "road_SFW49", 
   [9732] = "road_SFW50", [9733] = "road_SFW51", [9734] = "road_SFW52", [9735] = "road_SFW53", [9736] = "road_SFW54", 
   [9737] = "blokmod3_sfw69", [9738] = "blokmod2_sfw69", [9739] = "newvic1_sfw69b", [9740] = "newvic1_sfw69", [9741] = "blokmod1_sfwc", 
   [9742] = "blokmod1_sfwb", [9743] = "rock_coastSFW2", [9744] = "rock_coastSFW1", [9745] = "rock_coastSFW3", [9746] = "rock_coastSFW4", 
   [9747] = "road_SFW90", [9748] = "sfw_boxwest03", [9749] = "sfw_boxwest01", [9750] = "sfw_boxwest05", [9751] = "sfw_boxwest06", 
   [9752] = "sfw_boxwest08", [9753] = "sfw_boxwest09", [9754] = "sfw_boxwest11", [9761] = "freight_alfa_SFW", [9762] = "sfw_boxwest07", 
   [9763] = "blokcut_sfw01", [9764] = "blokcut_sfw02", [9765] = "blokcut_sfw03", [9766] = "scaff3_SFw", [9767] = "scaff2_SFw", 
   [9812] = "veg_ivy_balcny_kb08", [9814] = "firscape_sfw01", [9815] = "firscape_sfw02", [9816] = "firscape_sfw03", [9817] = "scaff1b_SFw", 
   [9818] = "shpbridge_sfw01", [9819] = "shpbridge_sfw02", [9820] = "shpbridge_sfw04", [9821] = "shpbridge_sfw03", [9822] = "shpbridge_sfw08", 
   [9823] = "sav1sfw", [9824] = "diner_SFw", [9825] = "carspaces3_sfw02", [9827] = "road_SFW28", [9829] = "bumblister_SFW", 
   [9830] = "ggcarpark_sfw", [9831] = "sfw_waterfall", [9832] = "parkbridge_sfw", [9833] = "fountain_SFW", [9834] = "hosbibal3_sfw", 
   [9835] = "hosbibal4_sfw", [9836] = "hosbibal2_sfw", [9837] = "gg_split2_SFW", [9838] = "gg_split1_SFW", [9858] = "ferrybit69_sfw", 
   [9859] = "chinawning69b", [9860] = "chinawning69", [9863] = "land_21_sfw", [9864] = "land_18_sfw", [9885] = "sfw_nitlite1", 
   [9886] = "sfw_nitelite2", [9889] = "park3a_sfw", [9891] = "park2a_sfw", [9893] = "gardsfw02", [9894] = "blokmod2_sfw", 
   [9895] = "bigboxtmp19", [9896] = "hosbi2al_sfw", [9897] = "hosbibal3b_sfw", [9898] = "boigas_sfw05", [9899] = "sprasfw", 
   [9900] = "landshit_09_sfe", [9901] = "ferybuild_1", [9902] = "ferryland3", [9903] = "pier69_models07", [9904] = "pier69_models04", 
   [9905] = "pier69_models06", [9906] = "tempsf_2_sfe", [9907] = "monolith_sfe", [9908] = "anotherbuild091", [9909] = "vicstuff_sfe33", 
   [9910] = "fishwarf01", [9911] = "fishwarf06", [9912] = "fishwarf03", [9913] = "fishwarf04", [9914] = "fishwarf05", 
   [9915] = "sfe_park", [9916] = "jumpbuild_sfe", [9917] = "yet_another_sfe", [9918] = "posh2_sfe", [9919] = "grnwhite_sfe", 
   [9920] = "vicstuff_sfe6000", [9921] = "ferryshops1", [9922] = "ferryshops2", [9923] = "ferryshops3", [9924] = "ferryshops4", 
   [9925] = "ferryshops5", [9926] = "ferryshops07", [9927] = "sfe_redwht2", [9928] = "ferryshops08", [9929] = "boring_sfe", 
   [9930] = "nicepark_sfe", [9931] = "church_sfe", [9932] = "nitelites_sfe05", [9933] = "nitelites_sfe01", [9934] = "nitelites_sfe04", 
   [9946] = "pyrground_sfe", [9947] = "lbd_house1_sfe", [9948] = "lbd_house2_sfe", [9949] = "pier1_sfe", [9950] = "pier2_sfe", 
   [9951] = "pier3_sfe", [9952] = "vicstuff_sfe6006", [9953] = "ottos_AUTOS_sfe", [9954] = "pier69_sfe3", [9955] = "pier69_sfe1", 
   [9956] = "pier69_sfe2", [9957] = "multustor2_sfe", [9958] = "submarr_sfe", [10008] = "fer_cars2_sfe", [10009] = "fer_cars3_sfe", 
   [10010] = "ugcarpark_SFe", [10011] = "carspaces_sfe14", [10012] = "cables4", [10013] = "vicstuff_sfe17", [10014] = "vicstu69_sfe", 
   [10015] = "vicstu69b_sfe", [10016] = "vicnew_sfe04", [10017] = "bigvic_a1", [10018] = "tunnel_sfe", [10019] = "vicstuff_sfe45", 
   [10020] = "vicstuff_sfe22", [10021] = "vicstuff_sfe06", [10022] = "vicstuff_sfe04", [10023] = "sfe_archybald1", [10024] = "archbuild_wins", 
   [10025] = "chinatown_sfe2", [10026] = "fire_esc_SFE06", [10027] = "bigwhiete_SFE", [10028] = "copshop_sfe", [10029] = "copbits_sfe", 
   [10030] = "chinatown_sfe9", [10031] = "landshit_24_sfe", [10032] = "carspaces_sfe", [10033] = "fire_esc_SFE02", [10034] = "landshit_18_sfe", 
   [10035] = "chinatown_sfe20", [10036] = "chin_sfe1121", [10037] = "chbackbit8_sfe", [10038] = "chinatown_sfe8", [10039] = "chinatown_sfe1", 
   [10040] = "cables3", [10041] = "BIGCENTRAL_SFE", [10042] = "fescape2_sfe", [10043] = "vicstuff_sfe6004", [10044] = "sfe_swank1", 
   [10045] = "pinkbuild4_sfe", [10046] = "pinkbuild_sfe", [10047] = "monlith_ground", [10048] = "vicstuff_sfe66", [10049] = "Posh_thingsfe", 
   [10050] = "vicstuff_sfe50", [10051] = "carimp_SFE", [10052] = "lowmall", [10053] = "fishwarf20_sfe", [10054] = "fishwarf24_sfe", 
   [10055] = "fishwarf21_sfe", [10056] = "tempsf_4_sfe", [10057] = "nitelites_sfe10", [10058] = "nitelites_sfe11", [10060] = "aprtmnts01_sfe", 
   [10061] = "aprtmntrailgs01_SFe", [10062] = "aprtmntrailgs03_SFe", [10063] = "aprtmnts02_sfe", [10064] = "aprtmntrailgs02_SFe", [10065] = "road24_sfe", 
   [10066] = "road02_sfe", [10067] = "road05_sfe", [10068] = "road_07_sfe", [10069] = "road06_sfe", [10070] = "road08_sfe", 
   [10071] = "road09_sfe", [10072] = "road10_sfe", [10073] = "road11_sfe", [10074] = "road12_sfe", [10075] = "road_16_sfe01", 
   [10076] = "road13_sfe", [10077] = "road14_sfe", [10078] = "road15_sfe", [10079] = "pyr_top_SFe", [10080] = "fishwarf10_sfe", 
   [10083] = "backalleys1_sfe", [10084] = "fishwarf13_sfe", [10086] = "aprtmnts03_sfe", [10087] = "landsl01_sfe", [10101] = "vicstuff_sfe67", 
   [10110] = "road16_sfe", [10111] = "road17_sfe", [10112] = "road18_sfe", [10113] = "road19_sfe", [10114] = "road20_sfe", 
   [10115] = "road21_sfe", [10116] = "road22_sfe", [10117] = "road23_sfe", [10118] = "road01_sfe", [10119] = "road25_sfe", 
   [10120] = "road26_sfe", [10121] = "road27_sfe", [10122] = "road28_sfe", [10123] = "road29_sfe", [10124] = "road30_sfe", 
   [10125] = "road32_sfe", [10126] = "road33_sfe", [10127] = "road34_sfe", [10128] = "road35_sfe", [10129] = "road36_sfe", 
   [10130] = "road37_sfe", [10131] = "road38_sfe", [10132] = "road39_sfe", [10133] = "road40_sfe", [10134] = "road41_sfe", 
   [10135] = "road43_sfe", [10136] = "road44_sfe", [10137] = "road45_sfe", [10138] = "road46_sfe", [10139] = "road47_sfe", 
   [10140] = "freig2_intSFE", [10142] = "dwntwnsl01_sfe1", [10143] = "tempsf_1_sfe", [10145] = "genome_SFE", [10146] = "nitelites_sfe14", 
   [10147] = "nitelites_sfe15", [10148] = "bombshop", [10149] = "bombdoor02", [10150] = "fdorsfe", [10151] = "bigvicgrnd_sfe", 
   [10152] = "victimber1_sfe", [10153] = "victimber2_sfe", [10154] = "pier69gdr", [10165] = "pointybot_Sfe", [10166] = "p69_rocks", 
   [10173] = "fire_esc_SFE03", [10174] = "fire_esc_SFE04", [10175] = "fire_esc_SFE05", [10176] = "fire_esc_SFE01", [10177] = "fire_esc_SFE07", 
   [10178] = "fire_esc_SFE08", [10179] = "fire_esc_SFE09", [10180] = "fire_esc_SFE10", [10181] = "fire_esc_SFE11", [10182] = "michdr", 
   [10183] = "ferspaces", [10184] = "sfcopdr", [10185] = "lombardsteps", [10186] = "lombard3_sfe", [10187] = "vicnew_sfe01", 
   [10188] = "vicnew_sfe02", [10189] = "vicnew_sfe03", [10193] = "hotelbits_Sfe07", [10194] = "hotelbits_Sfe03", [10195] = "hotelbits_Sfe02", 
   [10196] = "hotelbits_Sfe01", [10197] = "hotelbits_Sfe04", [10226] = "shipbits2_sfe", [10227] = "shipbits1_sfe", [10228] = "freight_litesSFE", 
   [10229] = "freighter2b_SFE", [10230] = "freighter_sfe", [10231] = "freightboxes", [10233] = "carspaces_sfe15", [10234] = "fescape2b_sfe", 
   [10235] = "pointybotb_Sfe", [10236] = "hotelbits_Sfe06", [10242] = "hotelbits_Sfe05", [10244] = "vicjump_sfe", [10245] = "ottos_ramp", 
   [10246] = "sav1sfe", [10247] = "road37b_sfe", [10248] = "copcrates_sfe", [10249] = "ottos_bits", [10250] = "masts1_sfe", 
   [10252] = "china_town_gateb", [10255] = "chinawning07", [10260] = "pointybot22_Sfe", [10261] = "chinawning01", [10262] = "chinawning02", 
   [10263] = "chinawning03", [10264] = "chinawning04", [10265] = "chinawning05", [10266] = "chinawning06", [10267] = "cables16", 
   [10270] = "bigwhiete2_SFE", [10271] = "sfe_redwht2b", [10273] = "churchgr_sfe", [10274] = "churchgr2_sfe", [10275] = "road07_sfe", 
   [10276] = "road42_sfe", [10278] = "vicstu69c_sfe", [10280] = "lowbox_sfe", [10281] = "michsign_sfe", [10282] = "mich_int_sfe", 
   [10287] = "tempsf_4_sfe3", [10288] = "tempsf_4_sfe2", [10289] = "tempsf_3_sfe", [10290] = "garse_85_SFE", [10294] = "road03_sfe", 
   [10295] = "road04_sfe", [10296] = "road31_sfe", [10300] = "ferryland_sfe111", [10301] = "ferry_ncoast1_sfe", [10305] = "ferryland_sfe112", 
   [10306] = "vicstuff_sfe38", [10308] = "yet_another_sfe2", [10309] = "pier69_models05", [10310] = "boigas_sfe", [10350] = "OC_FLATS_GND01_SFS", 
   [10351] = "groundbit_10_SFS", [10352] = "groundbit_11_SFS", [10353] = "groundbit_12_SFS", [10354] = "groundbit_13_SFS", [10355] = "groundbit_48_SFS", 
   [10356] = "hashbury_01_SFS", [10357] = "transmitter_sfs", [10358] = "OC_FLATS_GND02_SFS", [10359] = "sfshill02", [10360] = "sfshill03", 
   [10361] = "sfshill04", [10362] = "sfshill05", [10363] = "sfshill06", [10364] = "sfshill07", [10365] = "roadbit21_SFS", 
   [10366] = "golftunnel1_SFS", [10367] = "roadbit38_SFS", [10368] = "cathedral_SFS", [10369] = "smallshop_10_SFS08", [10370] = "alley1_SFS", 
   [10371] = "alley1_SFS01", [10372] = "alley2_SFS01", [10373] = "alley2_SFS02", [10374] = "alley2_SFS04", [10375] = "subshop_SFS", 
   [10376] = "subshop2_SFS", [10377] = "cityhall_SFS", [10378] = "ctiyhallsquare_SFS", [10379] = "cityhall2_SFS", [10380] = "cityhall2_SFS01", 
   [10381] = "artgallery_SFS", [10382] = "alleyfuckingway_SFS", [10383] = "subshops3_SFS", [10384] = "cityhallsq_SFS", [10385] = "bbgroundbit_SFS", 
   [10386] = "sfshill09", [10387] = "cuntwland22_SFS", [10388] = "tempobj_SFS02", [10389] = "mission_07_SFS", [10390] = "mission_12_SFS", 
   [10391] = "mission_14_SFS", [10392] = "smallshop_10_SFS07", [10393] = "scum_SFS01", [10394] = "plot1_SFS", [10395] = "mission_13_SFS", 
   [10396] = "hc_tenfence_SFS", [10397] = "hc_stadlight1_SFS", [10398] = "healthclub_SFS", [10399] = "healthcl69_SFS", [10400] = "hc_grounds02_SFS", 
   [10401] = "hc_shed02_SFS", [10402] = "hc_secfence_SFS", [10403] = "hc_track02_SFS", [10404] = "hc_laybyland_SFS", [10405] = "hc_golfcrse02_SFS", 
   [10406] = "hc_grounds04_SFS", [10407] = "hc_golfcrse03_SFS", [10408] = "hc_golfcrse05_SFS", [10409] = "hc_golfcrse09_SFS", [10410] = "hc_golfcrse10_SFS", 
   [10411] = "shiteybit_SFS", [10412] = "poshotel1_SFS", [10413] = "groundbit_09_SFS", [10414] = "OC_FLATS_GND03_SFS", [10415] = "OC_FLATS_GND17_SFS", 
   [10416] = "OC_FLATS_GND16_SFS", [10417] = "OC_FLATS_GND06_SFS", [10418] = "sfshill13", [10419] = "OC_FLATS_GND07_SFS", [10420] = "OC_FLATS_GND08_SFS", 
   [10421] = "OC_FLATS_GND09_SFS", [10422] = "OC_FLATS_GND19_SFS", [10423] = "mission_15_SFS", [10424] = "ROADSsfs01", [10425] = "temphotel1_sfs", 
   [10426] = "backroad_SFS", [10427] = "haight_52_SFS", [10428] = "hashblock1_02_SFS", [10429] = "hashblock1_10_SFS", [10430] = "hashblock1_08_SFS", 
   [10431] = "hashbury_03_SFS", [10432] = "haight_17_SFS", [10433] = "hashbury_04_SFS", [10434] = "hashbury_05_SFS", [10435] = "shoppie6_SFS04", 
   [10436] = "hashblock1_09_SFS", [10437] = "hashfence_09_SFS", [10438] = "hashbury_07_SFS", [10439] = "hashbury_08_SFS", [10440] = "ROADSsfs09", 
   [10441] = "hashbury_10_SFS", [10442] = "graveyardwall_SFS", [10443] = "graveyard_SFS", [10444] = "poolwater_SFS", [10445] = "hotelback2", 
   [10446] = "hotelback1", [10447] = "hashupass_SFS", [10448] = "lastbit_08_SFS", [10449] = "ROADSsfs17", [10450] = "ROADSsfs16", 
   [10451] = "sfshill12", [10452] = "ROADSsfs39", [10453] = "sfshill14", [10454] = "sfshill15", [10455] = "ROADSsfs19", 
   [10456] = "ROADSsfs02", [10457] = "ROADSsfs03", [10458] = "ROADSsfs04", [10459] = "ROADSsfs05", [10460] = "ROADSsfs06", 
   [10461] = "ROADSsfs07", [10462] = "ROADSsfs08", [10463] = "ROADSsfs23", [10464] = "ROADSsfs10", [10465] = "ROADSsfs11", 
   [10466] = "ROADSsfs12", [10467] = "ROADSsfs13", [10468] = "ROADSsfs14", [10469] = "ROADSsfs15", [10470] = "ROADSsfs38", 
   [10471] = "ROADSsfs27", [10472] = "ROADSsfs18", [10473] = "ROADSsfs28", [10474] = "ROADSsfs20", [10475] = "ROADSsfs21", 
   [10476] = "ROADSsfs22", [10477] = "ROADSsfs30", [10478] = "ROADSsfs24", [10479] = "ROADSsfs25", [10480] = "ROADSsfs26", 
   [10481] = "ROADSsfs33", [10482] = "ROADSsfs29", [10483] = "ROADSsfs36", [10484] = "ROADSsfs32", [10485] = "ROADSsfs35", 
   [10486] = "ROADSsfs34", [10487] = "parktunnel_SFS", [10488] = "sfshill08", [10489] = "cuntwland18_SFS", [10490] = "sfshill01", 
   [10491] = "sfshill11_SFS", [10492] = "sfshill10", [10493] = "SV_ground_04_SFS", [10558] = "tbnSFS", [10559] = "sfshill11beach", 
   [10560] = "bbgroundbitb_SFS", [10561] = "bbgroundbitc_SFS", [10562] = "bbgroundbitd_SFS", [10563] = "OC_FLATS_GND18_SFS", [10564] = "OC_FLATS_GND11_SFS", 
   [10565] = "OC_FLATS_GND12_SFS", [10566] = "OC_FLATS_GND13_SFS", [10567] = "OC_FLATS_GND14_SFS", [10568] = "OC_FLATS_GND15_SFS", [10569] = "OC_FLATS_GND10_SFS", 
   [10570] = "OC_FLATS_GND05_SFS", [10571] = "OC_FLATS_GND04_SFS", [10572] = "golftunnel3_SFS", [10573] = "golftunnel2_SFS", [10574] = "golftunnel4_SFS", 
   [10575] = "modshopdoor1_SFS", [10576] = "modshopint1_SFS", [10601] = "sfshill10b", [10606] = "cluckbell_SFS", [10608] = "lastbit_GND01_SFS", 
   [10609] = "lastbit_GND02_SFS", [10610] = "fedmint_SFS", [10611] = "fedmintfence_SFS", [10612] = "fedmintland_SFS", [10613] = "lastbit_07_SFS", 
   [10614] = "lastbit_06_SFS", [10615] = "lastbit_04_SFS", [10616] = "lastbit_03_SFS", [10617] = "lastbit_01_SFS", [10618] = "lastbit_02_SFS", 
   [10619] = "officymirrord_SFS", [10621] = "pinkcarpark_SFS", [10622] = "pinkcarparkrd1_SFS", [10623] = "pinkcarparkrd2_SFS", [10624] = "lowqueens1_SFS", 
   [10625] = "lowqueens2_SFS", [10626] = "queens_09_SFS", [10627] = "queens_02_SFS", [10628] = "queens_03_SFS", [10629] = "queens_04_SFS", 
   [10630] = "queens_10_SFS", [10631] = "ammunation_SFS", [10632] = "ammuwindows_SFS", [10633] = "queens_01_SFS", [10634] = "queens_06_SFS", 
   [10635] = "queens_07_SFS", [10636] = "queens_05_SFS", [10637] = "queens_08_SFS", [10638] = "cityhallsq2_SFS", [10639] = "lastbit_06b_SFS", 
   [10649] = "lastbit_01b_SFS", [10651] = "pinkcarparkrd1b_SFS", [10671] = "savehousegdoor_SFS", [10672] = "fescape_sfs01", [10675] = "elecstionv_SFS", 
   [10676] = "transmitbldg_SFS", [10682] = "shitfence1_SFS", [10683] = "shitfence2_SFS", [10694] = "sfshill11z_SFS", [10695] = "wires_02_SFS", 
   [10696] = "wires_18_SFS", [10697] = "wires_03_SFS", [10698] = "wires_04_SFS", [10699] = "wires_05_SFS", [10700] = "wires_06_SFS", 
   [10701] = "wires_07_SFS", [10702] = "wires_08_SFS", [10703] = "wires_09_SFS", [10704] = "wires_01_SFS", [10705] = "wires_11_SFS", 
   [10706] = "wires_12_SFS", [10707] = "wires_13_SFS", [10708] = "wires_10_SFS", [10709] = "wires_14_SFS", [10710] = "wires_15_SFS", 
   [10711] = "wires_16_SFS", [10712] = "wires_17_SFS", [10713] = "gayclub_SFS", [10716] = "cath_hedge_SFS", [10718] = "poshotel1b_SFS", 
   [10722] = "shoppie6_SFS03", [10734] = "wires_07b_SFS", [10735] = "wires_07c_SFS", [10736] = "wires_07d_SFS", [10737] = "wires_04b_SFS", 
   [10738] = "wires_04c_SFS", [10739] = "wires_04d_SFS", [10740] = "wires_03b_SFS", [10741] = "wires_15b_SFS", [10742] = "wires_01b_SFS", 
   [10743] = "wires_01c_SFS", [10744] = "BS_building_SFS", [10750] = "roadsSFSE01", [10751] = "roadsSFSE02", [10752] = "just_stuff07_sfse", 
   [10753] = "roadsSFSE03", [10754] = "road_sfse12", [10755] = "Airport_02_SFSe", [10756] = "Airport_03_SFSe", [10757] = "Airport_04_SFSe", 
   [10758] = "Airport_05_SFSe", [10759] = "roadsSFSE04", [10760] = "Airport_07_SFSe", [10761] = "Airport_08_SFSe", [10762] = "Airport_09_SFSe", 
   [10763] = "controltower_SFSe", [10764] = "app_light_SFS05e", [10765] = "skidmarks_SFSe", [10766] = "Airport_10_SFSe", [10767] = "Airport_11_SFSe", 
   [10768] = "airprtgnd_06_SFSe", [10769] = "Airport_14_SFSe", [10770] = "CARRIER_BRIDGE_SFSe", [10771] = "CARRIER_HULL_SFSe", [10772] = "CARRIER_LINES_SFSe", 
   [10773] = "dk_cargoshp2_SFSe", [10774] = "dk_cargoshp1_SFS01e", [10775] = "bigfactory_SFSe", [10776] = "bigfactory2_SFSe", [10777] = "ddfreeway3_SFSe", 
   [10778] = "aircarpark_01_SFSe", [10779] = "aircarpark_06_SFSe", [10780] = "aircarpark_07_SFSe", [10781] = "aircarpark_08_SFSe", [10782] = "aircarpark_02_SFSe", 
   [10783] = "aircarpark_03_SFSe", [10784] = "aircarpark_04_SFSe", [10785] = "aircarpark_05_SFSe", [10786] = "aircarpark_09_SFSe", [10787] = "aircarpark_10_SFSe", 
   [10788] = "aircarpark_11_SFSe", [10789] = "xenonroof_SFSe", [10790] = "roadsSFSE05", [10791] = "roadsSFSE06", [10792] = "underfreeway_SFSe", 
   [10793] = "car_ship_03_SFSe", [10794] = "car_ship_04_SFSe", [10795] = "car_ship_05_SFSe", [10806] = "airfence_01_SFSe", [10807] = "airfence_04_SFSe", 
   [10808] = "airfence_03_SFSe", [10809] = "airfence_02_SFSe", [10810] = "ap_smallradar1_SFSe", [10811] = "apfuel1_SFSe", [10814] = "apfuel2_SFSe", 
   [10815] = "airprtgnd_02_SFSe", [10816] = "airprtgnd_01_SFSe", [10817] = "airprtgnd_03_SFSe", [10818] = "airprtgnd_04_SFSe", [10819] = "airprtgnd_05_SFSe", 
   [10820] = "baybridge1_SFSe", [10821] = "baybridge2_SFSe", [10822] = "baybridge3_SFSe", [10823] = "baybridge4_SFSe", [10824] = "subpen_int_SFSe", 
   [10825] = "subpen_crane_SFSe", [10826] = "subpen_ext_SFSe", [10827] = "subbunker_ext_SFSe", [10828] = "drydock1_SFSe", [10829] = "gatehouse1_SFSe", 
   [10830] = "drydock2_SFSe", [10831] = "drydock3_SFSe", [10832] = "gatehouse2_SFSe", [10833] = "navybase_02_SFSe", [10834] = "navybase_03_SFSe", 
   [10835] = "navyfence2_SFSe", [10836] = "apinnerfence3_SFSe", [10837] = "ap_bigsign_SFSe", [10838] = "airwelcomesign_SFSe", [10839] = "aircarpkbarier_SFSe", 
   [10840] = "bigshed_SFSe", [10841] = "drydock1_SFSe01", [10842] = "Airport_14_SFSe01", [10843] = "bigshed_SFSe01", [10844] = "gen_whouse01_SFSe", 
   [10845] = "gen_whouse02_SFSe", [10846] = "gen_whouse03_SFSe", [10847] = "gen_whouse03_SFSe01", [10848] = "roadsSFSE07", [10849] = "roadsSFSE08", 
   [10850] = "landbit01_SFSe", [10851] = "sfseland02", [10852] = "roadsSFSE09", [10854] = "roadsSFSE10", [10855] = "roadsSFSE11", 
   [10856] = "viet_03b_SFSe", [10857] = "roadsSFSE12", [10858] = "roadsSFSE13", [10859] = "roadsSFSE14", [10860] = "roadsSFSE15", 
   [10861] = "bigjunction_05_SFSe", [10862] = "bigjunction_06_SFSe", [10863] = "bigjunction_07_SFSe", [10864] = "bigjunction_08_SFSe", [10865] = "bigjunct_09_SFSe", 
   [10866] = "roadsSFSE16", [10867] = "roadsSFSE18", [10868] = "roadsSFSE19", [10869] = "roadsSFSE20", [10870] = "roadsSFSE21", 
   [10871] = "blacksky_SFSe", [10872] = "wc_lift_SFSe", [10873] = "blackskyrail_SFSe", [10874] = "apinnerfence1_SFSe", [10875] = "apinnerfence2_SFSe", 
   [10885] = "navyfence_SFSe", [10889] = "dockbarrier1_SFSe", [10890] = "dockbarrier2_SFSe", [10891] = "bakery_SFSe", [10903] = "sf_landbut02", 
   [10904] = "sf_landbut01", [10905] = "sfseland01", [10917] = "landbit01b_SFSe", [10925] = "shoppie1_SFS", [10926] = "groundbit_70_SFS", 
   [10927] = "trainstuff37_SFS22", [10928] = "roadsSFSE22", [10929] = "roadsSFSE23", [10930] = "roadsSFSE24", [10931] = "traintrax05_SFS", 
   [10932] = "station03_SFS", [10933] = "traintrax01_SFS", [10934] = "traintrax03_SFS", [10935] = "traintrax04_SFS", [10936] = "landbit04_SFS", 
   [10937] = "roadsSFSE25", [10938] = "Groundbit84_SFS", [10939] = "Silicon09B_SFS", [10940] = "roadsSFSE26", [10941] = "Silicon11_SFS", 
   [10942] = "Silicon12_SFS", [10943] = "SV_ground_02_SFS", [10944] = "southtunnel_04_SFS", [10945] = "skyscrap_SFS", [10946] = "fuuuuuuuck_SFS", 
   [10947] = "officy_SFS", [10948] = "skyscrapper_SFS", [10949] = "shoppie4_SFS", [10950] = "shoppie2_SFS", [10951] = "shoppie3_SFS", 
   [10952] = "shoppie6_SFS", [10953] = "shoppie5_SFS", [10954] = "stadium_SFSe", [10955] = "stadiumroof_SFS", [10956] = "southtunnel_01_SFS", 
   [10957] = "xsjmstran1", [10958] = "roadsSFSE27", [10959] = "cuntwland36_SFS", [10960] = "cuntwland37_SFS", [10961] = "cuntwland39_SFS", 
   [10962] = "cuntwland26_SFS", [10965] = "depot_SFS", [10966] = "tankfact03_SFS", [10967] = "roadsSFSE28", [10968] = "roadsSFSE29", 
   [10969] = "groundbit_06_SFS", [10970] = "roadsSFSE30", [10971] = "roadsSFSE31", [10972] = "landbit06_SFS", [10973] = "mall_03_SFS", 
   [10974] = "mall_01_SFS", [10975] = "shoppie6_SFS01", [10976] = "drivingsch_SFS", [10977] = "smallshop_16_SFS", [10978] = "smallshop_17_SFS", 
   [10979] = "haightshop_SFS", [10980] = "tempobj2_SFS02", [10981] = "scum_SFS", [10982] = "smallshop_10_SFS03", [10983] = "hub_SFS", 
   [10984] = "rubbled01_SFS", [10985] = "rubbled02_SFS", [10986] = "rubbled03_SFS", [10987] = "coveredpath1_SFS", [10988] = "mission_01_SFS", 
   [10989] = "mission_02_SFS", [10990] = "mission_04_SFS", [10991] = "mission_05_SFS", [10992] = "mission_03_SFS", [10993] = "mission_06_SFS", 
   [10994] = "shoppie6_SFS02", [10995] = "mission_08_SFS", [10996] = "smallshop_10_SFS05", [10997] = "smallshop_10_SFS06", [10998] = "mission_11_SFS", 
   [10999] = "haightshop_SFS02", [11000] = "smallshop_17_SFS01", [11001] = "mission_16_SFS", [11002] = "tempobj_SFS03", [11003] = "roadsSFSE32", 
   [11004] = "mission_18_SFS", [11005] = "mission_17_SFS", [11006] = "mission_09_SFS", [11007] = "crack_wins_SFS", [11008] = "firehouse_SFS", 
   [11009] = "dk_cargoshp70_SFS02", [11010] = "crackbuild_SFS", [11011] = "crackfactjump_SFS", [11012] = "crackfact_SFS", [11013] = "landbit05_SFS", 
   [11014] = "drivingschlgrg_SFS", [11015] = "drivingschoolex_SFS", [11071] = "roadsSFSE33", [11072] = "roadsSFSE36", [11073] = "roadsSFSE37", 
   [11074] = "roadsSFSE38", [11075] = "roadsSFSE39", [11076] = "roadsSFSE42", [11077] = "roadsSFSE43", [11078] = "roadsSFSE44", 
   [11079] = "roadsSFSE45", [11080] = "roadsSFSE46", [11081] = "crackfacttanks_SFS", [11082] = "landbit05b_SFS", [11083] = "drivingschlgnd_SFS", 
   [11084] = "roadsSFSE47", [11085] = "crack_int1", [11086] = "crack_int2", [11087] = "crackfactwalk", [11088] = "CF_ext_dem_SFS", 
   [11089] = "crackfacttanks2_SFS", [11090] = "crackfactvats_SFS", [11091] = "crackfactfence_SFS", [11092] = "burgalrystore_SFS", [11093] = "gen_whouse02_SFS", 
   [11094] = "roadsSFSE49", [11095] = "stadbridge_SFS", [11096] = "roadsSFSE50", [11097] = "vietland_SFS", [11098] = "roadsSFSE52", 
   [11099] = "drivingschskid_SFS", [11100] = "roadsSFSE53", [11101] = "newtunnelrail_SFS", [11102] = "burgalrydoor_SFS", [11103] = "cfsmashwin1_SFS", 
   [11104] = "newsfsroad", [11105] = "roadsSFSE54", [11106] = "landy", [11107] = "landy2", [11110] = "roadsSFSE55", 
   [11111] = "roadsSFSE57", [11112] = "roadsSFSE58", [11113] = "roadsSFSE59", [11114] = "roadsSFSE60", [11115] = "roadsSFSE61", 
   [11116] = "roadsSFSE62", [11117] = "roadsSFSE63", [11118] = "roadsSFSE64", [11119] = "roadsSFSE65", [11120] = "roadsSFSE66", 
   [11121] = "roadsSFSE68", [11122] = "roadsSFSE69", [11123] = "roadsSFSE70", [11124] = "roadsSFSE71", [11125] = "roadsSFSE72", 
   [11126] = "roadsSFSE73", [11127] = "roadsSFSE74", [11128] = "roadsSFSE75", [11129] = "roadsSFSE76", [11130] = "roadsSFSE77", 
   [11131] = "roadsSFSE78", [11132] = "roadsSFSE79", [11133] = "roadsSFSE80", [11134] = "roadsSFSE81", [11135] = "roadsSFSE82", 
   [11136] = "roadsSFSE83", [11137] = "roadsSFSE84", [11138] = "roadsSFSE51", [11139] = "firehouseland_SFS", [11145] = "CARRIER_LOWDECK_SFS", 
   [11146] = "CARRIER_HANGAR_SFS", [11147] = "acpipes1_SFS", [11148] = "acpipes2_SFS", [11149] = "accorridors_SFS", [11150] = "ab_ACC_control", 
   [11223] = "hubhole1_SFSe", [11224] = "hubhole2_SFSe", [11225] = "hubhole3_SFSe", [11226] = "hubhole4_SFSe", [11228] = "traintrax01b_SFS", 
   [11229] = "traintrax01c_SFS", [11230] = "traintrax01d_SFS", [11231] = "traintrax03b_SFS", [11232] = "traintrax03c_SFS", [11233] = "crackfactwalkb", 
   [11234] = "crackfactwalkc", [11235] = "crackfactwalkd", [11236] = "crackfactwalke", [11237] = "CARRIER_Bits_SFSe", [11238] = "dockbarrier2z_SFSe", 
   [11239] = "dockbarrier2zb_SFSe", [11240] = "dockbarrier2zc_SFSe", [11241] = "dockbarrier2zd_SFSe", [11242] = "dockbarrier2ze_SFSe", [11243] = "wall_cm_firehse", 
   [11244] = "gen_whouse02_SFS01", [11245] = "sfsefirehseflag", [11246] = "SFSETREEBIT", [11247] = "TREEBIT21", [11252] = "railbridge04_sfse", 
   [11253] = "railbridge08_sfse", [11254] = "railbridge06_sfse", [11255] = "railbridge03_sfse", [11256] = "railbridge09_sfse", [11257] = "railbridge05_sfse", 
   [11258] = "railbridge01_sfse", [11259] = "railbridge07_sfse", [11260] = "railbridge02_sfse", [11261] = "railbridge10_sfse", [11280] = "crackhseskid", 
   [11283] = "Airport_14B_SFSe", [11285] = "Airport_14C_SFSe", [11287] = "bigjunct_10B_SFSe", [11288] = "bigjuncT_10_SFSe", [11289] = "posters", 
   [11290] = "facttanks_SFSe04", [11292] = "gasstatiohut", [11293] = "facttanks_SFSe08", [11295] = "facttanks_SFSe09", [11297] = "Groundbit82_SFS", 
   [11299] = "roadsSFSE40", [11301] = "carshow4_SFSe", [11302] = "roadsSFSE17", [11303] = "bigjunction_15_SFSe", [11305] = "station", 
   [11306] = "station05_SFS", [11308] = "roadsSFSE41", [11312] = "modshop2_SFSe", [11313] = "modshopdoor_SFSe", [11314] = "modshopint2_SFSe", 
   [11315] = "sprayshopint_SFSe", [11316] = "Carshow3_SFSe", [11317] = "carshow_SFSe", [11318] = "Carshow2_SFSe", [11319] = "sprayshpdr2_SFSe", 
   [11324] = "station_lights", [11326] = "Sfse_hublockup", [11327] = "sfse_hub_grgdoor02", [11332] = "dkgrassbitsfse", [11334] = "recroomstuff", 
   [11335] = "sfselandy2", [11337] = "Stunnel_1A_SFSe", [11340] = "hub02_SFSe", [11342] = "southtunnel_03_SFS", [11343] = "southtunnel_03A_SFS", 
   [11345] = "roadsSFSE35", [11351] = "roadsSFSE48", [11352] = "StationStuff", [11353] = "station5new", [11359] = "oldgrgedoor3_sfse", 
   [11360] = "oldgrgedoor4_sfse", [11362] = "Silicon11_land", [11363] = "Silicon11_land2", [11364] = "Silicon09A_SFS", [11365] = "roadsSFSE67", 
   [11367] = "airprtgnd_ct_SFSe", [11374] = "accorail_SFS", [11379] = "baybALPHA_SFSe", [11380] = "baybALPH2_SFSe", [11381] = "baybALPH3_SFSe", 
   [11382] = "baybALPH4_SFSe", [11383] = "jjct02", [11384] = "cutseen1_sfse", [11385] = "ctscene2_sfse", [11386] = "nuroad_sfse", 
   [11387] = "oldgarage_SFS", [11388] = "hubintroof_SFSe", [11389] = "hubinterior_SFS", [11390] = "hubgirders_SFSE", [11391] = "hubprops6_SFSe", 
   [11392] = "hubfloorstains_SFSe", [11393] = "hubprops1_SFS", [11394] = "hubgrgbeams_SFSe", [11395] = "corvinsign_SFSe", [11396] = "stadiumgates_SFSe", 
   [11400] = "acwinch1b_SFS02", [11401] = "acwinch1b_SFS", [11406] = "acwinch1b_SFS01", [11408] = "viet_03_SFSe", [11409] = "roadsSFSE34", 
   [11410] = "nightlights01_SFSE", [11411] = "nightlights02_SFSE", [11412] = "nightlights03_SFSE", [11413] = "fosterflowers1", [11414] = "fosterflowers02", 
   [11416] = "hbgdSFS", [11417] = "xenonsign2_SFSe", [11420] = "con_lighth", [11421] = "roadsupp1_01", [11422] = "con_br1", 
   [11423] = "con_br2", [11424] = "con_tunll_sup03", [11425] = "des_adobehooses1", [11426] = "des_adobe03", [11427] = "des_adobech", 
   [11428] = "des_indruin02", [11429] = "nw_bit_31", [11430] = "sw_bit_13", [11431] = "des_tepeoff01", [11432] = "des_tepesign01", 
   [11433] = "adobe_hoose2", [11434] = "des_indianstore", [11435] = "des_indsign1", [11436] = "des_indshops1", [11437] = "des_indchfenc", 
   [11438] = "des_indtpfenc", [11439] = "des_woodbr_", [11440] = "des_pueblo1", [11441] = "des_pueblo5", [11442] = "des_pueblo3", 
   [11443] = "des_pueblo4", [11444] = "des_pueblo2", [11445] = "des_pueblo06", [11446] = "des_pueblo07", [11447] = "des_pueblo08", 
   [11448] = "des_railbr_twr1", [11449] = "des_nwtshop2", [11450] = "des_nwtshop07", [11451] = "des_nwsherrif", [11452] = "des_nwshfenc", 
   [11453] = "des_sherrifsgn1", [11454] = "des_nwmedcen", [11455] = "des_medcensgn01", [11456] = "des_nwtshop10", [11457] = "des_pueblo09", 
   [11458] = "des_pueblo10", [11459] = "des_pueblo11", [11460] = "des_telewires03", [11461] = "des_nwwtower", [11462] = "des_railbridge1", 
   [11463] = "des_railbr_twr05", [11464] = "des_trainline02", [11465] = "des_trainline03", [11466] = "des_trainline04", [11467] = "des_trainline05", 
   [11468] = "des_railstruct1_", [11469] = "des_bullgrill_", [11470] = "des_bigbull", [11471] = "des_swtshop14", [11472] = "des_swtstairs1", 
   [11473] = "des_swtfence1", [11474] = "des_swtfence2", [11475] = "des_swtshop02", [11476] = "swt_teline_02", [11477] = "swt_teline_03", 
   [11478] = "swt_teline_01", [11479] = "des_nwtfescape", [11480] = "des_nwt_carport", [11481] = "des_railfenc1", [11482] = "des_railfenc2", 
   [11483] = "des_railjump02", [11484] = "dam_turbine_4", [11485] = "dam_turbine_3", [11486] = "dam_turbine_2", [11487] = "dam_turbine_1", 
   [11488] = "dam_statarea", [11489] = "dam_statues", [11490] = "des_ranch", [11491] = "des_ranchbits1", [11492] = "des_rshed1_", 
   [11493] = "des_ranchbot", [11494] = "des_rnchbhous", [11495] = "des_ranchjetty", [11496] = "des_wjetty", [11497] = "des_baitshop", 
   [11498] = "des_rockgp2_27", [11499] = "des_dinerfenc01", [11500] = "des_skelsignbush_", [11501] = "des_westrn9_03", [11502] = "des_weebarn1_", 
   [11503] = "des_westrn11_05", [11504] = "des_garagew", [11505] = "des_garwcanopy", [11506] = "nw_bit_02", [11507] = "nw_bit_03", 
   [11508] = "nw_bit_04", [11509] = "nw_bit_07", [11510] = "nw_bit_08", [11511] = "nw_bit_09", [11512] = "nw_bit_10", 
   [11513] = "nw_bit_11", [11514] = "nw_bit_12", [11515] = "nw_bit_13", [11516] = "nw_bit_14", [11517] = "nw_bit_15", 
   [11518] = "nw_bit_16", [11519] = "nw_bit_17", [11520] = "nw_bit_18", [11521] = "nw_bit_19", [11522] = "nw_bit_20", 
   [11523] = "nw_bit_21", [11524] = "nw_bit_22", [11525] = "nw_bit_23", [11526] = "nw_bit_24", [11527] = "nw_bit_25", 
   [11528] = "nw_bit_26", [11529] = "nw_bit_27", [11530] = "nw_bit_28", [11531] = "nw_bit_30", [11532] = "sw_bit_03", 
   [11533] = "sw_bit_04", [11534] = "sw_bit_05", [11535] = "sw_bit_06", [11536] = "sw_bit_08", [11537] = "sw_bit_11", 
   [11538] = "sw_bit_12", [11539] = "dambit1", [11540] = "dambit2", [11541] = "dambit3", [11542] = "sw_bit_14", 
   [11543] = "des_warehs", [11544] = "des_ntfrescape2", [11545] = "desn_tsblock", [11546] = "desn_fuelpay", [11547] = "desn_tscanopy", 
   [11548] = "cnts_lines", [11549] = "des_decocafe", [11550] = "cn_nbridegrails", [11551] = "cn_tunlbarrier", [11552] = "nw_bit_29", 
   [11553] = "sw_bit_01", [11554] = "sw_bit_02", [11555] = "sw_bit_15", [11556] = "des_adrocks", [11557] = "sw_bit_09", 
   [11558] = "cn_sta_grid_03", [11559] = "sw_bit_07", [11560] = "sw_bit_10", [11561] = "cn_teline_01", [11562] = "cn_teline_02", 
   [11563] = "cn_teline_03", [11564] = "swt_teline_04", [11565] = "swt_teline_05", [11566] = "des_tepeoff02", [11567] = "des_rvstuff", 
   [11568] = "des_clifftwal", [11571] = "sw_teline_05", [11572] = "con_br06", [11579] = "des_damlodbit3", [11580] = "damlodbit1", 
   [11581] = "damlodbit2", [11607] = "sw_teline_06", [11608] = "pylon-wires03", [11609] = "pylon-wires11", [11610] = "Pylonwires_new", 
   [11611] = "des_sherrifsgn02", [11615] = "desN_baitshop", [11623] = "n_dambarriers", [11625] = "cn_wires", [11626] = "cn_wires1", 
   [11627] = "cn_wires2", [11628] = "nw_bit_06", [11629] = "nw_bit_01", [11631] = "ranch_desk", [11647] = "nw_bit_05", 
   [11663] = "toreno_shadow", [11664] = "kb_couch02ext", [11665] = "kb_chair03ext", [11666] = "Frame_WOOD_1ext", [11674] = "des_cluckin", 
   [11677] = "xen2_countN", [11678] = "desn_detail01", [11679] = "desn_detail02", [11680] = "desn_detail03", [11681] = "desn_detail04", 
   [11682] = "CutsceneCouch1", [11683] = "CutsceneCouch2", [11684] = "CutsceneCouch3", [11685] = "CutsceneCouch4", [11686] = "CBarSection1", 
   [11687] = "CBarStool1", [11688] = "CWorkTop1", [11689] = "CBoothSeat1", [11690] = "CTable1", [11691] = "CTable2", 
   [11692] = "A51LandBit1", [11693] = "Hills250x250Grass1", [11694] = "Hill250x250Rocky1", [11695] = "Hill250x250Rocky2", [11696] = "Hill250x250Rocky3", 
   [11697] = "RopeBridgePart1", [11698] = "RopeBridgePart2", [11699] = "SAMPRoadSign46", [11700] = "SAMPRoadSign47", [11701] = "AmbulanceLights1", 
   [11702] = "AmbulanceLights2", [11703] = "MagnoCrane_03_2", [11704] = "BDupsMask1", [11705] = "BlackTelephone1", [11706] = "SmallWasteBin1", 
   [11707] = "TowelRack1", [11708] = "BrickSingle1", [11709] = "AbattoirSink1", [11710] = "FireExitSign1", [11711] = "ExitSign1", 
   [11712] = "Cross1", [11713] = "FireExtPanel1", [11714] = "MaintenanceDoors1", [11715] = "MetalFork1", [11716] = "MetalKnife1", 
   [11717] = "WooziesCouch1", [11718] = "SweetsSaucepan1", [11719] = "SweetsSaucepan2", [11720] = "SweetsBed1", [11721] = "Radiator1", 
   [11722] = "SauceBottle1", [11723] = "SauceBottle2", [11724] = "FireplaceSurround1", [11725] = "Fireplace1", [11726] = "HangingLight1", 
   [11727] = "PaperChaseLight1", [11728] = "PaperChasePhone1", [11729] = "GymLockerClosed1", [11730] = "GymLockerOpen1", [11731] = "WHeartBed1", 
   [11732] = "WHeartBath1", [11733] = "WRockingHorse1", [11734] = "WRockingChair1", [11735] = "WBoot1", [11736] = "MedicalSatchel1", 
   [11737] = "RockstarMat1", [11738] = "MedicCase1", [11739] = "MCake1", [11740] = "MCake2", [11741] = "MCake3", 
   [11742] = "MCakeSlice1", [11743] = "MCoffeeMachine1", [11744] = "MPlate1", [11745] = "HoldAllEdited1", [11746] = "DoorKey1", 
   [11747] = "Bandage1", [11748] = "BandagePack1", [11749] = "CSHandcuffs1", [11750] = "CSHandcuffs2", [11751] = "AreaBoundary50m", 
   [11752] = "AreaBoundary10m", [11753] = "AreaBoundary1m", [12800] = "cunte_roads01", [12801] = "cunte_roads03", [12802] = "cunte_roads04", 
   [12803] = "cunte_roads06", [12804] = "cuntEground01", [12805] = "CE_bigshed1", [12806] = "cunte_roads08", [12807] = "sw_logs4", 
   [12808] = "sw_logs3", [12809] = "cunte_roads11", [12810] = "cunte_roads12", [12811] = "cunte_roads13", [12812] = "cunte_roads14", 
   [12813] = "cunte_roads15", [12814] = "cuntyeland04", [12815] = "cunte_roads16", [12816] = "cunte_roads17", [12817] = "cunte_roads19", 
   [12818] = "cunte_roads20", [12819] = "cunte_roads21", [12820] = "cunte_roads22", [12821] = "cratesinalley", [12822] = "smalltwnbld05", 
   [12823] = "cuntEground02", [12824] = "CEgroundTP104", [12825] = "cuntEground08", [12826] = "cunte_roads23", [12827] = "cunte_roads24", 
   [12828] = "cunte_roads25", [12829] = "cunte_roads26", [12830] = "cunte_roads27", [12831] = "coe_traintrax_10", [12832] = "coe_traintrax_03", 
   [12833] = "coe_traintrax_04", [12835] = "coe_traintrax_06", [12836] = "coe_traintrax_07", [12837] = "coe_traintrax_08", [12838] = "coe_traintrax_09", 
   [12839] = "cos_sbanksteps02", [12840] = "cos_pizskyglas01", [12841] = "cos_pizinterior", [12842] = "cos_pizseats", [12843] = "cos_liquorshop", 
   [12844] = "cos_liqinside", [12845] = "cos_liqinsidebits", [12846] = "otb_sign", [12847] = "sprunk_fact", [12848] = "coe_sprunlkfenc", 
   [12849] = "CornerStore_01", [12850] = "sw_block01", [12851] = "cunte_roads29", [12852] = "cunte_roads30", [12853] = "sw_gas01", 
   [12854] = "sw_gas01int", [12855] = "sw_copshop", [12856] = "sw_bridge", [12857] = "CE_bridge02", [12858] = "sw_gate1", 
   [12859] = "sw_cont03", [12860] = "sw_cont04", [12861] = "sw_cont05", [12862] = "sw_block03", [12863] = "sw_genstore02", 
   [12864] = "cuntEground11", [12865] = "cuntEground13", [12866] = "CEgroundT202", [12867] = "cunte_roads32", [12868] = "cuntEground26", 
   [12869] = "cyecuntEground28", [12870] = "CE_grndPALCST06", [12871] = "cuntEground34", [12872] = "cuntEground43", [12873] = "cunte_roads33", 
   [12874] = "cunte_roads34", [12875] = "cunte_roads35", [12876] = "cunte_roads39", [12877] = "cunte_roads40", [12878] = "cunte_roads41", 
   [12879] = "cunte_roads42", [12880] = "cunte_roads43", [12881] = "cunte_roads44", [12882] = "cunte_roads45", [12883] = "cunte_roads46", 
   [12884] = "cunte_roads47", [12885] = "cunte_roads48", [12886] = "cunte_roads49", [12887] = "cunte_roads50", [12888] = "cunte_roads51", 
   [12889] = "cunte_roads52", [12890] = "cunte_roads54", [12891] = "cunte_roads56", [12892] = "cunteroads_58", [12893] = "cunte_roads59", 
   [12894] = "cunte_roads60", [12895] = "cunte_roads61", [12896] = "cunte_roads62", [12897] = "cunte_roads63", [12898] = "cunte_roads69", 
   [12899] = "cunte_roads71", [12900] = "cunte_roads72", [12901] = "cunte_roads73", [12902] = "cunte_roads74", [12903] = "cunte_roads75", 
   [12904] = "cuntetownrd1", [12905] = "cuntetownrd2", [12906] = "cuntetownrd3", [12907] = "cuntetownrd4", [12908] = "cuntEground09b", 
   [12909] = "sw_bridge03", [12910] = "sw_trainbridge1", [12911] = "sw_Silo02", [12912] = "sw_Silo04", [12913] = "sw_fueldrum03", 
   [12914] = "sw_corrug01", [12915] = "CE_bigbarn07", [12916] = "CE_farmland04", [12917] = "sw_haypile03", [12918] = "sw_haypile05", 
   [12919] = "sw_tempbarn06", [12920] = "sw_tempbarn02", [12921] = "sw_farment01", [12922] = "sw_farment02", [12923] = "sw_blockbit05", 
   [12924] = "sw_block06", [12925] = "sw_SHED01", [12926] = "sw_sheds_base", [12927] = "sw_pipepile01", [12928] = "sw_shedInterior04", 
   [12929] = "sw_SHED06", [12930] = "sw_pipepile02", [12931] = "CE_brewery", [12932] = "sw_trailer02", [12933] = "sw_breweryFence01", 
   [12934] = "sw_trailer03", [12935] = "sw_securitycab03", [12936] = "sw_beersign02", [12937] = "CE_CATshack", [12938] = "sw_apartments02", 
   [12939] = "sw_apartmentsBase", [12940] = "sw_apartments07", [12941] = "sw_LastDrop", [12942] = "sw_shedInterior01", [12943] = "sw_SHED07", 
   [12944] = "sw_lasershop", [12945] = "sw_dryclean01", [12946] = "sw_furnistore01", [12947] = "sw_musicstore01", [12948] = "sw_block01a", 
   [12949] = "sw_jazzmags", [12950] = "cos_sbanksteps03", [12951] = "sw_shopflat01", [12952] = "sw_bankalley", [12953] = "sw_blockbit01", 
   [12954] = "sw_furnipile01", [12955] = "dock_props01", [12956] = "sw_trailerjump", [12957] = "sw_pickupwreck01", [12958] = "cos_sbanksteps01", 
   [12959] = "sw_library", [12960] = "sw_church01", [12961] = "sw_hedstones", [12962] = "sw_shopflat04", [12963] = "sw_shopflat02", 
   [12964] = "sw_block07", [12965] = "cunte_roads10", [12966] = "cunte_roads66", [12967] = "cunte_roads67", [12968] = "cunte_roads68", 
   [12969] = "CE_ground08", [12970] = "cunte_roads76", [12971] = "cunte_roads78", [12972] = "sw_bridge01", [12973] = "roadfromLAN2", 
   [12974] = "cunte_roads40a", [12975] = "cunteroads43ramp01", [12976] = "sw_diner1", [12977] = "cratesinalley01", [12978] = "sw_SHED02", 
   [12979] = "sw_block09", [12980] = "sw_block10", [12981] = "sw_fact01", [12982] = "sw_shopflat06", [12983] = "sw_med1", 
   [12984] = "sw_block11", [12985] = "cos_sbanksteps05", [12986] = "sw_well1", [12987] = "cos_sbanksteps06", [12988] = "sw_fact02", 
   [12989] = "cuntEground06", [12990] = "sw_jetty", [12991] = "sw_shack02", [12992] = "CE_archbridge", [12993] = "cunte_roads09", 
   [12994] = "cunte_roads57", [12995] = "cunte_roads64", [12996] = "cunte_roads65", [12997] = "cunte_roads77", [12998] = "cunte_roads80", 
   [12999] = "cunte_roads82", [13000] = "cunte_roads83", [13001] = "cunte_roads84", [13002] = "cuntebigbarn", [13003] = "cunte_racestart", 
   [13004] = "sw_logs01", [13005] = "sw_logs6", [13006] = "sw_office1", [13007] = "sw_bankbits", [13008] = "sw_block02", 
   [13009] = "sw_block02alpha", [13010] = "sw_Block01alpha", [13011] = "cos_sbanksteps04", [13012] = "sw_shopflat05", [13013] = "sw_block12", 
   [13014] = "sw_block04", [13015] = "sw_genstore01", [13016] = "sw_block04COL27", [13017] = "CEhollyhil16", [13018] = "CEmulwire03", 
   [13019] = "CEhollyhil17", [13020] = "CEroadTEMP2", [13021] = "CEhllyhil01a", [13022] = "sw_block11a", [13023] = "sw_rocks1", 
   [13024] = "sw_breweryFence02", [13025] = "sw_fueldrum01", [13027] = "ce_spray", [13028] = "CE_spraydoor1", [13030] = "cuntEground34a", 
   [13033] = "cunte_roads30bar", [13034] = "cunte_roads30bar01", [13035] = "cuntEground12a", [13036] = "cuntEgund11a", [13038] = "cunte_roads35a", 
   [13039] = "CE_ground02", [13040] = "CE_ground03", [13041] = "CE_ground04", [13042] = "CE_ground05", [13043] = "CE_ground06", 
   [13044] = "CE_ground07", [13045] = "cunte_roads30bar02", [13049] = "CE_farmland01", [13050] = "CE_farmland02", [13051] = "CE_farmland03", 
   [13058] = "cunte_roads11a", [13059] = "CEfact03", [13060] = "CE_factcomp1", [13061] = "CE_factcomp2", [13065] = "sw_fact03", 
   [13066] = "sw_fact04", [13070] = "CEgroundTP101", [13071] = "CEgroundTP102", [13072] = "CEgroundTP103", [13077] = "CE_townware", 
   [13078] = "CEwrehse07", [13081] = "CEgroundT206", [13082] = "CEgroundT203", [13083] = "CEgroundT204", [13084] = "CEgroundT205", 
   [13088] = "cuntetownrd4a", [13092] = "cuntetownrd05", [13095] = "cunte_roads02", [13096] = "cunte_roadsbar01", [13097] = "cunte_roads30bar06", 
   [13098] = "cunte_roadsbar05", [13099] = "CE_groundPALO06", [13100] = "CE_groundPALO02", [13101] = "CE_groundPALO03", [13102] = "CE_groundPALO04", 
   [13103] = "CE_groundPALO05", [13104] = "CE_groundPALO01", [13105] = "CE_groundPALO07", [13106] = "CE_groundPALO08", [13107] = "CE_groundPALO10", 
   [13109] = "sw_watertower04", [13118] = "cunte_roadsbar02", [13119] = "cunte_roads37", [13120] = "CE_grndPALCST03", [13121] = "CE_grndPALCST04", 
   [13122] = "CE_grndPALCST01", [13123] = "CE_grndPALCST07", [13124] = "CE_grndPALCST08", [13125] = "CE_grndPALCST09", [13126] = "CE_grndPALCST10", 
   [13127] = "cunte_roads81", [13128] = "cunte_roads79", [13129] = "cunte_roads85", [13131] = "sw_block05", [13132] = "CE_bar01", 
   [13134] = "cuntEground03", [13135] = "cyecuntEground01", [13136] = "cyecuntEground02", [13137] = "CEwirestown", [13138] = "CE_archbridge2", 
   [13139] = "cuntetunnel1", [13140] = "cuntetunnel1A", [13141] = "cunte_roads58B", [13142] = "CE_Bbridge", [13143] = "CEmulwire02", 
   [13144] = "cuntEground04", [13145] = "cuntEground05", [13146] = "cuntEground07", [13147] = "cuntEground09", [13148] = "cuntEground10", 
   [13149] = "cuntEground17", [13150] = "cuntEground19", [13153] = "cunte_roads30bar03", [13156] = "cuntEground21", [13157] = "cuntEground22", 
   [13158] = "cuntEground27", [13163] = "CE_groundPALO11", [13165] = "CE_groundPALO12", [13167] = "cyecuntEground03", [13168] = "cunte_roads58", 
   [13169] = "cunte_roads86", [13170] = "cunte_roads87", [13171] = "cuntEgd12a01", [13172] = "cuntEgd12a02", [13173] = "cunte_roads88", 
   [13174] = "cunte_roots01", [13175] = "cuntEground18", [13176] = "cuntEground29", [13177] = "cuntEground30", [13178] = "cuntEground31", 
   [13179] = "cuntEground32", [13180] = "cuntEground33", [13181] = "cuntEground35", [13187] = "burbdoor", [13188] = "burbdoor2", 
   [13190] = "CE_busdepot", [13198] = "CE_waretank", [13205] = "CE_wires", [13206] = "CEtruth_barn02", [13207] = "cuntEground12", 
   [13208] = "cuntEground15", [13209] = "cuntEground36", [13210] = "cuntEground37", [13211] = "cuntEground38", [13212] = "cuntEground39", 
   [13213] = "cuntEground40", [13214] = "cuntEground41", [13235] = "cuntehil01", [13236] = "cuntehil02", [13237] = "cuntehil03", 
   [13295] = "CE_terminal1", [13296] = "CE_roadsidegas", [13297] = "CEgroundT201", [13312] = "coe_traintrax_05", [13321] = "cunte_roads07", 
   [13323] = "cunte_roads18", [13324] = "cunte_roads38", [13325] = "cunte_roads89", [13332] = "CE_multibridge1", [13336] = "cunte_roads46walls", 
   [13342] = "cunte_roads31", [13345] = "cunte_roads36", [13347] = "cunte_roads26W", [13348] = "cunte_roads23W", [13349] = "cunte_roads27W", 
   [13360] = "CE_CATshackdoor", [13361] = "CE_pizza1", [13363] = "CE_photoblock", [13364] = "CE_wtownblok1", [13367] = "sw_watertower01", 
   [13368] = "CE_bridgebase1", [13369] = "sw_logs07", [13370] = "CEhllyhil03a", [13371] = "CEhllyhil02a", [13374] = "CEwirestown01", 
   [13375] = "CEwirestown02", [13422] = "cunte_roads05a", [13435] = "sw_logs08", [13436] = "CE_wires01", [13437] = "CE_wires02", 
   [13438] = "sw_church01fnce", [13439] = "CE_wires03", [13440] = "CEwirestown04", [13441] = "CEwirestown05", [13442] = "CEwirestown06", 
   [13443] = "CEwirestown03", [13444] = "CEwirestown07", [13445] = "cunteroads05aFNCE", [13447] = "CE_wires04", [13448] = "CE_wires05", 
   [13449] = "CE_wires06", [13450] = "CE_apartStairs", [13451] = "CEwirestown08", [13452] = "CEwirestown09", [13461] = "CE_nitewindows1", 
   [13470] = "cunte_roads303", [13484] = "CE_nitewindows101", [13485] = "CE_nitewindows10", [13486] = "CE_ground09", [13489] = "sw_fueldrum04", 
   [13490] = "CE_ground01", [13491] = "coe_traintrax02", [13493] = "CE_nitewindows2", [13494] = "CE_groundPALO12A", [13495] = "CE_ground03A", 
   [13496] = "CE_groundPALO07A", [13497] = "CE_grndPALCST04A", [13498] = "CE_grndPALCST01A", [13499] = "CE_grndPALCST03A", [13500] = "cuntEground21A", 
   [13501] = "cuntEground22A", [13502] = "cuntEground07A", [13503] = "cuntEground02A", [13504] = "CE_grndPALCST07A", [13505] = "cuntEground03A", 
   [13506] = "cuntEground05A", [13507] = "cuntEground04A", [13508] = "cyecuntEground02A", [13509] = "cyecuntEground28A", [13510] = "CE_grndPALCST08A", 
   [13511] = "CE_grndPALCST09A", [13512] = "CE_groundPALO03A", [13513] = "CE_groundPALO04A", [13514] = "cuntEground10A", [13515] = "cuntEground09A", 
   [13516] = "cuntEground19A", [13517] = "cuntEground26A", [13518] = "CE_groundPALO06A", [13519] = "CEgroundT205A", [13520] = "CEgroundT201A", 
   [13521] = "CEgroundT206A", [13522] = "CEgroundTP104A", [13523] = "CEgroundTP103A", [13524] = "cuntEground43A", [13525] = "cuntEground17A", 
   [13526] = "cuntEground18A", [13527] = "cuntEground29A", [13528] = "cuntEground39A", [13529] = "cuntehil03A", [13530] = "cuntehil02A", 
   [13531] = "cuntehil01A", [13532] = "CEhllyhil03aA", [13533] = "CEhllyhil02aA", [13534] = "CEhllyhil01aA", [13535] = "cuntEground38A", 
   [13536] = "cuntEground40A", [13537] = "cuntEground32A", [13538] = "cuntEground01A", [13539] = "CE_farmland04A", [13540] = "CE_farmland03A", 
   [13541] = "cuntEground34A01", [13542] = "cuntEground34aA", [13543] = "cuntEground09bA", [13544] = "cuntEground15A", [13545] = "cuntEground37A", 
   [13546] = "cuntEground36A", [13547] = "cuntEgund11aA", [13548] = "cuntEground11A", [13549] = "CEhollyhil17A", [13550] = "CEhollyhil16A", 
   [13551] = "cuntEground08A", [13552] = "CE_ground01A", [13553] = "CE_ground09A", [13554] = "CE_ground02A", [13555] = "CE_ground05A", 
   [13556] = "CE_ground06A", [13557] = "CE_ground08A", [13558] = "CE_ground04A", [13559] = "CE_ground07A", [13560] = "cuntEground33A", 
   [13561] = "cuntEground31A", [13562] = "bigsprunkpole", [13563] = "cuntEground30A", [13590] = "kickbus04", [13591] = "kickcar28", 
   [13592] = "loopbig", [13593] = "kickramp03", [13594] = "fireyfire", [13595] = "stand02", [13596] = "destruct04", 
   [13597] = "destruct05", [13598] = "stand03", [13599] = "standblack04", [13600] = "destruct06", [13601] = "destruct07", 
   [13602] = "thebolla06", [13603] = "stad_tag", [13604] = "kickramp05", [13605] = "destruct1", [13606] = "standblack02", 
   [13607] = "ringwalls", [13608] = "sumoring", [13609] = "supports", [13610] = "stand04", [13611] = "thebowl13", 
   [13612] = "stuntman03", [13613] = "thebowl11", [13614] = "thebowl12", [13615] = "thebowl10", [13616] = "thebolla04", 
   [13617] = "thebowl14", [13618] = "thebowl16", [13619] = "thebowl17", [13620] = "thebowl15", [13621] = "thebolla03", 
   [13622] = "sumofence", [13623] = "midringfence", [13624] = "inner", [13625] = "stands", [13626] = "8road2", 
   [13627] = "stadoval", [13628] = "8stad", [13629] = "8screen01", [13630] = "8screen", [13631] = "dirtstad", 
   [13632] = "dirtcrowds", [13633] = "dirtouter01", [13634] = "dirtstad02", [13635] = "therocks10", [13636] = "logramps", 
   [13637] = "tuberamp", [13638] = "stunt1", [13639] = "ramparse", [13640] = "arse", [13641] = "kickramp04", 
   [13642] = "rings", [13643] = "logramps02", [13644] = "steps", [13645] = "kickramp06", [13646] = "ramplandpad", 
   [13647] = "wall1", [13648] = "wall2", [13649] = "ramplandpad01", [13650] = "kickcrowd01", [13651] = "otunnel", 
   [13652] = "oroadbit", [13653] = "innerfence", [13654] = "darkpoly", [13655] = "bridge", [13656] = "fuckknows", 
   [13657] = "bit", [13658] = "bit01", [13659] = "8bar5", [13660] = "8track1", [13661] = "cockbars", 
   [13662] = "dirtcock", [13663] = "dirtfences", [13664] = "dirtroad", [13665] = "dirtfences2", [13666] = "loopwee", 
   [13667] = "monkeyman", [13672] = "cunte_roads05", [13673] = "CEhollyhil03", [13674] = "CEmullholdr05", [13675] = "cuntelungrdj", 
   [13676] = "TCElawcuntun1a_law2", [13677] = "TCElawcuntuna_law2", [13678] = "CEnwhiltest", [13679] = "TCElandbivF4v_03", [13680] = "TCElawcuntunb", 
   [13681] = "TCEhilhouse03", [13682] = "TCEcuntun", [13683] = "CEnwhiltest2", [13684] = "CEnwhiltest93", [13685] = "TCEnwhiltest92", 
   [13686] = "TCEhomulhil10", [13687] = "TCEhillhse02", [13688] = "CEnwhiltest91", [13689] = "CEnwhiltest6", [13690] = "CE_Roads38a", 
   [13691] = "TCELAlandbiv_03", [13692] = "cunte_landF4_03", [13693] = "TCEnwhiltest94", [13694] = "CEhillhse13", [13695] = "CEhillhse05", 
   [13696] = "CEnewhillhus", [13697] = "TCElhouse06", [13698] = "CEhollyhil10", [13699] = "TCEmulhilhed1_law2", [13700] = "CEhollyhil1", 
   [13701] = "TCEhilouse02", [13702] = "CEhollyhil09X", [13703] = "CEnwhiltest3", [13704] = "CEnwhiltest5", [13705] = "CEhillbar2b", 
   [13706] = "CE_roads87", [13707] = "CEla_roads62", [13708] = "CE_roadscoast08", [13709] = "lae2_ground01", [13710] = "HillsEast05_LAe", 
   [13711] = "CEhollyhil06", [13712] = "CEhollyhil8a", [13713] = "road_hil03", [13714] = "radarmast1_LAwN", [13715] = "cunte_hollyhil9", 
   [13716] = "CE_hollyhil8a", [13717] = "road_hillLAwn15", [13718] = "CEroad_hill20", [13719] = "hollyhil10", [13720] = "road_hill04b", 
   [13721] = "mulhouse03_cunte", [13722] = "VineSign1_cunte", [13723] = "cunte_hollyhil01", [13724] = "drg_nu_ext", [13725] = "opmans01_cunte", 
   [13726] = "road_hill08", [13727] = "CEnorthbrij01", [13728] = "CEgraveBuil03_LAwN", [13729] = "CEgraveBuil01", [13730] = "CEroad_6", 
   [13731] = "TCEmulwire01", [13732] = "CE_Roads37", [13733] = "CE_Roads42", [13734] = "HillClif06", [13735] = "CE_Roads41", 
   [13736] = "CE_Roads40", [13737] = "cunteHill03", [13738] = "Roads39_CE", [13739] = "Roads38CE", [13740] = "cnteHillClif01", 
   [13741] = "HillClif02", [13742] = "HillClif05", [13743] = "CEmulwire01", [13744] = "drg_nu_ext05", [13746] = "TCEhillhouse07", 
   [13747] = "CEhillhse06", [13748] = "TCEmulhilhed1_law01", [13749] = "cunte_curvesteps1", [13751] = "cunte_Flyover2", [13752] = "cuntebridge01", 
   [13753] = "CEhillhouse04", [13754] = "CEmulhouse04", [13755] = "CEhillhouse01", [13756] = "hollyhil04a", [13757] = "hollyhil05", 
   [13758] = "radarmast1_LAwN01", [13761] = "cunte_Whisky", [13784] = "road_hill01", [13789] = "Roads40_CE", [13795] = "CE_HillsEast06", 
   [13801] = "cunte_skatetrak", [13802] = "skateivy", [13804] = "cuntelandF4", [13805] = "CELAlandbiv", [13806] = "CEhollyhil8a01", 
   [13809] = "CE_grndPALCST02", [13810] = "CE_grndPALCST05", [13813] = "CEGraveBlok03e", [13814] = "CEroadn", [13816] = "CE_safeground", 
   [13817] = "CE_safedoor01", [13818] = "CEhollyhil01", [13820] = "cuntEground16", [13821] = "cuntEground20", [13823] = "cuntEground23", 
   [13824] = "cuntEground24", [13825] = "cuntEground25", [13826] = "cuntEground28", [13831] = "VineSign1_cunte01", [13845] = "CEnwhiltest5base", 
   [13861] = "CE_telewires01", [13862] = "CE_telewires02", [13863] = "CE_telewires03", [13864] = "CE_telewires04", [13865] = "CEnwhiltestBrd", 
   [13871] = "LAhills_border1", [13872] = "LAhills_border2", [13882] = "road_hill13", [13887] = "CEroad_hill01", [13890] = "LAhBoards_LAh1", 
   [14383] = "burg_kit1", [14384] = "kitchen_bits", [14385] = "kb_tr_main", [14386] = "kb_tr_bits", [14387] = "Dr_GsNEW02", 
   [14388] = "MaddDoggs02", [14389] = "MaddDoggs03", [14390] = "MaddDoggs04", [14391] = "Dr_GsNEW07", [14392] = "Dr_GsNEW08", 
   [14393] = "Dr_GsNEW09", [14394] = "Dr_GsNEW10", [14395] = "Dr_GsNEW11", [14396] = "girders01", [14397] = "girders07", 
   [14398] = "girders11", [14399] = "bar2", [14400] = "flower-bush08", [14401] = "bench1", [14402] = "flower-bush09", 
   [14403] = "cds", [14404] = "jet_interior", [14405] = "chairs", [14406] = "mansion-light05", [14407] = "carter-stairs01", 
   [14408] = "Carter-floors04", [14409] = "carter-stairs02", [14410] = "carter-stairs03", [14411] = "carter-stairs04", [14412] = "Carter_drugfloor", 
   [14413] = "carter-column01", [14414] = "carter-stairs05", [14415] = "Carter-floors01", [14416] = "carter-stairs07", [14417] = "MaddDoggs05", 
   [14418] = "MaddDoggs07", [14419] = "MaddDoggs08", [14420] = "MaddDoggs09", [14421] = "MaddDoggs10", [14422] = "MaddDoggs01", 
   [14423] = "MaddDoggs12", [14424] = "MaddDoggs13", [14425] = "MaddDoggs14", [14426] = "MaddDoggs15", [14427] = "MaddDoggs16", 
   [14428] = "MaddDoggs17", [14429] = "MaddDoggs18", [14430] = "MaddDoggs19", [14431] = "MaddDoggs20", [14432] = "carter_light01", 
   [14433] = "carter_gubbins", [14434] = "carter-spotlight42", [14435] = "carter_girders", [14436] = "carter_girders1", [14437] = "carter-bars", 
   [14438] = "Carter-light04", [14439] = "Carter-light12", [14440] = "Carter_grill", [14441] = "Carter-light16", [14442] = "SHADOW-Carter", 
   [14443] = "burning_blinds08", [14444] = "Carter-TopFloor", [14445] = "carter-column02", [14446] = "Smokes_bed", [14447] = "carter-balcony", 
   [14448] = "carter_girders02", [14449] = "Carter_trampoline", [14450] = "carter_girders03", [14451] = "carter_girders04", [14452] = "carter_girders05", 
   [14453] = "GANG_EXIT", [14454] = "carter-dancers", [14455] = "Gs_BOOKCASE", [14456] = "ceiling-roses02", [14457] = "gs_gold-disks", 
   [14458] = "gs_chairs", [14459] = "carter-cage", [14460] = "mansion-light05a", [14461] = "Gs_Piccies", [14462] = "Gs_piccies1", 
   [14463] = "gs_barstuff", [14464] = "gs_cages", [14465] = "carter-alpha", [14466] = "carter-outside", [14467] = "carter_statue", 
   [14468] = "flower-bush09a", [14469] = "flower-bush08a", [14470] = "mansion-light05b", [14471] = "carls_moms_kit2", [14472] = "carls_moms_kit1", 
   [14473] = "mansionlights2", [14474] = "ganghse_int1", [14475] = "ganghse_int2", [14476] = "carlscrap", [14477] = "carlsbits", 
   [14478] = "carlsshadfloor", [14479] = "motel_skuzmain1", [14480] = "motel_toilet", [14481] = "motel_bath1", [14482] = "motel_skuz_win", 
   [14483] = "maddogsfakedoors", [14484] = "MaddDoggs06", [14485] = "MaddDoggs11", [14486] = "madgym1", [14487] = "madlites", 
   [14488] = "madgymroofs", [14489] = "carlspics", [14490] = "cuntchair", [14491] = "iwanfucker", [14492] = "sweets_room", 
   [14493] = "arsehole", [14494] = "sweets_bath", [14495] = "sweetshall", [14496] = "sweetsdaylight", [14497] = "im_couchs", 
   [14498] = "imys_bigvent", [14499] = "imy_motel_wins", [14500] = "immy_rooms", [14501] = "motel_grill", [14502] = "imy_roomfurn", 
   [14503] = "imy_roomfurn01", [14504] = "imy_roomfurn03", [14505] = "imy_roomfurn06", [14506] = "imy_motel_int", [14507] = "imy_roomfurn07", 
   [14508] = "imy_roomfurn10", [14509] = "imy_roomfurn11", [14510] = "imy_roomfurn12", [14511] = "im_cover_tbl", [14512] = "immy_rooms2", 
   [14513] = "im_mtl_rail", [14514] = "hexi_lite", [14515] = "im_mtel_sckts", [14516] = "im_xtra3", [14517] = "im_xtra1", 
   [14518] = "im_xtra2", [14519] = "im_xtra4", [14520] = "immy_clothes", [14521] = "immy_shoes", [14522] = "immy_curtains02", 
   [14523] = "immy_curtains05", [14524] = "im_couchsa", [14525] = "imy_otherbit", [14526] = "sweetsmain", [14527] = "fannyfan", 
   [14528] = "sweetshadows", [14530] = "driveschl_main", [14531] = "int_zerosrc01", [14532] = "tv_stand_driv", [14533] = "pleasure-TOP", 
   [14534] = "ab_woozies01", [14535] = "ab_woozies03", [14536] = "pleasure-BOT", [14537] = "pdomesBar", [14538] = "Pdomes_Xitbox", 
   [14539] = "pdomes_logo", [14540] = "pdomes_extras", [14541] = "driveschl_daylite", [14542] = "woozies_Xitbox", [14543] = "ab_woozies04", 
   [14544] = "ab_woozies02", [14545] = "ab_wooziesGlass", [14546] = "pleasure-MID", [14547] = "pleasure-DL", [14548] = "cargo_test", 
   [14549] = "carge_barrels", [14550] = "cargo_netting", [14551] = "cargo_store", [14552] = "cargo_stuff", [14553] = "androm_des_obj", 
   [14554] = "ab_wooziesSHAD", [14556] = "ZEROWARDROBE", [14558] = "MODEL_BOX15", [14559] = "PDomeCones", [14560] = "triad_bar", 
   [14561] = "triad_neon", [14562] = "triad_lion", [14563] = "triad_main", [14564] = "triad_lights", [14565] = "triad_bar_stuff", 
   [14566] = "budha_whel1b", [14567] = "budha_whel02b", [14568] = "budha_whel03b", [14569] = "tr_man_pillar", [14570] = "tr_man_glass", 
   [14571] = "chinafurn1", [14572] = "maintenance16", [14573] = "maintenance03", [14574] = "maintenance20", [14575] = "maintenance31", 
   [14576] = "vault_door", [14577] = "mafCasLoadbay01", [14578] = "mafCasPipes01", [14579] = "MafCasLites01", [14580] = "mafCasGoldBits01", 
   [14581] = "ab_mafiaSuite01zzz", [14582] = "mafiaCasinoBar1", [14583] = "ab_mafCasLaund", [14584] = "ab_abbatoir05", [14585] = "ab_abbatoir04", 
   [14586] = "ab_abbatoir03", [14587] = "ab_abbatoir02", [14588] = "ab_abbatoir01", [14589] = "ab_abbatoir06", [14590] = "mafCasTopfoor", 
   [14591] = "mafcasWallLite", [14592] = "mafCasLoadbay02", [14593] = "paperchase04", [14594] = "paperchase03", [14595] = "paperchase02", 
   [14596] = "paperchase_stairs", [14597] = "paperchase07", [14598] = "paperchase_glass", [14599] = "paperchase08", [14600] = "paperchase_bits2", 
   [14601] = "MafCasLites02", [14602] = "paperchase01", [14603] = "bikeschl_main", [14604] = "tv_stand_bike", [14605] = "triad_lights2", 
   [14606] = "MafCasMain4", [14607] = "triad_main2", [14608] = "triad_buddha01", [14609] = "MafCasLites04", [14610] = "MafCasLites05", 
   [14611] = "mafiaCasinoBarLite", [14612] = "ab_abattoir_box2", [14613] = "ab_abattoir_box1", [14614] = "triad_main3", [14615] = "abatoir_daylite", 
   [14616] = "ab_pillarTemp3", [14617] = "ab_pillarTemp2", [14618] = "ab_pillarTemp1", [14619] = "tricas_slotTable2", [14620] = "tricas_slotTable1", 
   [14621] = "mafiaCasinoGlass", [14622] = "ab_pillarTemp4", [14623] = "MafCasMain1", [14624] = "MafCasMain2", [14625] = "MafCasMain3", 
   [14626] = "mafcasSigns1", [14627] = "mafcas_optilite1", [14628] = "ab_caligulasfront", [14629] = "mafcas_chande", [14630] = "mafcas_Xitbox", 
   [14631] = "paperchase_daylite", [14632] = "paperchase_bits2b", [14633] = "paperchase_bits2c", [14634] = "bikeschl_daylite", [14635] = "mafcasGenStuff", 
   [14636] = "mafcas_signs", [14637] = "triad_dragon", [14638] = "ab_mafsuiteDoor", [14639] = "tr_man_main", [14640] = "chinafurn2", 
   [14641] = "tri_main_holes", [14642] = "mafcas_spiral_dad", [14643] = "tr_man_main_tr", [14650] = "trukstp04", [14651] = "trukstp05", 
   [14652] = "trukstp02", [14653] = "trukstp03", [14654] = "trukstp06", [14655] = "trukstp01", [14656] = "tsdinerXitbox", 
   [14657] = "cuntchairs", [14660] = "int_tatooA05", [14661] = "int_tatooA01", [14662] = "int_tatooA02", [14663] = "int_tatooA03", 
   [14664] = "int_tatooA04", [14665] = "int_7_11A40", [14666] = "CJ_SEX_COUNTER03", [14667] = "int_7_11A41", [14668] = "711_c", 
   [14669] = "711_d", [14670] = "int_7_11A42", [14671] = "int_7_11A5", [14672] = "int_sex01", [14673] = "chnsaw1", 
   [14674] = "hotelferns1_LAn", [14675] = "Hotelatrium_LAn", [14676] = "int_tatooA06", [14677] = "int_tatooA07", [14678] = "int_tatooA08", 
   [14679] = "Int_tat_tools01", [14680] = "Int_tat_lights01", [14681] = "int_tatooA09", [14682] = "int_tatooA10", [14683] = "int_tatooA11", 
   [14684] = "int_tatooA12", [14685] = "int_tatooA13", [14686] = "Int_tat_tools02", [14687] = "Int_tat_lights02", [14688] = "int_tatooA14", 
   [14689] = "int_tatooA15", [14690] = "int_7_11A40_bits", [14691] = "int_7_11A41_bits", [14692] = "int_7_11A41_bits01", [14693] = "Int_tat_tools", 
   [14694] = "SEX_SHOP_DET", [14695] = "int_7_11A41_bits02", [14699] = "Int_tat_lights", [14700] = "int2smSf01_int01", [14701] = "int2Hoose2", 
   [14702] = "int2lamid01", [14703] = "int2Hoose09", [14704] = "int2Hoose2_bits", [14705] = "int2Vase", [14706] = "int2labigtwo01", 
   [14707] = "int2labig301", [14708] = "int2labigone01", [14709] = "int2lamidtwo01", [14710] = "int2vgshM3", [14711] = "int2vgshM2", 
   [14712] = "int2Hoose11", [14713] = "int2Hoose16", [14714] = "int2Hoose08", [14715] = "int2Hoose09_Bits", [14716] = "int2lamid01_rail", 
   [14717] = "int2lasmtwo02", [14718] = "int2lasmone04", [14719] = "int2lasmone01", [14720] = "int2lasmone02", [14721] = "2labigone_bits", 
   [14722] = "int2Hoose09_Bits2", [14723] = "int2Hoose09_Bits3", [14724] = "int2Hoose09_Bits4", [14725] = "int2lamid01_rail2", [14726] = "int2lamid01_rail3", 
   [14727] = "int2lamid01_rail4", [14728] = "int2labig302", [14735] = "crackhoose", [14736] = "AH_chiller2", [14737] = "whorepix", 
   [14738] = "brothelbar", [14739] = "whorefurn", [14740] = "ryblinds", [14741] = "rykitunit", [14742] = "ryders_wall_stuf", 
   [14743] = "rydhall", [14744] = "rybathroom", [14745] = "rybatharse01", [14746] = "rylounge", [14747] = "curses04", 
   [14748] = "sfhsm1", [14749] = "sfhsm1lights", [14750] = "sfhsm2", [14751] = "sfhsm2bits", [14752] = "curses02", 
   [14753] = "sfhsb2curts", [14754] = "bigsanfranhoose", [14755] = "shite", [14756] = "shitlobby", [14757] = "sfmansionbits", 
   [14758] = "sfmansion1", [14759] = "sfhsm03", [14760] = "Object03", [14761] = "ryshadroom", [14762] = "arsewinows", 
   [14763] = "sweetsdaylight02", [14764] = "ballustrades", [14765] = "lacrakbulb", [14770] = "int_brothelseats", [14771] = "int3int_brothel", 
   [14772] = "int3int_LOW_TV", [14773] = "int3int_brothel03", [14774] = "int_5kb_flykiller", [14775] = "int3int_brothel04", [14776] = "int3int_carupg_int", 
   [14777] = "int_5weecasino", [14778] = "int_boxing02", [14779] = "int_boxing03", [14780] = "in_bxing04", [14781] = "in_bxing05", 
   [14782] = "int3int_boxing30", [14783] = "int3int_kbsgarage", [14784] = "genint_warehs", [14785] = "gen_otb", [14786] = "ab_sfGymBeams1", 
   [14787] = "ab_sfGymBits02a", [14788] = "ab_sfGymBits01a", [14789] = "ab_sfGymMain1", [14790] = "ab_sfGymBits03a", [14791] = "a_vgsGymBoxa", 
   [14792] = "ab_vgsGymBits01a", [14793] = "ab_vegasGymLitesa", [14794] = "ab_vegasGymMain2", [14795] = "genint3_smashtv", [14796] = "int_kbsgarage05b", 
   [14797] = "int_kbsgarage3b", [14798] = "int_kbsgarage3", [14799] = "otb_glass", [14800] = "gen_otb_bits", [14801] = "Bdups_main", 
   [14802] = "BDups_interior", [14803] = "BDupsNEW", [14804] = "BDups_plant", [14805] = "BDupsNew_int", [14806] = "BDupshifi", 
   [14807] = "BDupslight01", [14808] = "Strip2_Building", [14809] = "Strip2_Platforms", [14810] = "Strip2_Tables", [14811] = "Strip2_neon", 
   [14812] = "StudioHall_frames", [14813] = "StudioHall_Furn", [14814] = "StudioHallBuild", [14815] = "Whhouse_main", [14816] = "Whhouse_furn", 
   [14817] = "Whhouse_Rms", [14818] = "mc_straps", [14819] = "OG_Door", [14820] = "dj_stuff", [14821] = "mc_straps_int", 
   [14822] = "Gym2_doorway", [14823] = "Gym3_doorway", [14824] = "Gym1_doorway", [14825] = "int_boxing07", [14826] = "int_kbsgarage2", 
   [14827] = "ab_sfGymBits01a2", [14828] = "LM_strip2Priv", [14829] = "strip_signs", [14830] = "strip_lights", [14831] = "LM_stripbar", 
   [14832] = "LM_stripCorner", [14833] = "LM_stripchairs1", [14834] = "LM_stripplant", [14835] = "LM_stripColumns", [14836] = "LM_strippoles", 
   [14837] = "LM_stripchairs", [14838] = "int_strip_club", [14839] = "LM_stripPriv", [14840] = "Bdups_graf", [14841] = "Lee_gymers", 
   [14842] = "int_policeA07", [14843] = "int_policeA01", [14844] = "int_policeA02", [14845] = "int_policeA03", [14846] = "int_ppol", 
   [14847] = "mp_sfpd_big", [14848] = "mp_sfpd_stairs1", [14849] = "mp_sfpd_lights1", [14850] = "mp_sfpd_obj1", [14851] = "mp_sfpd_signa", 
   [14852] = "mp_sfpd_win1", [14853] = "veg_pol_main2", [14854] = "countera", [14855] = "counterb", [14856] = "cellsa", 
   [14858] = "veg_pol_main1", [14859] = "coochie-room", [14860] = "coochie-posters", [14861] = "choochie-bed", [14862] = "headboard", 
   [14863] = "clothes", [14864] = "shoes", [14865] = "bobbi-room01", [14866] = "bobbie-bed01", [14867] = "bobbie-cupboards", 
   [14868] = "pennants01", [14869] = "bobbie-table", [14870] = "pompom01", [14871] = "Kylie_barn", [14872] = "Kylie_logs", 
   [14873] = "Kylie_hay", [14874] = "Kylie_stairs", [14875] = "Kylie_hay1", [14876] = "michelle-garage", [14877] = "michelle-stairs", 
   [14878] = "michelle-barrels", [14879] = "michelle-bits", [14880] = "michelle-bed01", [14881] = "barbara-cop", [14882] = "barb-pipes", 
   [14883] = "prison-gates", [14885] = "Vegas-signs1", [14886] = "polvegsigns1", [14887] = "polvegsigns3", [14888] = "Millie-headboard", 
   [14889] = "Millie-room", [14890] = "millie-vibrators", [14891] = "millie-swing", [14892] = "mp_sfpd_win2", [14893] = "police1-exit", 
   [14894] = "police2-exit01", [14895] = "mp_sfpd_obj2", [14896] = "mp_sfpd_lights2a", [14897] = "mp_sfpd_lights1a", [14898] = "int_policeA03a", 
   [14900] = "police3-exit01", [14901] = "police3-exit02", [14902] = "veg_pol_window", [14903] = "mp_sfpd_lights2", [15025] = "genmotelfurn_sv", 
   [15026] = "imy_roomfurn12_sv", [15027] = "immy_clothes_sv", [15028] = "genmotel2sh_sv", [15029] = "genmotel2_sv", [15030] = "genmotel_sv", 
   [15031] = "lasmall1_sv", [15032] = "lasmallfurn_sv", [15033] = "vegashotel_sv", [15034] = "hotelgen_sv", [15035] = "kb_bed_test2_sv", 
   [15036] = "kit_cab_washin_sv", [15037] = "MED_DINNING_2_sv", [15038] = "Plant_Pot_3_sv", [15039] = "mrk_bed02_sv", [15040] = "cuntbits", 
   [15041] = "cunthouse", [15042] = "newhouse1", [15043] = "svcuntflorday", [15044] = "lamidshadfloor", [15045] = "bigLAshadow", 
   [15046] = "countrysavehouse", [15047] = "svvgmdshadfloor", [15048] = "LABIGSAVEHOUse", [15049] = "svlabigkitchshad", [15050] = "svlabigbits", 
   [15051] = "svlasmshad", [15052] = "svsfsmshad", [15053] = "bigniceveghotel", [15054] = "svvgmedhoose", [15055] = "savelamid", 
   [15056] = "svsfsmshadfloor2", [15057] = "bihotelshad", [15058] = "midvegsavehouse", [15059] = "labihalfhouse", [15060] = "svsfmdshadflr1", 
   [15061] = "svlamidshad", [15062] = "lamidshadflr", [15063] = "svmidsavebits", [15064] = "svrails", [16000] = "drvin_screen", 
   [16001] = "drvin_projhut", [16002] = "drvin_sign", [16003] = "drvin_ticket", [16004] = "des_tepeoff", [16005] = "desn2_stwnblok2", 
   [16006] = "ros_townhall", [16007] = "desn2_cn2blok1", [16008] = "des_nbrstruct", [16009] = "des_nbrstruct2", [16010] = "des_reslab_", 
   [16011] = "des_westrn2_", [16012] = "des_ntcafe", [16013] = "des_ntwn_lines1_", [16014] = "des_ntwn_lines2_", [16015] = "des_ntwn_lines6_", 
   [16016] = "des_roadbar01", [16017] = "des_roadbar02", [16018] = "des_roadbar03", [16019] = "des_roadbar04", [16020] = "des_roadbar05", 
   [16021] = "des_geyhotbase_", [16022] = "des_geywall1", [16023] = "des_trXingsign02", [16024] = "des_ltraintunnel2", [16025] = "des_trainline06", 
   [16026] = "des_trainline07", [16027] = "des_trainline08", [16028] = "des_trainline09", [16029] = "des_trainline11", [16030] = "des_trainline12", 
   [16031] = "des_trainline13", [16032] = "des_trainline14", [16033] = "des_trainline15", [16034] = "des_trainline16", [16035] = "des_trainline10", 
   [16036] = "des_trainline17", [16037] = "des_railbr_twr10", [16038] = "des_powercable_01", [16039] = "des_powercable_03", [16040] = "des_powercable_04", 
   [16041] = "des_powercable_07", [16042] = "des_powercable_08", [16043] = "des_powercable_09", [16044] = "des_powercable_10", [16045] = "des_powercable_11", 
   [16046] = "des_powercable_12", [16047] = "des_powercable_19", [16048] = "des_powercable_20", [16049] = "des_powercable_21", [16050] = "des_powercable_22", 
   [16051] = "des_westsaloon_01", [16052] = "des_ghotfence", [16053] = "des_westrn7_01", [16054] = "des_westrn9_01", [16055] = "quarry_bit04", 
   [16056] = "quarry_bit02", [16057] = "quarry_bit01", [16058] = "quarry_bit05", [16059] = "quarry_bit03", [16060] = "des_treeline1", 
   [16061] = "des_treeline2", [16062] = "des_nt_buntpoles", [16063] = "des_cockbunting", [16064] = "des_cn2blok4", [16065] = "des_stwnshop01", 
   [16066] = "des_bluecafe01", [16067] = "des_stwnmotel02", [16068] = "des_stripblock1", [16069] = "des_stwnyelmot1_", [16070] = "des_stwnhotel1", 
   [16071] = "des_quarrybelt02", [16072] = "des_quarrybelt01", [16073] = "des_quarrybelt03", [16074] = "des_quarrybelt04", [16075] = "des_quarrybelt07", 
   [16076] = "des_sorter01", [16077] = "des_gravelpile01", [16078] = "des_quarrybelt08", [16079] = "des_quarrybelt09", [16080] = "des_bigquaryconv01", 
   [16081] = "des_bigquaryconv02", [16082] = "des_quarryplatform", [16083] = "des_quarry_hopper01", [16084] = "des_quarryramp", [16085] = "des_quarstmound_02", 
   [16086] = "des_bigoilpipe01", [16087] = "des_oilfieldpipe01", [16088] = "des_pipestrut01", [16089] = "des_pipestrut02", [16090] = "des_pipestrut03", 
   [16091] = "des_pipestrut04", [16092] = "des_pipestrut05", [16093] = "a51_gatecontrol", [16094] = "des_a51infenc", [16095] = "des_a51guardbox02", 
   [16096] = "des_a51guardbox04", [16097] = "n_bit_16", [16098] = "des_by_hangar_", [16099] = "des_powercable_end", [16100] = "des_substa_bldgs", 
   [16101] = "des_windsockpole", [16102] = "cen_bit_18", [16103] = "ne_bit_22", [16104] = "des_boulders_", [16105] = "des_westrn11_04", 
   [16106] = "des_nmot_", [16107] = "des_ngassta", [16108] = "des_snakefarm_", [16109] = "radar_bit_03", [16110] = "des_rockgp1_01", 
   [16111] = "des_rockgp1_02", [16112] = "des_rockfl1_", [16113] = "des_rockgp2_03", [16114] = "des_rockgp2_", [16115] = "des_rockgp1_03", 
   [16116] = "des_rockgp2_04", [16117] = "des_rockgp1_04", [16118] = "des_rockgp2_05", [16119] = "des_rockgp2_06", [16120] = "des_rockgp2_07", 
   [16121] = "des_rockgp2_09", [16122] = "des_rockgp2_11", [16123] = "des_rockgp2_13", [16124] = "des_rockgp1_06", [16125] = "des_rockgp1_07", 
   [16126] = "des_rockgp2_15", [16127] = "des_rockgp1_08", [16128] = "des_rockgp1_09", [16129] = "des_rockgp1_12", [16130] = "des_rockgp2_16", 
   [16131] = "des_rockgp2_17", [16132] = "dam_trellis01", [16133] = "des_rockgp2_18", [16134] = "des_rockfl1_01", [16135] = "des_geysrwalk2", 
   [16136] = "des_telefenc", [16137] = "des_teleshed2_", [16138] = "des_teleshed2_01", [16139] = "des_rockgp2_19", [16140] = "des_rockgp2_20", 
   [16141] = "des_rockgp2_21", [16142] = "des_rockgp2_22", [16143] = "des_telecafe", [16144] = "des_telecafenc", [16145] = "des_rockgp2_23", 
   [16146] = "des_ufoinn", [16147] = "radar_bit_02", [16148] = "radar_bit_01", [16149] = "radar_bit_04", [16150] = "ufo_barinterior", 
   [16151] = "ufo_bar", [16152] = "ufo_booths", [16153] = "ufo_photos", [16154] = "ufo_backroom", [16155] = "ufo_backrmstuff", 
   [16156] = "Vdes_trainline18", [16157] = "n_bit_01", [16158] = "n_bit_02", [16159] = "n_bit_03", [16160] = "n_bit_04", 
   [16161] = "n_bit_05", [16162] = "n_bit_06", [16163] = "n_bit_07", [16164] = "n_bit_08", [16165] = "n_bit_10", 
   [16166] = "n_bit_11", [16167] = "n_bit_12", [16168] = "n_bit_13", [16169] = "n_bit_14", [16170] = "n_bit_15", 
   [16171] = "ne_bit_23", [16172] = "ne_bit_01", [16173] = "ne_bit_02", [16174] = "ne_bit_03", [16175] = "ne_bit_04", 
   [16176] = "ne_bit_06", [16177] = "ne_bit_07", [16178] = "ne_bit_08", [16179] = "ne_bit_09", [16180] = "ne_bit_10", 
   [16181] = "ne_bit_11", [16182] = "ne_bit_12", [16183] = "ne_bit_13", [16184] = "ne_bit_14", [16185] = "ne_bit_15", 
   [16186] = "ne_bit_16", [16187] = "ne_bit_17", [16188] = "ne_bit_18", [16189] = "ne_bit_19", [16190] = "ne_bit_20", 
   [16191] = "ne_bit_21", [16192] = "cen_bit_01", [16193] = "cen_bit_02", [16194] = "cen_bit_03", [16195] = "cen_bit_04", 
   [16196] = "cen_bit_20", [16197] = "cen_bit_05", [16198] = "cen_bit_06", [16199] = "cen_bit_07", [16200] = "cen_bit_08", 
   [16201] = "cen_bit_09", [16202] = "cen_bit_10", [16203] = "cen_bit_11", [16204] = "cen_bit_12", [16205] = "cen_bit_13", 
   [16206] = "cen_bit_14", [16207] = "cen_bit_15", [16208] = "cen_bit_16", [16209] = "cen_bit_19", [16210] = "cen_bit_17", 
   [16211] = "s_bit_01", [16212] = "s_bit_02", [16213] = "s_bit_03", [16214] = "s_bit_04", [16215] = "s_bit_05", 
   [16216] = "s_bit_06", [16217] = "s_bit_07", [16218] = "s_bit_08", [16219] = "s_bit_09", [16220] = "s_bit_10", 
   [16221] = "s_bit_11", [16222] = "s_bit_12", [16223] = "s_bit_13", [16224] = "s_bit_14", [16225] = "s_bit_15", 
   [16226] = "s_bit_16", [16227] = "s_bit_17", [16228] = "s_bit_18", [16229] = "s_bit_19", [16230] = "se_bit_01", 
   [16231] = "se_bit_02", [16232] = "se_bit_03", [16233] = "se_bit_04", [16234] = "se_bit_05", [16235] = "se_bit_06", 
   [16236] = "se_bit_07", [16237] = "se_bit_08", [16238] = "se_bit_09", [16239] = "se_bit_10", [16240] = "se_bit_11", 
   [16241] = "se_bit_12", [16242] = "se_bit_13", [16243] = "se_bit_14", [16244] = "se_bit_15", [16245] = "se_bit_16", 
   [16246] = "se_bit_17", [16247] = "se_bit_18", [16248] = "se_bit_20", [16249] = "se_bit_21", [16250] = "se_bit_23", 
   [16251] = "n_bit_17", [16252] = "n_bit_18", [16253] = "n_bit_19", [16254] = "n_bit_20", [16255] = "ne_bit_24", 
   [16256] = "ne_bit_25", [16257] = "ne_bit_26", [16258] = "cen_bit_21", [16259] = "cen_bit_22", [16260] = "cen_bit_23", 
   [16261] = "cen_bit_24", [16262] = "s_bit_21", [16263] = "se_bit_24", [16264] = "radar_bit_05", [16265] = "des_damlodbit04", 
   [16266] = "des_railbridgeoil", [16267] = "des_oilpipe_04", [16268] = "des_oillines01", [16269] = "des_oillines02", [16270] = "des_oillines03", 
   [16271] = "des_railfac02", [16272] = "des_railfac01", [16273] = "oilderricklod01", [16274] = "oilderricklod02", [16275] = "oilderricklod03", 
   [16276] = "oilderricklod04", [16277] = "oilderricklod05", [16278] = "oilderricklod06", [16279] = "oilderricklod07", [16280] = "des_farmhouse1_", 
   [16281] = "des_fgateway01", [16282] = "cn2_slines02", [16283] = "cn2_slines01", [16284] = "cn2_slines04", [16285] = "des_westrn7_03", 
   [16286] = "cn2_slines06", [16287] = "des_fshed1_", [16288] = "cn2_slines03", [16289] = "cn2_slines05", [16290] = "cn2_slines07", 
   [16291] = "cn2_slines08", [16292] = "cn2_slines09", [16293] = "a51_extfence03", [16294] = "a51_extfence06", [16295] = "quarry_fenc01", 
   [16296] = "quarry_fenc04", [16297] = "quarry_fenc06", [16298] = "quarry_fenc05", [16299] = "quarry_fenc02", [16300] = "quarry_fenc03", 
   [16301] = "des_quarrybelt13", [16302] = "des_gravelpile04", [16303] = "des_quarryramp01", [16304] = "des_gravelpile05", [16305] = "des_gravelpile06", 
   [16306] = "cn2_ywire", [16307] = "des_tellines01", [16308] = "des_sbridsupps", [16309] = "des_quarrybelt11", [16310] = "des_quarryhut1", 
   [16311] = "des_quarrybelt15", [16312] = "quarry_walllthing", [16313] = "quarry_fencins", [16314] = "quarry_chutelift", [16315] = "quarry_fencins2", 
   [16316] = "des_quarrybelt17", [16317] = "des_quarstmound_03", [16318] = "des_quarrybelt18", [16319] = "quarrystuff4", [16320] = "quarry_fenc07", 
   [16321] = "quarry_fenc08", [16322] = "a51_plat", [16323] = "a51_outbldgs", [16324] = "des_quaoldfenc", [16325] = "des_quarryhut02", 
   [16326] = "des_byoffice", [16327] = "des_bycontowr", [16328] = "quarry_crane", [16329] = "quarry_cranearm", [16330] = "quarry_cranebase", 
   [16331] = "quarry_cranecable", [16332] = "quarry_cranhook", [16333] = "quarry_crhookcble", [16334] = "des_cranelines01", [16335] = "des_transtower", 
   [16337] = "des_cranecontrol", [16338] = "dam_genbay01", [16339] = "dam_genend01", [16340] = "dam_genturbine05", [16341] = "dam_genalpha01", 
   [16342] = "dam_genturbine04", [16343] = "dam_genalpha02", [16344] = "dam_genbay02", [16345] = "dam_genturbine03", [16346] = "dam_genturbine02", 
   [16347] = "dam_genalpha04", [16348] = "dam_genbay04", [16349] = "dam_genturbine01", [16350] = "dam_genend02", [16351] = "dam_genalpha06", 
   [16352] = "dam_genbay06", [16353] = "dam_genalpha07", [16354] = "dam_genbay07", [16355] = "dam_gencrane01", [16356] = "dam_gencrane02", 
   [16357] = "des_ebrigroad01", [16358] = "des_ebrigroad07", [16359] = "des_shed3_01", [16360] = "desn2_tsfuelpay", [16361] = "desn2_tsblock", 
   [16362] = "desn2_tscanopy", [16363] = "des_trstplines", [16364] = "des_quaybase", [16365] = "des_substat_17", [16366] = "des_substat_37", 
   [16367] = "des_quayramp", [16368] = "bonyrd_windsock", [16369] = "des_quaoldfenc01", [16370] = "by_fuelfence", [16371] = "desn2_alphabit01", 
   [16372] = "desn2_alphabit02", [16373] = "desn2_alphabit04", [16374] = "desn2_alphabit05", [16375] = "by_helimarkings", [16376] = "desn2dambit01", 
   [16377] = "tv_stand_by", [16378] = "des_byofficeint", [16384] = "des_ebrigroad10", [16385] = "desh2_weefact2_", [16386] = "desn2_shed3_", 
   [16387] = "desn2_ammun", [16388] = "des_studbldg", [16389] = "des_studgrnd", [16390] = "desn2_studbush", [16391] = "des_reffenc04", 
   [16392] = "des_reffenc01", [16393] = "des_reffenc02", [16394] = "des_reffenc03", [16395] = "desn2_minerun", [16396] = "des_ntshop5_", 
   [16397] = "n_bit_09", [16398] = "desn2_peckfac1", [16399] = "desn2_peckfac2", [16400] = "desn2_peckfac3", [16401] = "desn2_peckjump", 
   [16402] = "desn2_peckalpha", [16403] = "des2_bushybits", [16404] = "desn2_hutskel2", [16405] = "desn2_hutskel03", [16406] = "desn2_weemineb", 
   [16407] = "airfieldhus1", [16408] = "airfieldhus2", [16409] = "by_weehangr", [16410] = "desn2_graves", [16411] = "desn2_platroks", 
   [16420] = "des_sbridsupps04", [16421] = "s_bit_06_2", [16422] = "s_bit_06_3", [16423] = "s_bit_06_4", [16424] = "s_bit_06_5", 
   [16430] = "des_ebrigroad02", [16434] = "desn2_stwnalph1", [16436] = "cn2_roadblock01", [16437] = "cn2_roadblock02", [16438] = "cn2_roadblock03", 
   [16439] = "cn2_roadblock04", [16442] = "desn2_stripsigs1", [16444] = "des_blackbags", [16445] = "des_quarrycut", [16446] = "quarry_weecrushr", 
   [16448] = "des_nt_buntpoles01", [16475] = "des_stwnbowl", [16477] = "des_stwngas1", [16479] = "des_stgas1sig", [16480] = "ftcarson_sign", 
   [16481] = "des_quarrybelt19", [16498] = "des_rdalpha01", [16500] = "cn2_savgardr1_", [16501] = "cn2_savgardr2_", [16502] = "cn2_jetty1", 
   [16503] = "cn2_rockgpst", [16530] = "des_oilfieldpipe02", [16531] = "des_oilpipe_03", [16532] = "des_oilpipe_05", [16533] = "des_oilpipe_06", 
   [16534] = "des_oilpipe_01", [16535] = "des_oilpipe_07", [16562] = "cn2_rosmot1", [16563] = "cn2_polis", [16564] = "des_stmedicentre_", 
   [16568] = "cn2_rosmot02", [16571] = "des_railbridgest01", [16593] = "se_bit_19", [16599] = "by_fuel06", [16601] = "by_fuel07", 
   [16605] = "des_stwnmotel03", [16610] = "des_nbridgebit_02", [16613] = "des_bigtelescope", [16622] = "des_ntwn_lines3_", [16623] = "des_rdalpha02", 
   [16627] = "des_ghotfenc01", [16628] = "des_ghotfenc02", [16629] = "des_ghotfenc03", [16630] = "des_ghotfenc04", [16631] = "des_ghotfenc05", 
   [16632] = "des_ghotfenc06", [16633] = "des_ghotfenc07", [16634] = "des_ghotfenc08", [16635] = "des_ghotfenc09", [16636] = "des_ghotfenc10", 
   [16637] = "ghostgardoor", [16638] = "a51_gatecon_a", [16639] = "des_a51_labs", [16640] = "des_a51_inner3", [16641] = "des_a51warheads", 
   [16642] = "a51_genroom", [16643] = "a51_stormech", [16644] = "a51_ventsouth", [16645] = "a51_ventsouth01", [16646] = "a51_ugstore1a", 
   [16647] = "a51_storeroom", [16648] = "a51_fakeroom2", [16649] = "a51_entstair", [16650] = "a51_genroomalpha", [16651] = "a51_genwalkway", 
   [16652] = "a51_fakealpha1", [16653] = "a51_fakealpha2", [16654] = "a51_fakeroom1", [16655] = "a51_labglass", [16656] = "a51_rocketlab", 
   [16657] = "des_a51_labs2", [16658] = "des_a51_labent", [16659] = "des_a51_entalpha", [16660] = "a51_entstuff", [16661] = "a51_sci_stair", 
   [16662] = "a51_radar_stuff", [16663] = "a51_jetpstuff", [16664] = "a51_jetpalpha", [16665] = "a51_radarroom", [16666] = "a51_machines", 
   [16667] = "des_rockgp2_14", [16668] = "a51_extfence04", [16669] = "a51_extfence05", [16670] = "a51_extfence02", [16671] = "a51_extfence01", 
   [16673] = "des_nmot_02", [16675] = "des_rockgp1_13", [16676] = "des_quarrycut3", [16677] = "des_quarrycut2", [16678] = "desn2_alphabit07", 
   [16681] = "a51_launchbottom", [16682] = "a51_jetroom", [16683] = "cn2_alphabit01", [16684] = "cn2_rnway_bit", [16685] = "cn2_rnway_bit2", 
   [16689] = "des_westrn7_02", [16690] = "des_westsaloon_02", [16692] = "des_rockgp1_05", [16693] = "n_bit_11b", [16694] = "n_bit_11c", 
   [16700] = "androm_des_obj", [16701] = "china_town_gateb", [16702] = "cargo_stuff", [16705] = "cargo_test", [16706] = "carge_barrels", 
   [16707] = "cargo_netting", [16708] = "cargo_store", [16731] = "cxrf_a51_stairs08", [16732] = "a51_ventcover", [16733] = "cn2_DETAIL01", 
   [16734] = "cn2_DETAIL02", [16735] = "des_alphabit08", [16736] = "des_alphabit05", [16737] = "des_alphabit01", [16738] = "des_alphabit02", 
   [16739] = "des_alphabit03", [16740] = "des_alphabit04", [16741] = "des_alphabit", [16742] = "des_alphabit06", [16743] = "des_alphabit07", 
   [16744] = "des_alphabit09", [16745] = "des_alphabit10", [16746] = "des_alphabit11", [16747] = "des_alphabit12", [16753] = "des_cn2_detailbit", 
   [16754] = "des_cn2_detail2", [16756] = "des_cn2_detail3", [16757] = "des_cn2_detail4", [16758] = "des_cn2_detailbit2", [16759] = "desn2_alphabit06", 
   [16760] = "cn2_ftcar_sig1", [16766] = "des_oilpipe_02", [16767] = "cluckinbell1_cn2", [16769] = "desn2_ammun04", [16770] = "des_gunbldg01", 
   [16771] = "des_savhangr", [16773] = "door_savhangr1", [16774] = "des_gunbldg", [16775] = "door_savhangr2", [16776] = "des_cockbody", 
   [16777] = "des_stmotsigbas1", [16778] = "des_ufosign", [16779] = "ufo_light02", [16780] = "ufo_light03", [16781] = "cn2_ringking", 
   [16782] = "a51_radar_scan", [16783] = "des_detailbit06", [16784] = "des_alphabit13", [16785] = "des_aroadbit02", [16786] = "des_aroadbit03", 
   [16787] = "des_aroadbit04", [16788] = "des_aroadbit08", [16789] = "des_aroadbit12", [16790] = "desn2_aroadbit05", [17000] = "wt6suppsxc", 
   [17001] = "cuntgrsilos", [17002] = "lawestbridge_law", [17003] = "cuntwcridge", [17004] = "cos_pch_brig_1", [17005] = "farmhouse", 
   [17006] = "D5002whi", [17007] = "wt6supps01", [17008] = "farmhouse01", [17009] = "truth_barn02", [17010] = "truth_barn03", 
   [17011] = "truth_barn04", [17012] = "cwsthseing26", [17013] = "cuntplant05", [17014] = "cuntwplant01", [17015] = "cuntwplant07", 
   [17016] = "cutnwplant09", [17017] = "cuntwplant10", [17018] = "cuntsplantfnce03", [17019] = "cuntfrates1", [17020] = "cuntfrates02", 
   [17021] = "cuntplant06", [17022] = "cuntwplant11", [17023] = "cutnwplant10", [17024] = "cuntwplant12", [17025] = "cunt_rockgp1_", 
   [17026] = "cunt_rockgp2_", [17027] = "cunt_rockgp1_03", [17028] = "cunt_rockgp2_04", [17029] = "cunt_rockgp2_09", [17030] = "cunt_rockgp2_11", 
   [17031] = "cunt_rockgp2_13", [17032] = "cunt_rockgp2_14", [17033] = "cunt_rockgp2_15", [17034] = "cunt_rockgp2_16", [17035] = "cunt_rockgp2_17", 
   [17036] = "cuntw_carport1_", [17037] = "cuntw_carport2_", [17038] = "cuntw_weefactory1_", [17039] = "cuntw_weebarn1_", [17040] = "cuntw_weefact1_", 
   [17041] = "cuntw_stwn", [17042] = "cuntw_stwnmotsign2", [17043] = "concretearch1", [17044] = "cuntw_stwnyels", [17045] = "cuntw_stwnyel", 
   [17046] = "telewirescuntw", [17047] = "cuntwwires", [17048] = "cuntwwires2", [17049] = "cw_Silo01", [17050] = "cw_Silo02", 
   [17051] = "cw_Silo03", [17052] = "cw_bigbarn02", [17053] = "cw_bigbarn03", [17054] = "cw_bigbarn04", [17055] = "cw_fueldrum03", 
   [17056] = "cw_corrug01", [17057] = "cw_haypile03", [17058] = "cw_tempbarn01", [17059] = "cw_haypile05", [17060] = "cw_haypile06", 
   [17061] = "cw_barnie", [17062] = "cuntytunnel", [17063] = "cw2_weebarn1_01", [17064] = "cw2_garage", [17065] = "cw2_garagecanopy", 
   [17066] = "cw2_genstore", [17067] = "cw2_logcabins", [17068] = "xjetty01", [17069] = "cunt_rockgp2_24", [17070] = "carspaces03", 
   [17071] = "cunt_rockgp2_25", [17072] = "smltrukext", [17073] = "smlltrukint", [17074] = "truth_barn05", [17075] = "cuntwland01b", 
   [17076] = "cunt_rockgp2_26", [17077] = "cuntwland02b", [17078] = "cuntwland03b", [17079] = "cuntwland04b", [17080] = "cuntwland05b", 
   [17081] = "cuntwland06b", [17082] = "cuntwland07b", [17083] = "cuntwland08b", [17084] = "cuntwland09b", [17085] = "cuntwland10bb", 
   [17086] = "cuntwland11b", [17087] = "cuntwland12b", [17088] = "cuntwland13b", [17089] = "cuntwland15b", [17090] = "cuntwland16b", 
   [17091] = "cuntwland17_de", [17092] = "cuntwland_de", [17093] = "cuntwland19b", [17094] = "cuntwland20b", [17095] = "cuntwland21b", 
   [17096] = "cuntwland22b", [17097] = "cuntwland23b", [17098] = "cuntwland24b", [17099] = "cuntwland25b", [17100] = "cuntwland26b", 
   [17101] = "cuntwland29b", [17102] = "cuntwland31b", [17103] = "cuntwland32b", [17104] = "cuntwland33b", [17105] = "cuntwland34b", 
   [17106] = "cuntwland35b", [17107] = "cuntwland36b", [17108] = "cuntwland37b", [17109] = "cuntwland38b", [17110] = "cuntwland39b", 
   [17111] = "cuntwland40b", [17112] = "cuntwland41b", [17113] = "cuntwland42b", [17114] = "cuntwland45b", [17115] = "cuntwland46b", 
   [17116] = "cuntwland47b", [17117] = "cuntwland48b", [17118] = "cuntwland50b", [17119] = "cuntwland52b", [17120] = "cuntwland53b", 
   [17121] = "cuntwland54b", [17122] = "cuntwland55b", [17123] = "cuntwland56bx", [17124] = "cuntwland58b", [17125] = "cuntwland59b", 
   [17126] = "cuntwland60b", [17127] = "cuntwland62b", [17128] = "cuntwland63b", [17129] = "cuntwland64b", [17130] = "cuntwland65b", 
   [17131] = "cuntwland66b", [17132] = "cuntwland67b", [17133] = "cuntwland68b", [17134] = "cuntwland69b", [17135] = "cuntwland70b", 
   [17136] = "cuntwland71b", [17137] = "cuntwland72b", [17138] = "cuntwland73b", [17139] = "cuntwland74b", [17140] = "cuntwland75b", 
   [17141] = "cuntwland76b", [17142] = "cuntwland77b", [17143] = "cuntwland78b", [17144] = "cuntwland79b", [17145] = "cuntwland80b", 
   [17146] = "cuntwroad37", [17148] = "cuntwroad02", [17150] = "cuntwroad03", [17152] = "cuntwroad04", [17154] = "cuntwroad72", 
   [17156] = "cuntwroad06", [17158] = "cuntwroad07", [17160] = "cuntwroad08", [17162] = "cuntwroad09", [17164] = "cuntwroad10", 
   [17166] = "cuntwroad11", [17168] = "cuntwroad12", [17170] = "cuntwroad13", [17172] = "cuntwroad14", [17174] = "cuntwroad15", 
   [17176] = "cuntwroad16", [17178] = "cuntwroad17", [17180] = "cuntwroad18", [17182] = "cuntwroad19", [17184] = "cuntwroad20", 
   [17186] = "cuntwroad21", [17188] = "cuntwroad24", [17190] = "cuntwroad25", [17192] = "cuntwroad26", [17194] = "cuntwroad27", 
   [17196] = "cuntwroad28", [17198] = "cuntwroad29", [17200] = "cuntwroad30", [17202] = "cuntwroad31", [17204] = "cuntwroad32", 
   [17208] = "cuntwroad74", [17210] = "cuntwroad73", [17212] = "cuntwroad34", [17214] = "cuntwroad35", [17216] = "cuntwroad36", 
   [17218] = "cuntwroad01", [17220] = "cuntwroad38", [17222] = "cuntwroad05", [17224] = "cuntwroad40", [17226] = "cuntwroad41", 
   [17228] = "cuntwroad42", [17230] = "cuntwroad43", [17232] = "cuntwroad44", [17234] = "cuntwroad45", [17236] = "cuntwroad46", 
   [17238] = "cuntwroad47", [17240] = "cuntwroad48", [17242] = "cuntwroad49", [17244] = "cuntwroad50", [17246] = "cuntwroad51", 
   [17248] = "cuntwroad52", [17250] = "cuntwroad33", [17252] = "cuntwroad54", [17254] = "cuntwroad55", [17256] = "cuntwroad39", 
   [17258] = "cuntwroad57", [17260] = "cuntwroad58", [17262] = "cuntwroad59", [17267] = "cuntwroad66", [17269] = "cuntwroad67", 
   [17271] = "cuntwroad63", [17273] = "cuntwroad65", [17275] = "cuntwroad69", [17277] = "cuntwroad70", [17279] = "cuntwroad68", 
   [17281] = "cuntwroad71", [17283] = "cuntwrail12", [17284] = "cuntwrail11", [17285] = "cuntwrail10", [17286] = "cuntwrail09", 
   [17287] = "cuntwrail08", [17288] = "cuntwrail07", [17289] = "cuntwrail01", [17290] = "cuntwrail02", [17291] = "cuntwrail03", 
   [17292] = "cuntwrail04", [17293] = "bwidgecuntw", [17294] = "cuntwland53bd", [17295] = "cuntwland53bc", [17296] = "cuntwrail04v", 
   [17297] = "cuntwrail04c", [17298] = "sjmoldbarn03", [17299] = "cunt_rockgp2_27", [17300] = "cuntytunnel2", [17301] = "cuntwland49b", 
   [17302] = "cuntwland51b", [17303] = "cuntwroad22", [17305] = "cuntwroad23", [17307] = "cuntwland40c", [17308] = "cuntwland02c", 
   [17309] = "concretearch02", [17310] = "concretearch03", [17323] = "cuntwmotsignCJ", [17324] = "cw_combbarn", [17326] = "cuntwroad60", 
   [17327] = "cuntwroad61", [17329] = "cuntwroad62", [17331] = "cuntwroad53", [17333] = "cuntwroad64", [17334] = "cuntwroad56", 
   [17335] = "farmhouse02", [17426] = "cuntwwiresx", [17427] = "cuntwwiresxx", [17428] = "cuntwwiresxxx", [17429] = "telewirescuntw01", 
   [17430] = "telewirescuntw02", [17431] = "telewirescuntw03", [17432] = "telewirescuntw04", [17433] = "cuntwwiresxx01", [17434] = "cuntwwiresxz", 
   [17436] = "xoverlaymap01", [17437] = "xoverlaymap02", [17438] = "xoverlaymap03", [17439] = "xoverlaymap04", [17440] = "xoverlaymap05", 
   [17441] = "xoverlaymap06", [17442] = "xoverlaymap13", [17443] = "xoverlaymap08", [17444] = "xoverlay_rock", [17448] = "xoverlaymap09", 
   [17450] = "xoverlaymap10", [17451] = "xoverlaymap07", [17452] = "xoverlaymap07b", [17453] = "brownwater", [17454] = "cuntgrsilosrail", 
   [17455] = "dirtover", [17456] = "rockovergay", [17457] = "sjmoldbarn04", [17458] = "xxxxxxtra", [17459] = "xxxtra2", 
   [17460] = "xxxover", [17461] = "xxxe", [17462] = "xxxxxxxxa", [17463] = "xxxc01", [17464] = "xxxd", 
   [17465] = "xxxzc", [17466] = "xxxza", [17467] = "xxovr2", [17468] = "xxcliffx", [17469] = "xoverelaya", 
   [17470] = "xoverlaydrt", [17471] = "cuntybitx", [17472] = "cunt_rocgxp2_04", [17474] = "cuntwland17_de_a", [17500] = "stormdrainLAE2_05", 
   [17501] = "RiverBridge1_LAe", [17502] = "RiverBridge2_LAe", [17503] = "Furniture_LAe", [17504] = "furnittrans1_LAe", [17505] = "lae2_ground02", 
   [17506] = "stormdrainLAE2_06", [17507] = "stormdrainLAE2_03", [17508] = "BlockK_LAe2", [17509] = "lae2_ground03", [17510] = "barrioTrans01_LAe", 
   [17511] = "gwforum1_LAe", [17513] = "lae2_ground04", [17514] = "starthootra1_LAe", [17515] = "scumgym1_LAe", [17516] = "BlockItrans_LAe", 
   [17517] = "BarberBlock1_LAe", [17518] = "telwire_01_LAe2", [17519] = "market2_lae", [17520] = "market1_lae", [17521] = "Pawnshp_lae2", 
   [17522] = "gangshop7_lae2", [17523] = "Stripbar_lae", [17524] = "LongBeBlok1_LAe", [17525] = "RiverBridge3_LAe2", [17526] = "gangshops1_LAe", 
   [17527] = "gangblock1Tr_LAe", [17528] = "barrioTrans01_LAe01", [17529] = "gangshops2_LAe2", [17530] = "pigpenblok1Tr_LAe", [17531] = "barrio03A_LAe", 
   [17532] = "barrio06Trans_LAe", [17533] = "tempLB1_LAe2", [17534] = "cluckinbell1_LAe", [17535] = "furnsign1_LAe2", [17536] = "dambuild1_LAe2", 
   [17537] = "cineblock1_LAe2", [17538] = "powerstat1_LAe2", [17539] = "rdsigns4_LAe03", [17540] = "rdsigns4_LAe05", [17541] = "LBeachBlok1z_LAe2", 
   [17542] = "gangshops6_LAe2", [17543] = "gangshops5_LAe2", [17544] = "gangshops4_LAe2", [17545] = "barrio02_LAe", [17546] = "hydro3_LAe", 
   [17547] = "EBeachAp1_LAe2", [17548] = "lae2_ground05", [17549] = "BeachBlok01_LAe2", [17550] = "EasBeBrij1_LAe2", [17551] = "BeachBlok02_LAe2", 
   [17552] = "burnHous1_LAe2", [17553] = "BeachBlok3_LAe2", [17554] = "BeachBlok5_LAe2", [17555] = "BeachBlok7_LAe2", [17556] = "MStorCP1_LAe2", 
   [17557] = "MStorCP2_LAe2", [17558] = "MStorCP4_LAe2", [17559] = "MStorCP6_LAe2", [17560] = "EBeachAp3_LAe2", [17561] = "MsCpTunn2_LAe2", 
   [17562] = "LongBeBlokx_LAe", [17563] = "wattspark1_LAe2", [17564] = "Tempdoor_LAe2", [17565] = "rustybrij01_LAe2", [17566] = "sweetsdoor_LAe2", 
   [17567] = "stormdrainLAE2_07", [17568] = "stormdrainLAE2_04", [17573] = "rydhou01_LAe2", [17574] = "rydbkyar1_LAe2", [17575] = "burgho01_LAe2", 
   [17576] = "hubbridge1_LAe2", [17577] = "Liquorstore01_LAe2", [17578] = "Liquorstore02_LAe2", [17579] = "Liquorstore03_LAe2", [17582] = "stadtplaza_lae2", 
   [17583] = "stadt_fence", [17585] = "lae2transbit", [17586] = "ebeach_alphabits", [17588] = "ebeach_alpahbits2", [17589] = "ebeachpark", 
   [17591] = "ebeachalpha5", [17592] = "ebeach_veg", [17594] = "lae2_ground06", [17595] = "Lae2_roads01", [17596] = "Lae2_roads02", 
   [17597] = "Lae2_roads03", [17598] = "Lae2_roads04", [17599] = "Lae2_roads85", [17600] = "Lae2_roads05", [17601] = "lae2_ground07", 
   [17602] = "Lae2_roads07", [17603] = "Lae2_roads08", [17604] = "Lae2_roads09", [17605] = "Lae2_roads10", [17606] = "lae2_roadscoast04", 
   [17607] = "Lae2_roads12", [17608] = "Lae2_roads13", [17609] = "Lae2_roads14", [17610] = "Lae2_roads15", [17611] = "Lae2_roads16", 
   [17612] = "Lae2_roads88", [17613] = "Lae2_roads89", [17614] = "Lae2_landHUB02", [17615] = "Lae2_landHUB03", [17616] = "Lae2_landHUB04", 
   [17617] = "Lae2_landHUB05", [17618] = "Lae2_landHUB06", [17619] = "Lae2_landHUB07", [17620] = "Lae2_landHUB01", [17621] = "Lae2_roads17", 
   [17622] = "Lae2_roads18", [17623] = "Lae2_roads19", [17624] = "Lae2_roads20", [17625] = "Lae2_roads21", [17626] = "Lae2_roads22", 
   [17627] = "Lae2_roads23", [17628] = "Lae2_roads24", [17629] = "Lae2_roads25", [17630] = "Lae2_roads26", [17631] = "Lae2_roads27", 
   [17632] = "Lae2_roads28", [17633] = "lae2_ground08", [17634] = "lae2_ground09", [17635] = "lae2_ground10", [17636] = "lae2_ground11", 
   [17637] = "Lae2_roads29", [17638] = "Lae2_roads30", [17639] = "Lae2_roads31", [17640] = "Lae2_roads32", [17641] = "Lae2_roads33", 
   [17642] = "Lae2_roads90", [17643] = "Lae2_roads34", [17644] = "Lae2_roads35", [17645] = "lae2_ground12", [17646] = "Lae2_roads36", 
   [17647] = "Lae2_roads37", [17648] = "Lae2_roads38", [17649] = "Lae2_roads39", [17650] = "Lae2_roads40", [17651] = "Lae2_roads41", 
   [17652] = "Lae2_roads42", [17653] = "Lae2_roads43", [17654] = "Lae2_roads44", [17655] = "Lae2_roads46", [17656] = "Lae2_roads50", 
   [17657] = "Lae2_roads52", [17658] = "Lae2_roads53", [17659] = "Lae2_roads54", [17660] = "Lae2_roads55", [17661] = "Lae2_roads56", 
   [17662] = "Lae2_roads57", [17663] = "Lae2_roads58", [17664] = "lae2_ground13", [17665] = "lae2_ground14", [17666] = "Lae2_roads86", 
   [17667] = "Lae2_roads59", [17668] = "Lae2_roads64", [17669] = "Lae2_roads65", [17670] = "Lae2_roads66", [17671] = "Lae2_roads67", 
   [17672] = "Lae2_roads68", [17673] = "lae2_roadscoast06", [17674] = "lae2_roadscoast05", [17675] = "lae2_roadscoast03", [17676] = "lae2_roadscoast01", 
   [17677] = "lae2_ground15", [17678] = "grnd05_lae2", [17679] = "lae2_bigblock", [17680] = "Lae2_roads76", [17681] = "Lae2_roads77", 
   [17682] = "Lae2_roads78", [17683] = "Lae2_roads79", [17684] = "Lae2_roads80", [17685] = "lae2_ground16", [17686] = "stormdrainLAE2_01", 
   [17687] = "Lae2_roads81", [17688] = "stormdrainLAE2_02", [17689] = "brglae2", [17690] = "lae2_blockN", [17691] = "lae2_ground17", 
   [17692] = "Lae2_roads83", [17693] = "Lae2_roads84", [17694] = "lae2_ground17b", [17695] = "brg_lae2", [17696] = "lae2_ground18", 
   [17697] = "carlshou1_LAe2", [17698] = "sweetshou1_LAe2", [17699] = "mcstraps_LAe2", [17700] = "pigpenblok1_LAe2", [17804] = "LBeachApts1_LAe2", 
   [17805] = "BeachApartAT_LAe2", [17807] = "BeachApartA4_LAe2", [17809] = "BeachApartA5_LAe2", [17829] = "Lae2_roads48", [17841] = "gymblok2_lae2", 
   [17848] = "pigpen_props", [17849] = "Lae2_roads60", [17851] = "cineblok_alpha", [17852] = "autoshpblok_lae2", [17853] = "cine_mark_lae2", 
   [17854] = "cinmamkr_alpha", [17859] = "cinemark2_lae2", [17860] = "autoshp_alpha", [17862] = "compomark_lae2", [17863] = "compmart_alpha", 
   [17864] = "comp_puchase", [17865] = "comp_ground", [17866] = "grass_bank", [17867] = "Lae2_roads46b", [17872] = "grbank_alpha", 
   [17874] = "hubst_alpha", [17875] = "hubst2_alpha", [17876] = "hubst3_alpha", [17877] = "lae2_hubgrass", [17878] = "lae2_hubgrass2", 
   [17879] = "hubst4alpha", [17880] = "hub_grass3", [17881] = "hub5_grass", [17886] = "stdrain_alpha", [17887] = "stdrain_alpha2", 
   [17888] = "EBeachAp2_LAe2", [17891] = "ground2_alpha", [17892] = "grnd02_lae2", [17893] = "splitapts01", [17894] = "splitapts02", 
   [17897] = "cparkshit_alpha", [17898] = "hubbrdge_alphab", [17899] = "blockN_alpha", [17901] = "coast_apts", [17902] = "coastapt_alpha", 
   [17904] = "blokz_fireescape", [17905] = "bighillalpha", [17906] = "lae2_ground15b", [17907] = "bighillalpha2", [17911] = "stdrainalpha3", 
   [17912] = "stdrainalpha3b", [17913] = "hubbrdge_alpha", [17915] = "lae2billbrds2", [17916] = "lae2billbrds3", [17917] = "lae2billbrds4", 
   [17918] = "lae2billbrds5", [17919] = "lae2billbrds6", [17920] = "Lae2_roads49", [17921] = "Lae2_roads82", [17922] = "coast_apts2", 
   [17925] = "carls_faux", [17926] = "sweet_faux_ent", [17927] = "Lae2_roads06", [17928] = "burnsfakeint", [17933] = "Carter-light15b", 
   [17934] = "coochieghous", [17936] = "rbridge3_girders", [17937] = "stormd_fill", [17938] = "stormd_fillc", [17939] = "stormd_fillb", 
   [17940] = "rbridg23_girders", [17941] = "stormd_filld", [17942] = "stormd_fille", [17943] = "ebeachalpha5b", [17944] = "LngBeBlok2_LAe", 
   [17946] = "Carter_GROUND", [17947] = "burg_alpha", [17950] = "cjsaveg", [17951] = "cjgaragedoor", [17953] = "conc_bblok", 
   [17954] = "nitelites_LAE2", [17955] = "nitelitesb_LAE2", [17956] = "nitelitesc_LAE2", [17957] = "nitelitesd_LAE2", [17958] = "buringd_alpha", 
   [17968] = "hubridge_smash", [17969] = "hub_graffitti", [17971] = "hub_grnd_alpha", [17972] = "grnd_alpha2", [17973] = "grnd_alpha3", 
   [17974] = "grnd_alpha4", [17976] = "grnd_alpha5", [17978] = "grnd_alpha6", [18000] = "ammunationwwws01", [18001] = "int_barberA07", 
   [18002] = "int_barberA02", [18003] = "int_barberA03", [18004] = "int_barberA05", [18005] = "int_barberA01", [18006] = "int_barberA08", 
   [18007] = "int_barberA12", [18008] = "int_clothingA01", [18009] = "int_rest_main", [18010] = "int_3rest_lights", [18011] = "int_rest_veg02", 
   [18012] = "int_rest_veg01", [18013] = "int_rest_veg3", [18014] = "int_rest_veg03", [18015] = "int_rest_veg04", [18016] = "int_rest_canopy", 
   [18017] = "int_rest_counchs", [18018] = "int_bars", [18019] = "int_burger_furn", [18020] = "int_6burger_main", [18021] = "int_din_donut_main", 
   [18022] = "int_chick_main", [18023] = "int_pizzaplace", [18024] = "int_clothe_ship", [18025] = "clothes_sports", [18026] = "clothes_shit", 
   [18027] = "CJ_BARB_2", [18028] = "smllbarinterior", [18029] = "smllrestaurant", [18030] = "GAP", [18031] = "clothesexl", 
   [18032] = "range_xtras2", [18033] = "munation_main", [18034] = "CJ_AMMUN1_EXTRA", [18035] = "munation_xtras2", [18036] = "range_main", 
   [18038] = "Gun-Shop-Vegas", [18039] = "vg_mun_opac2", [18040] = "vg_mun_xtras4", [18041] = "vg_mun_xtras3", [18042] = "gun_counter09", 
   [18043] = "CJ_AMMUN_BITS", [18044] = "CJ_AMMUN3_EXTRA", [18045] = "mp_ammu01", [18046] = "mp_ammu03", [18047] = "mpgun_counter06", 
   [18048] = "mp_ammu02", [18049] = "ammu_twofloor", [18050] = "range_opac01", [18051] = "range_xtras03", [18052] = "munation_xtras03", 
   [18053] = "munation_xtras04", [18054] = "munation_xtras05", [18055] = "smllrestseats", [18056] = "mp_dinerbig", [18057] = "table-plain", 
   [18058] = "mp_dinersmall", [18059] = "tables", [18060] = "big_seats", [18061] = "condiments07", [18062] = "ab_sfAmmuItems01", 
   [18063] = "ab_sfAmmuItems02", [18064] = "ab_sfAmmuUnits", [18065] = "ab_sfAmmuMain", [18066] = "posterv", [18067] = "blood-splat", 
   [18068] = "clothes-spot", [18069] = "clothes_sports2", [18070] = "GAP_COUNTER", [18071] = "Gap_Shadow", [18072] = "GAP_WINDOW", 
   [18073] = "Sub_shadow", [18074] = "Donut_rail", [18075] = "lightD", [18076] = "SHAD_1", [18077] = "din_donut_furn", 
   [18078] = "CJ_BARB_2_acc", [18079] = "BARB_CURTAIN", [18080] = "DONUT_BLINDS", [18081] = "CJ_AB_Barber2_2", [18082] = "CJ_Barber2", 
   [18083] = "CJ_Barber2_1", [18084] = "BARBER_BLINDS", [18085] = "Object01hjk", [18086] = "B_Lights", [18087] = "DONUT_BLINDS2", 
   [18088] = "cj_changing_room", [18089] = "DISCO_FENCE", [18090] = "Bar_BAR1", [18091] = "CJ_BAR_2_DETAILS", [18092] = "ammun3_counter", 
   [18093] = "LIGHT_SHARD_", [18094] = "CJ_SWEATER_F_71", [18095] = "BARBER_BLINDS02", [18096] = "LIGHT_SHARD_06", [18097] = "LIGHT_SHARD_07", 
   [18098] = "BARBER_BLINDS03", [18099] = "cj_RUBBISH", [18100] = "cj_RUBBISH01", [18101] = "cj_RUBBISH02", [18102] = "Light_box1", 
   [18104] = "CJ_AMMUN_BITS1", [18105] = "CJ_AMMUN5_EXTRA", [18109] = "CJ_AMMUN4_EXTRA", [18112] = "sub_signs", [18200] = "w_town_11", 
   [18201] = "wtown_bits2_02", [18202] = "wtown_trailwal", [18203] = "wtown_bits2_05", [18204] = "w_townwires_01", [18205] = "w_townwires_02", 
   [18206] = "w_townwires_03", [18207] = "w_townwires_04", [18208] = "w_townwires_05", [18209] = "w_townwires_06", [18210] = "w_townwires_07", 
   [18211] = "w_townwires_08", [18212] = "w_townwires_09", [18213] = "w_townwires_10", [18214] = "w_townwires_11", [18215] = "w_townwires_12", 
   [18216] = "mtbfence1", [18217] = "mtbfence06", [18218] = "mtbfence08", [18219] = "mtbfence09", [18220] = "mtbfence10", 
   [18221] = "mtbfence11", [18222] = "mtbfence12", [18223] = "mtbfence14", [18224] = "mtbfence15", [18225] = "cunt_rockgp2_18", 
   [18226] = "cunt_rockgp2_19", [18227] = "cunt_rockgp2_20", [18228] = "cunt_rockgp2_21", [18229] = "w7bark", [18230] = "logcabinnlogs", 
   [18231] = "cs_landbit_81", [18232] = "cuntw_ngassta", [18233] = "cuntw_town07", [18234] = "cuntw_shed2_", [18235] = "cuntw_weechurch_", 
   [18236] = "cuntw_shed3_", [18237] = "cuntw_dinerwst", [18238] = "cuntw_stwnfurn_", [18239] = "cuntw_restrnt1", [18240] = "cuntw_liquor01", 
   [18241] = "cuntw_weebuild", [18242] = "cuntw_stwnmotel01", [18243] = "cuntw_stmotsigbas1", [18244] = "cuntw_stwnmotsign1", [18245] = "cuntwjunk02", 
   [18246] = "cuntwjunk04", [18247] = "cuntwjunk03", [18248] = "cuntwjunk01", [18249] = "cuntwjunk05", [18250] = "cuntwjunk06", 
   [18251] = "cuntwjunk07", [18252] = "cuntwjunk08", [18253] = "cuntwjunk09", [18254] = "cuntwjunk10", [18255] = "cuntwjunk11", 
   [18256] = "w7bark01", [18257] = "crates", [18258] = "logcabinnlogs01", [18259] = "logcabinn01", [18260] = "crates01", 
   [18261] = "cw2_photoblock", [18262] = "cw2_phroofstuf", [18263] = "wtown_bits2_06", [18264] = "cw2_cinemablock", [18265] = "cw2_wtownblok1", 
   [18266] = "wtown_shops", [18267] = "logcabinn", [18268] = "cw2_mntfir05", [18269] = "cw2_mntfir11", [18270] = "cw2_mntfir13", 
   [18271] = "cw2_mntfir16", [18272] = "cw2_mntfir27", [18273] = "cw2_weefirz08", [18274] = "cuntw_shed3_01", [18275] = "cw2_mtbfinish", 
   [18276] = "mtb2_barrier1", [18277] = "mtb2_barrier2", [18278] = "mtb2_barrier3", [18279] = "mtb2_barrier6", [18280] = "mtb2_barrier4", 
   [18281] = "mtb2_barrier5", [18282] = "cw_tsblock", [18283] = "cw_fuelpay", [18284] = "cw_tscanopy", [18285] = "cw_trucklines", 
   [18286] = "cw_mountbarr06", [18287] = "cw_mountbarr01", [18288] = "cw_mountbarr02", [18289] = "cw_mountbarr03", [18290] = "cw_mountbarr04", 
   [18291] = "cw_mountbarr07", [18292] = "cw_mountbarr05", [18293] = "cs_landbit_03", [18294] = "cs_landbit_04", [18295] = "cs_landbit_05", 
   [18296] = "cs_landbit_06", [18297] = "cs_landbit_07", [18298] = "cs_landbit_08", [18299] = "cs_landbit_09", [18300] = "cs_landbit_10", 
   [18301] = "cs_landbit_11", [18302] = "cs_landbit_13", [18303] = "cs_landbit_14", [18304] = "cs_landbit_15", [18305] = "cs_landbit_16", 
   [18306] = "cs_landbit_17", [18307] = "cs_landbit_18", [18308] = "cs_landbit_19", [18309] = "cs_landbit_20", [18310] = "cs_landbit_21", 
   [18311] = "cs_landbit_22", [18312] = "cs_landbit_23", [18313] = "cs_landbit_24", [18314] = "cs_landbit_25", [18315] = "cs_landbit_26", 
   [18316] = "cs_landbit_27", [18317] = "cs_landbit_28", [18318] = "cs_landbit_29", [18319] = "cs_landbit_30", [18320] = "cs_landbit_31", 
   [18321] = "cs_landbit_32", [18322] = "cs_landbit_33", [18323] = "cs_landbit_34", [18324] = "cs_landbit_35", [18325] = "cs_landbit_36", 
   [18326] = "cs_landbit_37", [18327] = "cs_landbit_38", [18328] = "cs_landbit_39", [18329] = "cs_landbit_40", [18330] = "cs_landbit_41", 
   [18331] = "cs_landbit_42", [18332] = "cs_landbit_43", [18333] = "cs_landbit_44", [18334] = "cs_landbit_45", [18335] = "cs_landbit_47", 
   [18336] = "cs_landbit_48", [18337] = "cs_landbit_49", [18338] = "cs_landbit_50", [18339] = "cs_landbit_51", [18340] = "cs_landbit_52", 
   [18341] = "cs_landbit_53", [18342] = "cs_landbit_55", [18343] = "cs_landbit_56", [18344] = "cs_landbit_57", [18345] = "cs_landbit_58", 
   [18346] = "cs_landbit_59", [18347] = "cs_landbit_60", [18348] = "cs_landbit_61", [18349] = "cs_landbit_62", [18350] = "cs_landbit_64", 
   [18351] = "cs_landbit_65", [18352] = "cs_landbit_66", [18353] = "cs_landbit_67", [18354] = "cs_landbit_68", [18355] = "cs_landbit_69", 
   [18356] = "cs_landbit_70", [18357] = "cs_landbit_71", [18358] = "cs_landbit_73", [18359] = "cs_landbit_74", [18360] = "cs_landbit_75", 
   [18361] = "cs_landbit_76", [18362] = "cs_landbit_79", [18363] = "cs_landbit_80", [18364] = "cs_landbit_01", [18365] = "sawmill", 
   [18366] = "cw2_mountwalk1", [18367] = "cw2_bikelog", [18368] = "cs_mountplat", [18369] = "cs_roads01", [18370] = "cs_roads02", 
   [18371] = "cs_roads03", [18372] = "cs_roads04", [18373] = "cs_roads05", [18374] = "cs_roads06", [18375] = "cs_roads07", 
   [18376] = "cs_roads08", [18377] = "cs_roads09", [18378] = "cs_roads10", [18379] = "cs_roads11", [18380] = "cs_roads12", 
   [18381] = "cs_roads13", [18382] = "cs_roads16", [18383] = "cs_roads17", [18384] = "cs_roads20", [18385] = "cuntsrod03", 
   [18386] = "cuntsrod02", [18387] = "cuntsrod14", [18388] = "cuntsrod01", [18389] = "cs_roads26", [18390] = "cs_roads27", 
   [18391] = "cs_roads28", [18392] = "cs_roads29", [18393] = "cuntsrod04", [18394] = "cs_roads35", [18432] = "mtbfence17", 
   [18433] = "mtbfence21", [18434] = "mtbfence24", [18435] = "mtb_poles01", [18436] = "mtb_poles02", [18437] = "mtb_poles03", 
   [18438] = "mtb_poles04", [18439] = "mtb_poles05", [18440] = "mtbfence26", [18441] = "mtbfence29", [18442] = "mtbfence31", 
   [18443] = "mtbfence32", [18444] = "mtbfence39", [18445] = "mtbfence40", [18446] = "mtbfence43", [18447] = "cs_mntdetail01", 
   [18448] = "w_townwires_13", [18449] = "cs_roadbridge01", [18450] = "cs_roadbridge04", [18451] = "cs_oldcarjmp", [18452] = "cw_tscanopy01", 
   [18453] = "cs_detrok01", [18454] = "cs_detrok02", [18455] = "cs_detrok04", [18456] = "cs_detrok03", [18457] = "cs_detrok05", 
   [18458] = "cs_detrok06", [18459] = "cs_detrok07", [18460] = "cs_detrok08", [18461] = "cs_detrok09", [18462] = "cs_detrok10", 
   [18463] = "cs_detrok11", [18464] = "cs_detrok12", [18465] = "cs_detrok13", [18466] = "cs_detrok14", [18467] = "cs_detrok15", 
   [18468] = "cs_detrok16", [18469] = "cs_landbit_12", [18470] = "telewires2cs", [18471] = "telewires1cs", [18472] = "telewires3cs", 
   [18473] = "cs_landbit_50b", [18474] = "cstwnland03", [18475] = "cs_landbit_50c", [18476] = "cuntsrod12", [18477] = "cuntsrod11", 
   [18478] = "cuntsrod09", [18479] = "cuntsrod10", [18480] = "cuntsrod06", [18481] = "cuntsrod08", [18482] = "cuntsrod05", 
   [18483] = "cuntsrod07", [18484] = "cuntsrod13", [18485] = "cs_landbit_50d", [18496] = "w_town11b", [18518] = "cuntsrod02NEW", 
   [18551] = "countS_barriers", [18552] = "cunts_ammun", [18553] = "count_ammundoor", [18561] = "cS_newbridge", [18563] = "cS_bsupport", 
   [18565] = "Cs_Logs03", [18566] = "Cs_Logs02", [18567] = "Cs_Logs04", [18568] = "Cs_Logs05", [18569] = "Cs_Logs01", 
   [18608] = "countS_lights01", [18609] = "Cs_Logs06", [18610] = "cs_landbit_70_A", [18611] = "cs_landbit_71_A", [18612] = "cs_landbit_53_A", 
   [18613] = "cs_landbit_61_A", [18614] = "cs_landbit_44_A", [18615] = "cs_landbit_33_A", [18616] = "cs_landbit_25_A", [18617] = "cs_landbit_A", 
   [18618] = "cs_landbit_41_A", [18619] = "cs_landbit_50_A", [18620] = "w_town_11_A", [18621] = "cs_landbit_58_A", [18622] = "cs_landbit_50b_A", 
   [18623] = "cs_landbit_68_A", [18624] = "cs_landbit_65_A", [18625] = "cs_landbit_48_A", [18626] = "cs_landbit_36_A", [18627] = "cs_landbit_27_A", 
   [18628] = "cs_landbit_10_A", [18629] = "cs_landbit_06_A", [18630] = "cs_landbit_20_A", [18631] = "NoModelFile", [18632] = "FishingRod", 
   [18633] = "GTASAWrench1", [18634] = "GTASACrowbar1", [18635] = "GTASAHammer1", [18636] = "PoliceCap1", [18637] = "PoliceShield1", 
   [18638] = "HardHat1", [18639] = "BlackHat1", [18640] = "Hair1", [18641] = "Flashlight1", [18642] = "Taser1", 
   [18643] = "LaserPointer1", [18644] = "Screwdriver1", [18645] = "MotorcycleHelmet1", [18646] = "PoliceLight1", [18647] = "RedNeonTube1", 
   [18648] = "BlueNeonTube1", [18649] = "GreenNeonTube1", [18650] = "YellowNeonTube1", [18651] = "PinkNeonTube1", [18652] = "WhiteNeonTube1", 
   [18653] = "DiscoLightRed", [18654] = "DiscoLightGreen", [18655] = "DiscoLightBlue", [18656] = "LightBeamWhite", [18657] = "LightBeamRed", 
   [18658] = "LightBeamBlue", [18659] = "SprayTag1", [18660] = "SprayTag2", [18661] = "SprayTag3", [18662] = "SprayTag4", 
   [18663] = "SprayTag5", [18664] = "SprayTag6", [18665] = "SprayTag7", [18666] = "SprayTag8", [18667] = "SprayTag9", 
   [18667] = "SprayTag9H", [18668] = "blood_heli", [18669] = "boat_prop", [18670] = "camflash", [18671] = "carwashspray", 
   [18672] = "cementp", [18673] = "cigarette_smoke", [18674] = "cloudfast", [18675] = "coke_puff", [18676] = "coke_trail", 
   [18677] = "exhale", [18678] = "explosion_barrel", [18679] = "explosion_crate", [18680] = "explosion_door", [18681] = "explosion_fuel_car", 
   [18682] = "explosion_large", [18683] = "explosion_medium", [18684] = "explosion_molotov", [18685] = "explosion_small", [18686] = "explosion_tiny", 
   [18687] = "extinguisher", [18688] = "fire", [18689] = "fire_bike", [18690] = "fire_car", [18691] = "fire_large", 
   [18692] = "fire_med", [18693] = "Flame99", [18694] = "flamethrower", [18694] = "flamethrowerp", [18695] = "gunflash", 
   [18696] = "gunsmoke", [18697] = "heli_dust", [18698] = "insects", [18699] = "jetpack", [18699] = "jetpackp", 
   [18700] = "jetthrust", [18701] = "molotov_flame", [18702] = "nitro", [18702] = "nitrop", [18703] = "overheat_car", 
   [18704] = "overheat_car_elec", [18705] = "petrolcan", [18706] = "prt_blood", [18707] = "prt_boatsplash", [18708] = "prt_bubble", 
   [18709] = "prt_cardebris", [18710] = "prt_collisionsmoke", [18711] = "prt_glass", [18712] = "prt_gunshell", [18713] = "prt_sand2", 
   [18714] = "prt_sand", [18715] = "prt_smoke_huge", [18716] = "prt_smoke_expand", [18717] = "prt_spark", [18718] = "prt_spark_2", 
   [18719] = "prt_wake", [18720] = "prt_watersplash", [18721] = "prt_wheeldirt", [18722] = "puke", [18723] = "riot_smoke", 
   [18724] = "shootlight", [18725] = "smoke30lit", [18726] = "smoke30m", [18727] = "smoke50lit", [18728] = "smoke_flare", 
   [18729] = "spraycan", [18729] = "spraycanp", [18730] = "tank_fire", [18731] = "teargas99", [18732] = "teargasAD", 
   [18733] = "tree_hit_fir", [18734] = "tree_hit_palm", [18735] = "vent2", [18736] = "vent", [18737] = "wallbust", 
   [18738] = "water_fnt_tme", [18739] = "water_fountain", [18740] = "water_hydrant", [18741] = "water_ripples", [18742] = "water_speed", 
   [18743] = "water_splash", [18744] = "water_splash_big", [18745] = "water_splsh_sml", [18746] = "water_swim", [18747] = "waterfall_end", 
   [18748] = "WS_factorysmoke", [18749] = "SAMPLogoSmall", [18750] = "SAMPLogoBig", [18751] = "IslandBase1", [18752] = "Volcano", 
   [18753] = "Base125mx125m1", [18754] = "Base250mx250m1", [18755] = "VCElevator1", [18756] = "ElevatorDoor1", [18757] = "ElevatorDoor2", 
   [18758] = "VCElevatorFront1", [18759] = "DMCage1", [18760] = "DMCage2", [18761] = "RaceFinishLine1", [18762] = "Concrete1mx1mx5m", 
   [18763] = "Concrete3mx3mx5m", [18764] = "Concrete5mx5mx5m", [18765] = "Concrete10mx10mx5m", [18766] = "Concrete10mx1mx5m", [18767] = "ConcreteStair1", 
   [18767] = "ConcreteStair1H", [18768] = "SkyDivePlatform1", [18769] = "SkyDivePlatform1a", [18770] = "SkyDivePlatform1b", [18771] = "SpiralStair1", 
   [18772] = "TunnelSection1", [18773] = "TunnelJoinSection1", [18774] = "TunnelJoinSection2", [18775] = "TunnelJoinSection3", [18776] = "TunnelJoinSection4", 
   [18777] = "TunnelSpiral1", [18778] = "RampT1", [18779] = "RampT2", [18780] = "RampT3", [18781] = "MeshRampBig", 
   [18782] = "CookieRamp1", [18783] = "FunBoxTop1", [18784] = "FunBoxRamp1", [18785] = "FunBoxRamp2", [18786] = "FunBoxRamp3", 
   [18787] = "FunBoxRamp4", [18788] = "MRoad40m", [18789] = "MRoad150m", [18790] = "MRoadBend180Deg1", [18791] = "MRoadBend45Deg", 
   [18792] = "MRoadTwist15DegL", [18793] = "MRoadTwist15DegR", [18794] = "MRoadBend15Deg1", [18795] = "MRoadBend15Deg2", [18796] = "MRoadBend15Deg3", 
   [18797] = "MRoadBend15Deg4", [18798] = "MRoadB45T15DegL", [18799] = "MRoadB45T15DegR", [18800] = "MRoadHelix1", [18801] = "MRoadLoop1", 
   [18802] = "MBridgeRamp1", [18803] = "MBridge150m1", [18804] = "MBridge150m2", [18805] = "MBridge150m3", [18806] = "MBridge150m4", 
   [18807] = "MBridge75mHalf", [18808] = "Tube50m1", [18809] = "Tube50mGlass1", [18810] = "Tube50mBulge1", [18811] = "Tube50mGlassBulge1", 
   [18812] = "Tube50mFunnel1", [18813] = "Tube50mGlassFunnel1", [18814] = "Tube50mFunnel2", [18815] = "Tube50mFunnel3", [18816] = "Tube50mFunnel4", 
   [18817] = "Tube50mTSection1", [18818] = "Tube50mGlassT1", [18819] = "Tube50mPlus1", [18820] = "Tube50mGlassPlus1", [18821] = "Tube50m45Bend1", 
   [18822] = "Tube50mGlass45Bend1", [18823] = "Tube50m90Bend1", [18824] = "Tube50mGlass90Bend1", [18825] = "Tube50m180Bend1", [18826] = "Tube50mGlass180Bend", 
   [18827] = "Tube100m2", [18828] = "SpiralTube1", [18829] = "RTexturetube", [18830] = "RTexturebridge", [18831] = "RT25mBend90Tube1", 
   [18832] = "RT25mBend180Tube1", [18833] = "RT50mBend45Tube1", [18834] = "RT50mBend180Tube1", [18835] = "RBFunnel", [18836] = "RBHalfpipe", 
   [18837] = "RB25mBend90Tube", [18838] = "RB25mBend180Tube", [18839] = "RB50mBend45Tube", [18840] = "RB50mBend90Tube", [18841] = "RB50mBend180Tube", 
   [18842] = "RB50mTube", [18843] = "GlassSphere1", [18844] = "WaterUVAnimSphere1", [18845] = "RTexturesphere", [18846] = "BigCesar", 
   [18846] = "UFO", [18847] = "HugeHalfPipe1", [18848] = "SamSiteNonDynamic", [18849] = "ParaDropNonDynamic", [18850] = "HeliPad1", 
   [18851] = "TubeToRoad1", [18852] = "Tube100m1", [18853] = "Tube100m45Bend1", [18854] = "Tube100m90Bend1", [18855] = "Tube100m180Bend1", 
   [18856] = "Cage5mx5mx3m", [18857] = "Cage20mx20mx10m", [18858] = "FoamHoop1", [18859] = "QuarterPipe1", [18860] = "skyscrpunbuilt2", 
   [18861] = "scaffoldlift", [18862] = "GarbagePileRamp1", [18863] = "SnowArc1", [18864] = "FakeSnow1", [18865] = "MobilePhone1", 
   [18866] = "MobilePhone2", [18867] = "MobilePhone3", [18868] = "MobilePhone4", [18869] = "MobilePhone5", [18870] = "MobilePhone6", 
   [18871] = "MobilePhone7", [18872] = "MobilePhone8", [18873] = "MobilePhone9", [18874] = "MobilePhone10", [18875] = "Pager1", 
   [18876] = "BigGreenGloop1", [18877] = "FerrisWheelBit", [18878] = "FerrisBaseBit", [18879] = "FerrisCageBit", [18880] = "SpeedCamera1", 
   [18881] = "SkyDivePlatform2", [18882] = "HugeBowl1", [18883] = "HugeBowl2", [18884] = "HugeBowl3", [18885] = "GunVendingMachine1", 
   [18886] = "ElectroMagnet1", [18887] = "ForceField1", [18888] = "ForceField2", [18889] = "ForceField3", [18890] = "Rake1", 
   [18891] = "Bandana1", [18892] = "Bandana2", [18893] = "Bandana3", [18894] = "Bandana4", [18895] = "Bandana5", 
   [18896] = "Bandana6", [18897] = "Bandana7", [18898] = "Bandana8", [18899] = "Bandana9", [18900] = "Bandana10", 
   [18901] = "Bandana11", [18902] = "Bandana12", [18903] = "Bandana13", [18904] = "Bandana14", [18905] = "Bandana15", 
   [18906] = "Bandana16", [18907] = "Bandana17", [18908] = "Bandana18", [18909] = "Bandana19", [18910] = "Bandana20", 
   [18911] = "Mask1", [18912] = "Mask2", [18913] = "Mask3", [18914] = "Mask4", [18915] = "Mask5", 
   [18916] = "Mask6", [18917] = "Mask7", [18918] = "Mask8", [18919] = "Mask9", [18920] = "Mask10", 
   [18921] = "Beret1", [18922] = "Beret2", [18923] = "Beret3", [18924] = "Beret4", [18925] = "Beret5", 
   [18926] = "Hat1", [18927] = "Hat2", [18928] = "Hat3", [18929] = "Hat4", [18930] = "Hat5", 
   [18931] = "Hat6", [18932] = "Hat7", [18933] = "Hat8", [18934] = "Hat9", [18935] = "Hat10", 
   [18936] = "Helmet1", [18937] = "Helmet2", [18938] = "Helmet3", [18939] = "CapBack1", [18940] = "CapBack2", 
   [18941] = "CapBack3", [18942] = "CapBack4", [18943] = "CapBack5", [18944] = "HatBoater1", [18945] = "HatBoater2", 
   [18946] = "HatBoater3", [18947] = "HatBowler1", [18948] = "HatBowler2", [18949] = "HatBowler3", [18950] = "HatBowler4", 
   [18951] = "HatBowler5", [18952] = "BoxingHelmet1", [18953] = "CapKnit1", [18954] = "CapKnit2", [18955] = "CapOverEye1", 
   [18956] = "CapOverEye2", [18957] = "CapOverEye3", [18958] = "CapOverEye4", [18959] = "CapOverEye5", [18960] = "CapRimUp1", 
   [18961] = "CapTrucker1", [18962] = "CowboyHat2", [18963] = "CJElvisHead", [18964] = "SkullyCap1", [18965] = "SkullyCap2", 
   [18966] = "SkullyCap3", [18967] = "HatMan1", [18968] = "HatMan2", [18969] = "HatMan3", [18970] = "HatTiger1", 
   [18971] = "HatCool1", [18972] = "HatCool2", [18973] = "HatCool3", [18974] = "MaskZorro1", [18975] = "Hair2", 
   [18976] = "MotorcycleHelmet2", [18977] = "MotorcycleHelmet3", [18978] = "MotorcycleHelmet4", [18979] = "MotorcycleHelmet5", [18980] = "Concrete1mx1mx25m", 
   [18981] = "Concrete1mx25mx25m", [18982] = "Tube100m3", [18983] = "Tube100m4", [18984] = "Tube100m5", [18985] = "Tube100m6", 
   [18986] = "TubeToPipe1", [18987] = "Tube25m1", [18988] = "Tube25mCutEnd1", [18989] = "Tube25m45Bend1", [18990] = "Tube25m90Bend1", 
   [18991] = "Tube25m180Bend1", [18992] = "Tube10m45Bend1", [18993] = "Tube10m90Bend1", [18994] = "Tube10m180Bend1", [18995] = "Tube5m1", 
   [18996] = "Tube5m45Bend1", [18997] = "Tube1m1", [18998] = "Tube200m1", [18999] = "Tube200mBendy1", [19000] = "Tube200mBulge1", 
   [19001] = "VCWideLoop1", [19001] = "VCWideLoop10", [19002] = "FireHoop1", [19003] = "LAOfficeFloors1", [19003] = "RampT5", 
   [19004] = "RoundBuilding1", [19005] = "RampT4", [19006] = "GlassesType1", [19007] = "GlassesType2", [19008] = "GlassesType3", 
   [19009] = "GlassesType4", [19010] = "GlassesType5", [19011] = "GlassesType6", [19012] = "GlassesType7", [19013] = "GlassesType8", 
   [19014] = "GlassesType9", [19015] = "GlassesType10", [19016] = "GlassesType11", [19017] = "GlassesType12", [19018] = "GlassesType13", 
   [19019] = "GlassesType14", [19020] = "GlassesType15", [19021] = "GlassesType16", [19022] = "GlassesType17", [19023] = "GlassesType18", 
   [19024] = "GlassesType19", [19025] = "GlassesType20", [19026] = "GlassesType21", [19027] = "GlassesType22", [19028] = "GlassesType23", 
   [19029] = "GlassesType24", [19030] = "GlassesType25", [19031] = "GlassesType26", [19032] = "GlassesType27", [19033] = "GlassesType28", 
   [19034] = "GlassesType29", [19035] = "GlassesType30", [19036] = "HockeyMask1", [19037] = "HockeyMask2", [19038] = "HockeyMask3", 
   [19039] = "WatchType1", [19040] = "WatchType2", [19041] = "WatchType3", [19042] = "WatchType4", [19043] = "WatchType5", 
   [19044] = "WatchType6", [19045] = "WatchType7", [19046] = "WatchType8", [19047] = "WatchType9", [19048] = "WatchType10", 
   [19049] = "WatchType11", [19050] = "WatchType12", [19051] = "WatchType13", [19052] = "WatchType14", [19053] = "WatchType15", 
   [19054] = "XmasBox1", [19055] = "XmasBox2", [19056] = "XmasBox3", [19057] = "XmasBox4", [19058] = "XmasBox5", 
   [19059] = "XmasOrb1", [19060] = "XmasOrb2", [19061] = "XmasOrb3", [19062] = "XmasOrb4", [19063] = "XmasOrb5", 
   [19064] = "SantaHat1", [19065] = "SantaHat2", [19066] = "SantaHat3", [19067] = "HoodyHat1", [19068] = "HoodyHat2", 
   [19069] = "HoodyHat3", [19070] = "WSDown1", [19071] = "WSStraight1", [19072] = "WSBend45Deg1", [19073] = "WSRocky1", 
   [19074] = "Cage20mx20mx10mv2", [19075] = "Cage5mx5mx3mv2", [19076] = "XmasTree1", [19077] = "Hair3", [19078] = "TheParrot1", 
   [19079] = "TheParrot2", [19080] = "LaserPointer2", [19081] = "LaserPointer3", [19082] = "LaserPointer4", [19083] = "LaserPointer5", 
   [19084] = "LaserPointer6", [19085] = "EyePatch1", [19086] = "ChainsawDildo1", [19087] = "Rope1", [19088] = "Rope2", 
   [19089] = "Rope3", [19090] = "PomPomBlue", [19091] = "PomPomRed", [19092] = "PomPomGreen", [19093] = "HardHat2", 
   [19094] = "BurgerShotHat1", [19095] = "CowboyHat1", [19096] = "CowboyHat3", [19097] = "CowboyHat4", [19098] = "CowboyHat5", 
   [19099] = "PoliceCap2", [19100] = "PoliceCap3", [19101] = "ArmyHelmet1", [19102] = "ArmyHelmet2", [19103] = "ArmyHelmet3", 
   [19104] = "ArmyHelmet4", [19105] = "ArmyHelmet5", [19106] = "ArmyHelmet6", [19107] = "ArmyHelmet7", [19108] = "ArmyHelmet8", 
   [19109] = "ArmyHelmet9", [19110] = "ArmyHelmet10", [19111] = "ArmyHelmet11", [19112] = "ArmyHelmet12", [19113] = "SillyHelmet1", 
   [19114] = "SillyHelmet2", [19115] = "SillyHelmet3", [19116] = "PlainHelmet1", [19117] = "PlainHelmet2", [19118] = "PlainHelmet3", 
   [19119] = "PlainHelmet4", [19120] = "PlainHelmet5", [19121] = "BollardLight1", [19122] = "BollardLight2", [19123] = "BollardLight3", 
   [19124] = "BollardLight4", [19125] = "BollardLight5", [19126] = "BollardLight6", [19127] = "BollardLight7", [19128] = "DanceFloor1", 
   [19129] = "DanceFloor2", [19130] = "ArrowType1", [19131] = "ArrowType2", [19132] = "ArrowType3", [19133] = "ArrowType4", 
   [19134] = "ArrowType5", [19135] = "EnExMarker1", [19136] = "Hair4", [19137] = "CluckinBellHat1", [19138] = "PoliceGlasses1", 
   [19139] = "PoliceGlasses2", [19140] = "PoliceGlasses3", [19141] = "SWATHelmet1", [19142] = "SWATArmour1", [19143] = "PinSpotLight1", 
   [19144] = "PinSpotLight2", [19145] = "PinSpotLight3", [19146] = "PinSpotLight4", [19147] = "PinSpotLight5", [19148] = "PinSpotLight6", 
   [19149] = "PinSpotLight7", [19150] = "PinSpotLight8", [19151] = "PinSpotLight9", [19152] = "PinSpotLight10", [19153] = "PinSpotLight11", 
   [19154] = "PinSpotLight12", [19155] = "PinSpotLight13", [19156] = "PinSpotLight14", [19157] = "MetalLightBars1", [19158] = "MetalLightBars2", 
   [19159] = "MirrorBall1", [19160] = "HardHat3", [19161] = "PoliceHat1", [19162] = "PoliceHat2", [19163] = "GimpMask1", 
   [19164] = "GTASAMap1", [19164] = "GTASAMap1vert", [19165] = "GTASAMap2", [19166] = "GTASAMap3", [19167] = "GTASAMap4", 
   [19168] = "GTASAMap5", [19169] = "GTASAMap6", [19170] = "GTASAMap7", [19171] = "GTASAMap8", [19172] = "SAMPPicture1", 
   [19173] = "SAMPPicture2", [19174] = "SAMPPicture3", [19175] = "SAMPPicture4", [19176] = "LSOffice1Door1", [19177] = "MapMarkerNew1", 
   [19178] = "MapMarkerNew2", [19179] = "MapMarkerNew3", [19180] = "MapMarkerNew4", [19181] = "MapMarkerNew5", [19182] = "MapMarkerNew6", 
   [19183] = "MapMarkerNew7", [19184] = "MapMarkerNew8", [19185] = "MapMarkerNew9", [19186] = "MapMarkerNew10", [19187] = "MapMarkerNew11", 
   [19188] = "MapMarkerNew12", [19189] = "MapMarkerNew13", [19190] = "MapMarkerNew14", [19191] = "MapMarkerNew15", [19192] = "MapMarkerNew16", 
   [19193] = "MapMarkerNew17", [19194] = "MapMarkerNew18", [19195] = "MapMarkerNew19", [19196] = "MapMarkerNew20", [19197] = "EnExMarker2", 
   [19198] = "EnExMarker3", [19199] = "LCObservatory", [19200] = "PoliceHelmet1", [19201] = "MapMarker1", [19202] = "MapMarker2", 
   [19203] = "MapMarker3", [19204] = "MapMarker4", [19205] = "MapMarker5", [19206] = "MapMarker6", [19207] = "MapMarker7", 
   [19208] = "MapMarker8", [19209] = "MapMarker9", [19210] = "MapMarker10", [19211] = "MapMarker11", [19212] = "MapMarker12", 
   [19213] = "MapMarker13", [19214] = "MapMarker14", [19215] = "MapMarker15", [19216] = "MapMarker16", [19217] = "MapMarker17", 
   [19218] = "MapMarker18", [19219] = "MapMarker19", [19220] = "MapMarker20", [19221] = "MapMarker21", [19222] = "MapMarker22", 
   [19223] = "MapMarker23", [19224] = "MapMarker24", [19225] = "MapMarker25", [19226] = "MapMarker26", [19227] = "MapMarker27", 
   [19228] = "MapMarker28", [19229] = "MapMarker29", [19230] = "MapMarker30", [19231] = "MapMarker31", [19232] = "MapMarker32", 
   [19233] = "MapMarker33", [19234] = "MapMarker34", [19235] = "MapMarker35", [19236] = "MapMarker36", [19237] = "MapMarker37", 
   [19238] = "MapMarker38", [19239] = "MapMarker39", [19240] = "MapMarker40", [19241] = "MapMarker41", [19242] = "MapMarker42", 
   [19243] = "MapMarker43", [19244] = "MapMarker44", [19245] = "MapMarker45", [19246] = "MapMarker46", [19247] = "MapMarker47", 
   [19248] = "MapMarker48", [19249] = "MapMarker49", [19250] = "MapMarker50", [19251] = "MapMarker51", [19252] = "MapMarker52", 
   [19253] = "MapMarker53", [19254] = "MapMarker54", [19255] = "MapMarker55", [19256] = "MapMarker56", [19257] = "MapMarker57", 
   [19258] = "MapMarker58", [19259] = "MapMarker59", [19260] = "MapMarker60", [19261] = "MapMarker61", [19262] = "MapMarker62", 
   [19263] = "MapMarker63", [19264] = "MapMarker1a", [19265] = "MapMarker1b", [19266] = "MapMarker31a", [19267] = "MapMarker31b", 
   [19268] = "MapMarker31c", [19269] = "MapMarker31d", [19270] = "MapMarkerFire1", [19271] = "MapMarkerLight1", [19272] = "DMCage3", 
   [19273] = "KeypadNonDynamic", [19274] = "Hair5", [19275] = "SAMPLogo2", [19276] = "SAMPLogo3", [19277] = "LiftType1", 
   [19278] = "LiftPlatform1", [19279] = "LCSmallLight1", [19280] = "CarRoofLight1", [19281] = "PointLight1", [19282] = "PointLight2", 
   [19283] = "PointLight3", [19284] = "PointLight4", [19285] = "PointLight5", [19286] = "PointLight6", [19287] = "PointLight7", 
   [19288] = "PointLight8", [19289] = "PointLight9", [19290] = "PointLight10", [19291] = "PointLight11", [19292] = "PointLight12", 
   [19293] = "PointLight13", [19294] = "PointLight14", [19295] = "PointLight15", [19296] = "PointLight16", [19297] = "PointLight17", 
   [19298] = "PointLight18", [19299] = "PointLightMoon1", [19300] = "blankmodel", [19300] = "bridge_liftsec", [19301] = "mp_sfpd_nocell", 
   [19301] = "subbridge01", [19302] = "pd_jail_door01", [19302] = "subbridge07", [19303] = "pd_jail_door02", [19303] = "subbridge19", 
   [19304] = "pd_jail_door_top01", [19304] = "subbridge20", [19305] = "sec_keypad2", [19305] = "subbridge_lift", [19306] = "kmb_goflag2", 
   [19306] = "verticalift_bridg2", [19307] = "kmb_goflag3", [19307] = "verticalift_bridge", [19308] = "taxi01", [19309] = "taxi02", 
   [19310] = "taxi03", [19311] = "taxi04", [19312] = "a51fencing", [19313] = "a51fensin", [19314] = "bullhorns01", 
   [19315] = "deer01", [19316] = "FerrisCageBit01", [19317] = "bassguitar01", [19318] = "flyingv01", [19319] = "warlock01", 
   [19320] = "pumpkin01", [19321] = "cuntainer", [19322] = "mallb_laW02", [19323] = "lsmall_shop01", [19324] = "kmb_atm1_2", 
   [19325] = "lsmall_window01", [19326] = "7_11_sign01", [19327] = "7_11_sign02", [19328] = "7_11_sign03", [19329] = "7_11_sign04", 
   [19330] = "fire_hat01", [19331] = "fire_hat02", [19332] = "Hot_Air_Balloon01", [19333] = "Hot_Air_Balloon02", [19334] = "Hot_Air_Balloon03", 
   [19335] = "Hot_Air_Balloon04", [19336] = "Hot_Air_Balloon05", [19337] = "Hot_Air_Balloon06", [19338] = "Hot_Air_Balloon07", [19339] = "coffin01", 
   [19340] = "cslab01", [19341] = "easter_egg01", [19342] = "easter_egg02", [19343] = "easter_egg03", [19344] = "easter_egg04", 
   [19345] = "easter_egg05", [19346] = "hotdog01", [19347] = "badge01", [19348] = "cane01", [19349] = "monocle01", 
   [19350] = "moustache01", [19351] = "moustache02", [19352] = "tophat01", [19353] = "wall001", [19354] = "wall002", 
   [19355] = "wall003", [19356] = "wall004", [19357] = "wall005", [19358] = "wall006", [19359] = "wall007", 
   [19360] = "wall008", [19361] = "wall009", [19362] = "wall010", [19363] = "wall011", [19364] = "wall012", 
   [19365] = "wall013", [19366] = "wall014", [19367] = "wall015", [19368] = "wall016", [19369] = "wall017", 
   [19370] = "wall018", [19371] = "wall019", [19372] = "wall020", [19373] = "wall021", [19374] = "wall022", 
   [19375] = "wall023", [19376] = "wall024", [19377] = "wall025", [19378] = "wall026", [19379] = "wall027", 
   [19380] = "wall028", [19381] = "wall029", [19382] = "wall030", [19383] = "wall031", [19384] = "wall032", 
   [19385] = "wall033", [19386] = "wall034", [19387] = "wall035", [19388] = "wall036", [19389] = "wall037", 
   [19390] = "wall038", [19391] = "wall039", [19392] = "wall040", [19393] = "wall041", [19394] = "wall042", 
   [19395] = "wall043", [19396] = "wall044", [19397] = "wall045", [19398] = "wall046", [19399] = "wall047", 
   [19400] = "wall048", [19401] = "wall049", [19402] = "wall050", [19403] = "wall051", [19404] = "wall052", 
   [19405] = "wall053", [19406] = "wall054", [19407] = "wall055", [19408] = "wall056", [19409] = "wall057", 
   [19410] = "wall058", [19411] = "wall059", [19412] = "wall060", [19413] = "wall061", [19414] = "wall062", 
   [19415] = "wall063", [19416] = "wall064", [19417] = "wall065", [19418] = "handcuffs01", [19419] = "police_lights01", 
   [19420] = "police_lights02", [19421] = "headphones01", [19422] = "headphones02", [19423] = "headphones03", [19424] = "headphones04", 
   [19425] = "speed_bump01", [19426] = "wall066", [19427] = "wall067", [19428] = "wall068", [19429] = "wall069", 
   [19430] = "wall070", [19431] = "wall071", [19432] = "wall072", [19433] = "wall073", [19434] = "wall074", 
   [19435] = "wall075", [19436] = "wall076", [19437] = "wall077", [19438] = "wall078", [19439] = "wall079", 
   [19440] = "wall080", [19441] = "wall081", [19442] = "wall082", [19443] = "wall083", [19444] = "wall084", 
   [19445] = "wall085", [19446] = "wall086", [19447] = "wall087", [19448] = "wall088", [19449] = "wall089", 
   [19450] = "wall090", [19451] = "wall091", [19452] = "wall092", [19453] = "wall093", [19454] = "wall094", 
   [19455] = "wall095", [19456] = "wall096", [19457] = "wall097", [19458] = "wall098", [19459] = "wall099", 
   [19460] = "wall100", [19461] = "wall101", [19462] = "wall102", [19463] = "wall103", [19464] = "wall104", 
   [19465] = "wall105", [19466] = "window001", [19467] = "vehicle_barrier01", [19468] = "bucket01", [19469] = "scarf01", 
   [19470] = "forsale01", [19471] = "forsale02", [19472] = "gasmask01", [19473] = "grassplant01", [19474] = "pokertable01", 
   [19475] = "Plane001", [19476] = "Plane002", [19477] = "Plane003", [19478] = "Plane004", [19479] = "Plane005", 
   [19480] = "Plane006", [19481] = "Plane007", [19482] = "Plane008", [19483] = "Plane009", [19484] = "landbit01_01", 
   [19485] = "Groundbit84_SFS_01", [19486] = "burg_SFS_01", [19486] = "SFHarryPlums1", [19487] = "tophat02", [19488] = "HatBowler6", 
   [19489] = "sfhouse1", [19490] = "sfhouse1int", [19491] = "sfhouse2", [19492] = "sfhouse2int", [19493] = "sfhouse3", 
   [19494] = "sfhouse3int", [19495] = "sfhouse4", [19496] = "sfhouse4int", [19497] = "lvhouse1", [19498] = "lvhouse1int", 
   [19499] = "lvhouse2", [19500] = "lvhouse2int", [19501] = "lvhouse3", [19502] = "lvhouse3int", [19503] = "lvhouse4", 
   [19504] = "lvhouse4int", [19505] = "lshouse1", [19506] = "lshouse1int", [19507] = "lshouse2", [19508] = "lshouse2int", 
   [19509] = "lshouse3", [19510] = "lshouse3int", [19511] = "lshouse4", [19512] = "lshouse4int", [19513] = "whitephone", 
   [19514] = "SWATHgrey", [19515] = "SWATAgrey", [19516] = "Hair2_nc", [19517] = "Hair3_nc", [19518] = "Hair5_nc", 
   [19519] = "Hair1_nc", [19520] = "pilotHat01", [19521] = "policeHat01", [19522] = "property_red", [19523] = "property_orange", 
   [19524] = "property_yellow", [19525] = "WeddingCake1", [19526] = "ATMFixed", [19527] = "Cauldron1", [19528] = "WitchesHat1", 
   [19529] = "Plane125x125Grass1", [19530] = "Plane125x125Sand1", [19531] = "Plane125x125Conc1", [19532] = "15x125Road1", [19533] = "15x62_5Road1", 
   [19534] = "15x15RoadInters1", [19535] = "15x15RoadInters2", [19536] = "Plane62_5x125Grass1", [19537] = "Plane62_5x125Sand1", [19538] = "Plane62_5x125Conc1", 
   [19539] = "Edge62_5x62_5Grass1", [19540] = "Edge62_5x62_5Grass2", [19541] = "Edge62_5x15Grass1", [19542] = "Edge62_5x125Grass1", [19543] = "Plane62_5x15Grass1", 
   [19544] = "Plane62_5x15Sand1", [19545] = "Plane62_5x15Conc1", [19546] = "Edge62_5x62_5Grass3", [19547] = "Hill125x125Grass1", [19548] = "Hill125x125Sand1", 
   [19549] = "Edge62_5x32_5Grass1", [19550] = "Plane125x125Grass2", [19551] = "Plane125x125Sand2", [19552] = "Plane125x125Conc2", [19553] = "StrawHat1", 
   [19554] = "Beanie1", [19555] = "BoxingGloveL", [19556] = "BoxingGloveR", [19557] = "SexyMask1", [19558] = "PizzaHat1", 
   [19559] = "HikerBackpack1", [19560] = "MeatTray1", [19561] = "CerealBox1", [19562] = "CerealBox2", [19563] = "JuiceBox1", 
   [19564] = "JuiceBox2", [19565] = "IceCreamBarsBox1", [19566] = "FishFingersBox1", [19567] = "IcecreamContainer1", [19568] = "IcecreamContainer2", 
   [19569] = "MilkCarton1", [19570] = "MilkBottle1", [19571] = "PizzaBox1", [19572] = "PisshBox1", [19573] = "BriquettesBag1", 
   [19574] = "Orange1", [19575] = "Apple1", [19576] = "Apple2", [19577] = "Tomato1", [19578] = "Banana1", 
   [19579] = "BreadLoaf1", [19580] = "Pizza1", [19581] = "MarcosFryingPan1", [19582] = "MarcosSteak1", [19583] = "MarcosKnife1", 
   [19584] = "MarcosSaucepan1", [19585] = "MarcosPan1", [19586] = "MarcosSpatula1", [19587] = "PlasticTray1", [19588] = "FootBridge1", 
   [19589] = "RubbishSkipEmpty1", [19590] = "WooziesSword1", [19591] = "WooziesHandFan1", [19592] = "ShopBasket1", [19593] = "ZomboTechBuilding1", 
   [19594] = "ZomboTechLab1", [19595] = "LSAppartments1", [19597] = "LSBeachSideInsides", [19598] = "SFBuilding1Outside", [19599] = "SFBuilding1Inside", 
   [19600] = "SFBuilding1Land", [19601] = "SnowPlow1", [19602] = "Landmine1", [19603] = "WaterPlane1", [19604] = "WaterPlane2", 
   [19605] = "EnExMarker4-2", [19606] = "EnExMarker4-3", [19607] = "EnExMarker4-4", [19608] = "WoodenStage1", [19609] = "DrumKit1", 
   [19610] = "Microphone1", [19611] = "MicrophoneStand1", [19612] = "GuitarAmp1", [19613] = "GuitarAmp2", [19614] = "GuitarAmp3", 
   [19615] = "GuitarAmp4", [19616] = "GuitarAmp5", [19617] = "GoldRecord1", [19618] = "Safe1", [19619] = "SafeDoor1", 
   [19620] = "LightBar1", [19621] = "OilCan1", [19622] = "Broom1", [19623] = "Camera1", [19624] = "Case1", 
   [19625] = "Ciggy1", [19626] = "Spade1", [19627] = "Wrench1", [19628] = "MRoadBend90Banked1", [19629] = "MRoadBend90Banked2", 
   [19630] = "Fish1", [19631] = "SledgeHammer1", [19632] = "FireWood1", [19633] = "Ramp360Degree1", [19634] = "Ramp360Degree2", 
   [19635] = "Ramp360Degree3", [19636] = "RedApplesCrate1", [19637] = "GreenApplesCrate1", [19638] = "OrangesCrate1", [19639] = "EmptyCrate1", 
   [19640] = "EmptyShopShelf1", [19641] = "FenceSection1", [19642] = "TubeSeg10m1", [19643] = "TubeSeg10m2a", [19644] = "TubeSeg10m2b", 
   [19645] = "TubeSeg25m1", [19646] = "TubeHalf10m1", [19647] = "TubeHalf10mJoin1a", [19648] = "TubeHalf10mJoin1b", [19649] = "TubeHalf50m1", 
   [19650] = "TubeFlat25x25m1", [19651] = "TubeHalfSpiral1a", [19652] = "TubeHalfSpiral1b", [19653] = "TubeHalfSpiral2a", [19654] = "TubeHalfSpiral2b", 
   [19655] = "TubeHalfSpiral3a", [19656] = "TubeHalfSpiral3b", [19657] = "TubeHalfSpiral4a", [19658] = "TubeHalfSpiral4b", [19659] = "TubeHalf180Bend1a", 
   [19660] = "TubeHalf180Bend1b", [19661] = "TubeHalf90Bend1a", [19662] = "TubeHalf90Bend1b", [19663] = "TubeHalf50mDip1", [19664] = "TubeHalf50mBump1", 
   [19665] = "TubeHalfLoop1a", [19666] = "TubeHalfLoop1b", [19667] = "TubeHalfLoop2a", [19668] = "TubeHalfLoop2b", [19669] = "TubeHalfBowl1", 
   [19670] = "TubeSupport1", [19671] = "TubeSupport2", [19672] = "TubeHalfLight1", [19673] = "TubeHalf5Bend1a", [19674] = "TubeHalf5Bend1b", 
   [19675] = "TubeHalf5Bend2a", [19676] = "TubeHalf5Bend2b", [19677] = "TubeHalfTwist1a", [19678] = "alaman1", [19678] = "TubeHalfTwist1b", 
   [19679] = "TubeHalfTwist2a", [19680] = "TubeHalfTwist2b", [19681] = "TubeHalf45Bend1a", [19682] = "TubeHalf45Bend1b", [19683] = "TubeHalf15Bend1a", 
   [19684] = "TubeHalf15Bend1b", [19685] = "TubeHalf15Bend2a", [19686] = "TubeHalf15Bend2b", [19687] = "TubeHalf25m1", [19688] = "TubeHalf45Bend3", 
   [19689] = "TubeHalf45Bend4", [19690] = "TubeHalfNtoMJoin1a", [19691] = "TubeHalfNtoMJoin1b", [19692] = "MTubeSeg5m1", [19693] = "MTubeSeg5m2a", 
   [19694] = "MTubeSeg5m2b", [19695] = "MTubeSeg12_5m1", [19696] = "MTubeHalf10m1", [19697] = "MTubeHalf5mJoin1a", [19698] = "MTubeHalf5mJoin1b", 
   [19699] = "MTubeHalf25m1", [19700] = "MTubeFlt12_5x12_5m1", [19701] = "MTubeHalfSpiral1a", [19702] = "MTubeHalfSpiral1b", [19703] = "MTubeHalfSpiral2a", 
   [19704] = "MTubeHalfSpiral2b", [19705] = "MTubeHalfSpiral3a", [19706] = "MTubeHalfSpiral3b", [19707] = "MTubeHalfSpiral4a", [19708] = "MTubeHalfSpiral4b", 
   [19709] = "MTubeHalf180Bend1a", [19710] = "MTubeHalf180Bend1b", [19711] = "MTubeHalf90Bend1a", [19712] = "MTubeHalf90Bend1b", [19713] = "MTubeHalf25mDip1", 
   [19714] = "MTubeHalf25mBump1", [19715] = "MTubeHalfBowl1", [19716] = "MTubeSupport1", [19717] = "MTubeSupport2", [19718] = "MTubeHalfLight1", 
   [19719] = "MTubeHalf5Bend1a", [19720] = "MTubeHalf5Bend1b", [19721] = "MTubeHalf5Bend2a", [19722] = "MTubeHalf5Bend2b", [19723] = "MTubeHalf45Bend1a", 
   [19724] = "MTubeHalf45Bend1b", [19725] = "MTubeHalf15Bend1a", [19726] = "MTubeHalf15Bend1b", [19727] = "MTubeHalf15Bend2a", [19728] = "MTubeHalf15Bend2b", 
   [19729] = "MTubeHalf45Bend3", [19730] = "MTubeHalf45Bend4", [19731] = "TubeHalfMtoSJoin1a", [19732] = "TubeHalfMtoSJoin1B", [19733] = "STubeSeg5m1", 
   [19734] = "STubeSeg5m2a", [19735] = "STubeSeg5m2b", [19736] = "STubeSeg6_25m1", [19737] = "STubeHalf10m1", [19738] = "STubeHalf5mJoin1a", 
   [19739] = "STubeHalf5mJoin1b", [19740] = "STubeHalf12_5m1", [19741] = "STubeFlat6_25m1", [19742] = "STubeHalfSpiral1a", [19743] = "STubeHalfSpiral1b", 
   [19744] = "STubeHalfSpiral2a", [19745] = "STubeHalfSpiral2b", [19746] = "STubeHalfSpiral3a", [19747] = "STubeHalfSpiral3b", [19748] = "STubeHalfSpiral4a", 
   [19749] = "STubeHalfSpiral4b", [19750] = "STubeHalf180Bend1a", [19751] = "STubeHalf180Bend1b", [19752] = "STubeHalf90Bend1a", [19753] = "STubeHalf90Bend1b", 
   [19754] = "STubeHalf12_5mDip1", [19755] = "STubeHalf12_5mBump1", [19756] = "STubeHalfBowl1", [19757] = "STubeSupport1", [19758] = "STubeSupport2", 
   [19759] = "STubeHalfLight1", [19760] = "STubeHalf5Bend1a", [19761] = "STubeHalf5Bend1b", [19762] = "STubeHalf5Bend2a", [19763] = "STubeHalf5Bend2b", 
   [19764] = "STubeHalf45Bend1a", [19765] = "STubeHalf45Bend1b", [19766] = "STubeHalf15Bend1a", [19767] = "STubeHalf15Bend1b", [19768] = "STubeHalf15Bend2a", 
   [19769] = "STubeHalf15Bend2b", [19770] = "STubeHalf45Bend3", [19771] = "STubeHalf45Bend4", [19772] = "CrushedCarCube1", [19773] = "GunHolster1", 
   [19774] = "PoliceBadge2", [19775] = "PoliceBadge3", [19776] = "FBIIDCard1", [19777] = "FBILogo1", [19778] = "InsigniaDetective1", 
   [19779] = "InsigniaDetective2", [19780] = "InsigniaDetective3", [19781] = "InsigniaSergeant1", [19782] = "InsigniaSergeant2", [19783] = "InsigniaPOfficer2", 
   [19784] = "InsigniaPOfficer3", [19785] = "InsigniaSeniorLdOff", [19786] = "LCDTVBig1", [19787] = "LCDTV1", [19788] = "15x15RoadCorner1", 
   [19789] = "Cube1mx1m", [19790] = "Cube5mx5m", [19791] = "Cube10mx10m", [19792] = "SAMPKeycard1", [19793] = "FireWoodLog1", 
   [19794] = "LSPrisonWalls1", [19795] = "LSPrisonGateEast", [19796] = "LSPrisonGateSouth", [19797] = "PoliceVisorStrobe1", [19798] = "LSACarPark1", 
   [19799] = "CaligulasVaultDoor", [19800] = "LSBCarPark1", [19801] = "Balaclava1", [19802] = "GenDoorINT04Static", [19803] = "TowTruckLights1", 
   [19804] = "Padlock1", [19805] = "Whiteboard1", [19806] = "Chandelier1", [19807] = "Telephone1", [19808] = "Keyboard1", 
   [19809] = "MetalTray1", [19810] = "StaffOnlySign1", [19811] = "BurgerBox1", [19812] = "BeerKeg1", [19813] = "ElectricalOutlet1", 
   [19814] = "ElectricalOutlet2", [19815] = "ToolBoard1", [19816] = "OxygenCylinder1", [19817] = "CarFixerRamp1", [19818] = "WineGlass1", 
   [19819] = "CocktailGlass1", [19820] = "AlcoholBottle1", [19821] = "AlcoholBottle2", [19822] = "AlcoholBottle3", [19823] = "AlcoholBottle4", 
   [19824] = "AlcoholBottle5", [19825] = "SprunkClock1", [19826] = "LightSwitch1", [19827] = "LightSwitch2", [19828] = "LightSwitch3Off", 
   [19829] = "LightSwitch3On", [19830] = "Blender1", [19831] = "Barbeque1", [19832] = "AmmoBox1", [19833] = "Cow1", 
   [19834] = "PoliceLineTape1", [19835] = "CoffeeCup1", [19836] = "BloodPool1", [19837] = "GrassClump1", [19838] = "GrassClump2", 
   [19839] = "GrassClump3", [19840] = "WaterFall1", [19841] = "WaterFall2", [19842] = "WaterFallWater1", [19843] = "MetalPanel1", 
   [19844] = "MetalPanel2", [19845] = "MetalPanel3", [19846] = "MetalPanel4", [19847] = "LegHam1", [19848] = "CargoBobPlatform1", 
   [19849] = "MIHouse1Land", [19850] = "MIHouse1Land2", [19851] = "MIHouse1Land3", [19852] = "MIHouse1Land4", [19853] = "MIHouse1Land5", 
   [19854] = "MIHouse1Outside", [19855] = "MIHouse1Inside", [19856] = "MIHouse1IntWalls1", [19857] = "MIHouse1Door1", [19858] = "MIHouse1Door2", 
   [19859] = "MIHouse1Door3", [19860] = "MIHouse1Door4", [19861] = "MIHouse1GarageDoor1", [19862] = "MIHouse1GarageDoor2", [19863] = "MIHouse1GarageDoor3", 
   [19864] = "MIHouse1GarageDoor4", [19865] = "MIFenceWood1", [19866] = "MIFenceBlocks1", [19867] = "MailBox1", [19868] = "MeshFence1", 
   [19869] = "MeshFence2", [19870] = "MetalGate1", [19871] = "CordonStand1", [19872] = "CarFixerRamp2", [19873] = "ToiletPaperRoll1", 
   [19874] = "SoapBar1", [19875] = "CRDoor01New", [19876] = "DillimoreGasExt1", [19877] = "DillimoreGasInt1", [19878] = "Skateboard1", 
   [19879] = "WellsFargoBuild1", [19880] = "WellsFargoGrgDoor1", [19881] = "KylieBarnFixed1", [19882] = "MarcosSteak2", [19883] = "BreadSlice1", 
   [19884] = "WSBend45Deg2", [19885] = "WSStraight2", [19886] = "WSStraight3", [19887] = "WSStart1", [19888] = "WSBend45Deg3", 
   [19889] = "WSBend45Deg4", [19890] = "WSStraight4", [19891] = "WSTubeJoiner1", [19892] = "WSRoadJoiner1", [19893] = "LaptopSAMP1", 
   [19894] = "LaptopSAMP2", [19895] = "LadderFireTruckLts1", [19896] = "CigarettePack1", [19897] = "CigarettePack2", [19898] = "OilFloorStain1", 
   [19899] = "ToolCabinet1", [19900] = "ToolCabinet2", [19901] = "AnimTube", [19902] = "EnExMarker4", [19903] = "MechanicComputer1", 
   [19904] = "ConstructionVest1", [19905] = "A51Building1", [19906] = "A51Building1GrgDoor", [19907] = "A51Building2", [19908] = "A51Building2GrgDoor", 
   [19909] = "A51Building3", [19910] = "A51Building3GrgDoor", [19911] = "A51HangarDoor1", [19912] = "SAMPMetalGate1", [19913] = "SAMPBigFence1", 
   [19914] = "CutsceneBat1", [19915] = "CutsceneCooker1", [19916] = "CutsceneFridge1", [19917] = "CutsceneEngine1", [19918] = "CutsceneBox1", 
   [19919] = "CutscenePerch1", [19920] = "CutsceneRemote1", [19921] = "CutsceneToolBox1", [19922] = "MKTable1", [19923] = "MKIslandCooker1", 
   [19924] = "MKExtractionHood1", [19925] = "MKWorkTop1", [19926] = "MKWorkTop2", [19927] = "MKWorkTop3", [19928] = "MKWorkTop4", 
   [19929] = "MKWorkTop5", [19930] = "MKWorkTop6", [19931] = "MKWorkTop7", [19932] = "MKWallOvenCabinet1", [19933] = "MKWallOven1", 
   [19934] = "MKCupboard1", [19935] = "MKCupboard2", [19936] = "MKCupboard3", [19937] = "MKCupboard4", [19938] = "MKShelf1", 
   [19939] = "MKShelf2", [19940] = "MKShelf3", [19941] = "GoldBar1", [19942] = "PoliceRadio1", [19943] = "StonePillar1", 
   [19944] = "BodyBag1", [19945] = "CPSize16Red", [19946] = "CPSize16Green", [19947] = "CPSize16Blue", [19948] = "SAMPRoadSign1", 
   [19949] = "SAMPRoadSign2", [19950] = "SAMPRoadSign3", [19951] = "SAMPRoadSign4", [19952] = "SAMPRoadSign5", [19953] = "SAMPRoadSign6", 
   [19954] = "SAMPRoadSign7", [19955] = "SAMPRoadSign8", [19956] = "SAMPRoadSign9", [19957] = "SAMPRoadSign10", [19958] = "SAMPRoadSign11", 
   [19959] = "SAMPRoadSign12", [19960] = "SAMPRoadSign13", [19961] = "SAMPRoadSign14", [19962] = "SAMPRoadSign15", [19963] = "SAMPRoadSign16", 
   [19964] = "SAMPRoadSign17", [19965] = "SAMPRoadSign18", [19966] = "SAMPRoadSign19", [19967] = "SAMPRoadSign20", [19968] = "SAMPRoadSign21", 
   [19969] = "SAMPRoadSign22", [19970] = "SAMPRoadSign23", [19971] = "SAMPRoadSign24", [19972] = "SAMPRoadSign25", [19973] = "SAMPRoadSign26", 
   [19974] = "SAMPRoadSign27", [19975] = "SAMPRoadSign28", [19976] = "SAMPRoadSign29", [19977] = "SAMPRoadSign30", [19978] = "SAMPRoadSign31", 
   [19979] = "SAMPRoadSign32", [19980] = "SAMPRoadSign33", [19981] = "SAMPRoadSign34", [19982] = "SAMPRoadSign35", [19983] = "SAMPRoadSign36", 
   [19984] = "SAMPRoadSign37", [19985] = "SAMPRoadSign38", [19986] = "SAMPRoadSign39", [19987] = "SAMPRoadSign40", [19988] = "SAMPRoadSign41", 
   [19989] = "SAMPRoadSign42", [19990] = "SAMPRoadSign43", [19991] = "SAMPRoadSign44", [19992] = "SAMPRoadSign45", [19993] = "CutsceneBowl1", 
   [19994] = "CutsceneChair1", [19995] = "CutsceneAmmoClip1", [19996] = "CutsceneFoldChair1", [19997] = "CutsceneGrgTable1", [19998] = "CutsceneLighterFl", 
   [19999] = "CutsceneChair2", [0] = "N/A"
}

function main()
   if not isSampLoaded() or not isSampfuncsLoaded() then return end
      while not isSampAvailable() do wait(100) end
 
      sampAddChatMessage("{880000}Absolute Events Helper.\
	  {FFFFFF}Открыть меню: {CDCDCD}ALT + X", 0xFFFFFF)
      
	  reloadBindsFromConfig()

      if string.len(textbuffer.mpname.v) < 1 then
         textbuffer.mpname.v = u8('Заходите на МП ')
      end
      if string.len(textbuffer.rule1.v) < 1 then
         textbuffer.rule1.v = u8("Введите свои правила для мероприятия сюда")
      end
      
      -- ENB check
      if doesFileExist(getGameDirectory() .. "\\enbseries.asi") or 
      doesFileExist(getGameDirectory() .. "\\d3d9.dll") then
         ENBSeries = true
      end
      
	  -- simple SAMP Addon check
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
      
      sampRegisterChatCommand("abs", function() dialog.main.v = not dialog.main.v end)
	  
      -- set drawdist and figdist
      memory.setfloat(12044272, ini.settings.drawdist, true)
      memory.setfloat(13210352, ini.settings.fog, true)
	
      textbuffer.mpprize.v = '1.000.000$'
      --textbuffer.mpname.v = u8'Проходит МП "<название>" '
     
      --- END init
      while true do
      wait(0)
      
      -- sampGetCurrentServerName() returns a value with a long delay
      -- unlike receiving the IP and port. Therefore, for correct operation, the code is placed here      
      local servername = sampGetCurrentServerName()
      
      if servername:find("TRAINING") then
         isTraining = true
      end
      if servername:find("Absolute") then
         isAbsolutePlay = true
      end
      if servername:find("Абсолют") then
         isAbsolutePlay = true
      end
      
      -- Imgui menu
      if not ENBSeries then imgui.Process = dialog.main.v end
      
      -- chatfix
      if isTraining then
         if isKeyJustPressed(0x54) and not sampIsDialogActive() 
         and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
            sampSetChatInputEnabled(true)
         end
      end
      
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
      if isKeyJustPressed(0x1B) and not sampIsChatInputActive() 
      and not sampIsDialogActive() and not isPauseMenuActive() 
      and not isSampfuncsConsoleActive() then 
         if dialog.main.v then dialog.main.v = false end
         if dialog.fastanswer.v then dialog.fastanswer.v = false end
         if dialog.textures.v then dialog.textures.v = false end
         if dialog.playerstat.v then dialog.playerstat.v = false end
         if dialog.vehstat.v then dialog.vehstat.v = false end
         if dialog.extendedtab.v then dialog.extendedtab.v = false end
         if dialog.objectinfo.v then dialog.objectinfo.v = false end
      end 
      
      -- ALT+X (Main menu activation)
      if isKeyDown(0x12) and isKeyJustPressed(0x58) 
	  and not sampIsChatInputActive() and not sampIsDialogActive()
	  and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
         dialog.main.v = not dialog.main.v 
      end
      
      if ini.settings.hotkeys then
	     -- In onSendEditObject copy object modelid on RMB
	     if isKeyJustPressed(0x02) and editResponse == 2 and not sampIsChatInputActive() 
         and not sampIsDialogActive() and not isPauseMenuActive() 
         and not isSampfuncsConsoleActive() then 
	        setClipboardText(LastObjectData.modelid)
	 	    sampAddChatMessage("modelid скопирован в буфер обмена", -1)
	     end
	     
	     -- hide edited object on hold ALT key
         if isKeyDown(0x12) and editResponse > 0 and not sampIsChatInputActive() 
         and not sampIsDialogActive() and not isPauseMenuActive() 
         and not isSampfuncsConsoleActive() then
	        hideEditObject = true
	     else
	 	    hideEditObject = false
	     end
	     
	     -- upscale edited object on hold CTRL key
	     if isKeyDown(0x11) and editResponse > 0 and not sampIsChatInputActive() 
         and not sampIsDialogActive() and not isPauseMenuActive() 
         and not isSampfuncsConsoleActive() then
	        scaleEditObject = true
	     else
	 	    scaleEditObject = false
	     end
	     
         if isTraining and isCharInAnyCar(PLAYER_PED) then
            -- bind car lock/unlock on L key
	        if isKeyJustPressed(0x4C) and not sampIsChatInputActive() 
            and not sampIsDialogActive() and not isPauseMenuActive() 
            and not isSampfuncsConsoleActive() then 
               sampSendChat("/lock")
            end
            
            -- Fix exit from RC toys on F key
            if isKeyJustPressed(0x46) and not sampIsChatInputActive() 
            and not sampIsDialogActive() and not isPauseMenuActive() 
            and not isSampfuncsConsoleActive() then
               local carhandle = storeCarCharIsInNoSave(PLAYER_PED) 
               if carhandle then
                  local vehmodel = getCarModel(carhandle) 
                  if vehmodel == 441 or vehmodel == 594
                  or vehmodel == 464 or vehmodel == 465
                  or vehmodel == 501 or vehmodel == 564
                  then
                     sampSendChat("/slapme")
                  end
               end
            end
         end
	     -- if isKeyJustPressed(0x4E) and not sampIsChatInputActive() 
         -- and not sampIsDialogActive() and not isPauseMenuActive() 
         -- and not isSampfuncsConsoleActive() then 
	        -- if LastObjectData.handle then
	 	      -- local result, positionX, positionY, positionZ = getObjectCoordinates(LastObjectData.handle)
	           -- sampSendEditObject(false, LastObjectData.handle, 1, positionX, positionY, positionZ, 0.0, 0.0, 0,0)
	 	   -- end	
	     --end
         
         -- CTRL+O (Objects render activation)
         if isKeyDown(0x11) and isKeyJustPressed(0x4F)
	     and not sampIsChatInputActive() and not isPauseMenuActive()
	     and not isSampfuncsConsoleActive() then 
            checkbox.showobjects.v= not checkbox.showobjects.v
         end
         
	     if not isAbsfixInstalled then
	        -- Switching textdraws with arrow buttons, mouse buttons, pgup-pgdown keys
	        if isKeyJustPressed(0x25) or isKeyJustPressed(0x05) 
	 	    or isKeyJustPressed(0x21) and sampIsCursorActive() 
	 	    and not sampIsChatInputActive() and not sampIsDialogActive() 
	 	    and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
	 	       sampSendClickTextdraw(36)
	 	    end
            
	        if isKeyJustPressed(0x27) or isKeyJustPressed(0x05) 
	 	    or isKeyJustPressed(0x22) and sampIsCursorActive()
	 	    and not sampIsChatInputActive() and not sampIsDialogActive()
	 	    and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
	 	       sampSendClickTextdraw(37)
	 	    end
	     end
	     
         if isTraining then
            -- M key menu /vw and /world 
            if isKeyJustPressed(0x4D) and not sampIsChatInputActive() and not sampIsDialogActive()
	 	    and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
               if isWorldHoster then 
                  sampSendChat("/vw")
               else 
                  sampSendChat("/world")
               end   
            end
            
            -- N key edit object
            if isKeyJustPressed(0x4E) and not sampIsChatInputActive() and not sampIsDialogActive()
	 	    and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
               if isWorldHoster then sampSendChat("/csel") end
            end
         end
         
         if isKeyJustPressed(0x4B) and not sampIsChatInputActive() and not sampIsDialogActive()
	     and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
            isTexturesListOpened = false
            isSanpObjectsListOpened = false
         end
         
         -- Select texture on F key
         if isKeyJustPressed(0x66) and isTexturesListOpened and not sampIsChatInputActive() and not sampIsDialogActive()
	     and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
            if lastClickedTextdrawId == 2099 then
               sampSendClickTextdraw(37)
               lastClickedTextdrawId = 2053
            else
               sampSendClickTextdraw(lastClickedTextdrawId)
               lastClickedTextdrawId = lastClickedTextdrawId + 2
            end
         end
      end
      
	  -- Count streamed obkects
	  if countobjects then
	     streamedObjects = 0
	     for _, v in pairs(getAllObjects()) do
		    if isObjectOnScreen(v) then
			   streamedObjects = streamedObjects + 2
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
	  
      if checkbox.freezechat.v then
         local visible = sampIsChatInputActive()
         if isChatFreezed ~= visible then
		    isChatFreezed = visible
            if not isChatFreezed then
               for k, v in ipairs(chatbuffer) do
                  local color = string.format('%X', v.color)
                  sampAddChatMessage(v.text, tonumber('0x' .. string.sub(color, #color - 8, #color - 2)))
               end
            chatbuffer = {}
            end
         end
      end
      
      -- Render bottom bar
      if ini.settings.showbackgroundbar then
         local x, y = getScreenResolution()
         renderDrawBoxWithBorder(-2, y-15, x+2, y, 0xBF000000, 2, 0xFF000000)
         local px, py, pz = getCharCoordinates(PLAYER_PED)
         
         local rendertext = string.format("%s | {3f70d6}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f{FFFFFF} | {FFD700}mode: %s {FFFFFF}| FPS: %i | streamed: %i ", 
         servername, px, py, pz, editmodes[editMode+1], fps, streamedObjects)
         
         -- if LastObjectData.localid then
            -- string.format(" | objectid: %i modelid: %i", LastObjectData.localid, LastObjectData.modelid)
         -- end
         
         renderFontDrawText(backgroundfont, rendertext, 15, y-15, 0xFFFFFFFF)
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
      if imgui.Button(u8"Мероприятие") then tabmenu.main = 4 end
      imgui.SameLine()
      if imgui.Button(u8"Зона стрима") then tabmenu.main = 2 end
      imgui.SameLine()
      if imgui.Button(u8"Информация") then tabmenu.main = 3 end

      imgui.NextColumn()
      
      imgui.SameLine()
      imgui.Text("                       ")
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
         tabmenu.main = 3
         tabmenu.info = 1
      end
      imgui.Columns(1)

      -- (Change main window size here)
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
               sampAddChatMessage("Позиция скопирована в буфер обмена", -1)
            end
			
		    if tpcpos.x then
			   if tpcpos.x ~= 0 then
                  imgui.TextColoredRGB(string.format("Сохраненая позиция x: %.1f, y: %.1f, z: %.1f",
                  tpcpos.x, tpcpos.y, tpcpos.z))
	              if imgui.IsItemClicked() then
                    setClipboardText(string.format(u8"%.1f, %.1f, %.1f", tpcpos.x, tpcpos.y, tpcpos.z))
                    sampAddChatMessage("Позиция скопирована в буфер обмена", -1)
                  end
                  
                  imgui.SameLine()
                  imgui.TextColoredRGB(string.format("dist. %.1f m.",
                  getDistanceBetweenCoords3d(positionX, positionY, positionZ, tpcpos.x, tpcpos.y, tpcpos.z)))
			   end
			end
			
            if worldspawnpos.x then
			   if worldspawnpos.x ~= 0 then
                  imgui.TextColoredRGB(string.format("Позиция спавна в мире x: %.1f, y: %.1f, z: %.1f",
                  worldspawnpos.x, worldspawnpos.y, worldspawnpos.z))
	              if imgui.IsItemClicked() then
                    setClipboardText(string.format(u8"%.1f, %.1f, %.1f", worldspawnpos.x, worldspawnpos.y, worldspawnpos.z))
                    sampAddChatMessage("Позиция скопирована в буфер обмена", -1)
                  end
			   end
			end
            
		    local bTargetResult, bX, bY, bZ = getTargetBlipCoordinates()
		    if bTargetResult then
		       imgui.Text(string.format(u8"Позиция метки на карте x: %.1f, y: %.1f, z: %.1f",
               bX, bY, bZ))
			   if imgui.IsItemClicked() then
			      setClipboardText(string.format(u8"%.1f, %.1f, %.1f", bX, bY, bZ))
				  sampAddChatMessage("Позиция скопирована в буфер обмена", -1)
			   end
		    
               imgui.SameLine()
		       imgui.Text(string.format(u8"dist. %.1f m.",
               getDistanceBetweenCoords3d(positionX, positionY, positionZ, bX, bY, bZ)))
		    end 
			
			zone = getZoneName(positionX, positionY, positionZ)
			if zone then 
			   imgui.TextColoredRGB(string.format("Район: {696969}%s", zone))
			   if lastWorldNumber > 0 then
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
			
            if positionX > 3000 or positionY > 3000
            or positionX < -3000 or positionY < -3000 then
               imgui.TextColoredRGB("{FF0000}Вы находитесь за предедлами игровой зоны!")
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Нахождение вне игровой зоны, вызывает игровые аномалии (Рассинхронизация транспорта/игроков, отсутствие урона от ближнего боя, аномальное поведение объектов маппинга)")
            end
            
			imgui.Spacing()
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
               if result then
                  local dist = getDistanceBetweenCoords3d(x, y, z, getCharCoordinates(PLAYER_PED))
                  if isAbsolutePlay then
                     if dist < 10.0 then 
			            setCharCoordinates(PLAYER_PED, x, y, z + 3.0)
			            --sampAddChatMessage(("(%i %i %i)"):format(x,y,z), -1)
                        sampAddChatMessage("Вы телепортированы на ближайшую поверхность", -1)
			         else
			            sampAddChatMessage(("Ближайшая поверхность слишком далеко (%d m.)"):format(dist), 0x0FF0000)
			            local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                        setCharCoordinates(PLAYER_PED, posX, posY, posZ+3.0)
			         end
                  else
                     setCharCoordinates(PLAYER_PED, x, y, z + 3.0)
                     sampAddChatMessage("Вы телепортированы на ближайшую поверхность", -1)
                  end
               else
                  sampAddChatMessage("Не нашлось ни одной поверхности рядом", 0x0FF0000)
			      local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                  setCharCoordinates(PLAYER_PED, posX, posY, posZ+3.0)
               end
            end
			
            imgui.Spacing()
            
			if imgui.Checkbox(u8("Включить телепорт на координаты"), checkbox.teleportcoords) then
			   tpcpos.x = positionX
               tpcpos.y = positionY
               tpcpos.z = positionZ
	           textbuffer.tpcx.v = string.format("%.1f", tpcpos.x)
			   textbuffer.tpcy.v = string.format("%.1f", tpcpos.y)
			   textbuffer.tpcz.v = string.format("%.1f", tpcpos.z)
		    end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Активирует телепорт по заданным координатам (доступно только редактору мира)")
		 
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
			         textbuffer.tpcz.v = string.format("%.1f", bZ+2.0)
			      end
			   end
			   
			   if imgui.Button(u8"Телепорт по координатам", imgui.ImVec2(200, 25)) then
			   	  freezeCharPosition(playerPed, false)
                  if textbuffer.tpcx.v then
                     prepareTeleport = true
                     if isAbsolutePlay then
                        sampSendChat(string.format("/ngr %f %f %f", textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), -1)
                        sampAddChatMessage(string.format("Телепорт на координаты: %.1f %.1f %.1f",
                        textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), 0x000FF00)
                     end
                     if isTraining then
                        sampSendChat(string.format("/xyz %f %f %f", textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), -1)
                        sampAddChatMessage(string.format("Телепорт на координаты: %.1f %.1f %.1f",
                        textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), 0x000FF00)
                     end
                  else
                     prepareTeleport = false
                     sampAddChatMessage("Координаты не были сохранены", -1)
				  end  
               end
		    end
            if imgui.Checkbox(u8("Пошаговый телепорт"), checkbox.stepteleport) then
               textbuffer.tpstep.v = "3"
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Активирует пошаговый телепорт по заданным значениям")
            if checkbox.stepteleport.v then
               imgui.Spacing()
               imgui.Text("       ")
               imgui.SameLine()
               if imgui.Button(" ^ ") then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                     setCharCoordinates(PLAYER_PED, posX, posY, posZ+tonumber(textbuffer.tpstep.v))
                  end
               end
               imgui.SameLine()
               imgui.Text("            ")
               imgui.SameLine()
               
               imgui.Text(u8"Шаг: ")
               imgui.SameLine()
               imgui.PushItemWidth(25)
			   if imgui.InputText("##TpStepBuffer", textbuffer.tpstep) then
                  if textbuffer.tpstep.v ~= nil and tonumber(textbuffer.tpstep.v) ~= nil then 
                     if tonumber(textbuffer.tpstep.v) > 10 then
                        textbuffer.tpstep.v = "3" 
                     end
                  end
			   end
			   imgui.PopItemWidth()
               imgui.SameLine()
               imgui.Text("m.")
               
               if imgui.Button(" < ") then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                     setCharCoordinates(PLAYER_PED, posX+tonumber(textbuffer.tpstep.v), posY, posZ)
                  end
               end
               imgui.SameLine()
               if imgui.Button(" o ") then
                  if sampIsLocalPlayerSpawned() then
				     JumpForward()
			      end
               end
               imgui.SameLine()
               if imgui.Button(" > ") then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                     setCharCoordinates(PLAYER_PED, posX, posY+tonumber(textbuffer.tpstep.v), posZ)
                  end
               end
               imgui.SameLine()
               imgui.Text("  ")
               imgui.SameLine()
               if imgui.Checkbox(checkbox.freezepos.v and u8"Позиция: Заморожена" or u8"Позиция: Разморожена", checkbox.freezepos) then
	              if checkbox.freezepos.v and sampIsLocalPlayerSpawned() then
                     freezeCharPosition(PLAYER_PED, true)
                  else
                     freezeCharPosition(PLAYER_PED, false)
	                 setPlayerControl(PLAYER_HANDLE, true)
	                 clearCharTasksImmediately(PLAYER_PED)
                  end
	           end
               imgui.Text("       ")
               imgui.SameLine()
               if imgui.Button(" v ") then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                     setCharCoordinates(PLAYER_PED, posX, posY, posZ-tonumber(textbuffer.tpstep.v))
                  end
               end
               imgui.Spacing()                 
             end
		     imgui.Spacing()
		
	  elseif tabmenu.settings == 2 then
		 
         if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
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
         if LastObjectData.modelid then
            imgui.Text(string.format(u8"Последний modelid объекта: %i", LastObjectData.modelid))
            if imgui.IsItemClicked() then
               setClipboardText(LastObjectData.modelid)
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
		   if LastObjectData.modelid and input.rendselectedmodelid.v == 0 then 
		      input.rendselectedmodelid.v = LastObjectData.modelid
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
		   
		   if LastObjectData.modelid and input.closestobjectmodel.v == 0 then 
		      input.closestobjectmodel.v = LastObjectData.modelid
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
        imgui.TextQuestion("( ? )", u8"Скроет визуально объект по ID модели (modelid). Действует при обновлении зоны стрима")
	   
	    if checkbox.hideobject.v then 
		   if LastObjectData.modelid and input.hideobjectid.v == 615 then 
		      input.hideobjectid.v = LastObjectData.modelid
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
		   
		   if LastObjectData.modelid and input.mdomodel.v == 0 then 
		      input.mdomodel.v = LastObjectData.modelid
		   end
		   
		   imgui.SameLine()
		   if imgui.Button(u8"Применить") then
		      if string.len(input.mdomodel.v) > 0 and string.len(input.mdodist.v) > 0 then
                 memory.setfloat(getMDO(input.mdomodel.v), input.mdodist.v, true)
		      end
		   end
		end
	    
		if imgui.Checkbox(u8("Возвращать объект на исходную позицию"), checkbox.showobjectrot) then
           ini.settings.showobjectrot = checkbox.showobjectrot.v
		   inicfg.save(ini, configIni)
		end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Возвращает объект на исходную позицию при отмене редактирования")
		
        if imgui.Checkbox(u8("Показывать координаты объекта при перемещении"), checkbox.restoreobjectpos) then
           ini.settings.restoreobjectpos = checkbox.restoreobjectpos.v
		   inicfg.save(ini, configIni)
		end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Показывает координаты объекта при перемещении в редакторе карт")
        
        -- if imgui.Checkbox(u8("Показывать все скрытые объекты"), checkbox.showallhiddenobjects) then
		-- end
        -- imgui.SameLine()
        -- imgui.TextQuestion("( ? )", u8"Показывает все скрытые объекты в области стрима")
        
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
           
        imgui.Checkbox(u8("Изменить масштаб объекта"), checkbox.objectscale)
        if checkbox.objectscale.v then
           if LastObjectData.handle then
              if imgui.SliderFloat(u8"##scaleobject", slider.scale, 0.0, 50.0) then
                 setObjectScale(LastObjectData.handle, slider.scale.v)
              end
		   else 
		      imgui.Text(u8"Последний объект не найден")
           end
        end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Визуально изменяет масштаб объекта, и растягивает его. (как в МТА)")
        
		if imgui.Button(u8"ТП к последнему объекту", imgui.ImVec2(250, 25)) then
		   if LastObjectData.modelid and LastObjectData.position.x ~= 0 and doesObjectExist(LastObjectData.handle) then
		      if isAbsolutePlay then
		         sampSendChat(string.format("/ngr %f %f %f",
			     LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z), 0x0FFFFFF)
                 sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..LastObjectData.modelid, -1)
              elseif isTraining then
                 sampSendChat(string.format("/xyz %f %f %f",
			     LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z), 0x0FFFFFF)
                 sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..LastObjectData.modelid, -1)
			  else
                 sampAddChatMessage("Недосутпно для этого сервера!", -1)
			     --setCharCoordinates(PLAYER_PED, LastObjectData.position.x, LastObjectData.position.x, LastObjectData.position.z+0.2)
			  end
		   else
		      sampAddChatMessage("Не найден последний объект", -1)
		   end
		end
		
		if imgui.Button(u8(LastObjectData.blip and "Убрать метку с объекта" or "Метку на последний объект"), imgui.ImVec2(250, 25)) then
		   if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
		       if LastObjectData.blip then
			      removeBlip(LastObjectData.blip)
				  LastObjectData.blip = nil
			   else
		          LastObjectData.blip = addBlipForObject(LastObjectData.handle)
			   end
		   else
		      sampAddChatMessage("Не найден последний объект", -1)
		   end
		end
		
	    if imgui.Button(u8(LastObjectData.hidden and "Скрыть" or "Показать")..u8" последний объект", imgui.ImVec2(250, 25)) then
		   if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
		      if LastObjectData.hidden then
		         setObjectVisible(LastObjectData.handle, false)
				 LastObjectData.hidden = false
			  else
			     setObjectVisible(LastObjectData.handle, true)
				 LastObjectData.hidden = true
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
            sampAddChatMessage("Позиция скопирована в буфер обмена", -1)
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
		 
         -- if imgui.Button("camtest") then
            -- local X, Y, Z = getActiveCameraCoordinates()
            -- local rX, rY, rZ = getActiveCameraPointAt()
            -- sampAddChatMessage(string.format("X:%.1f Y%.1f, Z%.1f, rX%.1f, rY%.1f, rZ%.1f", 
            -- X, Y, Z, rX, rY, rZ), -1)
         -- end
         
		 if imgui.Checkbox(u8("Разблокировать изменение дистанции камеры"), checkbox.usecustomcamdist) then 
		    ini.settings.usecustomcamdist = not ini.settings.usecustomcamdist
            if ini.settings.usecustomcamdist then
		       setCameraDistanceActivated(1)
			   setCameraDistance(ini.settings.camdist)
		    else
	           setCameraDistanceActivated(0)
			   setCameraDistance(0)
		    end
		    inicfg.save(ini, configIni)
	     end
	     imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Разблокирует изменение положения камеры на произвольные значеня")
		 
	  	 if ini.settings.usecustomcamdist then
	        imgui.TextColoredRGB("Дистанция камеры {51484f} (по-умолчанию 1)")
			if imgui.IsItemClicked() then
		       slider.camdist.v = 1
			   ini.settings.camdist = slider.camdist.v
			   inicfg.save(ini, configIni)
		    end
	        if imgui.SliderInt(u8"##camdist", slider.camdist, -100, 250) then
               ini.settings.camdist = slider.camdist.v
               setCameraDistanceActivated(1)		  
		       setCameraDistance(ini.settings.camdist)
               inicfg.save(ini, configIni)
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
            inicfg.save(ini, configIni)
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
            inicfg.save(ini, configIni)
            memory.setfloat(12044272, ini.settings.drawdist, true)
         end
        
         imgui.TextColoredRGB("Дистанция тумана {51484f} (по-умолчанию 200)")
		 if imgui.IsItemClicked() then
		    slider.fog.v = 200
			memory.setfloat(13210352, slider.fog.v, true)
		 end
         if imgui.SliderInt(u8"##fog", slider.fog, -390, 390) then
            ini.settings.fog = slider.fog.v
            inicfg.save(ini, configIni)
            memory.setfloat(13210352, ini.settings.fog, true)
         end
         
         imgui.Spacing()
         imgui.Spacing()
         if imgui.TooltipButton(u8(hide3dtexts and 'Показать' or 'Скрыть')..u8" 3D тексты",
         imgui.ImVec2(200, 25), u8:encode("Скрывает 3d тексты из стрима (для скринов)")) then
            hide3dtexts = not hide3dtexts
		    sampAddChatMessage("Изменения видны после респавна либо обновления зоны стрима", -1)
         end
		 
         if imgui.TooltipButton(u8(nameTag and 'Показать' or 'Скрыть')..u8" NameTags",
         imgui.ImVec2(200, 25), u8:encode("Скрывает никнейм и информацию над игроком (nameTag)")) then
            if nameTag then
               nameTagOff()
            else
               nameTagOn()
            end
         end
		 
         if imgui.TooltipButton(u8"Рестрим", imgui.ImVec2(200, 25),
         u8:encode("Обновить зону стрима путем выхода из зоны стрима, и возврата через 5 сек")) then
            Restream()
		 end
         
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
            inicfg.save(ini, configIni)
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
		 
		 if imgui.Checkbox(u8'NoUnderwater', checkbox.underwater) then
		    if checkbox.underwater.v then
			   DisableUnderWaterEffects(true)
			else
			   DisableUnderWaterEffects(false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отключает все эффекты накладываемые игрой под водой")
         
         if imgui.Checkbox(u8'Vehicle LODs', checkbox.vehloads) then
		    if checkbox.vehloads.v then
			   memory.write(5425646, 1, 1, false)
			else
			   memory.write(5425646, 0, 1, false)
			end
		 end
		 imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отображение лодов транспорта")
         
		 imgui.Spacing()
	  elseif tabmenu.settings == 7 then
	     
		 local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		 local score = sampGetPlayerScore(id)
		 local ip, port = sampGetCurrentServerAddress()
         
	     imgui.Text(u8'Текущий Gamestate: '..gamestates[sampGetGamestate() + 1])
		 imgui.PushItemWidth(120)
         imgui.SameLine()
		 imgui.Combo(u8'##Gamestates', gamestate, gamestates)
		 imgui.SameLine()
		 if imgui.Button(u8'Сменить') then
			sampSetGamestate(gamestate.v)
		 end
		 if imgui.CollapsingHeader(u8"Логи:") then
            imgui.Text(u8"Логгировать в консоли:")
            imgui.Checkbox(u8'Логгировать в консоли нажатые текстдравы', checkbox.logtextdraws)
            imgui.Checkbox(u8'Логгировать в консоли поднятые пикапы', checkbox.pickeduppickups)
            imgui.Checkbox(u8'Логгировать в консоли ответы на диалоги', checkbox.logdialogresponse)
            imgui.Checkbox(u8'Логгировать в консоли выбранные объекты', checkbox.logobjects)
            imgui.Checkbox(u8'Логгировать в консоли 3d тексты', checkbox.log3dtexts)
            imgui.Checkbox(u8'Логгировать в консоли установку текстуры', checkbox.logtxd)
            imgui.Checkbox(u8'Логгировать в консоли сообщения в чате', checkbox.logmessages)
            
            imgui.Spacing()
            imgui.Text(u8"Стандартные логи:")
		    
		    imgui.PushItemWidth(150)
		    imgui.Combo(u8'##ComboBoxLogslist', combobox.logs,
            {"moonloader.log", "modloader.log", "sampfuncs.log", "chatlog.txt", "cleo.log"})
		    
		    imgui.SameLine()
		    if imgui.Button(u8"показать",imgui.ImVec2(110, 25)) then
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
         end
         
         if imgui.CollapsingHeader(u8"Текстдравы:") then
            if lastClickedTextdrawId then
               imgui.Text(u8"Последний нажатый текстдрав: "..lastClickedTextdrawId)
            end
         	imgui.Checkbox(u8'Отображать ID текстдравов', checkbox.showtextdrawsid)
		    if imgui.Checkbox(u8'Скрыть все текстдравы', checkbox.hidealltextdraws) then
		       for i = 0, 2048 do
                  sampTextdrawDelete(i)
               end
		    end
         end
         
         if imgui.CollapsingHeader(u8"Диалоги:") then
            if imgui.Button(u8'Скрыть диалог', imgui.ImVec2(200, 25)) then
		   	   enableDialog(false)
		    end
            imgui.SameLine()
		    imgui.Text(u8'Последний ID диалога: ' .. sampGetCurrentDialogId())
         end
	     
         if imgui.CollapsingHeader(u8"Справочная информация онлайн:") then
            imgui.Link("https://github.com/Brunoo16/samp-packet-list/wiki/RPC-List", u8"Список RPC")
            imgui.Link("https://github.com/ocornut/imgui/blob/v1.52/imgui.h", u8"Imgui (source)")
            imgui.Link("https://github.com/THE-FYP/SAMP.Lua/blob/master/samp/events.lua", u8"SAMP.Lua (Events)")
            imgui.Link("https://blast.hk/dokuwiki/moonloader:functions", u8"MoonLoader functions")
            imgui.Link("https://wiki.blast.hk/ru/moonloader/scripting-api", u8"Lua scripting API")
            imgui.Link("https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes", u8"Virtual key codes")
         end
         
         imgui.Spacing()
	     imgui.Text(isPlayerSpectating and u8('В наблюдении: Да') or u8('В наблюдении: Нет'))
               
	     if imgui.Button(u8'Выйти из спектатора', imgui.ImVec2(200, 25)) then
		    if isAbsolutePlay then
               sampAddChatMessage("Недоступно да Absolute Play, вы попадете в ЧМ", -1)
	        else
               --sampSendChat("/spec")
               local bs = raknetNewBitStream()
               raknetBitStreamWriteInt32(bs, 0)
               raknetEmulRpcReceiveBitStream(124, bs)
               raknetDeleteBitStream(bs)
            end
         end   
               
         imgui.SameLine()
         if imgui.Button(u8'Войти в спектатор', imgui.ImVec2(200, 25)) then
		    if isAbsolutePlay then
               sampAddChatMessage("Недоступно да Absolute Play, вы попадете в ЧМ", -1)
            else
               local bs = raknetNewBitStream()
               raknetBitStreamWriteInt32(bs, 1)
               raknetEmulRpcReceiveBitStream(124, bs)
               raknetDeleteBitStream(bs)
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
		 if imgui.Button(u8'Респавн (Эмуляция)', imgui.ImVec2(200, 25)) then
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
         if imgui.Button(u8"Выгрузить скрипт", imgui.ImVec2(130, 25)) then
            sampAddChatMessage("AbsEventHelper успешно выгружен.", -1)
            sampAddChatMessage("Для запуска используйте комбинацию клавиш CTRL + R.", -1)
            thisScript():unload()
         end
	     
		 imgui.SameLine()
		 if imgui.Button(u8"Реконнект (5 сек)", imgui.ImVec2(130, 25)) then
		    Recon(5000)
	     end
         
         if not isAbsolutePlay then
            imgui.SameLine()
			if imgui.Button(u8'Выбор класса', imgui.ImVec2(130, 25)) then
			   local skin = getCharModel(PLAYER_PED)
	           sampRequestClass(skin)
			   --setPlayerModel(skin)
			end
		 end
         
      elseif tabmenu.settings == 8 then
         if imgui.Button(u8"Очистить чат (Для себя)", imgui.ImVec2(300, 25)) then
            ClearChat()
         end
         if imgui.Button(u8"Открыть лог чата (chatlog.txt)", imgui.ImVec2(300, 25)) then
	        os.execute('explorer '..getFolderPath(5) ..'\\GTA San Andreas User Files\\SAMP\\chatlog.txt')
	     end
         if imgui.Button(u8"Отображать время в чате", imgui.ImVec2(300, 25)) then
            sampProcessChatInput("/timestamp")
	     end
         if imgui.Checkbox(u8(checkbox.hidechat.v and 'Показать чат' or 'Скрыть чат'), checkbox.hidechat) then
            memory.fill(getModuleHandle("samp.dll") + 0x63DA0, checkbox.hidechat.v and 0x90909090 or 0x0A000000, 4, true)
            sampSetChatInputEnabled(checkbox.hidechat.v)
	     end
         
         if imgui.Checkbox(u8("Уведомлять при упоминании в чате"), checkbox.chatmentions) then
            ini.settings.chatmentions = checkbox.chatmentions.v
            inicfg.save(ini, configIni)
         end
         
         if imgui.Checkbox(u8("Останавливать чат при открытии поля ввода"), checkbox.freezechat) then
            if checkbox.freezechat.v then 
               isChatFreezed = true 
            else
               isChatFreezed = false
            end
         end
         
         if imgui.Checkbox(u8("Отключить глобальный чат"), checkbox.globalchatoff) then
         end         
         
         imgui.Spacing()
         imgui.Text(u8"Копировать в буфер:")
	     if imgui.Button(u8"Получить id и ники игроков рядом", imgui.ImVec2(300, 25)) then
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
	     
         if imgui.Button(u8"Последний кликнутый игрок в TAB", imgui.ImVec2(300, 25)) then
	 	   if tabselectedplayer ~= nil then
               setClipboardText(tabselectedplayer)
               sampAddChatMessage("id последнего кликнутого игрока в TAB скопирован в буфер обмена", -1)
            else
               sampAddChatMessage("Нет последнего кликнтуого игрока в TAB", -1)
            end
	     end
         
      elseif tabmenu.settings == 9 then
      
         if imgui.Checkbox(u8'Показывать нижнюю панель', checkbox.showbackgroundbar) then
            ini.settings.showbackgroundbar = checkbox.showbackgroundbar.v
		    inicfg.save(ini, configIni)
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отображать панель с различной информацие внизу экрана")
        
         if imgui.Checkbox(u8'Включить горячие клавиши', checkbox.hotkeys) then
            ini.settings.hotkeys = checkbox.hotkeys.v
		    inicfg.save(ini, configIni)
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Активировать дополнительные горячие клавиши")
         
         
         imgui.Spacing()
         if imgui.Button(u8"Check updates",imgui.ImVec2(150, 25)) then
		    os.execute('explorer https://github.com/ins1x/AbsEventHelper/releases')
		 end
         imgui.Spacing()
      end -- end tabmenu.settings
      imgui.NextColumn()
	  
	  if imgui.Button(u8"Координаты",imgui.ImVec2(150, 25)) then tabmenu.settings = 1 end 
	  if imgui.Button(u8"Объекты",imgui.ImVec2(150, 25)) then tabmenu.settings = 2 end 
	  if imgui.Button(u8"Камера",imgui.ImVec2(150, 25)) then tabmenu.settings = 3 end 
	  if imgui.Button(u8"Прорисовка",imgui.ImVec2(150, 25)) then tabmenu.settings = 4 end 
	  if imgui.Button(u8"Погода",imgui.ImVec2(150, 25)) then tabmenu.settings = 5 end 
	  if imgui.Button(u8"Эффекты",imgui.ImVec2(150, 25)) then tabmenu.settings = 6 end 
	  if imgui.Button(u8"Чатик",imgui.ImVec2(150, 25)) then tabmenu.settings = 8 end 
      if imgui.Button(u8"Разное",imgui.ImVec2(150, 25)) then tabmenu.settings = 9 end 
      if ini.settings.debug then
	     if imgui.Button(u8"Дебаг",imgui.ImVec2(150, 25)) then tabmenu.settings = 7 end 
      end
      
	  
      imgui.Spacing()
      imgui.Columns(1)
       
      elseif tabmenu.main == 2 then
       
	   -- if dialog.extendedtab.v then
	      -- if imgui.Button("[ >> ]") then
	         -- dialog.extendedtab.v = not dialog.extendedtab.v
	      -- end
	   -- else
	      -- if imgui.Button("[ << ]") then
	         -- dialog.extendedtab.v = not dialog.extendedtab.v
	      -- end
       -- end	   
	   imgui.SameLine()
	   --imgui.TextQuestion("( ? )", u8"Открыть расширенные настройки")
	   --imgui.SameLine()
	   imgui.Text(u8"Выберите сущность:")
	   imgui.SameLine()
	   imgui.PushItemWidth(120)
	   imgui.Combo(u8'##ComboBoxSelecttable', combobox.selecttable, 
	   {u8'Игроки', u8'Транспорт', u8'Объекты'}, 3)
	   imgui.PopItemWidth()
	   
	   if combobox.selecttable.v == 0 then          
          playersTable = {}       
	 	  playersTotal = 0
	  
		  for k, v in ipairs(getAllChars()) do
		     local res, id = sampGetPlayerIdByCharHandle(v)
		     if res then
		 	     table.insert(playersTable, id)
		 	     playersTotal = playersTotal + 1
		      end
	 	   end
          
          -- imgui.SameLine()
          -- if imgui.TooltipButton(u8"Очистить", imgui.ImVec2(100, 25), u8:encode("Очистить таблицу")) then
             -- playersTable = {}       
             -- playersTotal = 0
			 -- if dialog.playerstat.v then dialog.playerstat.v = false end
			 -- chosenplayer = nil
          -- end
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
		     imgui.TextColoredRGB("{FF0000}Красным{CDCDCD} в таблице отмечены подозрительные игроки")
		  end
       
          --imgui.Spacing()
          imgui.Separator()
          imgui.Columns(5)
          imgui.TextQuestion("[ID]", u8"Нажмите на id чтобы скопировать в буфер id игрока")
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
			    if not dialog.playerstat.v then dialog.playerstat.v = true end
             end
             imgui.SetColumnWidth(-1, 250)
             imgui.NextColumn()
             if isAbsolutePlay then
                if score < 10 then
                   imgui.TextColoredRGB(string.format("{FF0000}%i", score))
                else 
                   imgui.TextColoredRGB(string.format("%i", score))
                end
             else
                imgui.TextColoredRGB(string.format("%i", score))
             end
             imgui.SetColumnWidth(-1, 70)
             imgui.NextColumn()
             if health >= 5000 then
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
      
	  elseif combobox.selecttable.v == 1 then
         imgui.Columns(2, "vehtableheader", false)
         imgui.SetColumnWidth(-1, 320)
         
         if imgui.Checkbox(u8("Найти ID транспорта по имени"), checkbox.findveh) then
            -- https://wiki.multitheftauto.com/wiki/Vehicle_IDs
         end
            
         if checkbox.findveh.v then 
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
         
         end
       
         if isCharInAnyCar(PLAYER_PED) then 
            local carhandle = storeCarCharIsInNoSave(PLAYER_PED)
            local carmodel = getCarModel(carhandle)
            imgui.Text(string.format(u8"Вы в транспорте: %s(%i)",
            VehicleNames[carmodel-399], carmodel))
         end
       
         imgui.NextColumn()
         imgui.Columns(1)
            
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
            local vehmodelname = string.format("%s", VehicleNames[carmodel-399])
            
            imgui.Columns(4)
            imgui.TextColoredRGB(string.format("%i", id))
            imgui.SetColumnWidth(-1, 50)
            imgui.NextColumn()
            imgui.Selectable(vehmodelname)
            if imgui.IsItemClicked() then
               chosenvehicle = v
               vehinfomodelid = carmodel
			   if not dialog.vehstat.v then dialog.vehstat.v = true end
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
       
         imgui.Text(u8"Всего транспорта в таблице: ".. vehiclesTotal)
         
      elseif combobox.selecttable.v == 2 then
         
         imgui.Separator()
         imgui.Columns(4)
         imgui.TextQuestion("ID", u8"Внутренний ID (/ctd)")
         imgui.NextColumn()
         imgui.Text("Modelid")
         imgui.NextColumn()
         imgui.Text("Name")
         imgui.NextColumn()
         imgui.Text("Distance")
         imgui.NextColumn()
         imgui.Columns(1)
         imgui.Separator()
         
         local objectsInTable = 0
         
         for _, v in pairs(getAllObjects()) do
            if isObjectOnScreen(v) then
               local model = getObjectModel(v)
               local objectid = sampGetObjectSampIdByHandle(v)
               local modelName = tostring(sampObjectModelNames[model])
               local _, x, y, z = getObjectCoordinates(v)
			   local px, py, pz = getCharCoordinates(PLAYER_PED)
			   local distance = string.format("%.2f", getDistanceBetweenCoords3d(x, y, z, px, py, pz))
              
               objectsInTable = objectsInTable + 1
               imgui.Columns(4)
               imgui.SetColumnWidth(-1, 80)
               imgui.Text(" "..objectid)
               imgui.NextColumn()
               imgui.SetColumnWidth(-1, 80)
               imgui.TextColoredRGB("{3f70d6}"..model)
               imgui.NextColumn()
               imgui.SetColumnWidth(-1, 350)
               imgui.Text(" "..modelName)
               imgui.NextColumn()
               imgui.Text(" "..distance)
               imgui.NextColumn()
               imgui.Columns(1)
               imgui.Separator()
            end
         end
         
         imgui.Text(u8"Всего объектов в таблице: ".. objectsInTable)
         
      end

      elseif tabmenu.main == 3 then
      imgui.Columns(2)
      imgui.SetColumnWidth(-1, 510)
      
      if tabmenu.info == 1 then
         imgui.Text(u8"Absolute Events Helper v".. thisScript().version)
         imgui.TextColoredRGB("Ассистент для мапперов и организаторов мероприятий.")
         imgui.Text(u8"Скрипт позволит сделать процесс маппинга в внутриигровом редакторе карт")
         imgui.Text(u8"максимально приятным, и даст больше возможностей организаторам мероприятий")
         imgui.Text(u8"Скрипт распостраняется только с открытым исходным кодом")
		 if isAbsolutePlay then
            imgui.Text(u8"Категорически не рекомендуется использовать этот скрипт вне редактора карт!")
		    imgui.TextColoredRGB("Протестировать скрипт можно на Absolute DM Play в мире №10 {007DFF}(/мир 10)")
            if imgui.IsItemClicked() then
               if isAbsolutePlay then sampSendChat("/мир 10") end
            end
         end
         imgui.Spacing()
         
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
		 
         imgui.Spacing()
         imgui.Spacing()
         imgui.Spacing()
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
               imgui.TextColoredRGB("макс. длина текста при ретекстуре {00FF00}50")
            end
            if isTraining then
               imgui.TextColoredRGB("Слоты сохранения игровы миров: {00FF00}3 (VIP 10)")
               imgui.TextColoredRGB("Объекты мапинга: {00FF00}300 (VIP 3500)")
               imgui.TextColoredRGB("Проходы(пикапы): {00FF00}20 (VIP 100)")
               imgui.TextColoredRGB("Командные блоки: {00FF00}200 (VIP 999)")
               imgui.TextColoredRGB("Актеры: {00FF00}50 (VIP 200)")
               imgui.TextColoredRGB("Транспорт: {00FF00}30 (VIP 80)")
               imgui.TextColoredRGB("Переменные: {00FF00}99")
               imgui.TextColoredRGB("Массивы: {00FF00}26{CDCDCD} для игроков, для сервера {00FF00}50")
            end
         end
         if imgui.CollapsingHeader(u8"Лимиты высоты:") then
            imgui.TextColoredRGB("На карте GTA-SA средней высотой дорог считается {00FF00}~ 20:")
            imgui.TextColoredRGB("- В Лос-Сантосе: {00FF00}~10-15")
            imgui.TextColoredRGB("- В Лас-Вентурасе: {00FF00}~10")
            imgui.TextColoredRGB("- В Сан-Фиерро: {00FF00}~7-80")
            imgui.TextColoredRGB("- Округ: {00FF00}~ -45(Карьер возле ЛВ)")
            imgui.Spacing()
            imgui.TextColoredRGB("Уровень океана всегда равен {00FF00}0")
            imgui.TextColoredRGB("Высшая точка на карте это горы Чиллиад {00FF00}~527")
            imgui.TextColoredRGB("Максимальной отрицательной высотой является значение в {00FF00}-99")
            imgui.TextColoredRGB("(Если высота будет ниже, игрока просто телепортирует на поверхность)")
            imgui.TextColoredRGB("Интерьеры принято размещать на высоте в {00FF00}1000")
            imgui.TextColoredRGB("Максимальная высота джетпака {00FF00}100 (с модами 200)")
            imgui.TextColoredRGB("Максимальная высота воздушного транспорта {00FF00}800 (с модами 2000)")
            imgui.Spacing()
            imgui.Link("https://forum.training-server.com/d/18361-prostranstvennaya-orientatsiya-po-karte-gtasa", u8"Пространственная ориентация по карте GTA:SA")
            imgui.Spacing()
         end
         imgui.Text(u8"В радиусе 150 метров нельзя создавать более 200 объектов.")
         imgui.TextColoredRGB("Максимальная длина текста на объектах в редакторе миров - {00FF00}50 символов")
         
		 imgui.Spacing()
         imgui.TextColoredRGB("Лимиты в SA:MP и UG:MP : ")
		 imgui.SameLine()
		 imgui.Link("https://gtaundergroundmod.com/pages/ug-mp/documentation/limits", "https://gtaundergroundmod.com")
         imgui.TextColoredRGB("Лимиты в San Andreas: ")
		 imgui.SameLine()
		 imgui.Link("https://gtamods.com/wiki/SA_Limit_Adjuster", "https://gtamods.com/wiki/SA_Limit_Adjuster")
         

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
         imgui.TextColoredRGB(u8:decode(textbuffer.rgb.v))
       
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
         imgui.TextQuestion("( ? )", u8"Нажмите чтобы скопировать цвет в буфер обмена")
		 
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
         
         if isAbsolutePlay then
		    if imgui.CollapsingHeader(u8'Доступные текстуры на Absolute Play') then
               imgui.Link("https://sun9-56.userapi.com/impf/qzMWsYTX7NTQ7_9tYfFgyMIgXHfjfeHnJWF11A/UQwq0T9ZxwM.jpg?size=771x2160&quality=95&sign=61ac0f5281133dc714855724b7c8c51a&type=album", u8"Изображение со всеми текстурами")
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
		 
         if imgui.CollapsingHeader(u8'Популярные текстуры') then
            if isTraining then
               imgui.TextColoredRGB("{00FF00}8660{FFFFFF} - невидимая текстура")
               imgui.TextColoredRGB("{00FF00}2643 или 64{FFFFFF} - двойной цвет (бело-чёрный)")
               imgui.TextColoredRGB("{00FF00}121{FFFFFF} - песок")
               imgui.TextColoredRGB("{00FF00}388{FFFFFF} - прозрачная текстура")
               imgui.TextColoredRGB("{00FF00}89{FFFFFF} - вода")
               imgui.TextColoredRGB("{00FF00}56 и 4853{FFFFFF} - трава")
               imgui.TextColoredRGB("{00FF00}1165 и 3123{FFFFFF} - дерево")
               imgui.TextColoredRGB("{00FF00}2864 и 3035{FFFFFF} - стекло")
               imgui.TextColoredRGB("{00FF00}2921 и 4062{FFFFFF} - белая текстура")
               imgui.TextColoredRGB("{00FF00}300{FFFFFF} - чёрная текстурка")
               imgui.TextColoredRGB("{00FF00}7838 - 7807 - 7808 - 8405 - 8406 - 8407 - 8408 - 5440 - 5441 - 5442 - 5443{FFFFFF}")
               imgui.TextColoredRGB("разные цвета (зелёный, красный, синий и т.д)")
               imgui.TextColoredRGB("{00FF00}235{FFFFFF} - стрелки")
               imgui.TextColoredRGB("{00FF00}6510{FFFFFF} - затемнение")
               imgui.TextColoredRGB("{00FF00}6439{FFFFFF} - прозрачная дверь")
               imgui.TextColoredRGB("{00FF00}6289{FFFFFF} - деревянные балки")
               imgui.TextColoredRGB("{00FF00}6239{FFFFFF} - окно")
               imgui.TextColoredRGB("{00FF00}6006{FFFFFF} - экран TВ")
               imgui.TextColoredRGB("{00FF00}4812{FFFFFF} - гараж")
               imgui.TextColoredRGB("{00FF00}4741{FFFFFF} - вентиляция")
               imgui.TextColoredRGB("{00FF00}4700{FFFFFF} - разбитое окно или двери")
               imgui.TextColoredRGB("{00FF00}3321{FFFFFF} - окно в магазинах")
               imgui.TextColoredRGB("{00FF00}3223{FFFFFF} - газета")
               imgui.TextColoredRGB("{00FF00}3124{FFFFFF} - люди, просто люди")
               imgui.TextColoredRGB("{00FF00}2519{FFFFFF} - занавес")
               imgui.TextColoredRGB("{00FF00}2410{FFFFFF} - флаги")
               imgui.TextColoredRGB("{00FF00}1847{FFFFFF} - дверь")
               imgui.TextColoredRGB("{00FF00}1665{FFFFFF} - сетка прозрачная")
               imgui.Spacing()
               imgui.TextColoredRGB("{00FF00}/tsearch <objectid> <slot> <name>{FFFFFF} - наложение текстуры по поиску")
               imgui.TextColoredRGB("{00FF00}/stexture <objectid> <slot> <index>{FFFFFF} - наложить текстуру на объект по индексу")
               imgui.TextColoredRGB("{00FF00}/untexture <objectid>{FFFFFF} - обнулить наложенные текстуры (и /ocolor)")
            end
            if isAbsolutePlay then
               imgui.TextColoredRGB("{00FF00}90{FFFFFF} - Вода из ViceCity")
               imgui.TextColoredRGB("{00FF00}118{FFFFFF} - белый цвет, {00FF00}204{FFFFFF} - Черный цвет")
               imgui.TextColoredRGB("{00FF00}98, 101, 178{FFFFFF} - Ящики")
               imgui.TextColoredRGB("{00FF00}121, 122, 125{FFFFFF} - Песок")
               imgui.TextColoredRGB("{00FF00}13, 59, 176, 234, 243, 273, 277, 283, 298{FFFFFF} - Дерево")
               imgui.TextColoredRGB("{00FF00}64, 73{FFFFFF} - Трава")
               imgui.TextColoredRGB("{00FF00}217-221 и 265-269{FFFFFF} - Подарки")
               imgui.TextColoredRGB("{00FF00}212 - 216{FFFFFF} Цвета")
               imgui.TextColoredRGB("{00FF00}129{FFFFFF} - Военный камуфляж")
               imgui.TextColoredRGB("{00FF00}244, 232{FFFFFF} - Ржавчина")
               imgui.TextColoredRGB("{00FF00}168, 170, 49, 230, 233{FFFFFF} - Металл")
               imgui.TextColoredRGB("{00FF00}256{FFFFFF} - Лава")
               imgui.TextColoredRGB("{00FF00}257{FFFFFF} - Мусор")
               imgui.TextColoredRGB("{00FF00}8{FFFFFF} - Снег")
               imgui.TextColoredRGB("{00FF00}65{FFFFFF} - Финиш (Флаг)")
               imgui.TextColoredRGB("{00FF00}107{FFFFFF} - Скайбокс")
               imgui.Spacing()
               imgui.TextColoredRGB("Используйте {00FF00}/tsearch{FFFFFF} для поиска тексуры")
            end
            imgui.TextColoredRGB("Топлист текстур онлайн:")
		    imgui.SameLine()
            imgui.Link("https://textures.xyin.ws/?page=toplist", "https://textures.xyin.ws/?page=toplist")
         end
         
		 if imgui.CollapsingHeader(u8'Популярные шрифты') then
            
            local fontlink
            imgui.Spacing()
            for k, fontname in pairs(AbsFontNames) do
               fontlink = string.format("https://flamingtext.ru/Font-Search?q=%s", fontname)
               imgui.Link(fontlink, fontname)
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
		    
		    imgui.TextColoredRGB("{00FF00}19481{FFFFFF} - Размер (радиус):{00FF00} 19.582")
			if imgui.IsItemClicked() then
                setClipboardText("19481")
                sampAddChatMessage("19481 - Скопирован в буфер обмена", -1)
            end
            imgui.TextColoredRGB("{00FF00}19480{FFFFFF} - Размер (радиус):{00FF00} 11.070")
			if imgui.IsItemClicked() then
                setClipboardText("19480")
                sampAddChatMessage("19480 - Скопирован в буфер обмена", -1)
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
		 if imgui.CollapsingHeader(u8'Выравнивание текста') then
            imgui.TextColoredRGB("0 - OBJECT_MATERIAL_TEXT_ALIGN_LEFT")
            imgui.TextColoredRGB("1 - OBJECT_MATERIAL_TEXT_ALIGN_CENTER")
            imgui.TextColoredRGB("2 - OBJECT_MATERIAL_TEXT_ALIGN_RIGHT")
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
               "//moonloader//resource//abseventhelper//objects.txt", "w")
               --favfile:write("\n")
               --favfile:write(string.format("%s \n", os.date("%d.%m.%y %H:%M:%S")))
               favfile:write(textbuffer.note.v)
               favfile:close()
               sampAddChatMessage("Сохранено в файл избранных: moonloader/resource/abseventhelper/objects.txt", -1)
            end
         
            imgui.SameLine()
            if imgui.Button(u8"Загрузить избранные из файла", imgui.ImVec2(200, 25)) then
               favfile = io.open(getGameDirectory() ..
               "//moonloader//resource//abseventhelper//objects.txt", "r")
               textbuffer.note.v = favfile:read('*a')
               favfile:close()
            end
         elseif combobox.objects.v == 6 then
	        imgui.TextColoredRGB("Поиск на {007DFF}Prineside DevTools (Online)")
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
            
            if LastObjectData.modelid then
               imgui.SameLine()
               if imgui.TooltipButton(u8"Вставить", imgui.ImVec2(65, 25), u8"Вставить последний объект id: "..LastObjectData.modelid) then
	              textbuffer.objectid.v = tostring(LastObjectData.modelid)
		       end
	        end
            
            if imgui.Button(u8"Найти объекты рядом по текущей позиции",imgui.ImVec2(300, 25)) then
		       if sampIsLocalPlayerSpawned() then
                  local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
                  local link = string.format('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/mapsearch/?x=%i&y=%i', posX, posY)
		          os.execute(link)
		       end
	        end
            
            imgui.Checkbox(u8'Найти объект с особым поведением', checkbox.searchobjectsext)
            if checkbox.searchobjectsext.v then
               if imgui.Button(u8"Все объекты без коллизии",imgui.ImVec2(220, 25)) then
                  os.execute('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/customsearch/?c%5B%5D=1&s=id-asc&bc=0&bb=-1&bt=-1&ba=-1"')
               end
               imgui.SameLine()
               if imgui.Button(u8"Все разрушаемые объекты",imgui.ImVec2(220, 25)) then
                  os.execute('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/customsearch/?c%5B%5D=1&s=id-asc&bc=-1&bb=1&bt=-1&ba=-1"')
               end
               if imgui.Button(u8"Все отображаемые по времени",imgui.ImVec2(220, 25)) then
                  os.execute('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/customsearch/?c%5B%5D=1&s=id-asc&bc=-1&bb=-1&bt=1&ba=-1"')
               end
               imgui.SameLine()
               if imgui.Button(u8"Все объекты с анимацией",imgui.ImVec2(220, 25)) then
                  os.execute('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/customsearch/?c%5B%5D=1&s=id-asc&bc=-1&bb=-1&bt=-1&ba=1"')
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
         
         imgui.TextColoredRGB("Частицы (партиклы) из SA")
		 imgui.SameLine()
		 imgui.Link("https://gtamods.com/wiki/Particle_(SA)", "gtamods.com")
           
      elseif tabmenu.info == 6 then
		 imgui.Spacing()
         if imgui.CollapsingHeader(u8"Дополнительные команды:") then
            imgui.TextColoredRGB("{00FF00}/abs{FFFFFF} - открыть главное меню хелпера")
            imgui.TextColoredRGB("{00FF00}/jump{FFFFFF} - прыгнуть вперед")
            imgui.TextColoredRGB("{00FF00}/ответ{FFFFFF} - быстрые ответы")
            if isAbsolutePlay then
               imgui.TextColoredRGB("{00FF00}/slapme{FFFFFF} - слапнуть себя")
               imgui.TextColoredRGB("{00FF00}/spawnme{FFFFFF} - заспавнить себя")
               imgui.TextColoredRGB("{00FF00}/savepos{FFFFFF} - сохранить позицию")
               imgui.TextColoredRGB("{00FF00}/setweather{FFFFFF} - установить погоду")
               imgui.TextColoredRGB("{00FF00}/settime{FFFFFF} - установить время")
               imgui.TextColoredRGB("{00FF00}/gopos{FFFFFF} - телепорт на сохраненную позицию")
            end
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
            imgui.TextColoredRGB("{00FF00}/hudscalefix{FFFFFF} - исправляет размер HUD'a, ссылаясь на разрешение экрана клиента")
			imgui.TextColoredRGB("{00FF00}/quit (/q){FFFFFF} - вернуться в суровую реальность")
		 end
         if imgui.CollapsingHeader(u8"Серверные команды:") then
            if isAbsolutePlay then
               imgui.TextColoredRGB("{00FF00}/menu{FFFFFF} — вызвать главное меню")
               imgui.TextColoredRGB("{00FF00}/мир <номер мира>{FFFFFF} — войти в мир по номеру")
               imgui.TextColoredRGB("{00FF00}/прыг{FFFFFF} — прыгнуть вперед")
               imgui.TextColoredRGB("{00FF00}/полет{FFFFFF} — уйти в режим полета в мире")
               imgui.TextColoredRGB("{00FF00}/стат <id игрока>{FFFFFF} — показать статистику игрока")
               imgui.TextColoredRGB("{00FF00}/и <id игрока>{FFFFFF} — меню игрока")
               imgui.TextColoredRGB("{00FF00}/id <часть имени>{FFFFFF} — найти id по части имени")
               imgui.TextColoredRGB("{00FF00}/тпк <x y z>{FFFFFF} — телепорт по координатам")
               imgui.TextColoredRGB("{00FF00}/коорд{FFFFFF} - узнать текущие координаты")
               imgui.TextColoredRGB("{00FF00}/выход либо /exit{FFFFFF} — выйти из мира")
               imgui.TextColoredRGB("{00FF00}/ограбить{FFFFFF} - ограбить игрока")
               imgui.TextColoredRGB("{00FF00}/п{FFFFFF} - перевернуть авто на колёса, если оно перевернулось")
               imgui.TextColoredRGB("{00FF00}/парашют{FFFFFF} - подняться в воздух с парашютом($5 000)")
               imgui.TextColoredRGB("{00FF00}/вм{FFFFFF} - перенести машину к дому($1 000)")
               imgui.TextColoredRGB("{00FF00}/машину{FFFFFF} - перенести машину к себе($1 000)")
               imgui.TextColoredRGB("{00FF00}/машину2{FFFFFF} - заказать транспорт к себе($ зависит от стоимости транспорта)")
            end
            if isTraining then
               imgui.TextColoredRGB("{00FF00}/world{FFFFFF} -  создать игровой мир")
               imgui.TextColoredRGB("{00FF00}/menu | /mm{FFFFFF} -  игровое меню")
               imgui.TextColoredRGB("{00FF00}/vw{FFFFFF} -  управление игровым миром")
               imgui.TextColoredRGB("{00FF00}/rules{FFFFFF} -  правила сервера")
               imgui.TextColoredRGB("{00FF00}/list | /world <1 пункт>{FFFFFF} -  список игровых миров")
               imgui.TextColoredRGB("{00FF00}/exit{FFFFFF} -  отправиться на спаун сервера")
               imgui.TextColoredRGB("{00FF00}/stats <id>{FFFFFF} -  посмотреть статистику игрока")
               imgui.TextColoredRGB("{00FF00}/id <name|id>{FFFFFF} -  поиск игроков по части ника | по id")
               imgui.TextColoredRGB("{00FF00}/time <0-23>{FFFFFF} -  сменить игровое время (локально)")
               imgui.TextColoredRGB("{00FF00}/weather <0-20>{FFFFFF} -  установить погоду (локально)")
               imgui.TextColoredRGB("{00FF00}/savepos{FFFFFF} -  сохранить текущую позицию и угол поворота")
               imgui.TextColoredRGB("{00FF00}/gopos{FFFFFF} -  телепортироваться на сохраненную позицию")
               imgui.TextColoredRGB("{00FF00}/xyz <x> <y> <z> <fa> {FFFFFF} -  телепортироваться на координаты")
               imgui.TextColoredRGB("{00FF00}/taser{FFFFFF} -  взять/убрать тайзер")
               imgui.TextColoredRGB("{00FF00}/accept{FFFFFF} -  принять приглашение в игровой мир")
               imgui.TextColoredRGB("{00FF00}/adminlist{FFFFFF} -  список модератов СЕРВЕРА")
               imgui.TextColoredRGB("{00FF00}/verify{FFFFFF} -  список верифицированных игроков сервера")
               imgui.TextColoredRGB("{00FF00}/nameon | /nameoff{FFFFFF} -  выключить/включить ники над головами игроков")
               imgui.TextColoredRGB("{00FF00}/slapme{FFFFFF} -  подбросить себя")
               imgui.TextColoredRGB("{00FF00}/spawnme{FFFFFF} -  заспавнить себя")
               imgui.TextColoredRGB("{00FF00}/jetpack{FFFFFF} -  [VIP] взять реактивный ранец")
               imgui.TextColoredRGB("{00FF00}/gm{FFFFFF} -  включить ГМ")
               imgui.TextColoredRGB("{00FF00}/rm{FFFFFF} -  обнулить деньги")
               imgui.TextColoredRGB("{00FF00}/rw{FFFFFF} -  обнулить оружие")
               imgui.TextColoredRGB("{00FF00}/pay <id> <money>{FFFFFF} -  передать деньги игроку")
               imgui.TextColoredRGB("{00FF00}/skill <0-999>{FFFFFF} -  установить скилл текущему оружию | > 999 -  одна рука")
               imgui.TextColoredRGB("{00FF00}/attachinfo | /attinfo <slot 0-10>{FFFFFF} - получить информацию про прикрепленный объект")
               imgui.TextColoredRGB("{00FF00}/fadd <id>{FFFFFF} - добавить игрока в список друзей")
               imgui.TextColoredRGB("{00FF00}/flist{FFFFFF} - список ваших друзей")
            end
            imgui.Spacing()
         end
         if imgui.CollapsingHeader(u8"Объекты:") then
            if isTraining then
               imgui.TextColoredRGB("{00FF00}/gate{FFFFFF} -  управление перемещаемыми объектами")
               imgui.TextColoredRGB("{00FF00}/pass <*passid>{FFFFFF} -  установить проход | <passid> редактировать")
               imgui.TextColoredRGB("{00FF00}/tpp <passid>{FFFFFF} -  телепортироваться к проходу")
               imgui.TextColoredRGB("{00FF00}/delpass <passid>{FFFFFF} -  удалить проход")
               imgui.TextColoredRGB("{00FF00}/passinfo{FFFFFF} -  редактирование ближайшего прохода")
               imgui.TextColoredRGB("{00FF00}/action{FFFFFF} -  создать 3D текст")
               imgui.TextColoredRGB("{00FF00}/editaction <actionid>{FFFFFF} -  редактировать 3D текст")
               imgui.TextColoredRGB("{00FF00}/tpaction <actoinid>{FFFFFF} -  телепортироваться к 3D тексту")
               imgui.TextColoredRGB("{00FF00}/delaction <actionid>{FFFFFF} -  удалить 3D текст")
               imgui.TextColoredRGB("{00FF00}/sel <objectid>{FFFFFF} -  выделить объект")
               imgui.TextColoredRGB("{00FF00}/oa(dd) <modelid>{FFFFFF} -  создать объект")
               imgui.TextColoredRGB("{00FF00}/od(ell) <*objectid>{FFFFFF} -  удалить объект | id только при /sel")
               imgui.TextColoredRGB("{00FF00}/ogh(ethere) <*objectid>{FFFFFF} -  телепортировать объект к себе | id при /sel")
               imgui.TextColoredRGB("{00FF00}/oinfo <*objectid>{FFFFFF} -  информация о объекте | id только при /sel")
               imgui.TextColoredRGB("{00FF00}/oswap <objectid> <modelid>{FFFFFF} -  изменить модель объекта")
               imgui.TextColoredRGB("{00FF00}/rx <objectid> <0-360>{FFFFFF} -  повернуть объект по координате X")
               imgui.TextColoredRGB("{00FF00}/ry <objectid> <0-360>{FFFFFF} -  повернуть объект по координате Y")
               imgui.TextColoredRGB("{00FF00}/rz <objectid> <0-360>{FFFFFF} -  повернуть объект по координате Z")
               imgui.TextColoredRGB("{00FF00}/ox <objectid> <m>{FFFFFF} -  сдвинуть объект по координате X")
               imgui.TextColoredRGB("{00FF00}/oy <objectid> <m>{FFFFFF} -  сдвинуть объект по координате Y")
               imgui.TextColoredRGB("{00FF00}/oz <objectid> <m>{FFFFFF} -  сдвинуть объект по координате Z")
               imgui.TextColoredRGB("{00FF00}/tpo <*objectid>{FFFFFF} -  телепортироваться к объекту | <*objectid> только при /sel")
               imgui.TextColoredRGB("{00FF00}/clone <*objectid>{FFFFFF} -  клонировать объект | <*objectid> только при /sel")
               imgui.TextColoredRGB("{00FF00}/oe(dit) <*objectid>{FFFFFF} -  редактировать объект | <*objectid> только при /sel")
               imgui.TextColoredRGB("{00FF00}/olist{FFFFFF} -  управление всеми объектами в мире")
               imgui.TextColoredRGB("{00FF00}/omenu <objectid>{FFFFFF} -  управление определенным объектом")
               imgui.TextColoredRGB("{00FF00}/osearch <name>{FFFFFF} -  поиск объекта по части имени")
               imgui.TextColoredRGB("{00FF00}/ocolor <objectid> <slot> <0xAARGBRGB>{FFFFFF} - сменить цвет объекта")
               imgui.TextColoredRGB("{00FF00}/texture <objectid> <slot> <page>{FFFFFF} - список текстур для наложения на объект")
               imgui.TextColoredRGB("{00FF00}/sindex <objectid>{FFFFFF} - перекрасить объект в зеленую текстуру и обозначить слоты")
               imgui.TextColoredRGB("{00FF00}/tsearch <objectid> <slot> <name>{FFFFFF} - наложение текстуры по поиску")
               imgui.TextColoredRGB("{00FF00}/stexture <objectid> <slot> <index>{FFFFFF} - наложить текстуру на объект по индексу")
               imgui.TextColoredRGB("{00FF00}/untexture <objectid>{FFFFFF} - обнулить наложенные текстуры (и /ocolor)")
               imgui.TextColoredRGB("{00FF00}/otext{FFFFFF} - наложение текста на слот объекта")
            end
            if isAbsolutePlay then
               imgui.TextColoredRGB("{00FF00}/tsearch{FFFFFF} - поиск текстуры по названию")
               imgui.TextColoredRGB("{00FF00}/osearch{FFFFFF} - поиск объекта по названию")
               imgui.TextColoredRGB("{00FF00}/ogoto{FFFFFF} - тп к текущему объекту")
               imgui.TextColoredRGB("{00FF00}/oalpha{FFFFFF} - сделать объект полупрозрачным")
               imgui.TextColoredRGB("{00FF00}/ocolor <0xAARGBRGB>{FFFFFF} - установить цвет объекту")
               imgui.TextColoredRGB("{00FF00}/sindex /rindex{FFFFFF} - вкл-откл визуальный просмотр индексов")
               imgui.TextColoredRGB("{00FF00}/showtext3d /hidetext3d{FFFFFF} - показать id объектов (CTRL + O)")
               imgui.TextColoredRGB("{00FF00}/csel /editobject{FFFFFF} - включить режим выбора объекта")
            end
         end
         if isTraining then
            if imgui.CollapsingHeader(u8"Управление миром:") then
               imgui.TextColoredRGB("{00FF00}/vw{FFFFFF} -  управление игровым миром")
               imgui.TextColoredRGB("{00FF00}/int | /op{FFFFFF} -  список интерьеров для телепорта")
               imgui.TextColoredRGB("{00FF00}/team{FFFFFF} - управление командами мира")
               imgui.TextColoredRGB("{00FF00}/givevw{FFFFFF} -  передать виртуальный мир игроку")
               imgui.TextColoredRGB("{00FF00}/cancel{FFFFFF} -  отменить покупку игрового мира")
               imgui.TextColoredRGB("{00FF00}/invite <id>{FFFFFF} - пригласить игрока в мир")
               imgui.TextColoredRGB("{00FF00}/armour <0-100>{FFFFFF} - пополнить уровень брони")
               imgui.TextColoredRGB("{00FF00}/health <0-100>{FFFFFF} - пополнить уровень здоровья")
               imgui.TextColoredRGB("{00FF00}/sethp <id> <0-100>{FFFFFF} - установить игроку уровень здоровья")
               imgui.TextColoredRGB("{00FF00}/setarm <id> <0-100>{FFFFFF} - установить игроку уровень брони")
               imgui.TextColoredRGB("{00FF00}/rsethp <hp 0-100> <armour 0-100> <radius>{FFFFFF} - выдать HP и ARMOUR в радиусе")
               imgui.TextColoredRGB("{00FF00}/ress <playerid>{FFFFFF} - воскресить игрока в RP стадии")
               imgui.TextColoredRGB("{00FF00}/ressall{FFFFFF} - воскресить всех игроков в RP стадии")
               imgui.TextColoredRGB("{00FF00}/vkick <id> <*reason>{FFFFFF} - исключить игрока из мира")
               imgui.TextColoredRGB("{00FF00}/vmute <id> <time (m)> <*reason>{FFFFFF} - замутить игрока в мире")
               imgui.TextColoredRGB("{00FF00}/vban <id> <time (m) | 0 - навсегда> <*reason>{FFFFFF} - забанить игрока в мире")
               imgui.TextColoredRGB("{00FF00}/setteam <id> <teamid>{FFFFFF} - установить игроку команду")
               imgui.TextColoredRGB("{00FF00}/unteam <id>{FFFFFF} - исключить игрока из команды")
               imgui.TextColoredRGB("{00FF00}/stream | /music | /boombox{FFFFFF} - управление аудиопотоками в мире")
            end
            if imgui.CollapsingHeader(u8"Командные блоки и массивы:") then
               imgui.Text(u8"Командные блоки:")
               imgui.TextColoredRGB("{00FF00}/cb{FFFFFF} - создать командный блокам")
               imgui.TextColoredRGB("{00FF00}/cbdell{FFFFFF} - удалить блок")
               imgui.TextColoredRGB("{00FF00}/cbtp{FFFFFF} - телепортрт к блоку")
               imgui.TextColoredRGB("{00FF00}/cbedit{FFFFFF} - открыть меню блока")
               imgui.TextColoredRGB("{00FF00}/timers{FFFFFF} - список таймеров мира")
               imgui.TextColoredRGB("{00FF00}/oldcb{FFFFFF} - включить устарелые текстовые команды")
               imgui.TextColoredRGB("{00FF00}/cmb | //<text>{FFFFFF} - активировать КБ аллиас")
               imgui.TextColoredRGB("{00FF00}/cblist{FFFFFF} - список всех командных блоков в мире")
               imgui.TextColoredRGB("{00FF00}/tb{FFFFFF} - список триггер блоков в мире")
               imgui.TextColoredRGB("{00FF00}/shopmenu{FFFFFF} - управление магазинами мира для КБ")
               imgui.Text(u8"Массивы и переменные:")
               imgui.TextColoredRGB("{00FF00}/data <id>{FFFFFF} - посмотреть массивы игрока")
               imgui.TextColoredRGB("{00FF00}/setdata <id> <array 0-26> <value>{FFFFFF} - установить значение массива игроку")
               imgui.TextColoredRGB("{00FF00}/server{FFFFFF} - посмотреть серверные массивы мира")
               imgui.TextColoredRGB("{00FF00}/setserver <array 0-49> <value>{FFFFFF} - установить значение серверному массиву")
               imgui.TextColoredRGB("{00FF00}/varlist{FFFFFF} - список серверных переменных мира")
               imgui.TextColoredRGB("{00FF00}/pvarlist{FFFFFF} - список пользовательских переменных мира")
               imgui.TextColoredRGB("{00FF00}/pvar <id>{FFFFFF} - управление пользовательскими переменными игрока")

               imgui.Spacing()
		       
               imgui.TextColoredRGB("Смотрите так же:")
               imgui.Link("https://forum.training-server.com/d/4466", u8"Командные блоки (Описание/Туториалы)")
               imgui.Link("https://forum.training-server.com/d/6166-kollbeki", u8"Коллбэки")
               imgui.Link("https://forum.training-server.com/d/16872-spisok-novyh-tekstovyh-funktsiy", u8"Список новых текстовых функций")
            end
         end
         if imgui.CollapsingHeader(u8"Чат команды:") then
            if isAbsolutePlay then
               imgui.TextColoredRGB("{00FF00}*{FFFFFF} - *текст - сказать игрокам поблизости, радиусный чат (50м)")
               imgui.TextColoredRGB("{00FF00}!{FFFFFF} - !текст - в клановый чат выведется сообщение текст")
               imgui.TextColoredRGB("{00FF00}@[номер игрока]{FFFFFF} - @0 - заменяет текст на имя игрока, @я - на свой")
               imgui.TextColoredRGB("{00FF00}/мчат <текст>{FFFFFF} — сказать игрокам в мире")
               imgui.TextColoredRGB("{00FF00}/об <текст>{FFFFFF} — дать объявление")
               imgui.TextColoredRGB("{00FF00}/me <текст>{FFFFFF} — сказать от 3-го лица")
               imgui.TextColoredRGB("{00FF00}/try <текст>{FFFFFF} — удачно-неудачно")
               imgui.TextColoredRGB("{00FF00}/w /ш <текст>{FFFFFF} — сказать шепотом")
               imgui.TextColoredRGB("{00FF00}/к <текст>{FFFFFF} — крикнуть")
               imgui.TextColoredRGB("{00FF00}/лс[ид игрока] <текст>{FFFFFF} — дать объявление")
            end
            if isTraining then
               imgui.TextColoredRGB("{00FF00}/!text{FFFFFF} - глобальный чат (оранжевый)")
               imgui.TextColoredRGB("{00FF00}/@ | ;text{FFFFFF} - чат игрового мира (зеленый)")
               imgui.TextColoredRGB("{00FF00}/v | $ | ;text{FFFFFF} - чат модераторов мира")
               imgui.TextColoredRGB("{00FF00}/low | /l <text>{FFFFFF} - сказать шепотом")
               imgui.TextColoredRGB("{00FF00}/whisper | /w <text>{FFFFFF} - сказать шепотом игроку")
               imgui.TextColoredRGB("{00FF00}/try <text>{FFFFFF} - случайная вероятность действия")
               imgui.TextColoredRGB("{00FF00}/todo <text>{FFFFFF} - совмещение действия /me и публичного чата")
               imgui.TextColoredRGB("{00FF00}/dice{FFFFFF} - бросить кости")
               imgui.TextColoredRGB("{00FF00}/coin{FFFFFF} - бросить монетку")
               imgui.TextColoredRGB("{00FF00}/shout | /s <text>{FFFFFF} - крикнуть")
               imgui.TextColoredRGB("{00FF00}/me <text>{FFFFFF} - отыграть действие")
               imgui.TextColoredRGB("{00FF00}/ame <text>{FFFFFF} - отыграть действие (текст над персонажем)")
               imgui.TextColoredRGB("{00FF00}/do <text>{FFFFFF} - описать событие")
               imgui.TextColoredRGB("{00FF00}/b <text>{FFFFFF} - OOC чат")
               imgui.TextColoredRGB("{00FF00}/m <text>{FFFFFF} - сказать что то в мегафон")
               imgui.TextColoredRGB("{00FF00}/channel <0-500>{FFFFFF} - установить радио канал")
               imgui.TextColoredRGB("{00FF00}/r <text>{FFFFFF} - отправить сообщение в рацию")
               imgui.TextColoredRGB("{00FF00}/f <text>{FFFFFF} - отправить сообщение в чат команды /team")
               imgui.TextColoredRGB("{00FF00}/pm <id> <text>{FFFFFF} - отправить игроку приватное сообщение")
               imgui.TextColoredRGB("{00FF00}/reply | /rep <text>{FFFFFF} - ответить на последнее приватное сообщение")
               imgui.TextColoredRGB("{00FF00}/pchat <create|invite|accept|leave|kick>{FFFFFF} - управление персональным чатом")
               imgui.TextColoredRGB("{00FF00}/c <text>{FFFFFF} - отправить сообщение в персональный чат")
               imgui.TextColoredRGB("{00FF00}/ask <text>{FFFFFF} - задать вопрос по функционалу сервера для всех игроков")
               imgui.TextColoredRGB("{00FF00}/mute{FFFFFF} - выключить определенный чат")
               imgui.TextColoredRGB("{00FF00}/ignore <id>{FFFFFF} - занести игрока в черный список")
               imgui.TextColoredRGB("{00FF00}/unignore <id | all>{FFFFFF} - вынести игрока из черного списка | all - очистить черный список")
               imgui.TextColoredRGB("{00FF00}/ignorelist{FFFFFF} - посмотреть черный список")
            end
         end
		 if imgui.CollapsingHeader(u8"Горячие клавиши:") then
            imgui.TextColoredRGB("{00FF00}CTRL + O{FFFFFF} — скрыть-показать ид объектов рядом")
            if isTraining then
               imgui.TextColoredRGB("{00FF00}Клавиша M{FFFFFF} — меню управления миром")
               imgui.TextColoredRGB("{00FF00}Клавиша N{FFFFFF} — включить режим редактирования")
               imgui.TextColoredRGB("В режиме ретекстур:")
               imgui.TextColoredRGB("Управление: {00FF00}Y{FFFFFF} - Текстура наверх {00FF00}N{FFFFFF} - текстура вниз")
               imgui.TextColoredRGB("{00FF00}Num4{FFFFFF} Предыдущая страница, {00FF00}Num6{FFFFFF} Следующая страница")
               imgui.TextColoredRGB("{00FF00}Пробел{FFFFFF} - принять.")
            end
            if isAbsolutePlay then
		       imgui.TextColoredRGB("{00FF00}Клавиша N{FFFFFF} — меню редактора карт (в полете)")
               imgui.TextColoredRGB("{00FF00}Клавиша J{FFFFFF} — полет в наблюдении (/полет)")
               imgui.TextColoredRGB("{00FF00}Боковые клавиши мыши{FFFFFF} — отменяют и сохраняют редактирование объекта")
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
            imgui.TextColoredRGB("{FFFFFF}Используйте {00FF00}клавишу бега{FFFFFF}, для перемещения камеры во время редактирования")
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
         
         if isTraining then
            imgui.TextColoredRGB("Texture Studio Commands")
			imgui.SameLine()
			imgui.Link("https://github.com/ins1x/mtools/wiki/Texture-Studio-Commands", "MTOOLS wiki")
         end
		 
      elseif tabmenu.info == 7 then

	   imgui.Spacing()
	   imgui.Text(u8"Общее")
	   imgui.Spacing()
	   
	   if imgui.CollapsingHeader(u8'Что такое виртуальный мир?') then
          imgui.Text(u8"Виртуальный мир это функция которая позволяет отделить игрока от других игроков\nпоместив его в отдельный виртуальный экземпляр мира.\nПричем функция не просто делает игроков невидимыми, а вообще не обрабатывает\nтранспортные средства или другие объекты из других виртуальных миров.")
       end
	   
       if imgui.CollapsingHeader(u8'Что такое зона стрима?') then
          imgui.Text(u8"Это область в которой для игрока будут отображаться элементы.\nТакие как объекты, пикапы, контрольные точки, значки карт, 3D-тексты, актеры и другие. По-умолчанию зона стрима - 300 метров\n\n")
       end
	   
	   if imgui.CollapsingHeader(u8'Статические и динамические объекты в чем разница?') then
	      imgui.Text(u8"Чтобы понять разницу нужно немного углубиться в кодовую базу.\nВ SA:MP cтатический объект создается через функцию CreateObject,\nа динамический CreateDynamicObject.\nДинамические объекты начинают прорисовываться на определенном расстоянии\nзаданном в настройках стримера, а статические как указано в настройках сервера.\nМожно создать всего 1000 статических объектов!\nОсновные понятия:\n- Динамические объекты - это объекты, пикапы, иконки, 3D тексты\nзоны, чекпоинты в целом обрабатываемые стримером.\n- Динамические зоны - виртуальная зона, представляет собой\nтолько точки в пространстве объединенные в логическую зону.")
	   end
       
       if imgui.CollapsingHeader(u8'Почему не стоит размещать объекты за пределами игровой зоны') then
	      imgui.Text(u8"Игровой зоной считается диапазон от -3000 до 3000 по координатам X, Y.\nНахождение вне этих координат, вызывает игровые аномалии, такие как:\nРассинхронизация транспорта/игроков\nОтсутствие урона от ближнего боя\nАномальное поведение объектов маппинга и пикапов, аномальные блики экрана\nнеправильное позиционирование камеры игрока\n")
	   end
       
       imgui.Spacing()
       imgui.Text(u8"Советы по маппингу")
	   imgui.Spacing()
       
       if imgui.CollapsingHeader(u8'Как исправить рябь на стыках?') then
          imgui.Text(u8"Рябь на стыках появляется в следствие наложения объектов.\nДля исправления нужно сместить объект чуть в сторону,\nлибо ниже (достаточно сдвинуть на 0.0001).\nМногие ошибочно считают что flickr устранит это мерцание — нет,\nплагин не решает проблему плохо сведенных между собой объектов")
       end
	   
	   if imgui.CollapsingHeader(u8'Как убрать засветы и тени?') then
          imgui.Text(u8"Их скрывают при помомщи Невидимых текстур.\nОдна из таких текстур - ID 19962 (Index 8955 в «Texture Studio»)\nДанная текстура очень полезна при сокрытии некоторых несовершенств\nдефолтных объектов GTA SA и при создании каких-либо новых объектов.")
       end
	   
	   if imgui.CollapsingHeader(u8'Как создается зеркальный пол?') then
	      imgui.Text(u8"В GTA есть стандартные интерьеры, в которых такой пол встречается.\nИ вокруг них есть небольшая зона, в которой есть зеркальное отражение.\nНазываются они cull zones.\nВ МapСonstructor возможно их все вывести на экран и чётко увидеть их границы\nТо есть, чтоб получить зеркальный пол, Вам нужно:\n- 1. Создать объект в области cull zone.\n- 2. Наложить на него текстуру и сделать её немного прозрачной.\n")
       end
       
       if imgui.CollapsingHeader(u8'Как создать движущийся текст?') then
	      imgui.Text(u8"Создать объект 7313(vgsN_scrollsgn01) и наложить текст на него\nлибо использовать объект воды из водопада 19842(WaterFallWater1).")
	   end

       if imgui.CollapsingHeader(u8'Создание прозрачных/Невидимых объектов') then
	      imgui.Text(u8"Создаются через функцию SetObjectMaterial.\nУказываем имя библиотеки с текстурой и текстуры как 'none'.\nПараметр materialcolor устанавливаем в 0x00000000 (0).\nMaterialIndex - обозначает ID слоя материала объекта.\nИногда объекты имеют 2 и более различных типов текстур.\nЭто означает, что есть 2 и более слотов (слоёв) в индексах.\nВ таком случае необходимо указывать прозрачность каждому слою.")
	   end
       
       if imgui.CollapsingHeader(u8'Как рассчитывается угол поворота?') then
	      imgui.Text(u8"Угол поворота используется для позиционирования вращений объекта.\n0 значением, как и в компасе является Север.\nДиапазоном является обычный круг 0-359.9 градусов\nИспользуя например /rz в положительном значении,\nвы всегда будете поворачивать объект против часовой стрелки,\nсоответственно в отрицательном - против.\n")
	   end
       
	   imgui.Spacing()
        if isTraining then
           imgui.Text(u8"TRAINING FAQ")
           imgui.Spacing()
           
           if imgui.CollapsingHeader(u8'Как сделать "картинку" в /otext?') then
	          imgui.Text(u8"Ввести букву/цифру в текст с использованием шрифта:\nGTAWeapon3, Webdings и Wingdings")
	       end
           
           if imgui.CollapsingHeader(u8'Как изменить спавн в мире?') then
	          imgui.Text(u8"Необходимо создать установить и настроить тиму через /team\nВ появившемся диалоге выбрать слот под тиму, далее указать название и нажать спаун.\nПосле этого в меню /vw появится пункт 'Команда по-умолчанию'.\nВ котором и задается тима (и спавн) по-умолчанию")
	       end
           
           if imgui.CollapsingHeader(u8'Как изменить текстуру у объекта?') then
	          imgui.Text(u8"Изменить текстуру можно командой /stexture <id> <slot>, где\nid - локальный ид объекта\nslot - индекс(слой) для изменения материала 0-16\nЛибо сменить через /tsearch <id> <text>, где text - текст для поиска.\n(Переключение на num4 и num6, выбор клавиша бега 'по-умолчанию - пробел')")
	       end
           
           if imgui.CollapsingHeader(u8'Как включить-отключить отображение ID на объекте?') then
	          imgui.Text(u8"Включить режим разработки: /vw - Режим разработки - ON")
	       end
           
           if imgui.CollapsingHeader(u8'Что такое КБ - Командный блок?') then
	          imgui.Text(u8"Это логические блоки позволяющие игрокам создавать\nуникальный функционал для игровых миров.\nВы можете задавать последовательности различных действий\nи обработку условий по множеству параметров.")
              imgui.Link("https://forum.training-server.com/d/4466", u8"Подробнее на форуме")
	       end
           
           if imgui.CollapsingHeader(u8'Текстовые команды (функции) КБ?') then
	          imgui.Text(u8"Текстовые команды (функции) - команды которые вы можете использовать внутри КБ\nв качестве условий для проверки, получения данных а так-же арифметики.\nТекстовые команды используются в двух форматах - глобальная функция и под.функция.\n- Глобальная функция записывается через символ “ # ”,\n- подфункция “ ` ” (клавиша Ё в анг.регистре).\n")
              imgui.Link("https://forum.training-server.com/d/10021-tekstovye-komandy-funktsii-kb", u8"Подробнее на форуме")
	       end
           
           if imgui.CollapsingHeader(u8'Что такое Массивы и зачем они нужны?') then
	          imgui.Text(u8"Массивы нужны для того, чтобы хранить в них данные игрока, сервера и т.д\nПредставьте, что массивы, это ящик, в котором \nвы будете хранить нужную информацию\nВ отличии от переменных массивы начинаются с нуля,\nи в них можно хранить только целое число!\n")
              imgui.Link("https://forum.training-server.com/d/19291-osnovy-osnov/9", u8"Подробнее на форуме")              
	       end
           
           if imgui.CollapsingHeader(u8'Как просмотреть информацию в массиве?') then
	          imgui.Text(u8"Для просмотра массива игрока, используйте команду /data [ ID ]\n")
	       end
           
           if imgui.CollapsingHeader(u8'Как пользоваться переменными?') then
	          imgui.Text(u8"В переменных вы можете хранить целые числа, десятичные дроби и текст.\nЭти данные вы сможете использовать в командных блоках\nПеременные нужны для хранения текстовых значений и для того\nчтобы удобнее было возвращать то или инное значение.\n/pvarlist - Посмотреть список всех созданных переменных\n/pvar [ ID игрока ] - Посмотреть список переменных игрока\n/varlist - Посмотреть список всех переменных мира\nПеременные мира сохраняются в бд (При включенной опции сохранения БД в /vw)\nа вот массивы сервера, машин и объектов после перезапуска мира обнуляются")
	       end
           
           if imgui.CollapsingHeader(u8'Что такое Аллиас(Allias)?') then
	          imgui.Text(u8"Аллиас - это тоже самая что и команда, только привязка идет на КБ\nВАЖНО! При создании аллиасов Не пишите // в аллиас!!\nСервер автоматически подставит значение\n")
	       end
           
           if imgui.CollapsingHeader(u8'Как сохранить-загрузить мир?') then
	          imgui.Text(u8"Открыть меню /vw - Управление игровым миром - Сохранить/загрузить виртуальный мир\n")
	       end
           
           if imgui.CollapsingHeader(u8'Как сделать мир статичным?') then
              imgui.Link("https://forum.training-server.com/d/10501-kak-sdelat-mir-statichnym", u8"Внимательно ознакомиться с темой на форуме")
              imgui.Text(u8"Привести мир в соответвие с требованиями:")
              imgui.Text(u8"-Мир должен быть полностью автономным.\n-На протяжение 3х дней после подачи заявки, в теме должен быть отчет\nскрины или видео с онлайном мира и игроками.\n(Скрины подойдут любые из игрового процесса.)\n-Все изменения / обновления мира должны сообщаться в теме.")
           end
           
           imgui.Spacing()
           imgui.Text(u8"Ошибки и баги")
           imgui.Spacing()
           
           if imgui.CollapsingHeader(u8'После ретекстура объект не редактируется через /sel, /csel, /oe') then
              imgui.Text(u8"В таком случае воспользуйтесь /olist")
           end
           
        end
        
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
              imgui.Text(u8"Такая ошибка появляется если вы создали много объектов в одной области.\nВ радиусе 150 метров нельзя создавать больше 200 объектов.\nЭто сигнал о том что ваша локация перегружена объектами\nи стоит провести оптимизацию и очистить эту область.\n")
           end
           
           if imgui.CollapsingHeader(u8'Ошибка. Создано максимум объектов') then
              imgui.Text(u8"Нужно увеличить лимит.\nY - Редактор карт - Управление мирами - Повышение лимита объектов. ")
           end
           
           if imgui.CollapsingHeader(u8'Ошибка. Максимальное количество созданных миров - 500') then
              imgui.Text(u8"Невозможно создать мир, нет свободных слотов.\nМожно ждать пока освободится слот,\nлибо купить мир у игрока.")
           end
           
           if imgui.CollapsingHeader(u8'Ошибка. Античит отправил тебя на место появления') then
              imgui.Text(u8"Это может происходить если вы без аддона уходите в афк на большой высоте,\nлибо если вы находитесь афк над водой.")
           end

           if imgui.CollapsingHeader(u8'Ошибка. Транспорт мира не создан. Транспорта в мире нет') then
              imgui.Text(u8"Может появиться если вы не создали транспорт через меню транспорта,\nно пытаетесь при этом применить к нему какие-либо действия.")
           end     
           
           if imgui.CollapsingHeader(u8'Ошибка. Установи 0.3DL чтоб включать полет в этом месте') then
              imgui.Text(u8"Необходимо устанавливать новый DL клиент с samp-ru,\nлибо уходить в полет с другой точки где мало объектов рядом (выйти из зоны стрима).")
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
         if isAbsolutePlay then
	        imgui.Text(u8"Интерфейс взаимодействия с сайтом")
		    imgui.SameLine()
		    imgui.SameLine()
            imgui.PushItemWidth(120)
	        imgui.Combo(u8'##ComboBoxSelectSiteLogSrc', combobox.sitelogsource, absServersNames, 6)
	        imgui.PopItemWidth()
		    
            local serverprefix = ""
            if combobox.sitelogsource.v == 0 then
               serverprefix = string.lower(absServersNames[1])
            elseif combobox.sitelogsource.v == 1 then
               serverprefix = string.lower(absServersNames[2])
            elseif combobox.sitelogsource.v == 2 then
               serverprefix = string.lower(absServersNames[3])
            elseif combobox.sitelogsource.v == 3 then
               serverprefix = string.lower(absServersNames[4])
            elseif combobox.sitelogsource.v == 4 then
               serverprefix = string.lower(absServersNames[5])
            elseif combobox.sitelogsource.v == 5 then
               serverprefix = string.lower(absServersNames[6])
            end
            
		    if imgui.Button(u8"Логи действий администрации",imgui.ImVec2(230, 25)) then
		       os.execute('explorer https://gta-samp.ru/adminhistory-'..serverprefix)
		    end
            imgui.SameLine()
		    if imgui.Button(u8"Логи смены никнеймов",imgui.ImVec2(230, 25)) then
		       os.execute('explorer https://gta-samp.ru/nickchange-'..serverprefix)
		    end 
		    
		    if imgui.Button(u8"История регистрации аккаунтов",imgui.ImVec2(230, 25)) then
		       os.execute('explorer https://gta-samp.ru/reg-'..serverprefix)
		    end
            imgui.SameLine()
            if combobox.sitelogsource.v == 0 then
		       if imgui.Button(u8"Полный список правил",imgui.ImVec2(230, 25)) then
		          os.execute('explorer https://forum.sa-mp.ru/index.php?/topic/802952-%D0%BF%D1%80%D0%B0%D0%B2%D0%B8%D0%BB%D0%B0-dm-%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0/')
               end
            elseif combobox.sitelogsource.v == 1 then
		       if imgui.Button(u8"Полный список правил",imgui.ImVec2(230, 25)) then
		          os.execute('explorer https://forum.gta-samp.ru/index.php?/forum/125-%D0%B2%D0%B0%D0%B6%D0%BD%D0%BE-%D0%B7%D0%BD%D0%B0%D1%82%D1%8C/')
               end
            elseif combobox.sitelogsource.v == 2 then
		       if imgui.Button(u8"Полный список правил",imgui.ImVec2(230, 25)) then
		          os.execute('explorer https://forum.gta-samp.ru/index.php?/forum/108-%D0%B8%D0%BD%D1%84%D0%BE%D1%80%D0%BC%D0%B0%D1%86%D0%B8%D1%8F-%D0%B8-%D0%BF%D1%80%D0%B0%D0%B2%D0%B8%D0%BB%D0%B0/')
               end
            elseif combobox.sitelogsource.v == 3 then
		       if imgui.Button(u8"Полный список правил",imgui.ImVec2(230, 25)) then
		          os.execute('explorer https://forum.gta-samp.ru/index.php?/forum/177-%D0%B2%D0%B0%D0%B6%D0%BD%D0%BE-%D0%B7%D0%BD%D0%B0%D1%82%D1%8C/')
               end
            elseif combobox.sitelogsource.v == 4 then
		       if imgui.Button(u8"Полный список правил",imgui.ImVec2(230, 25)) then
		          os.execute('explorer https://forum.gta-samp.ru/index.php?/forum/200-%D0%B2%D0%B0%D0%B6%D0%BD%D0%BE-%D0%B7%D0%BD%D0%B0%D1%82%D1%8C/')
               end
            elseif combobox.sitelogsource.v == 5 then
		       if imgui.Button(u8"Полный список правил",imgui.ImVec2(230, 25)) then
		          os.execute('explorer https://forum.gta-samp.ru/index.php?/forum/392-%D0%B2%D0%B0%D0%B6%D0%BD%D0%BE-%D0%B7%D0%BD%D0%B0%D1%82%D1%8C/')
               end
		    end
		    
		    if imgui.Button(u8"Администрация онлайн",imgui.ImVec2(230, 25)) then
		       sampSendChat("/admin")
		   	dialog.main.v = not dialog.main.v 
		    end
            if combobox.sitelogsource.v == 0 then
		       imgui.SameLine()
		       if imgui.Button(u8"Список администрации на сайте",imgui.ImVec2(230, 25)) then
		          os.execute('explorer "https://forum.gta-samp.ru/index.php?/topic/655150-%D1%81%D0%BF%D0%B8%D1%81%D0%BE%D0%BA-%D0%B0%D0%B4%D0%BC%D0%B8%D0%BD%D0%BE%D0%B2/"') 
		       end
            end
            
            if imgui.Button(u8"Список транспорта и хвр-ки", imgui.ImVec2(230, 25)) then
		       os.execute('explorer "https://forum.sa-mp.ru/index.php?/topic/1023608-faq-%D1%81%D0%BF%D0%B8%D1%81%D0%BE%D0%BA-%D1%82%D1%80%D0%B0%D0%BD%D1%81%D0%BF%D0%BE%D1%80%D1%82%D0%B0-%D1%81%D0%BA%D0%BE%D1%80%D0%BE%D1%81%D1%82%D1%8C-%D0%BD%D0%B5%D0%BE%D0%B1%D1%85%D0%BE%D0%B4%D0%B8%D0%BC%D1%8B%D0%B9-%D1%83%D1%80%D0%BE%D0%B2%D0%B5%D0%BD%D1%8C-%D1%86%D0%B5%D0%BD%D0%B0/"') 
		    end
            imgui.SameLine()
		    if imgui.Button(u8"Все о SAMP Addon",imgui.ImVec2(230, 25)) then
		       os.execute('explorer "https://forum.sa-mp.ru/index.php?/topic/1107880-%D0%B2%D1%81%D0%B5-%D0%BE-samp-addon/#comment-8807432"') 
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
                  local link = string.format('explorer "https://gta-samp.ru/adminhistory-'..serverprefix..'?year=%i&month=%i&searchtext=%s"',
		   	      os.date('%Y'),os.date('%m'), u8:decode(textbuffer.findlog.v))
		   	      os.execute(link)
		   	      print(link)
		   	   end
		    end
		    
		    imgui.Text(u8"Узнать историю аккаунта:")
		    if chosenplayer then
               local nickname = sampGetPlayerNickname(chosenplayer)
               local ucolor = sampGetPlayerColor(chosenplayer)
               
		   	imgui.SameLine()
               imgui.Selectable(string.format(u8"выбрать игрока %s[%d]", nickname, chosenplayer))
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
                     local link = 'explorer "https://gta-samp.ru/server-'..serverprefix..'?Nick='..u8:decode(textbuffer.ckeckplayer.v)..'"'
		   	      os.execute(link)
		   	   end
		    end 
		    imgui.SameLine()
		    if imgui.Button(u8"по номеру аккаунта",imgui.ImVec2(150, 25)) then
		   	   if string.len(textbuffer.ckeckplayer.v) > 0 and tonumber(textbuffer.ckeckplayer.v) then
                     local link = 'explorer "https://gta-samp.ru/server-'..serverprefix..'?Accid='..u8:decode(textbuffer.ckeckplayer.v)..'"'
		   	      os.execute(link)
		   	   end
		    end 
		 end
         if isTraining then
            imgui.TextColoredRGB("Интерфейс взаимодействия с сайтом {a57c00}TRAINING")
            imgui.Spacing()
            if imgui.Button(u8"Рейтинг игроков",imgui.ImVec2(230, 25)) then
		       os.execute('explorer https://training-server.com/stats')
		    end
            imgui.SameLine()
            if imgui.Button(u8"Лог админ действий",imgui.ImVec2(230, 25)) then
		       os.execute('explorer "https://training-server.com/api/admin"')
		    end
            
            if imgui.CollapsingHeader(u8"Информация на форуме") then
               imgui.Link("https://forum.training-server.com/d/4466", u8"Командные блоки (Описание/Туториалы)")
               imgui.Link("https://forum.training-server.com/d/14526-triger-bloki-i-princip-ix-raboty", u8"Тригер блоки и принцип их работы")
               imgui.Link("https://forum.training-server.com/d/6166-kollbeki", u8"Коллбэки")
               imgui.Link("https://forum.training-server.com/d/19134-pomosch-v-textdraw", u8"Помощь в TextDraw")
               imgui.Link("https://forum.training-server.com/d/4727", u8"Анимации для КБ")
               imgui.Link("https://forum.training-server.com/t/cmb-help", u8"Вопросы про командные блоки")
               imgui.Link("https://forum.training-server.com/t/cmb-info", u8"Подраздел с информацией (текстовые команды, коллбэки и т.д.)")
               imgui.Link("https://forum.training-server.com/t/cmb-less", u8"Уроки по командным блокам")
               imgui.Link("https://forum.training-server.com/t/cmb-sol", u8"Подраздел готовых решений КБ")
            end
            
            imgui.Text("")
		    imgui.Text(u8"Поиск на форуме по ключевому слову:")
		    imgui.PushItemWidth(385)
		    if imgui.InputText("##FindLogs", textbuffer.findlog) then
            end
		    imgui.PopItemWidth()
		    imgui.SameLine()
		    if imgui.Button(u8"Найти",imgui.ImVec2(70, 25)) then
     	       if string.len(textbuffer.findlog.v) > 0 then
                  local link = string.format('explorer "https://forum.training-server.com/?q="',
		   	      os.date('%Y'),os.date('%m'), u8:decode(textbuffer.findlog.v))
		   	      os.execute(link)
		   	      print(link)
		   	   end
		    end
            
            imgui.Spacing()
            imgui.Text(u8"Статистика аккаунта по никнейму:")
		    if chosenplayer then
               local nickname = sampGetPlayerNickname(chosenplayer)
               local ucolor = sampGetPlayerColor(chosenplayer)
               
		   	imgui.SameLine()
               imgui.Selectable(string.format(u8"выбрать игрока %s[%d]", nickname, chosenplayer))
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
		    if imgui.Button(u8"Найти",imgui.ImVec2(70, 25)) then
		   	   if string.len(textbuffer.ckeckplayer.v) > 0 then
                  local link = 'explorer "https://training-server.com/api/user/'..u8:decode(textbuffer.ckeckplayer.v)..'"'
		   	      os.execute(link)
		   	   end
		    end 
            imgui.Spacing()
         end
		 imgui.Spacing()
      end -- end tabmenu.info
		 
      imgui.NextColumn()

      if imgui.Button(u8"Объекты", imgui.ImVec2(100,25)) then tabmenu.info = 5 end
      if imgui.Button(u8"Лимиты", imgui.ImVec2(100,25)) then tabmenu.info = 2 end
      if imgui.Button(u8"Цвета", imgui.ImVec2(100,25)) then tabmenu.info = 3 end
      if imgui.Button(u8"Ретекстур", imgui.ImVec2(100,25)) then tabmenu.info = 4 end
      if imgui.Button(u8"Команды", imgui.ImVec2(100,25)) then tabmenu.info = 6 end
      if imgui.Button(u8"FAQ", imgui.ImVec2(100,25)) then tabmenu.info = 7 end
      if isAbsolutePlay or isTraining then
         if imgui.Button(u8"Форум", imgui.ImVec2(100,25)) then tabmenu.info = 8 end
      end
      if imgui.Button(u8"About", imgui.ImVec2(100, 25)) then tabmenu.info = 1 end

      imgui.Columns(1)
      
      elseif tabmenu.main == 4 then
      
         imgui.Columns(2)
         imgui.SetColumnWidth(-1, 490)
        
         local ip, port = sampGetCurrentServerAddress()
         local servername = sampGetCurrentServerName()
         
         imgui.TextColoredRGB("Сервер: {007DFF}" .. servername)
         --imgui.SameLine()
         --imgui.TextColoredRGB("IP:  {686868}" .. tostring(ip) ..":".. tostring(port))
         imgui.TextColoredRGB("Дата: {686868}" .. os.date('%d.%m.%Y %X'))
         if mpStartedDTime ~= nil then
            imgui.SameLine()
            imgui.TextColoredRGB("Началось МП в {686868}" .. mpStartedDTime)
         end
         imgui.Spacing()
         
         if tabmenu.mp == 1 then
            if combobox.profiles.v ~= 0 then
               imgui.Text(u8" Выбрано мероприятие: ")
            else
               imgui.Text(u8"Выберите мероприятие: ")
            end
            
	        imgui.SameLine()
	        imgui.PushItemWidth(140)
	        if imgui.Combo(u8'##ComboBoxProfiles', combobox.profiles, profilesNames, #profilesNames) then
               if combobox.profiles.v then cleanBindsForm() end
               if combobox.profiles.v == 0 then
	 	          reloadBindsFromConfig()
	 	          sampAddChatMessage('Загружен профиль Custom из конфига', -1)
                  if string.len(textbuffer.mpname.v) < 1 then
                     textbuffer.mpname.v = u8('Заходите на МП ')
                  end
                  if string.len(textbuffer.rule1.v) < 1 then
                     textbuffer.rule1.v = u8("Введите свои правила для мероприятия сюда")
                  end
               end
               if combobox.profiles.v == 1 then
	 	          textbuffer.rule1.v = u8("Разрешено использовать починку транспорта")
                  textbuffer.rule2.v = u8("Разрешено в случае смерти продолжить игру начиная от спавна")
                  textbuffer.rule3.v = u8("Разрешено в случае вылета за границы трассы, продолжить игру начиная от места вылета")
                  textbuffer.rule4.v = u8("Разрешено при поломке транспорта и невозможноcти починки, заказать его еще раз")
                  textbuffer.rule5.v = u8("Разрешено на данном мероприятии играть без samp addon и последней версии клиента")
                  textbuffer.mpname.v = u8('Заходите на МП Гонки')
	 	     	  sampAddChatMessage('Загружен профиль Race', -1)
               end
               if combobox.profiles.v == 2 then
	 	          textbuffer.rule1.v = u8("Запрещено использовать текстурные баги")
	 	          textbuffer.rule2.v = u8("Запрещено покидать транспорт - дисквалификация")
	 	          textbuffer.rule3.v = u8("Вы выбываете с игры в случае вылета за пределы арены")
	 	          textbuffer.rule4.v = u8("Вы выбываете с игры в случае уничтожения транспорта")
	 	          textbuffer.rule5.v = u8("Победит последний выживший игрок")
                  textbuffer.mpname.v = u8('Заходите на МП Дерби')
	 	     	  sampAddChatMessage('Загружен профиль Derby', -1)
	 	       end
               if combobox.profiles.v == 3 then
	 	          textbuffer.rule1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
                  textbuffer.rule2.v = u8("Запрещены объединения более 2-х игроков")
                  textbuffer.rule3.v = u8("Запрещено находиться в афк после начала мероприятия")
                  textbuffer.mpname.v = u8('Заходите на МП Выживание')
                  sampAddChatMessage('Загружен профиль Survival', -1)
               end
               if combobox.profiles.v == 4 then
	 	          textbuffer.rule1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
	 	          textbuffer.rule2.v = u8("После получения оружия ждем отсчета, начинаем только после окончания отсчета!")
	 	          textbuffer.rule3.v = u8("Если вы выстрелили раньше окончания отсчета - дисквалификация")
	 	          textbuffer.rule4.v = u8("Если вы прошли во второй тур и находитесь афк - дисквалификация")
	 	          textbuffer.mpname.v = u8('Заходите на МП Кемпа')
	 	          sampAddChatMessage('Загружен профиль PvP', -1)
	 	       end
	 	       if combobox.profiles.v == 5 then
	 	          textbuffer.rule1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
	 	          textbuffer.rule2.v = u8("Игроки которые упали с крыши - выбывают")
	 	          textbuffer.rule3.v = u8("Использование анимок и спец.действий запрещено!")
	 	          textbuffer.rule4.v = u8("Запрещено запрыгивать на транспорт организаторов")
	 	          textbuffer.mpname.v = u8('Заходите на МП Смертельная крыша')
	 	          sampAddChatMessage('Загружен профиль Death-Roof', -1)
	 	       end
               if combobox.profiles.v == 6 then
	 	          textbuffer.rule1.v = u8("Запрещено создавать помеху игрокам при помощи багов и недоработок игры")
                  textbuffer.rule2.v = u8("Не мешаем другим игрокам, ждем начала")
                  textbuffer.rule3.v = u8("Приз выдается в равном размере каждому участнику победившей команды")
                  textbuffer.mpname.v = u8('Заходите на МП TDM')
                  sampAddChatMessage('Загружен профиль TDM', -1)
               end
	 	       if combobox.profiles.v == 7 then
	 	          textbuffer.rule1.v = u8("Запрещено прятаться в текстурах и объектах")
	 	          textbuffer.rule2.v = u8("Запрещено использовать баги и недоработки игры для победы")
	 	          textbuffer.mpname.v = u8('Заходите на МП Прятки')
                  sampAddChatMessage('Загружен профиль Hide-n-Seek', -1)
	 	       end
	 	       if combobox.profiles.v == 8 then
	 	          textbuffer.rule1.v = u8("Организатор задает вопрос, а вы должны дать ответ быстрее всех")
	 	          textbuffer.rule2.v = u8("Кто первый ответ на заданный вопрос, получает балл")
	 	          textbuffer.rule3.v = u8("Игра продолжается пока кто-либо не наберет 3 балла")
	 	          textbuffer.rule4.v = u8("Не рекомендуется флудить и спамить в чат")
	 	          textbuffer.rule5.v = u8("Гугол, Яндекс и ChatGPT вам не помошники, вопросы специфические =)")
	 	          textbuffer.mpname.v = u8('Проходит МП Викторина на тему')
                  sampAddChatMessage('Загружен профиль Quiz', -1)
	 	       end
               if combobox.profiles.v == 9 then
	 	          textbuffer.rule1.v = u8("Победителем становится последний оставшийся в живых игрок")
	 	          textbuffer.rule2.v = u8("Запрещено пополнять хп любыми способами")
	 	          textbuffer.rule3.v = u8("Запрещено тимиться и уходить от боя багами")
                  textbuffer.mpname.v = u8('Проходит МП Король')
                  sampAddChatMessage('Загружен профиль King', -1)
	 	       end
               if combobox.profiles.v == 10 then
	 	          textbuffer.rule1.v = u8("Победителем становится игрок который убьет жертву")
	 	          textbuffer.rule2.v = u8("Жертва будет активно передвигаться и хорошо охраняется")
                  textbuffer.mpname.v = u8('Проходит МП Охота')
                  sampAddChatMessage('Загружен профиль Hunt', -1)
	 	       end
               if combobox.profiles.v == 11 then
	 	          textbuffer.rule1.v = u8("Победителем становится игрок который останется последним на самолете")
	 	          textbuffer.rule2.v = u8("Разрешено использовать любые анимации")
                  textbuffer.mpname.v = u8('Проходит МП Родео')
                  sampAddChatMessage('Загружен профиль Rodeo', -1)
	 	       end
               if combobox.profiles.v == 12 then
	 	          textbuffer.rule1.v = u8("Победителем становится последний выживший игрок")
	 	          textbuffer.rule2.v = u8("Запрещено покидать транспорт во время МП")
	 	          textbuffer.rule2.v = u8("Если водителя убили или он вышел, то пассажир должен сесть за руль и продолжать начатое. ")
                  textbuffer.mpname.v = u8('Проходит МП Road Rash')
                  sampAddChatMessage('Загружен профиль Road Rash', -1)
	 	       end
            end
	        imgui.PopItemWidth()
            
            imgui.SameLine()
            if imgui.TooltipButton(u8"идеи для МП", imgui.ImVec2(100, 25), u8"Идеи для различных МП на форуме") then
               os.execute('explorer https://forum.gta-samp.ru/index.php?/topic/992819-%D0%B2%D0%B0%D1%88%D0%B8-%D0%B8%D0%B4%D0%B5%D0%B8-%D0%BF%D0%BE-%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D0%B4%D0%B5%D0%BD%D0%B8%D1%8E-%D0%BC%D0%B5%D1%80%D0%BE%D0%BF%D1%80%D0%B8%D1%8F%D1%82%D0%B8%D0%B9/')
            end
            
            imgui.Text(u8"Объявление: ")
            imgui.PushItemWidth(300)
            if imgui.InputText("##BindMpname", textbuffer.mpname) then 
            end
            --imgui.InputTextWithHint('##SearchBar', textbuffer.mpname, u8'Введите текст объявления либо выберите МП', 1)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.Text(u8"Приз: ")
            imgui.SameLine()
            imgui.PushItemWidth(90)
            if imgui.InputText("##BindMpprize", textbuffer.mpprize) then
               if textbuffer.mpprize.v:find("$") then
                  --local money = getPlayerMoney(Player player)
               end
            end
            imgui.PopItemWidth()
            
            if imgui.TooltipButton(u8"Объявить МП", imgui.ImVec2(220, 25), u8"Аннонсировать МП в объявление (/об)") then
               if string.len(textbuffer.mpname.v) > 0 and string.len(textbuffer.mpprize.v) > 0 then 
                  sampSetChatInputEnabled(true)
                  sampSetChatInputText(string.format("/об %s, приз %s", u8:decode(textbuffer.mpname.v), u8:decode(textbuffer.mpprize.v)))
               else
                  sampAddChatMessage("Сперва укажите название мероприятия и приз!", -1)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(autoAnnounce and u8('Отключить авто-объявление') or u8('Включить авто-объявление'), imgui.ImVec2(220, 25), u8:encode("Автоматически шлет объявление о МП (раз в минуту)")) then
               if string.len(textbuffer.mpname.v) > 0 and string.len(textbuffer.mpprize.v) > 0 then 
                  autoAnnounce = not autoAnnounce
                  if autoAnnounce then 
                     sampAddChatMessage("В объявление будет подано: "..u8:decode(textbuffer.mpname.v)..", приз "..u8:decode(textbuffer.mpprize.v), -1)
                  end   
                  AutoAd()
               else
                  sampAddChatMessage("Сперва укажите название мероприятия и приз!", -1)
               end
            end
            
            if imgui.Checkbox(u8"Указать спонсоров", checkbox.donators) then
            end
            --imgui.SameLine()
            --if imgui.Checkbox(u8"Указать время начала МП", checkbox.donators) then
            --end
            
            if checkbox.donators.v then
               imgui.Text(u8"Укажите ники спонсоров через запятую")
               imgui.PushItemWidth(300)
               if imgui.InputText("##BindMpdonators", textbuffer.mpdonators) then 
               end
               imgui.SameLine()
               if imgui.Button(u8"Объявить спонсоров", imgui.ImVec2(140, 25)) then
                  if string.len(textbuffer.mpdonators.v) > 0 then
                     sampSetChatInputEnabled(true)
                     sampSetChatInputText("/мчат Спонсоры мероприятия: "..u8:decode(textbuffer.mpdonators.v))
                  else
                     sampAddChatMessage("Сперва укажите спонсоров мероприятия!", -1)
                  end                  
               end
            end
            
            imgui.Text(u8"Выбор капитана:")
	        if imgui.Button(u8"Игрок с наибольшим уровнем", imgui.ImVec2(220, 25)) then
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
	        imgui.SameLine()
	        if imgui.Button(u8"Выбрать случайного игрока", imgui.ImVec2(220, 25)) then
	   	       if next(playersTable) == nil then -- if playersTable is empty
	 	          sampAddChatMessage("Сперва обнови список игроков!", -1) 
	 	       else
	 	          local rand = math.random(playersTotal)
	 	          chosenplayer = playersTable[rand]                
	 	          sampAddChatMessage("Случайный игрок: ".. sampGetPlayerNickname(playersTable[rand]), -1)
	 	       end
	        end
            imgui.Text(u8"Список игроков:")
            if imgui.Button(u8"Обновить список игроков МП", imgui.ImVec2(220, 25)) then
               playersTable = {}       
               playersTotal = 0
               playersfile = io.open("moonloader/resource/abseventhelper/players.txt", "w")
               
               for k, v in ipairs(getAllChars()) do
                  local res, id = sampGetPlayerIdByCharHandle(v)
                  local nickname = sampGetPlayerNickname(id)
                  if res then
                     table.insert(playersTable, id)
                     playersTotal = playersTotal + 1
                     playersfile:write(nickname .. "\n")
                  end
               end
               playersfile:close()
               sampAddChatMessage("Список игроков на МП обновлен. Всего игроков "..playersTotal, -1)
            end
            imgui.SameLine()
            if imgui.Button(u8"Вывести список игроков", imgui.ImVec2(220, 25)) then
               sampAddChatMessage("Список игроков:", 0xFFFFFF)
               playersList = {}
               playersfile = io.open("moonloader/resource/abseventhelper/players.txt", "r")
               for name in playersfile:lines() do
                  table.insert(playersList, name:lower())
               end
               playersfile:close()
               maxPlayerOnline = sampGetMaxPlayerId(false)
               s = 1
               local res, playerId = sampGetPlayerIdByCharHandle(playerPed)
               for i = 0, maxPlayerOnline do
                  if sampIsPlayerConnected(i) then
                     name = sampGetPlayerNickname(i)
                     c = 1
                     for k,n in pairs(playersList) do
                        if(name:lower() == n:lower()) then
                           sampAddChatMessage("{FFFFFF}" .. s .. ". {34EB46}" .. name .. " (" .. i .. ")", 0xFFFFFF)
                           table.remove(playersList, c)
                           s = s + 1
                        end 
	                    c = c + 1
                     end
                  end
               end
               
               for k, n in pairs(playersList) do
                  name = sampGetPlayerNickname(playerId)
                  if(name:lower() == n:lower()) then
                     sampAddChatMessage("{FFFFFF}" .. s .. ". {CDCDCD}" .. n .. " {FFD700}(EVENTMAKER)", 0xFFFFFF)
                  else
                     sampAddChatMessage("{FFFFFF}" .. s .. ". {CDCDCD}" .. n .. " {E61920}(OFFLINE)", 0xFFFFFF)
                  end
                  s = s + 1
               end
            end
            imgui.Spacing()
            imgui.Spacing()
            imgui.Spacing()
            if imgui.TooltipButton(mpStarted and u8("Остановить мероприятие") or u8("Начать мероприятие"), imgui.ImVec2(220, 50), mpStarted and u8("Завершить МП") or u8("Готовы начать?")) then
               mpStarted = not mpStarted
               if mpStarted then
                  autoAnnounce = false
                  mpStartedDTime = os.date('%X')
                  
                  playersTable = {}       
                  playersTotal = 0
                  playersfile = io.open("moonloader/resource/abseventhelper/players.txt", "w")
                  
                  for k, v in ipairs(getAllChars()) do
                     local res, id = sampGetPlayerIdByCharHandle(v)
                     local nickname = sampGetPlayerNickname(id)
                     if res then
                        table.insert(playersTable, id)
                        playersTotal = playersTotal + 1
                        playersfile:write(nickname .. "\n")
                     end
                  end
                  playersfile:close()
                  
                  sampSendChat("/time")
                  sampAddChatMessage("МП нвчато!", -1)
                  -- if checkbox.donators.v then 
                     -- sampSendChat("/мчат Спонсоры мероприятия: "..u8:decode(textbuffer.mpdonators.v))
                  -- end 
                  --sampSetChatInputEnabled(true)
                  --sampSetChatInputText('* Начали! Желаю удачи всем игрокам')
               else
                  mpStartedDTime = nil
                  --sampSetChatInputEnabled(true)
                  --sampSetChatInputText('* МП Остановлено')
                  sampAddChatMessage("МП остановлено!", -1)
               end
            end
	        imgui.Spacing()
            
         elseif tabmenu.mp == 2 then

            imgui.PushItemWidth(150)
            imgui.Combo('##ComboWeaponSelect', combobox.weaponselect, weaponNames)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8"Выдать оружие", imgui.ImVec2(120, 25)) then
               --setVirtualKeyDown(78, true)
               setGameKeyState(10, 128)
              -- setVirtualKeyDown(0x4E, false)
            end
            imgui.Text(u8"Выдать патроны")
            imgui.Text(u8"Выставить скины")
            if imgui.Button(u8"Пополнить хп", imgui.ImVec2(220, 25)) then
               if isAbsolutePlay then
                  for k, v in pairs(playersTable) do
                     sampSendChat("/хп "..v)
                  end
               end
               if isTraining then
                  sampSendChat("/health 100")
                  sampAddChatMessage("Вы пополнили хп до 100 всем игрокам в мире", -1)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Пополнить броню", imgui.ImVec2(220, 25)) then
               if isTraining then
                  sampSendChat("/armour 100")
                  sampAddChatMessage("Вы пополнили броню до 100 всем игрокам в мире", -1)
               end
            end
            if imgui.Button(u8"Забрать оружие", imgui.ImVec2(220, 25)) then
            end
            if imgui.Button(u8"Зареспавнить игроков", imgui.ImVec2(220, 25)) then
            end
            if imgui.Button(u8"Изменить спавн", imgui.ImVec2(220, 25)) then
               if isAbsolutePlay then
                  sampAddChatMessage("Изменить спан можно в меню", 0x000FF00)
                  sampAddChatMessage("Y - Редактор миров - Управление мирами - Выбрать точку появления", 0x000FF00)
               end
            end
            if imgui.Button(u8"Заморозить", imgui.ImVec2(220, 25)) then
            end
            
         elseif tabmenu.mp == 3 then
            
            imgui.Text(u8"Дать команду в чат:")
            if imgui.Button(u8"Выдаю оружие и броню!", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Выдаю оружие и броню! После выдачи начинаем МП!')
	        end
            imgui.SameLine()
            if imgui.Button(u8"Сменил спавн!", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Изменил спавн! Не умирайте, МП скоро начнется')
	        end
            
            if imgui.Button(u8"Не стоим на месте", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Не стоим на месте, неактивные будут удалены с МП!')
	        end
            imgui.SameLine()
            if imgui.Button(u8"Все в строй", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Все в строй! Кто не в строю будет удален с МП')
	        end
            
            if imgui.Button(u8"Скоро начнем, приготовьтесь!", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Скоро начнем, занимайте позиции!')
	        end
            imgui.SameLine()
            if imgui.Button(u8"Начали!", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Желаем всем удачи, иии Начали!!')
	        end
            
            imgui.Text(u8"Предупреждения:")
            if imgui.Button(u8"Не мешаем, ждем!", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Не мешаем другим игрокам, ждем начала!')
	        end
            imgui.SameLine()
            if imgui.Button(u8"Обман = ЧС МП", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Обман организатора - черный список МП!')
	        end
            if imgui.Button(u8"АФКкик", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Игроки находящиеся в АФК будут удалены с МП')
	        end
            imgui.SameLine()
            if imgui.Button(u8"Увидели нарушителя", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Увидели лагера или нарушителя > пишите в лс')
	        end
            
            imgui.Spacing()
            
         elseif tabmenu.mp == 4 then
             imgui.ColorEdit4("##ColorEdit4lite", color, imgui.ColorEditFlags.NoInputs)
             imgui.SameLine()
             
             local prefix = ""
             if isAbsolutePlay then             
                imgui.PushItemWidth(120)
                prefixlist = {u8'мчат', u8'глобальный', u8"без префикса"}
                imgui.Combo('##ComboChatSelect', combobox.chatselect, prefixlist, #prefixlist)
                imgui.PopItemWidth()
                
                if combobox.chatselect.v == 0 then
                   prefix = "/мчат "
                elseif combobox.chatselect.v == 1 then
                   prefix = "* "
                elseif combobox.chatselect.v == 2 then
                   prefix = ""
                end
             elseif isTraining then  
                imgui.PushItemWidth(120)
                imgui.Text(u8"Чат:")
                imgui.SameLine()
                prefixlist = {u8'игрового мира', u8'модераторов', u8'глобальный', u8'ООС', u8"без префикса"}
                imgui.Combo('##ComboChatSelect', combobox.chatselect, prefixlist, #prefixlist)
                imgui.PopItemWidth()
                
                if combobox.chatselect.v == 0 then
                   prefix = "@ "
                elseif combobox.chatselect.v == 1 then
                   prefix = "$ "
                elseif combobox.chatselect.v == 2 then
                   prefix = "! "
                elseif combobox.chatselect.v == 2 then
                   prefix = "/b "
                elseif combobox.chatselect.v == 2 then
                   prefix = ""
                end
             else
                imgui.PushItemWidth(120)
                prefixlist = {u8"без префикса"}
                imgui.Combo('##ComboChatSelect', combobox.chatselect, prefixlist, #prefixlist)
                imgui.PopItemWidth()
                
                if combobox.chatselect.v == 0 then
                   prefix = ""
                end
             end
             
             imgui.SameLine()
             imgui.TextColoredRGB("МП: {696969}"..profilesNames[combobox.profiles.v+1])
             -- line 1
             imgui.Text("1.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule1", textbuffer.rule1) then 
             end
             imgui.PopItemWidth()
             -- if imgui.IsItemHovered() and imgui.IsMouseDown(1) then
                -- imgui.Text('Hovered and RMB down')
             -- end
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule1", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule1.v))
             end
             -- line 2
             imgui.Text("2.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule2", textbuffer.rule2) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule2", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule2.v))
             end
             -- line 3 
             imgui.Text("3.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule3", textbuffer.rule3) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule3", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule3.v))
             end
             -- line 4
             imgui.Text("4.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule4", textbuffer.rule4) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule4", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule4.v))
             end
             -- line 5
             imgui.Text("5.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule5", textbuffer.rule5) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule5", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule5.v))
             end
             -- line 6
             imgui.Text("6.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule6", textbuffer.rule6) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule6", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule6.v))
             end
             -- line 7
             imgui.Text("7.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule7", textbuffer.rule7) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule7", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule7.v))
             end
             -- line 8
             imgui.Text("8.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##rule8", textbuffer.rule8) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatrule8", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(textbuffer.rule8.v))
             end
             -- -- last line
             
             --imgui.SameLine()
             imgui.Spacing()
             if imgui.TooltipButton("Reload", imgui.ImVec2(60, 25), u8:encode("Перезагрузить бинды")) then 
               reloadBindsFromConfig()        
               sampAddChatMessage("Бинды были успешно презагружены из конфига", -1)
             end
             imgui.SameLine()
	         if imgui.TooltipButton("Save", imgui.ImVec2(60, 25), u8:encode("Сохранить бинды")) then 
               ini.binds.customrule1 = u8:decode(textbuffer.rule1.v)
               ini.binds.customrule2 = u8:decode(textbuffer.rule2.v)
               ini.binds.customrule3 = u8:decode(textbuffer.rule3.v)
               ini.binds.customrule4 = u8:decode(textbuffer.rule4.v)
               ini.binds.customrule5 = u8:decode(textbuffer.rule5.v)
               ini.binds.customrule6 = u8:decode(textbuffer.rule6.v)
               ini.binds.customrule7 = u8:decode(textbuffer.rule7.v)
               ini.binds.customrule8 = u8:decode(textbuffer.rule8.v)
               inicfg.save(ini, configIni)          
               sampAddChatMessage("Бинды были успешно сохранены", -1)
             end
             imgui.SameLine()
             if imgui.TooltipButton(u8"Clean", imgui.ImVec2(60, 25), u8:encode("Очистить бинды")) then
                cleanBindsForm()
             end
             
             imgui.SameLine()
             imgui.Text("            ")
             imgui.SameLine()
             if imgui.TooltipButton(u8"Анонсировать правила", imgui.ImVec2(150, 25), u8:encode("Анонсировать все правила в чат (Задержка в 2с, пустые строки игнорируются)")) then
                lua_thread.create(function()
                if string.len(textbuffer.rule1.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule1.v))
                end
                wait(2000)
                if string.len(textbuffer.rule2.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule2.v))
                end
                wait(2000)
                if string.len(textbuffer.rule3.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule3.v))
                end
                wait(2000)
                if string.len(textbuffer.rule4.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule4.v))
                end
                wait(2000)
                if string.len(textbuffer.rule5.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule5.v))
                end
                wait(2000)
                if string.len(textbuffer.rule6.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule6.v))
                end
                wait(2000)
                if string.len(textbuffer.rule7.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule7.v))
                end
                wait(2000)
                if string.len(textbuffer.rule8.v) > 1 then
                   sampSendChat(prefix..u8:decode(textbuffer.rule8.v))
                end
                wait(2000)
                end)
             end
             
	         --imgui.TextColoredRGB("* {00FF00}@ номер игрока - {bababa}заменит id на никнейм игрока.")
	         --imgui.TextColoredRGB("Цветной текст указывать через скобки (FF0000)")
             -- --imgui.Separator()
         elseif tabmenu.mp == 5 then
            imgui.Text(u8"Не забудьте после завершения мероприятия:")
            imgui.Text(u8"- Вернуть точку спавна на исходное положение")
            imgui.Text(u8"- Открыть мир для входа")
            imgui.Text(u8"- Вернуть пак оружия на стандартный")
            imgui.Spacing()
            imgui.Text(u8"Оставшиеся игроки рядом:")
            for k, v in ipairs(getAllChars()) do
		       local res, id = sampGetPlayerIdByCharHandle(v)
               local nick = sampGetPlayerNickname(id)
		       if res then
                  imgui.Text("  ")
                  imgui.SameLine()
		 	      imgui.Selectable(string.format("%d. %s", id, nick))
                  if imgui.IsItemClicked() then
                     sampSendChat("/и " .. id)
                     dialog.main.v = not dialog.main.v 
                  end
		       end
	 	    end
            imgui.Spacing()
            
            if imgui.Button(u8"Всем спасибо!", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Спасибо за участие в МП! ')
               sampAddChatMessage("Текст скопирован в строку чата", -1)
               dialog.main.v = not dialog.main.v 
	        end
            if imgui.Button(u8"Победители не выходите", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Победители не выходите! Дождитесь выдачи приза.')
               dialog.main.v = not dialog.main.v 
	        end
            if imgui.Button(u8"Объявить победителей МП", imgui.ImVec2(220, 25)) then
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
            imgui.Spacing()
         elseif tabmenu.mp == 6 then
            
            imgui.Text(u8"Разрешенное оружие: ")
            if #legalweapons > 2 then
               for k, v in pairs(legalweapons) do
                  if v > 1 then
                     imgui.SameLine()
                     imgui.Text(""..weaponNames[v]) 
                  end
               end
            end
            imgui.PushItemWidth(150)
            imgui.Combo('##ComboWeaponSelect', combobox.weaponselect, weaponNames)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.TooltipButton(u8"Добавить", imgui.ImVec2(70, 25), u8"Добавить в список разрешенных на МП") then
               if combobox.weaponselect.v == 1 or combobox.weaponselect.v == 0 then
                  sampAddChatMessage("Кулаки разрешены по-умолчанию", -1)
               elseif legalweapons[#legalweapons] == combobox.weaponselect.v then
                  sampAddChatMessage(string.format("Это оружие %s уже было добавлено в список разрешенных на МП",
                  weaponNames[combobox.weaponselect.v]),-1)
               elseif combobox.weaponselect.v == 19 or combobox.weaponselect.v == 20
               or combobox.weaponselect.v == 21 then
                  sampAddChatMessage("Пустой слот не может быть добавлен", -1)
               else
                 legalweapons[#legalweapons+1] = combobox.weaponselect.v
                 sampAddChatMessage(string.format("Оружие %s добавлено в список разрешенных на МП",
                 weaponNames[combobox.weaponselect.v]), -1)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Удалить", imgui.ImVec2(70, 25), u8"Удалить последнее выбранное оружие со списка разрешенных на МП") then
               legalweapons[#legalweapons] = nil
               sampAddChatMessage("Удалено последнее выбранное оружие со списка разрешенных", -1)
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Очистить", imgui.ImVec2(70, 25), u8"Очистить список разрешенного на МП оружия") then
               legalweapons = {0, 1}
               sampAddChatMessage("Список разрешенного на МП оружия обнулен", -1)
            end
            
            if imgui.Checkbox(u8("Проверять изменение хп и брони"), checkbox.healthcheck) then
            end
            if checkbox.healthcheck.v then
               if string.len(textbuffer.mphp.v) < 1 then 
                  textbuffer.mphp.v = '100'
               end
               if string.len(textbuffer.mparmour.v) < 1 then 
                  textbuffer.mparmour.v = '100'
               end
               imgui.PushItemWidth(50)
               imgui.InputText(u8"хп", textbuffer.mphp)
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.PushItemWidth(50)
               imgui.InputText(u8"броня", textbuffer.mparmour)
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"По умолчанию 100. Допустимые значения от 100 до 10 000")
            end
            
            if imgui.Checkbox(u8("Уведомлять о дисконнекте игроков из списка"), checkbox.disconnectreminder) then
	   	       if checkbox.disconnectreminder.v then
	 	     	  sampAddChatMessage("При вылете игроков с сервера будет выводить уведомление", -1)
	 	       else
	 	     	  sampAddChatMessage("Отключены уведомления о вылете игроков с сервера", -1)
	 	       end
	        end
	        
            if imgui.Checkbox(u8("Предупреждения на подозрительных игроков"), checkbox.playerwarnings) then
	   	       if checkbox.playerwarnings.v then
                  sampAddChatMessage("Предупреждения включены", -1)
                  isWarningsActive = true
                  PlayerWarnings()
	 	       else
	 	     	  sampAddChatMessage("Предупреждения отключены", -1)
                  isWarningsActive = false
	 	       end
	        end
            
	        -- if imgui.Checkbox(u8("Уведомлять о пополнении хп игроком"), checkbox.healthcheck) then
               -- sampAddChatMessage("Недоступно в бета версии", -1)
            -- end
            
            imgui.Spacing()
            
            imgui.Text(u8"Проверить игроков:")
	        if imgui.Button(u8"Вывести список лагеров", imgui.ImVec2(220, 25)) then
	           local counter = 0
	 	       if next(playersTable) == nil then -- if playersTable is empty
	 	          sampAddChatMessage("Сперва обнови список игроков!", -1) 
	 	       else
	              for k, v in pairs(playersTable) do
                    --local res, handle = sampGetCharHandleBySampPlayerId(v)
                    local ping = sampGetPlayerPing(v)
                    local nickname = sampGetPlayerNickname(v)
	 	     	    if(ping > 70) then
	 	     	       counter = counter + 1
	 	     	       sampAddChatMessage(string.format("Лагер %s(%i) ping: %i", nickname, v, ping), 0xFF0000)
                    end
	 	         end
	 	         if counter == 0 then
	 	            sampAddChatMessage("Лагеры не найдены", -1)
	 	         end
	           end
	        end
            imgui.SameLine()
	        if imgui.Button(u8"Вывести список игроков AFK", imgui.ImVec2(220, 25)) then
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
            
            if imgui.Button(u8"Статистика всего онлайна", imgui.ImVec2(220, 25)) then
               local totalonline = 0
	 	       local olds = 0
               local players = 0
	 	       local newbies = 0
               local bots = 0
               
	           for i = 0, sampGetMaxPlayerId(false) do
                  if sampIsPlayerConnected(i) then 
	 	             totalonline = totalonline + 1
	 	             local score = sampGetPlayerScore(i)
                     local ping = sampGetPlayerPing(i)
                     if ping <= 30 then
                        if score < 10 or score < 1000 then
                           bots = bots + 1
                        end
                     end
	 	             if score > 1000 then
	 	                olds = olds + 1
	 	             elseif score >= 50 and score < 1000 then 
                        players = players + 1
                     else 
                        newbies = newbies + 1
	 	             end
	 	          end
               end
	 	       sampAddChatMessage(string.format("Игроков в сети %i из них новички %i, постояльцы %i, олды %i (возможно боты %i)",
               totalonline, newbies, players, olds, bots), -1)
            end
            imgui.SameLine()
            if imgui.Button(u8"Черный список игроков", imgui.ImVec2(220, 25)) then
               sampAddChatMessage("Черный список:", -1)
               blacklist = {}
               blacklistfile = io.open("moonloader/resource/abseventhelper/blacklist.txt", "r")
               for name in blacklistfile:lines() do
                  table.insert(blacklist, name:lower())
               end
               io.close(blacklistfile)
               s = 1
               for k, n in pairs(blacklist) do
                  sampAddChatMessage("{363636}" .. s .. ". {FF0000}" .. n, 0xFFFFFF)
                  s = s + 1
               end
            end
            
            if imgui.Button(u8"Игроки с оружием", imgui.ImVec2(220, 25)) then
               local armedplayerscounter = 0
               for k, v in ipairs(getAllChars()) do
                  local res, id = sampGetPlayerIdByCharHandle(v)
                  if res then
                     local nick = sampGetPlayerNickname(id)
                     local weaponid = getCurrentCharWeapon(v)
                     if weaponid ~= 0 and weaponid ~= 1 then
                        armedplayerscounter = armedplayerscounter + 1
                        sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] с оружием %s (id:%d)!", nick, id, weaponNames[weaponid], weaponid), -1)
                     end
                  end
               end
               if armedplayerscounter == 0 then
                  sampAddChatMessage("Не найдено игроков с оружием", -1)
               else
                  sampAddChatMessage("Всего игроков с оружием: "..armedplayerscounter, -1)
               end
            end
            
            -- if imgui.Button(u8"Игроки с NonRP никами", imgui.ImVec2(220, 25)) then
               -- local nonrp = 0
               -- for k, i in pairs(playersTable) do
                  -- if sampIsPlayerConnected(i) then 
		             -- local nickname = sampGetPlayerNickname(i)
                     -- if not nickname:find("_") then
                        -- nonrp = nonrp + 1
                        -- sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] с NonRP ником", nickname, i), -1)
                     -- end
                  -- end 
               -- end
               -- if nonrp == 0 then
                  -- sampAddChatMessage("Не найдено игроков с NonRP никами", -1)
               -- else
                  -- sampAddChatMessage("Всего игроков: "..nonrp, -1)
               -- end
            -- end
            imgui.SameLine()
            if imgui.Button(u8"Игроки с малым уровнем", imgui.ImVec2(220, 25)) then
               local minscore = 5
               local noobs = 0

               for k, i in pairs(playersTable) do
                  if sampIsPlayerConnected(i) then 
		             local nickname = sampGetPlayerNickname(i)
                     local score = sampGetPlayerScore(i)
                     
                     if score < minscore then
                        noobs = noobs + 1
                        sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] с малым уровнем %d", nickname, i, score), -1)
                     end
                  end
               end
               
               if noobs == 0 then
                  sampAddChatMessage("Не найдено игроков с малым уровнем", -1)
               else
                  sampAddChatMessage("Всего: "..noobs, -1)
               end
            end
            
         end
         
         imgui.NextColumn()
         
         if imgui.Button(u8"Подготовка к МП",imgui.ImVec2(120, 25)) then tabmenu.mp = 1 end 
         --if imgui.Button(u8"Управление МП",imgui.ImVec2(120, 25)) then tabmenu.mp = 2 end 
         if imgui.Button(u8"Быстрые команды",imgui.ImVec2(120, 25)) then tabmenu.mp = 3 end 
         if imgui.Button(u8"Проверка игроков",imgui.ImVec2(120, 25)) then tabmenu.mp = 6 end 
         if imgui.Button(u8"Правила МП",imgui.ImVec2(120, 25)) then tabmenu.mp = 4 end 
         if imgui.Button(u8"Финал МП",imgui.ImVec2(120, 25)) then tabmenu.mp = 5 end 
         
         imgui.Spacing()
         imgui.Columns(1)
         imgui.Spacing()
         
      end --end tabmenu.main
      imgui.EndChild()
   
      if not isTraining and not isAbsolutePlay then
         imgui.TextColoredRGB("{FF0000}Некоторые функции могут быть недоступны для данного сервера.")
      end

      imgui.End()
   end
   
   -- Child dialogs
   if dialog.fastanswer.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 4, sizeY / 18),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Сообщения", dialog.fastanswer)
       
      local nickname = sampGetPlayerNickname(chosenplayer)
      local ucolor = sampGetPlayerColor(chosenplayer)
      
      if lastPmMessage then 
         imgui.TextColoredRGB(lastPmMessage)
      end
      
      imgui.TextColoredRGB(string.format("Ответить игроку: {%0.6x} %s[%d]",
      bit.band(ucolor,0xffffff), nickname, chosenplayer))
      imgui.SameLine()
      imgui.Text("                              ")
      imgui.SameLine()
      imgui.TextColoredRGB("{696969} "..string.len(u8:decode(textbuffer.sms.v)).."/128")
      
      imgui.PushItemWidth(420)
      if imgui.InputText("##SMSBuffer", textbuffer.sms) then
         -- if string.len(u8:decode(textbuffer.sms.v) > 128 then
         -- end
      end
      imgui.PopItemWidth()
      imgui.SameLine()
      if imgui.Button(u8" > ", imgui.ImVec2(30, 25)) then
         sampSendChat("/pm "..chosenplayer.." "..u8:decode(textbuffer.sms.v))
      end
      
      imgui.Spacing()
      -- if imgui.Button(u8"Перевести", imgui.ImVec2(100, 25)) then
      -- end
      -- imgui.SameLine()
      -- if imgui.Button(u8"Скопировать в буффер", imgui.ImVec2(100, 25)) then
      -- end
      
      imgui.Text(u8"Быстрые ответы: ")
      imgui.PushItemWidth(420)
      
      if imgui.Combo(u8'##ComboBoxFastAnswers', combobox.fastanswers, fastAnswers, #fastAnswers) then
         textbuffer.sms.v = fastAnswers[combobox.fastanswers.v+1]
      end            
      imgui.PopItemWidth()
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
      local animid = sampGetPlayerAnimationId(chosenplayer)
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
	  imgui.Text(u8("Анимация: ".. animid))
      
	  if weapon == 0 then 
	     imgui.Text(u8"Нет оружия на руках")
	  else
	     if ammo then 
	        imgui.TextColoredRGB(string.format("Оружие в руках: %s (id: %d)", 
	        weaponNames[weapon], weapon))
            if weapon > 15 and weapon < 44 then
               imgui.TextColoredRGB(string.format("Патроны: %d", ammo)) 
            end
	     end
	  end
	  
	  local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
	  distance = getDistanceBetweenCoords3d(posX, posY, posZ, pX, pY, pZ)
	  imgui.TextColoredRGB(string.format("Дистанция: %.1f m.", distance))
	  
	  if zone then 
	     imgui.TextColoredRGB(string.format("Район: {696969}%s", zone))
	  end
	  
      if imgui.TooltipButton(u8"Статистика", imgui.ImVec2(220, 25), u8"Открыть серверную статистику игрока") then
		 if isAbsolutePlay then
            sampSendChat("/стат " .. chosenplayer)
		 else
		    sampSendChat("/stats " .. chosenplayer)
		 end
		 dialog.main.v = false
      end
      
      if imgui.TooltipButton(u8"Наблюдать", imgui.ImVec2(220, 25), u8"Наблюдать за игроком") then      
	     if isAbsolutePlay then
            sampSendChat("/набл " .. chosenplayer)
	     else
		    sampSendChat("/spec " .. chosenplayer)
		 end
      end
          
      if imgui.TooltipButton(u8"Меню игрока", imgui.ImVec2(220, 25), u8"Открыть серверное меню взаимодействия с игроком") then
	     if isAbsolutePlay then
            sampSendChat("/и " .. chosenplayer)
		 end
		 dialog.main.v = false
      end
      
      if imgui.TooltipButton(u8"ТП к Игроку", imgui.ImVec2(220, 25), u8"Телепортироваться к игроку") then
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
          
       if imgui.TooltipButton(u8"Ответить", imgui.ImVec2(220, 25), u8"Быстро ответить игроку") then
          dialog.fastanswer.v = not dialog.fastanswer.v
       end
	   
       if imgui.TooltipButton(u8(chosenplayerMarker and 'Снять' or 'Установить')..u8" метку", imgui.ImVec2(220, 25), u8"Установить/Снять метку с игрока") then
          if chosenplayerMarker ~= nil then
             removeBlip(chosenplayerMarker)
             chosenplayerMarker = nil
             sampAddChatMessage("Метка удалена с игрока",-1)
          else
             for k, v in ipairs(getAllChars()) do
                local res, id = sampGetPlayerIdByCharHandle(v)
                if res then
                   if id == chosenplayer then
                      chosenplayerMarker = addBlipForChar(v)
                      sampAddChatMessage("Метка установлена на игрока",-1)
                   end
                end
             end
          end
       end
	   
	   imgui.End()
   end
   
   if dialog.vehstat.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.25, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Меню транспорта", dialog.vehstat)
      
      
      if chosenvehicle then
         local health = getCarHealth(chosenvehicle)
         local carmodel = getCarModel(chosenvehicle)
         local streamed, id = sampGetVehicleIdByCarHandle(chosenvehicle)
         local ped = getDriverOfCar(chosenvehicle)
         local res, pid = sampGetPlayerIdByCharHandle(ped)
         local passengers, valPassengers = getNumberOfPassengers(chosenvehicle)
         local maxPassengers = getMaximumNumberOfPassengers(chosenvehicle)
         local engineon = isCarEngineOn(chosenvehicle)
         local primaryColor, secondaryColor = getCarColours(chosenvehicle)
         local paintjob = getCurrentVehiclePaintjob(chosenvehicle)
         local availablePaintjobs = getNumAvailablePaintjobs(chosenvehicle)
         
         if carmodel == 447 or carmodel == 425 or carmodel == 432 or carmodel == 520 then
            vehmodelname = string.format("{FF0000}%s (id:%d)", VehicleNames[carmodel-399], carmodel)
         elseif carmodel == 476 or carmodel == 430 or carmodel == 406 or carmodel == 592 then
            vehmodelname = string.format("{FF8C00}%s (id:%d)", VehicleNames[carmodel-399], carmodel)
         elseif carmodel == 601 or carmodel == 407 then
            vehmodelname = string.format("{1E90FF}%s (id:%d)", VehicleNames[carmodel-399], carmodel)
         else
            vehmodelname = string.format("%s (id:%d)", VehicleNames[carmodel-399], carmodel)
         end
	   
         imgui.TextColoredRGB(vehmodelname)
         if imgui.IsItemClicked() then 
            textbuffer.vehiclename.v = tostring(VehicleNames[carmodel-399])
            vehinfomodelid = carmodel
         end
         
         imgui.TextColoredRGB(string.format("Хп: %i", health))
         
         imgui.Text(u8"Водитель:")
         imgui.SameLine()
         if res then 
            imgui.Selectable(string.format(u8"%s", sampGetPlayerNickname(pid)))
            if imgui.IsItemClicked() then
               chosenplayer = pid
               printStringNow("You have chosen a player ".. sampGetPlayerNickname(pid), 1000)
               if not dialog.playerstat.v then dialog.playerstat.v = true end
            end
         else
            imgui.Text(u8"Нет")
         end
         
         imgui.Text(string.format(u8"Скорость: %.0f", getCarSpeed(chosenvehicle)))
         
         if passengers then
            imgui.Text(string.format(u8"Пассажиров в транспорте: %i (max %i)", valPassengers, maxPassengers))
         else
            imgui.Text(string.format(u8"Пассажиров в транспорте: нет (max %i)", maxPassengers))
         end
         
         imgui.Text(engineon and u8('Двигатель: Работает') or u8('Двигатель: Заглушен'))
         
         
         imgui.Text(string.format(u8"Цвет 1: %i  Цвет 2: %i", primaryColor, secondaryColor))
         
         imgui.Text(string.format(u8"Покраска: %i/%i", paintjob, availablePaintjobs))
          
         if imgui.Button(u8"Информация о модели (онлайн)", imgui.ImVec2(250, 25)) then
	        if vehinfomodelid then
               if vehinfomodelid > 400 and vehinfomodelid < 611 then 
	              os.execute(string.format('explorer "https://gtaundergroundmod.com/pages/ug-mp/documentation/vehicle/%d/details"', vehinfomodelid))
               else
                  sampAddChatMessage("Некорректный ид транспорта", -1)
               end
	        end
	     end
                  
         if imgui.Button(u8"Предпросмотр 3D модели (онлайн)", imgui.ImVec2(250, 25)) then
	        if vehinfomodelid then
               if vehinfomodelid > 400 and vehinfomodelid < 611 then 
	              os.execute(string.format('explorer "http://gta.rockstarvision.com/vehicleviewer/#sa/%d"', vehinfomodelid))
               else
                  sampAddChatMessage("Некорректный ид транспорта", -1)
               end
	        end
	     end
         
         if imgui.Button(u8"Таблица цветов транспорта (онлайн)", imgui.ImVec2(250, 25)) then
            os.execute(string.format('explorer "https://www.open.mp/docs/scripting/resources/vehiclecolorid"'))
	     end
         
      end
      
   	  imgui.End()
   end
   
   if dialog.objectinfo.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 15, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Информация о объекте", dialog.objectinfo)
      
      if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
         local modelName = tostring(sampObjectModelNames[LastObjectData.modelid])
         
         imgui.TextColoredRGB("modelid: {3f70d6}".. LastObjectData.modelid)
         imgui.TextColoredRGB("name: {3f70d6}".. modelName)
         imgui.TextColoredRGB("id: {3f70d6}".. LastObjectData.id)
         if not LastObjectData.position.x ~= nil then
	        imgui.TextColoredRGB(string.format("{3f70d6}x: %.1f, {e0364e}y: %.1f, {26b85d}z: %.1f", LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z))
         end   
	     if not LastObjectData.rotation.x ~= nil then
            imgui.TextColoredRGB(string.format("{4f70d6}rx: %.1f, {f0364e}ry: %.1f, {36b85d}rz: %.1f", LastObjectData.rotation.x, LastObjectData.rotation.y, LastObjectData.rotation.z))
         end   
	     imgui.TextColoredRGB(string.format("angle: {3f70d6}%.1f", getObjectHeading(LastObjectData.handle)))
	     --imgui.TextColoredRGB("объект "..(isObjectOnScreen(LastObjectData.handle) and 'на экране' or 'не на экране'))
	     if not isObjectOnScreen(LastObjectData.handle) then 
            imgui.TextColoredRGB("{ff0000}объект вне зоны прямой видимости")
         end
         if isAbsolutePlay and LastObjectData.txdname ~= nil then
            for k, txdname in pairs(AbsTxdNames) do
               if txdname == LastObjectData.txdname then
                  imgui.TextColoredRGB("texture internalid: {3f70d6}" .. k-1)
                  break
               end
            end
	        imgui.TextColoredRGB("txdname: {3f70d6}".. LastObjectData.txdname .. " ("..LastObjectData.txdlibname..") ")
         end
         
         imgui.Spacing()  
         if imgui.TooltipButton(u8"Инфо по объекту (online)",imgui.ImVec2(200, 25), u8"Посмотреть подробную информацию по объекту на Prineside DevTools") then		    
            local link = 'explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/search/?q=' .. LastObjectData.modelid..'"'
		    os.execute(link)
	     end
         
         if imgui.Button(u8"В буфер обмена", imgui.ImVec2(200, 25)) then
            if not LastObjectData.rotation.x ~= nil then
               setClipboardText(string.format("%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f", LastObjectData.modelid, LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z, LastObjectData.rotation.x, LastObjectData.rotation.y, LastObjectData.rotation.z))
            else
               setClipboardText(string.format("%i, %.2f, %.2f, %.2f", LastObjectData.modelid, LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z))
            end
            sampAddChatMessage("Текcт скопирован в буфер обмена", -1)
	     end
         
         if imgui.Button(u8"Экспортировать", imgui.ImVec2(200, 25)) then
            if LastObjectData.txdname ~= nil then
               if not LastObjectData.rotation.x ~= nil then
                  sampAddChatMessage(string.format("tmpobjid = CreateObject(%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f);", LastObjectData.modelid, LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z, LastObjectData.rotation.x, LastObjectData.rotation.y, LastObjectData.rotation.z), -1)
               else
                  sampAddChatMessage(string.format("tmpobjid = CreateObject(%i, %.2f, %.2f, %.2f);", LastObjectData.modelid, LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z), -1)
               end
               sampAddChatMessage(string.format('SetObjectMaterial(tmpobjid, 0, %i, %s, %s, 0xFFFFFFFF);', LastObjectData.txdmodel, LastObjectData.txdlibname, LastObjectData.txdname), -1) 
            else 
               if not LastObjectData.rotation.x ~= nil then
                  sampAddChatMessage(string.format("CreateObject(%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)", LastObjectData.modelid, LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z, LastObjectData.rotation.x, LastObjectData.rotation.y, LastObjectData.rotation.z), -1)
               else
                  sampAddChatMessage(string.format("CreateObject(%i, %.2f, %.2f, %.2f)", LastObjectData.modelid, LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z), -1)
               end
            end
	     end
         
         if imgui.Button(u8"В избранное", imgui.ImVec2(200, 25)) then
            favfile = io.open(getGameDirectory() ..
            "//moonloader//resource//abseventhelper//objects.txt", "a")
            favfile:write(" ,"..LastObjectData.modelid)
            favfile:close()
            sampAddChatMessage("Добавлен в файл избранных (objects.txt)", -1)
         end
         imgui.Spacing()   
      end
	  imgui.End()
   end
   
end

-------------- SAMP hooks -----------
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
      print(string.format("dialogId: %d, button: %d, listboxId: %d, input: %s", dialogId, button, listboxId, input))
   end
   
   if isAbsolutePlay then
      isTexturesListOpened = false
      isSanpObjectsListOpened = false
      
      -- if player wxit from world without command drop lastWorldNumber var 
      if dialogId == 1405 and listboxId == 5 and button == 1 then
         lastWorldNumber = 0
         isWorldHoster = false
         worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
      end
       
	  -- Get current world number from server dialogs
	  if dialogId == 1426 and listboxId == 65535 and button == 1 then
         if tonumber(input) > 0 and tonumber(input) < 500 then
		    lastWorldNumber = tonumber(input)
            worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
	     end
      end
	  
	  if dialogId == 1406 and button == 1 then
	     local world = tonumber(string.sub(input, 0, 3))
	     if world then
		    lastWorldNumber = world
            worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
		 end
	  end
	  
      if dialogId == 1403 and listboxId == 2 and button == 1 then
         if LastObjectData.txdname ~= nil then
            for k, txdname in pairs(AbsTxdNames) do
               if txdname == LastObjectData.txdname then
                  sampAddChatMessage("Последняя использованная текстура: " .. k-1, 0xFF00FF00)
                  break
               end
            end
         end
      end
      
      if dialogId == 1400 and listboxId == 4 and button == 1 and not input:find("Игрок") then
         if LastObjectData.txdname ~= nil then
            for k, txdname in pairs(AbsTxdNames) do
               if txdname == LastObjectData.txdname then
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
      
      if dialogId == 1409 and listboxId == 2 and button == 1 and input:find("MP объекты") then
         isSampObjectsListOpened = true
      end
      
      if dialogId == 1412 and listboxId == 2 and button == 1 then
	     sampAddChatMessage("Вы изменили разрешение на редактирование мира для всех игроков!", 0xFF0000)
	  end
      
      if dialogId == 1419 and button == 1 then
         worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
      end
      
	  if dialogId == 1429 and button == 1 then
		 local startpos = input:find("№")
		 local endpos = startpos + 3
		 local world = tonumber(string.sub(input, startpos+1, endpos))
	     if world then
		    lastWorldNumber = world
            worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
		 end
	  end
      
      -- hook editmodes
      if dialogId == 1400 and button == 1 then
         if listboxId == 2 then editMode = 1 end
         if listboxId == 4 then editMode = 4 end
         if listboxId == 5 then editMode = 2 end
      end 
      
	  if dialogId == 1422 and listboxId == 0 and button == 1 then
         editMode = 1
      end
      
	  if dialogId == 1403 and button == 1 then
         if listboxId == 0 then editMode = 1 end
         if listboxId == 1 then editMode = 3 end
      end
      if dialogId == 1411 and button == 1 and listboxId == 0 then
         editMode = 3
      end
      -- if dialogId == 1403 or dialogId == 1411 and button == 1 then
	     -- if LastObjectData.modelid then 
		    -- lastRemovedObjectModelid = LastObjectData.modelid
			-- lastRemovedObjectCoords.x = LastObjectData.position.x
			-- lastRemovedObjectCoords.y = LastObjectData.position.y
			-- lastRemovedObjectCoords.z = LastObjectData.position.z
		 -- end
	  -- end
	  
	  -- if dialogId == 1401 and button == 1 then
	     -- if undoMode then
		    -- if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
		       -- setObjectCoordinates(LastObjectData.handle, lastRemovedObjectCoords.x, lastRemovedObjectCoords.y, lastRemovedObjectCoords.z)
			-- end
		 -- end
	  -- end

   end
   
   -- All Training dialogId has id 32700
   if isTraining and dialogId == 32700 then
      
      if button == 0 then 
         editDialogOpened = false
      end
      
      -- Corrects spawn item on /world menu
      if listboxId == 3 and button == 1 and input:find("Вернуться в свой мир") then
         if worldspawnpos.x and worldspawnpos.x ~= 0 then
            sampSendChat(string.format("/xyz %f %f %f",
		    worldspawnpos.x, worldspawnpos.y, worldspawnpos.z), 0x0FFFFFF)
         else
            sampSendChat("/spawnme")
         end
      end
      
      -- Added new features to /omenu
      if listboxId == 0 and button == 1 then 
         if LastObjectData.localid then 
            editMode = 1
            sampSendChat("/oedit "..LastObjectData.localid)
         end
      end
      if listboxId == 2 and button == 1 then editMode = 3 end
      if listboxId == 3 and button == 1 and input:find("Повернуть на 90") then
         sampSendChat("/rz 90")
      end
      if listboxId == 4 and button == 1 and input:find("Наложить текст") then
         sampSendChat("/otext -1")
      end
      if listboxId == 5 and button == 1 and input:find("Показать индексы") then
         sampSendChat("/sindex")
      end
      if listboxId == 6 and button == 1 and input:find("Информация") then
         sampSendChat("/oinfo")
      end
      
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
         local newtext = 
         "{FFFFFF}Внутриигровой редактор карт позволяет любому игроку создать уникальный мир.\n"..
         "Каждый игрок от 20 уровня может создать свой мир, или редактировать открытый мир.\n"..
         "По умолчанию в мире можно строить только 50 объектов, и расширить до 300 объектов.\n"..
         "Любого игрока можно пригласить в открытый мир, или позволить ему редактировать ваш мир.\n"..
         "В радиусе 150 метров нельзя создавать более 200 объектов.\n"..
         "\nВозможности редактора карт:\n"..
         "- Удобное меню редактора на диалогах. Вам не нужно запоминать десятки команд для управления, все доступно через единое меню.\n"..
         "- Визуальный выбор объектов в меню. Вы видите объекты через предпросмотр, вам не нужно искать номера объектов на сторонних ресурсах.\n".. 
         "- Создание пикапов. Создавайте пикапы оружия, здоровья, брони и другие предметы. Включая выпадение пикапов после убийства противника.\n"..
         "- Оружие и здоровье по умолчанию. Настройка изначальных характеристик, с которыми игрок войдёт в редактор карт.\n"..
         "- Создание транспорта. Создавайте любой транспорт в мире, включая уникальный и военную технику.\n"..
         "- Создание гонок. Использование разных машин, мотоциклов, лодок и воздушной техники для проведения соревнований с возможностью выбора маршрутов.\n"..
         "- Возможность совместного редактирования. Приглашайте друзей на помощь.\n"..
         "- Организаторские опции управления. Возможность гибкой настройки параметров мира для проведения различного рода мероприятий.\n"..
         "- Управление камерой. Вы можете работать в режиме полета свободной камерой, либо зафиксировать камеру над собой.\n"..
         "- Смена текстур. Применяйте ретекстур к различным объектам чтобы преобразить их до неузнаваемости.\n"..
         "- Настройка доступа. Ваш мир может быть открыт для всех игроков 24/7. Либо же вы можете задать пароль на вход, или вовсе сделать мир персональным.\n"..
         "\n{FFD700}VIP игроки{FFFFFF} могут:\n"..
         "- телепортироваться по метке на карте в ESC\n"..
         "- расширять мир до 2000 объектов\n"..
         "- выбирать шрифт и цвет текста\n"..
         "- выбирать точку появления в мире\n"
        
         sampAddChatMessage("Подробнее на https://forum.sa-mp.ru/index.php?/topic/1016832-миры-описание-работы-редактора-карт", -1)
         return {dialogId, style, title, button1, button2, newtext}
      end
      
      if dialogId == 1498 then
         return {dialogId, style, title, button1, button2,
         "Введи размер шрифта от 1 до 255"}
      end
      
      if dialogId == 1401 then
         local newtext = 
         "615-18300   GTA-SA \n"..
         "18632-19521 SA-MP\n\n"..
         "Номера объектов можно найти на сайте:\n"..
         "https://dev.prineside.com/ru/gtasa_samp_model_id/\n"..
         (LastObjectData.modelid and "\nПоследний использованный объект: "..LastObjectData.modelid or " ")..
         "\nВведи номер объекта: \n"
         return {dialogId, style, title, button1, button2, newtext}
      end
      
      if dialogId == 1410 then
         return {dialogId, style, title, button1, button2, 
         "Выбери радиус в котором необходимо удалить объекты (Рекомендуется не больше 50)"}
      end
      
      if dialogId == 1413 then
         local newtext = 
         "Для создания мира необходимо:\n"..
         "20 LvL, $1.000.000, 100 ОА\n\n"..
         "Ты уверен что хочешь создать мир для строительства?\n"
         return {dialogId, style, title, button1, button2, newtext}
      end
      
      if dialogId == 1414 then
         return {dialogId, style, title, button1, button2, 
         "{FF0000}Это действие необратимо!!!\nТы уверен что хочешь удалить мир?"}
      end
      
      if dialogId == 1426 then
         if lastWorldNumber > 0 then
            local newtext = 
            "Если вы хотите попробовать редактор карт\n"..
            "Посетите мир 10, он всегда открыт для редактирования\n\n"..
            "Последний мир в котором вы были: "..lastWorldNumber.."\n"..
            "Введите номер мира в который хотите войти:\n"
            return {dialogId, style, title, button1, button2, newtext}
         else
            local newtext = 
            "Если вы хотите попробовать редактор карт\n"..
            "Посетите мир 10, он всегда открыт для редактирования\n\n"..
            "Введите номер мира в который хотите войти:\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
      end
   end
   
   if isTraining and dialogId == 32700 then
      -- TRAINING Skip rules dialog
      if style == 0 and button1 == "Принимаю" then
         sampSendDialogResponse(32700, 1, nil)
         sampCloseCurrentDialogWithButton(1)
      end
      -- Added new features to /omenu
      if title:find("Редактирование / Клонирование") then
         editDialogOpened = true
         newitems = "Редактировать\n"..
         "Клонировать\n"..
         "Удалить\n"..
         "Повернуть на 90°\n"..
         "Наложить текст\n"..
         "Показать индексы\n"..
         "Информация\n"
         return {dialogId, style, "Редактирование объекта", button1, button2, newitems}
      end
      -- Automatic ID substitution for /otext
      if title:find("Master Text Textures") and text:find("Укажите ID")then
         if LastObjectData.localid and editDialogOpened then
            sampSendDialogResponse(32700, 1, nil, LastObjectData.localid)
            sampCloseCurrentDialogWithButton(0)
         end
      end
   end
   
   if checkbox.logdialogresponse.v then
      print(dialogId, style, title, button1, button2, text)
   end
end

function sampev.onServerMessage(color, text)
   local result, id = sampGetPlayerIdByCharHandle(playerPed)
   local nickname = sampGetPlayerNickname(id)
   
   if checkbox.logmessages.v then
      print(string.format("%s, %s", color, text))
   end
   
   if checkbox.globalchatoff.v then
      -- disable global chat, but write information to chatlog
      chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
      chatlog:write(os.date("[%H:%M:%S] ")..text)
      chatlog:write("\n")
      chatlog:close()
      return false
   end
   
   if isChatFreezed then
      table.insert(chatbuffer, {color = color, text = text})
      return false
   end
    
   if checkbox.chatmentions.v then
      -- mentions by nickname
      if text:find(nickname) and color ~= -1029514497 then
         if text:find(":") then
            local pointpos = text:find(":")
            local cleartext = text:sub(pointpos, string.len(text))
             --print(color, text)
            if cleartext:find(nickname) then
               printStyledString('You were mentioned in the chat', 2000, 4)
               addOneOffSound(0.0, 0.0, 0.0, 1138) -- CHECKPOINT_GREEN
               return true
            end
          else
            printStyledString('You were mentioned in the chat', 2000, 4)
            addOneOffSound(0.0, 0.0, 0.0, 1138) -- CHECKPOINT_GREEN
            return true
         end
      end
      
      -- mentions by id
      if text:match("(%s"..id.."%s)") then
         printStyledString('You were mentioned in the chat', 2000, 4)
         addOneOffSound(0.0, 0.0, 0.0, 1138) -- CHECKPOINT_GREEN
         return true
      end
      
   end
   
   -- TODO optimize shitcode
   if isAbsolutePlay and text:find('ЛС') and text:find('от') then
      lastPmMessage = text
   end
   
   if text:find('Добро пожаловать на Arizona Role Play!') then
      thisScript():unload()
   end
   
   if isTraining then
      if text:find("Невозможно создать новый мир, за вами уже есть закрепленный мир") then
         isWorldHoster = true
         sampSendChat("/vw")
         return false
      end
      if text:find("Меню управления миром") then
         sampAddChatMessage("[SERVER]: {FFFFFF}Меню управления миром - /vw или клавиша - M", 0x0ff4f00)
         return false
      end
   end
   
   if isAbsolutePlay then
      if text:find("У тебя нет прав") then
         if prepareJump then 
            JumpForward()
            prepareJump = false
         end
         if prepareTeleport then sampAddChatMessage("В мире телепортация отключена", 0x00FF00) end
         return false
      end
      
      if text:find("Последнего созданного объекта не существует") then
         if LastObjectData.modelid then
            sampAddChatMessage("Последний использованный объект: "..LastObjectData.modelid, 0x00FF00)
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
   
   if isTraining then
      if text:find("Виртуальный мир успешно создан") 
      or text:find("Вы создали пробный VIP мир") then
         isWorldHoster = true
         worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
         sampSendChat("/weather "..slider.weather.v)
         lua_thread.create(function()
            wait(1000)
            sampSendChat("/time "..slider.time.v)
            wait(1000)
            sampSendChat("/gm")
            if ini.settings.debug then
               wait(500)
               if sampIsLocalPlayerSpawned() then
                  sampSendChat("/skin 27")
               end
            end
         end)
      end
      
      if text:find('Создан объект: (%d+)') then
         LastObjectData.localid = text:match('Создан объект: (%d+)')
      end
      
      if text:find('Выбран предмет: (%d+)') then
         LastObjectData.localid = text:match('Выбран предмет: (%d+)')
      end
      
      if text:find('Вы отправлены на спаун!') then
         isWorldHoster = false
         sampSendChat("/spawnme")
      end
      
      if text:find('Удален объект: (%d+)') then
         LastObjectData.localid = nil
      end
   end
end

function sampev.onSendCommand(command)
    -- tips for those who are used to using Texture Studio syntax
   if isAbsolutePlay then
      if command:find("texture") then
         sampAddChatMessage("Для ретекстура используйте:", 0x000FF00)
         sampAddChatMessage("N - Редактировать объект - Выделить объект - Перекарсить объект", 0x000FF00)
         return false
      end
      if command:find("showtext3d") then
         sampAddChatMessage("Информация о объектах показана", 0x000FF00)
         checkbox.showobjects.v = true 
         return false
      end
      if command:find("hidetext3d") then
         sampAddChatMessage("Информация о объектах скрыта", 0x000FF00)
         checkbox.showobjects.v = false
         return false
      end
      if command:find("flymode") then
         sampSendChat("/полет")
         return false
      end
      if command:find("team") or command:find("setteam") then
         sampSendChat("Нельзя менять тимы. Если вы хотели изменить спавн используйте:",0x000FF00)
         sampSendChat("Y - Редактор карт - Управление миром - Выбрать точку появления",0x000FF00)
         return false
      end
      if command:find("jetpack")then
         sampAddChatMessage("Джетпак можно взять в меню: N - Оружие - Выдать себе оружие", 0x000FF00)
         return false
      end
   end
   
   if isTraining then
      -- Automatic substitution of the last object ID for some commands
      if not command:find('(.+) (.+)') then
         if LastObjectData.localid then
            if command:find("/omenu") then
               sampSendChat("/omenu "..LastObjectData.localid)
               return false
            end
            
            if command:find("/sel") then
               sampSendChat("/sel "..LastObjectData.localid)
               editMode = 3
               return false
            end
            
            if command:find("/ogh") then
               sampSendChat("/ogh "..LastObjectData.localid)
               return false
            end
            
            if command:find("/untexture") then
               sampSendChat("/untexture "..LastObjectData.localid)
               return false
            end
            
            if command:find("/oadd") then
               if LastObjectData.modelid then
                  sampAddChatMessage("Последний использованный объект: "..LastObjectData.modelid, 0x00FF00)
	           end
            end
         end
      end
   end
   
   if isAbsolutePlay then
      if command:find("/setweather") then
         if command:find('(.+) (.+)') then
            local cmd, arg = command:match('(.+) (.+)')
            local id = tonumber(arg)
            if id >= 0 and id <= 45 then
               ini.settings.lockserverweather = true
               patch_samp_time_set(true)
               slider.weather.v = id
               setWeather(slider.weather.v)
               sampAddChatMessage("Вы установили погоду - "..id, 0x000FF00)
            end
         else
            sampAddChatMessage("Укажите верный ид погоды от 0 до 45", -1)
         end
         return false
      end
      
      if command:find("/settime") then
         if command:find('(.+) (.+)') then
            local cmd, arg = command:match('(.+) (.+)')
            local id = tonumber(arg)
            if id >= 0 and id <= 12 then
               ini.settings.lockserverweather = true
               patch_samp_time_set(true)
               slider.time.v = id
               setTime(slider.time.v)
               sampAddChatMessage("Вы установили время - "..id, 0x000FF00)
            end
         else
            sampAddChatMessage("Укажите время от 0 до 12", -1)
         end
         return false
      end
   end
   
   if isAbsolutePlay then
      if command:find("vfibye2") or command:find("машину2") then 
         isTexturesListOpened = false
         isSanpObjectsListOpened = false
      end
   end
   
   if command:find("ответ") then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local id = tonumber(arg)
         if sampIsPlayerConnected(id) then 
            chosenplayer = id
         else
            sampAddChatMessage("Не выбран игрок. Используйте /ответ <id>", -1)
            return false
         end
      end
      
      dialog.fastanswer.v = true
      dialog.main.v = true
      return false
   end
   
   if command:find("exit") or command:find("выход") then
      isWorldHoster = false
	  lastWorldNumber = 0
      worldspawnpos.x = 0
      worldspawnpos.y = 0
      worldspawnpos.z = 0
   end
   
   if command:find("savepos") then
      if sampIsLocalPlayerSpawned() then
         tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(PLAYER_PED)
	     setClipboardText(string.format("%.2f %.2f %.2f", tpcpos.x, tpcpos.y, tpcpos.z))
	     sampAddChatMessage("Позиция скопирована в буфер обмена", -1)
         if isAbsolutePlay then
            sampAddChatMessage("Используйте /gopos чтобы телепортироваться на сохраненную позицию ", 0x000FF00)
         end
      end
      if not isTraining then
         return false
      end
   end
   
   if command:find("gopos") then
      if isTraining then
         return false
      end
      if sampIsLocalPlayerSpawned() then
         if tpcpos.x and tpcpos.x ~= 0 then
            if isAbsolutePlay then
		       sampSendChat(string.format("/тпк %f %f %f",
		       tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
               sampAddChatMessage(string.format("Вы телепортировались на координаты: %.2f %.2f %.2f",
		       tpcpos.x, tpcpos.y, tpcpos.z), 0x000FF00)
            elseif isTraining then
		       sampSendChat(string.format("/xyz %f %f %f",
		       tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
               sampAddChatMessage(string.format("Вы телепортировались на координаты: %.2f %.2f %.2f",
		       tpcpos.x, tpcpos.y, tpcpos.z), 0x000FF00)
		    else
               --setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z)
	           sampAddChatMessage("Недоступно для вашего сервера.", -1)
            end
         end
      end
      return false
   end
   
   if command:find("jump") then
      if sampIsLocalPlayerSpawned() then
         JumpForward()
      end
      return false
   end
   
   if command:find("slapme") and not isTraining then
      if sampIsLocalPlayerSpawned() then
         local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
         setCharCoordinates(PLAYER_PED, posX, posY, posZ+1.0)
      end
      return false
   end
   
   if command:find("spawnme") and not isTraining  then
      local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
	  setCharCoordinates(PLAYER_PED, posX, posY, posZ+0.2)
	  freezeCharPosition(PLAYER_PED, false)
	  setPlayerControl(PLAYER_HANDLE, true)
	  restoreCameraJumpcut()
	  clearCharTasksImmediately(PLAYER_PED)
      return false
   end
   
   if command:find("spec") then
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
   
   -- editmodes hook
   if command:find("csel") or command:find("editobject") and not isTraining then
      sampAddChatMessage("Включен режим редактирования объекта", 0x000FF00)
      enterEditObject()
      return false
   end
   
   if isTraining and command:find("odell") then
      editMode = 3
      return true
   end
   
   if isTraining and command:find("oedit") then
      editMode = 1
      return true
   end
   
   if command:find("sindex") and not isTraining then
      if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
         setMaterialObject(LastObjectData.id, 1, 0, 18646, "MatColours", "red", 0xFFFFFFFF) 
         setMaterialObject(LastObjectData.id, 1, 1, 18646, "MatColours", "green", 0xFFFFFFFF)         
         setMaterialObject(LastObjectData.id, 1, 2, 18646, "MatColours", "blue", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 3, 18646, "MatColours", "yellow", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 4, 18646, "MatColours", "lightblue", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 5, 18646, "MatColours", "orange", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 6, 18646, "MatColours", "redlaser", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 7, 18646, "MatColours", "grey", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 8, 18646, "MatColours", "white", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 9, 7910, "vgnusedcar", "lightpurple2_32", 0xFFFFFFFF)
         setMaterialObject(LastObjectData.id, 1, 10, 19271, "MapMarkers", "green-2", 0xFFFFFFFF) -- dark green
         --setMaterialObject(LastObjectData.id, 1, 11, 18979, "MatClothes", "darkblue", 0xFFFFFFFF) -- dark blue
         --setMaterialObjectText(LastObjectData.id, 2, 0, 100, "Arial", 255, 0, 0xFFFFFF00, 0xFF00FF00, 1, "0")
         sampAddChatMessage("Режим визуального просмотра индексов включен. Каждый индекс соответсвует цвету с таблицы.", 0x000FF00)
         sampAddChatMessage("{FF0000}0 {008000}1 {0000FF}2 {FFFF00}3 {00FFFF}4 {FF4FF0}5 {dc143c}6 {808080}7 {FFFFFF}8 {800080}9 {006400}10", -1)
      else
         sampAddChatMessage("Последний созданный объект не найден", -1)
      end
      return false
   end
   
   if command:find("rindex") then
      if isTraining then
         sampSendChat("/untexture")
         return false
      end
      if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
         for index = 0, 15 do 
            setMaterialObject(LastObjectData.id, 1, index, LastObjectData.modelid, "none", "none", 0xFFFFFFFF)
         end
         sampAddChatMessage("Режим визуального просмотра индексов отключен", 0x000FF00)
      else
         sampAddChatMessage("Последний созданный объект не найден", -1)
      end
      return false
   end
   
   if command:find("oalpha") then
      if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
         for index = 0, 15 do 
            setMaterialObject(LastObjectData.id, 1, index, LastObjectData.modelid, "none", "none", 0x99FFFFFF)
         end
         sampAddChatMessage("Установлена полупрозрачность последнему созданному объекту", 0x000FF00)
      else
         sampAddChatMessage("Последний созданный объект не найден", -1)
      end
      return false
   end
   
   if command:find("ocolor") and not isTraining then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local ocolor = tostring(arg)
         if string.len(ocolor) < 10 or not ocolor:find("0x") then
            sampAddChatMessage("Формат цвета 0xAARGBRGB", -1)
            return false
         end
      
         if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
            for index = 0, 15 do 
               setMaterialObject(LastObjectData.id, 1, index, LastObjectData.modelid, "none", "none", arg)
            end
            sampAddChatMessage("Установлен цвет ".. ocolor .." последнему созданному объекту", 0x000FF00)
         else
            sampAddChatMessage("Последний созданный объект не найден", -1)
         end
      else
         sampAddChatMessage("Формат цвета 0xAARGBRGB", -1)
      end
      return false
   end
   
   if command:find("ogoto") then
      if LastObjectData.handle and doesObjectExist(LastObjectData.handle) then
      	 if isAbsolutePlay then
		    sampSendChat(string.format("/тпк %f %f %f",
		    LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z), 0x0FFFFFF)
         elseif isTraining then
		    sampSendChat(string.format("/xyz %f %f %f",
		    LastObjectData.position.x, LastObjectData.position.y, LastObjectData.position.z), 0x0FFFFFF)   
		 else
		    setCharCoordinates(PLAYER_PED, LastObjectData.position.x, LastObjectData.position.x, LastObjectData.position.z+0.2)
		 end
		 sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..LastObjectData.modelid, 0x000FF00)
      else
         if isTraining then
            sampAddChatMessage("Используйте /tpo <id>", -1)
         else
            sampAddChatMessage("Последний созданный объект не найден", -1)
         end
      end
      return false
   end
   
   if command:find("tsearch") and not isTraining then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local searchtxd = tostring(arg)
         if string.len(searchtxd) < 2 then
            sampAddChatMessage("Минимальное кол-во символов для поиска текстуры = 2", -1)
            return false
         end
         
         local findedtxd = 0
         if searchtxd and searchtxd ~= nil then 
            for k, txdname in pairs(AbsTxdNames) do
               if txdname:find(searchtxd) then
                  findedtxd = findedtxd + 1
                  sampAddChatMessage(string.format("{696969}%d. {FFFFFF}%s", k-1, txdname), -1)
                  if findedtxd >= 50 then
                     break
                  end
               end
            end
            
            if findedtxd > 0 then
               sampAddChatMessage("Найдено совпадений: "..findedtxd, -1)
            else
               sampAddChatMessage("Совпадений не найдено.", -1)
            end
            return false
         end
      else 
         sampAddChatMessage("Введите название текстуры для поиска", -1)
         sampAddChatMessage("Например: /tsearch wood", -1)
         return false
      end
   end
   
   if command:find("osearch") and not isTraining then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local searchobj = tostring(arg)
         if string.len(searchobj) < 3 then
            sampAddChatMessage("Минимальное кол-во символов для поиска = 3", -1)
            return false
         end
         
         local findedobj = 0
         if searchobj and searchobj ~= nil then 
            for k, model in pairs(sampObjectModelNames) do
               if model:find(searchobj) then
                  findedobj = findedobj + 1
                  sampAddChatMessage(string.format("{696969}%d. {FFFFFF}%s", k, model), -1)
                  if findedobj >= 75 then
                     break
                  end
               end
            end
            
            if findedobj > 0 then
               sampAddChatMessage("Найдено совпадений: "..findedobj, -1)
            else
               sampAddChatMessage("Совпадений не найдено.", -1)
            end
            return false
         end
      else 
         sampAddChatMessage("Введите название объекта для поиска", -1)
         sampAddChatMessage("Например: /osearch wall", -1)
         return false
      end
   end
   
   if command:find("vbh") or command:find("мир") then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local id = tonumber(arg)
         if id then 
	        if id > 0 and id <= 500 then 
		       lastWorldNumber = id
               worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
	        end
         end
	  end
   end
   
   -- if command:find("afk") then
      -- if command:find('(.+) (.+)') then
         -- local cmd, arg = command:match('(.+) (.+)')
         -- local id = tonumber(arg)
         -- if id and sampIsPlayerConnected(id) then
			-- if sampIsPlayerPaused(id) then 
               -- sampAddChatMessage(sampGetPlayerNickname(id) .. '(' .. id .. ')' .. ': {FF0000}AFK', -1)
		    -- else 
		       -- sampAddChatMessage(sampGetPlayerNickname(id) .. '(' .. id .. ')' .. ': {00FF00}ONLINE', -1)
            -- end
         -- else
            -- sampAddChatMessage("Неверный ид либо игрок вышел", -1)
	     -- end
      -- else
         -- for i = 0, sampGetMaxPlayerId(false) do
            -- if sampIsPlayerConnected(i) then
               -- if sampIsPlayerPaused(i) then 
                  -- sampAddChatMessage(sampGetPlayerNickname(i) .. '(' .. i .. ')' .. ': {FF0000}AFK', -1)
		       -- else 
		          -- sampAddChatMessage(sampGetPlayerNickname(i) .. '(' .. i .. ')' .. ': {00FF00}ONLINE', -1)
               -- end
            -- end
         -- end         
      -- end
      -- return false
   -- end
   
   -- if command:find("@tab") then
      -- if tabselectedplayer ~= nil then
         -- command.gsub(command, "@tab", tabselectedplayer)
      -- end
   -- end
end

function sampev.onSendChat(message)
   -- Corrects erroneous sending of empty chat messages
   if isTraining then
      if string.len(message) < 2 then
         return false
      end
   end
end

function sampev.onApplyPlayerAnimation(playerId, animLib, animName, frameDelta, loop, lockX, lockY ,freeze, time)
   -- Fixes knocking down the jetpack by calling animation
   if isTraining then   
      local res, id = sampGetPlayerIdByCharHandle(playerPed)
      if res and sampGetPlayerSpecialAction(id) == 2 then
         return false
      end
   end
end

function onExitScript()
	if not sampIsDialogActive() then
	   showCursor(false)
	end
	setCameraDistanceActivated(0)
	setCameraDistance(0)
	patch_samp_time_set(false)
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
   if id == LastObjectData.id then 
      LastObjectData.txdlibname = data.libraryName
      LastObjectData.txdname = data.textureName
      LastObjectData.txdmodel = data.modelId
   end
   if checkbox.logtxd.v then
      print(id, data.materialId, data.modelId, data.libraryName, data.textureName, data.color)
   end
end

function sampev.onSendEditObject(playerObject, objectId, response, position, rotation)
   local object = sampGetObjectHandleBySampId(objectId)
   local modelId = getObjectModel(object)
   LastObjectData.handle = object
   LastObjectData.id = objectId
   LastObjectData.modelid = modelId
   LastObjectData.position.x = position.x
   LastObjectData.position.y = position.y
   LastObjectData.position.z = position.z
   LastObjectData.rotation.x = rotation.x
   LastObjectData.rotation.y = rotation.y
   LastObjectData.rotation.z = rotation.z
   
   -- Auto open /omenu on save object 
   -- if isTraining and response == 1 then
      -- if LastObjectData.localid then
         -- sampSendChat("/omenu "..LastObjectData.localid)
      -- end
   -- end
   
   -- Returns the object to its initial position when exiting editing
   -- TODO restore object angle too
   editResponse = response
   if ini.settings.restoreobjectpos then
      if isTraining and response == 0 then
         if LastObjectData.startpos.x ~= 0 and LastObjectData.startpos.y ~= 0 then
            return {playerObject, objectId, response,  LastObjectData.startpos, rotation}
         end
      end
   end
   
   if ini.settings.showobjectrot then
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
   LastObjectData.handle = object
   LastObjectData.id = objectId
   LastObjectData.modelid = modelId
   --LastObjectData.angle = getObjectHeading(object)
   -- Сontains the initial position of the object before editing
   LastObjectData.startpos.x = position.x
   LastObjectData.startpos.y = position.y
   LastObjectData.startpos.z = position.z
   -- Duplicate last object sync data
   LastObjectData.position.x = position.x
   LastObjectData.position.y = position.y
   LastObjectData.position.z = position.z
   
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

function sampev.onCreate3DText(id, color, position, distance, testLOS,
attachedPlayerId, attachedVehicleId, text)
   if checkbox.log3dtexts.v then
      print(id, color, position.x, position.y, position.z, distance, testLOS,
      attachedPlayerId, attachedVehicleId, text)
   end
   
   -- Get local id from textdraw info
   if isTraining and color == 8436991 then
      LastObjectData.localid = text:match('id:(%d+)')
   end
   
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
   if isTraining then
      setClipboardText(tabselectedplayer)
      sampAddChatMessage("id "..playerId.." кликнутого в TAB игрока "..sampGetPlayerNickname(playerId).." скопирован в буфер", 0x000FF00)
   end
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
   
   if isAbsolutePlay and isSampObjectsListOpened then
      if id >= 2053 and id <= 2100 then
         local modelid = tonumber(string.sub(data.text, 0, 5))
         if modelid ~= nil then
            local particlename = tostring(AbsParticleNames[modelid])
		    local particlename = string.gsub(particlename, " ", "~n~")
            local txdlabel = modelid.."~n~~n~"..cyrillic(particlename)
            if string.len(txdlabel) > 14 then data.text = txdlabel end
            data.letterWidth = 0.18
            data.letterHeight = 0.9
            return{id, data}    
         end
      end
   end
   
   if checkbox.hidealltextdraws.v then
      return false
   end
end

function sampev.onSendClickTextDraw(textdrawId)
   lastClickedTextdrawId = textdrawId
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

function nameTagOn()
   local pStSet = sampGetServerSettingsPtr();
   NTdist = memory.getfloat(pStSet + 39)
   NTwalls = memory.getint8(pStSet + 47)
   NTshow = memory.getint8(pStSet + 56)
   memory.setfloat(pStSet + 39, 70.0)
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

function setCameraDistanceActivated(activated) -- KepchiK
   memory.setuint8(0xB6F028 + 0x38, activated)
   memory.setuint8(0xB6F028 + 0x39, activated)
end

function setCameraDistance(distance) -- KepchiK
   memory.setfloat(0xB6F028 + 0xD4, distance)
   memory.setfloat(0xB6F028 + 0xD8, distance)
   memory.setfloat(0xB6F028 + 0xC0, distance)
   memory.setfloat(0xB6F028 + 0xC4, distance)
end

function DisableUnderWaterEffects(bState) -- kin4stat
   memory.setuint8(0x52CCF9, bState and 0xEB or 0x74, false)
end

function ClearChat()
   memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
   memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
   memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
end

function AutoAd()
   lua_thread.create(function()
   while autoAnnounce do
      wait(1000*60)
      --sampAddChatMessage(" "..u8:decode(textbuffer.mpname.v)..", приз "..u8:decode(textbuffer.mpprize.v), -1)
      sampSendChat("/об "..u8:decode(textbuffer.mpname.v)..", приз "..u8:decode(textbuffer.mpprize.v), -1)
   end   
   end)
end

function Recon(delay)
   lua_thread.create(function()
   sampDisconnectWithReason(quit)
   wait(delay)
   local ip, port = sampGetCurrentServerAddress()
   sampConnectToServer(ip, port) 
   end)
end

function PlayerWarnings()
   lua_thread.create(function()
   while isWarningsActive do
      wait(1000*30)
      for k, handle in ipairs(getAllChars()) do
      --for k, v in pairs(playersTable) do
         local res, id = sampGetPlayerIdByCharHandle(handle)
        -- local res, handle = sampGetCharHandleBySampPlayerId(v)
         if res then
            local nickname = sampGetPlayerNickname(id)
            local weaponid = getCurrentCharWeapon(handle)
            local px, py, pz = getCharCoordinates(handle)
            local health = sampGetPlayerHealth(id)
            local armor = sampGetPlayerArmor(id)
            local ping = sampGetPlayerPing(id)
            local afk = sampIsPlayerPaused(id)
            
            if warnings.undermap then
               if pz < 0.5 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] возможно находится под картой",
                  nickname, id), -1)
               elseif pz > 1000.0 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] длит в небе (высота: %d)",
                  nickname, id, pz), -1)
               end
            end
            
            if warnings.heavyweapons then
               if weaponid == 38 or weaponid == 35 or weaponid == 36 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] держит в руках тяжелое оружие! (%s [%d])",
                  nickname, id, weaponNames[weaponid], weaponid), -1)
               end
            end
            
            if warnings.illegalweapons then
               --print(weaponid)
               for key, value in pairs(legalweapons) do
                  if value ~= weaponid and weaponid > 1 then
                     sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] держит в руках нелегальное оружие! (%s [%d])",
                     nickname, id, weaponNames[weaponid], weaponid), -1)
                     break
                  end
               end
            end
            
            if warnings.hprefil then
               if checkbox.healthcheck.v then
                  print(health, tonumber(textbuffer.mphp.v))
                  if health > tonumber(textbuffer.mphp.v) then
                     sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] hp: %d превышает разрешенное значение! (max: %d)",
                     nickname, id, health, tonumber(textbuffer.mphp.v)), -1)
                  end
               end
            end
            
            if warnings.armourrefill then
               if checkbox.healthcheck.v then
                  if armour > tonumber(textbuffer.mparmour.v) then
                     sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] armour: %d превышает разрешенное значение! (max: %d)",
                     nickname, id, armour, tonumber(textbuffer.mparmour.v)), -1)
                  end
               end
            end
            
            if warnings.laggers then
               if ping > 50 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] лагер! (ping %d)",
                  nickname, id, ping), -1)
               end
            end
            
            if warnings.afk then
               if afk then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] в AFK",
                  nickname, id), -1)
               end
            end
         end
      end
   end   
   end)
end

function Restream()
   lua_thread.create(function()
   sampAddChatMessage('Начинается процесс рестрима', -1)
   tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(PLAYER_PED)
   if isAbsolutePlay then
      sampSendChat(string.format("/ngr %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z+1000.0), 0x0FFFFFF)
   elseif isTraining then
      sampSendChat(string.format("/xyz %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z+1000.0), 0x0FFFFFF)
   else
      setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z+1000.0)
   end
   wait(5000)
   if isAbsolutePlay then
      sampSendChat(string.format("/ngr %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
   elseif isTraining then
      sampSendChat(string.format("/xyz %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
   else
      setCharCoordinates(PLAYER_PED, tpcpos.x, tpcpos.y, tpcpos.z)
   end
   sampAddChatMessage('Рестрим завершен', -1)
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

function enterEditObject()
   -- There are no parameters, just send this RPC to the player
   local bs = raknetNewBitStream()
   raknetEmulRpcReceiveBitStream(27, bs)
   raknetDeleteBitStream(bs)
end

function cancelEdit()
   -- There are no parameters, just send this RPC to the player
   local bs = raknetNewBitStream()
   raknetEmulRpcReceiveBitStream(28, bs)
   raknetDeleteBitStream(bs)
end
 
function setMaterialObjectText(id, materialType, materialId, materialSize, fontName, fontSize, bold, fontColor, backGroundColor, align, text)
   local bs = raknetNewBitStream()
   raknetBitStreamWriteInt16(bs,id)
   raknetBitStreamWriteInt8(bs, type)
   raknetBitStreamWriteInt8(bs, materialId)
   raknetBitStreamWriteInt8(bs, materialSize)
   raknetBitStreamWriteString(bs, fontName)
   raknetBitStreamWriteInt8(bs, fontSize)
   raknetBitStreamWriteInt8(bs, bold)
   raknetBitStreamWriteInt32(bs, fontColor)
   raknetBitStreamWriteInt32(bs, backGroundColor)
   raknetBitStreamWriteInt8(bs, align)
   --raknetBitStreamEncodeString(bs, text)
   raknetBitStreamWriteString(bs, text)
   raknetEmulRpcReceiveBitStream(84,bs)
   raknetDeleteBitStream(bs)
end

function setMaterialObject(id, materialType, materialId, model, libraryName, textureName, color)
   local bs = raknetNewBitStream()
   raknetBitStreamWriteInt16(bs,id)
   raknetBitStreamWriteInt8(bs,materialType)
   raknetBitStreamWriteInt8(bs,materialId)
   raknetBitStreamWriteInt16(bs,model)
   raknetBitStreamWriteInt8(bs,#libraryName)
   raknetBitStreamWriteString(bs,libraryName)
   raknetBitStreamWriteInt8(bs,#textureName)
   raknetBitStreamWriteString(bs,textureName)
   raknetBitStreamWriteInt32(bs,color)
   raknetEmulRpcReceiveBitStream(84,bs)
   raknetDeleteBitStream(bs)
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
   textbuffer.rule1.v = " "
   textbuffer.rule2.v = " "
   textbuffer.rule3.v = " "
   textbuffer.rule4.v = " "
   textbuffer.rule5.v = " "
   textbuffer.rule6.v = " "
   textbuffer.rule7.v = " "
   textbuffer.rule8.v = " "
end

function reloadBindsFromConfig()
   textbuffer.rule1.v = u8(ini.binds.customrule1)
   textbuffer.rule2.v = u8(ini.binds.customrule2)
   textbuffer.rule3.v = u8(ini.binds.customrule3)
   textbuffer.rule4.v = u8(ini.binds.customrule4)
   textbuffer.rule5.v = u8(ini.binds.customrule5)
   textbuffer.rule6.v = u8(ini.binds.customrule6)
   textbuffer.rule7.v = u8(ini.binds.customrule7)
   textbuffer.rule8.v = u8(ini.binds.customrule8)
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

function getMDO(id_obj) -- by Gorskin 
   local mem_obj = callFunction(4210080, 1, 1, id_obj)
   return mem_obj + 24
end

function cyrillic(text)
      local convtbl = {[230]=155,[231]=159,[247]=164,[234]=107,[250]=144,[251]=168,[254]=171,[253]=170,[255]=172,[224]=97,[240]=112,[241]=99,[226]=162,[228]=154,[225]=151,[227]=153,[248]=165,[243]=121,[184]=101,[235]=158,[238]=111,[245]=120,[233]=157,[242]=166,[239]=163,[244]=63,[237]=174,[229]=101,[246]=36,[236]=175,[232]=156,[249]=161,[252]=169,[215]=141,[202]=75,[204]=77,[220]=146,[221]=147,[222]=148,[192]=65,[193]=128,[209]=67,[194]=139,[195]=130,[197]=69,[206]=79,[213]=88,[168]=69,[223]=149,[207]=140,[203]=135,[201]=133,[199]=136,[196]=131,[208]=80,[200]=133,[198]=132,[210]=143,[211]=89,[216]=142,[212]=129,[214]=137,[205]=72,[217]=138,[218]=167,[219]=145}
      local result = {}
      for i = 1, #text do
          local c = text:byte(i)
          result[i] = string.char(convtbl[c] or c)
      end
      return table.concat(result)
end

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

   if imgui.IsItemHovered() then
      imgui.BeginTooltip()
         imgui.PushTextWrapPos(500)
            imgui.TextUnformatted(link)
            --imgui.TextColored(imgui.ImVec4(0.00, 0.471, 1.00, 1.00), link)
         imgui.PopTextWrapPos()
      imgui.EndTooltip()
   end
end

-- function imgui.InputTextWithHint(lable, val, hint, hintpos)
   -- local hint = hint and hint or ''
   -- local hintpos = tonumber(hintpos) and tonumber(hintpos) or 1
   -- local cPos = imgui.GetCursorPos()
   -- local result = imgui.InputText(lable, val)
   -- if #val.v == 0 then
       -- local hintSize = imgui.CalcTextSize(hint)
       -- if hintpos == 2 then imgui.SameLine(cPos.x + (hintSize.x) / 2)
       -- elseif hintpos == 3 then imgui.SameLine(cPos.x + (hintSize.x - 10))
       -- else imgui.SameLine(cPos.x + 10) end
       -- imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 0.40), tostring(hint))
   -- end
   -- return result
-- end

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
script_author("1NS")
script_name("Mapping Toolkit")
script_description("Assistant for mappers and event makers")
script_dependencies('imgui', 'lib.samp.events')
script_properties("work-in-pause")
script_url("https://github.com/ins1x/MappingToolkit")
script_version("3.3")
-- script_moonloader(16) moonloader v.0.26
-- sa-mp version: 0.3.7 R1
-- Activaton: ALT + X (show main menu) or command /toolkit

require 'lib.moonloader'
local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

-------------- [ cfg ] ---------------
local inicfg = require 'inicfg'
local configIni = "mappingtoolkit.ini"
local ini = inicfg.load({
   settings =
   {
      anticaps = false,
      anticapsads = false,
      allchatoff = false,
      autodevmode = true,
      autoengine = false,
      camdist = "1",
      checkupdates = true,
      chathideip = false,
      chatfilter = true,
      chatmentions = false,
      debug = false,
      disconnectreminder = false,
      drawdist = "450",
      editkey = true,
      extendedmenues = true,
      fov = 70,
      fog = "200",
      freezechat = false,
      hotkeys = true,
      imguifont = "trebucbd",
      imguifontsize = 14.0,
      lockserverweather = false,
      playerwarnings = false,
      renderfont = "Arial",
      renderfontsize = 7,
      rendercolor = "{80FFFFFF}",
      remapnum = false,
      restoreobjectpos = false,
      reminderdelay = 15,
      saveskin = false,
      setgm = false,
	  showobjectrot = false,
      showobjectcoord = false,
      showhud = true,
      skinid = 27,
      tabclickcopy = false,
      time = 12,
      usecustomcamdist = false,
      weather = 0,
      worldsavereminder = false,
   },
   panel =
   {
      background = true,
      fontname = "Tahoma",
      fontsize = 7,
      showpanel = false,
      position = 0, -- position (0 = bottom pos, 1 = upper pos)
      showfps = true,
      showmode = true,
      showstreamed = true,
      showlastobject = true,
      showlasttxd = true,
   },
   warnings = {
      afk = true,
      armourrefill = true,
      heavyweapons = true,
      hprefill = true,
      illegalweapons = true,
      laggers = true,
      undermap = true,
   },
   binds =
   {
      cmdbind1 = " ",
      cmdbind2 = " ",
      cmdbind3 = " ",
      cmdbind4 = " ",
      cmdbind5 = " ",
      cmdbind6 = " ",
      cmdbind7 = " ",
      cmdbind8 = " ",
      cmdbind9 = " "
   }
}, configIni)
inicfg.save(ini, configIni)
--------------------------------------

objectsrenderfont = renderCreateFont(ini.settings.renderfont, ini.settings.renderfontsize, 5)
backgroundfont = renderCreateFont(ini.panel.fontname, ini.panel.fontsize, 5)
local defaultfont = nil
local sizeX, sizeY = getScreenResolution()
local v = nil
local color = imgui.ImFloat4(1, 0, 0, 1)

local isAbsolutePlay = false
local isTraining = false
local isAbsfixInstalled = false
local isPlayerSpectating = false
local isWorldHoster = false
local isWorldJoinUnavailable = false
local disableObjectCollision = false
local showobjectsmodel = false
local chosenplayer = nil
local chosenvehicle = nil
local tabselectedplayer = nil
local hide3dtexts = false
local editResponse = 0 
local editMode = 0
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
local firstSpawn = true
local formatChat = true
local autodevmenutoggle = false
local readonly = true
local minigame = nil
local fps = 0
local fps_counter = 0
local vehinfomodelid = 0 
local lastDialogInput = nil

local objectsCollisionDel = {}
local playersTable = {}
local vehiclesTable = {}
local hiddenObjects = {}
local chatbuffer = {}
local blacklist = {}
local chatfilter = {}
-- should be global!
vehiclesTotal = 0
playersTotal = 0
streamedObjects = 0 

local legalweapons = {0, 1}
local fixcam = {x = 0.0, y = 0.0, z = 0.0}
local tpcpos = {x = 0.0, y = 0.0, z = 0.0}
local worldspawnpos = {x = 0.0, y = 0.0, z = 0.0}

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
   showobjectcoord = imgui.ImBool(ini.settings.showobjectcoord),
   restoreobjectpos = imgui.ImBool(ini.settings.restoreobjectpos),
   chatmentions = imgui.ImBool(ini.settings.chatmentions),
   checkupdates= imgui.ImBool(ini.settings.checkupdates),
   hotkeys = imgui.ImBool(ini.settings.hotkeys),
   tabclickcopy = imgui.ImBool(ini.settings.tabclickcopy),
   freezechat = imgui.ImBool(ini.settings.freezechat),
   allchatoff = imgui.ImBool(ini.settings.allchatoff),
   chatfilter = imgui.ImBool(ini.settings.chatfilter),
   playerwarnings = imgui.ImBool(ini.settings.playerwarnings),
   worldsavereminder = imgui.ImBool(ini.settings.worldsavereminder),
   autodevmode = imgui.ImBool(ini.settings.autodevmode),
   autoengine = imgui.ImBool(ini.settings.autoengine),
   setgm = imgui.ImBool(ini.settings.setgm),
   saveskin = imgui.ImBool(ini.settings.saveskin),
   chathideip = imgui.ImBool(ini.settings.chathideip),
   anticaps = imgui.ImBool(ini.settings.anticaps),
   anticapsads = imgui.ImBool(ini.settings.anticapsads),
   remapnum = imgui.ImBool(ini.settings.remapnum),
   editkey = imgui.ImBool(ini.settings.editkey),
   skinid = imgui.ImInt(ini.settings.skinid),
   showpanel = imgui.ImBool(ini.panel.showpanel),
   showobjectsmodel = imgui.ImBool(false),
   showobjectsname = imgui.ImBool(false),
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
   mpprize = imgui.ImBool(false),
   objectscale = imgui.ImBool(false),
   stepteleport = imgui.ImBool(false),
   freezepos = imgui.ImBool(false),
   searchobjectsext = imgui.ImBool(false),
   trygame = imgui.ImBool(false),
   test = imgui.ImBool(false)
}

local input = {
   hideobjectid = imgui.ImInt(615),
   mdomodel = imgui.ImInt(0),
   mdodist = imgui.ImInt(100),
   addtime = imgui.ImInt(3),
   ammo = imgui.ImInt(1000),
   rendselectedmodelid = imgui.ImInt(0)
}

local slider = {
   fog = imgui.ImInt(ini.settings.fog),
   drawdist = imgui.ImInt(ini.settings.drawdist),
   weather = imgui.ImInt(ini.settings.weather),
   time = imgui.ImInt(ini.settings.time),
   fov = imgui.ImInt(ini.settings.fov),
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
   vehiclename = imgui.ImBuffer(64),
   mpname = imgui.ImBuffer(32),
   mpadd = imgui.ImBuffer(128),
   mpprize = imgui.ImBuffer(32),
   mpdonators = imgui.ImBuffer(128),
   mphp = imgui.ImBuffer(6),
   mparmour = imgui.ImBuffer(6),
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
   pid = imgui.ImBuffer(4),
   sethp = imgui.ImBuffer(6),
   setarm = imgui.ImBuffer(6),
   setteam = imgui.ImBuffer(3),
   setreason = imgui.ImBuffer(32),
   setptime = imgui.ImBuffer(10),
   tpstep = imgui.ImBuffer(2),
   saveskin = imgui.ImBuffer(4),
   trytext = imgui.ImBuffer(64),
   searchbar = imgui.ImBuffer(32),
   rules = imgui.ImBuffer(65536),
   favorites = imgui.ImBuffer(65536),
   cblist = imgui.ImBuffer(65536)
}

local binds = {
   cmdbind1 = imgui.ImBuffer(256),
   cmdbind2 = imgui.ImBuffer(256),
   cmdbind3 = imgui.ImBuffer(256),
   cmdbind4 = imgui.ImBuffer(256),
   cmdbind5 = imgui.ImBuffer(256),
   cmdbind6 = imgui.ImBuffer(256),
   cmdbind7 = imgui.ImBuffer(256),
   cmdbind8 = imgui.ImBuffer(256),
   cmdbind9 = imgui.ImBuffer(256),
}

local combobox = {
   chatselect = imgui.ImInt(0),
   selecttable = imgui.ImInt(0),
   objects = imgui.ImInt(0),
   weaponselect = imgui.ImInt(0),
   itemad = imgui.ImInt(0),
   sitelogsource = imgui.ImInt(0),
   setmoder = imgui.ImInt(1),
   fastanswers = imgui.ImInt(0),
   gamestate = imgui.ImInt(0),
   mpnames = imgui.ImInt(0),
   logs = imgui.ImInt(0)
}

local LastObject = {
   handle = nil,
   id = nil,
   modelid = nil,
   localid = nil,
   txdid = nil,
   txdname = nil,
   txdlibname = nil,
   txdmodel = nil,
   blip = false,
   hidden = true,
   startpos = {x=0.0, y=0.0, z=0.0},
   startrot = {x=0.0, y=0.0, z=0.0},
   position = {x=0.0, y=0.0, z=0.0},
   rotation = {x=0.0, y=0.0, z=0.0}
}

local LastRemovedObject = {
   modelid = nil,
   position = {x=0.0, y=0.0, z=0.0},
   rotation = {x=0.0, y=0.0, z=0.0}
}

local worldTexturesList = {[0] = "none"}

local gamestates = {
   'None', 'Wait Connect', 'Await Join', 
   'Connected', 'Restarting', 'Disconnected'
}

local editmodes = {
   "None", "Edit", "Clone", "Remove", "Retexture"
}

local absServersNames = {
   'Deathmatch', 'Platinum', 'Titanium', 'Chromium', 'Aurum', 'Litium'
}

local trainingGamemodes = {
   "Deathmatch", "WoT", "GunGame", "Copchase", "Derby"
}

local mpNames = {
   'Custom', 'Race', 'Derby', 'Survival', 'PvP', 'Death-Roof', 'TDM',
   'Hide-n-Seek', 'Quiz', 'King', 'Hunt', 'Rodeo', 'Road Rash'
}

local fastAnswers = {
   u8"Мероприятие уже начато - вход на МП был закрыт",
   u8"Вынужден был удалить вас с МП из-за ваших лагов",
   u8"Не мешайте игрокам - кикну",
   u8"Не мешайте проведению МП - кикну",
   u8"Заходите в мир №10",
   u8"Вам необходимо перезайти в мир",
   u8"Займите свободный транспорт",
   u8"Ожидайте",
   u8"Вы тут?"
}  

local weaponNames = {
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

local VehicleNames = {
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

local absTxdNames = {
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

local AbsParticleNames = {
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

local AbsFontNames = {
   "Verdana","Comic Sans MS","Calibri",
   "Cambria","Impact","Times New Roman",
   "Palatino Linotype","Lucida Sans Unicode",
   "Lucida Console","Georgia","Franklin Gothic Medium",
   "Courier New","Corbel","Consolas",
   "Candara","Trebuchet MS","Tahoma",
   "Sylfaen","Segoe UI","Webdings",
   "Wingdings","Symbol","GTAWEAPON3"
}

-- imported tables from moonloader/resource/mappingtoolkit/data
local sampObjectModelNames = {}
local sampTextureList = {}

function main()
   if not isSampLoaded() or not isSampfuncsLoaded() then return end
      while not isSampAvailable() do wait(100) end
      
      sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Открыть меню: {CDCDCD}ALT + X", 0xFFFFFF)
      
	  reloadBindsFromConfig()
	  
	  if doesFileExist(getGameDirectory() .. "\\moonloader\\AbsoluteFix.lua") then
	     isAbsfixInstalled = true
	  end
	  
      if not doesDirectoryExist("moonloader/resource/mappingtoolkit") then 
         createDirectory("moonloader/resource/mappingtoolkit")
      end
      
      if not doesFileExist(getFolderPath(0x14) .. '\\'..ini.settings.imguifont..'.ttf') then
         ini.settings.imguifont = "trebucbd"
         ini.settings.imguifontsize = 14
      end
      
      if doesFileExist('moonloader/resource/mappingtoolkit/modules/modelsdata.lua') then
         local loadedTable, loadError = loadfile('moonloader/resource/mappingtoolkit/modules/modelsdata.lua')
         if loadedTable then 
            sampObjectModelNames = loadedTable()
         else
            print(loadError)
         end
      else
         sampAddChatMessage("[Mapping Toolkit] {696969}Modelsdata{FFFFFF} not found. Re-install script from{696969} https://github.com/ins1x/MappingToolkit/releases", 0x0FF0000)
         print("Modelsdata not found. Re-install script from https://github.com/ins1x/MappingToolkit/releases")
         thisScript():unload()
      end
      
      if doesFileExist('moonloader/resource/mappingtoolkit/modules/texturelist.lua') then
         local loadedTable, loadError = loadfile('moonloader/resource/mappingtoolkit/modules/texturelist.lua')
         if loadedTable then 
            sampTextureList = loadedTable()
         else
            print(loadError)
         end
      else
         sampAddChatMessage("[Mapping Toolkit] {696969}texturelist{FFFFFF} not found. Re-install script from{696969} https://github.com/ins1x/MappingToolkit/releases", 0x0FF0000)
         print("texturelist not found. Re-install script from https://github.com/ins1x/MappingToolkit/releases")
         thisScript():unload()
      end
      
      if doesFileExist(getGameDirectory() .. '\\moonloader\\resource\\mappingtoolkit\\favorites.txt') then
         local file = io.open(getGameDirectory() ..
         "//moonloader//resource//mappingtoolkit//favorites.txt", "r")
         textbuffer.favorites.v = file:read('*a')
         file:close()
      else
         local file = io.open(getGameDirectory() .. "/moonloader/resource/mappingtoolkit/favorites.txt", "r")
         file:write("Файл поврежден либо не найден")
         file:close()
      end
      
      if doesFileExist(getGameDirectory() .. '\\moonloader\\resource\\mappingtoolkit\\rules.txt') then
         local file = io.open(getGameDirectory() ..
         "//moonloader//resource//mappingtoolkit//rules.txt", "r")
         textbuffer.rules.v = file:read('*a')
         file:close()
      end
      
      if doesFileExist(getGameDirectory() .. '\\moonloader\\resource\\mappingtoolkit\\cblist.txt') then
         local file = io.open(getGameDirectory() ..
         "//moonloader//resource//mappingtoolkit//cblist.txt", "r")
         textbuffer.cblist.v = file:read('*a')
         file:close()
      end
      
      if doesFileExist(getGameDirectory() .. '\\moonloader\\resource\\mappingtoolkit\\blacklist.txt') then
         blacklistfile = io.open("moonloader/resource/mappingtoolkit/blacklist.txt", "r")
         for name in blacklistfile:lines() do
            table.insert(blacklist, name:lower())
         end
         blacklistfile:close()
      else
         blacklistfile = io.open("moonloader/resource/mappingtoolkit/blacklist.txt", "w")
         blacklistfile:write(" ")
         blacklistfile:close()
      end
      
      if doesFileExist(getGameDirectory() .. '\\moonloader\\resource\\mappingtoolkit\\chatfilter.txt') then
         chatfilterfile = io.open("moonloader/resource/mappingtoolkit/chatfilter.txt", "r")
         for template in chatfilterfile:lines() do
            table.insert(chatfilter, u8:decode(template))
         end
         io.close(chatfilterfile)
      else
         chatfilterfile = io.open("moonloader/resource/mappingtoolkit/chatfilter.txt", "w")
         chatfilterfile:write("%[SALE%]%:.*", "\n")
         chatfilterfile:close()
      end         
      sampRegisterChatCommand("toolkit", function() dialog.main.v = not dialog.main.v end)
	  
      -- set drawdist and figdist
      memory.setfloat(12044272, ini.settings.drawdist, true)
      memory.setfloat(13210352, ini.settings.fog, true)
	  
      if string.len(textbuffer.mpadd.v) < 1 then
         textbuffer.mpadd.v = u8"Введите ваш рекламный текст здесь"
      end
      
      if string.len(textbuffer.mpname.v) < 1 then
         textbuffer.mpname.v = u8"Введите название"
      end
      
      if string.len(textbuffer.rules.v) < 1 then
         textbuffer.rules.v = u8"Здесь вы можете загружать правила мероприятия и лор вашего мира"
      end
      
      if string.len(binds.cmdbind1.v) < 1 then
         binds.cmdbind1.v = u8"Здесь вы можете задать свои бинды"
      end
      
      textbuffer.mpprize.v = '1'
      textbuffer.setarm.v = '100'
      textbuffer.sethp.v = '100'
      textbuffer.setteam.v = '0'
      textbuffer.setptime.v = '20'
      textbuffer.vehiclename.v = 'bmx'
      
      --textbuffer.mpadd.v = u8'Проходит МП "<название>" '
      
      if ini.settings.worldsavereminder then
         SaveReminder()
      end
      
      if ini.settings.checkupdates then
         checkScriptUpdates()
      end
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
      imgui.RenderInMenu = false
      imgui.ShowCursor = true
      imgui.LockPlayer = false 
      imgui.Process = dialog.main.v
      
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
	     setTime(ini.settings.time)
         setWeather(ini.settings.weather)
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
         
      -- Hide bottombar on F10 key
      if isKeyJustPressed(0x79) and not sampIsChatInputActive() 
      and not sampIsDialogActive() and not isPauseMenuActive() 
      and not isSampfuncsConsoleActive() then 
         if ini.panel.showpanel then 
            checkbox.showpanel.v = not checkbox.showpanel.v 
         end
      end
      
      -- ALT+X (Main menu activation)
      if isKeyDown(0x12) and isKeyJustPressed(0x58) 
	  and not sampIsChatInputActive() and not sampIsDialogActive()
	  and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
         dialog.main.v = not dialog.main.v
         if ini.panel.showpanel then 
            checkbox.showpanel.v = true
         end
      end
      
      if isTraining and ini.settings.editkey then
         -- N key edit object
         if isKeyJustPressed(0x4E) and not isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not sampIsDialogActive()
	     and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
            if isWorldHoster then sampSendChat("/csel") end
         end
      end
         
      if ini.settings.hotkeys then
	     -- In onSendEditObject copy object modelid on RMB
	     if isKeyJustPressed(0x02) and editResponse == 2 and not sampIsChatInputActive() 
         and not sampIsDialogActive() and not isPauseMenuActive() 
         and not isSampfuncsConsoleActive() then 
	        setClipboardText(LastObject.modelid)
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
	     
         if isTraining and ini.settings.remapnum then
            -- PageUP <-- Num4 (and editMode == 4)
            if isKeyDown(0x21) and not sampIsChatInputActive() 
            and not sampIsDialogActive() and not isPauseMenuActive() 
            and not isSampfuncsConsoleActive() then
               setVirtualKeyDown(0x64, true)
               lua_thread.create(function()
                  wait(100)
                  setVirtualKeyDown(0x64, false)
               end)
            end
            -- PageDown <-- Num6
            if isKeyDown(0x22) and not sampIsChatInputActive() 
            and not sampIsDialogActive() and not isPauseMenuActive() 
            and not isSampfuncsConsoleActive() then
               setVirtualKeyDown(0x66, true)
               lua_thread.create(function()
                  wait(100)
                  setVirtualKeyDown(0x66, false)
               end)
            end
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
            and not isSampfuncsConsoleActive() and not minigame then
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
            
            -- H+N Vehicle menu keybind
            if isKeyDown(0x48) and isKeyJustPressed(0x4E)
	        and not sampIsChatInputActive() and not isPauseMenuActive()
	        and not isSampfuncsConsoleActive() and not minigame  then 
               sampSendChat("/tun")
            end
         end
         
         -- CTRL+O (Objects render activation)
         if isKeyDown(0x11) and isKeyJustPressed(0x4F)
	     and not sampIsChatInputActive() and not isPauseMenuActive()
	     and not isSampfuncsConsoleActive() then 
            checkbox.showobjectsmodel.v = not checkbox.showobjectsmodel.v
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
      
	  -- Count streamed objects
      streamedObjects = 0
      for _, v in pairs(getAllObjects()) do
         if isObjectOnScreen(v) then
            streamedObjects = streamedObjects + 2
         end
      end
	  
      -- Objects render
      if checkbox.showobjectsmodel.v or checkbox.showobjectsname.v and not isPauseMenuActive() then
         for _, v in pairs(getAllObjects()) do
            if isObjectOnScreen(v) then
               local _, x, y, z = getObjectCoordinates(v)
			   local px, py, pz = getCharCoordinates(PLAYER_PED)
			   if getDistanceBetweenCoords3d(px, py, pz, x, y, z) >= 2 then
			      local x1, y1 = convert3DCoordsToScreen(x,y,z)
                  if checkbox.showobjectsmodel.v then
                     renderFontDrawText(objectsrenderfont, 
                     (checkbox.showobjectsname.v
                     and ini.settings.rendercolor .. getObjectModel(v) .. " ".. tostring(sampObjectModelNames[getObjectModel(v)])
                     or ini.settings.rendercolor .. getObjectModel(v)), x1, y1, -1)
                  end
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
                  --renderFontDrawText(objectsrenderfont, "{CCFFFFFF} " .. getObjectModel(v) .." distace: ".. distance, x1, y1, -1)
                  renderFontDrawText(objectsrenderfont, "{CCFFFFFF}distace:{CCFF6600} ".. distance, x1, y1, -1)
				  renderDrawLine(x10, y10, x1, y1, 1.0, '0xCCFFFFFF')
			   end
            end
         end
	  end 
	  
      -- Collision
      if disableObjectCollision then
         local find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
         local result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
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
      if checkbox.showpanel.v and not isPauseMenuActive() then
         local x, y = getScreenResolution()
         if ini.panel.background then
            renderDrawBoxWithBorder(-2, y-15, x+2, y, 0xBF000000, 2, 0xFF000000)
         end
         
         local px, py, pz = getCharCoordinates(PLAYER_PED)
         local rendertext = string.format("%s | {3f70d6}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f{FFFFFF}", servername, px, py, pz)
         
         if ini.panel.showmode then
            if not minigame then 
               rendertext = rendertext.." | {FFD700}mode: "..editmodes[editMode+1].."{FFFFFF}"
            else
               rendertext = rendertext.." | {FFD700}minigame: "..tostring(trainingGamemodes[minigame]).."{FFFFFF}"
            end
         end
         
         if ini.panel.showfps then
            rendertext = rendertext.." | FPS: "..fps..""
         end
         
         if ini.panel.showstreamed then
            rendertext = rendertext.." | streamed: "..streamedObjects..""
         end
         
         if ini.panel.showlastobject then
            if LastObject.localid then
               rendertext = rendertext.." | {0080BC}id: "..LastObject.localid.."{FFFFFF}"
            end
            if LastObject.modelid then
               rendertext = rendertext.." | {0080BC}model: "..LastObject.modelid.."{FFFFFF}"
            end
         end       
         
         if ini.panel.showlasttxd then
            if LastObject.txdid then
               rendertext = rendertext.." | {0080BC}txdid: "..LastObject.txdid.."{FFFFFF}"
            end
         end
         renderFontDrawText(backgroundfont, rendertext, 15, y-15, 0xFFFFFFFF)
      end
      -- END main
   end
end

function imgui.BeforeDrawFrame()
   if defaultfont == nil then
      defaultfont = imgui.GetIO().Fonts:AddFontFromFileTTF(
      getFolderPath(0x14) .. '\\'..ini.settings.imguifont..'.ttf',
      ini.settings.imguifontsize, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
   end
end

function imgui.OnDrawFrame()
   imgui.PushFont(defaultfont)
   if dialog.main.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 4, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(".::  Mapping Toolkit  ::.", dialog.main, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
      
      imgui.Columns(2, "mainmenucolumns", false)
      imgui.SetColumnWidth(-1, 440)
      
      if imgui.Button(u8"Основное", imgui.ImVec2(95, 30)) then tabmenu.main = 1 end
      imgui.SameLine()
      if imgui.Button(u8"Мероприятие", imgui.ImVec2(95, 30)) then tabmenu.main = 4 end
      imgui.SameLine()
      if imgui.Button(u8"Зона стрима", imgui.ImVec2(95, 30)) then tabmenu.main = 2 end
      imgui.SameLine()
      if imgui.Button(u8"Информация", imgui.ImVec2(95, 30)) then tabmenu.main = 3 end
      
      imgui.NextColumn()
      
      imgui.SameLine()
      imgui.Text("                   ")
	  imgui.SameLine()
      if imgui.Button(u8"Свернуть", imgui.ImVec2(70, 30)) then
         dialog.main.v = not dialog.main.v
      end
      imgui.SameLine()
      
      imgui.TextQuestion("( ? )", u8"О скрипте")
      if imgui.IsItemClicked() then 
         tabmenu.main = 3
         tabmenu.info = 1
      end
      imgui.Columns(1)

      -- (Change main window size here)
      imgui.BeginChild('##main',imgui.ImVec2(640, 430), true)
      
      if tabmenu.main == 1 then

         imgui.Columns(2)
         imgui.SetColumnWidth(-1, 475)

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
			      tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(PLAYER_PED)
                  setClipboardText(string.format("%.1f %.1f %.1f", tpcpos.x, tpcpos.y, tpcpos.z))
                  sampAddChatMessage("Координаты скопированы в буфер обмена", -1)
                  local posA = getCharHeading(PLAYER_PED)
                  sampAddChatMessage(string.format("Ваши координаты: {696969}%.2f %.2f %.2f {FFFFFF}Угол поворота: {696969}%.2f", tpcpos.x, tpcpos.y, tpcpos.z, posA), -1)
                  if isAbsolutePlay and isWorldHoster then
                     sampAddChatMessage(string.format("Используйте: /тпк {696969}%.2f %.2f %.2f", tpcpos.x, tpcpos.y, tpcpos.z), -1)
                  end
                  if isTraining and isWorldHoster then
                     sampAddChatMessage(string.format("Используйте: /xyz {696969}%.2f %.2f %.2f", tpcpos.x, tpcpos.y, tpcpos.z), -1)
                  end
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Сохранить позицию", imgui.ImVec2(200, 25)) then         
			   tpcpos.x = positionX
			   tpcpos.y = positionY
			   tpcpos.z = positionZ
			   textbuffer.tpcx.v = string.format("%.2f", tpcpos.x)
			   textbuffer.tpcy.v = string.format("%.2f", tpcpos.y)
			   textbuffer.tpcz.v = string.format("%.2f", tpcpos.z)
			   tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(PLAYER_PED)
			   setClipboardText(string.format(u8"%.2f %.2f %.2f", tpcpos.x, tpcpos.y, tpcpos.z))
			   sampAddChatMessage(string.format("Координаты сохранены: {696969}%.2f %.2f %.2f", tpcpos.x, tpcpos.y, tpcpos.z), -1)
            end
            
			if imgui.Button(u8"Прыгнуть вперед", imgui.ImVec2(200, 25)) then
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
            
			if imgui.Checkbox(u8("Телепорт на координаты"), checkbox.teleportcoords) then
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
		       if imgui.InputText("##TpcxBuffer", textbuffer.tpcx, imgui.InputTextFlags.CharsDecimal) then
			      tpcpos.x = tonumber(textbuffer.tpcx.v)
			   end
			   imgui.PopItemWidth()
			   imgui.SameLine()
			   imgui.Text("y:")
			   imgui.SameLine()
			   imgui.PushItemWidth(70)
			   if imgui.InputText("##TpcyBuffer", textbuffer.tpcy, imgui.InputTextFlags.CharsDecimal) then
			      tpcpos.y = tonumber(textbuffer.tpcy.v)
			   end
			   imgui.PopItemWidth()
			   imgui.SameLine()
			   imgui.Text("z:")
			   imgui.SameLine()
			   imgui.PushItemWidth(70)
			   if imgui.InputText("##TpczBuffer", textbuffer.tpcz, imgui.InputTextFlags.CharsDecimal) then
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
			   if imgui.InputText("##TpStepBuffer", textbuffer.tpstep, imgui.InputTextFlags.CharsDecimal) then
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
		 
         if LastObject.handle and doesObjectExist(LastObject.handle) then
            if dialog.objectinfo.v then 
               if imgui.TooltipButton("(>>)", imgui.ImVec2(30, 25), u8"Скрыть параметры последнего объекта") then
                  dialog.objectinfo.v = not dialog.objectinfo.v
               end
            else
               if imgui.TooltipButton("(<<)", imgui.ImVec2(30, 25), u8"Показать параметры последнего объекта") then
                  dialog.objectinfo.v = not dialog.objectinfo.v
               end
            end             
            imgui.SameLine()
         end   
         if LastObject.modelid then
            local modelName = tostring(sampObjectModelNames[LastObject.modelid])
            imgui.Text(u8"Последний modelid объекта: "..LastObject.modelid.." ("..modelName..") ")
            if imgui.IsItemClicked() then
               setClipboardText(LastObject.modelid)
			   sampAddChatMessage("modelid скопирован в буфер обмена", -1)
            end
		 else 
		    imgui.Text(u8"Последний modelid объекта: не выбран")
         end
		 
         local closestObjectId = getClosestObjectId()
         if closestObjectId then
            local model = getObjectModel(closestObjectId)
            local modelName = tostring(sampObjectModelNames[model])
            imgui.Text(u8"Ближайший объект: "..model.." ("..modelName..") ")
         end
         
         if removedBuildings > 0 then
		    imgui.Text(string.format(u8"Удаленные стандартные объекты (removeBuilding): %i", removedBuildings))
         end
         imgui.Text(string.format(u8"Объектов в области в стрима: %i", streamedObjects))
         
         imgui.Spacing()
		 
         if imgui.Checkbox(u8("Показывать modelid объектов рядом"), checkbox.showobjectsmodel) then 
            if checkbox.drawlinetomodelid.v then checkbox.drawlinetomodelid.v = false end
		 end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Показывает modelid на объектах рядом (CTRL + O)")
         
         if imgui.Checkbox(u8("Показывать имена объектов рядом"), checkbox.showobjectsname) then 
            if not checkbox.showobjectsmodel.v then checkbox.showobjectsmodel.v = true end
            if checkbox.drawlinetomodelid.v then checkbox.drawlinetomodelid.v = false end
		 end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Добавляет имя объект к рендеру объектов рядом (CTRL + O)")
         
         
		if imgui.Checkbox(u8("Найти объекты рядом по ID модели"), checkbox.drawlinetomodelid) then
		   if checkbox.showobjectsmodel.v then checkbox.showobjectsmodel.v = false end
		   if checkbox.showobjectsname.v then checkbox.showobjectsname.v = false end
		end
		imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Рисует линию к центру объекта с указанием расстояния")
              
	    if checkbox.drawlinetomodelid.v then 
		   if LastObject.modelid and input.rendselectedmodelid.v == 0 then 
		      input.rendselectedmodelid.v = LastObject.modelid
		   end
		   
	       imgui.Text(u8"modelid объекта: ")
           imgui.SameLine()
           imgui.PushItemWidth(55)
           imgui.InputInt('##INPUT_REND_SELECTED', input.rendselectedmodelid, 0)
		   imgui.PopItemWidth()
           imgui.SameLine()
           imgui.TextQuestion("( ? )", u8"Введите modelid от 615-18300 [GTASA], 18632-19521 [SAMP]")
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
		   if LastObject.modelid and input.hideobjectid.v == 615 then 
		      input.hideobjectid.v = LastObject.modelid
		   end
		   
	       imgui.Text(u8"modelid объекта: ")
           imgui.SameLine()
           imgui.PushItemWidth(55)
           imgui.InputInt('##INPUT_HIDEOBJECT_ID', input.hideobjectid, 0)
		   imgui.PopItemWidth()
		   imgui.SameLine()
		   if imgui.Button(u8"Скрыть объект", imgui.ImVec2(110, 25)) then 
		      if string.len(input.hideobjectid.v) > 0 then 
                 if not isValidObjectModel(tonumber(input.hideobjectid.v)) then
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
		   
		   if LastObject.modelid and input.mdomodel.v == 0 then 
		      input.mdomodel.v = LastObject.modelid
		   end
		   
		   imgui.SameLine()
		   if imgui.Button(u8"Применить") then
		      if string.len(input.mdomodel.v) > 0 and string.len(input.mdodist.v) > 0 then
                 memory.setfloat(getMDO(input.mdomodel.v), input.mdodist.v, true)
		      end
		   end
		end
	    
		if imgui.Checkbox(u8("Возвращать объект на исходную позицию"), checkbox.restoreobjectpos) then
           ini.settings.restoreobjectpos = checkbox.restoreobjectpos.v
		   inicfg.save(ini, configIni)
		end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Возвращает объект на исходную позицию при отмене редактирования")
		
        if imgui.Checkbox(u8("Показывать координаты объекта при перемещении"), checkbox.showobjectcoord) then
           checkbox.showobjectrot.v = false
           ini.settings.showobjectrot = false
           ini.settings.showobjectcoord = checkbox.showobjectcoord.v
		   inicfg.save(ini, configIni)
		end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Показывает координаты объекта при перемещении в редакторе карт")
        
        if imgui.Checkbox(u8("Показывать угол поворота объекта при перемещении"), checkbox.showobjectrot) then
           checkbox.showobjectcoord.v = false
           ini.settings.showobjectcoord = false
           ini.settings.showobjectrot = checkbox.showobjectrot.v
		   inicfg.save(ini, configIni)
		end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Показывает угол поворота объекта (Rx, Ry, Rz) при перемещении в редакторе карт")
        -- if imgui.Checkbox(u8("Показывать все скрытые объекты"), checkbox.showallhiddenobjects) then
		-- end
        -- imgui.SameLine()
        -- imgui.TextQuestion("( ? )", u8"Показывает все скрытые объекты в области стрима")
        
        if imgui.Checkbox(u8("Отключить коллизию у объектов"), checkbox.objectcollision) then 
           if checkbox.objectcollision.v then
              disableObjectCollision = true
           else
           disableObjectCollision = false
           local find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(PLAYER_PED)
           local result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
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
           if LastObject.handle then
              if imgui.SliderFloat(u8"##scaleobject", slider.scale, 0.0, 50.0) then
                 setObjectScale(LastObject.handle, slider.scale.v)
              end
		   else 
		      imgui.Text(u8"Последний объект не найден")
           end
        end
        imgui.SameLine()
        imgui.TextQuestion("( ? )", u8"Визуально изменяет масштаб объекта, и растягивает его. (как в МТА)")
        
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
		    if imgui.InputText("##FixcamxBuffer", textbuffer.fixcamx, imgui.InputTextFlags.CharsDecimal) then
			   fixcam.x = tonumber(textbuffer.fixcamx.v)
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Text("y:")
			imgui.SameLine()
			imgui.PushItemWidth(70)
			if imgui.InputText("##FixcamyBuffer", textbuffer.fixcamy, imgui.InputTextFlags.CharsDecimal) then
			   fixcam.y = tonumber(textbuffer.fixcamy.v)
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.Text("z:")
			imgui.SameLine()
			imgui.PushItemWidth(70)
			if imgui.InputText("##FixcamzBuffer", textbuffer.fixcamz, imgui.InputTextFlags.CharsDecimal) then
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
	        imgui.TextColoredRGB("Дистанция камеры")
            imgui.SameLine()
            imgui.TextQuestion(u8"(по-умолчанию 1)", u8"Вернуть на значение по-умолчанию")
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
		    imgui.TextColoredRGB("FOV")
            imgui.SameLine()
            imgui.TextQuestion(u8"(по-умолчанию 70)", u8"Вернуть на значение по-умолчанию")
			if imgui.IsItemClicked() then
		       slider.fov.v = 70
		       cameraSetLerpFov(slider.fov.v, slider.fov.v, 999988888, true)
               ini.settings.fov = slider.fov.v
			   inicfg.save(ini, configIni)
		    end
		    if imgui.SliderInt(u8"##fovslider", slider.fov, 1, 179) then
               cameraSetLerpFov(slider.fov.v, slider.fov.v, 999988888, true)
               ini.settings.fov = slider.fov.v
			   inicfg.save(ini, configIni)
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
	  
         imgui.Text(string.format(u8"Объектов в области в стрима: %i", streamedObjects))
         imgui.Text(string.format(u8"Игроков в области стрима: %i",
         sampGetPlayerCount(true) - 1))
      
         imgui.Text(string.format(u8"Транспорта в области стрима: %i",
         getVehicleInStream()))
	  
	     imgui.Spacing()
	     imgui.TextColoredRGB("Дистанция прорисовки")
         imgui.SameLine()
         imgui.TextQuestion(u8"(по-умолчанию 450)", u8"Вернуть на значение по-умолчанию")
		 if imgui.IsItemClicked() then
		    slider.drawdist.v = 450
		    memory.setfloat(12044272, slider.drawdist.v, true)
            ini.settings.drawdist = slider.drawdist.v
			inicfg.save(ini, configIni)
		 end
         if imgui.SliderInt(u8"##Drawdist", slider.drawdist, 50, 3000) then
            ini.settings.drawdist = slider.drawdist.v
            inicfg.save(ini, configIni)
            memory.setfloat(12044272, ini.settings.drawdist, true)
         end
        
         imgui.TextColoredRGB("Дистанция тумана")
         imgui.SameLine()
         imgui.TextQuestion(u8"(по-умолчанию 200)", u8"Вернуть на значение по-умолчанию")
		 if imgui.IsItemClicked() then
		    slider.fog.v = 200
			memory.setfloat(13210352, slider.fog.v, true)
            ini.settings.fog = slider.fog.v
			inicfg.save(ini, configIni)
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
            if isTraining then
               if nameTag then
                  sampSendChat("/nameoff")
                  nameTag = false
               else
                  sampSendChat("/nameon")
                  nameTag = true
               end
            else
               if nameTag then
                  nameTagOff()
               else
                  nameTagOn()
               end
            end 
         end
		 
         if imgui.TooltipButton(u8"Рестрим", imgui.ImVec2(200, 25),
         u8:encode("Обновить зону стрима путем выхода из зоны стрима, и возврата через 5 сек")) then
            Restream()
		 end
		 
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
            ini.settings.lockserverweather = checkbox.lockserverweather.v
            inicfg.save(ini, configIni)
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Блокирует изменение погоды и времени сервером")
	   
	     imgui.PushItemWidth(320)
         imgui.Text(u8'Время:')
         if imgui.SliderInt('##slider.time', slider.time, 0, 24) then 
            setTime(slider.time.v)
            ini.settings.time = slider.time.v
            inicfg.save(ini, configIni)
         end
         imgui.Spacing()
         imgui.Text(u8'Погода')
         if imgui.SliderInt('##slider.weather', slider.weather, 0, 45) then 
            setWeather(slider.weather.v)
            ini.settings.weather = slider.weather.v
            inicfg.save(ini, configIni)
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
         
		 imgui.Spacing()
	  elseif tabmenu.settings == 7 then
	     
		 local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		 local score = sampGetPlayerScore(id)
		 local ip, port = sampGetCurrentServerAddress()
         
	     imgui.Text(u8'Текущий Gamestate: '..gamestates[sampGetGamestate() + 1])
		 imgui.PushItemWidth(120)
         imgui.SameLine()
		 imgui.Combo(u8'##Gamestates', combobox.gamestate, gamestates)
		 imgui.SameLine()
		 if imgui.Button(u8'Сменить') then
			sampSetGamestate(combobox.gamestate.v)
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
            sampAddChatMessage("{696969}Mapping Toolkit{FFFFFF} успешно выгружен.", -1)
            sampAddChatMessage("Для запуска используйте комбинацию клавиш {696969}CTRL + R.", -1)
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
      
         if imgui.TooltipButton(u8"очистить", imgui.ImVec2(100, 25), u8"Очистить чат (Для себя)") then
            ClearChat()
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"chatlog", imgui.ImVec2(100, 25), u8"Открыть лог чата (chatlog.txt)") then
	        os.execute('explorer '..getFolderPath(5) ..'\\GTA San Andreas User Files\\SAMP\\chatlog.txt')
	     end
         imgui.SameLine()
         if imgui.TooltipButton(u8"timestamp", imgui.ImVec2(100, 25), u8"Отображать время в чате") then
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
            ini.settings.freezechat = checkbox.freezechat.v
            inicfg.save(ini, configIni)
         end
         
         if imgui.Checkbox(u8("Скрывать IP адреса игроков в чате"), checkbox.chathideip) then
            ini.settings.chathideip = checkbox.chathideip.v
            inicfg.save(ini, configIni)
            formatChat = true
         end    
         
         if imgui.Checkbox(u8("Анти-капс в глобальном чате"), checkbox.anticaps) then
            ini.settings.anticaps = checkbox.anticaps.v
            inicfg.save(ini, configIni)
            formatChat = true
         end   
         
         if isTraining then
            if imgui.Checkbox(u8("Анти-капс для объявлений в ADS"), checkbox.anticapsads) then
               ini.settings.anticapsads = checkbox.anticapsads.v
               inicfg.save(ini, configIni)
               formatChat = true
            end
         end
         
         if imgui.Checkbox(u8("Отключить весь чат"), checkbox.allchatoff) then
            ini.settings.allchatoff = checkbox.allchatoff.v
            inicfg.save(ini, configIni)
            formatChat = true
         end     
         
         if imgui.Checkbox(u8("Копировать ник кликнутого игрока в TAB"), checkbox.tabclickcopy) then
            ini.settings.tabclickcopy = checkbox.tabclickcopy.v
		    inicfg.save(ini, configIni)
         end
         
         if isTraining then
            if imgui.Checkbox(u8("Напоминать о необходимости сохранить мир"), checkbox.worldsavereminder) then
               if checkbox.worldsavereminder.v then
                  SaveReminder()
               end
               ini.settings.worldsavereminder = checkbox.worldsavereminder.v
		       inicfg.save(ini, configIni)
            end
         end 
         
         imgui.Spacing()
	     if imgui.Button(u8"Получить id и ники игроков рядом", imgui.ImVec2(300, 25)) then
            copyNearestPlayersToClipboard()
	     end
         
      elseif tabmenu.settings == 9 then
         resetIO()
         local _, id = sampGetPlayerIdByCharHandle(playerPed)
         local nickname = sampGetPlayerNickname(id)
         local score = sampGetPlayerScore(id)
         imgui.TextColoredRGB("Ваш id: {696969}"..id)
         if imgui.IsItemClicked() then
            sampAddChatMessage("Ид скопирован в буффер обмена", -1)
            setClipboardText(id)
         end
         imgui.SameLine()
         imgui.TextColoredRGB("Ваш ник: {696969}"..nickname)
         if imgui.IsItemClicked() then
            sampAddChatMessage("Ник скопирован в буффер обмена", -1)
            setClipboardText(nickname)
         end
         imgui.SameLine()
         imgui.TextColoredRGB("Score: {696969}"..score)
         if imgui.IsItemClicked() then
            sampAddChatMessage("Счет скопирован в буффер обмена", -1)
            setClipboardText(score)
         end
         imgui.SameLine()
         imgui.TextColoredRGB(string.format("FPS: {696969}%i", fps))
         if imgui.IsItemClicked() then
            runSampfuncsConsoleCommand("fps")
         end
         
         if imgui.Button(u8"Статистика", imgui.ImVec2(100, 25)) then
            dialog.main.v = not dialog.main.v
            if isTraining then 
               sampSendChat("/stats")
            elseif isAbsolutePlay then
               sampSendChat("/стат")
            end
         end
         if isTraining then
            imgui.SameLine()
            if imgui.Button(u8"Меню игрока", imgui.ImVec2(100, 25)) then
               dialog.main.v = not dialog.main.v
               sampSendChat("/menu")
            end
         end
         imgui.Spacing()
         imgui.Spacing()
         if imgui.Checkbox(u8'Показывать дополнительную нижнюю панель', checkbox.showpanel) then
            ini.panel.showpanel = checkbox.showpanel.v
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
         
         if isTraining then
            imgui.Checkbox(u8'Устанавливать свой скин', checkbox.saveskin)
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет выставлять скин при спавне в мире")
            
            if checkbox.saveskin.v then
               imgui.PushItemWidth(50)
               imgui.InputText("##saveskin", textbuffer.saveskin, imgui.InputTextFlags.CharsDecimal)
               imgui.PopItemWidth()
               local skinid = tonumber(textbuffer.saveskin.v)
               local currentskin = getCharModel(PLAYER_PED)
               if string.len(textbuffer.saveskin.v) < 1 then
                  textbuffer.saveskin.v = tostring(currentskin)
               end
               
               imgui.SameLine()
               if imgui.Button(u8"Сменить скин", imgui.ImVec2(120, 25)) then
                  if isValidSkin(skinid) then
                     sampSendChat("/skin "..skinid)
                     sampAddChatMessage("Вы cменили скин {696969}"..currentskin.."{FFFFFF} на {696969}"..skinid, -1)
                  end
               end
               imgui.SameLine()
               if imgui.Button(u8"Сохранить скин", imgui.ImVec2(120, 25)) then
                  if isValidSkin(skinid) then
                     sampSendChat("/skin "..skinid)
                     ini.settings.saveskin = true
                     ini.settings.skinid = skinid
		             inicfg.save(ini, configIni)
                     sampAddChatMessage("Вы сохранили скин {696969}"..skinid, -1)
                  end
               end
               
            end
            
            if imgui.Checkbox(u8'Включать бессмертие в мире', checkbox.setgm) then
               sampSendChat("/gm")
               ini.settings.setgm = checkbox.setgm.v
		       inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет выставлять бессмертие при спавне в мире")
            
            if imgui.Checkbox(u8'Включать режим разработчика при входе в мир', checkbox.autodevmode) then
               ini.settings.autodevmode = checkbox.autodevmode.v
		       inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет выставлять автоматически режим разработчика в мире (необходимо для перехвата локальных ид объектов)")
            
            if imgui.Checkbox(u8'Переключение текстур на PgUp и PgDown', checkbox.remapnum) then
               ini.settings.remapnum = checkbox.remapnum.v
		       inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Заменить переключение текстур с Numpad на PgUp и PgDown (Для ноутбуков)")
     
            if imgui.Checkbox(u8'Переходить в режим редактирования на клавишу N', checkbox.editkey) then
               ini.settings.editkey = checkbox.editkey.v
		       inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет включать режим редактирования при нажатии на N")
            
            if imgui.Checkbox(u8'Завести двигатель при посадке в ТС', checkbox.autoengine) then
               ini.settings.autoengine = checkbox.autoengine.v
		       inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"При посадке в транспорт автоматически заводит двигатель")
            imgui.Spacing()
         end
      end -- end tabmenu.settings
      imgui.NextColumn()
	  
	  if imgui.Button(u8"Координаты",imgui.ImVec2(150, 30)) then tabmenu.settings = 1 end 
	  if imgui.Button(u8"Объекты",imgui.ImVec2(150, 30)) then tabmenu.settings = 2 end 
	  if imgui.Button(u8"Камера",imgui.ImVec2(150, 30)) then tabmenu.settings = 3 end 
	  if imgui.Button(u8"Прорисовка",imgui.ImVec2(150, 30)) then tabmenu.settings = 4 end 
	  if imgui.Button(u8"Погода",imgui.ImVec2(150, 30)) then tabmenu.settings = 5 end 
	  if imgui.Button(u8"Эффекты",imgui.ImVec2(150, 30)) then tabmenu.settings = 6 end 
	  if imgui.Button(u8"Чатик",imgui.ImVec2(150, 30)) then tabmenu.settings = 8 end 
      if imgui.Button(u8"Персональное",imgui.ImVec2(150, 30)) then tabmenu.settings = 9 end 
      --if imgui.Button(u8"Разное",imgui.ImVec2(150, 30)) then tabmenu.settings = 10 end 
      if ini.settings.debug then
	     if imgui.Button(u8"Дебаг",imgui.ImVec2(150, 30)) then tabmenu.settings = 7 end 
      end
      
	  
      imgui.Spacing()
      imgui.Columns(1)
       
      elseif tabmenu.main == 2 then
       resetIO()
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
          
          if getClosestPlayerId() ~= -1 then
             imgui.Text(u8"Ближайший игрок: ")
             imgui.SameLine()
             if imgui.Selectable(tostring(sampGetPlayerNickname(getClosestPlayerId())).."["..getClosestPlayerId().."]", false, 0, imgui.ImVec2(200, 15)) then
                setClipboardText(getClosestPlayerId())
                sampAddChatMessage("ID скопирован в буфер обмена", -1)
             end
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
         resetIO()
         imgui.Columns(2, "vehtableheader", false)
         imgui.SetColumnWidth(-1, 320)
         
         local closestcarhandle, closestcarid = getClosestCar()
         if closestcarhandle then
            local closestcarmodel = getCarModel(closestcarhandle)
            imgui.Text(string.format(u8"Ближайший т/с: %s [id: %i] (%i)",
            VehicleNames[closestcarmodel-399], closestcarmodel, closestcarid))
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"В скобках указан внутренний ID (/dl)")
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
         resetIO()
         
         local closestObjectId = getClosestObjectId()
         if closestObjectId then
            local model = getObjectModel(closestObjectId)
            local modelName = tostring(sampObjectModelNames[model])
            imgui.Text(u8"Ближайший объект: "..model.." ("..modelName..") ")
            local result, distance, x, y, z = getNearestObjectByModel(model)
            if result then 
	 	       imgui.Text(string.format(u8'Объект находится на расстоянии %.2f метров от вас', distance))
	 	    end	 
         end
      
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
               if imgui.IsItemClicked() then
                  setClipboardText(model)
                  sampAddChatMessage("Модель id: {696969}"..model.." {FFFFFF}скопирована в буффер обмена", -1)
               end
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
         imgui.Text(u8"Mapping Toolkit v".. thisScript().version)
         imgui.Spacing()
         imgui.TextColoredRGB("Ассистент для мапперов и организаторов мероприятий.")
         imgui.Text(u8"Скрипт распостраняется только с открытым исходным кодом.")
         imgui.TextColoredRGB("Больше информации по возможностям тулкита на ")
         imgui.SameLine()
         imgui.Link("https://github.com/ins1x/MappingToolkit/wiki/FAQ-%D0%BF%D0%BE-MappingToolkit", u8"Github-Wiki")
		 if isAbsolutePlay then
		    imgui.TextColoredRGB("Протестировать скрипт можно на Absolute DM Play в {007DFF}(/мир 10)")
            if imgui.IsItemClicked() then
               if isAbsolutePlay then sampSendChat("/мир 10") end
            end
         end
         imgui.Spacing()
         --imgui.TextColoredRGB("Нашли баг? Напишите в тему на форум по ссылкам ниже")
         imgui.TextColoredRGB("{CDCDCD}Благодарю за помощь в тестировании скрипта форумчан с ")
         imgui.SameLine()
         imgui.Link("https://forum.training-server.com/d/19708-luamappingtoolkit/", u8"TRAINING FORUM")
         imgui.Spacing()
		 if isAbsfixInstalled then
		    imgui.TextColoredRGB("Спасибо что используете ")
			imgui.SameLine()
 		    imgui.Link("https://github.com/ins1x/useful-samp-stuff/tree/main/luascripts/absolutefix", "AbsoluteFix")
		 end
		 
         imgui.Text("Homepage:")
		 imgui.SameLine()
		 imgui.Link("https://github.com/ins1x/MappingToolkit", "ins1x/MappingToolkit")
         
		 if isTraining then
            imgui.Text("Forum page:")
		    imgui.SameLine()
		    imgui.Link("https://forum.training-server.com/d/19708-luamappingtoolkit/19", "Mapping Toolkit")
         elseif isAbsolutePlay then
            imgui.Text("Forum page:")
		    imgui.SameLine()
		    imgui.Link("https://forum.gta-samp.ru/index.php?/topic/1101593-mapping-toolkit/", "Mapping Toolkit")
         end
		 -- imgui.Text(u8"YouTube:")
		 -- imgui.SameLine()
		 -- imgui.Link("https://www.youtube.com/@1nsanemapping", "1nsanemapping")
		 
         imgui.Spacing()
         imgui.Spacing()
         if imgui.Button(u8"Проверить обновления",imgui.ImVec2(170, 25)) then
            if not checkScriptUpdates() then
               sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Установлена актуальная версия {696969}"..thisScript().version, -1)
               --os.execute('explorer https://github.com/ins1x/MappingToolkit/releases')
            end
		 end
         imgui.SameLine()
         if imgui.Button(u8"Сбросить настройки",imgui.ImVec2(170, 25)) then
		    os.rename(getGameDirectory().."//moonloader//config//mappingtoolkit.ini", getGameDirectory().."//moonloader//config//backup_mappingtoolkit.ini")
            sampAddChatMessage("Настройки были сброшены на стандартные. Скрипт автоматически перезагрузится.",-1)
            sampAddChatMessage("Резервную копию ваших предыдущих настроек можно найти в moonloader/config.",-1)
            reloadScripts()
		 end
         if imgui.Checkbox(u8("Проверять обновления автоматически (без загрузки)"), checkbox.checkupdates) then
            ini.settings.checkupdates = checkbox.checkupdates.v
            inicfg.save(ini, configIni)
         end
         
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
         if isAbsolutePlay then
            imgui.Text(u8"В радиусе 150 метров нельзя создавать более 200 объектов.")
            imgui.TextColoredRGB("Максимальная длина текста на объектах в редакторе миров - {00FF00}50 символов")
         end
         
		 imgui.Spacing()
         imgui.TextColoredRGB("Лимиты в SA:MP и UG:MP : ")
		 imgui.SameLine()
		 imgui.Link("https://gtaundergroundmod.com/pages/ug-mp/documentation/limits", "https://gtaundergroundmod.com")
         imgui.TextColoredRGB("Лимиты в San Andreas: ")
		 imgui.SameLine()
		 imgui.Link("https://gtamods.com/wiki/SA_Limit_Adjuster", "https://gtamods.com/wiki/SA_Limit_Adjuster")
         

      elseif tabmenu.info == 3 then
         resetIO()
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
       
         imgui.Text(u8"RR - красная часть цвета, GG - зеленая, BB - синяя, AA - альфа")
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
               for k, txdname in pairs(absTxdNames) do
                  if k % 3 ~= 0 then imgui.SameLine() end
                  texturelink = string.format("https://textures.xyin.ws/?page=textures&limit=10&search=%s", absTxdNames[k+1])
                  texturename = string.format("%d.%s", k+1, absTxdNames[k+1])
                  imgui.Link(texturelink, texturename)
               end
            end
		 end
		 
         if imgui.CollapsingHeader(u8'Популярные текстуры') then
            if isTraining then
               imgui.TextColoredRGB("{FF6600}8660{FFFFFF} - невидимая текстура")
               imgui.TextColoredRGB("{FF6600}2643 или 64{FFFFFF} - двойной цвет (бело-чёрный)")
               imgui.TextColoredRGB("{FF6600}121{FFFFFF} - песок")
               imgui.TextColoredRGB("{FF6600}388{FFFFFF} - прозрачная текстура")
               imgui.TextColoredRGB("{FF6600}89{FFFFFF} - вода")
               imgui.TextColoredRGB("{FF6600}56 и 4853{FFFFFF} - трава")
               imgui.TextColoredRGB("{FF6600}1165 и 3123{FFFFFF} - дерево")
               imgui.TextColoredRGB("{FF6600}2864 и 3035{FFFFFF} - стекло")
               imgui.TextColoredRGB("{FF6600}2921 и 4062{FFFFFF} - белая текстура")
               imgui.TextColoredRGB("{FF6600}300{FFFFFF} - чёрная текстурка")
               imgui.TextColoredRGB("{FF6600}7838 - 7807 - 7808 - 8405 - 8406 - 8407 - 8408 - 5440 - 5441 - 5442 - 5443{FFFFFF}")
               imgui.TextColoredRGB("разные цвета (зелёный, красный, синий и т.д)")
               imgui.TextColoredRGB("{FF6600}235{FFFFFF} - стрелки")
               imgui.TextColoredRGB("{FF6600}6510{FFFFFF} - затемнение")
               imgui.TextColoredRGB("{FF6600}6439{FFFFFF} - прозрачная дверь")
               imgui.TextColoredRGB("{FF6600}6289{FFFFFF} - деревянные балки")
               imgui.TextColoredRGB("{FF6600}6239{FFFFFF} - окно")
               imgui.TextColoredRGB("{FF6600}6006{FFFFFF} - экран TВ")
               imgui.TextColoredRGB("{FF6600}4812{FFFFFF} - гараж")
               imgui.TextColoredRGB("{FF6600}4741{FFFFFF} - вентиляция")
               imgui.TextColoredRGB("{FF6600}4700{FFFFFF} - разбитое окно или двери")
               imgui.TextColoredRGB("{FF6600}3321{FFFFFF} - окно в магазинах")
               imgui.TextColoredRGB("{FF6600}3223{FFFFFF} - газета")
               imgui.TextColoredRGB("{FF6600}3124{FFFFFF} - люди, просто люди")
               imgui.TextColoredRGB("{FF6600}2519{FFFFFF} - занавес")
               imgui.TextColoredRGB("{FF6600}2410{FFFFFF} - флаги")
               imgui.TextColoredRGB("{FF6600}1847{FFFFFF} - дверь")
               imgui.TextColoredRGB("{FF6600}1665{FFFFFF} - сетка прозрачная")
               imgui.Spacing()
               imgui.TextColoredRGB("{FF6600}/tsearch <objectid> <slot> <name>{FFFFFF} - наложение текстуры по поиску")
               imgui.TextColoredRGB("{FF6600}/stexture <objectid> <slot> <index>{FFFFFF} - наложить текстуру на объект по индексу")
               imgui.TextColoredRGB("{FF6600}/untexture <objectid>{FFFFFF} - обнулить наложенные текстуры (и /ocolor)")
            end
            if isAbsolutePlay then
               imgui.TextColoredRGB("{00FF00}90{FFFFFF} - Вода из ViceCity")
               imgui.TextColoredRGB("{00FF00}118{FFFFFF} - Белый цвет, {00FF00}204{FFFFFF} - Черный цвет")
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
         local symbols = 0
         local lines = 1
         local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//favorites.txt"
         
         symbols = string.len(textbuffer.favorites.v)/2
         for s in string.gmatch(textbuffer.favorites.v, "\n" ) do
            lines = lines + 1
         end
         -- if imgui.TooltipButton(u8"Unlock IO", imgui.ImVec2(80, 25), u8:encode("разблокировать инпут если курсор забагался")) then
            -- resetIO()
         -- end
         if imgui.TooltipButton(u8"Обновить", imgui.ImVec2(80, 25), u8:encode("Загрузить избранные из файла favorites.txt")) then
            local file = io.open(filepath, "r")
            textbuffer.favorites.v = file:read('*a')
            file:close()
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"Сохранить", imgui.ImVec2(80, 25), u8:encode("Сохранить избранные в favorites.txt")) then
            if not readonly then
               local file = io.open(filepath, "w")
               file:write(textbuffer.favorites.v)
               file:close()
               sampAddChatMessage("Сохранено в файл: /moonloader/resource/mappingtoolkit/favorites.txt", -1)
            else
               sampAddChatMessage("Недоступно в режмие для чтения. Снимте режим RO (Readonly)", -1)
            end
         end 
         imgui.SameLine()
         imgui.PushItemWidth(190)
         imgui.InputText("##search", textbuffer.searchbar)
         imgui.PopItemWidth()
         imgui.SameLine()
         if imgui.TooltipButton(u8"Поиск##Search", imgui.ImVec2(60, 25), u8:encode("Поиск по тексту")) then
            local results = 0
            local resultline = 0
            if string.len(textbuffer.searchbar.v) > 0 then
               for line in io.lines(filepath) do
                  resultline = resultline + 1
                  if line:find(textbuffer.searchbar.v, 1, true) then
                     results = results + 1
                     sampAddChatMessage("Строка "..resultline.." : "..u8:decode(line), -1)
                  end
               end
            end
            if not results then
               sampAddChatMessage("Результат поиска: Не найдено", -1)
            end
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Поиск по тексту регистрозависим!")
         
         if readonly then
            imgui.InputTextMultiline('##favorites', textbuffer.favorites, imgui.ImVec2(490, 345),
            imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
         else 
            imgui.InputTextMultiline('##favorites', textbuffer.favorites, imgui.ImVec2(490, 345),
            imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
         end
         
         imgui.TextColoredRGB("Не нашли нужный объект? вам сюда")
		 imgui.SameLine()
		 imgui.Link("https://dev.prineside.com/ru/gtasa_samp_model_id/", "dev.prineside.com")
         --imgui.SameLine()
         --imgui.Text("                                      ")
         imgui.SameLine()
	     if imgui.Selectable(readonly and "RO" or "W", false, 0, imgui.ImVec2(25, 15)) then
            readonly = not readonly
         end
         imgui.SameLine()
         if imgui.Selectable("Unlock IO", false, 0, imgui.ImVec2(50, 15)) then
            resetIO()
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"RO - Включить режим ReadOnly\nUnlock IO - разблокировать инпут если курсор забагался")
         
      elseif tabmenu.info == 6 then
         if imgui.CollapsingHeader(u8"Дополнительные команды:") then
            imgui.TextColoredRGB("{696969}/toolkit{FFFFFF} - открыть главное меню тулкита")
            imgui.TextColoredRGB("{696969}/jump{FFFFFF} - прыгнуть вперед")
            imgui.TextColoredRGB("{696969}/last{FFFFFF} - последние объекты, текстуры")
            imgui.TextColoredRGB("{696969}/ответ <id>{FFFFFF} - быстрые ответы")
            imgui.TextColoredRGB("{696969}/коорд{FFFFFF} - получить текущую позицию")
            imgui.TextColoredRGB("{696969}/ocl{FFFFFF} - найти ближайший объект")
            imgui.TextColoredRGB("{696969}/odist{FFFFFF} - рисует линию к центру объекта с отображением дистанции")
            imgui.TextColoredRGB("{696969}/ocol{FFFFFF} - включить  коллизию для объектов")
            imgui.TextColoredRGB("{696969}/restream{FFFFFF} - обновить зону стрима")
            imgui.TextColoredRGB("{696969}/retcam{FFFFFF} - вернуть камеру")
            imgui.TextColoredRGB("{696969}/afkkick{FFFFFF} - кикнуть игроков в афк")
            if isTraining then
               imgui.TextColoredRGB("{696969}/cbsearch <text>{FFFFFF} - поиск информации по командным блокам")
            end
            
            if not isAbsolutePlay then
               imgui.TextColoredRGB("{696969}/отсчет <1-10>{FFFFFF} - запустить отсчет")
               imgui.TextColoredRGB("{696969}/killme{FFFFFF} - умереть (применять если вы зависли в стадии смерти)")
               imgui.TextColoredRGB("{696969}/oalpha{FFFFFF} - сделать объект полупрозрачным (Визуально")
               imgui.TextColoredRGB("{696969}/showtext3d /hidetext3d{FFFFFF} - показать id объектов (CTRL + O)")
               imgui.TextColoredRGB("{696969}/csel /editobject{FFFFFF} - включить режим выбора объекта")
            end
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
               imgui.TextColoredRGB("{00FF00}/menu{FFFFFF} - вызвать главное меню")
               imgui.TextColoredRGB("{00FF00}/мир <номер мира>{FFFFFF} - войти в мир по номеру")
               imgui.TextColoredRGB("{00FF00}/прыг{FFFFFF} - прыгнуть вперед")
               imgui.TextColoredRGB("{00FF00}/полет{FFFFFF} - уйти в режим полета в мире")
               imgui.TextColoredRGB("{00FF00}/стат <id игрока>{FFFFFF} - показать статистику игрока")
               imgui.TextColoredRGB("{00FF00}/и <id игрока>{FFFFFF} - меню игрока")
               imgui.TextColoredRGB("{00FF00}/id <часть имени>{FFFFFF} - найти id по части имени")
               imgui.TextColoredRGB("{00FF00}/тпк <x y z>{FFFFFF} - телепорт по координатам")
               imgui.TextColoredRGB("{00FF00}/коорд{FFFFFF} - узнать текущие координаты")
               imgui.TextColoredRGB("{00FF00}/выход либо /exit{FFFFFF} - выйти из мира")
               imgui.TextColoredRGB("{00FF00}/ограбить{FFFFFF} - ограбить игрока")
               imgui.TextColoredRGB("{00FF00}/п{FFFFFF} - перевернуть авто на колёса, если оно перевернулось")
               imgui.TextColoredRGB("{00FF00}/парашют{FFFFFF} - подняться в воздух с парашютом($5 000)")
               imgui.TextColoredRGB("{00FF00}/вм{FFFFFF} - перенести машину к дому($1 000)")
               imgui.TextColoredRGB("{00FF00}/машину{FFFFFF} - перенести машину к себе($1 000)")
               imgui.TextColoredRGB("{00FF00}/машину2{FFFFFF} - заказать транспорт к себе($ зависит от стоимости транспорта)")
            end
            if isTraining then
               imgui.TextColoredRGB("{FF6600}/world{FFFFFF} -  создать игровой мир")
               imgui.TextColoredRGB("{FF6600}/menu | /mm{FFFFFF} -  игровое меню")
               imgui.TextColoredRGB("{FF6600}/vw{FFFFFF} -  управление игровым миром")
               imgui.TextColoredRGB("{FF6600}/rules{FFFFFF} -  правила сервера")
               imgui.TextColoredRGB("{FF6600}/list | /world <1 пункт>{FFFFFF} -  список игровых миров")
               imgui.TextColoredRGB("{FF6600}/exit{FFFFFF} -  отправиться на спаун сервера")
               imgui.TextColoredRGB("{FF6600}/stats <id>{FFFFFF} -  посмотреть статистику игрока")
               imgui.TextColoredRGB("{FF6600}/id <name|id>{FFFFFF} -  поиск игроков по части ника | по id")
               imgui.TextColoredRGB("{FF6600}/time <0-23>{FFFFFF} -  сменить игровое время (локально)")
               imgui.TextColoredRGB("{FF6600}/weather <0-20>{FFFFFF} -  установить погоду (локально)")
               imgui.TextColoredRGB("{FF6600}/savepos{FFFFFF} -  сохранить текущую позицию и угол поворота")
               imgui.TextColoredRGB("{FF6600}/gopos{FFFFFF} -  телепортироваться на сохраненную позицию")
               imgui.TextColoredRGB("{FF6600}/xyz <x> <y> <z> <fa> {FFFFFF} -  телепортироваться на координаты")
               imgui.TextColoredRGB("{FF6600}/taser{FFFFFF} -  взять/убрать тайзер")
               imgui.TextColoredRGB("{FF6600}/accept{FFFFFF} -  принять приглашение в игровой мир")
               imgui.TextColoredRGB("{FF6600}/adminlist{FFFFFF} -  список модератов СЕРВЕРА")
               imgui.TextColoredRGB("{FF6600}/verify{FFFFFF} -  список верифицированных игроков сервера")
               imgui.TextColoredRGB("{FF6600}/nameon | /nameoff{FFFFFF} -  выключить/включить ники над головами игроков")
               imgui.TextColoredRGB("{FF6600}/slapme{FFFFFF} -  подбросить себя")
               imgui.TextColoredRGB("{FF6600}/spawnme{FFFFFF} -  заспавнить себя")
               imgui.TextColoredRGB("{FF6600}/jetpack{FFFFFF} -  [VIP] взять реактивный ранец")
               imgui.TextColoredRGB("{FF6600}/gm{FFFFFF} -  включить ГМ")
               imgui.TextColoredRGB("{FF6600}/rm{FFFFFF} -  обнулить деньги")
               imgui.TextColoredRGB("{FF6600}/rw{FFFFFF} -  обнулить оружие")
               imgui.TextColoredRGB("{FF6600}/pay <id> <money>{FFFFFF} -  передать деньги игроку")
               imgui.TextColoredRGB("{FF6600}/skill <0-999>{FFFFFF} -  установить скилл текущему оружию | > 999 -  одна рука")
               imgui.TextColoredRGB("{FF6600}/attachinfo | /attinfo <slot 0-10>{FFFFFF} - получить информацию про прикрепленный объект")
               imgui.TextColoredRGB("{FF6600}/fadd <id>{FFFFFF} - добавить игрока в список друзей")
               imgui.TextColoredRGB("{FF6600}/flist{FFFFFF} - список ваших друзей")
            end
            imgui.Spacing()
         end
         if imgui.CollapsingHeader(u8"Объекты:") then
            if isTraining then
               imgui.TextColoredRGB("{FF6600}/gate{FFFFFF} -  управление перемещаемыми объектами")
               imgui.TextColoredRGB("{FF6600}/pass <*passid>{FFFFFF} -  установить проход | <passid> редактировать")
               imgui.TextColoredRGB("{FF6600}/tpp <passid>{FFFFFF} -  телепортироваться к проходу")
               imgui.TextColoredRGB("{FF6600}/delpass <passid>{FFFFFF} -  удалить проход")
               imgui.TextColoredRGB("{FF6600}/passinfo{FFFFFF} -  редактирование ближайшего прохода")
               imgui.TextColoredRGB("{FF6600}/action{FFFFFF} -  создать 3D текст")
               imgui.TextColoredRGB("{FF6600}/editaction <actionid>{FFFFFF} -  редактировать 3D текст")
               imgui.TextColoredRGB("{FF6600}/tpaction <actoinid>{FFFFFF} -  телепортироваться к 3D тексту")
               imgui.TextColoredRGB("{FF6600}/delaction <actionid>{FFFFFF} -  удалить 3D текст")
               imgui.TextColoredRGB("{FF6600}/sel <objectid>{FFFFFF} -  выделить объект")
               imgui.TextColoredRGB("{FF6600}/oa(dd) <modelid>{FFFFFF} -  создать объект")
               imgui.TextColoredRGB("{FF6600}/od(ell) <*objectid>{FFFFFF} -  удалить объект | id только при /sel")
               imgui.TextColoredRGB("{FF6600}/ogh(ethere) <*objectid>{FFFFFF} -  телепортировать объект к себе | id при /sel")
               imgui.TextColoredRGB("{FF6600}/oinfo <*objectid>{FFFFFF} -  информация о объекте | id только при /sel")
               imgui.TextColoredRGB("{FF6600}/oswap <objectid> <modelid>{FFFFFF} -  изменить модель объекта")
               imgui.TextColoredRGB("{FF6600}/rx <objectid> <0-360>{FFFFFF} -  повернуть объект по координате X")
               imgui.TextColoredRGB("{FF6600}/ry <objectid> <0-360>{FFFFFF} -  повернуть объект по координате Y")
               imgui.TextColoredRGB("{FF6600}/rz <objectid> <0-360>{FFFFFF} -  повернуть объект по координате Z")
               imgui.TextColoredRGB("{FF6600}/ox <objectid> <m>{FFFFFF} -  сдвинуть объект по координате X")
               imgui.TextColoredRGB("{FF6600}/oy <objectid> <m>{FFFFFF} -  сдвинуть объект по координате Y")
               imgui.TextColoredRGB("{FF6600}/oz <objectid> <m>{FFFFFF} -  сдвинуть объект по координате Z")
               imgui.TextColoredRGB("{FF6600}/tpo <*objectid>{FFFFFF} -  телепортироваться к объекту | <*objectid> только при /sel")
               imgui.TextColoredRGB("{FF6600}/clone <*objectid>{FFFFFF} -  клонировать объект | <*objectid> только при /sel")
               imgui.TextColoredRGB("{FF6600}/oe(dit) <*objectid>{FFFFFF} -  редактировать объект | <*objectid> только при /sel")
               imgui.TextColoredRGB("{FF6600}/olist{FFFFFF} -  управление всеми объектами в мире")
               imgui.TextColoredRGB("{FF6600}/omenu <objectid>{FFFFFF} -  управление определенным объектом")
               imgui.TextColoredRGB("{FF6600}/osearch <name>{FFFFFF} -  поиск объекта по части имени")
               imgui.TextColoredRGB("{FF6600}/ocolor <objectid> <slot> <0xAARGBRGB>{FFFFFF} - сменить цвет объекта")
               imgui.TextColoredRGB("{FF6600}/texture <objectid> <slot> <page>{FFFFFF} - список текстур для наложения на объект")
               imgui.TextColoredRGB("{FF6600}/sindex <objectid>{FFFFFF} - перекрасить объект в зеленую текстуру и обозначить слоты")
               imgui.TextColoredRGB("{FF6600}/tsearch <objectid> <slot> <name>{FFFFFF} - наложение текстуры по поиску")
               imgui.TextColoredRGB("{FF6600}/stexture <objectid> <slot> <index>{FFFFFF} - наложить текстуру на объект по индексу")
               imgui.TextColoredRGB("{FF6600}/untexture <objectid>{FFFFFF} - обнулить наложенные текстуры (и /ocolor)")
               imgui.TextColoredRGB("{FF6600}/otext{FFFFFF} - наложение текста на слот объекта")
            end
            if isAbsolutePlay then
               imgui.TextColoredRGB("{00FF00}/tsearch <text>{FFFFFF} - поиск текстуры по названию")
               imgui.TextColoredRGB("{00FF00}/osearch <text>{FFFFFF} - поиск объекта по названию")
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
               imgui.TextColoredRGB("{FF6600}/vw{FFFFFF} -  управление игровым миром")
               imgui.TextColoredRGB("{FF6600}/int | /op{FFFFFF} -  список интерьеров для телепорта")
               imgui.TextColoredRGB("{FF6600}/team{FFFFFF} - управление командами мира")
               imgui.TextColoredRGB("{FF6600}/givevw{FFFFFF} -  передать виртуальный мир игроку")
               imgui.TextColoredRGB("{FF6600}/cancel{FFFFFF} -  отменить покупку игрового мира")
               imgui.TextColoredRGB("{FF6600}/invite <id>{FFFFFF} - пригласить игрока в мир")
               imgui.TextColoredRGB("{FF6600}/armour <0-100>{FFFFFF} - пополнить уровень брони")
               imgui.TextColoredRGB("{FF6600}/health <0-100>{FFFFFF} - пополнить уровень здоровья")
               imgui.TextColoredRGB("{FF6600}/sethp <id> <0-100>{FFFFFF} - установить игроку уровень здоровья")
               imgui.TextColoredRGB("{FF6600}/setarm <id> <0-100>{FFFFFF} - установить игроку уровень брони")
               imgui.TextColoredRGB("{FF6600}/rsethp <hp 0-100> <armour 0-100> <radius>{FFFFFF} - выдать HP и ARMOUR в радиусе")
               imgui.TextColoredRGB("{FF6600}/ress <playerid>{FFFFFF} - воскресить игрока в RP стадии")
               imgui.TextColoredRGB("{FF6600}/ressall{FFFFFF} - воскресить всех игроков в RP стадии")
               imgui.TextColoredRGB("{FF6600}/vkick <id> <*reason>{FFFFFF} - исключить игрока из мира")
               imgui.TextColoredRGB("{FF6600}/vmute <id> <time (m)> <*reason>{FFFFFF} - замутить игрока в мире")
               imgui.TextColoredRGB("{FF6600}/vban <id> <time (m) | 0 - навсегда> <*reason>{FFFFFF} - забанить игрока в мире")
               imgui.TextColoredRGB("{FF6600}/setteam <id> <teamid>{FFFFFF} - установить игроку команду")
               imgui.TextColoredRGB("{FF6600}/unteam <id>{FFFFFF} - исключить игрока из команды")
               imgui.TextColoredRGB("{FF6600}/bring, /gethere <id>{FFFFFF} - Телепортировать игрока к себе")
               imgui.TextColoredRGB("{FF6600}/goto <id>{FFFFFF} - Телепортироваться к игроку")
               imgui.TextColoredRGB("{FF6600}/vgethere <id>{FFFFFF} - Телепортировать игрока к себе вместе с машиной")
               imgui.TextColoredRGB("{FF6600}/stream | /music | /boombox{FFFFFF} - управление аудиопотоками в мире")
            end
            if imgui.CollapsingHeader(u8"Командные блоки и массивы:") then
               imgui.Text(u8"Командные блоки:")
               imgui.TextColoredRGB("{FF6600}/cb{FFFFFF} - создать командный блокам")
               imgui.TextColoredRGB("{FF6600}/cbdell{FFFFFF} - удалить блок")
               imgui.TextColoredRGB("{FF6600}/cbtp{FFFFFF} - телепортрт к блоку")
               imgui.TextColoredRGB("{FF6600}/cbedit{FFFFFF} - открыть меню блока")
               imgui.TextColoredRGB("{FF6600}/timers{FFFFFF} - список таймеров мира")
               imgui.TextColoredRGB("{FF6600}/oldcb{FFFFFF} - включить устарелые текстовые команды")
               imgui.TextColoredRGB("{FF6600}/cmb | //<text>{FFFFFF} - активировать КБ аллиас")
               imgui.TextColoredRGB("{FF6600}/cblist{FFFFFF} - список всех командных блоков в мире")
               imgui.TextColoredRGB("{FF6600}/tb{FFFFFF} - список триггер блоков в мире")
               imgui.TextColoredRGB("{FF6600}/shopmenu{FFFFFF} - управление магазинами мира для КБ")
               imgui.Text(u8"Массивы и переменные:")
               imgui.TextColoredRGB("{FF6600}/data <id>{FFFFFF} - посмотреть массивы игрока")
               imgui.TextColoredRGB("{FF6600}/setdata <id> <array 0-26> <value>{FFFFFF} - установить значение массива игроку")
               imgui.TextColoredRGB("{FF6600}/server{FFFFFF} - посмотреть серверные массивы мира")
               imgui.TextColoredRGB("{FF6600}/setserver <array 0-49> <value>{FFFFFF} - установить значение серверному массиву")
               imgui.TextColoredRGB("{FF6600}/varlist{FFFFFF} - список серверных переменных мира")
               imgui.TextColoredRGB("{FF6600}/pvarlist{FFFFFF} - список пользовательских переменных мира")
               imgui.TextColoredRGB("{FF6600}/pvar <id>{FFFFFF} - управление пользовательскими переменными игрока")

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
               imgui.TextColoredRGB("{00FF00}/мчат <текст>{FFFFFF} - сказать игрокам в мире")
               imgui.TextColoredRGB("{00FF00}/об <текст>{FFFFFF} - дать объявление")
               imgui.TextColoredRGB("{00FF00}/me <текст>{FFFFFF} - сказать от 3-го лица")
               imgui.TextColoredRGB("{00FF00}/try <текст>{FFFFFF} - удачно-неудачно")
               imgui.TextColoredRGB("{00FF00}/w /ш <текст>{FFFFFF} - сказать шепотом")
               imgui.TextColoredRGB("{00FF00}/к <текст>{FFFFFF} - крикнуть")
               imgui.TextColoredRGB("{00FF00}/лс[ид игрока] <текст>{FFFFFF} - дать объявление")
            end
            if isTraining then
               imgui.TextColoredRGB("{FF6600}/!text{FFFFFF} - глобальный чат (оранжевый)")
               imgui.TextColoredRGB("{FF6600}/@ | ;text{FFFFFF} - чат игрового мира (зеленый)")
               imgui.TextColoredRGB("{FF6600}/v | $ | ;text{FFFFFF} - чат модераторов мира")
               imgui.TextColoredRGB("{FF6600}/low | /l <text>{FFFFFF} - сказать шепотом")
               imgui.TextColoredRGB("{FF6600}/whisper | /w <text>{FFFFFF} - сказать шепотом игроку")
               imgui.TextColoredRGB("{FF6600}/try <text>{FFFFFF} - случайная вероятность действия")
               imgui.TextColoredRGB("{FF6600}/todo <text>{FFFFFF} - совмещение действия /me и публичного чата")
               imgui.TextColoredRGB("{FF6600}/dice{FFFFFF} - бросить кости")
               imgui.TextColoredRGB("{FF6600}/coin{FFFFFF} - бросить монетку")
               imgui.TextColoredRGB("{FF6600}/shout | /s <text>{FFFFFF} - крикнуть")
               imgui.TextColoredRGB("{FF6600}/me <text>{FFFFFF} - отыграть действие")
               imgui.TextColoredRGB("{FF6600}/ame <text>{FFFFFF} - отыграть действие (текст над персонажем)")
               imgui.TextColoredRGB("{FF6600}/do <text>{FFFFFF} - описать событие")
               imgui.TextColoredRGB("{FF6600}/b <text>{FFFFFF} - OOC чат")
               imgui.TextColoredRGB("{FF6600}/m <text>{FFFFFF} - сказать что то в мегафон")
               imgui.TextColoredRGB("{FF6600}/channel <0-500>{FFFFFF} - установить радио канал")
               imgui.TextColoredRGB("{FF6600}/setchannel <0-500>{FFFFFF} - установить радио канал по умолчанию в мире")
               imgui.TextColoredRGB("{FF6600}/r <text>{FFFFFF} - отправить сообщение в рацию")
               imgui.TextColoredRGB("{FF6600}/f <text>{FFFFFF} - отправить сообщение в чат команды /team")
               imgui.TextColoredRGB("{FF6600}/pm <id> <text>{FFFFFF} - отправить игроку приватное сообщение")
               imgui.TextColoredRGB("{FF6600}/reply | /rep <text>{FFFFFF} - ответить на последнее приватное сообщение")
               imgui.TextColoredRGB("{FF6600}/pchat <create|invite|accept|leave|kick>{FFFFFF} - управление персональным чатом")
               imgui.TextColoredRGB("{FF6600}/c <text>{FFFFFF} - отправить сообщение в персональный чат")
               imgui.TextColoredRGB("{FF6600}/ask <text>{FFFFFF} - задать вопрос по функционалу сервера для всех игроков")
               imgui.TextColoredRGB("{FF6600}/mute{FFFFFF} - выключить определенный чат")
               imgui.TextColoredRGB("{FF6600}/ignore <id>{FFFFFF} - занести игрока в черный список")
               imgui.TextColoredRGB("{FF6600}/unignore <id | all>{FFFFFF} - вынести игрока из черного списка | all - очистить черный список")
               imgui.TextColoredRGB("{FF6600}/ignorelist{FFFFFF} - посмотреть черный список")
            end
         end
		 if imgui.CollapsingHeader(u8"Горячие клавиши:") then
            imgui.TextColoredRGB("{696969}CTRL + O{FFFFFF} - скрыть-показать ид объектов рядом")
            if isTraining then
               imgui.TextColoredRGB("{FF6600}Клавиша M{FFFFFF} - меню управления миром")
               imgui.TextColoredRGB("{FF6600}Клавиша N{FFFFFF} - включить режим редактирования")
               imgui.Spacing()
               imgui.TextColoredRGB("В режиме ретекстура:")
               imgui.TextColoredRGB("{FFFFFF}Управление: {FF6600}Y{FFFFFF} - Текстура наверх {FF6600}N{FFFFFF} - текстура вниз")
               if ini.settings.remapnum then
                  imgui.TextColoredRGB("{FF6600}Num4{FFFFFF} Предыдущая страница, {FF6600}Num6{FFFFFF} Следующая страница")
               else
                  imgui.TextColoredRGB("{FF6600}PgUp{FFFFFF} Предыдущая страница, {FF6600}PgDown{FFFFFF} Следующая страница")
               end
               imgui.TextColoredRGB("{FF6600}Клавиша бега{FFFFFF} - принять.")
               imgui.Spacing()
               imgui.TextColoredRGB("Актеры:")
               imgui.TextColoredRGB("{FFFFFF}Навести на актера {FF6600}Клавиша бега + ПКМ{FFFFFF} - меню управления актером")
               imgui.Spacing()
               imgui.TextColoredRGB("Транспорт:")
               imgui.TextColoredRGB("{FF6600}L{FFFFFF} - открыть/закрыть транспорт")
               imgui.TextColoredRGB("{FF6600}H+N{FFFFFF} - меню тюнинга транспорта")
               imgui.TextColoredRGB("{FF6600}F{FFFFFF} - выйти из RC игрушки")
            end
            if isAbsolutePlay then
		       imgui.TextColoredRGB("{00FF00}Клавиша N{FFFFFF} - меню редактора карт (в полете)")
               imgui.TextColoredRGB("{00FF00}Клавиша J{FFFFFF} - полет в наблюдении (/полет)")
               imgui.TextColoredRGB("{00FF00}Боковые клавиши мыши{FFFFFF} - отменяют и сохраняют редактирование объекта")
               imgui.Spacing()
               imgui.TextColoredRGB("В режиме редактирования:")
               imgui.TextColoredRGB("{00FF00}Зажатие клавиши ALT{FFFFFF} - скрыть объект")
               imgui.TextColoredRGB("{00FF00}Зажатие клавиши CTRL{FFFFFF} - визуально увеличить объект")
               imgui.TextColoredRGB("{FF0000}Зажатие клавиши SHIFT{FFFFFF} - плавное перемещение объекта")
               imgui.TextColoredRGB("{00FF00}Клавиша Enter{FFFFFF}  - сохранить редактируемый объект")
               imgui.Spacing()
               imgui.TextColoredRGB("В режиме выделения:")
			   imgui.TextColoredRGB("{00FF00}Клавиша RMB (Правая кл.мыши){FFFFFF}  - скопирует номер модели объекта")
               imgui.TextColoredRGB("{FF0000}Клавиша SHIFT{FFFFFF} - переключение между объектами")
			   imgui.Spacing()
               imgui.TextColoredRGB("* {FF0000}Красным цветом{cdcdcd} обозначены функции доступные только с SAMP Addon")
            end
            imgui.TextColoredRGB("{FFFFFF}Используйте {696969}клавишу бега{FFFFFF}, для перемещения камеры во время редактирования")
            imgui.Spacing()
            if imgui.Checkbox(u8'Включить горячие клавиши', checkbox.hotkeys) then
               ini.settings.hotkeys = checkbox.hotkeys.v
		       inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Активировать дополнительные горячие клавиши")
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
			imgui.Link("https://github.com/ins1x/mtools/wiki/Texture-Studio-Commands", "Git wiki")
         end
         
      --elseif tabmenu.info == 7 then

      elseif tabmenu.info == 8 then
         resetIO()
         if isAbsolutePlay then
	        imgui.Text(u8"Интерфейс взаимодействия с сайтом")
		    imgui.SameLine()
		    imgui.SameLine()
            imgui.PushItemWidth(120)
	        imgui.Combo(u8'##ComboBoxSelectSiteLogSrc', combobox.sitelogsource, absServersNames, #absServersNames)
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
		 imgui.Spacing()
      elseif tabmenu.info == 9 then
         resetIO()
      	 imgui.TextColoredRGB("{007DFF}Prineside DevTools (Online)")
         imgui.Text(u8"В этом разделе вы можете найти объекты через сайт")
         imgui.SameLine()
         imgui.Link("https://dev.prineside.com/ru/gtasa_samp_model_id/", "dev.prineside.com")
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Все запросы перенаправляет в ваш браузер")
         imgui.Spacing()
         
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
         
         local closestObjectId = getClosestObjectId()
         if closestObjectId then
            local model = getObjectModel(closestObjectId)
            local modelName = tostring(sampObjectModelNames[model])
            imgui.TextColoredRGB("Ближайший объект: {007DFF}"..model.." ("..modelName..") ")
            if imgui.IsItemClicked() then
               textbuffer.objectid.v = tostring(model)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Нажмите на текст чтобы вставить в поиск")
         end
         if LastObject.modelid then
            local modelName = tostring(sampObjectModelNames[LastObject.modelid])
            imgui.TextColoredRGB("Последний modelid объекта: {007DFF}"..LastObject.modelid.." ("..modelName..") ")
            if imgui.IsItemClicked() then
               textbuffer.objectid.v = tostring(LastObject.modelid)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Нажмите на текст чтобы вставить в поиск")
		 end
         
         if imgui.Button(u8"Найти объекты рядом по текущей позиции",imgui.ImVec2(300, 25)) then
		    if sampIsLocalPlayerSpawned() then
               local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
               local link = string.format('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/mapsearch/?x=%i&y=%i', posX, posY)
		       os.execute(link)
		    end
	     end
         
         imgui.Spacing()
         imgui.Spacing()
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
         
         imgui.Spacing()
         imgui.TextColoredRGB("Карта объектов которые не видны редакторами карт")
		 imgui.SameLine()
		 imgui.Link("https://map.romzes.com/", "map.romzes.com")
         
      elseif tabmenu.info == 10 then
         local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//cblist.txt"
         
         if imgui.TooltipButton(u8"Unlock IO", imgui.ImVec2(80, 25), u8:encode("разблокировать инпут если курсор забагался")) then
            resetIO()
         end
         imgui.SameLine()
         imgui.PushItemWidth(190)
         imgui.InputText("##search", textbuffer.searchbar)
         imgui.PopItemWidth()
         imgui.SameLine()
         if imgui.TooltipButton(u8"Поиск##Search", imgui.ImVec2(60, 25), u8:encode("Поиск по тексту")) then
            local results = 0
            local resultline = 0
            if string.len(textbuffer.searchbar.v) > 0 then
               for line in io.lines(filepath) do
                  resultline = resultline + 1
                  if line:find(textbuffer.searchbar.v, 1, true) then
                     results = results + 1
                     sampAddChatMessage("Строка "..resultline.." : "..u8:decode(line), -1)
                  end
               end
            end
            if not results then
               sampAddChatMessage("Результат поиска: Не найдено", -1)
            end
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Поиск по тексту регистрозависим!")
            
         imgui.InputTextMultiline('##cblist', textbuffer.cblist, imgui.ImVec2(490, 370),
         imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)

      end -- end tabmenu.info
		 
      imgui.NextColumn()
      if imgui.Button(u8"Поиск", imgui.ImVec2(100, 30)) then tabmenu.info = 9 end
      if imgui.Button(u8"Избранные", imgui.ImVec2(100, 30)) then tabmenu.info = 5 end
      if imgui.Button(u8"Лимиты", imgui.ImVec2(100, 30)) then tabmenu.info = 2 end
      if imgui.Button(u8"Цвета", imgui.ImVec2(100, 30)) then tabmenu.info = 3 end
      if imgui.Button(u8"Ретекстур", imgui.ImVec2(100, 30)) then tabmenu.info = 4 end
      if imgui.Button(u8"Команды", imgui.ImVec2(100, 30)) then tabmenu.info = 6 end
      if isTraining then
         if imgui.Button(u8"КБ", imgui.ImVec2(100, 30)) then tabmenu.info = 10 end
      end
      --if imgui.Button(u8"FAQ", imgui.ImVec2(100, 30)) then tabmenu.info = 7 end
      if isAbsolutePlay then
         if imgui.Button(u8"Форум", imgui.ImVec2(100, 30)) then tabmenu.info = 8 end
      end
      if imgui.Button(u8"About", imgui.ImVec2(100, 30)) then tabmenu.info = 1 end

      imgui.Columns(1)
      
      elseif tabmenu.main == 4 then
      
         imgui.Columns(2)
         imgui.SetColumnWidth(-1, 500)
        
         local ip, port = sampGetCurrentServerAddress()
         local servername = sampGetCurrentServerName()
         
         -- TODO Add mpadd here
         -- imgui.Spacing()
         
         if tabmenu.mp == 1 then
            resetIO()
            imgui.TextColoredRGB("Сервер: {007DFF}" .. servername)
            --imgui.SameLine()
            --imgui.TextColoredRGB("IP:  {686868}" .. tostring(ip) ..":".. tostring(port))
            imgui.TextColoredRGB("Дата: {686868}" .. os.date('%d.%m.%Y %X'))
            if mpStartedDTime ~= nil then
               imgui.SameLine()
               imgui.TextColoredRGB("Началось МП в {686868}" .. mpStartedDTime)
            end
            
            imgui.Text(u8"Название мероприятия: ")
            imgui.PushItemWidth(220)
            if imgui.InputText("##BindMpname", textbuffer.mpname) then 
            end
            imgui.PopItemWidth()
            imgui.SameLine()
	        imgui.PushItemWidth(100)
            
            if imgui.Combo(u8'##ComboBoxMpNames', combobox.mpnames, mpNames, #mpNames) then
               textbuffer.mpname.v = tostring(mpNames[combobox.mpnames.v + 1])
            end
            imgui.PopItemWidth()
           
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
               playersfile = io.open("moonloader/resource/mappingtoolkit/players.txt", "w")
               
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
               playersfile = io.open("moonloader/resource/mappingtoolkit/players.txt", "r")
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
                  playersfile = io.open("moonloader/resource/mappingtoolkit/players.txt", "w")
                  
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
                  
                  if not isTraining then 
                     sampSendChat("/time")
                  end
                  sampAddChatMessage("МП начато!", -1)
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
            resetIO()
            local pid 
            local res, playerId = sampGetPlayerIdByCharHandle(playerPed)
            if string.len(textbuffer.pid.v) < 1 then
               textbuffer.pid.v = tostring(playerId)
            end
            
            if string.len(textbuffer.pid.v) > 1 
            and sampIsPlayerConnected(tonumber(textbuffer.pid.v))then
               pid = tonumber(textbuffer.pid.v)
            else
               pid = tostring(playerId)
            end             
            
            imgui.Text(u8"Для всех игроков в мире:")
            if imgui.Button(u8"Пополнить хп", imgui.ImVec2(150, 25)) then
               -- if isAbsolutePlay then
                  -- for k, v in pairs(playersTable) do
                     -- sampSendChat("/хп "..v)
                  -- end
               -- end
               if isTraining then
                  sampSendChat("/health 100")
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы пополнили хп до 100 всем игрокам в мире", 0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Пополнить броню", imgui.ImVec2(150, 25)) then
               if isTraining then
                  sampSendChat("/armour 100")
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы пополнили броню до 100 всем игрокам в мире", 0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Ресснуть игроков", imgui.ImVec2(150, 25)) then
               if isTraining then
                  sampSendChat("/ressall")
                  --sampAddChatMessage("Вы пополнили броню до 100 всем игрокам в мире", -1)
               end
            end
            
            -- if imgui.Button(u8"Изменить спавн", imgui.ImVec2(150, 25)) then
               -- if isAbsolutePlay then
                  -- sampAddChatMessage("Изменить спан можно в меню", 0x000FF00)
                  -- sampAddChatMessage("Y - Редактор миров - Управление мирами - Выбрать точку появления", 0x000FF00)
               -- end
            -- end
            imgui.Text(u8"Введите ID:")
            --imgui.SameLine()
            imgui.PushItemWidth(50)
            if imgui.InputText("##PlayerIDBuffer", textbuffer.pid, imgui.InputTextFlags.CharsDecimal) then
            end
            imgui.PopItemWidth()
           
            if pid then
               imgui.SameLine()
               imgui.Text(u8""..sampGetPlayerNickname(pid))
            end

            imgui.PushItemWidth(50)
            if imgui.InputText("##PlayerIdHp", textbuffer.sethp, imgui.InputTextFlags.CharsDecimal) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8"Установить HP", imgui.ImVec2(150, 25)) then
               sampSendChat("/sethp "..pid.." "..textbuffer.sethp.v)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы пополнили хп игроку "..pid.." до "..textbuffer.sethp.v, 0x0FF6600)
            end
            imgui.SameLine()
            imgui.Text("    ")
            imgui.SameLine()
            if imgui.Button(u8"Воскресить", imgui.ImVec2(150, 25)) then
               sampSendChat("/ress "..pid)
            end

            imgui.PushItemWidth(50)
            if imgui.InputText("##PlayerIdArmour", textbuffer.setarm, imgui.InputTextFlags.CharsDecimal) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8"Установить броню", imgui.ImVec2(150, 25)) then
               sampSendChat("/setarm "..pid.." "..textbuffer.setarm.v)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы пополнили броню игроку "..pid.." до "..textbuffer.sethp.v, 0x0FF6600)
            end
 
            imgui.PushItemWidth(50)
            if imgui.InputText("##PlayerIdTeamId", textbuffer.setteam, imgui.InputTextFlags.CharsDecimal) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8"Установить команду", imgui.ImVec2(150, 25)) then
               sampSendChat("/setteam "..pid.." "..textbuffer.setteam.v)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы установили тиму "..textbuffer.setteam.v.."{FFFFFF} игроку {696969}"..pid, 0x0FF6600)
            end
            imgui.SameLine()
            imgui.Text("    ")
            imgui.SameLine()
            if imgui.Button(u8"Обнулить команду", imgui.ImVec2(150, 25)) then
               sampSendChat("/unteam "..pid)
            end
            
            imgui.PushItemWidth(200)
            if imgui.InputText("##PlayerIdVehicle", textbuffer.vehiclename) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Укажите ID либо имя транспорта")
            imgui.SameLine()
            if imgui.Button(u8"Выдать транспорт", imgui.ImVec2(150, 25)) then
               if string.len(textbuffer.vehiclename.v) >= 3 then
                  sampSendChat("/giveveh "..pid.." "..textbuffer.vehiclename.v)
               else
                  sampAddChatMessage("Вы не указали ID транспорта", -1)
               end
            end
            
            imgui.PushItemWidth(140)
            imgui.Combo('##ComboWeaponSelect', combobox.weaponselect, weaponNames)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.PushItemWidth(50)
            imgui.InputInt("##inputAmmo", input.ammo, 0)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Укажите количество патронов")
            imgui.SameLine()
            if imgui.Button(u8"Выдать оружие", imgui.ImVec2(150, 25)) then
               if combobox.weaponselect.v == 19 or combobox.weaponselect.v == 20
               or combobox.weaponselect.v == 1 or combobox.weaponselect.v == 21 then
                  sampAddChatMessage("Некорректный выбор оружия", -1)
               else
                  sampSendChat("/givegun "..pid.." "..combobox.weaponselect.v.." "..input.ammo.v)
               end
            end
            local moderitems = {
                u8"Обнулить",
                u8"1-го уровня", 
                u8"2-го уровня", 
                u8"3-го уровня", 
                u8"4-го уровня", 
                u8"5-го уровня"
            }
            imgui.PushItemWidth(200)
            imgui.Combo(u8'##ComboBoxSetModer', combobox.setmoder, moderitems, #moderitems)
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Выдать права модератора в мире")
            imgui.SameLine()
            if imgui.Button(u8"Выдать модера", imgui.ImVec2(150, 25)) then
               sampSendChat("/setmoder "..pid.." "..combobox.setmoder.v)
            end
            
            imgui.Text(u8"Выдать наказание: ")
            imgui.PushItemWidth(200)
            if imgui.InputText(u8"причина", textbuffer.setreason) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.PushItemWidth(50)
            if imgui.InputText(u8"минут", textbuffer.setptime, imgui.InputTextFlags.CharsDecimal) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Чтобы забанить навсегда укажите 0 в графу с минутами")
            
            if imgui.Button(u8"Кикнуть игрока", imgui.ImVec2(150, 25)) then
               if string.len(textbuffer.setreason.v) >= 3 then
                  sampSendChat("/vkick "..pid.." "..textbuffer.setreason.v)
               else
                  sampAddChatMessage("Вы не указали причину", -1)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Заглушить игрока", imgui.ImVec2(150, 25)) then
               if string.len(textbuffer.setptime.v) >= 1 then
                  sampSendChat("/vmute "..pid.." "..tonumber(textbuffer.settime.v).." "..textbuffer.setreason.v)
               else
                  sampAddChatMessage("Вы не указали на какое время выдать наказание", -1)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Забанить игрока", imgui.ImVec2(150, 25)) then
               if string.len(textbuffer.setptime.v) >= 1 then
                  sampSendChat("/vban "..pid.." "..tonumber(textbuffer.settime.v).." "..textbuffer.setreason.v)
               else
                  sampAddChatMessage("Вы не указали на какое время выдать наказание", -1)
               end
            end
            
            imgui.PopItemWidth()
            
            imgui.Spacing()
         elseif tabmenu.mp == 3 then
            --resetIO()
            local symbols = 0
            local lines = 1
            local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//rules.txt"
            
            symbols = string.len(textbuffer.rules.v)/2
            for s in string.gmatch(textbuffer.rules.v, "\n" ) do
               lines = lines + 1
            end
               
            if imgui.TooltipButton(u8"Обновить", imgui.ImVec2(80, 25), u8:encode("Загрузить правила с файла rules.txt")) then
               local file = io.open(filepath, "r")
               textbuffer.rules.v = file:read('*a')
               file:close()
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Сохранить", imgui.ImVec2(80, 25), u8:encode("Сохранить правила с файла rules.txt")) then
               if not readonly then
                  local file = io.open(filepath, "w")
                  file:write(textbuffer.rules.v)
                  file:close()
                  sampAddChatMessage("Сохранено в файл: /moonloader/resource/mappingtoolkit/rules.txt", -1)
               else
                  sampAddChatMessage("Недоступно в режмие для чтения. Снимте режим RO (Readonly)", -1)
               end
            end
            -- if imgui.TooltipButton(u8"Анонсировать правила", imgui.ImVec2(150, 25), u8:encode("Анонсировать правила в чат")) then
               -- for line in io.lines(filepath) do
                  -- sampAddChatMessage(u8:decode(line), -1)
               -- end
            -- end
            imgui.SameLine()
            imgui.PushItemWidth(190)
            imgui.InputText("##search", textbuffer.searchbar)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.TooltipButton(u8"Поиск##Search", imgui.ImVec2(60, 25), u8:encode("Поиск по тексту")) then
               local results = 0
               local resultline = 0
               if string.len(textbuffer.searchbar.v) > 0 then
                  for line in io.lines(filepath) do
                     resultline = resultline + 1
                     if line:find(textbuffer.searchbar.v, 1, true) then
                        results = results + 1
                        sampAddChatMessage("Строка "..resultline.." : "..u8:decode(line), -1)
                     end
                  end
               end
               if not results then
                  sampAddChatMessage("Результат поиска: Не найдено", -1)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Поиск по тексту регистрозависим!")
            imgui.Spacing()
            if readonly then
               imgui.InputTextMultiline('##rules', textbuffer.rules, imgui.ImVec2(490, 340),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
            else 
               imgui.InputTextMultiline('##rules', textbuffer.rules, imgui.ImVec2(490, 340),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
            end

            imgui.Text("lines: "..lines.." symbols: "..symbols)
            imgui.SameLine()
            imgui.Text("                                      ")
            imgui.SameLine()
		 	if imgui.Selectable(readonly and "RO" or "W", false, 0, imgui.ImVec2(50, 15)) then
               readonly = not readonly
            end
            imgui.SameLine()
            if imgui.Selectable("Unlock IO", false, 0, imgui.ImVec2(50, 15)) then
               resetIO()
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"RO - Включить режим ReadOnly, Unlock IO - разблокировать инпут если курсор забагался")
            --imgui.Spacing()
         elseif tabmenu.mp == 4 then
             resetIO()
             
             if not isTraining then
                imgui.ColorEdit4("##ColorEdit4lite", color, imgui.ColorEditFlags.NoInputs)
                imgui.SameLine()
             end
             
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
             imgui.Spacing()
             --imgui.TextColoredRGB("МП: {696969}"..profilesNames[combobox.profiles.v+1])
             -- line 1
             imgui.Text("1.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind1", binds.cmdbind1) then 
             end
             imgui.PopItemWidth()
             -- if imgui.IsItemHovered() and imgui.IsMouseDown(1) then
                -- imgui.Text('Hovered and RMB down')
             -- end
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind1", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind1.v))
             end
             -- line 2
             imgui.Text("2.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind2", binds.cmdbind2) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind2", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind2.v))
             end
             -- line 3 
             imgui.Text("3.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind3", binds.cmdbind3) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind3", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind3.v))
             end
             -- line 4
             imgui.Text("4.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind4", binds.cmdbind4) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind4", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind4.v))
             end
             -- line 5
             imgui.Text("5.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind5", binds.cmdbind5) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind5", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind5.v))
             end
             -- line 6
             imgui.Text("6.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind6", binds.cmdbind6) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind6", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind6.v))
             end
             -- line 7
             imgui.Text("7.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind7", binds.cmdbind7) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind7", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind7.v))
             end
             -- line 8
             imgui.Text("8.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind8", binds.cmdbind8) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind8", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind8.v))
             end
             -- line 8
             imgui.Text("9.")
             imgui.SameLine()
             imgui.PushItemWidth(400)
             if imgui.InputText("##cmdbind9", binds.cmdbind9) then 
             end
             imgui.PopItemWidth()
             
             imgui.SameLine()
             if imgui.TooltipButton(u8"[>]##Sendchatcmdbind9", imgui.ImVec2(25, 25), u8:encode("Отправить в чат")) then
                sampSendChat(prefix..u8:decode(binds.cmdbind9.v))
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
                ini.binds.cmdbind1 = u8:decode(binds.cmdbind1.v)
                ini.binds.cmdbind2 = u8:decode(binds.cmdbind2.v)
                ini.binds.cmdbind3 = u8:decode(binds.cmdbind3.v)
                ini.binds.cmdbind4 = u8:decode(binds.cmdbind4.v)
                ini.binds.cmdbind5 = u8:decode(binds.cmdbind5.v)
                ini.binds.cmdbind6 = u8:decode(binds.cmdbind6.v)
                ini.binds.cmdbind7 = u8:decode(binds.cmdbind7.v)
                ini.binds.cmdbind8 = u8:decode(binds.cmdbind8.v)
                ini.binds.cmdbind9 = u8:decode(binds.cmdbind9.v)
                inicfg.save(ini, configIni)          
                sampAddChatMessage("Бинды были успешно сохранены", -1)
             end
             imgui.SameLine()
             if imgui.TooltipButton(u8"Clean", imgui.ImVec2(60, 25), u8:encode("Очистить бинды")) then
                cleanBindsForm()
             end
             imgui.SameLine()
             if imgui.TooltipButton(u8"Demo", imgui.ImVec2(60, 25), u8:encode("Установить демонстрационные значения")) then
                binds.cmdbind1.v = u8"Выдаю оружие и броню! После выдачи начинаем МП!"
                binds.cmdbind2.v = u8"Изменил спавн! Не умирайте, МП скоро начнется"
                binds.cmdbind3.v = u8"Не стоим на месте, неактивные будут удалены с МП!"
                binds.cmdbind4.v = u8"Все в строй! Кто не в строю будет удален с МП"
                binds.cmdbind5.v = u8"Скоро начнем, занимайте позиции!"
                binds.cmdbind6.v = u8"Желаем всем удачи, иии Начали!!"
                binds.cmdbind7.v = u8"Не мешаем другим игрокам, ждем начала!"
                binds.cmdbind8.v = u8"Игроки находящиеся в АФК будут удалены с МП"
                binds.cmdbind9.v = u8"Увидели нарушителя - напишите организатору!"
             end
             
	         --imgui.TextColoredRGB("* {00FF00}@ номер игрока - {bababa}заменит id на никнейм игрока.")
	         --imgui.TextColoredRGB("Цветной текст указывать через скобки (FF0000)")
             -- --imgui.Separator()
         elseif tabmenu.mp == 5 then
            resetIO()
            -- local _, playerId = sampGetPlayerIdByCharHandle(playerPed)
            -- local money = getPlayerMoney(playerPed)
            -- imgui.TextColoredRGB("{36662C}$"..money)
            if isAbsolutePlay then
               imgui.TextColoredRGB("Посмотреть свой баланс доната {696969}/donate")
               imgui.TextColoredRGB("Дать денег игроку {36662C}${FFFFFF} {696969}/giveplayermoney <id> <кол-во>")
            end
            if isTraining then
               imgui.TextColoredRGB("{FF6600}/pay <id> <money>{cdcdcd} передать деньги игроку")
            end
            
            imgui.Text(u8"Текущий приз: ")
            imgui.SameLine()
            imgui.PushItemWidth(90)
            imgui.InputText(u8"$##BindMpprize", textbuffer.mpprize, imgui.InputTextFlags.CharsDecimal)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Выдать приз всем оставшимся в мире игрокам (в виртуальной валюте)")
            if imgui.Button(u8"Выдать приз всем оставшимся", imgui.ImVec2(220, 25)) then
               if string.len(textbuffer.mpprize.v) >= 1 
               and tonumber(textbuffer.mpprize.v) >= 1 then
                  lua_thread.create(function()
                     for k, v in ipairs(getAllChars()) do
		                local res, id = sampGetPlayerIdByCharHandle(v)
                        local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                        local nick = sampGetPlayerNickname(id)
		                if res and id ~= pid then
                           sampAddChatMessage("Выдача приза игроку "..nick.."("..id..")", -1)
                           if isTraining then
                              sampSendChat("/pay "..id.." "..tonumber(textbuffer.mpprize.v), -1)
                           elseif isAbsolutePlay then
                              sampSendChat("/giveplayermoney "..id.." "..tonumber(textbuffer.mpprize.v), -1)
                           end
                           wait(500)
                        end
                     end
                  end)
               else
                  sampAddChatMessage("Не указан приз, либо указан не в числовом формате", -1)
               end
            end
            -- if isAbsolutePlay then
               -- imgui.Text(u8"Не забудьте после завершения мероприятия:")
               -- imgui.Text(u8"- Вернуть точку спавна на исходное положение")
               -- imgui.Text(u8"- Открыть мир для входа")
               -- imgui.Text(u8"- Вернуть пак оружия на стандартный")
            -- end
            
            imgui.Text(u8"Оставшиеся игроки рядом:")
            local playerscounter = 0
            for k, v in ipairs(getAllChars()) do
		       local res, id = sampGetPlayerIdByCharHandle(v)
               local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
               local nick = sampGetPlayerNickname(id)
		       if res and id ~= pid then
                  playerscounter = playerscounter + 1
                  if playerscounter >= 9 then
                     break
                  end
                  imgui.Text("  ")
                  imgui.SameLine()
		 	      imgui.Selectable(string.format("%d. %s", id, nick))
                  if imgui.IsItemClicked() then
                     if isAbsolutePlay then
                        sampSendChat("/и " .. id)
                        dialog.main.v = not dialog.main.v 
                     else
                        sampAddChatMessage("Ид {696969}"..id.."{FFFFFF} игрока {696969}"..nick.." {FFFFFF}скопирован в буффер обмена", -1)
                        setClipboardText(id) 
                     end
                  end
		       end
	 	    end
            imgui.Spacing()
	        if imgui.Button(u8"Получить id и ники игроков рядом", imgui.ImVec2(220, 25)) then
               copyNearestPlayersToClipboard()
	        end
            imgui.SameLine()
            if imgui.Button(u8"Всем спасибо!", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Спасибо за участие в МП! ')
               sampAddChatMessage("Текст скопирован в строку чата", -1)
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
            imgui.SameLine()
            if imgui.Button(u8"Победители не выходите", imgui.ImVec2(220, 25)) then
               sampSetChatInputEnabled(true)
               sampSetChatInputText('* Победители не выходите! Дождитесь выдачи приза.')
               dialog.main.v = not dialog.main.v 
	        end
            imgui.Spacing()
         elseif tabmenu.mp == 6 then
            resetIO()
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
               imgui.InputText(u8"хп", textbuffer.mphp, imgui.InputTextFlags.CharsDecimal)
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.PushItemWidth(50)
               imgui.InputText(u8"броня", textbuffer.mparmour, imgui.InputTextFlags.CharsDecimal)
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
               ini.settings.playerwarnings = checkbox.playerwarnings.v
               inicfg.save(ini, configIni)
	        end
            
            imgui.Checkbox(u8("Проверить игрока через /try"), checkbox.trygame)
            if checkbox.trygame.v then
               imgui.PushItemWidth(220)
               imgui.InputText("##trybuff", textbuffer.trytext)
               imgui.PopItemWidth()
               imgui.SameLine()
               if imgui.TooltipButton(u8"/try", imgui.ImVec2(105, 25), u8"Сыграть в try (Удачно/Неудачно)") then
                  if string.len(textbuffer.trytext.v) > 1 then
                     sampSendChat("/try "..textbuffer.trytext.v)
                  else
                     sampAddChatMessage("Введите текст сообщения", -1)
                  end
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Nick", imgui.ImVec2(105, 25), u8"Вставить ник ближайшего игрока") then
                  if getClosestPlayerId() ~= -1 then
                     textbuffer.trytext.v = tostring(sampGetPlayerNickname(getClosestPlayerId()))
                  end
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
               local afk = 0
               
	           for i = 0, sampGetMaxPlayerId(false) do
                  if sampIsPlayerConnected(i) then 
	 	             totalonline = totalonline + 1
	 	             local score = sampGetPlayerScore(i)
                     local ping = sampGetPlayerPing(i)
                     local color = sampGetPlayerColor(i)
                     --print(i, color, string.format("%x", color))
                     
                     -- white clist color 16777215
                     if ping <= 30 and score < 10 and color == 16777215 then
                        bots = bots + 1
                     end
	 	             if score > 1000 then
	 	                olds = olds + 1
	 	             elseif score >= 50 and score < 1000 then 
                        players = players + 1
                     else 
                        newbies = newbies + 1
	 	             end
                     
                     if sampIsPlayerPaused(i) then 
                        afk = afk + 1
                     end
	 	          end
               end
               if isAbsolutePlay then
                  sampAddChatMessage(string.format("Игроков в сети %i из них новички %i, постояльцы %i, олды %i (возможно боты %i)",
                  totalonline, newbies, players, olds, bots), -1)
               else
                  sampAddChatMessage(string.format("Игроков в сети %i из них AFK %i (возможно боты %i)",
                  totalonline, afk, bots), -1)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Черный список игроков", imgui.ImVec2(220, 25)) then
               sampAddChatMessage("Черный список:", -1)
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
         elseif tabmenu.mp == 7 then
            resetIO()
            
            imgui.Text(u8"Объявление: ")
            imgui.PushItemWidth(450)
            if imgui.InputText("##Mpadd", textbuffer.mpadd) then 
            end
            imgui.PopItemWidth()
            
            imgui.Text(u8"Дополнительно:")
            imgui.Checkbox(u8"Указать приз", checkbox.mpprize)
            
            if checkbox.mpprize.v then
               imgui.SameLine()
               imgui.Text(u8"Приз: ")
               imgui.SameLine()
               imgui.PushItemWidth(90)
               imgui.InputText(u8"$##BindMpprize", textbuffer.mpprize, imgui.InputTextFlags.CharsDecimal)
               imgui.PopItemWidth()
            end
            
            imgui.Checkbox(u8"Указать спонсоров", checkbox.donators)
            if checkbox.donators.v then
               imgui.Text(u8"Спонсоры:")
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
            imgui.Spacing()
            if isAbsolutePlay then
               if imgui.TooltipButton(u8"Объявить МП", imgui.ImVec2(220, 25), u8"Аннонсировать МП в объявление (/об)") then
                  if string.len(textbuffer.mpadd.v) > 0 then 
                     sampSetChatInputEnabled(true)
                     if checkbox.mpprize.v then
                        sampSetChatInputText(string.format("/об %s, приз %s", u8:decode(textbuffer.mpadd.v), u8:decode(textbuffer.mpprize.v)))
                     else
                        sampSetChatInputText(string.format("/об %s, приз %s", u8:decode(textbuffer.mpadd.v)))
                     end
                  else
                     sampAddChatMessage("Сперва укажите текст объявления!", -1)
                  end
               end
            elseif isTraining then
               if imgui.TooltipButton(u8"Объявить МП", imgui.ImVec2(220, 25), u8"Аннонсировать МП в объявление (/ads)") then
                  if string.len(textbuffer.mpadd.v) > 0 then 
                     sampSetChatInputEnabled(true)
                     if checkbox.mpprize.v then
                        sampSetChatInputText(string.format("/ads %s, приз %s", u8:decode(textbuffer.mpadd.v), u8:decode(textbuffer.mpprize.v)))
                     else
                        sampSetChatInputText(string.format("/ads %s", u8:decode(textbuffer.mpadd.v)))
                     end
                  else
                     sampAddChatMessage("Сперва укажите текст объявления!", -1)
                  end
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Протестировать", imgui.ImVec2(220, 25), u8:encode("Выведет сообщение только вам для теста")) then
               if checkbox.mpprize.v then
                  sampAddChatMessage("В объявление будет подано: "..u8:decode(textbuffer.mpadd.v)..", приз "..u8:decode(textbuffer.mpprize.v), -1)
               else
                  sampAddChatMessage("В объявление будет подано: "..u8:decode(textbuffer.mpadd.v), -1)
               end
            end
            
            imgui.Spacing()
            imgui.Text(u8"Авто-объявление:")
            if imgui.TooltipButton(autoAnnounce and u8('Отключить авто-объявление') or u8('Включить авто-объявление'), imgui.ImVec2(220, 25), u8:encode("Автоматически шлет объявление о МП")) then
               if string.len(textbuffer.mpadd.v) > 0 then 
                  autoAnnounce = not autoAnnounce
                  if autoAnnounce then
                     if checkbox.mpprize.v then
                        sampAddChatMessage("В объявление будет подано: "..u8:decode(textbuffer.mpadd.v)..", приз "..u8:decode(textbuffer.mpprize.v), -1)
                     else
                        sampAddChatMessage("В объявление будет подано: "..u8:decode(textbuffer.mpadd.v), -1)
                     end
                  end   
                  AutoAd()
               else
                  autoAnnounce = false
                  sampAddChatMessage("Сперва укажите текст объявления!", -1)
               end
            end
            
            imgui.Text(u8"Повтор авто-объявления через: ")
            imgui.PushItemWidth(150)
            if imgui.InputInt("##MpaddTime", input.addtime) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.Text(u8"мин.")
            
         end
         
         imgui.NextColumn()
         
         if imgui.Button(u8"Подготовка к МП",imgui.ImVec2(120, 30)) then tabmenu.mp = 1 end 
         if imgui.Button(u8"Объявление",imgui.ImVec2(120, 30)) then tabmenu.mp = 7 end 
         if isTraining then
            if imgui.Button(u8"Управление",imgui.ImVec2(120, 30)) then tabmenu.mp = 2 end 
         end
         if imgui.Button(u8"Быстрые команды",imgui.ImVec2(120, 30)) then tabmenu.mp = 4 end 
         if imgui.Button(u8"Проверка игроков",imgui.ImVec2(120, 30)) then tabmenu.mp = 6 end 
         if imgui.Button(u8"Правила МП",imgui.ImVec2(120, 30)) then tabmenu.mp = 3 end 
         if imgui.Button(u8"Финал МП",imgui.ImVec2(120, 30)) then tabmenu.mp = 5 end 
         
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
         if isTraining and isWorldHoster then
            sampSendChat("/ans "..chosenplayer.." "..u8:decode(textbuffer.sms.v))
         else
            sampSendChat("/pm "..chosenplayer.." "..u8:decode(textbuffer.sms.v))
         end
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
	     imgui.TextColoredRGB(string.format("Хп: %.1f  броня: %.1f", 
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
         elseif isTraining then
            sampSendChat("/sp " .. chosenplayer)
	     else
	 	    sampSendChat("/spec " .. chosenplayer)
	     end
      end
          
      if imgui.TooltipButton(u8"Меню игрока", imgui.ImVec2(220, 25), u8"Открыть серверное меню взаимодействия с игроком") then
	     if isAbsolutePlay then
            sampSendChat("/и " .. chosenplayer)
		 end
         if isTraining then
            sampSendChat("/data " .. chosenplayer)
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
			         pposX+0.5, pposY+0.5, pposZ), -1)
                  elseif isTraining then
                     sampSendChat(string.format("/xyz %f %f %f",
			         pposX+0.5, pposY+0.5, pposZ), -1)
				  else
				     setCharCoordinates(PLAYER_PED, posX+0.5, posY+0.5, posZ)
				  end
                end
            else
               sampAddChatMessage("Доступно только в редакторе карт", -1)
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
      
      if LastObject.handle and doesObjectExist(LastObject.handle) then
         local modelName = tostring(sampObjectModelNames[LastObject.modelid])
         
         if isTraining then
            imgui.TextColoredRGB("localid: {3f70d6}".. LastObject.localid)
         end
         imgui.TextColoredRGB("modelid: {3f70d6}".. LastObject.modelid)
         imgui.TextColoredRGB("name: {3f70d6}".. modelName)
         imgui.TextColoredRGB("id: {3f70d6}".. LastObject.id)
         if not LastObject.position.x ~= nil then
	        imgui.TextColoredRGB(string.format("{3f70d6}x: %.1f, {e0364e}y: %.1f, {26b85d}z: %.1f", LastObject.position.x, LastObject.position.y, LastObject.position.z))
         end   
	     if not LastObject.rotation.x ~= nil then
            imgui.TextColoredRGB(string.format("{4f70d6}rx: %.1f, {f0364e}ry: %.1f, {36b85d}rz: %.1f", LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z))
         end   
	     imgui.TextColoredRGB(string.format("angle: {3f70d6}%.1f", getObjectHeading(LastObject.handle)))
	     --imgui.TextColoredRGB("объект "..(isObjectOnScreen(LastObject.handle) and 'на экране' or 'не на экране'))
	     if not isObjectOnScreen(LastObject.handle) then 
            imgui.TextColoredRGB("{ff0000}объект вне зоны прямой видимости")
         end
         if isAbsolutePlay and LastObject.txdname ~= nil then
            for k, txdname in pairs(absTxdNames) do
               if txdname == LastObject.txdname then
                  imgui.TextColoredRGB("texture internalid: {3f70d6}" .. k-1)
                  break
               end
            end
	        imgui.TextColoredRGB("txdname: {3f70d6}".. LastObject.txdname .. " ("..LastObject.txdlibname..") ")
         end
         
         imgui.Spacing()  
         if imgui.TooltipButton(u8"Инфо по объекту (online)",imgui.ImVec2(200, 25), u8"Посмотреть подробную информацию по объекту на Prineside DevTools") then		    
            local link = 'explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/search/?q=' .. LastObject.modelid..'"'
		    os.execute(link)
	     end
         
         if imgui.Button(u8"В буфер обмена", imgui.ImVec2(200, 25)) then
            if not LastObject.rotation.x ~= nil then
               setClipboardText(string.format("%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f", LastObject.modelid, LastObject.position.x, LastObject.position.y, LastObject.position.z, LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z))
            else
               setClipboardText(string.format("%i, %.2f, %.2f, %.2f", LastObject.modelid, LastObject.position.x, LastObject.position.y, LastObject.position.z))
            end
            sampAddChatMessage("Текcт скопирован в буфер обмена", -1)
	     end
         
         if imgui.TooltipButton(u8"Экспортировать", imgui.ImVec2(200, 25), u8"Выведет строчку в формате создания объекта для filterscript") then
            if LastObject.txdname ~= nil then
               if not LastObject.rotation.x ~= nil then
                  sampAddChatMessage(string.format("tmpobjid = CreateObject(%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f);", LastObject.modelid, LastObject.position.x, LastObject.position.y, LastObject.position.z, LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z), -1)
               else
                  sampAddChatMessage(string.format("tmpobjid = CreateObject(%i, %.2f, %.2f, %.2f);", LastObject.modelid, LastObject.position.x, LastObject.position.y, LastObject.position.z), -1)
               end
               sampAddChatMessage(string.format('SetObjectMaterial(tmpobjid, 0, %i, %s, %s, 0xFFFFFFFF);', LastObject.txdmodel, LastObject.txdlibname, LastObject.txdname), -1) 
            else 
               if not LastObject.rotation.x ~= nil then
                  sampAddChatMessage(string.format("CreateObject(%i, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f)", LastObject.modelid, LastObject.position.x, LastObject.position.y, LastObject.position.z, LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z), -1)
               else
                  sampAddChatMessage(string.format("CreateObject(%i, %.2f, %.2f, %.2f)", LastObject.modelid, LastObject.position.x, LastObject.position.y, LastObject.position.z), -1)
               end
            end
	     end
         
         if imgui.TooltipButton(u8"В избранное", imgui.ImVec2(200, 25), u8"Добавит объект в список избранных") then
            favfile = io.open(getGameDirectory() ..
            "//moonloader//resource//mappingtoolkit//favorites.txt", "a")
            favfile:write(" ,"..LastObject.modelid)
            favfile:close()
            sampAddChatMessage("Объект {696969}"..LastObject.modelid.."{FFFFFF} добавлен в файл избранных {696969}(favorites.txt)", -1)
         end
         
         if imgui.Button(u8"ТП к объекту", imgui.ImVec2(200, 25)) then
		    if LastObject.modelid and LastObject.position.x ~= 0 and doesObjectExist(LastObject.handle) then
		       if isAbsolutePlay then
		          sampSendChat(string.format("/ngr %f %f %f",
			      LastObject.position.x, LastObject.position.y, LastObject.position.z), 0x0FFFFFF)
                  sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..LastObject.modelid, -1)
               elseif isTraining then
                  sampSendChat(string.format("/xyz %f %f %f",
			      LastObject.position.x, LastObject.position.y, LastObject.position.z), 0x0FFFFFF)
                  sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..LastObject.modelid, -1)
			   else
                  sampAddChatMessage("Недосутпно для этого сервера!", -1)
			      --setCharCoordinates(PLAYER_PED, LastObject.position.x, LastObject.position.x, LastObject.position.z+0.2)
			   end
		    else
		       sampAddChatMessage("Не найден последний объект", -1)
		    end
		 end
		
		 if imgui.Button(u8(LastObject.blip and "Убрать метку с объекта" or "Поставить метку на объект"), imgui.ImVec2(200, 25)) then
		    if LastObject.handle and doesObjectExist(LastObject.handle) then
		        if LastObject.blip then
		 	      removeBlip(LastObject.blip)
		 		  LastObject.blip = nil
		 	   else
		          LastObject.blip = addBlipForObject(LastObject.handle)
		 	   end
		    else
		       sampAddChatMessage("Не найден последний объект", -1)
		    end
		 end
		
	     if imgui.Button(u8(LastObject.hidden and "Скрыть" or "Показать")..u8" объект", imgui.ImVec2(200, 25)) then
		    if LastObject.handle and doesObjectExist(LastObject.handle) then
		       if LastObject.hidden then
		          setObjectVisible(LastObject.handle, false)
		 		  LastObject.hidden = false
		 	   else
		 	      setObjectVisible(LastObject.handle, true)
		 		  LastObject.hidden = true
		 	   end
		    else
		       sampAddChatMessage("Не найден последний объект", -1)
		    end
		 end
        
         imgui.Spacing()   
      end
	  imgui.End()
   end
   imgui.PopFont()
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

function sampev.onSendEnterVehicle(vehicleId, passenger)
   if isTraining and ini.settings.autoengine and not passenger then
      local carhandle = storeCarCharIsInNoSave(PLAYER_PED)
      local state = isCarEngineOn(carhandle)
      if not state then
         lua_thread.create(function()
            wait(3500)
            setVirtualKeyDown(0x11, true)
            wait(100)
            setVirtualKeyDown(0x11, false)
         end)
      end
   end
end

function sampev.onPutPlayerInVehicle(vehicleId, seatId)
   if isTraining and ini.settings.autoengine then
      local carhandle = storeCarCharIsInNoSave(PLAYER_PED)
      local state = isCarEngineOn(carhandle)
      if not state then
         lua_thread.create(function()
            wait(500)
            setVirtualKeyDown(0x11, true)
            wait(100)
            setVirtualKeyDown(0x11, false)
         end)
      end
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
   lastDialogInput = input
   if checkbox.logdialogresponse.v then
      print(string.format("dialogId: %d, button: %d, listboxId: %d, input: %s", dialogId, button, listboxId, input))
   end
   
   if isAbsolutePlay and ini.settings.extendedmenues then
      isTexturesListOpened = false
      isSanpObjectsListOpened = false
      
      -- if player wxit from world without command drop lastWorldNumber var 
      if dialogId == 1405 and listboxId == 5 and button == 1 then
         if input:find("Войти в свой мир") then
            isWorldHoster = true
            worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
         else
            lastWorldNumber = 0
            isWorldHoster = false
         end
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
         if LastObject.txdname ~= nil then
            for k, txdname in pairs(absTxdNames) do
               if txdname == LastObject.txdname then
                  sampAddChatMessage("Последняя использованная текстура: " .. k-1, 0xFF00FF00)
                  break
               end
            end
         end
      end
      
      if dialogId == 1400 and listboxId == 4 and button == 1 and not input:find("Игрок") then
         if LastObject.txdname ~= nil then
            for k, txdname in pairs(absTxdNames) do
               if txdname == LastObject.txdname then
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
         if listboxId == 0 and input:find("Редактировать") then editMode = 1 end
         if listboxId == 2 and input:find("Переместить") then editMode = 1 end
         if listboxId == 4 and input:find("Перекрасить") then editMode = 4 end
         if listboxId == 5 and input:find("Копировать") then editMode = 2 end
         if listboxId == 17 and input:find("Информация") then editMode = 1 end
      end 
      
	  if dialogId == 1422 and listboxId == 0 and button == 1 then
         editMode = 1
      end
      
	  if dialogId == 1403 and button == 1 then
         if listboxId == 0 then editMode = 1 end
         if listboxId == 1 then 
            editMode = 3
            if LastObject.modelid then
               LastRemovedObject.modelid = LastObject.modelid
            end
         end
         if listboxId == 2 then editMode = 4 end
         if listboxId == 4 then editMode = 2 end
      end
      if dialogId == 1411 and button == 1 then
         if listboxId == 0 or listboxId == 2 then
            editMode = 3
            if LastObject.modelid then
               LastRemovedObject.modelid = LastObject.modelid
            end
         end
      end
	  if dialogId == 1409 and button == 1 then
         editMode = 1
      end
	  -- if dialogId == 1401 and button == 1 then
	     -- if undoMode then
		    -- if LastObject.handle and doesObjectExist(LastObject.handle) then
		       -- setObjectCoordinates(LastObject.handle, lastRemovedObjectCoords.x, lastRemovedObjectCoords.y, lastRemovedObjectCoords.z)
			-- end
		 -- end
	  -- end

   end
   
   -- All Training dialogId has id 32700
   if isTraining and dialogId == 32700 and ini.settings.extendedmenues then
      
      if button == 0 then 
         editDialogOpened = false
      end
      
      if button == 1 then -- if dialog response
         -- Corrects spawn item on /world menu
         if listboxId == 3 and input:find("Вернуться в свой мир") then
            if not isWorldJoinUnavailable then
               if worldspawnpos.x and worldspawnpos.x ~= 0 then
                  sampSendChat(string.format("/xyz %f %f %f",
	 	          worldspawnpos.x, worldspawnpos.y, worldspawnpos.z), 0x0FFFFFF)
               else
                  sampSendChat("/spawnme")
               end
            end
         end
         
         -- if listboxId == 2 and input:find("Создать игровой мир") then
         -- end
         -- if listboxId == 3 and input:find("Создать пробный VIP мир") then
         -- end
         if listboxId == 4 and input:find("Отправиться на спаун") then
            editMode = 0
            if not isWorldHoster and ini.settings.saveskin then
               restorePlayerSkin()
            end
         end
         
         -- Added new features to /omenu
         if listboxId == 0 and input:find("Редактировать") then 
            if LastObject.localid then 
               editMode = 1
               sampSendChat("/oedit "..LastObject.localid)
            end
         end
         --if listboxId == 1 and input:find("Клонировать") then 
         --end
         if listboxId == 2 and input:find("Удалить") then 
            editMode = 3
         end
         if listboxId == 3 and input:find("Повернуть на 90") then
            sampSendChat("/rz 90")
         end
         -- if listboxId == 4 and button == 1 and input:find("Выровнять по координатам") then
            -- if LastObject.localid and LastObject.handle and doesObjectExist(LastObject.handle) then
               -- local angle = getObjectHeading(LastObject.handle)
               -- if angle then
                  -- --enterEditObject()
                  -- setObjectHeading(LastObject.handle, getCorrectAngle(angle))
                  -- sampSendChat("/oedit")
                   -- --setObjectRotation(LastObject.handle, float rotationX, float rotationY, float rotationZ)
                  -- --sampSendChat("/rz "..LastObject.localid.." "..getCorrectAngle(angle))
                  -- --print(getCorrectAngle(angle))
               -- end
            -- end
         -- end
         if listboxId == 4 and input:find("Наложить текст") then
            sampSendChat("/otext -1")
         end
         if listboxId == 5 and input:find("Наложить текстуру") then
            if LastObject.localid then 
               editMode = 4
               showRetextureKeysHelp()
               sampSendChat("/texture 0")
            end
         end
         if listboxId == 6 and input:find("Показать индексы") then
            sampSendChat("/sindex")
         end
         if listboxId == 7 and input:find("Скрыть индексы") then
            sampSendChat("/untexture")
         end
         if listboxId == 8 and input:find("Телепортироваться") then
            sampSendChat("/tpo")
         end
         if listboxId == 9 and input:find("Информация") then
            sampSendChat("/oinfo")
         end
         
         -- Extend main /menu
         if input:find("Взять Jetpack") then
            sampSendChat("/jetpack")
         end
         if input:find("Сменить скин") then
            sampSendChat("/skin")
         end
         if input:find("Заспавнить себя") then
            sampSendChat("/spawnme")
         end
         if input:find("Слапнуть себя") then
            sampSendChat("/slapme")
         end
         if input:find("Список друзей") then
            sampSendChat("/flist")
         end
         if input:find("Ачивки") then
            sampSendChat("/ach")
         end
         -- Extend main /vw menu
         if input:find("Настройки для команд") then
            sampSendChat("/team")
         end
         if input:find("Интерьеры") then
            sampSendChat("/int")
         end
         -- Extend world manage menu
         if input:find("Список командных блоков") then
            sampSendChat("/cblist")
         end
         if input:find("Список триггер блоков") then
            sampSendChat("/tblist")
         end
         if input:find("Список таймеров") then
            sampSendChat("/timers")
         end
         if input:find("Список объектов в мире") then
            sampSendChat("/olist")
         end
         if input:find("Список перемещаемых объектов") then
            sampSendChat("/gate")
         end
         if input:find("Список переменных") then
            sampSendChat("/varlist")
         end
         if input:find("Список переменных игрока") then
            sampSendChat("/pvarlist")
         end
         if input:find("Список аудиостримов") then
            sampSendChat("/stream")
         end
      end
   end
   
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
   if isAbsolutePlay and ini.settings.extendedmenues then
      -- save random color from text editing dialog to clipboard
      -- moved to absolutefix
      -- if dialogId == 1496 then
         -- local randomcolor = string.sub(text, string.len(text)-6, #text-1)
		 -- printStringNow("color "..randomcolor.." copied to clipboard",1000)
	     -- setClipboardText(randomcolor)
      -- end
      if dialogId == 1400 and title:find("Управление мира") then
         isWorldHoster = true
      end
      
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
         local closestObjectId = getClosestObjectId()
         
         local newtext = 
         "{FFD700}615-18300       {FFFFFF}GTA-SA \n{FFD700}18632-19521{FFFFFF}   SA-MP\n"..
         (LastObject.modelid and "\n{FFFFFF}Последний {FFFF00}использованный объект: "..LastObject.modelid.." ("..tostring(sampObjectModelNames[LastObject.modelid])..") " or " ")..
         (LastRemovedObject.modelid and "\n{FFFFFF}Последний {FF0000}удаленный объект: "..LastRemovedObject.modelid.." ("..tostring(sampObjectModelNames[LastRemovedObject.modelid])..") " or " ")..
         (closestObjectId and "\n{FFFFFF}Ближайший {696969}объект: "..getObjectModel(closestObjectId).." ("..tostring(sampObjectModelNames[getObjectModel(closestObjectId)])..") \n" or " ")..
         "\n{FFFFFF}Введи номер объекта: \n"
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
   
   if isTraining and dialogId == 32700 and ini.settings.extendedmenues then
      -- TRAINING Skip cmdbinds dialog
      if style == 0 and button1 == "Принимаю" then
         sampSendDialogResponse(32700, 1, nil)
         sampCloseCurrentDialogWithButton(1)
      end
      -- Added new features to /omenu
      if title:find("Редактирование / Клонирование") then
         editDialogOpened = true
         
         local newtitle
         if LastObject.localid then
            newtitle = "Редактирование объекта id:"..LastObject.localid
         else
            newtitle = "Редактирование объекта"
         end
         
         local newitems = "Редактировать\n"..
         "Клонировать\n"..
         "Удалить\n"..
         "Повернуть на 90°\n"..
         --"Выровнять по координатам\n"..
         "Наложить текст\n"..
         "Наложить текстуру\n"..
         "Показать индексы\n"..
         "Скрыть индексы\n"..
         "Телепортироваться\n"..
         "Информация\n"
         return {dialogId, style, newtitle, button1, button2, newitems}
      end
      -- Automatic ID substitution for /otext
      if title:find("Master Text Textures") and text:find("Укажите ID")then
         if LastObject.localid and editDialogOpened then
            sampSendDialogResponse(32700, 1, nil, LastObject.localid)
            sampCloseCurrentDialogWithButton(0)
         end
      end
      -- Extend main /vw menu
      if text:find("Название мира") and style == 4 then
         if autodevmenutoggle then
            lua_thread.create(function()
               wait(500)
               sampSendDialogResponse(32700, 1, 11, "- Режим разработки")
               sampCloseCurrentDialogWithButton(0)
               autodevmenutoggle = false
            end)
         end
         local newitems = 
         " - Настройки для команд\n"..
         " - Интерьеры\n"
         return {dialogId, style, title, button1, button2, text..newitems}
      end
      -- Extend world manage menu
      if text:find("Обнулить все оружие") and style == 4 then
         local newitems = "\n"..
         "- Список командных блоков\n"..
         "- Список триггер блоков\n"..
         "- Список таймеров\n"..
         "- Список объектов в мире\n"..
         "- Список перемещаемых объектов\n"..
         "- Список переменных\n"..
         "- Список переменных игрока\n"..
         "- Список аудиостримов\n"
         return {dialogId, style, title, button1, button2, text..newitems}
      end
      -- Extend main /menu
      if title:match("^Меню$") then
         local newitems = "\n"..
         "Заспавнить себя\n"..
         "Слапнуть себя\n"..
         "Взять Jetpack\n"..
         "Список друзей\n"..
         "Ачивки\n"
         return {dialogId, style, title, button1, button2, text..newitems}
      end
      if title:find("Настройки игрока") then
         local newitems = "\n"..
         "15. Сменить скин\n"
         return {dialogId, style, title, button1, button2, text..newitems}
      end
      if text:find("Создать игровой мир") then
         if text:find("сек") then
            isWorldJoinUnavailable = true
         else
            isWorldJoinUnavailable = false
         end
      end
      if text:find("После подтверждения Вы отправитесь в") then
         if isWorldHoster then
            sampSendDialogResponse(32700, 1, nil, nil)
            sampCloseCurrentDialogWithButton(1)
         else
            restorePlayerSkin()
         end
      end
   end
   
   -- Skip olist when exit from /omenu
   if isTraining and dialogId == 65535 and ini.settings.extendedmenues then
      if lastDialogInput ~= "Слот 1" then -- /att fix
         sampSendClickTextdraw(2118)
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
   
   if checkbox.allchatoff.v then
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
   
   -- TODO optimize shitcode
   if isAbsolutePlay and text:find('ЛС') and text:find('от') then
      lastPmMessage = text
   end
   if isTraining and text:find('PM') and text:find('от') then
      -- blacklict check
      for k, name in pairs(blacklist) do
         if text:find(name) then
            return false
         end
      end
      lastPmMessage = text
   end
   
   if text:find('Добро пожаловать на Arizona Role Play!') then
      thisScript():unload()
   end
   
   if isTraining then
      if text:find("Невозможно создать новый мир, за вами уже есть закрепленный мир") then
         -- "Создать игровой мир"
         if not isWorldJoinUnavailable then
            isWorldHoster = true
            sampSendChat("/vw")
         end
         return false
      end
      if text:find("Меню управления миром") then
         isWorldHoster = true
         if ini.settings.hotkeys then
            sampAddChatMessage("[SERVER]: {FFFFFF}Меню управления миром - /vw или клавиша - M", 0x0FF6600)
         end
         return false
      end
   end
   
   if isAbsolutePlay then   
      if text:find("Последнего созданного объекта не существует") then
         if LastObject.modelid then
            sampAddChatMessage("Последний использованный объект: {696969}"..LastObject.modelid, -1)
	     end
      end
      
      if text:find("Управляющим мира смертельный урон не наносится") then
         sampAddChatMessage("N - Оружие - Отключить сужающуюся зону урона", -1)
      end
      
      if text:find("Установи 0.3DL чтобы включать полёт в этом месте") then
         sampAddChatMessage("Необходимо уходить в полет с другой точки, где мало объектов рядом (выйти из зоны стрима)", 0x00FF00)
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
      
      if text:find("использовал телепорт") and isWorldHoster then
         return false
      end
   end
   
   if isTraining then
      if text:find("Виртуальный мир успешно создан") 
      or text:find("Вы создали пробный VIP мир") then
         WorldJoinInit()
      end
      
      if text:find("Хост "..nickname) and text:find("вернулся в мир") then
         WorldJoinInit()
      end
      
      if text:find('Создан объект: (%d+)') then
         LastObject.localid = text:match('Создан объект: (%d+)')
      end
      
      if text:find('Выбран предмет: (%d+)') then
         LastObject.localid = text:match('Выбран предмет: (%d+)')
      end
      
      if text:find('Вы отправлены на спаун!') then
         sampSendChat("/spawnme")
         isWorldHoster = false
      end
      
      if text:find('Удален объект: (%d+)') then
         LastObject.localid = nil
      end
      
      if text:find('применена текстура: (%d+)') then
         LastObject.txdid = text:match('.+применена текстура: (%d+)')
      end

      if text:find('На объект (%d+)') then
         LastObject.localid = text:match('.+На объект (%d+)')
      end
   end
   
   if checkbox.chatmentions.v then
      -- ignore system messages by color
      if color ~= -793842689 -- lime color abs
      and color ~= -1029514497 -- puprple color
      and color ~= -10092289 then --orange color training
         -- mentions by nickname
         if text:find(nickname) then
            if text:find(":") then
               local pointpos = text:find(":")
               local cleartext = text:sub(pointpos, string.len(text))
               if cleartext:find(nickname) then
                  printStyledString('You were mentioned in the chat', 2000, 4)
                  addOneOffSound(0.0, 0.0, 0.0, 1138) -- CHECKPOINT_GREEN
                 -- return true
               end
             else
               printStyledString('You were mentioned in the chat', 2000, 4)
               addOneOffSound(0.0, 0.0, 0.0, 1138) -- CHECKPOINT_GREEN
              -- return true
            end
         end
         
         -- mentions by id
         if text:match("(%s"..id.."%s)") then
            printStyledString('You were mentioned in the chat', 2000, 4)
            addOneOffSound(0.0, 0.0, 0.0, 1138) -- CHECKPOINT_GREEN
            --return true
         end
      end
   end
   
   if ini.settings.chatfilter then
      for i = 1, #chatfilter do
         if text:find(chatfilter[i]) then 
            return false
         end
      end
   end
   
   if formatChat then
      local newtext = text
      
      if checkbox.anticaps.v then
         newtext = string.nlower(newtext)
      end
      
      if isTraining then
         if checkbox.anticapsads.v and not checkbox.anticaps.v then
            if newtext:find("ADS") then
               newtext = string.nlower(newtext)
            end
         end
      end
      
      if checkbox.chathideip.v then
         if newtext:match("(%d+.%d+.%d+.%d+)") then
            newtext = newtext:gsub("(%d+.%d+.%d+.%d+)", "***.***.***.***")
         end
      end
      
      return {color, newtext}
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
         checkbox.showobjectsmodel.v = true 
         return false
      end
      if command:find("hidetext3d") then
         sampAddChatMessage("Информация о объектах скрыта", 0x000FF00)
         checkbox.showobjectsmodel.v = false
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
         if LastObject.localid then
            if command:find("/sel") then
               sampSendChat("/sel "..LastObject.localid)
               --editMode = 3
               return false
            end
            
            if command:find("/ogh") then
               sampSendChat("/ogh "..LastObject.localid)
               return false
            end
            
            if command:find("/untexture") then
               sampSendChat("/untexture "..LastObject.localid)
               return false
            end
            
            if command:find("/stexture") then
               if LastObject.txdid ~= nil then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Последняя использованная текстура: " .. LastObject.txdid, 0x0FF6600)
               end
            end
         end
      end
   end
   
   if isTraining then
      if command:find("/dm") then
         minigame = 1
      elseif command:find("/gungame") or command:find("/gg") then
         minigame = 3
      elseif command:find("/copchase") or command:find("/ch") then
         minigame = 4
      elseif command:find("/wot") then
         minigame = 2
      elseif command:find("/derby") then
         minigame = 5
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
      if command:find("/vfibye2") or command:find("/машину2") then 
         isTexturesListOpened = false
         isSanpObjectsListOpened = false
      end
   end
   
   if command:find("/ближ") or command:find("/ocl") then
      local closestObjectId = getClosestObjectId()
      if closestObjectId then
         local model = getObjectModel(closestObjectId)
         local modelName = tostring(sampObjectModelNames[model])
         sampAddChatMessage("Ближайший объект: {696969}"..model.." ("..modelName..") ", -1)
         local result, distance, x, y, z = getNearestObjectByModel(model)
         if result then 
		    sampAddChatMessage(string.format('Объект находится на расстоянии {696969}%.2f{FFFFFF} метров от вас', distance), -1)
		 end	 
      else
         sampAddChatMessage("Не найден ближайший объект", -1)
      end
      return false
   end
   
   if command:find("/коорд") or command:find("/coord") then
      local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
      local posA = getCharHeading(PLAYER_PED)
      sampAddChatMessage(string.format("Ваши координаты: {696969}%.2f %.2f %.2f {FFFFFF}Угол поворота: {696969}%.2f", posX, posY, posZ, posA), -1)
      if isAbsolutePlay and isWorldHoster then
         sampAddChatMessage(string.format("Используйте: /тпк {696969}%.2f %.2f %.2f", posX, posY, posZ), -1)
      end
      if isTraining and isWorldHoster then
         sampAddChatMessage(string.format("Используйте: /xyz {696969}%.2f %.2f %.2f", posX, posY, posZ), -1)
      end
      return false
   end
   
   if command:find("/ответ") then
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
   
   if command:find("/отсчет") then
      if isAbsolutePlay then
         return true
      end
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local time = tonumber(arg) 
         if time >= 1 and time <= 10 then 
            lua_thread.create(function()
               while time ~= 0 do
                  time = time - 1
                  if time > 0 then
                     if isTraining then
                        sampSendChat("/s "..time)
                     else
                        sampSendChat(""..time)
                     end
                  else
                     if isTraining then
                        sampSendChat("/s GO!")
                     else
                        sampSendChat("GO!")
                     end
                  end
                  wait(1000)
               end
            end)
         else
            sampAddChatMessage("Используйте /отсчет <1-10>", -1)
            return false
         end
      end
      return false
   end
   
   if command:find("/exit") or command:find("/выход") then
      isWorldHoster = false
      editMode = 0
      minigame = nil
	  lastWorldNumber = 0
      worldspawnpos.x = 0
      worldspawnpos.y = 0
      worldspawnpos.z = 0
   end
   
   if command:find("/time") and isTraining then
      if not command:find('(.+) (.+)') then
         sampAddChatMessage("Сегодня "..os.date("%x %X"), -1)
      end
   end
            
   if command:find("/savepos") then
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
   
   if command:find("/gopos") then
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
   
   if command:find("/jump") then
      if sampIsLocalPlayerSpawned() then
         JumpForward()
      end
      return false
   end
   
   if command:find("/slapme") and not isTraining then
      if sampIsLocalPlayerSpawned() then
         local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
         setCharCoordinates(PLAYER_PED, posX, posY, posZ+1.0)
      end
      return false
   end
   
   if command:find("/spawnme") and not isTraining  then
      local posX, posY, posZ = getCharCoordinates(PLAYER_PED)
	  setCharCoordinates(PLAYER_PED, posX, posY, posZ+0.2)
	  freezeCharPosition(PLAYER_PED, false)
	  setPlayerControl(PLAYER_HANDLE, true)
	  restoreCameraJumpcut()
	  clearCharTasksImmediately(PLAYER_PED)
      return false
   end
   
   if command:find("/spec") then
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
   if command:find("/csel") or command:find("/editobject") and not isTraining then
      sampAddChatMessage("Включен режим редактирования объекта", 0x000FF00)
      enterEditObject()
      return false
   end
   
   if isTraining and command:find("/mn") then
      sampSendChat("/menu")
      return false
   end
   
   if isTraining and command:find("/omenu") then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            LastObject.localid = id
            return true
         end         
      else
         if LastObject.localid then
            if command:find("/omenu") then
               sampSendChat("/omenu "..LastObject.localid)
               return false
            end
         end
      end
   end
   
   if isTraining and command:find("/odell") then
      editMode = 3
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local id = tonumber(arg) 
         if id == LastObject.localid then
            LastRemovedObject.modelid = LastObject.modelid
            LastRemovedObject.position.x = LastObject.position.x
            LastRemovedObject.position.y = LastObject.position.y
            LastRemovedObject.position.z = LastObject.position.z
            LastRemovedObject.rotation.x = LastObject.position.x
            LastRemovedObject.rotation.y = LastObject.position.y
            LastRemovedObject.rotation.z = LastObject.position.z
         end
      end
      return true
   end
   
   if isTraining and command:find("/oadd") then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local id = tonumber(arg)
         if isValidObjectModel(id) then 
            LastRemovedObject.modelid = id
            checkBuggedObject(id)
            -- if not isValidObjectModel(id) then
               -- sampAddChatMessage("[ERROR]: {FFFFFF}Данный объект запрещен или не существует!", 0x0CC0000)
               -- return false
            -- end
         end
      else
         if LastObject.modelid then
            sampAddChatMessage("Последний использованный объект: {696969}"..LastObject.modelid, -1)
         end
	  end
   end
   
   if isTraining and command:find("/mtexture") then
      sampAddChatMessage("[SERVER]: {FFFFFF}/texture <object> <slot> <page*>", 0x0FF6600)
      return false
   end
   
   if isTraining and command:find("/texture") then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            editMode = 4
         end
         showRetextureKeysHelp()
      else
         if LastObject.txdid ~= nil then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Последняя использованная текстура: " .. LastObject.txdid, 0x0FF6600)
         end
      end
   end
      
   if isTraining and command:find("/stexture") then
      if command:find('(.+) (.+) (.+)') then
         local cmd, slot, textureid = command:match('(.+) (.+) (.+)')
         if tonumber(textureid) > 0 and tonumber(textureid) < 19000 then
            LastObject.txdid = tonumber(textureid)
            if LastObject.localid then
               local txdtable = sampTextureList[LastObject.txdid]
               if worldTexturesList[LastObject.localid] then 
                  worldTexturesList[LastObject.localid] = tostring(txdtable[3])
               else
                  table.insert(worldTexturesList, LastObject.localid, tostring(txdtable[3]))
               end
            end
         end
      end
      if not command:find('(.+) (.+)') then
         if LastObject.txdid ~= nil then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Последняя использованная текстура: " .. LastObject.txdid, 0x0FF6600)
         end
      end
   end
   
   if command:find("/tlist") or command:find("/textures") then
      local counter = 0
      for objectlocalid, texturename in pairs(worldTexturesList) do
         if objectlocalid ~= 0 then
            counter = counter + 1
            sampAddChatMessage("id: "..objectlocalid.." - {696969} "..texturename, -1)
         end
      end
      if counter == 0 then
         sampAddChatMessage("Список использованных за сеанс текстур - пуст", -1)
      end
      return false
   end
   
   if command:find("/undo") then
      if LastRemovedObject.modelid then
         if isTraining then
            sampSendChat("/oadd ".. LastRemovedObject.modelid)
         end
         sampAddChatMessage("Восстановлен последний удаленный объект: "..LastRemovedObject.modelid, -1)
      else
         sampAddChatMessage("Не найден последний удаленный объект", -1)
      end
      return false
   end
   
   if isTraining and command:find("/oedit") then
      editMode = 1
      return true
   end
   
   if isTraining and command:find("/spint") then
      if isWorldHoster then
         sampSendChat("/int")
         return false
      end
   end
   
   if not isAbsolutePlay and command:find("/killme") then
      sampAddChatMessage("[SCRIPT]{FFFFFF} Если вы остались живы, отключите режим бога {696969}/gm ", 0x0FF6600)
      setCharHealth(PLAYER_PED, 0.0)
      return false
   end
   
   if command:find("/sindex") and not isTraining then
      if LastObject.handle and doesObjectExist(LastObject.handle) then
         setMaterialObject(LastObject.id, 1, 0, 18646, "MatColours", "red", 0xFFFFFFFF) 
         setMaterialObject(LastObject.id, 1, 1, 18646, "MatColours", "green", 0xFFFFFFFF)         
         setMaterialObject(LastObject.id, 1, 2, 18646, "MatColours", "blue", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 3, 18646, "MatColours", "yellow", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 4, 18646, "MatColours", "lightblue", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 5, 18646, "MatColours", "orange", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 6, 18646, "MatColours", "redlaser", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 7, 18646, "MatColours", "grey", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 8, 18646, "MatColours", "white", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 9, 7910, "vgnusedcar", "lightpurple2_32", 0xFFFFFFFF)
         setMaterialObject(LastObject.id, 1, 10, 19271, "MapMarkers", "green-2", 0xFFFFFFFF) -- dark green
         --setMaterialObjectText(LastObject.id, 2, 0, 100, "Arial", 255, 0, 0xFFFFFF00, 0xFF00FF00, 1, "0")
         sampAddChatMessage("Режим визуального просмотра индексов включен. Каждый индекс соответсвует цвету с таблицы.", 0x000FF00)
         sampAddChatMessage("{FF0000}0 {008000}1 {0000FF}2 {FFFF00}3 {00FFFF}4 {FF4FF0}5 {dc143c}6 {808080}7 {FFFFFF}8 {800080}9 {006400}10", -1)
      else
         sampAddChatMessage("Последний созданный объект не найден", -1)
      end
      return false
   end
   
   if command:find("/rindex") then
      if isTraining then
         sampSendChat("/untexture")
         return false
      end
      if LastObject.handle and doesObjectExist(LastObject.handle) then
         for index = 0, 15 do 
            setMaterialObject(LastObject.id, 1, index, LastObject.modelid, "none", "none", 0xFFFFFFFF)
         end
         sampAddChatMessage("Режим визуального просмотра индексов отключен", 0x000FF00)
      else
         sampAddChatMessage("Последний созданный объект не найден", -1)
      end
      return false
   end
   
   if command:find("/odist") then
      if checkbox.drawlinetomodelid.v then
         checkbox.drawlinetomodelid.v = false
      else
         if LastObject.modelid then 
	 	    input.rendselectedmodelid.v = LastObject.modelid
            checkbox.drawlinetomodelid.v = true
         else
            sampAddChatMessage("Последний созданный объект не найден", -1)
	     end
      end
      return false
   end
   
   if command:find("/ocol") then
      disableObjectCollision = not disableObjectCollision
      checkbox.objectcollision.v = disableObjectCollision
      if not disableObjectCollision then 
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
      sampAddChatMessage(disableObjectCollision and "[SCRIPT]: {FFFFFF}Коллизия обектов: Отключена" or "[SCRIPT]: {FFFFFF}Коллизия обектов: Включена", 0x0FF6600)
      return false
   end 
   
   if command:find("/oalpha") then
      if LastObject.handle and doesObjectExist(LastObject.handle) then
         for index = 0, 15 do 
            setMaterialObject(LastObject.id, 1, index, LastObject.modelid, "none", "none", 0x99FFFFFF)
         end
         if LastObject.localid then
            sampAddChatMessage("Установлена полупрозрачность объекту {696969}"..LastObject.localid.."{FFFFFF} (model: {696969}"..LastObject.modelid.."{FFFFFF}) отменить можно через {696969}/rindex", -1)
         else
            sampAddChatMessage("Установлена полупрозрачность объекту (model: {696969}"..LastObject.modelid.."{FFFFFF}) отменить можно через {696969}/rindex", -1)
         end
      else
         sampAddChatMessage("Последний созданный объект не найден", -1)
      end
      return false
   end
   
   if command:find("/ocolor") and not isTraining then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local ocolor = tostring(arg)
         if string.len(ocolor) < 10 or not ocolor:find("0x") then
            sampAddChatMessage("Формат цвета 0xAARGBRGB", -1)
            return false
         end
      
         if LastObject.handle and doesObjectExist(LastObject.handle) then
            for index = 0, 15 do 
               setMaterialObject(LastObject.id, 1, index, LastObject.modelid, "none", "none", arg)
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
   
   if command:find("/ogoto") then
      if LastObject.handle and doesObjectExist(LastObject.handle) then
      	 if isAbsolutePlay then
		    sampSendChat(string.format("/тпк %f %f %f",
		    LastObject.position.x, LastObject.position.y, LastObject.position.z), 0x0FFFFFF)
         elseif isTraining then
		    sampSendChat(string.format("/xyz %f %f %f",
		    LastObject.position.x, LastObject.position.y, LastObject.position.z), 0x0FFFFFF)   
		 else
		    setCharCoordinates(PLAYER_PED, LastObject.position.x, LastObject.position.x, LastObject.position.z+0.2)
		 end
		 sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..LastObject.modelid, 0x000FF00)
      else
         if isTraining then
            sampAddChatMessage("Используйте /tpo <id>", -1)
         else
            sampAddChatMessage("Последний созданный объект не найден", -1)
         end
      end
      return false
   end
   
   if command:find("/tsearch") and not isTraining then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local searchtxd = tostring(arg)
         if string.len(searchtxd) < 2 then
            sampAddChatMessage("Минимальное кол-во символов для поиска текстуры = 2", -1)
            return false
         end
         
         local findedtxd = 0
         if searchtxd and searchtxd ~= nil then 
            for k, txdname in pairs(absTxdNames) do
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
   
   if command:find("/tsearch") and isTraining then
      if LastObject.txdid ~= nil then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Последняя использованная текстура: " .. LastObject.txdid, 0x0FF6600)
      end
      if not command:find('(.+) (.+) (.+)') then
         sampAddChatMessage("[SERVER]: {FFFFFF}/tsearch <objectid> <slot> <name>", 0x0FF6600)
         return false
      else
         showRetextureKeysHelp()
      end
   end
   
   if command:find("/cbsearch") and isTraining then
      if command:find('(.+) (.+)') then
         local cmd, arg = command:match('(.+) (.+)')
         local searchtext = tostring(arg)
         if string.len(searchtext) < 2 then
            sampAddChatMessage("Минимальное кол-во символов для поиска = 2", -1)
            return false
         end
         local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//cblist.txt"
         local results = 0
         local resultline = 0
         if string.len(searchtext) > 0 then
            for line in io.lines(filepath) do
               resultline = resultline + 1
               if line:find(searchtext, 1, true) then
                  results = results + 1
                  sampAddChatMessage(""..u8:decode(line), -1)
               end
            end
         end
         if not results then
            sampAddChatMessage("Результат поиска: Не найдено", -1)
         end
         return false
      else 
         sampAddChatMessage("Введите информацию для поиска", -1)
         sampAddChatMessage("Например: /cbsearch tick", -1)
         return false
      end
   end
   
   if command:find("/osearch") and not isTraining then
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
   
   if isTraining and command:find("/лс") then
      if command:find('(.+) (.+) (.+)') then
         local cmd, id, message = command:match('(.+) (.+) (.+)')
         if message then
            sampSendChat("/pm "..id.." "..message)
         end
      end
   end
   
   if command:find("/vbh") or command:find("/мир") then
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
   
   if command:find("/last") then
      if isAbsolutePlay and lastWorldNumber then
         sampAddChatMessage("Последний мир в котором вы были: {696969}"..lastWorldNumber, -1)
      end
      if isTraining and LastObject.localid then
         sampAddChatMessage("Последний локальный ид объекта: {696969}"..LastObject.localid, -1)
      end
      if LastObject.modelid then
         sampAddChatMessage("Последний использованный объект: {696969}"..LastObject.modelid.." ("..tostring(sampObjectModelNames[LastObject.modelid])..")", -1)
      end
      if LastObject.txdid then
         sampAddChatMessage("Последняя использованная текстура: {696969}"..LastObject.txdid.." ("..LastObject.txdname..")", -1)
      end
      if LastRemovedObject.modelid then
         sampAddChatMessage("Последний удаленный объект: {696969}"..LastRemovedObject.modelid, -1)
      end
      
      local closestObjectId = getClosestObjectId()
      if closestObjectId then
         sampAddChatMessage("Ближайший объект: {696969}"..getObjectModel(closestObjectId).." ("..tostring(sampObjectModelNames[getObjectModel(closestObjectId)])..") ", -1)
         local result, distance, x, y, z = getNearestObjectByModel(getObjectModel(closestObjectId))
         if result then 
	 	    sampAddChatMessage(string.format('Объект находится на расстоянии {696969}%.2f{FFFFFF} метров от вас', distance), -1)
	 	 end	 
      end
      
      if ini.settings.debug and lastClickedTextdrawId then
         sampAddChatMessage("Последний нажатый текстдрав: {696969}"..lastClickedTextdrawId, -1)
      end
   
      return false
   end
   
   if command:find("/restream") then
      Restream()
      return false
   end 
   
   if isTraining and command:find("/afkkick") then
      local counter = 0
	  if next(playersTable) == nil then 
	     sampAddChatMessage("Сперва обнови список игроков!", -1) 
         return false
      end
      
      if not isWorldHoster then 
	     sampAddChatMessage("Вы не находитесь в вирутальном в мире!", -1) 
         return false
      end
      
	  for k, v in pairs(playersTable) do
         local nickname = sampGetPlayerNickname(v)
	     if sampIsPlayerPaused(v) then
	        counter = counter + 1
            sampSendChat("/kick "..v)
	     end
	  end
	  if counter == 0 then
	     sampAddChatMessage("АФКашники не найдены", -1)
	  end
	  
      return false
   end 
   
   if command:find("/retcam") or command:find("/restorecam") then
      if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
      if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
      setCameraBehindPlayer()
	  restoreCamera()  
      return false
   end 
   
   if ini.settings.debug and command:find("/test") then   
      --deleteChar(PLAYER_HANDLE)
      sampAddChatMessage("Test", -1)
      return false
   end
   
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
   if id == LastObject.id then 
      LastObject.txdlibname = data.libraryName
      LastObject.txdname = data.textureName
      LastObject.txdmodel = data.modelId
   end
   if checkbox.logtxd.v then
      print(id, data.materialId, data.modelId, data.libraryName, data.textureName, data.color)
   end
   
   --local showtxd = true
   --if showtxd then
      --local x1, y1 = convert3DCoordsToScreen(data.position.x, data.position.y, data.position.z)
      --renderFontDrawText(objectsrenderfont, ""..data.libraryName, data.textureName, x1, y1, -1)
      --sampCreate3dText(""..data.materials, 0x000FF00, data.position.x, data.position.y, data.position.z, 50.0, false)
      
      -- local handle = sampGetObjectHandleBySampId(id)
      -- local result, x, y, z = getObjectCoordinates(handle)
      -- local position = {x = x, y = y, z = z}
      -- print(id, handle, position.x, position.y, position.z)

      --print(materials.position)
      --materials.id = id
      --materials.handle = handle
      --print(data.libraryName)
      --print(data.textureName)
      
   --end
end

function sampev.onSendEditObject(playerObject, objectId, response, position, rotation)
   local object = sampGetObjectHandleBySampId(objectId)
   local modelId = getObjectModel(object)
   LastObject.handle = object
   LastObject.id = objectId
   LastObject.modelid = modelId
   LastObject.position.x = position.x
   LastObject.position.y = position.y
   LastObject.position.z = position.z
   LastObject.rotation.x = rotation.x
   LastObject.rotation.y = rotation.y
   LastObject.rotation.z = rotation.z
   
   
   -- Auto open /omenu on save object 
   -- if isTraining and response == 1 then
      -- if LastObject.localid then
         -- sampSendChat("/omenu "..LastObject.localid)
      -- end
   -- end
   
   -- Returns the object to its initial position when exiting editing
   -- TODO restore object angle too
   editResponse = response
   if ini.settings.restoreobjectpos then
      if isTraining and response == 0 then
         if LastObject.startpos.x ~= 0 and LastObject.startpos.y ~= 0 then
            return {playerObject, objectId, response,  LastObject.startpos, rotation}
         end
      end
   end
   
   if ini.settings.showobjectrot then
      if LastObject.startrot.x ~= rotation.x then
         printStringNow(string.format("~w~rx:~b~~h~%0.2f", rotation.x), 500)
         LastObject.startrot.x = rotation.x
      end
      if LastObject.startrot.y ~= rotation.y then
         printStringNow(string.format("~w~ry:~r~~h~%0.2f", rotation.y), 500)
         LastObject.startrot.y = rotation.y
      end
      if LastObject.startrot.z ~= rotation.z then
         printStringNow(string.format("~w~rz:~g~~h~%0.2f", rotation.z), 500)
         LastObject.startrot.z = rotation.z
         print(LastObject.startrot.z, LastObject.rotation.z, rotation.z)
      end
   end
   
   if ini.settings.showobjectcoord then
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
   LastObject.handle = object
   LastObject.id = objectId
   LastObject.modelid = modelId
   --LastObject.angle = getObjectHeading(object)
   -- Сontains the initial position of the object before editing
   LastObject.startpos.x = position.x
   LastObject.startpos.y = position.y
   LastObject.startpos.z = position.z
   -- Duplicate last object sync data
   LastObject.position.x = position.x
   LastObject.position.y = position.y
   LastObject.position.z = position.z

   LastObject.startrot.x = LastObject.rotation.x
   LastObject.startrot.y = LastObject.rotation.y
   LastObject.startrot.z = LastObject.rotation.z
   
   if not isTraining then
      checkBuggedObject(model)
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
      LastObject.localid = text:match('id:(%d+)')
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
   if checkbox.tabclickcopy.v then
      local nickname = sampGetPlayerNickname(playerId)
      local buffer = string.format("%s[%d]", nickname, playerId)
      setClipboardText(buffer)
      sampAddChatMessage("Ник {696969}"..nickname.." {FFFFFF}кликнутого в TAB игрока {696969}".. playerId.."{FFFFFF} скопирован в буфер", -1)
   end
end

function sampev.onShowTextDraw(id, data)
   if isAbsolutePlay and isTexturesListOpened then
      if id >= 2053 and id <= 2100 then
         local index = tonumber(data.text)
         if index ~= nil then
            local txdlabel = data.text.."~n~~n~"..tostring(absTxdNames[index+1])
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
   
   -- if isTraining then
      -- id 2069-2058 is logs
   -- end
   
   
   if checkbox.logtextdraws.v then
      local posX, posY = sampTextdrawGetPos(id)
      print(("Show Textdraw ID: %s, x : %.2f, y: %.2f text: %s"):format(id, posX, posY, data.text))
   end
   
   if checkbox.hidealltextdraws.v then
      return false
   end
end

function sampev.onSendClickTextDraw(textdrawId)
   lastClickedTextdrawId = textdrawId
   if checkbox.logtextdraws.v then
      local posX, posY = sampTextdrawGetPos(textdrawId)
      print(("Click Textdraw ID: %s, Model: %s, x : %.2f, y: %.2f"):format(textdrawId, sampTextdrawGetModelRotationZoomVehColor(textdrawId), posX, posY))
   end
   -- if textdrawId >= 2053 and textdrawId <= 2099 then
      -- local model, rotX, rotY, rotZ, zoom, clr1, clr2 = sampTextdrawGetModelRotationZoomVehColor(textdrawId)
      -- sampTextdrawSetModelRotationZoomVehColor(textdrawId, model, rotX, rotY, rotZ+90.0, zoom, clr1, clr2)
   -- end   
end

function sampev.onSendPickedUpPickup(id)
   if checkbox.pickeduppickups.v then
	  print('Pickup: ' .. id)
   end
end

function sampev.onRemoveBuilding(modelId, position, radius)
   removedBuildings = removedBuildings + 1;
end

function sampev.onSendSpawn()
   if firstSpawn and ini.settings.allchatoff then
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Глобальный чат отключен!", 0x0FF6600)
   end
   if firstSpawn and isTraining then 
      firstSpawn = false
      if sampIsLocalPlayerSpawned() then 
         if ini.settings.saveskin and isValidSkin(ini.settings.skinid) then
            sampSendChat("/skin "..ini.settings.skinid)
         end
      end
   end
   local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
   if isTraining and pid == 0 then
      sampAddChatMessage("[SCRIPT]: {FFFFFF}У вас багнутый ID перезайдите на сервер!", 0x0FF6600)
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Если не перезайти вас будут кикать с большинста миров!", 0x0FF6600)
      sampSetGamestate(4)
   end
end
-- END hooks

-- Macros
local lower, sub, char, upper = string.lower, string.sub, string.char, string.upper
local concat = table.concat
-- initialization table
local lu_rus, ul_rus = {}, {}
for i = 192, 223 do
    local A, a = char(i), char(i + 32)
    ul_rus[A] = a
    lu_rus[a] = A
end
local E, e = char(168), char(184)
ul_rus[E] = e
lu_rus[e] = E

function string.nlower(s)
   s = lower(s)
   local len, res = #s, {}
   for i = 1, len do
      local ch = sub(s, i, i)
      res[i] = ul_rus[ch] or ch
   end
   return concat(res)
end

function string.nupper(s)
   s = upper(s)
   local len, res = #s, {}
   for i = 1, len do
      local ch = sub(s, i, i)
      res[i] = lu_rus[ch] or ch
   end
   return concat(res)
end

function isRpNickname(name)
   return name:match('^%u%l+_%u%a+$')
end

-- function ltrim(s)
   -- return s:match'^%s*(.*)'
-- end

-- function trim(s)
   -- return (s:gsub("^%s*(.-)%s*$", "%1"))
-- end

function checkBuggedObject(model)
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
   if isTraining then
      if model == 11694 or model == 11695 or model == 11696 then
         sampAddChatMessage("Этот объект "..model.." при размещении рядом с большим кол-вом объетов может вызывать аномалии", 0x0FF0000)
      end
   end
end

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

function getClosestObjectId()
   local closestId = nil
   mydist = 20
   local px, py, pz = getCharCoordinates(PLAYER_PED)
   for _, v in ipairs(getAllObjects()) do
      if isObjectOnScreen(v) then
         local _, x, y, z = getObjectCoordinates(v)
         local dist = getDistanceBetweenCoords3d(x, y, z, px, py, pz)
         if dist <= mydist and dist >= 1.0 then -- 1.0 to ignore attached objects
            mydist = dist
            closestId = v
         end
      end
   end
   return closestId
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
   for _ in pairs(getAllObjects()) do count = count + 1 end
   return count
end

function getNearestObjectByModel(modelid)
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

function getCorrectAngle(angle)
   return 360/8 * math.floor(angle/45)
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

function isValidSkin(skinid)
   if type(skinid) ~= "number" then 
      return false
   end
   if skinid >= 0 and skinid <= 311 and skinid ~= 74 then
      return true
   end
   return false
end

function restorePlayerSkin()
   lua_thread.create(function()
      wait(4500)
      if sampIsLocalPlayerSpawned() then
         if ini.settings.saveskin and isValidSkin(ini.settings.skinid) then
            if getCharModel(PLAYER_PED) ~= ini.settings.skinid then 
               sampSendChat("/skin "..ini.settings.skinid)
            end
         end
      end
   end)
end

function SaveReminder()
   lua_thread.create(function()
      while checkbox.worldsavereminder.v do
         local delay = tonumber(ini.settings.reminderdelay)
         wait(1000*60*delay)
         if isWorldHoster and not isAbsolutePlay then
            sampAddChatMessage("{FF6600}[SCRIPT]{FFFFFF} Вы давно не сохраняли мир. Сохраните его во избежание потери прогресса.", 0x0FF6600)
         end
      end   
   end)
end

function WorldJoinInit()
   isWorldHoster = true
   worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(PLAYER_PED)
   lua_thread.create(function()
      setPlayerControl(PLAYER_HANDLE, false)
      wait(100)
      sampSendChat("/time "..ini.settings.time)
      wait(500)
      sampSendChat("/weather "..ini.settings.weather)
      wait(500)
      if ini.settings.autodevmode then
         autodevmenutoggle = true
         sampSendChat("/vw")
         wait(500)
      end
      if ini.settings.setgm then 
         sampSendChat("/gm")
         wait(500)
      end
      
      if sampIsLocalPlayerSpawned() then
         if ini.settings.saveskin and isValidSkin(ini.settings.skinid) then
            if getCharModel(PLAYER_PED) ~= ini.settings.skinid then 
               sampSendChat("/skin "..ini.settings.skinid)
            end
         end
      end
      wait(500)
      
      freezeCharPosition(PLAYER_PED, false)
	  setPlayerControl(PLAYER_HANDLE, true)
      
   end)
end

function AutoAd()
   lua_thread.create(function()
   while autoAnnounce do
      if input.addtime.v >= 2 then
         wait(input.addtime.v)
      else       
         wait(1000*60*3)-- 3 min
      end
      local prefix = ""
      if isAbsolutePlay then
         prefix = "* "
      elseif isTraining then
         prefix = "/ads "
      else
         prefix = " "
      end 
      
      if checkbox.mpprize.v then
         sampSendChat(prefix..u8:decode(textbuffer.mpadd.v)..", приз "..u8:decode(textbuffer.mpprize.v), -1)
      else
         sampSendChat(prefix..u8:decode(textbuffer.mpadd.v), -1)
      end
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
            
            if ini.warnings.undermap then
               if pz < 0.5 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] возможно находится под картой",
                  nickname, id), -1)
               elseif pz > 1000.0 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] длит в небе (высота: %d)",
                  nickname, id, pz), -1)
               end
            end
            
            if ini.warnings.heavyweapons then
               if weaponid == 38 or weaponid == 35 or weaponid == 36 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] держит в руках тяжелое оружие! (%s [%d])",
                  nickname, id, weaponNames[weaponid], weaponid), -1)
               end
            end
            
            if ini.warnings.illegalweapons then
               --print(weaponid)
               for key, value in pairs(legalweapons) do
                  if value ~= weaponid and weaponid > 1 then
                     sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] держит в руках нелегальное оружие! (%s [%d])",
                     nickname, id, weaponNames[weaponid], weaponid), -1)
                     break
                  end
               end
            end
            
            if ini.warnings.hprefil then
               if checkbox.healthcheck.v then
                  print(health, tonumber(textbuffer.mphp.v))
                  if health > tonumber(textbuffer.mphp.v) then
                     sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] hp: %d превышает разрешенное значение! (max: %d)",
                     nickname, id, health, tonumber(textbuffer.mphp.v)), -1)
                  end
               end
            end
            
            if ini.warnings.armourrefill then
               if checkbox.healthcheck.v then
                  if armour > tonumber(textbuffer.mparmour.v) then
                     sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] armour: %d превышает разрешенное значение! (max: %d)",
                     nickname, id, armour, tonumber(textbuffer.mparmour.v)), -1)
                  end
               end
            end
            
            if ini.warnings.laggers then
               if ping > 50 then
                  sampAddChatMessage(string.format("{FF0000}Игрок %s[%d] лагер! (ping %d)",
                  nickname, id, ping), -1)
               end
            end
            
            if ini.warnings.afk then
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
   sampAddChatMessage('Начинается процесс рестрима. Ожидайте 5 секунд', -1)
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

function copyNearestPlayersToClipboard()
   local tmpPlayers = {}
   local resulstring
   local totalplayers = 0
   for k, v in ipairs(getAllChars()) do
      local res, id = sampGetPlayerIdByCharHandle(v)
      local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
      if res and id ~= pid then
         totalplayers = totalplayers + 1
         local nickname = sampGetPlayerNickname(id)
         table.insert(tmpPlayers, string.format("%s[%d] ", nickname, id))
      end
   end
   if totalplayers then
      resulstring = table.concat(tmpPlayers)
      setClipboardText(resulstring)
      sampAddChatMessage("Ид и ники "..totalplayers.." игроков рядом скопированы в буфер обмена", -1)
      --return resulstring
   else 
      sampAddChatMessage("Не найдено игроков рядом", -1)
   end
end

function checkScriptUpdates()
   if doesFileExist(getGameDirectory() .. "\\moonloader\\lib\\requests.lua") then
      local response = require('requests').get("https://raw.githubusercontent.com/ins1x/MappingToolkit/main/version.dat")
      if response then
         local text = response.text
         local version = text:gsub("[.]", "")
         local installedversion = tostring(thisScript().version)
         installedversion = installedversion:gsub("[.]", "")
         if tonumber(version) > tonumber(installedversion) then
            sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Доступно обновление до версии {696969}"..text, -1)
            return true
         end
      else
         print("Updates server not responded")
         return false
      end
   else
      print("Updates check: module <requests> not found.")
      print("Install module from: https://luarocks.org/modules/jakeg/lua-requests")
      return false
   end
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

function showRetextureKeysHelp()
   sampAddChatMessage("[SCRIPT]: {FFFFFF}Управление: {FF6600}Y{FFFFFF} - Текстура наверх {FF6600}N{FFFFFF} - текстура вниз", 0x0FF6600)
   if ini.settings.remapnum then
      sampAddChatMessage("[SCRIPT]: {FF6600}Num4{FFFFFF} Предыдущая страница, {FF6600}Num6{FFFFFF} Следующая страница", 0x0FF6600)
   else
      sampAddChatMessage("[SCRIPT]: {FF6600}PgUp{FFFFFF} Предыдущая страница, {FF6600}PgDown{FFFFFF} Следующая страница", 0x0FF6600)
   end
   sampAddChatMessage("[SCRIPT]: {FF6600}Клавиша бега{FFFFFF} - принять.", 0x0FF6600)
end               

function cleanBindsForm()
   for k, v in pairs(binds) do
      binds[k] = imgui.ImBuffer(256)
   end
end

function reloadBindsFromConfig()
   binds.cmdbind1.v = u8(ini.binds.cmdbind1)
   binds.cmdbind2.v = u8(ini.binds.cmdbind2)
   binds.cmdbind3.v = u8(ini.binds.cmdbind3)
   binds.cmdbind4.v = u8(ini.binds.cmdbind4)
   binds.cmdbind5.v = u8(ini.binds.cmdbind5)
   binds.cmdbind6.v = u8(ini.binds.cmdbind6)
   binds.cmdbind7.v = u8(ini.binds.cmdbind7)
   binds.cmdbind8.v = u8(ini.binds.cmdbind8)
   binds.cmdbind9.v = u8(ini.binds.cmdbind9)
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
   local convtbl = {[230]=155,[231]=159,[247]=164,[234]=107,[250]=144,
      [251]=168,[254]=171,[253]=170,[255]=172,[224]=97,[240]=112,[241]=99,
      [226]=162,[228]=154,[225]=151,[227]=153,[248]=165,[243]=121,[184]=101,
      [235]=158,[238]=111,[245]=120,[233]=157,[242]=166,[239]=163,[244]=63,
      [237]=174,[229]=101,[246]=36,[236]=175,[232]=156,[249]=161,[252]=169,
      [215]=141,[202]=75,[204]=77,[220]=146,[221]=147,[222]=148,[192]=65,
      [193]=128,[209]=67,[194]=139,[195]=130,[197]=69,[206]=79,[213]=88,
      [168]=69,[223]=149,[207]=140,[203]=135,[201]=133,[199]=136,[196]=131,
      [208]=80,[200]=133,[198]=132,[210]=143,[211]=89,[216]=142,[212]=129,
      [214]=137,[205]=72,[217]=138,[218]=167,[219]=145}
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

function resetIO()
   -- Bug fix with focus in inputText (imgui)
   for i = 1, 512 do
      imgui:GetIO().KeysDown[i] = false
   end
   for i = 1, 5 do
      imgui:GetIO().MouseDown[i] = false
   end
   imgui:GetIO().KeyCtrl = false
   imgui:GetIO().KeyShift = false
   imgui:GetIO().KeyAlt = false
   imgui:GetIO().KeySuper = false     
end

function isValidObjectModel(modelid)
   -- Checks valid GTA:SA and SA:MP models.
   if modelid >= 321 and modelid <= 328 or modelid >= 330 and modelid <= 331 then return true
   elseif modelid >= 333 and modelid <= 339 or modelid >= 341 and modelid <= 373 then return true
   elseif modelid >= 615 and modelid <= 661 or modelid == 664 then return true 
   elseif modelid >= 669 and modelid <= 698 or modelid >= 700 and modelid <= 792 then return true
   elseif modelid >= 800 and modelid <= 906 or modelid >= 910 and modelid <= 964 then return true
   elseif modelid >= 966 and modelid <= 998 or modelid >= 1000 and modelid <= 1193 then return true
   elseif modelid >= 1207 and modelid <= 1325 or modelid >= 1327 and modelid <= 1572 then return true
   elseif modelid >= 1574 and modelid <= 1698 or modelid >= 1700 and modelid <= 2882 then return true
   elseif modelid >= 2885 and modelid <= 3135 or modelid >= 3167 and modelid <= 3175 then return true
   elseif modelid == 3178 or modelid == 3187 or modelid == 3193 or modelid == 3214 then return true
   elseif modelid == 3221 or modelid >= 3241 and modelid <= 3244 then return true
   elseif modelid == 3246 or modelid >= 3249 and modelid <= 3250 then return true
   elseif modelid >= 3252 and modelid <= 3253 or modelid >= 3255 and modelid <= 3265 then return true
   elseif modelid >= 3267 and modelid <= 3347 or modelid >= 3350 and modelid <= 3415 then return true
   elseif modelid >= 3417 and modelid <= 3428 or modelid >= 3430 and modelid <= 3609 then return true
   elseif modelid >= 3612 and modelid <= 3783 or modelid >= 3785 and modelid <= 3869 then return true
   elseif modelid >= 3872 and modelid <= 3882 or modelid >= 3884 and modelid <= 3888 then return true
   elseif modelid >= 3890 and modelid <= 3973 or modelid >= 3975 and modelid <= 4541 then return true
   elseif modelid >= 4550 and modelid <= 4762 or modelid >= 4806 and modelid <= 5084 then return true
   elseif modelid >= 5086 and modelid <= 5089 or modelid >= 5105 and modelid <= 5375 then return true
   elseif modelid >= 5390 and modelid <= 5682 or modelid >= 5703 and modelid <= 6010 then return true
   elseif modelid >= 6035 and modelid <= 6253 or modelid >= 6255 and modelid <= 6257 then return true
   elseif modelid >= 6280 and modelid <= 6347 or modelid >= 6349 and modelid <= 6525 then return true
   elseif modelid >= 6863 and modelid <= 7392 or modelid >= 7415 and modelid <= 7973 then return true
   elseif modelid >= 7978 and modelid <= 9193 or modelid >= 9205 and modelid <= 9267 then return true
   elseif modelid >= 9269 and modelid <= 9478 or modelid >= 9482 and modelid <= 10310 then return true
   elseif modelid >= 10315 and modelid <= 10744 or modelid >= 10750 and modelid <= 11417 then return true
   elseif modelid >= 11420 and modelid <= 11753 or modelid >= 12800 and modelid <= 13563 then return true
   elseif modelid >= 13590 and modelid <= 13667 or modelid >= 13672 and modelid <= 13890 then return true
   elseif modelid >= 14383 and modelid <= 14528 or modelid >= 14530 and modelid <= 14554 then return true
   elseif modelid == 14556 or modelid >= 14558 and modelid <= 14643 then return true
   elseif modelid >= 14650 and modelid <= 14657 or modelid >= 14660 and modelid <= 14695 then return true
   elseif modelid >= 14699 and modelid <= 14728 or modelid >= 14735 and modelid <= 14765 then return true
   elseif modelid >= 14770 and modelid <= 14856 or modelid >= 14858 and modelid <= 14883 then return true
   elseif modelid >= 14885 and modelid <= 14898 or modelid >= 14900 and modelid <= 14903 then return true
   elseif modelid >= 15025 and modelid <= 15064 or modelid >= 16000 and modelid <= 16790 then return true
   elseif modelid >= 17000 and modelid <= 17474 or modelid >= 17500 and modelid <= 17974 then return true
   elseif modelid == 17976 or modelid == 17978 or modelid >= 18000 and modelid <= 18036 then return true
   elseif modelid >= 18038 and modelid <= 18102 or modelid >= 18104 and modelid <= 18105 then return true
   elseif modelid == 18109 or modelid == 18112 or modelid >= 18200 and modelid <= 18859 then return true
   elseif modelid >= 18860 and modelid <= 19274 or modelid >= 19275 and modelid <= 19595 then return true
   elseif modelid >= 19596 and modelid <= 19999 then return true 
   else return false end
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
   style.ItemSpacing = imgui.ImVec2(8, 8)
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
script_name("Mapping Toolkit")
script_description("Assistant for mappers")
script_dependencies('imgui', 'lib.samp.events')
script_properties("work-in-pause")
script_url("https://github.com/ins1x/MappingToolkit")
script_version("4.14") -- R3
-- support sa-mp versions depends on SAMPFUNCS (0.3.7-R1, 0.3.7-R3-1, 0.3.7-R5, 0.3.DL)
-- script_moonloader(16) moonloader v.0.26 
-- editor options: tabsize 3, Unix (LF), encoding Windows-1251
-- in-game activaton: ALT + X (show main menu) or command /toolkit

-- Description:
-- Toolkit gives you more options for mapping and developing your projects. 
-- A convenient graphical interface on imgui is provided to manage all the options. 
-- The toolkit provides additional functions for working with textures and objects,
-- fixes some game bugs, supplements server commands and dialogs.

-- The functionality is quite extensive and is regularly updated. 
-- More information on the toolkit's capabilities is on the wiki. 
-- Designed for TRAINING-SANDBOX. It can work on other projects, 
-- but most of the features will be unavailable.

local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
-- require('requests') The lua-requests module is used only for version checking! 

local inicfg = require 'inicfg'
local configIni = "mappingtoolkit.ini"
local ini = inicfg.load({
   settings = {
      antiads = false,
      anticaps = false,
      antichatbot = false,
      allchatoff = false,
      autodevmode = true,
      autoreconnect = true,
      autocleanlogs = true,
      backtoworld = true,
      blockhamster = false,
      bigoffsetwarning = true,
      camdist = "1",
      cberrorwarnings = true,
      cbvalautocomplete = true,
      cbdefaultradius = 0.1,
      cbnewactivation = true,
      cbnewactivationitem = 31,
      checkupdates = true,
      chatfilter = true,
      chathidecb = false,
      chathiderp = false,
      chatinputdrop = false,
      chatonlysystem = false,
      chatprefix = 0,
      debug = false,
      devmode = false,
      dialogautocomplete = true,
      devmodelabeldist = 50.0,
      drawdist = "450",
      editnocol = false,
      extendedmenues = true,
      fov = 70,
      fog = "200",
      forcerun = false,
      fixobjinfotext = false,
      fixpedstuck = true,
      flymodespeed = 0.3,
      flymodemaxspeed = 50.0,
      freezechat = false,
      hotkeys = true,
      hotkeystips = true,
      imguifont = "trebucbd",
      imguifontsize = 14.0,
      imguitheme = 1,
      lockserverweather = false,
      maxtableitems = 100,
      menukeychanged = false,
      menukey = "0x2D",
      multilinefont = "trebucbd",
      multilinefontsize = 13.0,
      noaltenter = false,
      nointeriorradar = false,
      nopagekeys = false,
      novehiclevisualdamage = false,
      recontime = 15500,
      renderfont = "Arial",
      renderfontsize = 7,
      rendercolor = "80FFFFFF",
      remapnum = false,
      restoreobjectpos = false,
      reminderdelay = 15,
      rmbmodelidcopy = true,
      saveskin = false,
      saveweather = false,
      saveworldname = true,
      savepmmessages = true,
      setgm = false,
      serverlock = true,
      showhud = true,
      showobjectrot = false,
      showobjectcoord = false,
      showidonhud = true,
      skinid = 27,
      skipomenu = false,
      skipvehnotify = false,
      skiprules = false,
      streammemmax = 0,
      tabclickcopy = false,
      tabclickstat = false,
      time = 12,
      txtmacros = true,
      trailerspawnfix = true,
      usecustomcamdist = false,
      weather = 0,
      weatherinformer = false,
      worldlogson = false,
      worldsavelogs = true,
      worldsavereminder = false,
   },
   hotkeyactions = {
      keyJ = "/flymode",
      keyK = "",
      keyL = "/lock",
      keyN = "",
      keyB = "",
      keyZ = "",
      keyI = "",
      keyO = "",
      keyP = "",
      keyU = "/animlist",
      keyF2 = "",
      keyF3 = "",
      keyF4 = "",
      keyF5 = "",
      keyF7 = "",
      keyF9 = "",
      keyF10 = "",
      keyF11 = "",
      keyF12 = "",
   },
   mentions = {
      chatmentions = false,
      usecolor = false,
      usesound = true,
      usegametext = true,
      color = "FFD700",
      sound = 1138,
   },
   panel = {
      background = true,
      fontname = "Tahoma",
      fontsize = 7,
      showpanel = false,
      position = 0, -- position (0 = bottom pos, 1 = upper pos)
      showfps = true,
      showmode = true,
      showstreameddynobjects = true,
      showstreamedallobjects = true,
      showstreamedplayers = false,
      showstreamedvehs = false,
      showlastobject = true,
      showlasttxd = true,
      showcursorpos = true,
   },
   tmp = {
      animationdata = "",
      osearch = "",
      worldname = "",
      worldhoster = false,
      worlddescription = "",
      sadstext = "",
      searchbar = "",
      disconnecttime = 0,
   }
}, configIni)
inicfg.save(ini, configIni)

local sizeX, sizeY = getScreenResolution()
local v = nil

local isTrainingSanbox = false

local searchresults = {}
local playerAtachedObjects = {}
local objectsCollisionDel = {}
local playersTable = {}
local vehiclesTable = {}
local hiddenObjects = {}
local chatbuffer = {}
local chatfilter = {}
local hiddenPlayerObjects = {}
local streamedTextures = {}
local streamedPickups = {}
local streamed3dTexts = {}
local streamedTexts = {}

for i = 1, ini.settings.maxtableitems do
   table.insert(streamedTextures, "")
   table.insert(streamedPickups, "")
   table.insert(streamed3dTexts, "")
   table.insert(streamedTexts, "")
end
-- should be global!
vehiclesTotal = 0
playersTotal = 0

local fixcam = {x = 0.0, y = 0.0, z = 0.0}
local cam = {x = 0.0, y = 0.0, z = 0.0}
local tpcpos = {x = 0.0, y = 0.0, z = 0.0}
local worldspawnpos = {x = 0.0, y = 0.0, z = 0.0}

local fonts = {
   objectsrenderfont = renderCreateFont(ini.settings.renderfont, ini.settings.renderfontsize, 5),
   backgroundfont = renderCreateFont(ini.panel.fontname, ini.panel.fontsize, 5),
   infobarfont = renderCreateFont(ini.panel.fontname, 10, 5),
   defaultfont = nil,
   multilinetextfont = nil
}

local edit = {
   response = 0, -- 0 - exit edit, 1 - save, 2 - move
   mode = 0, -- editmodes table
}

local const = {
   txdmodelinfoid = 555,
   maxlogfilesize = 65535, --(MAX unsigned short)
}

local playerdata = {
   isPlayerSpectating = false,
   isLockPlayerControl = false,
   isPlayerEditAttachedObject = false,
   isPlayerEditObject = false,
   isChatFreezed = false,
   isWorldHoster = false,
   isWorldJoinUnavailable = false,
   disableObjectCollision = false,
   firstSpawn = true,
   flymode = false,
   flypower = 0.5,
   fps = 0,
   fps_counter = 0,
   reconattempt = 0
}

local chosen = {
   player = nil,
   vehicle = nil,
   object = nil,
   tabselectedplayer = nil,
   playerMarker = nil,
}

local threads = {
   timelap = nil,
   savereminder = nil,
}

local dialog = {
   main = imgui.ImBool(false),
   textures = imgui.ImBool(false),
   playerstat = imgui.ImBool(false),
   vehstat = imgui.ImBool(false),
   extendedtab = imgui.ImBool(false),
   objectinfo = imgui.ImBool(false),
   dialogtext = imgui.ImBool(false),
   txdlist = imgui.ImBool(false),
   toolkitmanage = imgui.ImBool(false),
}

local dialoghook = {
   action = false,
   animlist = false,
   attachcode = false,
   autoattach = false,
   backtoworld = false,
   cbnewactivation = false,
   suspendcbactivation = false,
   saveworld = false,
   saveworldname = false,
   setsadstext = false,
   setworldname = false,
   setworlddescription = false,
   loadworld = false,
   logstoggle = false,
   modelinfo = false,
   editdialog = false,
   textureslist = false,
   sampobjectslist = false,
   exitdialog = false,
   cbvalue = false,
   tbvalue = false,
   olist = false,
   otext = false,
   previewdialog = false,
   spcars = false,
   resetguns = false,
   resetvehs = false,
   vkickall = false,
   error = false,
   devmenutoggle = false
}

local checkbox = {
   autoreconnect = imgui.ImBool(ini.settings.autoreconnect),
   showhud = imgui.ImBool(ini.settings.showhud),
   backtoworld = imgui.ImBool(ini.settings.backtoworld),
   blockhamster = imgui.ImBool(ini.settings.blockhamster),
   bigoffsetwarning = imgui.ImBool(ini.settings.bigoffsetwarning),
   lockserverweather = imgui.ImBool(ini.settings.lockserverweather),
   usecustomcamdist = imgui.ImBool(ini.settings.usecustomcamdist),
   showobjectrot = imgui.ImBool(ini.settings.showobjectrot),
   showobjectcoord = imgui.ImBool(ini.settings.showobjectcoord),
   restoreobjectpos = imgui.ImBool(ini.settings.restoreobjectpos),
   chatmentions = imgui.ImBool(ini.mentions.chatmentions),
   checkupdates= imgui.ImBool(ini.settings.checkupdates),
   hotkeys = imgui.ImBool(ini.settings.hotkeys),
   hotkeystips = imgui.ImBool(ini.settings.hotkeystips),
   tabclickcopy = imgui.ImBool(ini.settings.tabclickcopy),
   freezechat = imgui.ImBool(ini.settings.freezechat),
   allchatoff = imgui.ImBool(ini.settings.allchatoff),
   chatfilter = imgui.ImBool(ini.settings.chatfilter),
   chathidecb = imgui.ImBool(ini.settings.chathidecb),
   worldsavereminder = imgui.ImBool(ini.settings.worldsavereminder),
   autodevmode = imgui.ImBool(ini.settings.autodevmode),
   setgm = imgui.ImBool(ini.settings.setgm),
   saveskin = imgui.ImBool(ini.settings.saveskin),
   saveweather = imgui.ImBool(ini.settings.saveweather),
   antiads = imgui.ImBool(ini.settings.antiads),
   anticaps = imgui.ImBool(ini.settings.anticaps),
   antichatbot = imgui.ImBool(ini.settings.antichatbot),
   remapnum = imgui.ImBool(ini.settings.remapnum),
   skinid = imgui.ImInt(ini.settings.skinid),
   showidonhud = imgui.ImBool(ini.settings.showidonhud),
   skipomenu = imgui.ImBool(ini.settings.skipomenu),
   cberrorwarnings = imgui.ImBool(ini.settings.cberrorwarnings),
   cbvalautocomplete = imgui.ImBool(ini.settings.cbvalautocomplete),
   cbnewactivation = imgui.ImBool(ini.settings.cbnewactivation),
   trailerspawnfix = imgui.ImBool(ini.settings.trailerspawnfix),
   skipvehnotify = imgui.ImBool(ini.settings.skipvehnotify),
   skiprules = imgui.ImBool(ini.settings.skiprules),
   novehiclevisualdamage = imgui.ImBool(ini.settings.novehiclevisualdamage),
   noaltenter = imgui.ImBool(ini.settings.noaltenter),
   nopagekeys = imgui.ImBool(ini.settings.nopagekeys),
   nointeriorradar = imgui.ImBool(ini.settings.nointeriorradar),
   weatherinformer = imgui.ImBool(ini.settings.weatherinformer),
   saveworldname = imgui.ImBool(ini.settings.saveworldname),
   worldlogson = imgui.ImBool(ini.settings.worldlogson),
   fixobjinfotext = imgui.ImBool(ini.settings.fixobjinfotext),
   serverlock = imgui.ImBool(ini.settings.serverlock),
   savepmmessages = imgui.ImBool(ini.settings.savepmmessages),
   
   showpanel = imgui.ImBool(ini.panel.showpanel),
   panelbackground = imgui.ImBool(ini.panel.background),
   panelshowfps = imgui.ImBool(ini.panel.showfps),
   panelshowstreamedobj = imgui.ImBool(ini.panel.showstreameddynobjects),
   panelshowstreamedallobjects = imgui.ImBool(ini.panel.showstreamedallobjects),
   panelshowstreamedvehs = imgui.ImBool(ini.panel.showstreamedvehs),
   panelshowstreamedplayers = imgui.ImBool(ini.panel.showstreamedplayers),
   panelshowcursorpos = imgui.ImBool(ini.panel.showcursorpos),
   panelshoweditdata = imgui.ImBool(ini.panel.showlastobject),
   
   usecolor = imgui.ImBool(ini.mentions.usecolor),
   usesound = imgui.ImBool(ini.mentions.usesound),
   usegametext = imgui.ImBool(ini.mentions.usegametext),
   
   allslots = imgui.ImBool(false),
   daynight = imgui.ImBool(false),
   showobjectsmodel = imgui.ImBool(false),
   showobjectsname = imgui.ImBool(false),
   drawlinetomodelid = imgui.ImBool(false),
   noempyvehstream = imgui.ImBool(true),
   hideobject = imgui.ImBool(false),
   hidestaticobjects = imgui.ImBool(false),
   hidechat = imgui.ImBool(false),
   hooksetattachedobject = imgui.ImBool(false),
   lockfps = imgui.ImBool(false),
   changefov = imgui.ImBool(false),
   fixcampos = imgui.ImBool(false),
   holdcam = imgui.ImBool(false),
   smoothcam = imgui.ImBool(false),
   teleportcoords = imgui.ImBool(false),
   logtextdraws = imgui.ImBool(false),
   logdialogresponse = imgui.ImBool(false),
   logobjects = imgui.ImBool(false),
   log3dtexts = imgui.ImBool(false),
   loggametexts = imgui.ImBool(false),
   logtxd = imgui.ImBool(false),
   logcamset = imgui.ImBool(false),
   logsetplayerpos = imgui.ImBool(false),
   logmessages = imgui.ImBool(false),
   logworlddouns = imgui.ImBool(false),
   pickeduppickups = imgui.ImBool(false),
   showtextdrawsid = imgui.ImBool(false),
   vehloads = imgui.ImBool(false),
   shadows = imgui.ImBool(false),
   noeffects = imgui.ImBool(false),
   nofactorysmoke = imgui.ImBool(false),
   nofire = imgui.ImBool(false),
   noexplosions = imgui.ImBool(false),
   nobloodonearth = imgui.ImBool(false),
   novision = imgui.ImBool(false),
   notiretracks = imgui.ImBool(false),
   noclouds = imgui.ImBool(false),
   nowater = imgui.ImBool(false),
   nowind = imgui.ImBool(false),
   nosnow = imgui.ImBool(false),
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
   hidematerialtext = imgui.ImBool(false),
   hideped = imgui.ImBool(false),
   objectcollision = imgui.ImBool(false),
   editnocol = imgui.ImBool(false),
   changemdo = imgui.ImBool(false),
   findveh = imgui.ImBool(false),
   objectscale = imgui.ImBool(false),
   freezepos = imgui.ImBool(false),
   searchobjectsext = imgui.ImBool(false),
   hideplayers = imgui.ImBool(false),
   hidevehicles = imgui.ImBool(false),
   hideattaches = imgui.ImBool(false),
   hide3dtexts = imgui.ImBool(false),
   nametagoff = imgui.ImBool(false),
   txdparamsonshow = imgui.ImBool(false),
   txdparamsonclick = imgui.ImBool(false),
   txdproportional = imgui.ImBool(true),
   txdsetshadow = imgui.ImBool(false),
   txdusebox = imgui.ImBool(false),
   txdusemodel = imgui.ImBool(false),
   txdsetinivisbox = imgui.ImBool(false),
   txdsetselectable = imgui.ImBool(false),
   setobjalpha = imgui.ImBool(false),
   hidelastobject = imgui.ImBool(false),
   bliplastobject = imgui.ImBool(false),
   noworldbounds = imgui.ImBool(false),
   nogravity = imgui.ImBool(false),
   chatinputdrop = imgui.ImBool(false),
   chathiderp = imgui.ImBool(false),
   chatonlysystem = imgui.ImBool(false),
   searchaslower = imgui.ImBool(true),
   searchwithoutformat = imgui.ImBool(false),
   searchregexp = imgui.ImBool(false),
   lockcamchange = imgui.ImBool(false),
   pickupinfo = imgui.ImBool(false),
   lockcambehind = imgui.ImBool(false),
   lockcamfront = imgui.ImBool(false),
   streammemmax = imgui.ImBool(false),
   drunkcam = imgui.ImBool(false),
   test = imgui.ImBool(false)
}

local input = {
   readonly = true,
   isbot = false,
   error = false,
   camdelay = imgui.ImInt(5000),
   camshake = imgui.ImInt(500),
   gametexttime = imgui.ImInt(5000),
   hideobjectid = imgui.ImInt(615),
   mdomodel = imgui.ImInt(0),
   mdodist = imgui.ImInt(100),
   rendselectedmodelid = imgui.ImInt(0),
   rendmaxdist = imgui.ImInt(250),
   timelapdelay = imgui.ImInt(5),
   tpstep = imgui.ImInt(3),
   txdid = imgui.ImInt(0),
   txdposx = imgui.ImFloat(50.0),
   txdposy = imgui.ImFloat(250.0),
   txdlettersizex = imgui.ImFloat(0.25),
   txdlettersizey = imgui.ImFloat(1.0),
   txdboxsizex = imgui.ImFloat(80.0),
   txdboxsizey = imgui.ImFloat(80.0),
   txdstyle = imgui.ImInt(1),
   txdmodel = imgui.ImInt(411),
   txdmodelrx = imgui.ImFloat(-10.0),
   txdmodelry = imgui.ImFloat(1.0),
   txdmodelrz = imgui.ImFloat(-45.0),
   txdmodelzoom = imgui.ImFloat(1.0),
   txdmodelclr1 = imgui.ImInt(1),
   txdmodelclr2 = imgui.ImInt(1),
   txdshowtime = imgui.ImInt(-1),
   txdclickid = imgui.ImInt(0),
   txdslot = imgui.ImInt(0),
   txdobject = imgui.ImInt(0),
   pickupid = imgui.ImInt(0),
   streamdist = imgui.ImFloat(200.0),
   renderfontsize = imgui.ImInt(ini.settings.renderfontsize),
   reminderdelay = imgui.ImInt(ini.settings.reminderdelay),
   cbdefaultradius = imgui.ImFloat(ini.settings.cbdefaultradius),
   streammemmax = imgui.ImInt(ini.settings.streammemmax),
   flymodemaxspeed = imgui.ImFloat(ini.settings.flymodemaxspeed),
   flymodespeed = imgui.ImFloat(ini.settings.flymodespeed),
   rendclrrgba = imgui.ImFloat4(1, 1, 1, 1),
   txdclrrgba = imgui.ImFloat4(1, 1, 1, 1),
   txdletcolorrgba = imgui.ImFloat4(1, 1, 1, 1),
   txdoutlinecolorrgba = imgui.ImFloat4(0, 0, 0, 0),
   txdshadowrgba = imgui.ImFloat4(1, 1, 1, 1),
   txdboxcolorrgba = imgui.ImFloat4(1, 1, 1, 1),
   colorpicker = imgui.ImFloat4(1, 0, 0, 1)
}

local slider = {
   fog = imgui.ImInt(ini.settings.fog),
   drawdist = imgui.ImInt(ini.settings.drawdist),
   weather = imgui.ImInt(ini.settings.weather),
   time = imgui.ImInt(ini.settings.time),
   fov = imgui.ImInt(ini.settings.fov),
   scale = imgui.ImFloat(1.0),
   flymodepower = imgui.ImFloat(0.1),
   camdist = imgui.ImInt(ini.settings.camdist)
}

local tabmenu = {
   main = 1,
   objects = 1,
   settings = 9,
   coords = 1,
   credits = 1,
   effects = 1,
   hotkeys = 1,
   onlinesearch = 1,
   colorformat = 1,
   favorites = 1,
   txd = 1,
   txdalign = 1,
   info = 1,
   mp = 1,
   cb = 1,
   cmds = 1
}

local textbuffer = {
   attachcode = imgui.ImBuffer(32),
   vehiclename = imgui.ImBuffer(64),
   findplayer = imgui.ImBuffer(32),
   rendcolor = imgui.ImBuffer(16),
   txdletcolor = imgui.ImBuffer(16),
   txdoutlinecolor = imgui.ImBuffer(16),
   txdboxcolor = imgui.ImBuffer(16),
   txdsprite = imgui.ImBuffer(32),
   cbdefaultradius = imgui.ImBuffer(6),
   colorsearch = imgui.ImBuffer(24),
   ocolor = imgui.ImBuffer(12),
   objectid = imgui.ImBuffer(48),
   rgb = imgui.ImBuffer(256),
   fixcamx = imgui.ImBuffer(12),
   fixcamy = imgui.ImBuffer(12),
   fixcamz = imgui.ImBuffer(12),
   camx = imgui.ImBuffer(12),
   camy = imgui.ImBuffer(12),
   camz = imgui.ImBuffer(12),
   tpcx = imgui.ImBuffer(12),
   tpcy = imgui.ImBuffer(12),
   tpcz = imgui.ImBuffer(12),
   sms = imgui.ImBuffer(256),
   pid = imgui.ImBuffer(4),
   tpstep = imgui.ImBuffer(2),
   saveskin = imgui.ImBuffer(4),
   searchbar = imgui.ImBuffer(32),
   pattern = imgui.ImBuffer(144),
   strtest = imgui.ImBuffer(144),
   txdstring = imgui.ImBuffer(256),
   txdcbstring = imgui.ImBuffer(512),
   gametextclr = imgui.ImBuffer(144),
   dialogtext = imgui.ImBuffer(2048),
   chatfilters = imgui.ImBuffer(4096),
   favobjects = imgui.ImBuffer(65536),
   favtxd = imgui.ImBuffer(65536),
   favtxt = imgui.ImBuffer(65536),
   cmdlist = imgui.ImBuffer(65536),
   animlist = imgui.ImBuffer(65536),
   cblist = imgui.ImBuffer(65536)
}

local nops = {
   spectator = imgui.ImBool(false),
   health = imgui.ImBool(false),
   givegun = imgui.ImBool(false),
   resetgun = imgui.ImBool(false),
   setgun = imgui.ImBool(false),
   spawn = imgui.ImBool(false),
   death = imgui.ImBool(false),
   psync = imgui.ImBool(false),
   requestclass = imgui.ImBool(false),
   requestspawn = imgui.ImBool(false),
   applyanimation = imgui.ImBool(false),
   clearanimation = imgui.ImBool(false),
   showdialog = imgui.ImBool(false),
   clicktextdraw = imgui.ImBool(false),
   selecttextdraw = imgui.ImBool(false),
   forceclass = imgui.ImBool(false),
   facingangle = imgui.ImBool(false),
   togglecontrol = imgui.ImBool(false),
   position = imgui.ImBool(false),
   setdrunk = imgui.ImBool(false),
   setskin = imgui.ImBool(false),
   setspecialaction = imgui.ImBool(false),
   setplayerattachedobject = imgui.ImBool(false),
   audiostream = imgui.ImBool(false)
}

local combobox = {
   cbactivations = imgui.ImInt(ini.settings.cbnewactivationitem),
   imguitheme = imgui.ImInt(ini.settings.imguitheme),
   chatprefix = imgui.ImInt(ini.settings.chatprefix),
   
   hotkeyJaction = imgui.ImInt(0),
   hotkeyKaction = imgui.ImInt(0),
   hotkeyIaction = imgui.ImInt(0),
   hotkeyLaction = imgui.ImInt(0),
   hotkeyRaction = imgui.ImInt(0),
   hotkeyOaction = imgui.ImInt(0),
   hotkeyPaction = imgui.ImInt(0),
   hotkeyNaction = imgui.ImInt(0),
   hotkeyBaction = imgui.ImInt(0),
   hotkeyZaction = imgui.ImInt(0),
   hotkeyUaction = imgui.ImInt(0),
   
   hotkeyF2action = imgui.ImInt(0),
   hotkeyF3action = imgui.ImInt(0),
   hotkeyF4action = imgui.ImInt(0),
   hotkeyF5action = imgui.ImInt(0),
   hotkeyF7action = imgui.ImInt(0),
   hotkeyF9action = imgui.ImInt(0),
   hotkeyF10action = imgui.ImInt(0),
   hotkeyF11action = imgui.ImInt(0),
   hotkeyF12action = imgui.ImInt(0),
   
   attname = imgui.ImInt(0),
   chatselect = imgui.ImInt(0),
   fonts = imgui.ImInt(0),
   selecttable = imgui.ImInt(2),
   objects = imgui.ImInt(0),
   weaponselect = imgui.ImInt(0),
   itemad = imgui.ImInt(0),
   gamestate = imgui.ImInt(0),
   gametextstyles = imgui.ImInt(0),
   txdsearchfilter = imgui.ImInt(0),
   txdexport = imgui.ImInt(0),
   txdtype = imgui.ImInt(0),
   exportformat = imgui.ImInt(0),
   uifontselect = imgui.ImInt(0),
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
   txdslot = nil,
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

local LastData = {
   lastWorldNumber = 0, -- is not same GetVirtualWorldId
   lastWorldName = "",
   lastWorldDescription = "",
   lastCommand = "",
   lastTextBuffer = "",
   lastClickedTextdrawId = 0,
   lastShowedTextdrawId = 0,
   lastDialogInput = nil,
   lastDialogText = nil,
   lastDialogTitle = nil,
   lastDialogStyle = nil,
   lastDialogId = 0,
   lastDialogButton = nil,
   lastListboxId = nil,
   lastcb = nil,
   lastActor = nil,
   lastAction = nil,
   lastPass = nil,
   lastAccept = nil,
   lastModel = nil, 
   lastVehicle = nil,
   lastTextureListIndex = 0,
   lastTextureListPage = 0,
   lastWeather = 1,
   lastLink = "",
   lastOtext = "",
   lastPickupBlip = nil,
   lastVehinfoModelid = 0,
   lastCbvaluebuffer = nil,
   lastTbvaluebuffer = nil,
   lastMinigame = nil,
   lastModelinfo = 0,
   lastLoadedWorldNumber = nil
}

local imguiThemeNames = {
   "Dark Night", "Grey-Blue", "Brutal", "Training", "Halloween"
}

local gamestates = {
   'None', 'Wait Connect', 'Await Join', 
   'Connected', 'Restarting', 'Disconnected'
}

local editmodes = {
   "None", "Edit", "Clone", "Remove", "Retexture"
}

local trainingGamemodes = {
   "Deathmatch", "WoT", "GunGame", "Copchase", "Derby"
}

local cbActivationItemsList = {
   u8"Вход",u8"Выход",u8"Нанесение урона",u8"Получение урона",u8"Выстрел",u8"Убийство",u8"Смерть",
   u8"Сесть в транспорт",u8"Выйти из транспорта",u8"Попытка сесть в транспорт",u8"Взять чекпоинт",
   u8"Выйти из чекпоинта",u8"Взять гоночный чекпоинт",u8"Выйти из гоночного чекпоинта",
   u8"Пешком: TAB | В ТС: ALT GR / LCTRL / NUM0",u8"C | H / CAPSLOCK ",u8"LCTRL / LMB | LALT ",
   u8"SPACE | W",u8"ENTER | ENTER",u8"LSHIFT | S",u8"RMB | SPACE",u8"NUM1 / MMB | 2 / NUMPAD +",
   u8"LALT | N/A",u8"N/A | NUM8",u8"N/A | NUM2",u8"NUM4 | NUM4",u8"NUM6 | NUM6",u8"Y | Y",u8"N | N",
   u8"H | H",u8"Выстрелить по объекту",u8"Ввод диалога",u8"Завести двигатель",u8"Заглушить двигатель",
   u8"РП смерть",u8"Выход из мира",u8"Метка на карте",u8"Пешком: N/A | В ТС: Q",u8"Пешком: N/A | В ТС: E",
   u8"Выбор игрока в TAB",u8"Смена интерьера",u8"Смена статуса сирены",u8"Спавн игрока",
   u8"Клик на текстдрав",u8"Отправить сообщение",u8"Выбор объекта"
}

local hotkeysActivationList = {
   u8"Не использовать", u8"Прыгнуть", u8"Заспавнить себя", u8"Слапнуть себя", 
   u8"Взять джетпак", u8"Взять bmx", u8"Взять оружие", u8"Взять транспорт",
   u8"Перейти в режим полета", u8"Спек за ближайшим игроком", 
   u8"Перейти в режим редактирования", u8"Выбрать объект (по клику)",
   u8"Открыть меню редактирования", u8"Открыть инфо по объекту",
   u8"Открыть список анимаций", u8"Создать комадный блок", 
   u8"Откр/Закр транспорт", u8"Починить транспорт", u8"Открыть меню транспорта",
   u8"Сохранить мир", u8"Загрузить мир", u8"Список комадных блоков",
   u8"Повернуть объект на 90", u8"Повернуть объект на 45",
   u8"Скрыть/Показать нижнюю панель", u8"Открыть список миров"
}

local hotkeysActivationCmds = {
   "", "/jump", "/spawnme", "/slapme", "/jetpack", "/veh 481", "/weapon",
   "/veh", "/flymode", "/spec", "/oedit", "/csel", "/omenu", "/oinfo",
   "/animlist", "/cb", "/lock", "/fix", "/vmenu", "/savevw", "/loadvw",
   "/cblist", "/rot", "/rot 45", "/panel", "/list"
}

local chatPrefixList = {
   "", "!", "@", "$", "/b", "/c", "/r", "/f"
}

local chatPrefixNames = {
   u8"Не выбран", u8"Глобальный чат", u8"Чат игрового мира", 
   u8"Чат модераторов мира", u8"ООС чат", u8"Персональный чат",
   u8"Сообщение в рацию", u8"Сообщение для команд"
}

local attCodes = {
   "CC49-45A5-1EC8-4A50", -- пикачу
   "21A4-748E-6B0B-4000", -- хедкраб
   "CFB5-5106-DEC3-4F74", -- день рождения
   "2E5A-3E8C-2D9F-4055", -- деловой ананимас
   "7773-50CB-370A-48C9", -- пингвин
   "1A4B-E5ED-6A03-41FA", -- немец
   "31F0-321B-86E3-4A4F", -- самурай
   "8286-DCEB-1BC4-4322", -- бабочка
   "D52-818A-E71D-4B89", -- енот
}

local attCodeNames = {
   u8"пикачу", u8"хедкраб", u8"день рождения", u8"деловой ананимас",
   u8"пингвин", u8"немец", u8"самурай", u8"бабочка", u8"енот"
}

local weaponNames = {
    [0] = 'Fists',
    [1] = 'Brass Knuckles',
    [2] = 'Golf Club',
    [3] = 'Nightstick',
    [4] = 'Knife',
    [5] = 'Baseball Bat ',
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
local uiFontsList = {
   "Arial", "Arial Black", "Courier", "Courier New",
   "Lucida Console", "Segoe UI", "Tahoma", 
   "Times New Roman", "Verdana", "Trebuchet MS"
}

local uiFontsFilenames = {
   "arial", "arialbd", "coure", "cour",
   "lucon", "segoeui", "tahoma", 
   "times", "verdana", "trebucbd"
}

local PopularFonts = {
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
      
      if not ini.settings.menukeychanged then
         sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Открыть меню: {CDCDCD}ALT + X", 0xFFFFFF)
      else
         sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Открыть меню: {CDCDCD}/toolkit", 0xFFFFFF)
      end
      
      if not doesDirectoryExist("moonloader/resource/mappingtoolkit") then 
         createDirectory("moonloader/resource/mappingtoolkit")
      end
      
      if not doesDirectoryExist("moonloader/resource/mappingtoolkit/export") then 
         createDirectory("moonloader/resource/mappingtoolkit/export")
      end
      
      if not doesDirectoryExist("moonloader/resource/mappingtoolkit/history") then 
         createDirectory("moonloader/resource/mappingtoolkit/history")
      end
      
      if doesFileExist('moonloader/resource/mappingtoolkit/resetsetting.txt') 
      or doesFileExist('moonloader/resetsetting.txt') then
         os.rename(getGameDirectory().."//moonloader//config//mappingtoolkit.ini", getGameDirectory().."//moonloader//config//prevconf_backup_mappingtoolkit.ini")
         print("Настройки были сброшены на стандартные. Тулкит автоматически перезагрузится.")
         print("Резервную копию ваших предыдущих настроек можно найти в moonloader/config.")
         sampAddChatMessage("Настройки были сброшены на стандартные. Тулкит автоматически перезагрузится.",-1)
         sampAddChatMessage("Резервную копию ваших предыдущих настроек можно найти в moonloader/config.",-1)
         reloadScripts()
      end      
      
      if not doesFileExist(getFolderPath(0x14)..'\\'..ini.settings.imguifont..'.ttf') then
         ini.settings.imguifont = "trebucbd"
         ini.settings.imguifontsize = 14
      end
      
      -- training-autologin already have a skip rules function
      if doesFileExist('moonloader/training-autologin.lua')
      or doesFileExist('moonloader/training-autologin.luac') then
         ini.settings.skiprules = false 
         checkbox.skiprules.v = false
      end
      
      -- dialogs.asi cause crashes
      if doesFileExist(getGameDirectory()..'\\dialogs.asi') then
         sampAddChatMessage("[Mapping Toolkit] {FFFFFF}Плагин dialogs.asi может вызывать краши в кастомных диалогах, рекомендуется его удалить!", 0x0FF0000)
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
         -- if getFileSize('moonloader/resource/mappingtoolkit/modules/texturelist.lua') ~= 379889 then
            -- sampAddChatMessage("[Mapping Toolkit] {696969}texturelist.lua{FFFFFF} устарел. Обновите его для корректной работы ретекстура", 0x0FF0000)
         -- end
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
      
      if doesFileExist(getGameDirectory()..'\\moonloader\\resource\\mappingtoolkit\\favorites\\objects.txt') then
         local file = io.open(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//favorites//objects.txt", "r")
         textbuffer.favobjects.v = file:read('*a')
         file:close()
      else
         local file = io.open(getGameDirectory().."/moonloader/resource/mappingtoolkit/favorites/objects.txt", "r")
         file:write(u8"Файл поврежден либо не найден")
         file:close()
      end
      
      if doesFileExist(getGameDirectory()..'\\moonloader\\resource\\mappingtoolkit\\favorites\\textures.txt') then
         local file = io.open(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//favorites//textures.txt", "r")
         textbuffer.favtxd.v = file:read('*a')
         file:close()
      else
         local file = io.open(getGameDirectory().."/moonloader/resource/mappingtoolkit/favorites/textures.txt", "w")
         file:write(u8"Файл поврежден либо не найден")
         file:close()
      end
      
      if doesFileExist(getGameDirectory()..'\\moonloader\\resource\\mappingtoolkit\\favorites\\textsurfaces.txt') then
         local file = io.open(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//favorites//textsurfaces.txt", "r")
         textbuffer.favtxt.v = file:read('*a')
         file:close()
      else
         local file = io.open(getGameDirectory().."/moonloader/resource/mappingtoolkit/favorites/textsurfaces.txt", "r")
         file:write(u8"Файл поврежден либо не найден")
         file:close()
      end
      
      if doesFileExist(getGameDirectory()..'\\moonloader\\resource\\mappingtoolkit\\cmdlist.txt') then
         local file = io.open(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//cmdlist.txt", "r")
         textbuffer.cmdlist.v = file:read('*a')
         file:close()
      else
         local file = io.open(getGameDirectory().."/moonloader/resource/mappingtoolkit/cmdlist.txt", "w")
         file:write(u8"Файл поврежден либо не найден\n")
         file:write(u8"Скачать стандартный можно по ссылке:\n")
         file:write("https://github.com/ins1x/MappingToolkit/blob/main/moonloader/resource/mappingtoolkit/cmdlist.txt")
         file:close()
      end
      
      if doesFileExist(getGameDirectory()..'\\moonloader\\resource\\mappingtoolkit\\anims.txt') then
         local file = io.open(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//anims.txt", "r")
         textbuffer.animlist.v = file:read('*a')
         file:close()
      else
         local file = io.open(getGameDirectory().."/moonloader/resource/mappingtoolkit/anims.txt", "w")
         file:write(u8"Файл поврежден либо не найден\n")
         file:write(u8"Скачать стандартный можно по ссылке:\n")
         file:write("https://github.com/ins1x/MappingToolkit/blob/main/moonloader/resource/mappingtoolkit/anims.txt")
         file:close()
      end
      
      if doesFileExist(getGameDirectory()..'\\moonloader\\resource\\mappingtoolkit\\cblist.txt') then
         local file = io.open(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//cblist.txt", "r")
         textbuffer.cblist.v = file:read('*a')
         file:close()
      else
         local file = io.open("moonloader/resource/mappingtoolkit/cblist.txt", "w")
         file:write(u8"Файл поврежден либо не найден\n")
         file:write(u8"Скачать стандартный можно по ссылке:\n")
         file:write("https://github.com/ins1x/MappingToolkit/blob/main/moonloader/resource/mappingtoolkit/cblist.txt")
         file:close()
      end
      
      if not doesFileExist(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//history//worldlogs.txt") then
         local file = io.open(getGameDirectory()..
         "//moonloader//resource//mappingtoolkit//history//worldlogs.txt", "w")
         file:write("")
         file:close()
      end
      
      if doesFileExist(getGameDirectory()..'\\moonloader\\resource\\mappingtoolkit\\chatfilter.txt') then
         chatfilterfile = io.open("moonloader/resource/mappingtoolkit/chatfilter.txt", "r")
         for template in chatfilterfile:lines() do
            table.insert(chatfilter, u8:decode(template))
         end
         textbuffer.chatfilters.v = chatfilterfile:read('*a')
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
      
      -- set day-night button mode
      if ini.settings.time > 20 and ini.settings.time < 6 then
         checkbox.daynight.v = false
      else
         checkbox.daynight.v = true         
      end
      
      if ini.settings.nopagekeys then
         writeMemory(getModuleHandle("samp.dll") + 0x63700, 1, 0xC3, true)
      end
      
      if ini.settings.autocleanlogs then
         local logpath = 'moonloader/resource/mappingtoolkit/history'
         if getFileSize(logpath..'/texture.txt') > const.maxlogfilesize then
            os.remove(logpath..'/texture.txt')
         end
         if getFileSize(logpath..'/worldlogs.txt') > const.maxlogfilesize then
            os.remove(logpath..'/worldlogs.txt')
         end
         if getFileSize(logpath..'/pmmessages.txt') > const.maxlogfilesize then
            os.remove(logpath..'/pmmessages.txt')
         end
      end
      
      if ini.settings.streammemmax  >= 100 then
         checkbox.streammemmax.v = true
      end
      
      if ini.tmp.osearch:len() > 1 then
         textbuffer.objectid.v = ini.tmp.osearch
      end
      
      if ini.tmp.searchbar:len() > 1 then
         textbuffer.searchbar.v = ini.tmp.searchbar
      end
      
      -- restore world hoster right if script reloaded
      if ini.tmp.worldhoster then 
         playerdata.isWorldHoster = true
         inicfg.save(ini, configIni)
      end
      
      textbuffer.vehiclename.v = 'bmx'
      textbuffer.txdstring.v = "This is an ~y~example ~g~textdraw"
      textbuffer.txdsprite.v = "LD_TATT:11dice2"
      textbuffer.cbdefaultradius.v = string.format("%.1f", ini.settings.cbdefaultradius)
      textbuffer.attachcode.v = tostring(attCodes[combobox.attname.v+1])
      
      -- legacy color fix
      local formattedcolor = tostring(ini.settings.rendercolor)
      formattedcolor = formattedcolor:gsub("}","")
      formattedcolor = formattedcolor:gsub("{","")
      textbuffer.rendcolor.v = formattedcolor
      
      combobox.chatprefix.v = ini.settings.chatprefix
      
      for k, v in ipairs(uiFontsFilenames) do
         if v == ini.settings.imguifont then
            combobox.uifontselect.v = k-1
            break
         end
      end
      
      hotkeyActionInit()
      
      if ini.settings.worldsavereminder then
         SaveReminder()
      end
      
      if ini.settings.checkupdates then
         checkScriptUpdates()
      end
      
      --- END init
      while true do
      wait(0)
      
      -- Autoreconnect
      -- Required use reset_remove.asi fix
      if ini.settings.autoreconnect then
         local chatstring = sampGetChatString(99)
         if chatstring == "Server closed the connection." 
         or chatstring == "You are banned from this server."
         or chatstring == "Use /quit to exit or press ESC and select Quit Game" then
            playerdata.reconattempt = playerdata.reconattempt + 1
            cleanStreamMemory()
            playerdata.flymode = false
            playerdata.isWorldHoster = false
            ini.tmp.worldhoster = false
            inicfg.save(ini, configIni)
            sampDisconnectWithReason(quit)
            --sampSetGamestate(5)-- GAMESTATE_DISCONNECTED
            sampAddChatMessage("Wait reconnecting...", 0xffb7d5ef)
            wait(ini.settings.recontime + playerdata.reconattempt*3000)
            sampAddChatMessage("Try connecting to server...", 0xffb7d5ef)
            sampSetGamestate(1)-- GAMESTATE_WAIT_CONNECT
         end
      end
      
      -- -- sampGetCurrentServerName() returns a value with a long delay
      -- -- unlike receiving the IP and port. Therefore, for correct operation, the code is placed here      
      local servername = sampGetCurrentServerName()
      
      if servername:find("TRAINING") or ini.settings.forcerun then
         isTrainingSanbox = true
      end
      
      -- Unload script if not localhost server and not is TRAINING-SANDBOX
      if ini.settings.serverlock then
         if not servername:find("SA.+MP") then
            local ip, port = sampGetCurrentServerAddress()
            
            if not ip:find("127.0.0.1") and not servername:find("TRAINING") then
               print("was automatically unloaded [serverlock]")
               thisScript():unload()
            end
         end
      end
      
      -- Imgui menu
      imgui.RenderInMenu = false
      imgui.ShowCursor = true
      imgui.LockPlayer = false
      imgui.Process = dialog.main.v
      
      -- chatfix
      if isTrainingSanbox then
         if isKeyJustPressed(0x54) 
         and not sampIsScoreboardOpen() 
         and not isSampfuncsConsoleActive() then
            if sampIsDialogActive() then
               local dialogType = sampGetCurrentDialogType()
               -- if not DIALOG_STYLE_INPUT and DIALOG_STYLE_PASSWORD
               if dialogType ~= 1 and dialogType ~= 3 then
                  sampSetChatInputEnabled(true)
               end
            else
              sampSetChatInputEnabled(true)
            end
         end
      end
      
      -- if isKeyDown(0x09) and dialog.main.v then -- TAB
         -- sampToggleScoreboard(true)
      -- end
      
      -- Camera distantion set
      if ini.settings.usecustomcamdist then
         setCameraDistanceActivated(1)
         setCameraDistance(ini.settings.camdist)
         
         -- Fix cam stuck bug
         if not sampIsChatInputActive() and not sampIsDialogActive()
         and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
            if isKeyDown(0x56) or isKeyDown(0x24) then -- V or HOME key
               ini.settings.usecustomcamdist = false
               setCameraDistanceActivated(0)
               setCameraDistance(0)
            end
         end
      end
      
      -- clear chatinput on close
      if ini.settings.chatinputdrop then
         if not sampIsChatInputActive() then
            sampSetChatInputText("")
         end
      end
      
      -- disable visual damage on gm car
      if ini.settings.novehiclevisualdamage then
         if isCharInAnyCar(playerPed) then
            local car = getCarCharIsUsing(playerPed)
            local health = getCarHealth(car)
            if health > 1000.0 then
               setCarCanBeVisiblyDamaged(car, false)
            end
         end
      end
      
      -- preset time and weather
      if ini.settings.lockserverweather then
         setTime(ini.settings.time)
         setWeather(ini.settings.weather)
      end
      
      -- Win key (Hide main menu, fix bug with collapsing)
      if isKeyJustPressed(0x5B) or isKeyJustPressed(0x5C) 
      and not isPauseMenuActive() then 
         if dialog.main.v then dialog.main.v = false end
      end
         
      -- Hide dialogs on ESC
      if isKeyJustPressed(0x1B) and not sampIsChatInputActive() 
      and not sampIsDialogActive() and not isPauseMenuActive() 
      and not isSampfuncsConsoleActive() then
         if dialog.main.v then dialog.main.v = false end
         if dialog.textures.v then dialog.textures.v = false end
         if dialog.playerstat.v then dialog.playerstat.v = false end
         if dialog.vehstat.v then dialog.vehstat.v = false end
         if dialog.extendedtab.v then dialog.extendedtab.v = false end
         if dialog.objectinfo.v then dialog.objectinfo.v = false end
         if dialog.dialogtext.v then dialog.dialogtext.v = false end
         if dialog.txdlist.v then dialog.txdlist.v = false end
         if dialog.toolkitmanage.v then dialog.toolkitmanage.v = false end
         if tabmenu.main == 2 then -- durtyfix tab unfolding
            tabmenu.main = 1
         end
      end 
      
      if ini.settings.menukeychanged then
         if isKeyDown(tonumber(ini.settings.menukey)) 
         and not sampIsChatInputActive() and not isPauseMenuActive() then 
            dialog.main.v = not dialog.main.v
            if ini.panel.showpanel then 
               checkbox.showpanel.v = true
            end
         end
      else
         -- ALT+X (Main menu activation)
         if isKeyDown(0x12) and isKeyJustPressed(0x58) 
         and not sampIsChatInputActive() and not isPauseMenuActive() then 
            dialog.main.v = not dialog.main.v
            if ini.panel.showpanel then 
               checkbox.showpanel.v = true
            end
         end
      end
      
      -- fix player stuck bug (Unfreeze)
      -- LMB + W + (SHIFT or SPACE) 
      if isKeyDown(0x01) and isKeyDown(0x57) then
         if isKeyDown(0x10) or isKeyDown(0x20) then
            freezeCharPosition(playerPed, false)
            setPlayerControl(PLAYER_HANDLE, true)
            lockPlayerControl(false)
         end
      end
         
      if isTrainingSanbox then
         -- CTRL + SHIFT + V
         if isKeyDown(0x11) and isKeyDown(0x10) and isKeyDown(0x56) 
         and not sampIsChatInputActive() and not isPauseMenuActive()
         and not isSampfuncsConsoleActive() then  
            if ini.settings.cbvalautocomplete and LastData.lastCbvaluebuffer then
               lua_thread.create(function()
                  wait(50)
                  sampSetCurrentDialogEditboxText(tostring(LastData.lastCbvaluebuffer))
               end)
               LastData.lastTextBuffer = ""
            end
            
            if ini.settings.cbvalautocomplete and LastData.lastTbvaluebuffer then
               lua_thread.create(function()
                  wait(50)
                  sampSetCurrentDialogEditboxText(tostring(LastData.lastTbvaluebuffer))
               end)
               LastData.lastTextBuffer = ""
            end
            
            -- if dialoghook.attachcode then
               -- lua_thread.create(function()
                  -- wait(50)
                  -- sampSetCurrentDialogEditboxText("CC49-45A5-1EC8-4A50")
               -- end)
            -- end
            
            if LastData.lastOtext and dialoghook.otext then
               if LastData.lastOtext:len() > 1 then
                  lua_thread.create(function()
                     wait(50)
                     sampSetCurrentDialogEditboxText(tostring(LastData.lastOtext))
                  end)
               end
            end
            
            if LastData.lastTextBuffer then
               if LastData.lastTextBuffer:len() > 1 then
                  sampSetCurrentDialogEditboxText(LastData.lastTextBuffer)
               end
            end
         end
         -- CTRL + SHIFT + L
         if isKeyDown(0x11) and isKeyDown(0x10) and isKeyDown(0x4C) 
         and not sampIsChatInputActive() and not isPauseMenuActive()
         and not isSampfuncsConsoleActive() then  
            if LastData.lastLink then
               local link = 'explorer "'..LastData.lastLink..'"'
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Переход по ссылке: "..LastData.lastLink, 0x0FF6600)
               os.execute(link)
            end
         end
      end
      
      if ini.settings.hotkeys then
         -- In onSendEditObject copy object modelid on RMB
         if ini.settings.rmbmodelidcopy then
            if isKeyJustPressed(0x02) and edit.response == 2 and not sampIsChatInputActive() 
            and not sampIsDialogActive() and not isPauseMenuActive() 
            and not isSampfuncsConsoleActive() then 
               setClipboardText(LastObject.modelid)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}modelid скопирован в буффер обмена", 0x0FF6600)
            end
         end
         
         if not sampIsChatInputActive() and not sampIsDialogActive() 
         and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
            if isKeyJustPressed(0x4A) and ini.hotkeyactions.keyJ ~= nil and string.len(ini.hotkeyactions.keyJ) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyJ))
            end
            if isKeyJustPressed(0x49) and ini.hotkeyactions.keyI ~= nil and string.len(ini.hotkeyactions.keyI) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyI))
            end
            if isKeyJustPressed(0x4B) and ini.hotkeyactions.keyK ~= nil and string.len(ini.hotkeyactions.keyK) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyK))
            end
            if isKeyJustPressed(0x4C) and ini.hotkeyactions.keyL ~= nil and string.len(ini.hotkeyactions.keyL) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyL))
            end
            if isKeyJustPressed(0x4E) and ini.hotkeyactions.keyN ~= nil and string.len(ini.hotkeyactions.keyN) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyN))
            end
            if isKeyJustPressed(0x42) and ini.hotkeyactions.keyB ~= nil and string.len(ini.hotkeyactions.keyB) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyB))
            end
            if isKeyJustPressed(0x4F) and ini.hotkeyactions.keyO ~= nil and string.len(ini.hotkeyactions.keyO) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyO))
            end
            if isKeyJustPressed(0x50) and ini.hotkeyactions.keyP ~= nil and string.len(ini.hotkeyactions.keyP) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyP))
            end
            if isKeyJustPressed(0x52) and ini.hotkeyactions.keyR ~= nil and string.len(ini.hotkeyactions.keyR) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyR))
            end
            if isKeyJustPressed(0x5A) and ini.hotkeyactions.keyZ ~= nil and string.len(ini.hotkeyactions.keyZ) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyZ))
            end
            if isKeyJustPressed(0x55) and ini.hotkeyactions.keyU ~= nil and string.len(ini.hotkeyactions.keyU) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyU))
            end
            -- F keys
            if isKeyJustPressed(0x71) and ini.hotkeyactions.keyF2 ~= nil and string.len(ini.hotkeyactions.keyF2) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF2))
            end
            if isKeyJustPressed(0x72) and ini.hotkeyactions.keyF3 ~= nil and string.len(ini.hotkeyactions.keyF3) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF3))
            end
            if isKeyJustPressed(0x73) and ini.hotkeyactions.keyF4 ~= nil and string.len(ini.hotkeyactions.keyF4) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF4))
            end
            if isKeyJustPressed(0x74) and ini.hotkeyactions.keyF5 ~= nil and string.len(ini.hotkeyactions.keyF5) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF5))
            end
            if isKeyJustPressed(0x76) and ini.hotkeyactions.keyF7 ~= nil and string.len(ini.hotkeyactions.keyF7) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF7))
            end
            if isKeyJustPressed(0x78) and ini.hotkeyactions.keyF9 ~= nil and string.len(ini.hotkeyactions.keyF9) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF9))
            end
            if isKeyJustPressed(0x79) and ini.hotkeyactions.keyF10 ~= nil and string.len(ini.hotkeyactions.keyF10) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF10))
            end
            if isKeyJustPressed(0x7A) and ini.hotkeyactions.keyF11 ~= nil and string.len(ini.hotkeyactions.keyF11) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF11))
            end
            if isKeyJustPressed(0x7B) and ini.hotkeyactions.keyF12 ~= nil and string.len(ini.hotkeyactions.keyF12) > 1 then
               sampSendChat(tostring(ini.hotkeyactions.keyF12))
            end 	
         end
         
         if isTrainingSanbox and ini.settings.remapnum then
            -- PageUP <-- Num4 (and edit.mode == 4)
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
         
         -- Fix ped stuck
         if ini.settings.fixpedstuck then
            if not sampIsDialogActive() and not isPauseMenuActive() 
            and not isSampfuncsConsoleActive() then 
               for i = 0, sampGetMaxPlayerId(false) do
                  if sampIsPlayerConnected(i) then
                     local result, id = sampGetCharHandleBySampPlayerId(i)
                     if result and doesCharExist(id) then
                        local x, y, z = getCharCoordinates(id)
                        local mX, mY, mZ = getCharCoordinates(playerPed)
                        if 0.55 > getDistanceBetweenCoords3d(x, y, z, mX, mY, mZ) then
                           setCharCollision(id, false)
                        end
                     end
                  end
               end
            end
         end
         
         if isTrainingSanbox then
            -- Backspace reset texturelist to 0 page
            if edit.mode == 4 and dialoghook.textureslist then
               if isKeyJustPressed(0x08) and not sampIsChatInputActive() 
               and not sampIsDialogActive() and not isPauseMenuActive() 
               and not isSampfuncsConsoleActive() then 
                  if LastObject.localid and LastObject.txdslot then
                     sampSendChat("/texture "..tonumber(LastObject.localid).." "..tonumber(LastObject.txdslot).." 0")
                  end
               end
            end
         end
         
         if isTrainingSanbox and isCharInAnyCar(playerPed) then
            -- Fix exit from RC toys on F key
            if isKeyJustPressed(0x46) and not sampIsChatInputActive() 
            and not sampIsDialogActive() and not isPauseMenuActive() 
            and not isSampfuncsConsoleActive() and not LastData.lastMinigame then
               local carhandle = storeCarCharIsInNoSave(playerPed) 
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
            and not isSampfuncsConsoleActive() and not LastData.lastMinigame  then 
               sampSendChat("/tun")
            end
         end
         
         -- CTRL+O (Objects render activation)
         if isKeyDown(0x11) and isKeyJustPressed(0x4F)
         and not sampIsChatInputActive() and not isPauseMenuActive()
         and not isSampfuncsConsoleActive() then 
            checkbox.showobjectsmodel.v = not checkbox.showobjectsmodel.v
         end
         
         if isTrainingSanbox and dialoghook.previewdialog then
            -- Switching textdraws with arrow buttons, mouse buttons, pgup-pgdown keys
            if isKeyJustPressed(0x25) or isKeyJustPressed(0x05) 
            or isKeyJustPressed(0x21) and sampIsCursorActive() 
            and not sampIsChatInputActive() and not sampIsDialogActive() 
            and not isPauseMenuActive() and not isSampfuncsConsoleActive() then
               sampSendClickTextdraw(2095)
            end
            
            if isKeyJustPressed(0x27) or isKeyJustPressed(0x06) 
            or isKeyJustPressed(0x22) and sampIsCursorActive()
            and not sampIsChatInputActive() and not sampIsDialogActive()
            and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
               sampSendClickTextdraw(2094)
            end
         end
         
         if isTrainingSanbox then
            -- M key menu /vw and /world 
            if isKeyJustPressed(0x4D) and not sampIsChatInputActive() and not sampIsDialogActive()
            and not isPauseMenuActive() and not isSampfuncsConsoleActive() then 
               if playerdata.isWorldHoster then 
                  sampSendChat("/vw")
               else 
                  sampSendChat("/world")
               end   
            end
         end
      end
      
      -- Objects render
      if checkbox.showobjectsmodel.v or checkbox.showobjectsname.v then
         if not isPauseMenuActive() then
            for _, v in pairs(getAllObjects()) do
               if isObjectOnScreen(v) then
                  local _, x, y, z = getObjectCoordinates(v)
                  local px, py, pz = getCharCoordinates(playerPed)
                  local distance = getDistanceBetweenCoords3d(px, py, pz, x, y, z)
                  if distance <= tonumber(input.rendmaxdist.v)
                  and distance >= 2 then -- 2 to ignore attaches
                     local x1, y1 = convert3DCoordsToScreen(x,y,z)
                     if checkbox.showobjectsmodel.v then
                        renderFontDrawText(fonts.objectsrenderfont, 
                        (checkbox.showobjectsname.v
                        and "{"..ini.settings.rendercolor.."}".. getObjectModel(v) .. "\n".. tostring(sampObjectModelNames[getObjectModel(v)])
                        or "{"..ini.settings.rendercolor.."}".. getObjectModel(v)), x1, y1, -1)
                     end
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
               local px, py, pz = getCharCoordinates(playerPed)
               local x1, y1 = convert3DCoordsToScreen(x,y,z)
               local x10, y10 = convert3DCoordsToScreen(px,py,pz)
               local distance = string.format("%.0f", getDistanceBetweenCoords3d(x, y, z, px, py, pz))

               if tonumber(distance) <= tonumber(input.rendmaxdist.v)
               and model == input.rendselectedmodelid.v then
                  renderFontDrawText(fonts.objectsrenderfont, 
                  "{CCFFFFFF}distace:{CCFF6600} "..distance, x1, y1, -1)
                  renderDrawLine(x10, y10, x1, y1, 1.0, '0xCCFFFFFF')
               end
            end
         end
      end 
      
      -- Collision
      if playerdata.disableObjectCollision then
         local find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(playerPed)
         local result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
         if result then
            setObjectCollision(objectHandle, false)
            table.insert(objectsCollisionDel, objectHandle, objectHandle)            
            --setObjectCollisionDamageEffect(objectHandle, false)
         end
      end
      
      if checkbox.changefov.v then
         if slider.fov.v >= 1 and slider.fov.v <= 179 then 
            cameraSetLerpFov(slider.fov.v, slider.fov.v, 1000, true)
         else
            slider.fov.v = 70
         end
      end
      
      if ini.settings.nointeriorradar then
         if getActiveInterior() ~= 0 then
            displayRadar(false)
         end
      end
   
      -- Show TD index
      if checkbox.showtextdrawsid.v then
         for id = 1, 2048 do
            if sampTextdrawIsExists(id) then
               local x, y = sampTextdrawGetPos(id)
               local xw, yw = convertGameScreenCoordsToWindowScreenCoords(x, y)
               renderFontDrawText(fonts.objectsrenderfont, 'ID: ' .. id, xw, yw, -1)
            end
         end
      end
      
      if checkbox.fixcampos.v then
         setFixedCameraPosition(fixcam.x, fixcam.y, fixcam.z, 0.0, 0.0, 0.0)
         pointCameraAtPoint(fixcam.x, fixcam.y, fixcam.z, 2) 
      end
      
      if checkbox.lockcambehind.v then
         setCameraBehindPlayer()
      end
      
      if checkbox.lockcamfront.v then
         setCameraInFrontOfPlayer()
      end
      
      if checkbox.drunkcam.v then
         local bs = raknetNewBitStream()
         raknetBitStreamWriteInt32(bs, 5000)
         raknetEmulRpcReceiveBitStream(35, bs)
         raknetDeleteBitStream(bs)
      end
      
      if checkbox.freezechat.v then
         local visible = sampIsChatInputActive()
         if playerdata.isChatFreezed ~= visible then
            playerdata.isChatFreezed = visible
            if not playerdata.isChatFreezed then
               for k, v in ipairs(chatbuffer) do
                  local color = string.format('%X', v.color)
                  sampAddChatMessage(v.text, tonumber('0x' .. string.sub(color, #color - 8, #color - 2)))
               end
            chatbuffer = {}
            end
         end
      end
      
      if checkbox.streammemmax.v and ini.settings.streammemmax >= 100 then
         local streamedmem = memory.read(0x8E4CB4, 4, true)
         if streamedmem > ini.settings.streammemmax * 1000000 then
            cleanStreamMemory()
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Low memory detected. Streaming memory cleaned", 0x0FF6600)
         end
      end
      
      if playerdata.flymode then
         local x, y = getScreenResolution()
         if not isCharInAnyCar(playerPed) then 
            speed = getFullSpeed(ini.settings.flymodespeed, 0, 0) 
            setCharHeading(playerPed, getHeadingFromVector2d(
            select(1, getActiveCameraPointAt()) - select(1, getActiveCameraCoordinates()),
            select(2, getActiveCameraPointAt()) - select(2, getActiveCameraCoordinates()))) 
         end
         
         if sampIsChatInputActive() or sampIsDialogActive() then 
            goto holdposition 
         end
         
         if not isPauseMenuActive() and not sampIsCursorActive() then
            if isKeyDown(1) then -- LMB
               if playerdata.flypower < ini.settings.flymodemaxspeed then 
                  if playerdata.flypower <= 0.5 then
                     playerdata.flypower = playerdata.flypower + 0.01
                  else
                     playerdata.flypower = playerdata.flypower + 0.05
                  end
               end
               renderFontDrawText(fonts.infobarfont, 
               string.format("flyspeed:{26b85d} %.2f", playerdata.flypower), x-200, y-60, 0xFFFFFFFF)
            elseif isKeyDown(0x04) then -- MMB (Middle mouse button)
               if playerdata.flypower < ini.settings.flymodemaxspeed then 
                  playerdata.flypower = playerdata.flypower + 0.5
               else
                  playerdata.flypower = ini.settings.flymodemaxspeed
               end
               renderFontDrawText(fonts.infobarfont, 
               string.format("flyspeed:{ff8c00} %.2f", playerdata.flypower),x-200, y-60, 0xFFFFFFFF)
            elseif isKeyDown(2) then -- RMB
               if playerdata.flypower <= 0.5 then
                  playerdata.flypower = playerdata.flypower - 0.01
               else
                  playerdata.flypower = playerdata.flypower - 0.05
               end
               if playerdata.flypower < 0.05 then
                  playerdata.flypower = 0.05
               end
               renderFontDrawText(fonts.infobarfont, 
               string.format("flyspeed:{a52a2a} %.2f", playerdata.flypower),x-200, y-60, 0xFFFFFFFF)
            end
         end
         
         if isKeyDown(0x46) or isKeyDown(0x0D) then -- F/ENTER
            toggleFlyMode(false)
         end
         
         if isKeyDown(0x20) or isKeyDown(0x06) then -- Space or Mouse dop key X2
            flyCoords[3] = flyCoords[3] + speed * playerdata.flypower / 2
         elseif isKeyDown(0x11) or isKeyDown(0x05) -- CTRL or Mouse dop key X1
         and flyCoords[3] > -95.0 then 
            flyCoords[3] = flyCoords[3] - speed * playerdata.flypower / 2
         end
         
         if isKeyDown(0x57) then -- W key
            flyCoords[1] = flyCoords[1] + speed * playerdata.flypower * math.sin(-math.rad(getCharHeading(playerPed)))
            flyCoords[2] = flyCoords[2] + speed * playerdata.flypower * math.cos(-math.rad(getCharHeading(playerPed))) 
         elseif isKeyDown(0x53) then -- S key
            flyCoords[1] = flyCoords[1] - speed * playerdata.flypower * math.sin(-math.rad(getCharHeading(playerPed))) 
            flyCoords[2] = flyCoords[2] - speed * playerdata.flypower * math.cos(-math.rad(getCharHeading(playerPed)))
         end
         
         if isKeyDown(0x41) then -- A key
            flyCoords[1] = flyCoords[1] - speed * playerdata.flypower * math.sin(-math.rad(getCharHeading(playerPed) - 90))
            flyCoords[2] = flyCoords[2] - speed * playerdata.flypower * math.cos(-math.rad(getCharHeading(playerPed) - 90)) 
         elseif isKeyDown(0x44) then -- D key
            flyCoords[1] = flyCoords[1] + speed * playerdata.flypower * math.sin(-math.rad(getCharHeading(playerPed) - 90))
            flyCoords[2] = flyCoords[2] + speed * playerdata.flypower * math.cos(-math.rad(getCharHeading(playerPed) - 90)) 
         end
         
         if not isPauseMenuActive() then
            if isKeyDown(0x43) then -- C key
               playerdata.flypower = ini.settings.flymodespeed
               renderFontDrawText(fonts.infobarfont, 
               string.format("flyspeed:{a52a2a} %.2f", playerdata.flypower),x-200, y-60, 0xFFFFFFFF)
            end
         end
         ::holdposition::
         setCharCoordinates(playerPed, flyCoords[1], flyCoords[2], flyCoords[3])
         
      end
      
      -- Render stats bar
      if ini.settings.showidonhud and not isPauseMenuActive() 
      and not isKeyDown(0x79) and not playerdata.firstSpawn then -- 0x79 is F10 key
         local x, y = getScreenResolution()
         local id = getLocalPlayerId()
         renderFontDrawText(fonts.backgroundfont, "ID: "..id , x-300, 20, 0xFFFFFFFF)
      end 
      
      -- Render bottom bar
      --if not sampGetCurrentServerName() == "SA-MP" 
      if checkbox.showpanel.v and not isPauseMenuActive() 
      and not isKeyDown(0x79) then -- 0x79 is F10 key
         local x, y = getScreenResolution()
         if ini.panel.background then
            renderDrawBoxWithBorder(-2, y-15, x+2, y, 0xBF000000, 2, 0xFF000000)
         end
         
         local px, py, pz = getCharCoordinates(playerPed)
         local rendertext = string.format("%s | {3f70d6}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f{FFFFFF}", servername, px, py, pz)
         
         if ini.panel.showcursorpos then
            if sampIsCursorActive() then
               local cursorPosX, cursorPosY = getCursorPos()
               rendertext = rendertext.." | {3f70d6}X: "..cursorPosX.." {e0364e}Y: "..cursorPosY.."{FFFFFF}"
            end
         end
         
         if ini.panel.showmode then
            if not LastData.lastMinigame then 
               rendertext = rendertext.." | {FFD700}mode: "..editmodes[edit.mode+1].."{FFFFFF}"
            else
               rendertext = rendertext.." | {FFD700}minigame: "..tostring(trainingGamemodes[LastData.lastMinigame]).."{FFFFFF}"
            end
         end
         
         if ini.panel.showfps then
            rendertext = rendertext.." | FPS: "..playerdata.fps..""
         end
         
         if ini.panel.showstreameddynobjects then
            local streamedobjects = getStreamedObjects(ini.panel.showstreamedallobjects)
            if streamedobjects < 200 then
               rendertext = rendertext.." | objects: "..streamedobjects..""
            elseif streamedobjects > 200 and streamedobjects < 350 then
               rendertext = rendertext.." | objects: {FFA500}"..streamedobjects.."{FFFFFF}"
            else
               rendertext = rendertext.." | objects: {A00000}"..streamedobjects.."{FFFFFF}"
            end
         end
         
         if ini.panel.showstreamedvehs then
            streamedVehicles = getVehicleInStream()
            if streamedVehicles < 10 then
               rendertext = rendertext.." | vehicles: "..streamedVehicles..""
            elseif streamedVehicles > 15 and streamedVehicles < 25 then
               rendertext = rendertext.." | vehicles: {FFA500}"..streamedVehicles.."{FFFFFF}"
            else
               rendertext = rendertext.." | vehicles: {A00000}"..streamedVehicles.."{FFFFFF}"
            end
         end
         
         if ini.panel.showstreamedplayers then 
            local streamedPlayers = sampGetPlayerCount(true)
            if streamedPlayers < 10 then
               rendertext = rendertext.." | players: "..streamedPlayers..""
            elseif streamedPlayers > 10 and streamedPlayers < 25 then
               rendertext = rendertext.." | players: {FFA500}"..streamedPlayers.."{FFFFFF}"
            else
               rendertext = rendertext.." | players: {A00000}"..streamedPlayers.."{FFFFFF}"
            end
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
         renderFontDrawText(fonts.backgroundfont, rendertext, 15, y-15, 0xFFFFFFFF)
      end
      
      if ini.settings.showobjectcoord and edit.response == 2 
      and not isPauseMenuActive() then
         local x, y = getScreenResolution()
         local offset = {x = 0.0, y = 0.0, z = 0.0}
         renderFontDrawText(fonts.infobarfont, string.format("position {3f70d6}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f{FFFFFF}", 
         LastObject.position.x, LastObject.position.y, LastObject.position.z),
         x-400, y-80, 0xFFFFFFFF)
         renderFontDrawText(fonts.infobarfont, string.format("rotation {3f70d6}rx: %.2f, {e0364e}ry: %.2f, {26b85d}rz: %.2f{FFFFFF}", 
         LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z),
         x-400, y-60, 0xFFFFFFFF)
         if LastObject.position.x and LastObject.startpos.x then
            offset.x = LastObject.position.x-LastObject.startpos.x
            offset.y = LastObject.position.y-LastObject.startpos.y
            offset.z = LastObject.position.z-LastObject.startpos.z
            renderFontDrawText(fonts.infobarfont, string.format("offset {3f70d6}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f{FFFFFF}", 
            offset.x, offset.y, offset.z),
            x-400, y-40, 0xFFFFFFFF)
         end
         if ini.settings.bigoffsetwarning then
            if math.abs(offset.x) ~= math.abs(LastObject.position.x) then
               local maxOffsetDistance = 220.0
               if math.abs(offset.x) > maxOffsetDistance - 25 then
                  printStyledString('~y~ WARNING ~w~to much offset ~n~distance: ~y~'..math.abs(math.floor(offset.x)), 2000, 4)
               elseif math.abs(offset.y) > maxOffsetDistance - 25 then
                  printStyledString('~y~ WARNING ~w~to much offset ~n~distance: ~y~'..math.abs(math.floor(offset.y)), 2000, 4)
               elseif math.abs(offset.z) > maxOffsetDistance - 25 then
                  printStyledString('~y~ WARNING ~w~to much offset ~n~distance: ~y~'..math.abs(math.floor(offset.z)), 2000, 4)
               end
               
               if math.abs(offset.x) > maxOffsetDistance then
                  printStyledString('~r~ WARNING ~w~to much offset ~n~distance: ~r~'..math.abs(math.floor(offset.x)), 2000, 4)
               elseif math.abs(offset.y) > maxOffsetDistance then 
                  printStyledString('~r~ WARNING ~w~to much offset ~n~distance: ~r~'..math.abs(math.floor(offset.y)), 2000, 4)
               elseif math.abs(offset.z) > maxOffsetDistance then 
                  printStyledString('~r~ WARNING ~w~to much offset ~n~distance: ~r~'..math.abs(math.floor(offset.z)), 2000, 4)
               end
            end
         end
      end
      -- END main
   end
end

lua_thread.create(function()
   while true do
      wait(1000)
      playerdata.fps = playerdata.fps_counter
      playerdata.fps_counter = 0
   end
end)

function onD3DPresent()
   playerdata.fps_counter = playerdata.fps_counter + 1
end

function imgui.BeforeDrawFrame()
   if fonts.defaultfont == nil then
      fonts.defaultfont = imgui.GetIO().Fonts:AddFontFromFileTTF(
      getFolderPath(0x14) .. '\\'..ini.settings.imguifont..'.ttf',
      ini.settings.imguifontsize, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
   end
   if fonts.multilinetextfont == nil then
      fonts.multilinetextfont = imgui.GetIO().Fonts:AddFontFromFileTTF(
      getFolderPath(0x14) .. '\\'..ini.settings.multilinefont..'.ttf',
      ini.settings.multilinefontsize, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
   end
end

function imgui.OnDrawFrame()
   imgui.PushFont(fonts.defaultfont)
   if dialog.main.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.SetNextWindowSize(imgui.ImVec2(640, 500))
      imgui.Begin((".::  Mapping Toolkit v%s ::."):format(thisScript().version), dialog.main, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
      
      if tabmenu.main == 1 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Основное", imgui.ImVec2(125, 30)) then tabmenu.main = 1 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Основное", imgui.ImVec2(125, 30)) then tabmenu.main = 1 end
      end
      
      imgui.SameLine()
      if tabmenu.main == 3 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Информация", imgui.ImVec2(125, 30)) then tabmenu.main = 3 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Информация", imgui.ImVec2(125, 30)) then tabmenu.main = 3 end
      end
      
      imgui.SameLine()
      if tabmenu.main == 2 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Зона стрима", imgui.ImVec2(125, 30)) then tabmenu.main = 2 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Зона стрима", imgui.ImVec2(125, 30)) then tabmenu.main = 2 end
      end
      
      imgui.SameLine()
      imgui.Text("                               ")
      imgui.SameLine()

      if imgui.TooltipButton(u8" _ ", imgui.ImVec2(30, 25), u8"Свернуть окно тулкита") then
         dialog.main.v = not dialog.main.v
      end
      imgui.SameLine()
      if imgui.TooltipButton(u8" ? ", imgui.ImVec2(30, 25), u8"Информация о тулките") then
         tabmenu.main = 3
         tabmenu.info = 1
      end
      imgui.SameLine()
      if dialog.toolkitmanage.v then
         if imgui.TooltipButton(u8" < ", imgui.ImVec2(30, 25), u8"Управление") then
            dialog.toolkitmanage.v = false
         end
      else
         if imgui.TooltipButton(u8" > ", imgui.ImVec2(30, 25), u8"Управление") then
            dialog.toolkitmanage.v = true
         end
      end

      imgui.Spacing()
      
      if tabmenu.main == 1 then

         imgui.Columns(2)
         imgui.SetColumnWidth(-1, 510)

         if tabmenu.settings == 1 then
            
            local positionX, positionY, positionZ = getCharCoordinates(playerPed)
            local id = getLocalPlayerId()
            local score
            if sampGetPlayerScore(id) then
               score = sampGetPlayerScore(id)
            end
         
            imgui.TextColoredRGB(string.format("Ваша позиция на карте {007DFF}x: %.1f, {e0364e}y: %.1f, {26b85d}z: %.1f",
            positionX, positionY, positionZ))
            if imgui.IsItemClicked() then
               setClipboardText(string.format(u8"%.1f, %.1f, %.1f", positionX, positionY, positionZ))
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Позиция скопирована в буффер обмена", 0x0FF6600)
            end
            
            zone = getZoneName(positionX, positionY, positionZ)
            if zone then 
               imgui.TextColoredRGB(string.format("Вы находитесь в районе: {FF6600}%s", zone))
               if string.len(LastData.lastWorldName) > 1 then
                  imgui.TextColoredRGB("Мир: "..LastData.lastWorldName)
               end
               if LastData.lastWorldNumber > 0 then
                  imgui.Text(string.format(u8"Последний мир (номер): %s", LastData.lastWorldNumber))
                  if imgui.IsItemClicked() then
                     sampAddChatMessage("Выбран мир "..LastData.lastWorldNumber, -1)
                     sampSendChat("/мир "..LastData.lastWorldNumber)
                  end
               end
            else
               if string.len(LastData.lastWorldName) > 1 then
                  imgui.TextColoredRGB("Мир: "..LastData.lastWorldName)
               end
               if LastData.lastWorldNumber > 0 then               
                  imgui.Text(string.format(u8"Последний мир (номер): %s", LastData.lastWorldNumber))
                  if imgui.IsItemClicked() then
                     sampAddChatMessage("Выбран мир "..LastData.lastWorldNumber, -1)
                     sampSendChat("/мир "..LastData.lastWorldNumber)
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
            
            if tabmenu.coords == 1 then
               imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
               if imgui.Button(u8"Позиция", imgui.ImVec2(100, 30)) then tabmenu.coords = 1 end
               imgui.PopStyleColor()
            else
               if imgui.Button(u8"Позиция", imgui.ImVec2(100, 30)) then tabmenu.coords = 1 end
            end
            
            imgui.SameLine()
            if tabmenu.coords == 2 then
               imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
               if imgui.Button(u8"Телепорт", imgui.ImVec2(100, 30)) then 
                  tabmenu.coords = 2 
               end
               imgui.PopStyleColor()
            else
               if imgui.Button(u8"Телепорт", imgui.ImVec2(100, 30)) then 
                  -- tpcpos.x = positionX
                  -- tpcpos.y = positionY
                  -- tpcpos.z = positionZ
                  -- textbuffer.tpcx.v = string.format("%.1f", tpcpos.x)
                  -- textbuffer.tpcy.v = string.format("%.1f", tpcpos.y)
                  -- textbuffer.tpcz.v = string.format("%.1f", tpcpos.z)
                  tabmenu.coords = 2
               end
            end
            
            imgui.Spacing()
            
            if tabmenu.coords == 1 then
               if tpcpos.x then
                  if tpcpos.x ~= 0 then
                     imgui.TextColoredRGB(string.format("Отмеченная позиция {696969}x: %.1f, y: %.1f, z: %.1f",
                     tpcpos.x, tpcpos.y, tpcpos.z))
                     if imgui.IsItemClicked() then
                        setClipboardText(string.format(u8"%.1f, %.1f, %.1f", tpcpos.x, tpcpos.y, tpcpos.z))
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Позиция скопирована в буффер обмена", 0x0FF6600)
                     end
                     
                     imgui.SameLine()
                     imgui.TextColoredRGB(string.format("Дистанция {696969}%.1f m.",
                     getDistanceBetweenCoords3d(positionX, positionY, positionZ, tpcpos.x, tpcpos.y, tpcpos.z)))
                  else
                     imgui.TextColoredRGB("Отмеченная позиция: {696969}не задана")
                  end
               end
               
               imgui.Spacing()
               
               if imgui.TooltipButton(u8"Получить", imgui.ImVec2(130, 25), u8"Получить текущую позицию игрока и сохранить") then
                  tpcpos.x = positionX
                  tpcpos.y = positionY
                  tpcpos.z = positionZ
                  textbuffer.tpcx.v = string.format("%.2f", tpcpos.x)
                  textbuffer.tpcy.v = string.format("%.2f", tpcpos.y)
                  textbuffer.tpcz.v = string.format("%.2f", tpcpos.z)
                  tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(playerPed)
                  setClipboardText(string.format("%.1f %.1f %.1f", tpcpos.x, tpcpos.y, tpcpos.z))
                  sampAddChatMessage("Координаты скопированы в буффер обмена", -1)
                  local posA = getCharHeading(playerPed)
                  sampAddChatMessage(string.format("Ваши координаты: {696969}%.2f %.2f %.2f {FFFFFF}Угол поворота: {696969}%.2f", tpcpos.x, tpcpos.y, tpcpos.z, posA), -1)
                  if isTrainingSanbox and playerdata.isWorldHoster then
                     sampAddChatMessage(string.format("Используйте: /xyz {696969}%.2f %.2f %.2f", tpcpos.x, tpcpos.y, tpcpos.z), -1)
                  end
               end
               imgui.SameLine()
               if imgui.Button(u8"Прыгнуть вперед", imgui.ImVec2(130, 25)) then
                  if sampIsLocalPlayerSpawned() then
                     JumpForward()
                  end
               end
               imgui.SameLine()
               if imgui.Button(u8"Прыгнуть вверх", imgui.ImVec2(130, 25)) then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(playerPed)
                     setCharCoordinates(playerPed, posX, posY, posZ+10.0)
                  end
               end
               
               if imgui.Button(u8"Провалиться под текстуры", imgui.ImVec2(200, 25)) then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(playerPed)
                     setCharCoordinates(playerPed, posX, posY, posZ-3.0)
                  end
               end
               imgui.SameLine()
               if imgui.Button(u8"Вернуться на поверхность", imgui.ImVec2(200, 25)) then
                  local result, x, y, z = getNearestRoadCoordinates()
                  if result then
                     local dist = getDistanceBetweenCoords3d(x, y, z, getCharCoordinates(playerPed))
                     if not isTrainingSanbox then
                        if dist < 10.0 then 
                           setCharCoordinates(playerPed, x, y, z + 3.0)
                           sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы телепортированы на ближайшую поверхность", 0x0FF6600)
                        else
                           sampAddChatMessage(("Ближайшая поверхность слишком далеко (%d m.)"):format(dist), 0x0FF0000)
                           local posX, posY, posZ = getCharCoordinates(playerPed)
                           setCharCoordinates(playerPed, posX, posY, posZ+3.0)
                        end
                     else
                        setCharCoordinates(playerPed, x, y, z + 3.0)
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы телепортированы на ближайшую поверхность", 0x0FF6600)
                     end
                  else
                     sampAddChatMessage("Не нашлось ни одной поверхности рядом", 0x0FF0000)
                     local posX, posY, posZ = getCharCoordinates(playerPed)
                     setCharCoordinates(playerPed, posX, posY, posZ+3.0)
                  end
               end
               
               imgui.Spacing()
               imgui.Spacing()
               -- local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//favorites//coordinates.txt"
               
               -- if imgui.Button(u8"Добавить", imgui.ImVec2(100, 25)) then
                  -- local file = io.open(filepath, "a")
                  -- file:write(("%s, %.2f, %.2f, %.2f\n"):format("saved point", positionX,positionY,positionZ))
                  -- file:close()
                  -- --sampAddChatMessage("[SCRIPT]: {FFFFFF}Текстдрав был сохранен в /moonloader/resource/mappingtoolkit/export/export_txdtocb.txt", 0x0FF6600)
                  -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты были добавлены в список", 0x0FF6600)
               -- end
               -- imgui.SameLine()
               -- if imgui.Button(u8"Удалить", imgui.ImVec2(100, 25)) then
               -- end
               
               -- local file = io.open(filepath, "r")
               -- for line in file:lines() do
                  -- if line:len() > 1 then
                     -- if imgui.Selectable(tostring(line)) then
                        -- -- for element in string.gmatch(line, "[^,]+") do
                        -- -- end
                     -- end
                  -- end
               -- end
               -- file:close()
               
                        
               if worldspawnpos.x then
                  if worldspawnpos.x ~= 0 then
                     imgui.TextColoredRGB(string.format("Позиция спавна в мире {007DFF}x: %.1f, {e0364e}y: %.1f, {26b85d}z: %.1f",
                     worldspawnpos.x, worldspawnpos.y, worldspawnpos.z))
                     if imgui.IsItemClicked() then
                       setClipboardText(string.format(u8"%.1f, %.1f, %.1f", worldspawnpos.x, worldspawnpos.y, worldspawnpos.z))
                       sampAddChatMessage("[SCRIPT]: {FFFFFF}Позиция скопирована в буффер обмена", 0x0FF6600)
                     end
                  end
               end
               
               if imgui.TooltipButton(u8"Заспавниться", imgui.ImVec2(130, 25), u8"Отправить SpawnPlayer серверу") then
                  sampSpawnPlayer()
                  restoreCameraJumpcut()
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Респавн", imgui.ImVec2(130, 25), u8"Отправить SendSpawn серверу") then
                  sampSendSpawn()
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Запросить спавн", imgui.ImVec2(130, 25), u8"Отправить SendRequestSpawn серверу") then
                  sampSendRequestSpawn()
               end
               if isTrainingSanbox then
                  if imgui.TooltipButton(u8"Слапнуть себя", imgui.ImVec2(200, 25), u8"Подбросить себя /slapme") then
                     sampSendChat("/slapme")
                  end
                  imgui.SameLine()
                  if imgui.TooltipButton(u8"Заспавнить себя", imgui.ImVec2(200, 25), u8"Заспавнить себя /spawnme") then
                     sampSendChat("/spawnme")
                  end
               end
               if isTrainingSanbox then
                  if imgui.TooltipButton(u8"Выбрать интерьер", imgui.ImVec2(200, 25), u8"Выбрать интерьер для мира /int") then
                     sampSendChat("/int")
                     dialog.main.v = false
                  end
                  imgui.SameLine()
                  if imgui.TooltipButton(u8"Выбрать спавн", imgui.ImVec2(200, 25), u8"Выбрать спавн для мира /team") then
                     sampSendChat("/team")
                     dialog.main.v = false
                  end
               end
               
               imgui.Spacing()
            
               if imgui.Checkbox(u8"Игнорировать границы мира", checkbox.noworldbounds) then
                  if checkbox.noworldbounds.v then
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Границы мира обнулены (setWorldBounds)", 0x0FF6600)
                  end
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Отключает установленные сервером ограничения границ мира (setWorldBounds)")
               
               if imgui.Checkbox(u8"Игнорировать изменение позиции", nops.position) then
                  if nops.position.v then
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Изменение вашей позиции сервером будет игнорироваться. {CC0000}Это может триггерить античит!", 0x0FF6600)
                  end
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Отключает изменение сервером позиции игрока (setPlayerPos) Это может триггерить античит!")
               
               if imgui.Checkbox(u8"Игнорировать изменение гравитации", checkbox.nogravity) then
                  if checkbox.nogravity.v then
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Изменение гравитации сервером будет игнорироваться", 0x0FF6600)
                  end
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Отключает установленные сервером значения гравитации (setGravity)")
               
               -- if imgui.TooltipButton(u8"ForceSync", imgui.ImVec2(200, 25), u8"Отправить ForceSync серверу") then
                  -- sampForceAimSync()
                  -- sampForceOnfootSync()
                  -- sampForceStatsSync()
                  -- sampForceWeaponsSync()
               -- end
               
            elseif tabmenu.coords == 2 then
               
               if string.len(textbuffer.tpcx.v) < 1 then
                  tpcpos.x = positionX
                  tpcpos.y = positionY
                  tpcpos.z = positionZ
                  textbuffer.tpcx.v = string.format("%.1f", tpcpos.x)
                  textbuffer.tpcy.v = string.format("%.1f", tpcpos.y)
                  textbuffer.tpcz.v = string.format("%.1f", tpcpos.z)               
               end
               local bTargetResult, bX, bY, bZ = getTargetBlipCoordinates()
               if bTargetResult then
                  imgui.TextColoredRGB(string.format("Позиция метки на карте {007DFF}x: %.1f, {e0364e}y: %.1f, {26b85d}z: %.1f",
                  bX, bY, bZ))
                  if imgui.IsItemClicked() then
                     setClipboardText(string.format(u8"%.1f, %.1f, %.1f", bX, bY, bZ))
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Позиция скопирована в буффер обмена", 0x0FF6600)
                  end
               
                  imgui.SameLine()
                  imgui.TextColoredRGB(string.format("Дистанция {696969}%.1f m.",
                  getDistanceBetweenCoords3d(positionX, positionY, positionZ, bX, bY, bZ)))
               end 
               
               imgui.Text(u8"Телепорт по координатам:")
               if imgui.TooltipButton(u8"Обновить", imgui.ImVec2(70, 25), u8"Обновит значения на вашу текущую позицию") then
                  tpcpos.x = positionX
                  tpcpos.y = positionY
                  tpcpos.z = positionZ
                  textbuffer.tpcx.v = string.format("%.1f", tpcpos.x)
                  textbuffer.tpcy.v = string.format("%.1f", tpcpos.y)
                  textbuffer.tpcz.v = string.format("%.1f", tpcpos.z)
               end
               imgui.SameLine()
               imgui.TextColoredRGB("{007DFF}x:")
               imgui.SameLine()
               imgui.PushItemWidth(70)
               if imgui.InputText("##TpcxBuffer", textbuffer.tpcx, imgui.InputTextFlags.CharsDecimal) then
                  tpcpos.x = tonumber(textbuffer.tpcx.v)
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.TextColoredRGB("{e0364e}y:")
               imgui.SameLine()
               imgui.PushItemWidth(70)
               if imgui.InputText("##TpcyBuffer", textbuffer.tpcy, imgui.InputTextFlags.CharsDecimal) then
                  tpcpos.y = tonumber(textbuffer.tpcy.v)
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.TextColoredRGB("{26b85d}z:")
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
               
               if imgui.Button(u8"По координатам (системно)", imgui.ImVec2(200, 25)) then
                  freezeCharPosition(playerPed, false)
                  if textbuffer.tpcx.v then
                     if isTrainingSanbox then
                        sampSendChat(string.format("/xyz %f %f %f", textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), -1)
                        sampAddChatMessage(string.format("[SCRIPT]: {FFFFFF}Телепорт на координаты: %.1f %.1f %.1f",
                        textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), 0x0FF6600)
                     else 
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно для вашего сервера", 0x0FF6600)
                     end
                  else
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты не были сохранены", 0x0FF6600)
                  end  
               end
               imgui.SameLine()
               if imgui.Button(u8"По метке (системно)", imgui.ImVec2(200, 25)) then
                  local bTargetResult, bX, bY, bZ = getTargetBlipCoordinates()
                  if bTargetResult then
                     textbuffer.tpcx.v = string.format("%.1f", bX)
                     textbuffer.tpcy.v = string.format("%.1f", bY)
                     textbuffer.tpcz.v = string.format("%.1f", bZ+2.0)
                     freezeCharPosition(playerPed, false)
                  
                     if textbuffer.tpcx.v then
                        if isTrainingSanbox then
                           sampSendChat(string.format("/xyz %f %f %f", textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), -1)
                           sampAddChatMessage(string.format("[SCRIPT]: {FFFFFF}Телепорт на метку: %.1f %.1f %.1f",
                           textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), 0x0FF6600)
                        else 
                           sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно для вашего сервера", 0x0FF6600)
                        end
                     else
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты не были сохранены", 0x0FF6600)
                     end  
                  else
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Метка на карте не обнаружена. Координаты не были изменены.", 0x0FF6600)
                  end
               end
               
               if imgui.Button(u8"По координатам (hack)", imgui.ImVec2(200, 25)) then
                  freezeCharPosition(playerPed, false)
                  if textbuffer.tpcx.v then
                     setCharCoordinates(playerPed, textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v)
                     sampAddChatMessage(string.format("[SCRIPT]: {FFFFFF}Телепорт на координаты: %.1f %.1f %.1f",
                     textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), 0x0FF6600)
                  else
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты не были сохранены", 0x0FF6600)
                  end  
               end
               imgui.SameLine()
               if imgui.Button(u8"По метке (hack)", imgui.ImVec2(200, 25)) then
                  local bTargetResult, bX, bY, bZ = getTargetBlipCoordinates()
                  if bTargetResult then
                     textbuffer.tpcx.v = string.format("%.1f", bX)
                     textbuffer.tpcy.v = string.format("%.1f", bY)
                     textbuffer.tpcz.v = string.format("%.1f", bZ+2.0)
                     
                     freezeCharPosition(playerPed, false)
                  
                     if textbuffer.tpcx.v then
                        if isTrainingSanbox then
                           setCharCoordinates(playerPed, textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v)
                           sampAddChatMessage(string.format("[SCRIPT]: {FFFFFF}Телепорт на метку: %.1f %.1f %.1f",
                           textbuffer.tpcx.v, textbuffer.tpcy.v, textbuffer.tpcz.v), 0x0FF6600)
                        else 
                           sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно для вашего сервера", 0x0FF6600)
                        end
                     else
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты не были сохранены", 0x0FF6600)
                     end                    
                  else
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Метка на карте не обнаружена. Координаты не были изменены.", 0x0FF6600)
                  end 
               end
               
               imgui.Spacing()
               imgui.Text(u8"Пошаговый телепорт:")
               
               imgui.Spacing()
               imgui.Text("       ")
               imgui.SameLine()
               if imgui.Button(" ^ ") then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(playerPed)
                     setCharCoordinates(playerPed, posX, posY, posZ+input.tpstep.v)
                  end
               end
               imgui.SameLine()
               imgui.Text("          ")
               imgui.SameLine()
               
               imgui.Text(u8"Шаг: ")
               imgui.SameLine()
               imgui.PushItemWidth(85)
               if imgui.InputInt(u8'##INPUT_tpstep', input.tpstep, 1, 10) then
                  if input.tpstep.v < 1 then
                     input.tpstep.v = 1
                  end                  
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.Text("m.")
               
               if imgui.Button(" < ") then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(playerPed)
                     setCharCoordinates(playerPed, posX+input.tpstep.v, posY, posZ)
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
                     local posX, posY, posZ = getCharCoordinates(playerPed)
                     setCharCoordinates(playerPed, posX, posY+input.tpstep.v, posZ)
                  end
               end
               imgui.SameLine()
               imgui.Text("  ")
               imgui.SameLine()
               if imgui.Checkbox(checkbox.freezepos.v and u8"Позиция: Заморожена" or u8"Позиция: Разморожена", checkbox.freezepos) then
                  if checkbox.freezepos.v and sampIsLocalPlayerSpawned() then
                     freezeCharPosition(playerPed, true)
                  else
                     freezeCharPosition(playerPed, false)
                     setPlayerControl(PLAYER_HANDLE, true)
                     clearCharTasksImmediately(playerPed)
                  end
               end
               imgui.Text("       ")
               imgui.SameLine()
               if imgui.Button(" v ") then
                  if sampIsLocalPlayerSpawned() then
                     local posX, posY, posZ = getCharCoordinates(playerPed)
                     setCharCoordinates(playerPed, posX, posY, posZ-input.tpstep.v)
                  end
               end
          end
        
      elseif tabmenu.settings == 2 then
         
         --imgui.TextColoredRGB("{696969}EditMode: "..editmodes[edit.mode+1])
         
         if LastObject.handle and doesObjectExist(LastObject.handle) then
            if dialog.objectinfo.v then 
               if imgui.TooltipButton("(>>)", imgui.ImVec2(35, 25), u8"Скрыть дополнительные параметры объекта") then
                  dialog.objectinfo.v = not dialog.objectinfo.v
               end
            else
               if imgui.TooltipButton("(<<)", imgui.ImVec2(35, 25), u8"Показать дополнительные параметры объекта") then
                  dialog.objectinfo.v = not dialog.objectinfo.v
                  if LastObject.handle and doesObjectExist(LastObject.handle) then
                     chosen.object = LastObject.handle
                  end
               end
            end             
            imgui.SameLine()
         end   
         if LastObject.modelid then
            local modelName = tostring(sampObjectModelNames[LastObject.modelid])
            imgui.TextColoredRGB("Последний объект: {007DFF}"..LastObject.modelid.." ("..modelName..") ")
            if imgui.IsItemClicked() then
               setClipboardText(LastObject.modelid)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}modelid скопирован в буффер обмена", 0x0FF6600)
            end
         else
            if isTrainingSanbox then
               if imgui.TooltipButton(u8"/olist", imgui.ImVec2(65, 25), u8:encode("Список всех созданнных вами в мире объектов")) then
                  sampSendChat("/olist")
                  dialog.main.v = not dialog.main.v
               end
               imgui.SameLine()
            end
            imgui.Text(u8"Последний modelid объекта: не выбран")
            -- if isTrainingSanbox then
               -- if imgui.IsItemClicked() then
                  -- sampSendChat("/olist")
                  -- dialog.main.v = not dialog.main.v
               -- end
            -- end
         end
         
         if LastObject.handle and doesObjectExist(LastObject.handle) then
            
            local modelid = getObjectModel(LastObject.handle)
            local objectid = sampGetObjectSampIdByHandle(LastObject.handle)
      
            if isTrainingSanbox then
               if LastObject.localid then
                  imgui.SameLine()
                  imgui.TextColoredRGB("localid: {007DFF}"..LastObject.localid)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"O", imgui.ImVec2(25, 25), u8"Посмотреть подробную информацию по объекту на Prineside DevTools") then            
               local link = 'explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/search/?q='..modelid..'"'
               os.execute(link)
            end
            if isTrainingSanbox then
               imgui.SameLine()
               if imgui.TooltipButton(u8"/olist", imgui.ImVec2(65, 25), u8:encode("Список всех созданнных вами в мире объектов")) then
                  sampSendChat("/olist")
                  dialog.main.v = not dialog.main.v
               end
            end
            
            if LastObject.handle and isTrainingSanbox
            and LastObject.txdid ~= nil then
               local txdtable = sampTextureList[LastObject.txdid+1]
               local txdname = tostring(txdtable[3])
               imgui.TextColoredRGB("Последняя текстура: {007DFF}"..txdname.."("..LastObject.txdid..")")
               if imgui.IsItemClicked() then
                  textbuffer.objectid.v = txdname
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Textureid скопирован в буффер обмена!", 0x0FF6600)
               end
               if LastObject.txdslot then
                  imgui.SameLine()
                  imgui.TextColoredRGB(" {CDCDCD}слот:{007DFF} "..LastObject.txdslot)
               end
            end
            
            if LastObject.handle then
               if not LastObject.position.x ~= nil then
                  imgui.TextColoredRGB(string.format("{007DFF}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f",
                  LastObject.position.x, LastObject.position.y, LastObject.position.z))
                  if imgui.IsItemClicked() then
                     setClipboardText(string.format("%.2f, %.2f, %.2f", LastObject.position.x, LastObject.position.y, LastObject.position.z))
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты скопированы в буффер обмена!", 0x0FF6600)
                  end
                  imgui.SameLine()
                  imgui.TextQuestion(" [=] ", u8"Копировать координаты в буффер")
                  if imgui.IsItemClicked() then
                     setClipboardText(string.format("%.2f, %.2f, %.2f", LastObject.position.x, LastObject.position.y, LastObject.position.z))
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты скопированы в буффер обмена!", 0x0FF6600)
                  end
               end   
               if not LastObject.rotation.x ~= nil then
                  imgui.TextColoredRGB(string.format("{007DFF}rx: %.2f, {f0364e}ry: %.2f, {36b85d}rz: %.2f",
                  LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z))
               end
            else
               local result, x, y, z = getObjectCoordinates(LastObject.handle)
               if result then
                  imgui.TextColoredRGB(string.format("{007DFF}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f", x, y, z))
                  if imgui.IsItemClicked() then
                     setClipboardText(string.format("%.2f, %.2f, %.2f", x, y, z))
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты скопированы в буффер обмена!", 0x0FF6600)
                  end
               end
               imgui.SameLine()
               imgui.TextQuestion(" [=] ", u8"Копировать координаты в буффер")
               if imgui.IsItemClicked() then
                  setClipboardText(string.format("%.2f, %.2f, %.2f", x, y, z))
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Координаты скопированы в буффер обмена!", 0x0FF6600)
               end
            end
            
         end
         imgui.Spacing()
         local closestObjectId = getClosestObjectId()
         if closestObjectId then
            local model = getObjectModel(closestObjectId)
            local modelName = tostring(sampObjectModelNames[model])
            imgui.TextColoredRGB("{696969}Ближайший объект: "..model.." ("..modelName..") ")
            if imgui.IsItemClicked() then
               setClipboardText(model)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}modelid скопирован в буффер обмена", 0x0FF6600)
            end
            local result, distance, x, y, z = getNearestObjectByModel(model)
            if result then 
               imgui.TextColoredRGB(string.format('{696969}Объект находится на расстоянии %.2f метров от вас', distance))
            end  
         end
         
         if isTrainingSanbox then
            if LastObject.modelid then
               if imgui.TooltipButton(u8"Редактировать", imgui.ImVec2(95, 25), u8:encode("Редактировать текущий объект (/oe)")) then
                  sampSendChat("/oe")
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Копировать", imgui.ImVec2(95, 25), u8:encode("Копировать текущий объект (/clone)")) then
                  sampSendChat("/clone")
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Удалить", imgui.ImVec2(75, 25), u8:encode("Удалить текущий объект (/od)")) then
                  sampSendChat("/od")
               end
            end
            if LastObject.modelid and LastObject.localid then
               imgui.SameLine()
               imgui.Text("  ")
               imgui.SameLine()
               imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 1.0, 1.0))
               if imgui.TooltipButton(u8"RX 90", imgui.ImVec2(55, 25), u8:encode("Повернуть объект по оси Х на 90 градусов (/rx)")) then
                  sampSendChat("/rx "..LastObject.localid.." 90")
               end
               imgui.PopStyleColor()
               imgui.SameLine()
               imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
               if imgui.TooltipButton(u8"RY 90", imgui.ImVec2(55, 25), u8:encode("Повернуть объект по оси Y на 90 градусов (/ry)")) then
                  sampSendChat("/ry "..LastObject.localid.." 90")
               end
               imgui.PopStyleColor()
               imgui.SameLine()
               imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.0, 1.0))
               if imgui.TooltipButton(u8"RZ 90", imgui.ImVec2(55, 25), u8:encode("Повернуть объект по оси Z на 90 градусов (/rz)")) then
                  sampSendChat("/rz "..LastObject.localid.." 90")
               end
               imgui.PopStyleColor()
            end
            if LastObject.modelid then
               if imgui.TooltipButton(u8"/omenu", imgui.ImVec2(65, 25), u8:encode("Дополнительные опции редактирования объекта")) then
                  dialog.main.v = not dialog.main.v
                  sampSendChat("/omenu")
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"/oinfo", imgui.ImVec2(65, 25), u8:encode("Информация о объекте (серверная)")) then
                  dialog.main.v = not dialog.main.v
                  sampSendChat("/oinfo")
               end
               -- imgui.SameLine()
               -- if imgui.TooltipButton(u8"/sindex", imgui.ImVec2(65, 25), u8:encode("Показать индексы(слои) объекта")) then
                  -- sampSendChat("/sindex")
               -- end
               -- imgui.SameLine()
               -- if imgui.TooltipButton(u8"/untexture", imgui.ImVec2(70, 25), u8:encode("Очистить ретекрстур с объекта")) then
                  -- sampSendChat("/untexture")
               -- end
               imgui.SameLine()
               if imgui.TooltipButton(u8"/otext", imgui.ImVec2(65, 25), u8:encode("Наложить текст")) then
                  sampSendChat("/otext")
                  dialog.main.v = not dialog.main.v
               end
               if LastRemovedObject.modelid then
                  imgui.SameLine()
                  if imgui.TooltipButton(u8"/undo", imgui.ImVec2(65, 25), u8:encode("Восстановить удаленный объект")) then
                     sampSendChat("/undo")
                  end
               end
            end
         end
         
         imgui.Spacing()
         
         if imgui.CollapsingHeader(u8"Свойства") then
            
            imgui.Text(u8"Прорисовка:")
            if LastObject.localid then
               if imgui.TooltipButton(u8"/getstream", imgui.ImVec2(120, 25), u8:encode("Узнать дистанцию прорисовки текущего объекта")) then
                  sampSendChat("/getstream "..LastObject.localid)
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"/setstream", imgui.ImVec2(120, 25), u8:encode("Изменить дистанцию прорисовки текущего объекта")) then
                  if input.streamdist.v then
                     sampSendChat("/setstream "..LastObject.localid.." "..input.streamdist.v)
                  end
               end
               imgui.SameLine()
               imgui.PushItemWidth(145)
               imgui.InputFloat('##streamdist', input.streamdist, 0.01, 9999.0)
               imgui.PopItemWidth()
            end
            if imgui.Checkbox(u8("Изменить дальность прорисовки объекта по ID модели"), checkbox.changemdo) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Изменяет дальность прорисовки объекта (визуально)")
            
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
            
            imgui.Checkbox(u8("Изменить масштаб объекта"), checkbox.objectscale)
            if checkbox.objectscale.v then
               if LastObject.handle then
                  if imgui.SliderFloat(u8"##scaleobject", slider.scale, 0.0, 50.0) then
                     setObjectScale(LastObject.handle, slider.scale.v)
                  end
               else 
                  checkbox.objectscale.v = false
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден последний объект!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Визуально изменяет масштаб объекта, и растягивает его. (как в МТА)")
            
            imgui.Text(u8"Видимость:")
            if imgui.Checkbox(u8("Поставить метку на текущий объект"), checkbox.bliplastobject) then 
               if LastObject.handle and doesObjectExist(LastObject.handle) then
                  if LastObject.blip then
                     removeBlip(LastObject.blip)
                     LastObject.blip = nil
                  else
                     LastObject.blip = addBlipForObject(LastObject.handle)
                  end
               else
                  checkbox.bliplastobject.v = false
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден последний объект!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Визуально для вас устновит метку над объектом")
            
            if imgui.Checkbox(u8("Скрыть текущий объект"), checkbox.hidelastobject) then 
               if LastObject.handle and doesObjectExist(LastObject.handle) then
                  if LastObject.hidden then
                     setObjectVisible(LastObject.handle, false)
                     LastObject.hidden = false
                  else
                     setObjectVisible(LastObject.handle, true)
                     LastObject.hidden = true
                  end
               else
                  checkbox.hidelastobject.v = false
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден последний объект!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Визуально для вас скроет объект")
            
            if imgui.Checkbox(u8("Сделать прозрачным текущий объект"), checkbox.setobjalpha) then 
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
                  checkbox.setobjalpha.v = false
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден последний объект!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Сделает объект прозрачным (Визуально для вас)")
            
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
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект не был добавлен, так как вы ввели некорректный id!", 0x0FF6600)
                     else
                        table.insert(hiddenObjects, tonumber(input.hideobjectid.v))
                        sampAddChatMessage(string.format("Вы скрыли все объекты с modelid: %i",
                        tonumber(input.hideobjectid.v)), -1)
                     end
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Изменения будут видны после обновления зоны стрима!", 0x0FF6600)
                  else
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект не был добавлен, так как вы не ввели id!", 0x0FF6600)
                  end
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Введите modelid от 615-18300 [GTASA], 18632-19521 [SAMP]")
            end
            
            imgui.Text(u8"Коллизия:")
            if imgui.Checkbox(u8("Отключить коллизию у всех объектов"), checkbox.objectcollision) then 
               if checkbox.objectcollision.v then
                  playerdata.disableObjectCollision = true
               else
               playerdata.disableObjectCollision = false
               local find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(playerPed)
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
            imgui.TextQuestion("( ? )", u8"Отключает коллизию для всех объектов в области стрима")
            
            if imgui.Checkbox(u8("Отключать коллизию у редактируемых объектов"), checkbox.editnocol) then 
               ini.settings.editnocol = checkbox.editnocol.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Временно отключает коллизию только для редактируемого объекта")
         end
         
         -- if imgui.CollapsingHeader(u8"Визуальный ред. объектов") then
            -- Object object = createObject(Model modelId, float atX, float atY, float atZ)
         -- end
         if imgui.CollapsingHeader(u8"Ретекстур") then
            if not LastObject.localid then
               imgui.TextColoredRGB("{696969}Объект не выбран! Укажите ID объекта ниже")
            end
            
            if imgui.TooltipButton(u8"Список текстур", imgui.ImVec2(120, 25), u8:encode("Список последних использованных текстур (/tlist)")) then
               sampSendChat("/tlist")
            end
            imgui.SameLine()
            imgui.TextColoredRGB("ID:")
            imgui.SameLine()
            imgui.PushItemWidth(40)
            if imgui.InputInt('##INPUT_OBJ', input.txdobject, 0) then
               if input.txdobject.v < 1 and input.txdobject.v > 65535 then
                  input.txdobject.v = 1
                  imgui.resetIO()
               end
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion(" [<] ", u8"Вставить ID последнего объекта")
            if imgui.IsItemClicked() then
               if LastObject.localid then
                  input.txdobject.v = tonumber(LastObject.localid)
               else
                  input.txdobject.v = 0
               end
            end
            imgui.SameLine()
            imgui.TextColoredRGB("Слот:")
            imgui.SameLine()
            imgui.PushItemWidth(30)
            if imgui.InputInt('##INPUT_SLOT', input.txdslot, 0) then
               if input.txdslot.v < 0 and input.txdslot.v > 16 then
                  input.txdslot.v = 0
                  imgui.resetIO()
               end
            end
            imgui.PopItemWidth()
            -- imgui.SameLine()
            -- if imgui.Checkbox(u8("Все слои"), checkbox.allslots) then 
            -- end
            -- imgui.SameLine()
            -- imgui.TextQuestion("( ? )", u8"Применить на все слои (только для ретексура)")
            
            if imgui.TooltipButton(u8"Наложить текстуру", imgui.ImVec2(140, 25), u8:encode("Наложить текcтуру на объект (/texture)")) then
               if LastObject.localid then
                  edit.mode = 4
                  showRetextureKeysHelp()
                  -- if checkbox.allslots.v then
                     -- lua_thread.create(function()
                        -- for i = 1, 16 do
                           -- sampSendChat("/texture "..input.txdobject.v.." "..i)
                           -- wait(500)
                        -- end
                     -- end)
                  -- else
                     -- sampSendChat("/texture "..input.txdobject.v.." "..input.txdslot.v)
                  -- end
                  sampSendChat("/texture "..input.txdobject.v.." "..input.txdslot.v)
                  if dialog.main.v then dialog.main.v = false end
               else
                  sampSendChat("/texture 0")               
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не выбран объект. Попробуйте /omenu <id>", 0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Наложить текст", imgui.ImVec2(140, 25), u8:encode("Наложить текст на объект (/otext)")) then
               if LastObject.localid then
                  sampSendChat("/otext "..LastObject.localid)
               else
                  sampSendChat("/otext -1")
               end
               if dialog.main.v then dialog.main.v = false end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Поиск", imgui.ImVec2(60, 25), u8:encode("Открыть вкладку поиска текстур")) then
               tabmenu.info = 2
               tabmenu.main = 3
               tabmenu.onlinesearch = 2
            end
            
            --imgui.Spacing()
            imgui.Text(u8"Цвет:")
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.0, 1.0))
            if imgui.TooltipButton(u8"Покрасить", imgui.ImVec2(105, 25), u8:encode("Наложить цвет на объект (/ocolor)")) then
               sampSendChat("/ocolor "..input.txdobject.v.." "..input.txdslot.v.." "..textbuffer.ocolor.v)
            end
            imgui.PopStyleColor()
            imgui.SameLine()
            
            imgui.PushItemWidth(70)
            if string.len(textbuffer.ocolor.v) < 1 then
               textbuffer.ocolor.v = "FFFFFFFF"
            end
            if imgui.InputText("##ocolor", textbuffer.ocolor) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.PushItemWidth(150)
            if imgui.ColorEdit4("##txdclrrgba", input.txdclrrgba, imgui.ColorEditFlags.NoInputs) then
               local rgba = imgui.ImColor(input.txdclrrgba.v[1], input.txdclrrgba.v[2], input.txdclrrgba.v[3], input.txdclrrgba.v[4])
               local hexcolor = tostring(intToHexRgb(join_argb(input.txdclrrgba.v[4] * 255,
               input.txdclrrgba.v[1] * 255, input.txdclrrgba.v[2] * 255, input.txdclrrgba.v[3] * 255)))
               local color = string.upper(hexcolor)
               textbuffer.ocolor.v = "FF"..tostring(color)
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion(u8" ( ? ) ", u8"Цвет в формате AARRGGBB")
            imgui.SameLine()
            if imgui.TooltipButton(u8"Палитра", imgui.ImVec2(85, 25), u8:encode("Перейти на вкладку выбора цвета")) then
               tabmenu.info = 3
               tabmenu.main = 3
            end
            
            if imgui.TooltipButton(u8"Затемнить", imgui.ImVec2(105, 25), u8:encode("Затемнить объект")) then
               if LastObject.localid then 
                  sampSendChat("/ocolor "..LastObject.localid.." 0xFFFFFFFF")
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект "..LastObject.localid.." был затемнен", 0x0FF6600)
               else 
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не выбран объект. Попробуйте /omenu <id>", 0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Сбросить", imgui.ImVec2(70, 25), u8:encode("Сбросить цвет на стандартный")) then
               textbuffer.ocolor.v = "FFFFFFFF"
               sampSendChat("/ocolor "..input.txdobject.v.." "..input.txdslot.v.." FFFFFFFF")
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Сделать прозрачным", imgui.ImVec2(150, 25), u8:encode("Устанавливает прозрачную текстуру на 0 слой делая объект невидимым")) then
               if LastObject.localid then 
                  sampSendChat("/stexture "..LastObject.localid.." 0 8660")
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект "..LastObject.localid.." сделан прозрачным", 0x0FF6600)
               else 
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не выбран объект. Попробуйте /omenu <id>", 0x0FF6600)
               end
            end
            
            --imgui.Spacing()
            imgui.Text(u8"Индексы:")
            if imgui.TooltipButton(u8"Показать индексы", imgui.ImVec2(140, 25), u8:encode("Показать индексы(слои) на объекте (/sindex)")) then
               sampSendChat("/sindex")
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Очистить текстуры", imgui.ImVec2(140, 25), u8:encode("Очистить все текстуры на объекте (/untexture)")) then
               sampSendChat("/untexture")
            end
            -- imgui.SameLine()
            -- if imgui.TooltipButton(u8"Цветные индексы", imgui.ImVec2(140, 25), u8:encode("Покрасить каждый слой на объекте (/cindex)")) then
               -- if LastObject.handle and doesObjectExist(LastObject.handle) then
                  -- setMaterialObject(LastObject.id, 1, 0, 18646, "MatColours", "red", 0xFFFFFFFF) 
                  -- setMaterialObject(LastObject.id, 1, 1, 18646, "MatColours", "green", 0xFFFFFFFF)         
                  -- setMaterialObject(LastObject.id, 1, 2, 18646, "MatColours", "blue", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 3, 18646, "MatColours", "yellow", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 4, 18646, "MatColours", "lightblue", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 5, 18646, "MatColours", "orange", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 6, 18646, "MatColours", "redlaser", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 7, 18646, "MatColours", "grey", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 8, 18646, "MatColours", "white", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 9, 7910, "vgnusedcar", "lightpurple2_32", 0xFFFFFFFF)
                  -- setMaterialObject(LastObject.id, 1, 10, 19271, "MapMarkers", "green-2", 0xFFFFFFFF) -- dark green
                  -- --setMaterialObjectText(LastObject.id, 2, 0, 100, "Arial", 255, 0, 0xFFFFFF00, 0xFF00FF00, 1, "0"))
                  -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Режим визуального просмотра индексов включен.", 0x0FF6600)
                  -- sampAddChatMessage("{FFFFFF}Каждый индекс соответсвует цвету с таблицы:", 0x0FF6600)
                  -- sampAddChatMessage("{FF0000}0 {008000}1 {0000FF}2 {FFFF00}3 {00FFFF}4 {FF4FF0}5 {dc143c}6 {808080}7 {FFFFFF}8 {800080}9 {006400}10", -1)
               -- else
                  -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Последний созданный объект не найден", 0x0FF6600)
               -- end
            -- end
            
         end
         
         if imgui.CollapsingHeader(u8"Рендер") then
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
               -- if LastObject.modelid and input.rendselectedmodelid.v == 0 then 
                  -- input.rendselectedmodelid.v = LastObject.modelid
               -- end
               
               local closestObjectId = getClosestObjectId()
               if closestObjectId and input.rendselectedmodelid.v == 0 then
                  input.rendselectedmodelid.v = getObjectModel(closestObjectId)
               end
               
               imgui.Text(u8"modelid объекта: ")
               imgui.SameLine()
               imgui.PushItemWidth(55)
               imgui.InputInt('##INPUT_REND_SELECTED', input.rendselectedmodelid, 0)
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Введите modelid от 615-18300 [GTASA], 18632-19521 [SAMP]")
               imgui.SameLine()
               if imgui.TooltipButton(u8"Ближайший", imgui.ImVec2(90, 25), u8"Вставить модель ближайшего объекта") then
                  local closestObjectId = getClosestObjectId()
                  if closestObjectId then
                     input.rendselectedmodelid.v = getObjectModel(closestObjectId)
                  end
               end
            end
            
            imgui.Text(u8"Макс. дистанция поиска: ")
            imgui.SameLine()
            imgui.PushItemWidth(55)
            imgui.InputInt('##rendmaxdist', input.rendmaxdist, 0)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Максимальная дистанция поиска от 0 - 500 (Ограничен зоной стрима)")
            
            imgui.PushItemWidth(150)
            if imgui.ColorEdit4("##rendclrrgba", input.rendclrrgba, imgui.ColorEditFlags.NoInputs) then
               local rgba = imgui.ImColor(input.rendclrrgba.v[1], input.rendclrrgba.v[2], input.rendclrrgba.v[3], input.rendclrrgba.v[4])
               local hexcolor = tostring(intToHexRgb(join_argb(input.rendclrrgba.v[4] * 255,
               input.rendclrrgba.v[1] * 255, input.rendclrrgba.v[2] * 255, input.rendclrrgba.v[3] * 255)))
               local color = string.upper(hexcolor)
               textbuffer.rendcolor.v = "80"..tostring(color)
            end
            imgui.PopItemWidth()
            imgui.PushItemWidth(125)
            imgui.SameLine()
            if imgui.InputText("##renderclr", textbuffer.rendcolor) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8"Сохранить") then
               local formattedcolor = textbuffer.rendcolor.v
               formattedcolor = formattedcolor:gsub("}","")
               formattedcolor = formattedcolor:gsub("{","")
               ini.settings.rendercolor = formattedcolor
               inicfg.save(ini, configIni)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Сохранен новый "..tostring(formattedcolor).." цвет для рендера!", 0x0FF6600)
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"[r]", imgui.ImVec2(35, 25), u8"Сбросить на стандартный (80FFFFFF)") then
               input.rendclrrgba = imgui.ImFloat4(1, 1, 1, 1)
               textbuffer.rendcolor.v = "80FFFFFF"
               ini.settings.rendercolor = "80FFFFFF"
               inicfg.save(ini, configIni)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Цвет для рендера сброшен на стандартный!", 0x0FF6600)
            end
            
            imgui.Text(u8"Размер шрифта: ")
            imgui.SameLine()
            imgui.PushItemWidth(100)
            if imgui.InputInt('##INPUTrenderfontsize', input.renderfontsize) then
               fonts.objectsrenderfont = renderCreateFont(ini.settings.renderfont, ini.settings.renderfontsize, 5)
               ini.settings.renderfontsize = input.renderfontsize.v
               inicfg.save(ini, configIni)
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Размер шрифта для текста на рендере (стандартный - 7)")
         end
         
         if imgui.CollapsingHeader(u8"Позиция") then
            
            if imgui.Checkbox(u8("Возвращать объект на исходную позицию при отмене редактирования"), checkbox.restoreobjectpos) then
               ini.settings.restoreobjectpos = checkbox.restoreobjectpos.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Возвращает объект на исходную позицию при ESC")
            
            if imgui.Checkbox(u8("Показывать координаты объекта при перемещении"), checkbox.showobjectcoord) then
               ini.settings.showobjectrot = false
               ini.settings.showobjectcoord = checkbox.showobjectcoord.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Показывает координаты объекта при перемещении в редакторе карт")
            
            if imgui.Checkbox(u8("Показывать угол поворота объекта при перемещении"), checkbox.showobjectrot) then
               ini.settings.showobjectcoord = false
               ini.settings.showobjectrot = checkbox.showobjectrot.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Показывает угол поворота объекта (Rx, Ry, Rz) при перемещении в редакторе карт")
            
            if imgui.Checkbox(u8("Предупреждать о превышении макс. сдвига"), checkbox.bigoffsetwarning) then
               ini.settings.bigoffsetwarning = checkbox.showobjectrot.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Предупреждать при приближении к максимально возможному значению сдвига (offset) объекта")
            
            -- if imgui.Checkbox(u8("Показывать все скрытые объекты"), checkbox.showallhiddenobjects) then
            -- end
            -- imgui.SameLine()
            -- imgui.TextQuestion("( ? )", u8"Показывает все скрытые объекты в области стрима")
         end
         
         if imgui.CollapsingHeader(u8"Аттачи") then
            -- if isTrainingSanbox then
               -- if imgui.Button(u8"Список кодов аттачей") then
                  -- sampSendChat("/attlist")
               -- end
            -- end
            imgui.TextColoredRGB("{696969}К одному игроку можно прикрепить не более 10 объектов (слот 0-9)")
            imgui.SameLine()
            imgui.Link("https://www.open.mp/docs/scripting/resources/boneid", "Bone Ids")
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"\
            Bone ID's:\
            1	Spine\
            2	Head\
            3	Left upper arm\
            4	Right upper arm\
            5	Left hand\
            6	Right hand\
            7	Left thigh\
            8	Right thigh\
            9	Left foot\
            10	Right foot\
            11	Right calf\
            12	Left calf\
            13	Left forearm\
            14	Right forearm\
            15	Left clavicle (shoulder)\
            16	Right clavicle (shoulder)\
            17	Neck\
            18	Jaw\
            ")
            
            if isTrainingSanbox then
              if imgui.TooltipButton(u8"Наборы аттачей", imgui.ImVec2(200, 25),
              u8"Открыть ваши наборы аттачей") then
                  sampSendChat("/mn")
                  lua_thread.create(function()
                     wait(100)
                     sampSendDialogResponse(32700, 1, 3, "Наборы аттачей")
                  end)
                  dialog.main.v = false
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Меню аттачей на игрока", imgui.ImVec2(200, 25),
               u8"Открыть меню редактирования аттачей на игрока /att") then
                  sampSendChat("/att")
                  dialog.main.v = false
               end
            end

            if imgui.Button(u8"Скрыть аттачи (Визуально)",imgui.ImVec2(200, 25)) then
               for i, objid in pairs(getAllObjects()) do
                  pX, pY, pZ = getCharCoordinates(playerPed)
                  _, objX, objY, objZ = getObjectCoordinates(objid)
                  local ddist = getDistanceBetweenCoords3d(pX, pY, pZ, objX, objY, objZ)
                  if ddist < 1 and playerAtachedObjects[objid] ~= false then
                     setObjectVisible(objid, false)
                     playerAtachedObjects[objid] = false
                  end
               end
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы скрыли все аттачи (Визуально для себя)", 0x0FF6600)
            end
            imgui.SameLine()
            if imgui.Button(u8"Показать аттачи (Визуально)",imgui.ImVec2(200, 25)) then
               for i, objid in pairs(getAllObjects()) do
                  if playerAtachedObjects[objid] == false then
                     pX, pY, pZ = getCharCoordinates(playerPed)
                     _, objX, objY, objZ = getObjectCoordinates(objid)
                     local ddist = getDistanceBetweenCoords3d(pX, pY, pZ, objX, objY, objZ)
                     if playerAtachedObjects[objid] == false then
                        setObjectVisible(objid, true)
                        playerAtachedObjects[objid] = true
                     end
                  end
               end
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы показали скрытые аттачи", 0x0FF6600)
            end
            
            if isTrainingSanbox then
               imgui.Spacing()
               imgui.Text(u8"Применить сет аттачей по коду:")
               imgui.PushItemWidth(170)
               imgui.InputText("##TxtBufferAttachcode", textbuffer.attachcode)
               imgui.PopItemWidth()
               imgui.PushItemWidth(125)
               imgui.SameLine()
               if imgui.Combo(u8'##Attname', combobox.attname, attCodeNames) then
                  textbuffer.attachcode.v = attCodes[combobox.attname.v+1]
               end
               
               if imgui.Button(u8"Сбросить",imgui.ImVec2(150, 25)) then
                  textbuffer.attachcode.v = attCodes[combobox.attname.v+1]
                  sampSendChat("/mn")
                  lua_thread.create(function()
                     wait(50)
                     sampSendChat("/mn")
                     wait(200)
                     sampSendDialogResponse(32700, 1, 3, "Наборы аттачей")
                     wait(5)
                     sampSendDialogResponse(32700, 1, 1, "Очистить надетые аттачи")
                  end)
               end
               imgui.SameLine()
               if imgui.Button(u8"Протестировать",imgui.ImVec2(150, 25)) then
                  dialoghook.attachcode = true
                  dialoghook.autoattach = true
                  sampSendChat("/code")
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Демонстрация сета - "..u8:decode(attCodeNames[combobox.attname.v+1]), 0x0FF6600)
               end
            end
            
            imgui.Spacing()
            
            imgui.Checkbox(u8("Отслеживать установку аттачей"), checkbox.hooksetattachedobject) 
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет выводить сообщение в чат при установке аттача с его параметрами")
            
            imgui.Checkbox(u8("Игнорировать установку аттачей"), nops.setplayerattachedobject) 
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет игнорировать установку аттачей сервером на вашего персонажа")
            
         end
         
         if imgui.CollapsingHeader(u8"Пикапы") then
            local pickup = sampGetPickupHandleBySampId(input.pickupid.v)
            local exist = doesPickupExist(pickup)
            
            if exist then
               imgui.TextColoredRGB("ID:")
            else
               imgui.TextColoredRGB("{696969}ID:")
            end
            imgui.SameLine()
            imgui.PushItemWidth(40)
            if imgui.InputInt('##INPUT_PickupId', input.pickupid, 0) then
               if input.pickupid.v < 0 and input.pickupid.v > 4096 then
                  input.pickupid.v = 0
               end
            end
            
            if exist then
               local x, y, z = getPickupCoordinates(pickup)
               imgui.TextColoredRGB(("Координаты: %.2f, %.2f, %.2f"):format(x,y,z))
               if imgui.IsItemClicked() then
                  setClipboardText(("%.2f, %.2f, %.2f"):format(x,y,z))
                  sampAddChatMessage("Координаты скопированы в буффер обмена", -1)
               end
            end
            
            if imgui.TooltipButton(u8"ТП к Пикапу", imgui.ImVec2(120, 25), u8"Телепортироваться к пикапу") then
               local x, y, z = getPickupCoordinates(pickup)
               if isAnyPickupAtCoords(x, y, z) then 
                  sampSendChat(string.format("/xyz %f %f %f", x, y, z)) 
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Пикап не существует!",0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Взять пикап по ID", imgui.ImVec2(120, 25), u8"Отправить взятие пикапа по ID") then
               sampSendPickedUpPickup(input.pickupid.v)
            end
            imgui.SameLine()
            imgui.Text("    ")
            imgui.SameLine()
            if imgui.TooltipButton(u8"Список всех пикапов в стриме", imgui.ImVec2(220, 25), 
            u8"Показать список всех пикапов в стриме /pickuplist") then
               sampSendChat("/pickuplist")
            end
            
            if imgui.TooltipButton(u8"Метку на пикап", imgui.ImVec2(120, 25), u8"Установить метку на пикап") then
               if LastData.lastPickupBlip then
                  removeBlip(LastData.lastPickupBlip)
                  LastData.lastPickupBlip = nil
               else
                  LastData.lastPickupBlip = addBlipForPickup(pickup)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Снять метку", imgui.ImVec2(120, 25), u8"Снимет метку с пикапа") then
               if LastData.lastPickupBlip then
                  removeBlip(LastData.lastPickupBlip)
                  LastData.lastPickupBlip = nil
               end
            end
            imgui.SameLine()
            imgui.Text("    ")
            imgui.SameLine()
            if imgui.TooltipButton(u8"Список всех моделей пикапов", imgui.ImVec2(220, 25), 
            u8"Открыть список всех доступных пикапов на сайте open.mp (Онлайн)") then
               os.execute('explorer "https://www.open.mp/docs/scripting/resources/pickupids"')
            end
            
            if imgui.TooltipButton(u8"Удалить пикап", imgui.ImVec2(245, 25), u8"Визуально удалит пикап по ID") then
               removePickup(pickup)
            end
            imgui.SameLine()
            imgui.Text("    ")
            imgui.SameLine()
            if imgui.TooltipButton(u8"Список всех типов пикапов", imgui.ImVec2(220, 25), 
            u8"Открыть список всех типов пикапов на сайте open.mp (Онлайн)") then
               os.execute('explorer "https://sampwiki.blast.hk/wiki/PickupTypes"')
            end
            
            
            if imgui.Checkbox(u8"Уведомлять о взятии пикапа", checkbox.pickupinfo) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Выводит сообщение в чат при взятии пикапа")
            
            imgui.PopItemWidth()
            -- for k, pickup in ipairs(getAllPickups()) do
               -- local id = sampGetPickupSampIdByHandle(pickup)
               -- local x, y, z = getPickupCoordinates(pickup)
               -- local pX, pY, pZ = getCharCoordinates(playerPed)
               -- local distance = getDistanceBetweenCoords3d(x, y, z, pX, pY, pZ)
            -- end
         end
         
         imgui.Spacing()
         imgui.Spacing()
         local streamedobjects = getStreamedObjects(true)
         local streamedobjectsdyn = getStreamedObjects(false)
         if streamedobjects then
            if streamedobjects < 200 then
               imgui.TextColoredRGB(("{696969}Объектов на экране: %i (dynamic: %i)"):format(streamedobjects, streamedobjectsdyn))
            elseif streamedobjects > 200 and streamedobjects < 350 then
               imgui.TextColoredRGB(("{696969}Объектов на экране: {FFA500}%i (dynamic: %i)"):format(streamedobjects, streamedobjectsdyn))
            else
               imgui.TextColoredRGB(("{696969}Объектов на экране: {A00000}%i (dynamic: %i)"):format(streamedobjects, streamedobjectsdyn))
            end
         end
        
      elseif tabmenu.settings == 3 then

         local angle = math.ceil(getCharHeading(playerPed))
         imgui.Text(string.format(u8"Направление: %s  %i°", direction(), angle))
         local camX, camY, camZ = getActiveCameraCoordinates()
         imgui.Text(string.format(u8"Камера x: %.1f, y: %.1f, z: %.1f",
         camX, camY, camZ))
         if imgui.IsItemClicked() then
            setClipboardText(string.format(u8"%.1f, %.1f, %.1f", camX, camY, camZ))
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Позиция скопирована в буффер обмена", 0x0FF6600)
         end
         
         -- local rX, rY, rZ = getActiveCameraPointAt()
         -- imgui.Text(string.format(u8"Камера rx: %.1f, ry: %.1f, rz: %.1f",
         -- rX, rY, rZ))
         
         if isCharInAnyCar(playerPed) then 
            imgui.Text(string.format(u8"Режим камеры в транспорте: %d", getPlayerInCarCameraMode()))
         end
         imgui.Spacing()
         imgui.Spacing()
         
         if imgui.CollapsingHeader(u8"Зафиксированная камера") then
            if imgui.Checkbox(u8("Зафиксировать камеру на координатах"), checkbox.fixcampos) then
               if checkbox.fixcampos.v then
                  fixcam.x = camX           
                  fixcam.y = camY           
                  fixcam.z = camZ
                  textbuffer.fixcamx.v = string.format("%.1f", fixcam.x)
                  textbuffer.fixcamy.v = string.format("%.1f", fixcam.y)
                  textbuffer.fixcamz.v = string.format("%.1f", fixcam.z)
               else 
                  restoreCamera()
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Зафиксирует положение камеры на указанные значения")
            
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
            
            if imgui.Checkbox(u8("Зафиксировать камеру позади игрока"), checkbox.lockcambehind) then
               if checkbox.lockcamfront.v then checkbox.lockcamfront.v = false end
               if checkbox.fixcampos.v then
                  checkbox.lockcambehind.v = false
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Сперва разблокируйте положение камеры", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Зафиксирует положение камеры позади игрока (Камера всегда смотрит прямо)")
            
            if imgui.Checkbox(u8("Зафиксировать камеру спереди игрока"), checkbox.lockcamfront) then
               if checkbox.lockcambehind.v then checkbox.lockcambehind.v = false end
               if checkbox.fixcampos.v then
                  checkbox.lockcamfront.v = false
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Сперва разблокируйте положение камеры", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Зафиксирует положение камеры спереди игрока (Режим селфи)")
            
            if imgui.Checkbox(u8'Запретить изменять положение камеры', checkbox.lockcamchange) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет полностью игнорировать смену камеры сервером")
         
            imgui.Text(u8"Прикрепить камеру:")
            if imgui.Button(u8"Позади игрока", imgui.ImVec2(200, 25)) then
               if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Камера установлена позади игрока", 0x0FF6600)
               setCameraBehindPlayer()
            end
            imgui.SameLine()
            if imgui.Button(u8"В текущей точке", imgui.ImVec2(200, 25)) then
               local mode = 15 -- Fixed camera (non-moving) - used for Pay 'n' Spray, chase camera, tune shops, entering buildings, buying food etc.
               local switchstyle = 1 --(1 - CAMERA_MOVE 2 - CAMERA_CUT)
               pointCameraAtChar(playerPed, mode, switchstyle)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Камера закреплена в текущей точке", 0x0FF6600)
            end
            
            if imgui.Button(u8"На ближайшего игрока", imgui.ImVec2(200, 25)) then
               if getClosestPlayerId() ~= -1 and getClosestPlayerId() ~= getLocalPlayerId() then
                  local result, ped = sampGetCharHandleBySampPlayerId(getClosestPlayerId())
                  local mode = 4 -- https://sampwiki.blast.hk/wiki/CameraModes
                  local switchstyle = 1 --(1 - CAMERA_MOVE 2 - CAMERA_CUT)
                  pointCameraAtChar(ped, mode, switchstyle)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Камера прикреплена к ближйшему игроку id:"..getClosestPlayerId(), 0x0FF6600)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден ближайший игрок (рядом никого нет)", 0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"На ближайший транспорт", imgui.ImVec2(200, 25)) then
               local closestcarhandle, closestcarid = getClosestCar()
               if closestcarhandle then
                  local mode = 18 -- Normal car (+skimmer+helicopter+airplane), several variable distances.
                  local switchstyle = 1 --(1 - CAMERA_MOVE 2 - CAMERA_CUT)
                  pointCameraAtCar(closestcarhandle, mode, switchstyle)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Камера прикреплена к ближйшему транспорту id:"..closestcarid, 0x0FF6600)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден ближайший транспорт", 0x0FF6600)
               end
            end
         end
         if imgui.CollapsingHeader(u8"Перемещение камеры") then
            --local camX, camY, camZ = getActiveCameraCoordinates()
            --cameraSetVectorMove(camX, camY, camZ, posX, posY, posZ, 5000, false)
            if textbuffer.camx.v == textbuffer.fixcamx.v  
            or textbuffer.camy.v == textbuffer.fixcamx.v
            or textbuffer.camz.v == textbuffer.fixcamz.v then
               imgui.TextColoredRGB("{696969}Все конечные значения перемещения камеры, должны отличаться от начальных!")
            end
            
            if string.len(textbuffer.fixcamx.v) < 1
            or string.len(textbuffer.fixcamx.v) < 1
            or string.len(textbuffer.fixcamz.v) < 1 then
               imgui.TextColoredRGB("{696969}Введите конечную позицию для перемещения камеры!")
            end
            
            if not checkbox.holdcam.v then
               cam.x = camX           
               cam.y = camY           
               cam.z = camZ
               textbuffer.camx.v = string.format("%.1f", cam.x)
               textbuffer.camy.v = string.format("%.1f", cam.y)
               textbuffer.camz.v = string.format("%.1f", cam.z)
            end
            
            imgui.Text(u8"Начальная позиция:")
            imgui.Text("x:")
            imgui.SameLine()
            imgui.PushItemWidth(70)
            if imgui.InputText("##camxBuffer", textbuffer.camx, imgui.InputTextFlags.CharsDecimal) then
               cam.x = tonumber(textbuffer.camx.v)
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.Text("y:")
            imgui.SameLine()
            imgui.PushItemWidth(70)
            if imgui.InputText("##camyBuffer", textbuffer.camy, imgui.InputTextFlags.CharsDecimal) then
               cam.y = tonumber(textbuffer.camy.v)
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.Text("z:")
            imgui.SameLine()
            imgui.PushItemWidth(70)
            if imgui.InputText("##camzBuffer", textbuffer.camz, imgui.InputTextFlags.CharsDecimal) then
               cam.z = tonumber(textbuffer.camz.v)
            end
            imgui.PopItemWidth()
            
            imgui.SameLine()
            if imgui.Checkbox(u8"Удерживать", checkbox.holdcam) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет удерживать текущие значения камеры")
            
            imgui.Text(u8"Конечная позиция:")
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
            
            imgui.SameLine()
            if imgui.Button(u8"Копировать", imgui.ImVec2(100, 25)) then
               textbuffer.fixcamx.v = string.format("%.1f", cam.x)
               textbuffer.fixcamy.v = string.format("%.1f", cam.y)
               textbuffer.fixcamz.v = string.format("%.1f", cam.z)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Скопирует значения с начальной позиции")
            
            imgui.Text(u8"Время:")
            imgui.SameLine()
            imgui.PushItemWidth(55)
            imgui.InputInt('ms.##CamDelay', input.camdelay, 0)
            imgui.PopItemWidth()
            
            imgui.SameLine()
            if imgui.Checkbox(u8"Плавное движение", checkbox.smoothcam) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Устанвливает плавное движение камеры при перемещении")
            
            if imgui.Button(u8"Переместить камеру", imgui.ImVec2(150, 25)) then
               cameraSetVectorMove(cam.x, cam.y, cam.z, fixcam.x, fixcam.y, fixcam.z, input.camdelay.v, checkbox.smoothcam.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Векторное перемещение камеры", imgui.ImVec2(220, 25)) then
               cameraSetVectorTrack(cam.x, cam.y, cam.z, fixcam.x, fixcam.y, fixcam.z, input.camdelay.v, checkbox.smoothcam.v)
            end
         end
         
         if imgui.CollapsingHeader(u8"Дистанция камеры") then
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
               imgui.TextColoredRGB("Дистанция камеры игрока")
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
               cameraSetLerpFov(slider.fov.v, slider.fov.v, 1000, true)
            end 
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Разблокирует изменения значение поля зрения (FOV).")
            
            if checkbox.changefov.v then
               imgui.TextColoredRGB("FOV")
               imgui.SameLine()
               imgui.TextQuestion(u8"(по-умолчанию 70)", u8"Вернуть на значение по-умолчанию")
               if imgui.IsItemClicked() then
                  slider.fov.v = 70
                  cameraSetLerpFov(slider.fov.v, slider.fov.v, 1000, true)
                  ini.settings.fov = slider.fov.v
                  inicfg.save(ini, configIni)
               end
               if imgui.SliderInt(u8"##fovslider", slider.fov, 1, 179) then
                  cameraSetLerpFov(slider.fov.v, slider.fov.v, 1000, true)
                  ini.settings.fov = slider.fov.v
                  inicfg.save(ini, configIni)
               end
            end
         end
         
         if imgui.CollapsingHeader(u8"Flymode") then
            
            imgui.TextColoredRGB("Скорость перемещения в режиме полета")
            imgui.PushItemWidth(95)
            if imgui.InputFloat('Default##defspeed', input.flymodespeed, 0.01, 10.0) then
               if input.flymodespeed.v < 0.01 or input.flymodespeed.v > 10.0 then
                  input.flymodespeed.v = 0.30
               end
               --ini.settings.flymodespeed = ("%.2f"):format(input.flymodespeed.v)
               ini.settings.flymodespeed = input.flymodespeed.v
               inicfg.save(ini, configIni)
            end
            imgui.PopItemWidth()

            imgui.SameLine()
            
            imgui.PushItemWidth(95)
            if imgui.InputFloat('MAX##maxspeed', input.flymodemaxspeed, 1.0, 100.0) then
               if input.flymodemaxspeed.v < 1.0 or input.flymodemaxspeed.v > 100.0 then
                  input.flymodemaxspeed.v = 50.0
               end
               ini.settings.flymodemaxspeed = input.flymodemaxspeed.v
               inicfg.save(ini, configIni)
            end
            imgui.PopItemWidth()
            
            imgui.SameLine()
            if imgui.Button(u8"Сбросить", imgui.ImVec2(70, 25)) then
               input.flymodespeed.v = 0.30
               input.flymodemaxspeed.v = 50.0
               ini.settings.flymodemaxspeed = input.flymodemaxspeed.v
               --ini.settings.flymodespeed = ("%.2f"):format(input.flymodespeed.v)
               ini.settings.flymodespeed = input.flymodespeed.v
               inicfg.save(ini, configIni)
            end
            
            if imgui.Button(u8"Помощь", imgui.ImVec2(125, 25)) then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Управление в режиме полета (Flymode):", 0x0FF6600)
               sampAddChatMessage("[SCRIPT]: {FF6600}Пробел{FFFFFF} - переместиться вверх {FF6600}CTRL{FFFFFF} - переместиться вниз", 0x0FF6600)
               sampAddChatMessage("[SCRIPT]: {FF6600}ЛКМ{FFFFFF} - ускориться {FF6600}ПКМ{FFFFFF} - замедлиться", 0x0FF6600)
               sampAddChatMessage("[SCRIPT]: {FF6600}С{FFFFFF} - сбросить скорость на начальное значение", 0x0FF6600)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Нажатие на {FF6600}колесико мыши{FFFFFF} - быстрое ускорение", 0x0FF6600)
               sampAddChatMessage("[SCRIPT]: {FF6600}Боковые клавиши мыши{FFFFFF} - переместиться вверх-вниз", 0x0FF6600)
            end
            imgui.SameLine()
            if imgui.Button(u8"Режим полета", imgui.ImVec2(220, 25)) then
               sampSendChat("/flymode")
            end
            
            -- imgui.TextColoredRGB("Ускорение в режиме полета (На нажатие клавиш мыши)")
            -- if imgui.SliderFloat(u8"##flymodepower", slider.flymodepower, 0.1, 50.0) then
               -- local power = slider.flymodepower.v
               -- playerdata.flypower = playerdata.flypower + power
            -- end
         end
         
         imgui.Spacing()
         imgui.Spacing()
         if imgui.Button(u8(ini.settings.showhud and 'Скрыть' or 'Показать')..u8" HUD", imgui.ImVec2(100, 25)) then
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
         if isTrainingSanbox then
            imgui.SameLine()
            if imgui.TooltipButton(u8"Перейти в интерьер для съемок", imgui.ImVec2(230, 25), u8"Телепортирует в интерьер с хромакеем") then
               if playerdata.isWorldHoster then
                  sampSendChat("/int 1 1")
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Вернуться обратно можно командой /spawnme", 0x0FF6600)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы не хостер в мире!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Черный экран", imgui.ImVec2(130, 25), u8"Включает режим черного экрана /blind") then
               sampSendChat("/blind")
            end
         end
         
         if imgui.Checkbox(u8'Отключать радар в интерьерах', checkbox.nointeriorradar) then
            ini.settings.nointeriorradar = checkbox.nointeriorradar.v
            inicfg.save(ini, configIni)
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Отключит радар при входе в интерьер")
         
         
         if imgui.Checkbox(u8("Визуально скрыть персонажа"), checkbox.hideped) then 
            if checkbox.hideped.v then
               hidePED(true)
            else
               hidePED(false)
            end
         end 
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Визуально для вас скроет скин и аттачи")
	     
         if imgui.Checkbox(u8("Пьяная камера"), checkbox.drunkcam) then 
            if not checkbox.drunkcam.v then
               local bs = raknetNewBitStream()
               raknetBitStreamWriteInt32(bs, 0)
               raknetEmulRpcReceiveBitStream(35, bs)
               raknetDeleteBitStream(bs)
            end
         end 
         
         --imgui.Text(u8"Время:")
         --imgui.SameLine()
         imgui.PushItemWidth(50)
         imgui.InputInt('##CamShake', input.camshake, 0)
         imgui.PopItemWidth()
         imgui.SameLine()
         if imgui.Button(u8"Тряска камеры", imgui.ImVec2(150, 25)) then
            shakeCam(input.camshake.v)
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Создаёт эффект тряски камеры")
         
         if imgui.Button(u8">> Вернуть камеру <<", imgui.ImVec2(250, 25)) then
            if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Камера возвращена на исходные", 0x0FF6600)
            restoreCamera()
         end
         
         imgui.Spacing()
      elseif tabmenu.settings == 4 then
         
         imgui.TextColoredRGB("Дистанция прорисовки LOD")
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
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"LOD модели - это низкополигональные версии обычных моделей.\
         Эти модели мы видим издалека. По мере того, как вы приближаетесь \
         к LOD-модели, она должна изменится на оригинальную.")
         
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
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Позволяет управлять дальностью прорисовки тумана.")
         
         imgui.Spacing()
         imgui.Spacing()
         imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(4, 4))
         
         if imgui.ToggleButton(u8"Скрыть 3D тексты", checkbox.hide3dtexts) then 
            if checkbox.hide3dtexts.v then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}3DText hide: {00FF00}Включен", 0x0FF6600)
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}3DText hide: {696969}Отключен", 0x0FF6600)
            end
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Изменения видны после респавна, либо обновления зоны стрима", 0x0FF6600)
         end 
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Скрывает 3d тексты из стрима (для скринов)")
         
         if imgui.ToggleButton(u8"Скрыть NameTags", checkbox.nametagoff) then 
            if isTrainingSanbox then
               if checkbox.nametagoff.v then
                  sampSendChat("/nameoff")
               else
                  sampSendChat("/nameon")
               end
            else
               if checkbox.nametagoff.v then
                  local pStSet = sampGetServerSettingsPtr();
                  memory.setfloat(pStSet + 39, NTdist)
                  memory.setint8(pStSet + 47, NTwalls)
                  memory.setint8(pStSet + 56, NTshow)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}nameTag hide: {00FF00}Включен", 0x0FF6600)
               else
                  local pStSet = sampGetServerSettingsPtr();
                  NTdist = memory.getfloat(pStSet + 39)
                  NTwalls = memory.getint8(pStSet + 47)
                  NTshow = memory.getint8(pStSet + 56)
                  memory.setfloat(pStSet + 39, 70.0)
                  memory.setint8(pStSet + 56, 1)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}nameTag hide: {696969}Отключен", 0x0FF6600)
               end
            end
         end 
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Скрывает никнейм и информацию над игроком (nameTag)")
         
         if imgui.ToggleButton(u8"Скрыть игроков", checkbox.hideplayers) then 
            if checkbox.hideplayers.v then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Players hide: {00FF00}Включен", 0x0FF6600)
               local chars = getAllChars()
               for i = 1, #chars do
                  local res, id = sampGetPlayerIdByCharHandle(chars[i])
                  if res and chars[i] ~= 1 then
                     local bs = raknetNewBitStream()
                     raknetBitStreamWriteInt16(bs, id)
                     raknetEmulRpcReceiveBitStream(163, bs)
                     raknetDeleteBitStream(bs)
                  end
               end
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Players hide: {696969}Отключен", 0x0FF6600)
            end
         end 
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Визуально скрывает игроков в области стрима для вас")
         
         if imgui.ToggleButton(u8"Скрыть транспорт", checkbox.hidevehicles) then 
            if checkbox.hidevehicles.v then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Vehicles hide: {00FF00}Включен", 0x0FF6600)
               local vehicles = getAllVehicles()
               for i = 1, #vehicles do
                  local res, id = sampGetVehicleIdByCarHandle(vehicles[i])
                  if res and vehicles[i] ~= 0 then
                     local bs = raknetNewBitStream()
                     raknetBitStreamWriteInt16(bs, id)
                     raknetEmulRpcReceiveBitStream(165, bs)
                     raknetDeleteBitStream(bs)
                  end
               end
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Vehicles hide: {696969}Отключен", 0x0FF6600)
            end
         end 
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Визуально скрывает транспорт в области стрима для вас")
         
         if imgui.ToggleButton(u8"Скрыть аттачи игроков", checkbox.hideattaches) then 
            if checkbox.hideattaches.v then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}PlayerAttaches hide: {00FF00}Включен", 0x0FF6600)
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}PlayerAttaches hide: {696969}Отключен", 0x0FF6600)
            end
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Изменения видны только после обновления зоны стрима. (Можно презайти в мир)!", 0x0FF6600)
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Визуально скрывает скрывает аттачи других игроков для вас")
         
         if imgui.ToggleButton(u8"Скрыть надписи", checkbox.hidematerialtext) then 
            if checkbox.hidematerialtext.v then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}MaterialText hide: {00FF00}Включен", 0x0FF6600)
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}MaterialText hide: {696969}Отключен", 0x0FF6600)
            end
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Изменения видны только после обновления зоны стрима!", 0x0FF6600)
         end 
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Визуально скрывает все надписи (MaterialText)")
         
         imgui.PopStyleVar()
         imgui.Spacing()
         
         if imgui.TooltipButton(u8"Updstream", imgui.ImVec2(95, 25),
            u8:encode("Подгрузить параметры дальности прорисовки для объектов")) then
            if isTrainingSanbox then
               sampSendChat("/updstream")
            else
               -- force clean stream memory (cause crashes)
               callFunction(0x40D7C0, 1, 1, -1) 
            end
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"Restream", imgui.ImVec2(95, 25),
         u8:encode("Обновить зону стрима путем телепорта из зоны стрима, и возврата обратно")) then
            Restream()
         end
         imgui.SameLine()
         imgui.TextColoredRGB(("{696969}streamed objects:  %i"):format(tostring(getStreamedObjects(ini.panel.showstreamedallobjects))))
         
         if imgui.Button(u8"Очистить streaming memory",imgui.ImVec2(195, 25)) then
            cleanStreamMemory()
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Streaming memory очищена", 0x0FF6600)
         end
         local streamedmem = memory.read(0x8E4CB4, 4, true)
         if streamedmem then
            imgui.SameLine()
            imgui.TextColoredRGB(("{696969}streaming memory: %.2f MB"):format(tostring(streamedmem/1000000)))
         end
         
         if imgui.Checkbox(u8"Авто-очистка streaming memory", checkbox.streammemmax) then 
            if checkbox.streammemmax.v then
               input.streammemmax.v = 400
            else
               input.streammemmax.v = 0
            end
            ini.settings.streammemmax = input.streammemmax.v
            inicfg.save(ini, configIni)
         end 
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Авто-очистка памяти по максимальному значению (Рекомендуемое значение 400)")
         
         if checkbox.streammemmax.v then
            imgui.PushItemWidth(40)
            imgui.InputInt('##INPUT_streammemmax', input.streammemmax, 0)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8"Применить") then
               if input.streammemmax.v  >= 100 then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Настройки авто-очистки сохранены!", 0x0FF6600)
                  ini.settings.streammemmax = input.streammemmax.v
                  inicfg.save(ini, configIni)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Неверное значение. (От 100 MB)!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion(u8"(по-умолчанию 400)", u8"Вернуть на значение по-умолчанию")
            if imgui.IsItemClicked() then
               input.streammemmax.v = 400
               ini.settings.streammemmax = input.streammemmax.v
               inicfg.save(ini, configIni)
            end
         end
         
      elseif tabmenu.settings == 5 then
         local textdata = {lines = 0, symbols = 0, tags = 0}
         
         if string.len(textbuffer.txdoutlinecolor.v) < 1 then
            local color = tostring(join_argb(input.txdoutlinecolorrgba.v[4] * 255,
            input.txdoutlinecolorrgba.v[1] * 255, input.txdoutlinecolorrgba.v[2] * 255, input.txdoutlinecolorrgba.v[3] * 255))
            textbuffer.txdoutlinecolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
         end
         
         if string.len(textbuffer.txdletcolor.v) < 1 then
            local color = tostring(join_argb(input.txdletcolorrgba.v[4] * 255,
            input.txdletcolorrgba.v[1] * 255, input.txdletcolorrgba.v[2] * 255, input.txdletcolorrgba.v[3] * 255))
            textbuffer.txdletcolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
         end
         
         if string.len(textbuffer.txdboxcolor.v) < 1 then
            local color = tostring(join_argb(input.txdboxcolorrgba.v[4] * 255,
            input.txdboxcolorrgba.v[1] * 255, input.txdboxcolorrgba.v[2] * 255, input.txdboxcolorrgba.v[3] * 255))
            textbuffer.txdboxcolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
         end
         
         --imgui.TextNotify("{696969}TextDraws",u8"")
         imgui.TextColoredRGB("{696969}TextDraws")
         --imgui.Link("https://www.open.mp/docs/scripting/functions/TextDrawCreate","TextDraw")
         imgui.SameLine()
         if tabmenu.txd == 1 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Редактировать", imgui.ImVec2(115, 25)) then tabmenu.txd = 1 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Редактировать", imgui.ImVec2(115, 25)) then tabmenu.txd = 1 end
         end
         
         imgui.SameLine()
         if tabmenu.txd == 2 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Экспорт", imgui.ImVec2(75, 25)) then 
               local posX, posY = sampTextdrawGetPos(input.txdid.v)
               if posX > 12400 or posY > 12400 then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Сначала получите или примените параметры текстдрава!", 0x0FF6600)
               else
                  tabmenu.txd = 2 
               end
            end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Экспорт", imgui.ImVec2(80, 25)) then 
               local posX, posY = sampTextdrawGetPos(input.txdid.v)
               if posX > 12400 or posY > 12400 then
               --if sampTextdrawIsExists(input.txdid.v) then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Сначала получите или примените параметры текстдрава!", 0x0FF6600)
               else
                  tabmenu.txd = 2 
               end
            end
         end
         
         imgui.SameLine()
         if tabmenu.txd == 3 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Дополнительно##tabmenutxd3", imgui.ImVec2(115, 25)) then tabmenu.txd = 3 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Дополнительно##tabmenutxd3", imgui.ImVec2(115, 25)) then tabmenu.txd = 3 end
         end
         
         -- if tabmenu.txd == 1 then
            -- local cursorPosX, cursorPosY = getCursorPos()
            -- local pos_x, pos_y = getScreenResolution()
            -- local resolution = u8"Разрешение: "..pos_x.."x"..pos_y
            -- local centerPoint = u8"Центральная точка: "..pos_x/2 .."x".. pos_y/2
            
            -- imgui.SameLine()
            -- imgui.TextColoredRGB(u8"{696969} X: "..cursorPosX.." Y: "..cursorPosY)
            -- imgui.SameLine()
            -- imgui.TextQuestion("( ? )", u8"Позиция курсора:\n< X - width (ширина) >, ^ Y - height (высота) v\n"..resolution.."\n"..centerPoint.." (320x240)")
         -- end
         
         imgui.Spacing()
         
         if tabmenu.txd == 1 then
            
            if dialog.txdlist.v then
               if imgui.TooltipButton("[ > ]", imgui.ImVec2(40, 25), u8"Скрыть список текстдравов") then
                  dialog.txdlist.v = not dialog.txdlist.v
               end
            else
               if imgui.TooltipButton("[ < ]", imgui.ImVec2(40, 25), u8"Раскрыть список текстдравов") then
                  dialog.txdlist.v = not dialog.txdlist.v
               end
            end
            imgui.SameLine()
            if sampTextdrawIsExists(input.txdid.v) then
               imgui.TextColoredRGB("ID:")
            else
               imgui.TextColoredRGB("{696969}ID:")
            end
            --imgui.TextQuestion("ID", u8"Глобальный ID текстдрава от 0 до 2048")
            imgui.SameLine()
            imgui.PushItemWidth(40)
            if imgui.InputInt('##INPUT_TXD', input.txdid, 0) then
               if input.txdid.v < 0 and input.txdid.v > 2048 then
                  input.txdid.v = 0
               end
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            local txdTypeList = {u8"Text", u8"Model", u8"TXD"}
            imgui.Text(u8"Тип:")
            imgui.PushItemWidth(80)
            imgui.SameLine()
            if imgui.Combo(u8'##txdtype', combobox.txdtype, txdTypeList) then
               if combobox.txdtype.v == 0 then
                  input.txdstyle.v = 1
               elseif combobox.txdtype.v == 1 then
                  input.txdstyle.v = 5 --Using font type 5 (model preview)
                  checkbox.txdusebox.v = true
               elseif combobox.txdtype.v == 2 then
                  input.txdstyle.v = 4 -- Using font type 4 (sprite) 
                  checkbox.txdusebox.v = true
               end
            end
            imgui.PopItemWidth()
            
            if combobox.txdtype.v == 0 then
               imgui.SameLine()
               imgui.PushItemWidth(85)
               imgui.Text(u8"Стиль:")
               imgui.SameLine()
               if imgui.InputInt(u8'##INPUT_STYLE', input.txdstyle, 1, 5) then
                  if input.txdstyle.v > 5 or input.txdstyle.v < 0 then
                     input.txdstyle.v = 0
                  end
                  sampTextdrawSetStyle(input.txdid.v, tonumber(input.txdstyle.v))
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Стиль шрифта \n0. Граффити\n1. Обычный текст\n2. Строгий\n3. Жирный\n4. TXD спрайт\n5. Модель")
            end
            
            imgui.TextColoredRGB("Координаты:")
            imgui.SameLine()
            imgui.PushItemWidth(145)
            imgui.InputFloat('X##INPUT_TXDX', input.txdposx, 0.01, 9999.0)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.PushItemWidth(145)
            imgui.InputFloat('Y##INPUT_TXDY', input.txdposy, 0.01, 9999.0)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"< X - width (ширина) >, ^ Y - height (высота) v")
            
            if combobox.txdtype.v == 0 then
               --local textdata = {lines = 0, symbols = 0, tags = 0}
            
               --textdata.symbols = math.floor(string.len(textbuffer.txdstring.v)/2) --RU
               textdata.symbols = math.floor(string.len(textbuffer.txdstring.v))
               for s in string.gmatch(textbuffer.txdstring.v, "\n" ) do
                  textdata.lines = textdata.lines + 1
               end
               for s in string.gmatch(textbuffer.txdstring.v, "[~]" ) do
                  textdata.tags = textdata.tags + 1
               end
               
               imgui.TextColoredRGB("Размер букв:")
               imgui.SameLine()
               imgui.PushItemWidth(145)
               if imgui.InputFloat('X##INPUT_TXDLETX', input.txdlettersizex, 0.1, 200.0) then
                  sampTextdrawSetLetterSizeAndColor(input.txdid.v, input.txdlettersizex.v, input.txdlettersizey.v, -1)
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.PushItemWidth(145)
               if imgui.InputFloat('Y##INPUT_TXDLETY', input.txdlettersizey, 0.1, 200.0) then
                  sampTextdrawSetLetterSizeAndColor(input.txdid.v, input.txdlettersizex.v, input.txdlettersizey.v, -1)
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Шрифты выглядят лучше с соотношением X к Y от 1 до 4\n(например, если X равно 0,5, то Y должно быть 2)")
               
               imgui.TextColoredRGB("Цвет букв:  ")
               imgui.SameLine()
               if imgui.ColorEdit4("##txdletcolorrgba", input.txdletcolorrgba, imgui.ColorEditFlags.NoInputs) then
                  local color = tostring(join_argb(input.txdletcolorrgba.v[4] * 255,
                  input.txdletcolorrgba.v[1] * 255, input.txdletcolorrgba.v[2] * 255, input.txdletcolorrgba.v[3] * 255))
                  textbuffer.txdletcolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
               end
               imgui.PushItemWidth(80)
               imgui.SameLine()
               if imgui.InputText("##txdletcolor", textbuffer.txdletcolor) then
               end
               imgui.PopItemWidth()
               
               imgui.SameLine()
               imgui.TextColoredRGB("Обводка: ")
               imgui.SameLine()
               if imgui.ColorEdit4("##txdoutlinecolorrgba", input.txdoutlinecolorrgba, imgui.ColorEditFlags.NoInputs) then
                  local color = tostring(join_argb(input.txdoutlinecolorrgba.v[4] * 255,
                  input.txdoutlinecolorrgba.v[1] * 255, input.txdoutlinecolorrgba.v[2] * 255, input.txdoutlinecolorrgba.v[3] * 255))
                  textbuffer.txdoutlinecolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
               end
               imgui.PushItemWidth(80)
               imgui.SameLine()
               if imgui.InputText("##txdoutlinecolor", textbuffer.txdoutlinecolor) then
               end
               imgui.PopItemWidth()
               
               imgui.SameLine()
               if imgui.Checkbox(u8"Тень", checkbox.txdsetshadow) then
                  if checkbox.txdsetshadow.v then
                     sampTextdrawSetShadow(input.txdid.v, 1, 255)
                  else
                     sampTextdrawSetShadow(input.txdid.v, 0, 255)
                  end
               end
               
               imgui.Text(u8"Положение:")
               imgui.SameLine()
               if tabmenu.txdalign == 1 then
                  imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                  if imgui.Button(u8"Слева", imgui.ImVec2(70, 25)) then 
                     tabmenu.txdalign = 1 
                     sampTextdrawSetAlign(input.txdid.v, 1) --alignment 1-left 2-centered 3-right.
                  end
                  imgui.PopStyleColor()
               else
                  if imgui.Button(u8"Слева", imgui.ImVec2(70, 25)) then 
                     tabmenu.txdalign = 1 
                     sampTextdrawSetAlign(input.txdid.v, 1)
                  end
               end
               
               imgui.SameLine()
               if tabmenu.txdalign == 2 then
                  imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                  if imgui.Button(u8"Центр", imgui.ImVec2(70, 25)) then 
                     tabmenu.txdalign = 2
                     sampTextdrawSetAlign(input.txdid.v, 2)
                  end
                  imgui.PopStyleColor()
               else
                  if imgui.Button(u8"Центр", imgui.ImVec2(70, 25)) then 
                     tabmenu.txdalign = 2
                     sampTextdrawSetAlign(input.txdid.v, 2)
                  end
               end
               
               imgui.SameLine()
               if tabmenu.txdalign == 3 then
                  imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                  if imgui.Button(u8"Справа", imgui.ImVec2(70, 25)) then 
                     tabmenu.txdalign = 3
                     sampTextdrawSetAlign(input.txdid.v, 3)
                  end
                  imgui.PopStyleColor()
               else
                  if imgui.Button(u8"Справа", imgui.ImVec2(70, 25)) then 
                     tabmenu.txdalign = 3
                     sampTextdrawSetAlign(input.txdid.v, 3)
                  end
               end
               
               imgui.SameLine()
               if imgui.Checkbox(u8"Пропорционально", checkbox.txdproportional) then
                  if checkbox.txdproportional.v then
                     sampTextdrawSetProportional(input.txdid.v, 1)
                  else
                     sampTextdrawSetProportional(input.txdid.v, 0)
                  end
               end
               
               imgui.InputTextMultiline('##txdstringbuff', textbuffer.txdstring, imgui.ImVec2(450, 70),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
               imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8"строки").x) / 2.0)
               if textdata.symbols > 255 then
                  imgui.TextColoredRGB(string.format("{696969}строки: %i символы: {FF0000}%i/255", textdata.lines, textdata.symbols))
               else
                  imgui.TextColoredRGB(string.format("{696969}строки: %i символы: %i/255", textdata.lines, textdata.symbols))
               end

            elseif combobox.txdtype.v == 1 then 
               
               imgui.TextColoredRGB("Модель:")
               imgui.SameLine()
               imgui.PushItemWidth(40)
               if imgui.InputInt('##INPUT_TXDMODEL', input.txdmodel, 0) then
               end
               imgui.PopItemWidth()
               
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Примеры идшников:\nТранспорт Infernus - 411\nСкин рабочего - 27\nДеревянная стена - 19370\nОружие M4 - 356")
               
               imgui.SameLine()
               imgui.TextColoredRGB(" Цвет: ")
               imgui.SameLine()
               imgui.PushItemWidth(40)
               if imgui.InputInt('##INPUT_txdmodelclr1', input.txdmodelclr1, 0) then
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.PushItemWidth(40)
               if imgui.InputInt('##INPUT_txdmodelclr2', input.txdmodelclr2, 0) then
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               if imgui.TooltipButton(u8"random", imgui.ImVec2(65, 25), u8"Случайные цвета") then
                  input.txdmodelclr1.v = math.random(0, 255)
                  input.txdmodelclr2.v = math.random(0, 255)
               end
               
               imgui.TextColoredRGB("Поворот:")
               
               imgui.PushItemWidth(145)
               if imgui.InputFloat('rx##INPUT_txdmodelrx', input.txdmodelrx, 0.1, 200.0) then
               end
               imgui.PopItemWidth()
               
               imgui.PushItemWidth(145)
               if imgui.InputFloat('ry##INPUT_txdmodelry', input.txdmodelry, 0.1, 200.0) then
               end
               imgui.PopItemWidth()
               
               imgui.PushItemWidth(145)
               if imgui.InputFloat('rz##INPUT_txdmodelrz', input.txdmodelrz, 0.1, 200.0) then
               end
               imgui.PopItemWidth()
               
               imgui.TextColoredRGB("Зум:")
               imgui.SameLine()
               imgui.PushItemWidth(145)
               if imgui.InputFloat('##INPUT_txdmodelzoom', input.txdmodelzoom, 0.1, 100.0) then
               end
               imgui.PopItemWidth()
               
            elseif combobox.txdtype.v == 2 then
               imgui.TextColoredRGB("TXDName:TXDSprite")
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Указывать без расширения .txd")
               
               imgui.PushItemWidth(165)
               imgui.InputText('##txdstxdsprite', textbuffer.txdsprite,
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
               imgui.PopItemWidth()
               imgui.SameLine()
               if imgui.TooltipButton(u8"Онлайн браузер", imgui.ImVec2(125, 25), 
               u8"Предпросмотр спрайта онлайн через pawnokit.ru") then
                  --local link = 'explorer "https://encycolorpedia.ru/search?q='..textbuffer.txdsprite.v..'"'
                  os.execute('explorer "https://pawnokit.ru/en/txmngr"')
               end
               imgui.TextColoredRGB("{696969}Предпросмотр спрайтов на текущий момент недоступен!")
               
               imgui.Spacing()
               if imgui.TreeNode(u8"Помощь по TXD спрайтам:") then
                  imgui.TextColoredRGB("textdrawsprites:")
                  imgui.SameLine()
                  imgui.Link("https://www.open.mp/docs/scripting/resources/textdrawsprites", "open.mp")
                  
                  imgui.TextColoredRGB("TXD textures list:")
                  imgui.SameLine()
                  imgui.Link("https://dev.prineside.com/gtasa_samp_game_texture/view/", "dev.prineside.com")
                  
                  imgui.TextColoredRGB("Браузер спрайтов:")
                  imgui.SameLine()
                  imgui.Link("https://pawnokit.ru/ru/txmngr", "pawnokit.ru")
                  imgui.TreePop()
               end
               imgui.Spacing()
               imgui.Spacing()
            end
            
            if combobox.txdtype.v > 0 then
               imgui.TextColoredRGB("{696969}Использовать фон (Box):")
            else
               imgui.Text(u8"Использовать фон (Box):")
            end
            imgui.SameLine()
            if imgui.Checkbox(u8"##txdusebox", checkbox.txdusebox) then
               if checkbox.txdusebox.v then
               else
                  if combobox.txdtype.v > 0 then
                     checkbox.txdusebox.v = true
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Отключение фона недоступно для типа Model и TXD Sprite!", 0x0FF6600)
                  else
                     sampTextdrawSetBoxColorAndSize(input.txdid.v, 0, textbuffer.txdboxcolor.v, input.txdboxsizex.v, input.txdboxsizey.v)
                  end
               end
            end
            
            if checkbox.txdusebox.v then
               imgui.SameLine()
               imgui.Text(u8"    Прозрачный:")
               imgui.SameLine()
               if imgui.Checkbox(u8"##txdsetinivisbox", checkbox.txdsetinivisbox) then
                  textbuffer.txdboxcolor.v = tostring(255)
                  sampTextdrawSetBoxColorAndSize(input.txdid.v, 1, 255, input.txdboxsizex.v, input.txdboxsizey.v)
               end
               
               if tabmenu.txdalign ~= 1 then
                  imgui.TextColoredRGB("{696969}Рекомендуется использовать выравнивание по Левой стороне!")
               end
               
               imgui.TextColoredRGB("Цвет фона:    ")
               imgui.SameLine()
               if imgui.ColorEdit4("##txdboxcolorrgba", input.txdboxcolorrgba, imgui.ColorEditFlags.NoInputs) then
                  local color = tostring(join_argb(input.txdboxcolorrgba.v[4] * 255,
                  input.txdboxcolorrgba.v[1] * 255, input.txdboxcolorrgba.v[2] * 255, input.txdboxcolorrgba.v[3] * 255))
                  textbuffer.txdboxcolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
                  checkbox.txdsetinivisbox.v = false
               end
               imgui.PushItemWidth(75)
               imgui.SameLine()
               if imgui.InputText("##txdboxcolor", textbuffer.txdboxcolor) then
                  checkbox.txdsetinivisbox.v = false
               end
               imgui.PopItemWidth()
               
               imgui.SameLine()
               imgui.Text(u8"Кликабельный:")
               imgui.SameLine()
               if imgui.Checkbox(u8"##txdsetselectable", checkbox.txdsetselectable) then
               end
               if isTrainingSanbox then
                  imgui.SameLine()
                  imgui.Text(u8"Время:")
                  imgui.SameLine()
                  imgui.PushItemWidth(45)
                  imgui.InputInt("##txdshowtime", input.txdshowtime, 0)
                  imgui.PopItemWidth()
                  imgui.SameLine()
                  imgui.TextQuestion("( ? )", u8"Время показа текстдрава в секундах (только для TRAINING-SANDBOX)")
               end
               
               imgui.TextColoredRGB("Размер фона:")
               imgui.SameLine()
               imgui.PushItemWidth(145)
               if imgui.InputFloat('X##INPUT_TXDBOXX', input.txdboxsizex, 0.1, 200.0) then
                  sampTextdrawSetBoxColorAndSize(input.txdid.v, 1, textbuffer.txdboxcolor.v, input.txdboxsizex.v, input.txdboxsizey.v)
               end
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.PushItemWidth(145)
               if imgui.InputFloat('Y##INPUT_TXDBOXY', input.txdboxsizey, 0.1, 200.0) then
                  sampTextdrawSetBoxColorAndSize(input.txdid.v, 1, textbuffer.txdboxcolor.v, input.txdboxsizex.v, input.txdboxsizey.v)
               end
               imgui.PopItemWidth()
            end
            imgui.Spacing()
            if imgui.TooltipButton(u8"Применить", imgui.ImVec2(125, 30), u8"Обновить и применить текущие параметры") then
               imgui.resetIO()
               
               local letColorU32 = join_argb(255, input.txdletcolorrgba.v[1]*255, input.txdletcolorrgba.v[2]*255, input.txdletcolorrgba.v[3]*255)
               local outlineColorU32 = join_argb(255, input.txdoutlinecolorrgba.v[1]*255, input.txdoutlinecolorrgba.v[2]*255, input.txdoutlinecolorrgba.v[3]*255)
               local boxColorU32 = join_argb(255, input.txdboxcolorrgba.v[1]*255, input.txdboxcolorrgba.v[2]*255, input.txdboxcolorrgba.v[3]*255)
               
               if combobox.txdtype.v == 0 then
                  if string.len(textbuffer.txdstring.v) > 1 then
                     if tonumber(textdata.tags) > 0 then 
                        local invalidtag = tonumber(textdata.tags) % 2
                        if invalidtag > 0 then
                           sampAddChatMessage("[SCRIPT]: {FFFFFF}Пропущен символ ~ в теге!", 0x0FF6600)
                        end
                     end
                     sampTextdrawCreate(input.txdid.v, tostring(textbuffer.txdstring.v), input.txdposx.v, input.txdposy.v)
                     sampTextdrawSetLetterSizeAndColor(input.txdid.v, input.txdlettersizex.v, input.txdlettersizey.v, letColorU32)
                  else
                     sampTextdrawCreate(input.txdid.v, "_", input.txdposx.v, input.txdposy.v)
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Укажите текст!", 0x0FF6600)
                  end                  
               elseif combobox.txdtype.v == 1 then
                  if string.len(tostring(input.txdmodel.v)) > 1 then
                     sampTextdrawCreate(input.txdid.v, "_", input.txdposx.v, input.txdposy.v)
                     sampTextdrawSetModelRotationZoomVehColor(input.txdid.v, input.txdmodel.v,
                     input.txdmodelrx.v, input.txdmodelry.v, input.txdmodelrz.v, input.txdmodelzoom.v,
                     input.txdmodelclr1.v, input.txdmodelclr2.v)
                  else
                     sampTextdrawCreate(input.txdid.v, "411", input.txdposx.v, input.txdposy.v)
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Укажите модель!", 0x0FF6600)
                  end
               elseif combobox.txdtype.v == 2 then
                  if string.len(textbuffer.txdsprite.v) > 1 then
                     sampTextdrawCreate(input.txdid.v, "_", input.txdposx.v, input.txdposy.v)
                     sampTextdrawSetString(input.txdid.v, tostring(textbuffer.txdsprite.v))
                     --sampTextdrawCreate(input.txdid.v, tostring(textbuffer.txdsprite.v), input.txdposx.v, input.txdposy.v)
                     sampTextdrawSetLetterSizeAndColor(input.txdid.v, input.txdlettersizex.v, input.txdlettersizey.v, letColorU32)
                  else
                     sampTextdrawCreate(input.txdid.v, "_", input.txdposx.v, input.txdposy.v)
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Укажите спрайт!", 0x0FF6600)
                  end
               end
               
               sampTextdrawSetStyle(input.txdid.v, tonumber(input.txdstyle.v))
               sampTextdrawSetAlign(input.txdid.v, tabmenu.txdalign)
               
               if checkbox.txdsetshadow.v then
                  sampTextdrawSetShadow(input.txdid.v, 1, 255)
               else
                  sampTextdrawSetShadow(input.txdid.v, 0, 255)
               end
               
               if checkbox.txdproportional.v then
                  sampTextdrawSetProportional(input.txdid.v, 1)
               else
                  sampTextdrawSetProportional(input.txdid.v, 0)
               end
               
               --sampTextdrawSetOutlineColor(input.txdid.v, 1, 1)
               sampTextdrawSetOutlineColor(input.txdid.v, 1, outlineColorU32)
               
               if checkbox.txdusebox.v then
                  sampTextdrawSetBoxColorAndSize(input.txdid.v, 1, boxColorU32, input.txdboxsizex.v, input.txdboxsizey.v)
               end
               
               if combobox.txdtype.v == 2 then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Предпросмотр спрайтов на текущий момент недоступен", 0x0FF6600)
               end
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Текст TextDraw "..tostring(input.txdid.v).." был обновлен.", 0x0FF6600)
            end
            imgui.SameLine()
            imgui.Text("    ")
            imgui.SameLine()
            if imgui.TooltipButton(u8"Очистить", imgui.ImVec2(75, 30), u8"Очистить текущий текстдрав") then
               imgui.resetIO()
               sampTextdrawDelete(input.txdid.v)
               
               input.txdposx.v = 50.0
               input.txdposy.v = 250.0
               input.txdlettersizex.v = 0.25
               input.txdlettersizey.v = 1.0
               input.txdstyle.v = 1
               tabmenu.align = 1
               input.txdshowtime.v = -1
               checkbox.txdproportional.v = true
               checkbox.txdsetshadow.v = false
               
               if combobox.txdtype.v == 0 then
                  checkbox.txdusebox.v = false
               end
               input.txdboxsizex.v = 80.0
               input.txdboxsizey.v = 80.0
               
               input.txdmodel.v = 411
               input.txdmodelrx.v = -10.0
               input.txdmodelry.v = 1.0
               input.txdmodelrz.v = -45.0
               input.txdmodelzoom.v = 1.0
               input.txdmodelclr1.v = 1
               input.txdmodelclr2.v = 1
               
               input.txdletcolorrgba = imgui.ImFloat4(1, 1, 1, 1)
               input.txdoutlinecolorrgba = imgui.ImFloat4(0, 0, 0, 0)
               input.txdshadowrgba = imgui.ImFloat4(1, 1, 1, 1)
               input.txdboxcolorrgba = imgui.ImFloat4(1, 1, 1, 1)
               
               if string.len(textbuffer.txdoutlinecolor.v) < 1 then
                  local color = tostring(join_argb(input.txdoutlinecolorrgba.v[4] * 255,
                  input.txdoutlinecolorrgba.v[1] * 255, input.txdoutlinecolorrgba.v[2] * 255, input.txdoutlinecolorrgba.v[3] * 255))
                  textbuffer.txdoutlinecolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
               end
               
               if string.len(textbuffer.txdletcolor.v) < 1 then
                  local color = tostring(join_argb(input.txdletcolorrgba.v[4] * 255,
                  input.txdletcolorrgba.v[1] * 255, input.txdletcolorrgba.v[2] * 255, input.txdletcolorrgba.v[3] * 255))
                  textbuffer.txdletcolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
               end
               
               if string.len(textbuffer.txdboxcolor.v) < 1 then
                  local color = tostring(join_argb(input.txdboxcolorrgba.v[4] * 255,
                  input.txdboxcolorrgba.v[1] * 255, input.txdboxcolorrgba.v[2] * 255, input.txdboxcolorrgba.v[3] * 255))
                  textbuffer.txdboxcolor.v = string.upper(string.sub(bit.tohex(color), 1, 8))
               end
         
               textbuffer.txdstring.v = "This is an ~y~example ~g~textdraw"
               textbuffer.txdsprite.v = "LD_TATT:11dice2"
                  
               sampAddChatMessage("[SCRIPT]: {FFFFFF}TextDraw "..tostring(input.txdid.v).." очищен!", 0x0FF6600)
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Получить", imgui.ImVec2(125, 30), u8"Сдампить параметры с выбранного текстдрава") then
               local id = input.txdid.v
               local style = sampTextdrawGetStyle(id)
               if style < 16 then
                  local posX, posY = sampTextdrawGetPos(id)
                  local align = sampTextdrawGetAlign(id)
                  local prop = sampTextdrawGetProportional(id)
                  local text = sampTextdrawGetString(id)
                  local shadow, shadowColor = sampTextdrawGetShadowColor(id)
                  local outline, outlineColor = sampTextdrawGetOutlineColor(id)
                  local model, rotX, rotY, rotZ, zoom, clr1, clr2 = sampTextdrawGetModelRotationZoomVehColor(id)
                  local letSizeX, letSizeY, letColor = sampTextdrawGetLetterSizeAndColor(id)
                  local box, boxColor, boxSizeX, boxSizeY = sampTextdrawGetBoxEnabledColorAndSize(id)
                  
                  local letColorArgb = string.upper(string.sub(bit.tohex(letColor), 1, 8))
                  local outlineColorArgb = string.upper(string.sub(bit.tohex(outlineColor), 1, 8))
                  local boxColorArgb = string.upper(string.sub(bit.tohex(boxColor), 1, 8))
                  
                  local a, r, g, b = explode_argb(letColor)
                  input.txdletcolorrgba.v[4] = a/255
                  input.txdletcolorrgba.v[1] = r/255
                  input.txdletcolorrgba.v[2] = g/255
                  input.txdletcolorrgba.v[3] = b/255
                  
                  local a, r, g, b = explode_argb(outlineColor)
                  input.txdoutlinecolorrgba.v[4] = a/255
                  input.txdoutlinecolorrgba.v[1] = r/255
                  input.txdoutlinecolorrgba.v[2] = g/255
                  input.txdoutlinecolorrgba.v[3] = b/255
                  
                  local a, r, g, b = explode_argb(boxColor)
                  input.txdboxcolorrgba.v[4] = a/255
                  input.txdboxcolorrgba.v[1] = r/255
                  input.txdboxcolorrgba.v[2] = g/255
                  input.txdboxcolorrgba.v[3] = b/255
                  
                  input.txdposx.v = posX
                  input.txdposy.v = posY
                  input.txdlettersizex.v = letSizeX
                  input.txdlettersizey.v = letSizeY
                  textbuffer.txdletcolor.v = letColorArgb
                  
                  input.txdstyle.v = style
                  tabmenu.align = align
                  if prop > 0 then
                     checkbox.txdproportional.v = true
                  else
                     checkbox.txdproportional.v = false
                  end
                  
                  if shadow > 0 then
                     checkbox.txdsetshadow.v = true
                  else
                     checkbox.txdsetshadow.v = false
                  end
                  
                  if outline > 0 then
                     textbuffer.txdoutlinecolor.v = outlineColorArgb
                  end
                  
                  if box > 0 then
                     checkbox.txdusebox.v = true
                     input.txdboxsizex.v = boxSizeX
                     input.txdboxsizey.v = boxSizeY
                     textbuffer.txdboxcolor.v = boxColorArgb
                  else
                     checkbox.txdusebox.v = false
                  end
                  
                  input.txdmodel.v = model
                  input.txdmodelrx.v = rotX
                  input.txdmodelry.v = rotY
                  input.txdmodelrz.v = rotZ
                  input.txdmodelzoom.v = zoom
                  
                  if clr1 == 65535 then
                     input.txdmodelclr1.v = 1
                     input.txdmodelclr2.v = 1
                  else
                     input.txdmodelclr1.v = clr1
                     input.txdmodelclr2.v = clr2
                  end
                  
                  textbuffer.txdstring.v = tostring(text)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Текстдрав несуществует! Укажите реальный ID", 0x0FF6600)
               end
            end
            
         elseif tabmenu.txd == 2 then
         
            local txdExportFormatsList = {u8"KБ", u8"TextDraw", u8"PlayerTextDraw"}
            imgui.Text(u8"Выберите формат:")
            imgui.PushItemWidth(125)
            imgui.SameLine()
            if imgui.Combo(u8'##txdexport', combobox.txdexport, txdExportFormatsList) then
            end
            imgui.PopItemWidth()
            imgui.Spacing()
            
            local id = input.txdid.v
            local posX, posY = sampTextdrawGetPos(id)
            local align = sampTextdrawGetAlign(id)
            local prop = sampTextdrawGetProportional(id)
            local style = sampTextdrawGetStyle(id)
            local text = sampTextdrawGetString(id)
            local shadow, shadowColor = sampTextdrawGetShadowColor(id)
            local outline, outlineColor = sampTextdrawGetOutlineColor(id)
            local model, rotX, rotY, rotZ, zoom, clr1, clr2 = sampTextdrawGetModelRotationZoomVehColor(id)
            local letSizeX, letSizeY, letColor = sampTextdrawGetLetterSizeAndColor(id)
            local box, boxColor, boxSizeX, boxSizeY = sampTextdrawGetBoxEnabledColorAndSize(id)
            local letColorArgb = string.upper(string.sub(bit.tohex(letColor), 1, 8))
            local shadowColorArgb = string.upper(string.sub(bit.tohex(shadowColor), 1, 8))
            local outlineColorArgb = string.upper(string.sub(bit.tohex(outlineColor), 1, 8))
            local boxColorArgb = string.upper(string.sub(bit.tohex(boxColor), 1, 8))
            local letColorRgb = string.sub(bit.tohex(letColor), 3, 8)
            local letColorAbgr = tostring(string.sub(letColorArgb, 1, 2)..string.sub(letColorArgb, 7, 8)..string.sub(letColorArgb, 5, 6)..string.sub(letColorArgb, 3, 4))
            local outlineColorAbgr = tostring(string.sub(outlineColorArgb, 1, 2)..string.sub(outlineColorArgb, 7, 8)..string.sub(outlineColorArgb, 5, 6)..string.sub(outlineColorArgb, 3, 4))
            local boxColorAbgr = tostring(string.sub(boxColorArgb, 1, 2)..string.sub(boxColorArgb, 7, 8)..string.sub(boxColorArgb, 5, 6)..string.sub(boxColorArgb, 3, 4))
            local showtime = input.txdshowtime.v
            local type = combobox.txdtype.v
            local clickable = checkbox.txdsetselectable.v and 1 or 0 
            -- on TRAINING reverse format is used for align (left <=> right)
            local reversedAlign = align
            if align == 1 then 
               reversedAlign = 3
            elseif align == 3 then
               reversedAlign = 1
            end
            
            -- Convert color TAGS to RGB
            -- https://www.open.mp/docs/scripting/resources/colorslist
            local tagTextRGB = text
            tagTextRGB = tagTextRGB:gsub("~w~","{FFFFFF}~w~")
            tagTextRGB = tagTextRGB:gsub("~s~","{FFFFFF}~s~")
            tagTextRGB = tagTextRGB:gsub("~r~","{FF0000}~r~")
            tagTextRGB = tagTextRGB:gsub("~g~","{008000}~g~")
            tagTextRGB = tagTextRGB:gsub("~b~","{0000FF}~b~")
            tagTextRGB = tagTextRGB:gsub("~y~","{FFFF00}~y~")
            tagTextRGB = tagTextRGB:gsub("~p~","{EE82EE}~p~")
            tagTextRGB = tagTextRGB:gsub("~l~","{363636}~l~")
            tagTextRGB = tagTextRGB:gsub("~n~","{FFFFFF}~n~\n")

            if combobox.txdexport.v == 0 then
               --local textdata = {lines = 0, symbols}
               --textdata.symbols = math.floor(string.len(textbuffer.txdcbstring.v)/2) --RU
               textdata.symbols = math.floor(string.len(textbuffer.txdcbstring.v))
               for s in string.gmatch(textbuffer.txdcbstring.v, "\n" ) do
                  textdata.lines = textdata.lines + 1
               end
               imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(3, 3))
               if combobox.txdtype.v > 0 then
                  imgui.TextColoredRGB(("Показать текстдрав (бокс type %i):"):format(combobox.txdtype.v))
                  imgui.TextNotify(("{696969}%i"):format(id), "<slot 0-99>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(posX), "<posX>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(posY), "<posY>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(boxSizeX), "<sizeX>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(boxSizeY), "<sizeY>")
                  imgui.SameLine()
                  imgui.TextNotify(("{CDCDCD}0x%s"):format(boxColorAbgr), "<boxColor> 0xFFBBGGRR")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(reversedAlign), u8"<aligment> выравнивание (1 - право | 2 - центр | 3 - лево)")
                  if type == 0 then
                     imgui.SameLine()
                     imgui.TextNotify(("{FF6600}%i"):format(type), u8"*<type 0/1/2> (0 - обычный бокс | 1 - модель(скин, тс, объект, оружие) | 2 - TXD спрайт)")
                  elseif type == 1 then
                     imgui.SameLine()
                     imgui.TextNotify(("{FF6600}%i"):format(type), u8"*<type 0/1/2> (0 - обычный бокс | 1 - модель(скин, тс, объект, оружие) | 2 - TXD спрайт)")
                     imgui.SameLine()
                     imgui.TextNotify(("{696969}%i"):format(model), "<modelid>")
                     imgui.SameLine()
                     imgui.TextNotify(("{FF6600}%.2f"):format(rotX), "<rotX>")
                     imgui.SameLine()
                     imgui.TextNotify(("{FF6600}%.2f"):format(rotY), "<rotY>")
                     imgui.SameLine()
                     imgui.TextNotify(("{FF6600}%.2f"):format(rotZ), "<rotZ>")
                     imgui.SameLine()
                     imgui.TextNotify(("{FF6600}%.2f"):format(zoom), "<zoom>")
                     imgui.SameLine()
                     imgui.TextNotify(("{696969}%i"):format(clr1), "<color1> 0-255")
                     imgui.SameLine()
                     imgui.TextNotify(("{696969}%i"):format(clr2), "<color2> 0-255")
                  elseif type == 2 then
                     imgui.SameLine()
                     imgui.TextNotify(("{FF6600}%i"):format(type), u8"*<type 0/1/2> (0 - обычный бокс | 1 - модель(скин, тс, объект, оружие) | 2 - TXD спрайт)")
                  end
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(clickable), "<clickable 0/1>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(showtime), "<showTime -1>")
                  if type == 2 then
                     imgui.SameLine()
                     imgui.TextNotify(("{FFFFFF}%s"):format(textbuffer.txdsprite.v), u8"<spriteName TXDName:TXDSprite>")
                  end
               else
                  imgui.TextColoredRGB("Показать текстдрав (текст):")
                  imgui.TextNotify(("{696969}%i"):format(id), "<slot 0-99>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(posX), "<posX>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(posY), "<posY>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(boxSizeX), "<sizeX>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(boxSizeY), "<sizeY>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(style), "<style(font 0-3)>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(letSizeX), "<letsizeX>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%.2f"):format(letSizeY), "<letsizeY>")
                  imgui.SameLine()
                  imgui.TextNotify(("{CDCDCD}0x%s"):format(letColorAbgr), "<textColor> 0xFFBBGGRR")
                  imgui.SameLine()
                  imgui.TextNotify(("{CDCDCD}0x%s"):format(outlineColorAbgr), "<backgroundColor> 0xFFBBGGRR")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(outline), "<outline>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(shadow), "<shadow>")
                  imgui.SameLine()
                  
                  imgui.TextNotify(("{FF6600}%i"):format(reversedAlign), u8"<aligment> выравнивание (1 - право | 2 - центр | 3 - лево)")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(clickable), "<clickable 0/1>")
                  imgui.SameLine()
                  imgui.TextNotify(("{FF6600}%i"):format(showtime), "<showTime -1>")
                  if not text:match("_") then
                     imgui.TextNotify(("{%s}%s"):format(letColorRgb, tagTextRGB), "<text (max 255)>")
                  end
               end
               imgui.PopStyleVar()
               imgui.Spacing()
               imgui.Spacing()
               imgui.Spacing()
               -- imgui.InputTextMultiline('##txdcbstringbuff', textbuffer.txdcbstring, imgui.ImVec2(450, 50),
               -- imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
               -- imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8"строки").x) / 2.0)
               -- imgui.Text(string.format(u8"строки: %i символы: %i/255", textdata.lines, textdata.symbols))
               imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2, 2))
               imgui.TextColoredRGB("Координаты указывайте на основе разрешения 640х480 (центр: 320x240)")
               imgui.TextColoredRGB("Цвет для КБ указывается в формате 0xFF{0000FF}BB{008000}GG{FF0000}RR{CDCDCD} (0xFF<инвертируйте ваш hex код>)")
               if imgui.TreeNode(u8"Дополнительная информация по параметрам:") then
                  imgui.TextColoredRGB("{FF6600}<aligment>{FFFFFF} - выравнивание (1 - право | 2 - центр | 3 - лево)")
                  imgui.TextColoredRGB("{FF6600}<font 0-3>{FFFFFF} - шрифты для текста, 4 для моделек, 5 для спрайтов")
                  imgui.TextColoredRGB("{FF6600}<*type> 0{FFFFFF} - обычный бокс | 1 - модель(скин, тс, объект, оружие) | 2 - TXD спрайт")
                  imgui.TextColoredRGB("{FF6600}<showTime -1>{FFFFFF} - время показа текстдрава в секундах (-1 не использовать)")
                  imgui.TreePop()
               end
               imgui.PopStyleVar()
               imgui.Spacing()
               imgui.Spacing()
               imgui.Spacing()
               imgui.Text(u8"Помощь по системе текстдравов:")
               imgui.SameLine()
               imgui.Link("https://forum.training-server.com/d/19134-pomosch-v-textdraw", "https://forum.training-server.com/")
               
               imgui.Spacing()
               local exportText = ""
               if combobox.txdtype.v > 0 then
                  exportText = string.format("%i %.2f %.2f %.2f %.2f 0x%s %i", 
                  id, posX, posY, boxSizeX, boxSizeY, boxColorArgb, reversedAlign)
                  if type == 0 then
                     exportText = string.format("%s %i", exportText, type)
                  elseif type == 1 then
                     exportText = string.format("%s %i %i %.2f %.2f %.2f %.2f %i %i", 
                     exportText, type, model, rotX, rotY, rotZ, zoom, clr1, clr2)
                  elseif type == 2 then
                     exportText = string.format("%s %i", exportText, type)
                  end
                  exportText = string.format("%s %i %i", exportText, clickable, showtime)
                  if type == 2 then
                     exportText = string.format("%s %s", exportText, textbuffer.txdsprite.v)
                  end
               else
                  exportText = string.format("%i %.2f %.2f %.2f %.2f %i %.2f %.2f 0x%s 0x%s %i %i %i %i %i", 
                  id, posX, posY, boxSizeX, boxSizeY, style, letSizeX, letSizeY, letColorArgb, outlineColorArgb, 
                  outline, shadow, reversedAlign, clickable, showtime, text)
               end
                  
               if imgui.TooltipButton(u8"Скопировать", imgui.ImVec2(125, 30), u8"Скопировать в буффер обмена") then
                  setClipboardText(exportText)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Параметры текстдрава скопированы в буффер обмена в формате КБ", 0x0FF6600)
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Сохранить в файл", imgui.ImVec2(125, 30), u8"Сохранить в текстовый файл") then
                  local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//export//export_txdtocb.txt"
                  local file = io.open(filepath, "w")
                  file:write("// MappingTollkit: Exported TXDtoCB format:\n")
                  if type == 0 then
                     file:write("// text: <slot 0-99> <posX> <posY> <sizeX> <sizeY> <font> <letterSizeX> <letterSizeY> <textColor> <backColor> <outline> <shadow> <aligment> <clickable 0/1> <showTime -1> <text 255>\n")
                     file:write("// box: <slot 0-99> <posX> <posY> <sizeX> <sizeY> <boxColor 0xFFBBGGRR> <aligment> *<type 0/1/2> ... <clickable 0/1> <showTime -1>\n")
                     file:write("// <*type> 0 - обычный бокс | 1 - модель(скин, тс, объект, оружие) | 2 - TXD спрайт\n")
                  elseif type == 1 then
                     file:write("// <type> 1 ... <modelid> <rx> <ry> <rz> <zoom 1.0> *<color1> <color2> <clickable 0/1> <showTime -1>\n")
                  elseif type == 2 then
                     file:write("// <type> 2 ... <clickable 0/1> <showTime -1> <spriteName TXDName:TXDSprite>\n")
                  end
                  file:write(exportText)
                  file:write("\n\n")
                  file:close()
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Текстдрав был сохранен в /moonloader/resource/mappingtoolkit/export/export_txdtocb.txt", 0x0FF6600)
               end
            
            elseif combobox.txdexport.v == 1 then
               imgui.TextColoredRGB(('{CDCDCD}new Text:{696969}TextDraw%i;{CDCDCD}'):format(id))
               if text:len() > 32 then
                  imgui.TextColoredRGB(('{696969}TextDraw%i{CDCDCD} = TextDrawCreate({FF6600}%.2f, %.2f{CDCDCD},'):format(id, posX, posY))
                  imgui.TextColoredRGB(('{%s}"%s{FFFFFF}");'):format(letColorRgb, tagTextRGB))
               else
                  imgui.TextColoredRGB(('{696969}TextDraw%i{CDCDCD} = TextDrawCreate({FF6600}%.2f, %.2f{CDCDCD}, {696969}"%s"{CDCDCD});'):format(id, posX, posY, text))
               end
               --imgui.TextColoredRGB(('TextDrawSetString({696969}Textdraw%i{CDCDCD}, {FF6600}"%s"{CDCDCD});'):format(id, text))
               imgui.TextColoredRGB(("TextDrawLetterSize({696969}Textdraw%i{CDCDCD}, {FF6600}%.2f, %.2f{CDCDCD});"):format(id, letSizeX, letSizeY))
               imgui.TextColoredRGB(("TextDrawColor({696969}Textdraw%i{CDCDCD}, {FF6600}0x%s{CDCDCD});"):format(id, letColorArgb))
               imgui.TextColoredRGB(("TextDrawAlignment({696969}Textdraw%i{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, align))
               imgui.TextColoredRGB(("TextDrawFont({696969}Textdraw%i{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, style))
               imgui.TextColoredRGB(("TextDrawSetOutline({696969}Textdraw%i{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, outline))
               imgui.TextColoredRGB(("TextDrawSetProportional({696969}Textdraw%i{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, prop))
               imgui.TextColoredRGB(("TextDrawSetShadow({696969}Textdraw%i{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, shadow))
               if checkbox.txdusebox.v then
                  imgui.TextColoredRGB(("TextDrawUseBox({696969}Textdraw%i{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, box))
                  imgui.TextColoredRGB(("TextDrawTextSize({696969}Textdraw%i{CDCDCD}, {FF6600}%.2f, %.2f{CDCDCD});"):format(id, boxSizeX, boxSizeY))
                  imgui.TextColoredRGB(("TextDrawBoxColor({696969}Textdraw%i{CDCDCD}, {FF6600}0x%s{CDCDCD});"):format(id, boxColorArgb))
                  imgui.TextColoredRGB(("TextDrawBackgroundColor({696969}Textdraw%i{CDCDCD}, {FF6600}0x%s{CDCDCD});"):format(id, shadowColorArgb))    
               end
               if combobox.txdtype.v == 1 then
                  imgui.TextColoredRGB(("TextDrawSetPreviewModel({696969}Textdraw%i{CDCDCD}, {FF6600}%i{CDCDCD}{CDCDCD});"):format(id, model))
                  imgui.TextColoredRGB(("TextDrawSetPreviewRot({696969}Textdraw%i{CDCDCD}, {FF6600}%f, %f, %f, %f{CDCDCD});"):format(id, rotX, rotY, rotZ, zoom))
                  imgui.TextColoredRGB(("TextDrawSetPreviewVehCol({696969}Textdraw%i{CDCDCD}, {FF6600}%i, %i{CDCDCD});"):format(id, clr1, clr2))
               end
               if checkbox.txdsetselectable.v then
                  imgui.TextColoredRGB(("TextDrawSetSelectable({696969}Textdraw%i{CDCDCD}, {FF6600}%i{CDCDCD});"):format(id, clickable))
               end
               
               imgui.Spacing()
               imgui.Text(u8"Список функций для работы с TextDraw:")
               imgui.SameLine()
               imgui.Link("https://www.open.mp/docs/scripting/functions/TextDrawCreate", "open.mp")
               
               imgui.Spacing()
               if imgui.TooltipButton(u8"Сохранить в файл", imgui.ImVec2(125, 30), u8"Сохранить в текстовый файл") then
                  local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//export//export_textdraw.pwn"
                  local file = io.open(filepath, "w")
                  file:write(('new Text:TextDraw%i;\n'):format(id))
                  if text:len() > 32 then
                     file:write(('TextDraw%i = TextDrawCreate(%.2f, %.2f,'):format(id, posX, posY))
                     file:write(('"%s");\n'):format(text))
                  else
                     file:write(('TextDraw%i = TextDrawCreate(%.2f, %.2f, "%s");\n'):format(id, posX, posY, text))
                  end
                  --file:write(('TextDrawSetString(Textdraw%i, "%s");\n'):format(id, text))
                  file:write(("TextDrawLetterSize(Textdraw%i, %.2f, %.2f);\n"):format(id, letSizeX, letSizeY))
                  file:write(("TextDrawColor(Textdraw%i, 0x%s);\n"):format(id, letColorArgb))
                  file:write(("TextDrawAlignment(Textdraw%i, %d);\n"):format(id, align))
                  file:write(("TextDrawFont(Textdraw%i, %d);\n"):format(id, style))
                  file:write(("TextDrawSetOutline(Textdraw%i, %d);\n"):format(id, outline))
                  file:write(("TextDrawSetProportional(Textdraw%i, %d);\n"):format(id, prop))
                  file:write(("TextDrawSetShadow(Textdraw%i, %d);\n"):format(id, shadow))
                  if checkbox.txdusebox.v then
                     file:write(("TextDrawUseBox(Textdraw%i, %d);\n"):format(id, box))
                     file:write(("TextDrawTextSize(Textdraw%i, %.2f, %.2f);\n"):format(id, boxSizeX, boxSizeY))
                     file:write(("TextDrawBoxColor(Textdraw%i, 0x%s);\n"):format(id, boxColorArgb))
                     file:write(("TextDrawBackgroundColor(Textdraw%i, 0x%s);\n"):format(id, shadowColorArgb))    
                  end
                  if combobox.txdtype.v == 1 then
                     file:write(("TextDrawSetPreviewModel(Textdraw%i, %i);\n"):format(id, model))
                     file:write(("TextDrawSetPreviewRot(Textdraw%i, %f, %f, %f, %f);\n"):format(id, rotX, rotY, rotZ, zoom))
                     file:write(("TextDrawSetPreviewVehCol(Textdraw%i, %i, %i);\n"):format(id, clr1, clr2))
                  end
                  if checkbox.txdsetselectable.v then
                     file:write(("TextDrawSetSelectable(Textdraw%i, %i);\n"):format(id, clickable))
                  end
                  file:write("\n")
                  file:close()
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Текстдрав был сохранен в /moonloader/resource/mappingtoolkit/export/export_textdraw.pwn", 0x0FF6600)
               end
            elseif combobox.txdexport.v == 2 then
               imgui.TextColoredRGB(('{CDCDCD}new PlayerText:{696969}PlayerTextDraw%i[MAX_PLAYERS];{CDCDCD}'):format(id))
               if text:len() > 32 then
                  imgui.TextColoredRGB(('{696969}PlayerTextDraw%i[playerid]{CDCDCD} = CreatePlayerTextDraw({FF6600}playerid, %.2f, %.2f{CDCDCD},'):format(id, posX, posY))
                  imgui.TextColoredRGB(('{%s}"%s{FFFFFF}");'):format(letColorRgb, tagTextRGB))
               else
                  imgui.TextColoredRGB(('{696969}PlayerTextDraw%i[playerid]{CDCDCD} = CreatePlayerTextDraw({FF6600}playerid, %.2f, %.2f{CDCDCD}, {696969}"%s"{CDCDCD});'):format(id, posX, posY, text))
               end
               
               imgui.TextColoredRGB(("PlayerTextDrawLetterSize({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%.2f, %.2f{CDCDCD});"):format(id, letSizeX, letSizeY))
               imgui.TextColoredRGB(("PlayerTextDrawColor({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}0x%s{CDCDCD});"):format(id, letColorArgb))
               imgui.TextColoredRGB(("PlayerTextDrawAlignment({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, align))
               imgui.TextColoredRGB(("PlayerTextDrawFont({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, style))
               imgui.TextColoredRGB(("PlayerTextDrawSetOutline({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, outline))
               imgui.TextColoredRGB(("PlayerTextDrawSetProportional({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, prop))
               imgui.TextColoredRGB(("PlayerTextDrawSetShadow({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, shadow))
               if checkbox.txdusebox.v then
                  imgui.TextColoredRGB(("PlayerTextDrawUseBox({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%d{CDCDCD});"):format(id, box))
                  imgui.TextColoredRGB(("PlayerTextDrawTextSize({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%.2f, %.2f{CDCDCD});"):format(id, boxSizeX, boxSizeY))
                  imgui.TextColoredRGB(("PlayerTextDrawBoxColor({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}0x%s{CDCDCD});"):format(id, boxColorArgb))
                  imgui.TextColoredRGB(("PlayerTextDrawBackgroundColor({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}0x%s{CDCDCD});"):format(id, shadowColorArgb))    
               end
               if combobox.txdtype.v == 1 then
                  imgui.TextColoredRGB(("PlayerTextDrawSetPreviewModel({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%i{CDCDCD}{CDCDCD});"):format(id, model))
                  imgui.TextColoredRGB(("PlayerTextDrawSetPreviewRot({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%f, %f, %f, %f{CDCDCD});"):format(id, rotX, rotY, rotZ, zoom))
                  imgui.TextColoredRGB(("PlayerTextDrawSetPreviewVehCol({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%i, %i{CDCDCD});"):format(id, clr1, clr2))
               end
               if checkbox.txdsetselectable.v then
                  imgui.TextColoredRGB(("PlayerTextDrawSetSelectable({FF6600}playerid, {696969}PlayerTextDraw%i[playerid]{CDCDCD}, {FF6600}%i{CDCDCD});"):format(id, clickable))
               end
               
               imgui.Spacing()
               imgui.Text(u8"Список функций для работы с PlayerTextDraw:")
               imgui.SameLine()
               imgui.Link("https://sampwiki.blast.hk/wiki/CreatePlayerTextDraw", "sampwiki.blast.hk")
               
               imgui.Spacing()
               if imgui.TooltipButton(u8"Сохранить в файл", imgui.ImVec2(125, 30), u8"Сохранить в текстовый файл") then
                  local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//export//export_playertextdraw.pwn"
                  local file = io.open(filepath, "w")
                  file:write(('new PlayerText:PlayerTextDraw%i[MAX_PLAYERS];\n'):format(id))
                  if text:len() > 32 then
                     file:write(('PlayerTextDraw%i[playerid] = PlayerTextDrawCreate(playerid, %.2f, %.2f,'):format(id, posX, posY))
                     file:write(('"%s");\n'):format(text))
                  else
                     file:write(('PlayerTextDraw%i[playerid] = PlayerTextDrawCreate(playerid, %.2f, %.2f, "%s");\n'):format(id, posX, posY, text))
                  end
                  
                  file:write(("PlayerTextDrawLetterSize(playerid, PlayerTextDraw%i[playerid], %.2f, %.2f);\n"):format(id, letSizeX, letSizeY))
                  file:write(("PlayerTextDrawColor(playerid, PlayerTextDraw%i[playerid], 0x%s);\n"):format(id, letColorArgb))
                  file:write(("PlayerTextDrawAlignment(playerid, PlayerTextDraw%i[playerid], %d);\n"):format(id, align))
                  file:write(("PlayerTextDrawFont(playerid, PlayerTextDraw%i[playerid], %d);\n"):format(id, style))
                  file:write(("PlayerTextDrawSetOutline(playerid, PlayerTextDraw%i[playerid], %d);\n"):format(id, outline))
                  file:write(("PlayerTextDrawSetProportional(playerid, PlayerTextDraw%i[playerid], %d);\n"):format(id, prop))
                  file:write(("PlayerTextDrawSetShadow(playerid, PlayerTextDraw%i[playerid], %d);\n"):format(id, shadow))
                  if checkbox.txdusebox.v then
                     file:write(("PlayerTextDrawUseBox(playerid, PlayerTextDraw%i[playerid], %d);\n"):format(id, box))
                     file:write(("PlayerTextDrawTextSize(playerid, PlayerTextDraw%i[playerid], %.2f, %.2f);\n"):format(id, boxSizeX, boxSizeY))
                     file:write(("PlayerTextDrawBoxColor(playerid, PlayerTextDraw%i[playerid], 0x%s);\n"):format(id, boxColorArgb))
                     file:write(("PlayerTextDrawBackgroundColor(playerid, PlayerTextDraw%i[playerid], 0x%s);\n"):format(id, shadowColorArgb))    
                  end
                  if combobox.txdtype.v == 1 then
                     file:write(("PlayerTextDrawSetPreviewModel(playerid, PlayerTextDraw%i[playerid], %i);\n"):format(id, model))
                     file:write(("PlayerTextDrawSetPreviewRot(playerid, PlayerTextDraw%i[playerid], %f, %f, %f, %f);\n"):format(id, rotX, rotY, rotZ, zoom))
                     file:write(("PlayerTextDrawSetPreviewVehCol(playerid, PlayerTextDraw%i[playerid], %i, %i);\n"):format(id, clr1, clr2))
                  end
                  if checkbox.txdsetselectable.v then
                     file:write(("PlayerTextDrawSetSelectable(playerid, PlayerTextDraw%i[playerid], %i);\n"):format(id, clickable))
                  end
                  file:write("\n")
                  file:close()
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Текстдрав был сохранен в /moonloader/resource/mappingtoolkit/export/export_playertextdraw.pwn", 0x0FF6600)
               end
            end
            
            imgui.SameLine()
            if imgui.TooltipButton(u8"Открыть папку Export", imgui.ImVec2(150, 30), u8"Открыть в проводнике папку с сохраннеными текстдравами") then
               os.execute('explorer '..getGameDirectory().."\\moonloader\\resource\\mappingtoolkit\\export")
            end
            
         elseif tabmenu.txd == 3 then      
            
            local cursorPosX, cursorPosY = getCursorPos()
            local pos_x, pos_y = getScreenResolution()
            
            imgui.TextColoredRGB("Позиция курсора: {3f70d6}X: "..cursorPosX.." {e0364e}Y: "..cursorPosY)
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Позиция курсора:\n< X - width (ширина) >, ^ Y - height (высота) v")
            
            imgui.Text(u8"Разрешение: "..pos_x.."x"..pos_y)
            imgui.Text(u8"Центральная точка: "..pos_x/2 .."x".. pos_y/2 .." (320x240)")
            
            if LastData.lastClickedTextdrawId then
               imgui.Text(u8"Последний нажатый текстдрав: "..LastData.lastClickedTextdrawId)
            end
            if LastData.lastShowedTextdrawId then
               imgui.Text(u8"Последний показанный текстдрав: "..LastData.lastShowedTextdrawId)
            end
            imgui.Checkbox(u8'Выводить параметры текстдрава в чат, при его показе', checkbox.txdparamsonshow)
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Выводит параметры текстдрава при его отображенни игроку")
            
            imgui.Checkbox(u8'Выводить параметры текстдрава в чат, при нажатии на него', checkbox.txdparamsonclick)
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Выводит параметры текстдрава при нажатии на него")
            
            if imgui.Checkbox(u8'Отображать ID текстдравов', checkbox.showtextdrawsid) then
               for id = 1, 2048 do
                  if sampTextdrawIsExists(id) then
                     local x, y = sampTextdrawGetPos(id)
                     local xw, yw = convertGameScreenCoordsToWindowScreenCoords(x, y)
                     renderFontDrawText(fonts.objectsrenderfont, 'ID: ' .. id, xw, yw, -1)
                  end
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Отображает рядом с текстдравом его ID")
            
            if imgui.Checkbox(u8'Скрыть все текстдравы', checkbox.hidealltextdraws) then
               for i = 0, 2048 do
                  sampTextdrawDelete(i)
               end
               if checkbox.hidealltextdraws.v then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Sсе текстдравы были скрыты!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Скрывает все текстдравы визуально для вас")
            
            imgui.Text(u8"Кликнуть текстдрав по ID: ")
            imgui.PushItemWidth(40)
            if imgui.InputInt('ID##INPUT_txdclickid', input.txdclickid, 0) then
               if input.txdclickid.v < 0 and input.txdclickid.v > 2048 then
                  input.txdclickid.v = 0
               end
            end
            imgui.SameLine()
            if imgui.Button(u8"Нажать", imgui.ImVec2(100, 25)) then
               sampSendClickTextdraw(input.txdclickid.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Удалить", imgui.ImVec2(100, 25)) then
               sampTextdrawDelete(input.txdclickid.v)
            end
            
            imgui.Spacing()
            imgui.Text(u8"Онлайн сервисы:")
            if imgui.TooltipButton(u8"Конвертер символов (Онлайн)", imgui.ImVec2(200, 25),
            u8"Данный сервис предназначен для перевода кириллических (русских) GameText, TextDraw символов в поддерживаемый GTA-русификаторами формат.")
            then
               local link = 'explorer "https://pawnokit.ru/ru/text_conv"'
               os.execute(link)
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"TextDrawEditor (Онлайн)", imgui.ImVec2(200, 25),
            u8"Онлайн редактор текстдравов для SA:MP")
            then
               local link = 'explorer "https://leonardo541.github.io/TextDrawEditor/"'
               os.execute(link)
            end
            --imgui.SameLine()
            --if imgui.Button(u8"Включить курсор", imgui.ImVec2(100, 25)) then
               --showCursor(true, true) -- showCursor(bool show, [bool lockControls])
               --sampToggleCursor(true) - bugged
            --end
         end
         
      elseif tabmenu.settings == 6 then
         imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8"1").x) / 2.2)
         if tabmenu.effects == 1 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"1", imgui.ImVec2(100, 25)) then tabmenu.effects = 1 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"1", imgui.ImVec2(100, 25)) then tabmenu.effects = 1 end
         end
         imgui.SameLine()
         if tabmenu.effects == 2 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"2", imgui.ImVec2(100, 25)) then tabmenu.effects = 2 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"2", imgui.ImVec2(100, 25)) then tabmenu.effects = 2 end
         end
         
         -- changes the spacings so that all the elements can fit
         imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(4, 4))
         
         if tabmenu.effects == 1 then
            if imgui.ToggleButton(u8'Тени окружающего мира', checkbox.shadows) then
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
            
            if imgui.ToggleButton(u8'Пост-обработка, эффекты добавляемые после рендеринга (PostFX)', checkbox.postfx) then
               if checkbox.postfx.v then
                  memory.write(7358318, 1448280247, 4, false)
                  memory.write(7358314, -988281383, 4, false)
               else
                  memory.write(7358318, 2866, 4, false)
                  memory.write(7358314, -380152237, 4, false)
               end
            end
            
            if imgui.ToggleButton(u8'Анизотропная фильтрация текстур (Убирает рябь на тестурах)', checkbox.aniso) then
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
            
            if imgui.ToggleButton(u8'Blur эффект - Размытость при ускореннии транспорта', checkbox.blur) then
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
            
            if imgui.ToggleButton(u8'Sun эффект - Солнце из одиночной игры', checkbox.sunfix) then
               if checkbox.sunfix.v then
                  memory.hex2bin("E865041C00", 0x53C136, 5) 
                  memory.protect(0x53C136, 5, memory.unprotect(0x53C136, 5))
               else
                  memory.fill(0x53C136, 0x90, 5, true)
               end
            end
            
            if imgui.ToggleButton(u8'Nightvision - Эффект ночного зрения', checkbox.nightvision) then
               if checkbox.nightvision.v then
                  setNightVision(true)
               else
                  setNightVision(false)
               end
            end
            
            if imgui.ToggleButton(u8'InfraredVision - Эффект инфракрасного зрения', checkbox.infraredvision) then
               if checkbox.infraredvision.v then
                  setInfraredVision(true)
               else
                  setInfraredVision(false)
               end
            end
            
            -- https://github.com/JuniorDjjr/GraphicsTweaker/tree/master/GraphicsTweaker
            if imgui.ToggleButton(u8'LightMap - Засветлить всю карту', checkbox.lightmap) then
               if checkbox.lightmap.v then
                  memory.fill(0x73558B, 0x90, 2, true)
               else
                  memory.write(0x73558B, 15476, 2, true)
               end
            end
            
            -- By 4elove4ik
            if imgui.ToggleButton(u8'NoWater - Отключает воду (Визуально)', checkbox.nowater) then
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
            
            if imgui.ToggleButton(u8'NoUnderwater - Откл. все эффекты под водой', checkbox.underwater) then
               if checkbox.underwater.v then
                  DisableUnderWaterEffects(true)
               else
                  DisableUnderWaterEffects(false)
               end
            end
            
            if imgui.ToggleButton(u8'Vehicle LODs - Отображение лодов транспорта', checkbox.vehloads) then
               if checkbox.vehloads.v then
                  memory.write(5425646, 1, 1, false)
               else
                  memory.write(5425646, 0, 1, false)
               end
            end
            imgui.Spacing()
            imgui.Spacing()
            
         elseif tabmenu.effects == 2 then
            -- All effects finded by Gorskin
            if imgui.ToggleButton(u8'Отключить все эффекты игры (дыма, пыли, тени)', checkbox.noeffects) then
               if checkbox.noeffects.v then
                  memory.fill(0x53EAD3, 0x90, 5, true) 
               else
                  memory.hex2bin("E898F6FFFF", 0x53EAD3, 5) 
               end
            end
            
            if imgui.ToggleButton(u8'Отрисовка травы и растений из одиночной игры', checkbox.grassfix) then
               if checkbox.grassfix.v then
                  memory.hex2bin("E8420E0A00", 0x53C159, 5) 
                  memory.protect(0x53C159, 5, memory.unprotect(0x53C159, 5)) 
               else
                  memory.fill(0x53C159, 0x90, 5, true)
               end
            end
            
            if imgui.ToggleButton(u8'Отключить дым из труб и огонь с факелов', checkbox.nofactorysmoke) then
               if checkbox.nofactorysmoke.v then
                  memory.fill(0x4A125D, 0x90, 8, true)
                  writeMemory(0x539F00, 4, 0x0024C2, true)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Отключен дым из труб на заводах, и прочие эффекты по типу факелов, горящих черепов. (Требуется рестрим)", 0x0FF6600)
               else
                  memory.hex2bin('8B4E08E88B900000', 0x4A125D, 8)
                  writeMemory(0x539F00, 4, 0x6C8B5551, true)
               end
            end
            
            if imgui.ToggleButton(u8'Отключить эффекты огоня (Визуально)', checkbox.nofire) then
               if checkbox.nofire.v then
                  writeMemory(0x539F00, 4, 0x0024C2, true)
               else
                  writeMemory(0x539F00, 4, 51, true)
               end
            end
            
            if imgui.ToggleButton(u8'Отключить эффект взрыва (Не убирает тряску камеры и урон)', checkbox.noexplosions) then
               if checkbox.noexplosions.v then
                  writeMemory(0x736A50, 1, 0xC3, true) 
               else
                  writeMemory(0x736A50, 1, 0x83, true)
               end
            end
            
            if imgui.ToggleButton(u8'Отключить кровь на земле', checkbox.nobloodonearth) then
               if checkbox.nobloodonearth.v then
                  memory.fill(0x49EB23, 0x90, 2, true)
               else
                  memory.hex2bin('EB05', 0x49EB23, 2) 
               end
            end
            
            if imgui.ToggleButton(u8'Отключить очки ночного видения и тепловизор', checkbox.novision) then
               if checkbox.novision.v then
                  memory.fill(0x634F67, 0x90, 5, true)
               else
                  memory.hex2bin('E874EBFAFF', 0x634F67, 5)
               end
            end
            
            if imgui.ToggleButton(u8'Отключить следы от шин при торможении', checkbox.notiretracks) then
               if checkbox.notiretracks.v then
                  writeMemory(0x720B22, 1, -1, true)
               else
                  writeMemory(0x720B22, 1, 100, true)
               end
            end
            
            if imgui.ToggleButton(u8'Отключить облака', checkbox.noclouds) then
               if checkbox.noclouds.v then
                  --writeMemory(0x70EAB0, 1, 0x83, true)
                  memory.setfloat(0x716642, 100000.0)
                  memory.setfloat(0x716655, 100000.0)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}При использовании модов облака не исчезнут!", 0x0FF6600)
               else
                  memory.setfloat(0x716642, 1000.0)
                  memory.setfloat(0x716655, 1000.0)
               end
            end
            
            if imgui.ToggleButton(u8'Отключить эффект ветра', checkbox.nosnow) then
               writeMemory(0x506667+1, 4, checkbox.nosnow.v and 0xB72914 or 0x8E26DC, true)
               writeMemory(0x505BEB+1, 4, checkbox.nosnow.v and 0xB72914 or 0x8E26DC, true)
               writeMemory(0x505377+2, 4, checkbox.nosnow.v and 0xB72914 or 0x8E26DC, true)
            end
            
            if imgui.ToggleButton(u8'Отключить эффеты падающего снега', checkbox.nosnow) then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Изменения будут видны только после респавна!", 0x0FF6600)
            end

         end
         
         imgui.PopStyleVar()
         
      -- elseif tabmenu.settings == 7 then
      elseif tabmenu.settings == 8 then
         if ini.settings.allchatoff then 
            imgui.TextColoredRGB("{FF0000}Chat OFF")
         else
            imgui.TextColoredRGB("{696969}Chat")
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"очистить", imgui.ImVec2(90, 25), u8"Очистить чат (Для себя)") then
            ClearChat()
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Чат был очищен!", 0x0FF6600)
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"chatlog", imgui.ImVec2(90, 25), u8"Открыть лог чата (chatlog.txt)") then
            os.execute('explorer '..getFolderPath(5) ..'\\GTA San Andreas User Files\\SAMP\\chatlog.txt')
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"timestamp", imgui.ImVec2(90, 25), u8"Отображать время в чате") then
            sampProcessChatInput("/timestamp")
         end
         if isTrainingSanbox then
            imgui.SameLine()
            if ini.settings.savepmmessages then
               --imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 0.0, 1.0))
               if imgui.TooltipButton(u8"pmh", imgui.ImVec2(60, 25), u8"История личных сообщений /pmh") then
                  sampSendChat("/pmh")
               end
               --imgui.PopStyleColor()
            end
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"getids", imgui.ImVec2(60, 25), u8"Получить id и ники игроков рядом") then
            copyNearestPlayersToClipboard()
         end
         
         imgui.Spacing()

         if imgui.CollapsingHeader(u8"Поиск:") then
            local statistics = {lines = 0, results = 0}
            
            imgui.PushItemWidth(270)
            if imgui.InputText("##searchbar", textbuffer.searchbar, imgui.InputTextFlags.EnterReturnsTrue) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.TooltipButton(u8"Найти", imgui.ImVec2(65, 25), u8"Найти в чатлоге") then
               imgui.resetIO()
               if string.len(textbuffer.searchbar.v) >= 2 then
                  local filepath = getFolderPath(5)..'\\GTA San Andreas User Files\\SAMP\\chatlog.txt'
                  if doesFileExist(filepath) then
                     local file = io.open(filepath, "r")
                     searchresults = {}
                     local pattern = nil
                     
                     for line in file:lines() do
                        if line:len() > 1 then
                           if checkbox.searchregexp.v then
                              local result = string.match(line, string.nlower(u8:decode(textbuffer.searchbar.v)))
                              if result then
                                 table.insert(searchresults, line)
                                 statistics.results = statistics.results + 1
                              end
                           else
                              if checkbox.searchaslower.v then
                                 pattern = string.nlower(u8:decode(textbuffer.searchbar.v))
                              else
                                 pattern = u8:decode(textbuffer.searchbar.v)
                              end
                              if line:find(pattern) then
                                 table.insert(searchresults, line)
                                 statistics.results = statistics.results + 1
                              end
                           end
                           statistics.lines = statistics.lines + 1
                        end
                     end
                     if statistics.results > 0 then
                        sampAddChatMessage(("[SCRIPT]: {FFFFFF}Найдено %d совпадений в %d строках"):format(statistics.results, statistics.lines), 0x0FF6600)
                     else
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найдено совпадений", 0x0FF6600)
                        --table.insert(searchresults, "Совпадений не найдено")
                     end
                     file:close()
                  else
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Чатлог не найден!", 0x0FF6600)
                  end
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите 2 и более символа для посика!", 0x0FF6600)
               end
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Очистить", imgui.ImVec2(70, 25), u8"Очистить результаты поиска") then
               imgui.resetIO()
               searchresults = {}
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Экспорт", imgui.ImVec2(70, 25), u8"Сохранить результаты поиска") then
               if #searchresults >= 1 then
                  local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//export//exportchat.txt"
                  local file = io.open(filepath, "w")
                  file:write("MappingTollkit: Exported search chat results:\n")
                  for i, line in ipairs(searchresults) do
                     file:write(tostring(u8:encode(line)))   
                  end
                  file:close()
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Результаты поиска были сохранены в /moonloader/resource/mappingtoolkit/export/exportchat.txt", 0x0FF6600)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Нет результатов для сохранения!", 0x0FF6600)
               end
            end
            
            if imgui.Checkbox(u8"Игнорировать регистр", checkbox.searchaslower) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Не учитывает регистр букв при поиске (ТЕкСТ = текст)")
            
            if imgui.Checkbox(u8"Выводить без форматирования", checkbox.searchwithoutformat) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Выводит строку как есть без раскраски и форматирования")
            
            if imgui.Checkbox(u8"Регулярные выражения", checkbox.searchregexp) then
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Для поиска можно использовать регулярные выражения.\nИспользует шаблон match для поиска паттерну")
            
            local notifytext = [[
            .  - Любой символ
            %a  - Буква (только англ.!)
            %A  - Любая буква (русская), символ, или цифра, кроме английской буквы
            %c  - Управляющий символ
            %d  - Цифра
            %D  - Любая буква, или символ, кроме цифры
            %l  - Буква в нижней раскладке (только англ.!)
            %L  - Любая буква, символ, или цифра, кроме английской буквы в нижней раскладке
            %p  - Символ пунктуации
            %P  - Любая буква, символ, или цифра, кроме символа пунктуации
            %s  - Символ пробел
            %S  - Любая буква, символ, или цифра, кроме символа пробела
            %u  - Буква в верхней раскладке (только англ.!)
            %U  - Любая буква, символ, или цифра, кроме английской буквы в верхней раскладке
            %w  - Любая буква, или цифра (только англ.!)
            %W  - Любой символ, или буква (русская), кроме английской буквы, или цифры
            %x  - Шестнадцатеричное число
            %X  - Любая буква, или символ,  кроме цифры, или английской буквы, используемой в записи шестнадцатеричного числа
            %z  - Строковые параметры, содержащие символы с кодом 0
            ]]
            notifytext = string.gsub(notifytext, "   ", "")
            imgui.SameLine()
            imgui.TextNotify(" [%Паттерны]",u8(notifytext))
            
            if #searchresults >= 1 then
               local maxresults = 25
               imgui.TextColoredRGB("{696969}* Для копирования строки нажмите на нее")
               imgui.Text(u8"Результаты: ")
               for i, line in ipairs(searchresults) do
                  if checkbox.searchwithoutformat.v then
                     if imgui.Selectable(tostring(u8:encode(line))) then
                        setClipboardText(tostring(line))
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Текст скопирован в буффер обмена", 0x0FF6600)
                     end
                  else
                     imgui.TextColoredRGB(tostring(line))
                     if imgui.IsItemClicked() then 
                        setClipboardText(tostring(line))
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Текст скопирован в буффер обмена", 0x0FF6600)
                     end
                  end
                  if i >= maxresults then
                     break
                  end
               end
            end
            
         end
         if imgui.CollapsingHeader(u8"Фильтры:") then
            if imgui.ToggleButton(u8"Анти-капс для сообщений в чате", checkbox.anticaps) then
               ini.settings.anticaps = checkbox.anticaps.v
               inicfg.save(ini, configIni)
            end
            
            -- Outdate. Hamster deactivated on server
            -- if isTrainingSanbox then
               -- if imgui.ToggleButton(u8"Заткнуть хомяка (Бот Hamster)", checkbox.blockhamster) then
                  -- ini.settings.blockhamster = checkbox.blockhamster.v
                  -- inicfg.save(ini, configIni)
               -- end
            -- end
            
            if imgui.ToggleButton(u8"Скрывать все объявления и рекламу", checkbox.antiads) then
               ini.settings.antiads = checkbox.antiads.v
               inicfg.save(ini, configIni)
            end  
            
            if imgui.ToggleButton(u8"Скрывать сообщения от ботов", checkbox.antichatbot) then
               if checkbox.antichatbot.v then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Если не все сообщения ботов заблокировались воспользуйтесь расширенными чат-фильтрами", 0x0FF6600)
                  if isTrainingSanbox then
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Так же можно заблокировать сообщения от бота командой /ignore <id>", 0x0FF6600)
                  end
               end
               ini.settings.antichatbot = checkbox.antichatbot.v
               inicfg.save(ini, configIni)
            end  
            
            if imgui.ToggleButton(u8"Скрывать отыгровки (/me, /do, /ame ..)", checkbox.chathiderp) then
               ini.settings.chathiderp = checkbox.chathiderp.v
               inicfg.save(ini, configIni)
            end
            
            if imgui.ToggleButton(u8"Скрывать все сообщения кроме системных", checkbox.chatonlysystem) then
               ini.settings.chatonlysystem = checkbox.chatonlysystem.v
               inicfg.save(ini, configIni)
            end
            
            if isTrainingSanbox then
               if imgui.ToggleButton(u8"Скрывать приставку [CB] в чате", checkbox.chathidecb) then
                  ini.settings.chathidecb = checkbox.chathidecb.v
                  inicfg.save(ini, configIni)
               end
            end
            imgui.Spacing()
         end
         
         if imgui.CollapsingHeader(u8"Расширенные настройки фильтров:") then
            local filedata = {filepath, lines, symbols}
            filedata.filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//chatfilter.txt"
            filedata.lines = 1
            filedata.symbols = 0
            
            imgui.TextColoredRGB("Вы можете убрать для себя надоедливые сообщения в чате")
            imgui.TextColoredRGB("определив правила фильтрации по паттренам.")
            
            imgui.Spacing()
            if ini.settings.chatfilter then
            
               filedata.symbols = math.floor(string.len(textbuffer.chatfilters.v)/2)
               for s in string.gmatch(textbuffer.chatfilters.v, "\n" ) do
                  filedata.lines = filedata.lines + 1
               end
               
               if filedata.symbols == 0 then
                  local file = io.open(filedata.filepath, "r")
                  textbuffer.chatfilters.v = file:read('*a')
                  file:close()
               end
               
               if imgui.TooltipButton(u8"Обновить", imgui.ImVec2(80, 25), u8:encode("Загрузить шаблоны из файла chatfilter.txt")) then
                  local file = io.open(filedata.filepath, "r")
                  textbuffer.chatfilters.v = file:read('*a')
                  file:close()
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Изменить", imgui.ImVec2(80, 25), u8:encode("Разблокировать для редактирования")) then
                  input.readonly = false
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Сохранить", imgui.ImVec2(80, 25), u8:encode("Сохранить шаблоны в chatfilter.txt")) then
                  if not input.readonly then
                     local file = io.open(filedata.filepath, "w")
                     file:write(textbuffer.chatfilters.v)
                     file:close()
                     sampAddChatMessage("Сохранено в файл: /moonloader/resource/mappingtoolkit/chatfilter.txt", -1)
                  else
                     sampAddChatMessage("Недоступно в режмие для чтения. Снимте режим RO (Readonly)", -1)
                  end
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Помощь", imgui.ImVec2(80, 25), u8:encode("Гайд по паттернам (Онлайн)")) then
                  os.execute('explorer https://www.blast.hk/threads/62661/')
               end
               imgui.SameLine()
               if imgui.TooltipButton(u8"Отключить", imgui.ImVec2(80, 25), u8"Отключить расширенные фильтры для чата") then
                  ini.settings.chatfilter = false
                  inicfg.save(ini, configIni)
               end
               
               imgui.PushFont(fonts.multilinetextfont)
               if input.readonly then
                  imgui.InputTextMultiline('##chatfilters', textbuffer.chatfilters, imgui.ImVec2(450, 145),
                  imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
               else 
                  imgui.InputTextMultiline('##chatfilters', textbuffer.chatfilters, imgui.ImVec2(450, 145),
                  imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
               end
               imgui.PopFont()
               
               imgui.Text("lines: "..filedata.lines.." symbols: "..filedata.symbols)
               imgui.SameLine()
               imgui.Text("                                      ")
               imgui.SameLine()
               if imgui.Selectable(input.readonly and "RO" or "W", false, 0, imgui.ImVec2(25, 15)) then
                  input.readonly = not input.readonly
               end
               imgui.SameLine()
               if imgui.Selectable("Unlock IO", false, 0, imgui.ImVec2(50, 15)) then
                  imgui.resetIO()
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"RO - Включить режим ReadOnly\nUnlock IO - разблокировать инпут если курсор забагался")
            else
               if imgui.TooltipButton(u8"Включить расширенные фильтры", imgui.ImVec2(220, 25), u8"Активирует расширенные фильтры для чата") then
                  ini.settings.chatfilter = true
                  inicfg.save(ini, configIni)
               end
            end
            imgui.Spacing()
         end
         
         imgui.Spacing()
         imgui.Spacing()
         
         if isTrainingSanbox then
            if imgui.TooltipButton(u8"mute", imgui.ImVec2(60, 25), u8"Настройки чата, позволяет заглушить указанный тип сообщений /mute") then
               if dialog.main.v then dialog.main.v = false end
               sampSendChat("/mute")
            end
            imgui.SameLine()
         end
         
         imgui.PushItemWidth(175)
         if imgui.Combo(u8'Чат по-умолчанию##cahtprefixcombo', combobox.chatprefix, chatPrefixNames) then
            ini.settings.chatprefix = combobox.chatprefix.v
            inicfg.save(ini, configIni)
         end
         imgui.PopItemWidth()
         
         if imgui.ToggleButton(u8"Останавливать чат при открытии поля ввода", checkbox.freezechat) then
            if checkbox.freezechat.v then 
               playerdata.isChatFreezed = true 
            else
               playerdata.isChatFreezed = false
            end
            ini.settings.freezechat = checkbox.freezechat.v
            inicfg.save(ini, configIni)
         end
         
         if imgui.ToggleButton(u8"Отключить весь чат", checkbox.allchatoff) then
            ini.settings.allchatoff = checkbox.allchatoff.v
            inicfg.save(ini, configIni)
            if checkbox.allchatoff.v then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Все сообщения в чат будут игнорироваться", 0x0FF6600)
            end
         end     
         
         if imgui.ToggleButton(u8(checkbox.hidechat.v and 'Показать панель с чатотм' or 'Скрыть панель с чатом'), checkbox.hidechat) then
            memory.fill(getModuleHandle("samp.dll") + 0x63DA0, checkbox.hidechat.v and 0x90909090 or 0x0A000000, 4, true)
            sampSetChatInputEnabled(checkbox.hidechat.v)
         end
         
         if imgui.ToggleButton(u8"Очищать строку ввода после закрытия", checkbox.chatinputdrop) then
            ini.settings.chatinputdrop = checkbox.chatinputdrop.v
            inicfg.save(ini, configIni)
         end
         
         if imgui.ToggleButton(u8"Копировать ник кликнутого игрока в TAB", checkbox.tabclickcopy) then
            ini.settings.tabclickcopy = checkbox.tabclickcopy.v
            inicfg.save(ini, configIni)
            if ini.settings.tabclickcopy then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Кликните на игрока чтобы скопировать его никнейм", 0x0FF6600)
            end
         end
         
         if imgui.ToggleButton(u8"Сохранять историю персональных сообщений /pmh", checkbox.savepmmessages) then
            ini.settings.savepmmessages = checkbox.savepmmessages.v
            inicfg.save(ini, configIni)
            if ini.settings.savepmmessages then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}История персональных сообщений доступна через команду /pmh", 0x0FF6600)
            end
         end
         
         -- imgui.Spacing()
         -- if imgui.Button(u8"Получить id и ники игроков рядом", imgui.ImVec2(300, 25)) then
            -- copyNearestPlayersToClipboard()
         -- end
         
      elseif tabmenu.settings == 9 then
         
         local id = getLocalPlayerId()
         local nickname = sampGetPlayerNickname(id)
         local score
         if sampGetPlayerScore(id) then
            score = sampGetPlayerScore(id)
         end
         
         if dialog.playerstat.v then
            if imgui.TooltipButton("[ << ]", imgui.ImVec2(50, 25), u8:encode("Скрыть подробную статистику")) then
               dialog.playerstat.v = not dialog.playerstat.v
            end
         else
            if imgui.TooltipButton("[ >> ]", imgui.ImVec2(50, 25), u8:encode("Раскрыть подробную статистику")) then
               dialog.playerstat.v = not dialog.playerstat.v
               chosen.player = id
            end
         end
         imgui.SameLine()       
         
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
         imgui.TextColoredRGB(string.format("FPS: {696969}%i", playerdata.fps))
         --imgui.TextColoredRGB(string.format("Ffs imgui: {696969}%.3f s.", imgui.GetIO().DeltaTime))
         if imgui.IsItemClicked() then
            runSampfuncsConsoleCommand("fps")
         end
         
         imgui.Spacing()
         
         if imgui.CollapsingHeader(u8"Погода и время:") then
         
            if imgui.Checkbox(u8("Уведомлять о изменении погоды сервером"), checkbox.weatherinformer) then          
               ini.settings.weatherinformer = checkbox.weatherinformer.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Сообщает в чат ид погоды при изменении сервером")
            
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

            if imgui.TooltipButton(u8(threads.timelap and 'Отключить' or 'Включить')..u8" автосмену времени", 
            imgui.ImVec2(220, 25), u8"Автосмена времени каждые n секунд (Тест)") then
               if threads.timelap then
                  threads.timelap:terminate()
                  threads.timelap = nil
                  ini.settings.time = 12
                  slider.time.v = ini.settings.time
                  setTime(slider.time.v)
               else
                  timelap(input.timelapdelay.v)
               end
            end
            
            imgui.SameLine()
            imgui.PushItemWidth(40)
            if imgui.InputInt('##INPUT_timelapdealy', input.timelapdelay, 0) then
               if input.timelapdelay.v < 1 then
                  input.timelapdelay.v = 1
               end
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.Text(u8"сек.")
            
            imgui.SameLine()
            imgui.Text(u8"            ")
            imgui.SameLine()
            if checkbox.daynight.v then
               imgui.TextColoredRGB("{696969}День")
            else
               imgui.TextColoredRGB("День")
            end
            imgui.SameLine()
            if imgui.ToggleButton(u8"Ночь", checkbox.daynight) then
               if checkbox.daynight.v then
                  ini.settings.time = 0
               else
                  ini.settings.time = 12
               end
               slider.time.v = ini.settings.time
               setTime(slider.time.v)
            end
            
            imgui.PushItemWidth(455)
            imgui.Text(u8'Время:')
            if imgui.SliderInt('##slider.time', slider.time, 0, 24) then 
               setTime(slider.time.v)
               ini.settings.time = slider.time.v
               if slider.time.v > 6 and slider.time.v < 20 then 
                  checkbox.daynight.v = false
               else
                  checkbox.daynight.v = true
               end
               inicfg.save(ini, configIni)
            end
            imgui.Spacing()
            imgui.Text(u8'Погода:')
            if imgui.SliderInt('##slider.weather', slider.weather, 0, 45) then 
               setWeather(slider.weather.v)
               ini.settings.weather = slider.weather.v
               inicfg.save(ini, configIni)
            end
            imgui.PopItemWidth()
            
            --imgui.Text(u8"Пресеты погоды: ")
            if imgui.Button(u8"Солнечная", imgui.ImVec2(110,25)) then
               slider.weather.v = 0
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Тусклая", imgui.ImVec2(110,25)) then
               slider.weather.v = 15
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)            
            end
            imgui.SameLine()
            if imgui.Button(u8"Чистое небо", imgui.ImVec2(110,25)) then
               slider.weather.v = 10
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Жара", imgui.ImVec2(110,25)) then
               slider.weather.v = 17
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            
            if imgui.Button(u8"Туманная", imgui.ImVec2(110,25)) then
               slider.weather.v = 9
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Песочная буря", imgui.ImVec2(110,25)) then
               slider.weather.v = 19
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Дождливая", imgui.ImVec2(110,25)) then
               slider.weather.v = 16
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Облачная", imgui.ImVec2(110,25)) then
               slider.weather.v = 12
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)            
            end
            
            if imgui.Button(u8"Монохромная", imgui.ImVec2(110,25)) then
               slider.weather.v = 44
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Темная", imgui.ImVec2(110,25)) then
               slider.weather.v = 45
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Зеленая", imgui.ImVec2(110,25)) then
               slider.weather.v = 20
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
            end
            imgui.SameLine()
            if imgui.Button(u8"Стандартная", imgui.ImVec2(110, 25)) then
               slider.weather.v = 0
               ini.settings.weather = slider.weather.v
               setWeather(slider.weather.v)
               slider.time.v = 12
               setTime(slider.time.v)
               ini.settings.time = slider.time.v
               inicfg.save(ini, configIni)
            end
            
            imgui.Spacing()          
            imgui.TextColoredRGB("Галерея погоды")
            imgui.SameLine()
            imgui.Link("https://dev.prineside.com/ru/gtasa_weather_id/", "dev.prineside.com")
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Данная галерея содержит снимки из игры GTA San Andreas, сделанные при разной погоде и времени суток. ")
            imgui.Spacing()
         end
         
         if imgui.CollapsingHeader(u8"Интерфейс:") then
            
            imgui.Text(u8"Выбрана тема:")
            imgui.SameLine()
            imgui.PushItemWidth(120)
            if imgui.Combo(u8'##imguitheme', combobox.imguitheme, imguiThemeNames) then
               ini.settings.imguitheme = combobox.imguitheme.v
               inicfg.save(ini, configIni)
               apply_custom_style()
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрана тема - "..tostring(imguiThemeNames[combobox.imguitheme.v+1]), 0x0FF6600)
            end
            imgui.PopItemWidth()
            
            imgui.SameLine()
            imgui.Text(u8"    ")
            imgui.SameLine()
            imgui.Text(u8"Выбран шрифт:")
            imgui.SameLine()
            imgui.PushItemWidth(120)
            if imgui.Combo(u8'##uifontselect', combobox.uifontselect, uiFontsList) then
               ini.settings.imguifont = tostring(uiFontsFilenames[combobox.uifontselect.v + 1])
               inicfg.save(ini, configIni)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрана шрифт - "..tostring(uiFontsList[combobox.uifontselect.v + 1]), 0x0FF6600)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Перезапустите тулкит чтобы увидеть изменения", 0x0FF6600)
            end
            imgui.PopItemWidth()
            
            imgui.Text(u8"Нижняя панель:")
            if imgui.Checkbox(u8'Показывать дополнительную нижнюю панель', checkbox.showpanel) then
               ini.panel.showpanel = checkbox.showpanel.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Отображать панель с различной информацие внизу экрана")
            
            if imgui.Checkbox(u8'Показывать темный фон для нижней панели', checkbox.panelbackground) then
               ini.panel.background = checkbox.panelbackground.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Отображать темный фон на нижней панели")
            
            if imgui.Checkbox(u8'Показывать счетчик FPS на нижней панели', checkbox.panelshowfps) then
               ini.panel.showfps = checkbox.panelshowfps.v
               inicfg.save(ini, configIni)
            end

            if imgui.Checkbox(u8'Показывать счетчик объектов на нижней панели', checkbox.panelshowstreamedobj) then
               ini.panel.showstreameddynobjects = checkbox.panelshowstreamedobj.v
               inicfg.save(ini, configIni)
            end
            
            if imgui.Checkbox(u8'Показывать счетчик транспорта в стриме на нижней панели', checkbox.panelshowstreamedvehs) then
               ini.panel.showstreamedvehs = checkbox.panelshowstreamedvehs.v
               inicfg.save(ini, configIni)
               if checkbox.panelshowstreamedvehs.v then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Данная опция может снижать FPS!", 0x0FF6600)
               end
            end
            
            if imgui.Checkbox(u8'Показывать счетчик игроков в стриме на нижней панели', checkbox.panelshowstreamedplayers) then
               ini.panel.showstreamedplayers = checkbox.panelshowstreamedplayers.v
               inicfg.save(ini, configIni)
            end
            
            if imgui.Checkbox(u8'Показывать XY координаты курсора на нижней панели', checkbox.panelshowcursorpos) then
               ini.panel.showcursorpos = checkbox.panelshowcursorpos.v
               inicfg.save(ini, configIni)
            end
            
            if imgui.Checkbox(u8'Показывать информацию о текущем объекте (id, model, txd)', checkbox.panelshoweditdata) then
               ini.panel.showlasttxd = checkbox.panelshoweditdata.v
               ini.panel.showlastobject = checkbox.panelshoweditdata.v
               inicfg.save(ini, configIni)
            end
            imgui.Text(u8"Прочее:")
            if imgui.Checkbox(u8'Показывать ID над HUD', checkbox.showidonhud) then
               ini.settings.showidonhud = checkbox.showidonhud.v
               inicfg.save(ini, configIni)
               if ini.settings.showidonhud then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Если текст не появился, попробуйте заспавниться", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Отображать ваш ID над худом (вверху экрана с правой стороны)")
            
            if isTrainingSanbox then
               if imgui.Checkbox(u8'Восстановить стандартный цвет 3D текста с инф-цией о объекте', checkbox.fixobjinfotext) then
                  ini.settings.fixobjinfotext = checkbox.fixobjinfotext.v
                  inicfg.save(ini, configIni)
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Восстанавливает стандартный синий цвет для 3D текста с информацией о ид объекта (В режиме разработки)")
            end
            
         end
         
         if imgui.CollapsingHeader(u8"Уведомления:") then
            if imgui.Checkbox(u8("Напоминать о необходимости сохранить мир"), checkbox.worldsavereminder) then
               if checkbox.worldsavereminder.v then
                  SaveReminder()
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Включены напоминания о необходимости сохранять виртуальный мир", 0x0FF6600)
               else
                  if threads.savereminder then
                     threads.savereminder:terminate()
                     threads.savereminder = nil
                  end
               end
               ini.settings.worldsavereminder = checkbox.worldsavereminder.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет напоминать вам о необходимости сохранить ваш мир (/saveworld)")
            
            if checkbox.worldsavereminder.v then
                if imgui.Button(u8"Применить") then
                  ini.settings.reminderdelay = input.reminderdelay.v
                  inicfg.save(ini, configIni)
               end
               imgui.SameLine()
               imgui.Text(u8"Напоминать каждые ")
               imgui.SameLine()
               imgui.PushItemWidth(40)
               imgui.InputInt("##inputreminderdelay", input.reminderdelay, 0)
               imgui.PopItemWidth()
               imgui.SameLine()
               imgui.Text(u8" минут")
            end
            
            if imgui.Checkbox(u8("Уведомлять о ошибках КБ в мире"), checkbox.cberrorwarnings) then
               if checkbox.cberrorwarnings.v then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Включены уведомления о ошибках КБ в мире", 0x0FF6600)
                  sampAddChatMessage("[WARNING]: {FFFFFF}Будет выводить предупреждения с тегом {FF6600}[WARNING]", 0x0FF6600)
               end
               ini.settings.cberrorwarnings = checkbox.cberrorwarnings.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет уведомлять о недопустимых параметрах КБ в мире (Используйте для тестов мира)")
            
            imgui.Spacing()
            imgui.Text(u8"Уведомления при упоминании вас в чате:")
            if imgui.Checkbox(u8("Уведомлять при упоминании по ID либо Никнейму в чате"), checkbox.chatmentions) then
               ini.mentions.chatmentions = checkbox.chatmentions.v
               inicfg.save(ini, configIni)
            end
            if checkbox.chatmentions.v then
               if imgui.Checkbox(u8("Воспроизводить звук при упоминании"), checkbox.usesound) then
                  ini.mentions.usesound = checkbox.usesound.v
                  inicfg.save(ini, configIni)
               end
               
               if imgui.Checkbox(u8("Выводить уведомление GameText'ом"), checkbox.usegametext) then
                  ini.mentions.usegametext = checkbox.usegametext.v
                  inicfg.save(ini, configIni)
               end
               
               if imgui.Checkbox(u8("Выделять цветом сообщение в котором вас упомянули"), checkbox.usecolor) then
                  ini.mentions.usecolor = checkbox.usecolor.v
                  inicfg.save(ini, configIni)
               end
               
               if imgui.Checkbox(u8'Скрывать всплывающие подсказки о системах транспорта', checkbox.skipvehnotify) then
                  ini.settings.skipvehnotify = checkbox.skipvehnotify.v
                  inicfg.save(ini, configIni)
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Скрывает всплывающие подсказки внизу экрана при переключении опций транспорта")
            end
            imgui.Spacing()
         
         end
         
         if imgui.CollapsingHeader(u8"Вход в мир:") then
            imgui.resetIO()
            if imgui.Checkbox(u8'Включать режим разработчика при входе в мир', checkbox.autodevmode) then
               ini.settings.autodevmode = checkbox.autodevmode.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет выставлять автоматически режим разработчика в мире (необходимо для перехвата локальных ид объектов)")

            if imgui.Checkbox(u8("Включать логи мира при входе"), checkbox.worldlogson) then
               ini.settings.worldlogson = checkbox.worldlogson.v
               inicfg.save(ini, configIni)
               dialoghook.logstoggle = true
               sampSendChat("/vw")
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Включает текстдрав с логами мира")
            
            if imgui.Checkbox(u8("Отключить audiostream"), nops.audiostream) then
               if nops.audiostream.v then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы отключили аудиострим (на период игровой сессии)", 0x0FF6600)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы включили аудиострим, показать url стрима можно командой /audiomsg", 0x0FF6600)
               end
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Отключает аудиострим (убирает музыку в мирах)")
            
            if imgui.Checkbox(u8'Включать бессмертие в мире', checkbox.setgm) then
               sampSendChat("/gm")
               ini.settings.setgm = checkbox.setgm.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет выставлять бессмертие при спавне в мире")
            
            if imgui.Checkbox(u8'Устанавливать свою погоду и время', checkbox.saveweather) then
               ini.settings.saveweather = checkbox.saveweather.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Устанавливать свою погоду и время при входе в мир")
            
            if imgui.Checkbox(u8'Устанавливать свой скин в мире', checkbox.saveskin) then 
               if checkbox.saveskin.v then
                  ini.settings.saveskin = true
                  --ini.settings.skinid = skinid
               else
                  ini.settings.saveskin = false
                  ---ini.settings.skinid = skinid
               end               
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Будет выставлять скин при спавне в мире")
            
            if checkbox.saveskin.v then
               -- imgui.Text("Skinid:")
               -- imgui.SameLine()
               imgui.PushItemWidth(45)
               imgui.InputText("ID##saveskin", textbuffer.saveskin, imgui.InputTextFlags.CharsDecimal)
               imgui.PopItemWidth()
               local skinid = tonumber(textbuffer.saveskin.v)
               local currentskin = getCharModel(playerPed)
               if string.len(textbuffer.saveskin.v) < 1 then
                  textbuffer.saveskin.v = tostring(currentskin)
               end
               
               imgui.SameLine()
               if imgui.Button(u8"Сменить скин", imgui.ImVec2(110, 25)) then
                  if isValidSkin(skinid) then
                     sampSendChat("/skin "..skinid)
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы cменили скин {696969}"..currentskin.."{FFFFFF} на {696969}"..skinid, 0x0FF6600)
                  end
               end
               imgui.SameLine()
               if imgui.Button(u8"Сохранить скин", imgui.ImVec2(110, 25)) then
                  if isValidSkin(skinid) then
                     sampSendChat("/skin "..skinid)
                     ini.settings.saveskin = true
                     ini.settings.skinid = skinid
                     inicfg.save(ini, configIni)
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы сохранили скин {696969}"..skinid, 0x0FF6600)
                  end
               end
               imgui.SameLine()
               if imgui.Button(u8"Сменить скин (Визуал)", imgui.ImVec2(150, 25)) then
                  if isValidSkin(skinid) then
                     setPlayerModel(skinid)
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы визуально cменили скин {696969}"..currentskin.."{FFFFFF} на {696969}"..skinid, 0x0FF6600)
                  end
               end
            end
         end
         
         if imgui.CollapsingHeader(u8"Автодополнение:") then
            
            if imgui.Checkbox(u8'Автодополнение имени мира (при сохранении)', checkbox.saveworldname) then
               ini.settings.saveworldname = checkbox.saveworldname.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"При сохранении мира поставит в поле ввода предыдущее имя (только для TRAINING)")
            
            if imgui.Checkbox(u8'Автодополнение в диалогах КБ', checkbox.cbvalautocomplete) then
               ini.settings.cbvalautocomplete = checkbox.cbvalautocomplete.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Использовать авто-дополнение текущих значений в /cblist (только для TRAINING)")
            
            if imgui.Checkbox(u8'Изменять способ активации при создании КБ', checkbox.cbnewactivation) then
               ini.settings.cbnewactivation = checkbox.cbnewactivation.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"При создании КБ изменяет активацию по-умолчанию на вашу")
            
            if checkbox.cbnewactivation.v then
               imgui.PushItemWidth(200)
               if imgui.Combo(u8'<- Выберите активацию КБ по-умолчанию##cbactivations', combobox.cbactivations, cbActivationItemsList) then
                  ini.settings.cbnewactivationitem = combobox.cbactivations.v
                  inicfg.save(ini, configIni)
               end
               imgui.PopItemWidth()
            end
            
            imgui.Text(u8"Радиус активации КБ по-умолчанию:")
            imgui.SameLine()
            imgui.PushItemWidth(60)
            --if imgui.InputFloat("##inputcbdefaultradius", input.cbdefaultradius, 0.1, 9999, '%.2f') then
            if imgui.InputText("##Buffercbdefaultradius", textbuffer.cbdefaultradius, imgui.InputTextFlags.CharsDecimal) then
               if tonumber(textbuffer.cbdefaultradius.v) > 0.1 and tonumber(textbuffer.cbdefaultradius.v) <= 9999.9 then
                  ini.settings.cbdefaultradius = string.format("%.1f", textbuffer.cbdefaultradius.v)
                  inicfg.save(ini, configIni)
               else
                  textbuffer.cbdefaultradius.v = "0.1"
               end
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"При создании КБ изменяет радиус активации (Принимает значения от 0.1 до 9999)")
               
            if imgui.Checkbox(u8'Скипать меню выбора объектов при отмене в /omenu', checkbox.skipomenu) then
               ini.settings.skipomenu = checkbox.skipomenu.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Автоматически пропускает меню выбора объектов при отмене в /omenu")
         end

         if imgui.CollapsingHeader(u8"Подключение:") then
           
            if isTrainingSanbox then   
               if imgui.Checkbox(u8'Пропускать диалог с правилами при входе на сервер', checkbox.skiprules) then
                  ini.settings.skiprules = checkbox.skiprules.v
                  inicfg.save(ini, configIni)
               end
               imgui.SameLine()
               imgui.TextQuestion("( ? )", u8"Автоматически пропускает диалог с правилами при входе на сервер")
            end
            
            if imgui.Checkbox(u8'Использовать автореконнект при потере соединения', checkbox.autoreconnect) then
               ini.settings.autoreconnect = checkbox.autoreconnect.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Автоматически переподключит вас к серверу при потере соединения\
            (Исправляет так же сообщение You are bannded on this server)")
            
            if imgui.Checkbox(u8'Возвращаться обратно в свой мир при вылете', checkbox.backtoworld) then
               ini.settings.backtoworld = checkbox.backtoworld.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Автоматически зайдет в созданный мир при подключении\
            (при условии что он еще не был обнулен)")
            
            if imgui.Checkbox(u8'Автоматически выгружать тулкит для других проектов', checkbox.serverlock) then
               ini.settings.serverlock = checkbox.serverlock.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Автоматически выгрузит тулкит если вы зайдете на другой сервер\
            (Будет загружать тулкит только для TRAINING-SANDBOX и локалхоста)")
            
            if imgui.Button(u8"Fastconnect (5 сек)", imgui.ImVec2(200, 25)) then
               Recon(5000)
            end
            imgui.SameLine()
            if imgui.Button(u8"Reconnect (15 сек)", imgui.ImVec2(200, 25)) then
               Recon(15500)
            end
            
            imgui.Text(u8'Текущий Gamestate: '..gamestates[sampGetGamestate() + 1])
            imgui.PushItemWidth(120)
            imgui.SameLine()
            imgui.Combo(u8'##Gamestates', combobox.gamestate, gamestates)
            imgui.SameLine()
            if imgui.Button(u8'Сменить') then
               sampSetGamestate(combobox.gamestate.v)
            end
            
            -- if fileschecker.isAutologinExist then
               -- imgui.TextColoredRGB("Авто-логин: {00FF00}Установлен")
               -- imgui.SameLine()
               -- imgui.TextQuestion("( ? )", u8"У вас уже установлен training-autologin.lua")
               -- -- if imgui.TooltipButton(u8'Сбросить конфиг', imgui.ImVec2(250, 25), u8"Сбросит файл с ключами") then
                  -- -- os.rename(getGameDirectory().."//moonloader//config//training-autologin.ini", getGameDirectory().."//moonloader//config//backup_training-autologin.ini")
                  -- -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Настройки авто-логина были сброшены на стандартные.",0x0FF6600)
                  -- -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Резервную копию ваших предыдущих настроек можно найти в {696969}moonloader/config.",0x0FF6600)
               -- -- end
            -- else
               -- if imgui.TooltipButton(u8'Установить авто-логин', imgui.ImVec2(250, 25), u8"Отправит вас на страницу скачивания тулкита авто-логина") then
                  -- os.execute('explorer "https://github.com/ins1x/moonloader-scripts/raw/refs/heads/main/training-sandbox/training-autologin/training-autologin.lua"')
                  -- sampAddChatMessage("[SCRIPT]: {FFFFFF}После загрузки файла скопируйте training-autologin.lua в папку moonloader", 0x0FF6600)
                  -- sampAddChatMessage("[SCRIPT]: {FFFFFF}При первом входе после установки авто-логин автоматически сохранит пароль (Только для TRAINING-SANDBOX)", 0x0FF6600)
               -- end
               -- imgui.SameLine()
               -- imgui.TextQuestion("( ? )", u8"После загрузки файла скопируйте training-autologin.lua в папку moonloader")
            -- end
            
         end
         if imgui.CollapsingHeader(u8"Горячие клавиши:") then
            if imgui.Checkbox(u8'Включить горячие клавиши', checkbox.hotkeys) then
               ini.settings.hotkeys = checkbox.hotkeys.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Активировать дополнительные горячие клавиши")
            
            if imgui.Checkbox(u8'Переключение текстур на PgUp и PgDown', checkbox.remapnum) then
               ini.settings.remapnum = checkbox.remapnum.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Заменить переключение текстур с Numpad на PgUp и PgDown (Для ноутбуков)")
            
            if imgui.Checkbox(u8'Отключить прокрутку чата на PgUp и PgDown', checkbox.nopagekeys) then
               writeMemory(getModuleHandle("samp.dll") + 0x63700, 1, 0xC3, true) -- 0x66B50 for R3
               ini.settings.nopagekeys = checkbox.nopagekeys.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Чат не будет прокручиваться на PgUp и PgDown (Включайте если используете опцию выше)")
            
            if imgui.Checkbox(u8'Запрет ALT + ENTER', checkbox.noaltenter) then
               ini.settings.noaltenter = checkbox.noaltenter.v
               inicfg.save(ini, configIni)
            end
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"GTA не будет сворачиваться в оконный режим при нажатии ALT+ENTER")
            
            -- if imgui.Checkbox(u8'Показывать подсказки для горячих клавиш', checkbox.hotkeystips) then
               -- ini.settings.hotkeystips = checkbox.hotkeystips.v
               -- inicfg.save(ini, configIni)
            -- end
            -- imgui.SameLine()
            -- imgui.TextQuestion("( ? )", u8"Показывать подсказки по горячим клавишам (например при переходе в режим полета, ретекстура и.т.д)")
            imgui.Spacing()
            if tabmenu.hotkeys == 1 then
               imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
               if imgui.Button(u8"Основные", imgui.ImVec2(125, 25)) then tabmenu.hotkeys = 1 end
               imgui.PopStyleColor()
            else
               if imgui.Button(u8"Основные", imgui.ImVec2(125, 25)) then tabmenu.hotkeys = 1 end
            end
            
            imgui.SameLine()
            if tabmenu.main == 2 then
               imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
               if imgui.Button(u8"Функциональные (F2-F12)", imgui.ImVec2(185, 25)) then tabmenu.hotkeys = 2 end
               imgui.PopStyleColor()
            else
               if imgui.Button(u8"Функциональные (F2-F12)", imgui.ImVec2(185, 25)) then tabmenu.hotkeys = 2 end
            end
      
            imgui.PushItemWidth(270)
            imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(16, 4))
            
            if tabmenu.hotkeys == 1 then
               if imgui.Combo(u8'Клавиша J##ComboBoxhotkeyJaction', combobox.hotkeyJaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyJ = tostring(hotkeysActivationCmds[combobox.hotkeyJaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyJaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша I##ComboBoxhotkeyIaction', combobox.hotkeyIaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyI = tostring(hotkeysActivationCmds[combobox.hotkeyIaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyIaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша K##ComboBoxhotkeyKaction', combobox.hotkeyKaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyK = tostring(hotkeysActivationCmds[combobox.hotkeyKaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyKaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша L##ComboBoxhotkeyLaction', combobox.hotkeyLaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyL = tostring(hotkeysActivationCmds[combobox.hotkeyLaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyLaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша N##ComboBoxhotkeyNaction', combobox.hotkeyNaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyN = tostring(hotkeysActivationCmds[combobox.hotkeyNaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyNaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша B##ComboBoxhotkeyBaction', combobox.hotkeyBaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyB = tostring(hotkeysActivationCmds[combobox.hotkeyBaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyBaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша 0##ComboBoxhotkeyOaction', combobox.hotkeyOaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyO = tostring(hotkeysActivationCmds[combobox.hotkeyOaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyOaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша P##ComboBoxhotkeyPaction', combobox.hotkeyPaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyP = tostring(hotkeysActivationCmds[combobox.hotkeyPaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyPaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша R##ComboBoxhotkeyRaction', combobox.hotkeyRaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyR = tostring(hotkeysActivationCmds[combobox.hotkeyRaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyRaction.v+1])), 0x0FF6600)
               end

               if imgui.Combo(u8'Клавиша Z##ComboBoxhotkeyZaction', combobox.hotkeyZaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyZ = tostring(hotkeysActivationCmds[combobox.hotkeyZaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyZaction.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша U##ComboBoxhotkeyUaction', combobox.hotkeyUaction, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyU = tostring(hotkeysActivationCmds[combobox.hotkeyUaction.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyUaction.v+1])), 0x0FF6600)
               end
               
            elseif tabmenu.hotkeys == 2 then
               
               if imgui.Combo(u8'Клавиша F2##ComboBoxhotkeyF2action', combobox.hotkeyF2action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF2 = tostring(hotkeysActivationCmds[combobox.hotkeyF2action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF2action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F3##ComboBoxhotkeyF3action', combobox.hotkeyF3action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF3 = tostring(hotkeysActivationCmds[combobox.hotkeyF3action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF3action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F4##ComboBoxhotkeyF4action', combobox.hotkeyF4action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF4 = tostring(hotkeysActivationCmds[combobox.hotkeyF4action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF4action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F5##ComboBoxhotkeyF5action', combobox.hotkeyF5action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF5 = tostring(hotkeysActivationCmds[combobox.hotkeyF5action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF5action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F7##ComboBoxhotkeyF7action', combobox.hotkeyF7action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF7 = tostring(hotkeysActivationCmds[combobox.hotkeyF7action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF7action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F9##ComboBoxhotkeyF9action', combobox.hotkeyF9action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF9 = tostring(hotkeysActivationCmds[combobox.hotkeyF9action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF9action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F10##ComboBoxhotkeyF10action', combobox.hotkeyF10action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF10 = tostring(hotkeysActivationCmds[combobox.hotkeyF10action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF10action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F11##ComboBoxhotkeyF11action', combobox.hotkeyF11action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF11 = tostring(hotkeysActivationCmds[combobox.hotkeyF11action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF11action.v+1])), 0x0FF6600)
               end
               
               if imgui.Combo(u8'Клавиша F12##ComboBoxhotkeyF12action', combobox.hotkeyF12action, 
               hotkeysActivationList, #hotkeysActivationList) then
                  ini.hotkeyactions.keyF12 = tostring(hotkeysActivationCmds[combobox.hotkeyF12action.v+1])
                  inicfg.save(ini, configIni)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Выбрано действие - "..
                  u8:decode(tostring(hotkeysActivationList[combobox.hotkeyF12action.v+1])), 0x0FF6600)
               end
            end
            imgui.PopStyleVar()
            imgui.PopItemWidth()
            
            if imgui.Button(u8"Вернуть на стандартные",imgui.ImVec2(200, 25)) then
               ini.hotkeyactions.keyJ = "/flymode"
               ini.hotkeyactions.keyI = ""
               ini.hotkeyactions.keyK = ""
               ini.hotkeyactions.keyL = "/lock"
               ini.hotkeyactions.keyN = ""
               ini.hotkeyactions.keyB = ""
               ini.hotkeyactions.keyR = ""
               ini.hotkeyactions.keyZ = ""
               ini.hotkeyactions.keyU = "/animlist"
               
               ini.hotkeyactions.keyF2 = ""
               ini.hotkeyactions.keyF3 = ""
               ini.hotkeyactions.keyF4 = ""
               ini.hotkeyactions.keyF5 = ""
               ini.hotkeyactions.keyF7 = ""
               ini.hotkeyactions.keyF9 = ""
               ini.hotkeyactions.keyF10 = ""
               ini.hotkeyactions.keyF11 = ""
               ini.hotkeyactions.keyF12 = ""

               inicfg.save(ini, configIni)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Восстановлены стандартные значения", 0x0FF6600)
            end
            
            imgui.TextColoredRGB("{696969}Нет нужной клавиши? Воспользуйтесь биндером")
         end
         -- if imgui.CollapsingHeader(u8"Прочее:") then
            
         -- end
      end -- end tabmenu.settings
      imgui.NextColumn()
      
      if tabmenu.settings == 9 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Персональное",imgui.ImVec2(105, 30)) then tabmenu.settings = 9 end 
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Персональное",imgui.ImVec2(105, 30)) then tabmenu.settings = 9 end 
      end
      
      if tabmenu.settings == 1 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Координаты",imgui.ImVec2(105, 30)) then tabmenu.settings = 1 end 
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Координаты",imgui.ImVec2(105, 30)) then tabmenu.settings = 1 end 
      end
      
      if tabmenu.settings == 2 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Объекты",imgui.ImVec2(105, 30)) then tabmenu.settings = 2 end 
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Объекты",imgui.ImVec2(105, 30)) then tabmenu.settings = 2 end 
      end
      
      if tabmenu.settings == 5 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Текстдравы", imgui.ImVec2(105, 30)) then tabmenu.settings = 5 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Текстдравы", imgui.ImVec2(105, 30)) then tabmenu.settings = 5 end
      end
      
      if tabmenu.settings == 3 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Камера",imgui.ImVec2(105, 30)) then tabmenu.settings = 3 end  
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Камера",imgui.ImVec2(105, 30)) then tabmenu.settings = 3 end 
      end
      
      if tabmenu.settings == 4 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Прорисовка",imgui.ImVec2(105, 30)) then tabmenu.settings = 4 end 
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Прорисовка",imgui.ImVec2(105, 30)) then tabmenu.settings = 4 end 
      end
      
      --if imgui.Button(u8"Пусто",imgui.ImVec2(105, 30)) then tabmenu.settings = 5 end 
      if tabmenu.settings == 6 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Эффекты",imgui.ImVec2(105, 30)) then tabmenu.settings = 6 end 
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Эффекты",imgui.ImVec2(105, 30)) then tabmenu.settings = 6 end 
      end
      
      if tabmenu.settings == 8 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Чатик",imgui.ImVec2(105, 30)) then tabmenu.settings = 8 end 
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Чатик",imgui.ImVec2(105, 30)) then tabmenu.settings = 8 end 
      end
      
      --if imgui.Button(u8"Разное",imgui.ImVec2(105, 30)) then tabmenu.settings = 10 end 
      
      imgui.Spacing()
      imgui.Columns(1)
       
      elseif tabmenu.main == 2 then
       imgui.resetIO()
       -- if dialog.extendedtab.v then
          -- if imgui.TooltipButton("[ >> ]", imgui.ImVec2(50, 25), u8:encode("Скрыть расширенные настройки")) then
             -- dialog.extendedtab.v = not dialog.extendedtab.v
          -- end
       -- else
          -- if imgui.TooltipButton("[ << ]", imgui.ImVec2(50, 25), u8:encode("Раскрыть расширенные настройки")) then
             -- dialog.extendedtab.v = not dialog.extendedtab.v
          -- end
       -- end
       -- imgui.SameLine()       
       
       -- changes the spacings so that all the elements can fit
       -- imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2, 2))
       -- imgui.Text(string.format(u8"Объектов в области в стрима: %i",streamedObjects))
       -- imgui.Text(string.format(u8"Игроков в области стрима: %i",sampGetPlayerCount(true) - 1))
       -- imgui.Text(string.format(u8"Транспорта в области стрима: %i",getVehicleInStream()))
       -- imgui.PopStyleVar()
       -- imgui.Spacing()
         
       imgui.Text(u8"Выберите сущность:")
       imgui.SameLine()
       imgui.PushItemWidth(100)
       local selecttableitems = {
          u8'Игроки', u8'Транспорт', u8'Объекты', u8'Текстуры', 
          u8'Пикапы', u8'3d-тексты'--, u8'Надписи'
       }
       imgui.Combo(u8'##ComboBoxSelecttable', combobox.selecttable, 
       selecttableitems, #selecttableitems)
       imgui.PopItemWidth()
       
       imgui.SameLine()
       
       imgui.Text(u8"Экспорт в ")
       imgui.SameLine()
       imgui.PushItemWidth(65)
       local exportformat = {
          u8'Text', u8'Pawn',
       }
       imgui.Combo(u8'##ComboBoxExportformat', combobox.exportformat, 
       exportformat, #exportformat)
       imgui.PopItemWidth()
       imgui.SameLine()
       if imgui.TooltipButton(u8"Экспортировать", imgui.ImVec2(120, 25), u8:encode("Экспортировать таблицу в файл")) then
          if combobox.exportformat.v == 0 then
             local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//export//exportdata.txt"
             local file = io.open(filepath, "w")
             if combobox.selecttable.v == 0 then
                file:write("MappingTollkit: Exported players:\n")
                for k, v in pairs(playersTable) do
                   file:write(string.format("%s(%d)\n", sampGetPlayerNickname(v), v))
                end
             elseif combobox.selecttable.v == 1 then
                file:write("MappingTollkit: Exported vehicles:\n")
                for k, v in ipairs(getAllVehicles()) do
                   local streamed, id = sampGetVehicleIdByCarHandle(v)
                   local vehmodelname = string.format("%s", VehicleNames[getCarModel(v)-399])
                   file:write(string.format("%d. %s\n", id, vehmodelname))
                end
             elseif combobox.selecttable.v == 2 then
                file:write("MappingTollkit: Exported objects:\n")
                for k, v in ipairs(getAllObjects()) do
                   if isObjectOnScreen(v) then
                      local model = getObjectModel(v)
                      local objectid = sampGetObjectSampIdByHandle(v)
                      local modelName = tostring(sampObjectModelNames[model])
                      file:write(string.format("%d, %d, %s\n", objectid, model, modelName))
                   end
                end
             elseif combobox.selecttable.v == 3 then
                file:write("MappingTollkit: Exported textures:\n")
                for k, v in ipairs(streamedTextures) do
                   if string.len(v) > 1 then
                      for element in string.gmatch(v, "[^,]+") do
                         file:write(string.format(" %s ", element))
                      end
                      file:write(string.format("\n", element))
                   end
                end
             elseif combobox.selecttable.v == 4 then
                file:write("MappingTollkit: Exported pickups:\n")
                for k, v in ipairs(streamedPickups) do
                   if string.len(v) > 1 then
                      for element in string.gmatch(v, "[^,]+") do
                         file:write(string.format(" %s ", element))
                      end
                      file:write(string.format("\n", element))
                   end
                end
             elseif combobox.selecttable.v == 5 then
                file:write("MappingTollkit: Exported 3dTexts:\n")
                for k, v in ipairs(streamed3dTexts) do
                   if string.len(v) > 1 then
                      for element in string.gmatch(v, "[^,]+") do
                         file:write(string.format(" %s ", element))
                      end
                      file:write(string.format("\n", element))
                   end
                end
             -- elseif combobox.selecttable.v == 6 then
                -- file:write("MappingTollkit: Exported MaterialTexts:\n")
                -- for k, v in ipairs(streamedTexts) do
                   -- if string.len(v) > 1 then
                      -- for element in string.gmatch(v, "[^,]+") do
                         -- file:write(string.format(" %s ", element))
                      -- end
                      -- file:write(string.format("\n", element))
                   -- end
                -- end
             end
             file:close()
             sampAddChatMessage("[SCRIPT]: {FFFFFF}Список был сохранен в /moonloader/resource/mappingtoolkit/export/exportdata.txt", 0x0FF6600)
          elseif combobox.exportformat.v == 1 then
             local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//export//exportdata.pwn"
             local file = io.open(filepath, "w")
             if combobox.selecttable.v == 0 then
                sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно! (Вы серьезно хотели экспортировать игроков?)", 0x0FF6600)
             elseif combobox.selecttable.v == 1 then
                file:write("// MappingTollkit: Exported vehicles:\n")
                file:write("// CreateVehicle(vehicletype, Float:x, Float:y, Float:z, Float:rotation, color1, color2, respawn_delay)\n")
                for k, v in ipairs(getAllVehicles()) do
                   local streamed, id = sampGetVehicleIdByCarHandle(v)
                   local vehmodelname = string.format("%s", VehicleNames[getCarModel(v)-399])
                   local pX, pY, pZ = getCarCoordinates(v)
                   local angle = getCarHeading(v)
                   local primaryColor, secondaryColor = getCarColours(v)
                   file:write(string.format("CreateVehicle(%d, %.2f, %.2f, %.2f, %.2f, %d, %d, %d); // %s\n", 
                   getCarModel(v), pX, pY, pZ, angle, primaryColor, secondaryColor, -1, vehmodelname))
                end
             elseif combobox.selecttable.v == 2 then
                file:write("// MappingTollkit: Exported objects\n")
                file:write("// CreateObject(modelid, Float:X, Float:Y, Float:Z, Float:rX, Float:rY, Float:rZ, Float:DrawDistance = 0.0)\n")
                for k, v in ipairs(getAllObjects()) do
                   if isObjectOnScreen(v) then
                      local model = getObjectModel(v)
                      local objectid = sampGetObjectSampIdByHandle(v)
                      local modelName = tostring(sampObjectModelNames[model])
                      local result, pX, pY, pZ = getObjectCoordinates(v)
                      local angle = getObjectHeading(v)
                      file:write(string.format("CreateObject(%d, %.2f, %.2f, %.2f, 0.0, 0.0, %.2f); // %s\n", 
                      model, pX, pY, pZ, angle, modelName))
                   end
                end
                sampAddChatMessage("[SCRIPT]: {FFFFFF}Важно! На данный момент не сохраняет корректно Rx и Ry значения поворота объекта!", 0x0FF6600)
             elseif combobox.selecttable.v == 3 then
                file:write("// MappingTollkit: Exported textures:\n")
                file:write("// SetObjectMaterial(objectid, materialindex, modelid, txdname[], texturename[], materialcolor)\n")
                file:write("new tmpobjid;\n")
                local elementCount = 0
                for k, v in ipairs(streamedTextures) do
                   if string.len(v) > 1 then
                      file:write("SetObjectMaterial(tmpobjid, ")
                      for element in string.gmatch(v, "[^,]+") do
                         elementCount = elementCount + 1
                         if elementCount > 1 then
                            local result = string.match(element, "%D")
                            if result then
                               if elementCount == 6 then
                                  if string.find(element, "none") then
                                     file:write(' 0')
                                  else
                                     file:write(string.format(' 0x%s', element))
                                  end
                               else
                                  file:write(string.format(' "%s",', element))
                               end
                            else
                               file:write(string.format(' %s,', element))
                            end
                         end
                      end
                      file:write(string.format(");\n", element))
                      elementCount = 0
                   end
                end
             elseif combobox.selecttable.v == 4 then
                file:write("// MappingTollkit: Exported pickups:\n")
                file:write("// CreatePickup(model, type, Float:X, Float:Y, Float:Z, virtualworld);\n")
                local elementCount = 0
                for k, v in ipairs(streamedPickups) do
                   if string.len(v) > 1 then
                      file:write("CreatePickup(")
                      for element in string.gmatch(v, "[^,]+") do
                         elementCount = elementCount + 1
                         if elementCount > 1 then
                            file:write(string.format(' %s,', element))
                         end
                      end
                      file:write(string.format(" -1 );\n", element))
                   end
                   elementCount = 0
                end
             elseif combobox.selecttable.v == 5 then
                file:write("// MappingTollkit: Exported 3DTexts:\n")
                file:write("// Create3DTextLabel(text[], color, Float:X, Float:Y, Float:Z, Float:DrawDistance, virtualworld, testLOS);\n")
                local elementCount = 0
                for k, v in ipairs(streamed3dTexts) do
                   if string.len(v) > 1 then
                      file:write('Create3DTextLabel(')
                      for element in string.gmatch(v, "[^,]+") do
                         elementCount = elementCount + 1
                         if elementCount > 1 then
                            file:write(string.format(' %s,', element))
                         end
                      end
                      file:write(string.format(" -1 );\n", element))
                   end
                   elementCount = 0
                end
             -- elseif combobox.selecttable.v == 6 then
                -- file:write("// MappingTollkit: Exported Texts:\n")
                -- file:write('// SetObjectMaterialText(objectid, text[], materialindex = 0, materialsize = OBJECT_MATERIAL_SIZE_256x128, fontface[] = "Arial", fontsize = 24, bold = 1, fontcolor = 0xFFFFFFFF, backcolor = 0, textalignment = 0);\n')
                -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно в текущей версии", 0x0FF6600)
             end
             file:close()  
             sampAddChatMessage("[SCRIPT]: {FFFFFF}Список был сохранен в /moonloader/resource/mappingtoolkit/export/exportdata.pwn", 0x0FF6600)
          end
       end
       if combobox.selecttable.v >= 3 then
          imgui.SameLine()
          if imgui.TooltipButton(u8"Очистить", imgui.ImVec2(70, 25), u8:encode("Очистить таблицу")) then
             if combobox.selecttable.v >= 3 then
                if combobox.selecttable.v == 3 then
                   streamedTextures = {}
                   for i = 1, ini.settings.maxtableitems do
                      table.insert(streamedTextures, "")
                   end
                elseif combobox.selecttable.v == 4 then
                   for i = 1, ini.settings.maxtableitems do
                      table.insert(streamedPickups, "")
                   end
                   streamedPickups = {}
                elseif combobox.selecttable.v == 5 then
                   for i = 1, ini.settings.maxtableitems do
                      table.insert(streamed3dTexts, "")
                   end
                   streamed3dTexts = {}
                elseif combobox.selecttable.v == 6 then
                   for i = 1, ini.settings.maxtableitems do
                      table.insert(streamedTexts, "")
                   end
                   streamedTexts = {}
                end
                sampAddChatMessage("[SCRIPT]: {FFFFFF}Таблица была очищена", 0x0FF6600)
             else
                sampAddChatMessage("[SCRIPT]: {FFFFFF}Действие не требуется - таблица очищается автоматически", 0x0FF6600)
             end
          end
       end
       
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
       
          if chosen.player then
             local nickname = sampGetPlayerNickname(chosen.player)
             local ucolor = sampGetPlayerColor(chosen.player)
             imgui.TextColoredRGB(string.format("Выбран игрок: {%0.6x} %s[%d]",
             bit.band(ucolor,0xffffff), nickname, chosen.player))
          else
             imgui.TextColoredRGB("{FF0000}Красным{CDCDCD} в таблице отмечены подозрительные игроки")
          end
          
          if getClosestPlayerId() ~= -1 then
             imgui.Text(u8"Ближайший игрок: ")
             imgui.SameLine()
             if imgui.Selectable(tostring(sampGetPlayerNickname(getClosestPlayerId())).."["..getClosestPlayerId().."]", false, 0, imgui.ImVec2(200, 15)) then
                setClipboardText(getClosestPlayerId())
                sampAddChatMessage("ID скопирован в буффер обмена", -1)
             end
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
                sampAddChatMessage("Скопирован в буффер обмена", -1)
             end
             imgui.SetColumnWidth(-1, 60)
             imgui.NextColumn()
             if sampIsPlayerPaused(v) then
                imgui.TextColoredRGB("{FF0000}[AFK]")
                imgui.SameLine()
             end
             --imgui.TextColoredRGB(string.format("{%0.6x} %s", bit.band(ucolor,0xffffff), nickname))
             imgui.Selectable(u8(nickname))
             if imgui.IsItemClicked() then
                chosen.player = v
                if not dialog.playerstat.v then dialog.playerstat.v = true end
             end
             imgui.SetColumnWidth(-1, 300)
             imgui.NextColumn()

             imgui.TextColoredRGB(string.format("%i", score))

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
         imgui.resetIO()
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
            
         if isCharInAnyCar(playerPed) then 
            local carhandle = storeCarCharIsInNoSave(playerPed)
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
         imgui.SetColumnWidth(-1, 150)
         imgui.Text("Vehicle")
         imgui.NextColumn()
         imgui.SetColumnWidth(-1, 300)
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
               chosen.vehicle = v
               LastData.lastVehinfoModelid = carmodel
               if not dialog.vehstat.v then dialog.vehstat.v = true end
            end
                   
            imgui.NextColumn()
            if res then 
               imgui.Selectable(string.format(u8"%s", sampGetPlayerNickname(pid)))
               if imgui.IsItemClicked() then
                  chosen.player = pid
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
         imgui.resetIO()
         
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
               local px, py, pz = getCharCoordinates(playerPed)
               local distance = string.format("%.2f", getDistanceBetweenCoords3d(x, y, z, px, py, pz))
              
               -- TODO Later
               --if checkbox.hidestaticobjects and objectid ~= -1 then
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
               if objectid ~= -1 then
                  if imgui.Selectable(" "..modelName) then
                     dialog.objectinfo.v = true
                     chosen.object = v
                  end
               else
                  imgui.TextColoredRGB("{696969}"..modelName)
               end
               imgui.NextColumn()
               imgui.Text(" "..distance)
               imgui.NextColumn()
               imgui.Columns(1)
               imgui.Separator()
            end
         end
         imgui.Text(u8"Всего объектов в таблице: ".. objectsInTable)
      elseif combobox.selecttable.v == 3 then
         imgui.Separator()
         imgui.Columns(6)
         imgui.TextQuestion("TxdId", u8"ID текстуры (/tsearch)")
         imgui.SetColumnWidth(-1, 50)
         imgui.NextColumn()
         imgui.Text("Slot")
         imgui.SetColumnWidth(-1, 40)
         imgui.NextColumn()
         imgui.Text("Modelid")
         imgui.SetColumnWidth(-1, 80)
         imgui.NextColumn()
         imgui.Text("TxdName")
         imgui.SetColumnWidth(-1, 150)
         imgui.NextColumn()
         imgui.Text("TxdLib")
         imgui.SetColumnWidth(-1, 150)
         imgui.NextColumn()
         imgui.TextQuestion("TxdColor", u8"Цвет указан в формате AARRGGBB")
         imgui.NextColumn()
         imgui.Columns(1)
         imgui.Separator()
         
         local texturesInTable = 0
         
         for k, v in ipairs(streamedTextures) do
            if string.len(v) > 1 then
               texturesInTable = texturesInTable + 1
               imgui.Columns(6)
               for element in string.gmatch(v, "[^,]+") do
                  local result = string.match(element, "%D")
                  if result then
                     if imgui.Selectable(" "..element) then
                        setClipboardText(element)
                        sampAddChatMessage("{696969}"..element.." {FFFFFF}скопирован в буффер обмена", -1)
                     end
                  else
                     imgui.TextColoredRGB("{696969}"..element)
                     if imgui.IsItemClicked() then
                        setClipboardText(element)
                        sampAddChatMessage("{696969}"..element.." {FFFFFF}скопирован в буффер обмена", -1)
                     end
                  end
                  imgui.NextColumn()
               end
               imgui.Columns(1)
               imgui.Separator()
            end
         end
         imgui.Text(u8"Всего текстур в таблице: ".. texturesInTable)
      elseif combobox.selecttable.v == 4 then
         imgui.Separator()
         imgui.Columns(6)
         imgui.Text("Id")
         imgui.SetColumnWidth(-1, 50)
         imgui.NextColumn()
         imgui.TextColoredRGB("Model {696969}(ModelName)")
         imgui.SetColumnWidth(-1, 200)
         imgui.NextColumn()
         imgui.TextNotify("Type", u8"Нажмите чтобы просмотреть типы пикапов на\nhttps://sampwiki.blast.hk/wiki/PickupTypes")
         if imgui.IsItemClicked() then
            os.execute('explorer "https://sampwiki.blast.hk/wiki/PickupTypes"')
         end
         imgui.SetColumnWidth(-1, 50)
         imgui.NextColumn()
         imgui.Text("x")
         imgui.SetColumnWidth(-1, 120)
         imgui.NextColumn()
         imgui.Text("y")
         imgui.SetColumnWidth(-1, 120)
         imgui.NextColumn()
         imgui.Text("z")
         imgui.SetColumnWidth(-1, 120)
         imgui.NextColumn()
         imgui.Columns(1)
         imgui.Separator()
         
         local pickupsInTable = 0
         local elementCount = 0
         
         for k, v in ipairs(streamedPickups) do
            if string.len(v) > 1 then
               pickupsInTable = pickupsInTable + 1
               imgui.Columns(6)           
               for element in string.gmatch(v, "[^,]+") do
                  elementCount = elementCount + 1
                  if elementCount == 2 then
                     if isValidObjectModel(tonumber(element)) then
                        local modelName = tostring(sampObjectModelNames[tonumber(element)])
                        imgui.TextColoredRGB(("%s {696969}(%s)"):format(element, modelName))
                        if imgui.IsItemClicked() then
                           sampAddChatMessage("model скопирован в буффер обмена", -1)
                           setClipboardText(tonumber(element))
                        end
                     else
                        imgui.TextColoredRGB("{696969}"..element)
                     end
                  else
                     local result = string.match(element, "%D")
                     if result then
                        imgui.TextColoredRGB("{696969}"..element)
                     else
                        imgui.TextColoredRGB("{FFFFFF}"..element)
                     end
                  end
                  imgui.NextColumn()
               end
               elementCount = 0
               imgui.Columns(1)
               imgui.Separator()
            end
         end
         imgui.Text(u8"Всего пикапов в таблице: ".. pickupsInTable)
      elseif combobox.selecttable.v == 5 then
         imgui.Separator()
         imgui.Columns(3)
         imgui.Text("Id")
         imgui.SetColumnWidth(-1, 37)
         imgui.NextColumn()
         imgui.Text("Text")
         imgui.SetColumnWidth(-1, 510)
         imgui.NextColumn()
         imgui.TextQuestion("Color", u8"Цвет указан в формате RRGGBBAA (-1 без цвета)")
         imgui.SetColumnWidth(-1, 70)
         -- imgui.NextColumn()
         -- imgui.Text("xyz")
         -- imgui.SetColumnWidth(-1, 60)
         -- imgui.NextColumn()
         -- imgui.Text("y")
         -- imgui.SetColumnWidth(-1, 60)
         -- imgui.NextColumn()
         -- imgui.Text("z")
         -- imgui.SetColumnWidth(-1, 60)
         -- imgui.NextColumn()
         imgui.Columns(1)
         imgui.Separator()
         
         local textsInTable = 0
         local elementCount = 0
         for k, v in ipairs(streamed3dTexts) do
            if string.len(v) > 1 then
               textsInTable = textsInTable + 1
               imgui.Columns(3)           
               for element in string.gmatch(v, "[^,]+") do
                  elementCount = elementCount + 1
                  if elementCount <= 3 then
                     if element:find('"') then
                        element = element:gsub('"','')
                     end
                     local result = string.match(element, "%D")
                     if result then
                        if elementCount == 2 and element:find('[.]') then
                           element = element:gsub('[.]','\n')
                           element = element:gsub('%s%s','\n')
                        end
                        imgui.TextColoredRGB(""..element)
                     else
                        imgui.TextColoredRGB("{696969}"..element)
                     end
                     imgui.NextColumn()
                  end
               end
               elementCount = 0
               imgui.Columns(1)
               imgui.Separator()
            end
         end

         imgui.Text(u8"Всего 3D текстов в таблице: ".. textsInTable)
      elseif combobox.selecttable.v == 6 then
         imgui.Separator()
         imgui.Columns(2)
         imgui.Text("Id")
         imgui.SetColumnWidth(-1, 40)
         imgui.NextColumn()
         imgui.Text("Text")
         imgui.SetColumnWidth(-1, 550)
         imgui.Columns(1)
         imgui.Separator()
         
         imgui.TextColoredRGB("{FF0000}Доступно только для экспорта")
         -- local textsInTable = 0
         -- local elementCount = 0
         -- for k, v in ipairs(streamedTexts) do
            -- if string.len(v) > 1 then
               -- textsInTable = textsInTable + 1
               -- imgui.Columns(2)           
               -- for element in string.gmatch(v, "[^,]+") do
                  -- elementCount = elementCount + 1
                  -- if elementCount <= 2 then
                     -- if element:find('"') then
                        -- element = element:gsub('"','')
                     -- end
                     -- local result = string.match(element, "%D")
                     -- if result then
                        -- if elementCount == 2 and element:find('[.]') then
                           -- element = element:gsub('[.]','\n')
                           -- element = element:gsub('%s%s','\n')
                        -- end
                        -- imgui.TextColoredRGB(""..element)
                     -- else
                        -- imgui.TextColoredRGB("{696969}"..element)
                     -- end
                     -- imgui.NextColumn()
                  -- end
               -- end
               -- elementCount = 0
               -- imgui.Columns(1)
               -- imgui.Separator()
            -- end
         -- end
         
         imgui.Text(u8"Всего текстов в таблице: ".. textsInTable)
      end

   elseif tabmenu.main == 3 then
      imgui.Columns(2)
      imgui.SetColumnWidth(-1, 510)
      
      if tabmenu.info == 1 then
         local text = [[Ассистент дает вам больше возможностей для маппинга и разработки.
         Предоставляет дополнительные функции для работы с текстурами и объектами,
         исправляет некоторые баги игры, дополняет серверные команды и диалоги.
         
         Функционал достаточно обширен, и регулярно обновляется.  
         Может работать и на других проектах, но многие функции будут недоступны.
         Распостраняется только с открытым исходным кодом!
         ]]

         text = string.gsub(text, "   ", "")
         imgui.Text(u8(text))
         imgui.Spacing()
            imgui.Text(u8"Обсуждение Mapping Toolkit на форуме:")
            imgui.SameLine()
            imgui.Link("https://forum.training-server.com/d/19708-luamappingtoolkit/", "Mapping Toolkit")
            
            imgui.Text(u8"Скачать тулкит с GitHub:")
            imgui.SameLine()
            imgui.Link("https://github.com/ins1x/MappingToolkit", "ins1x/MappingToolkit")
            imgui.SameLine()
            imgui.Text(u8"или с GoogleDrive:")
            imgui.SameLine()
            imgui.Link("https://drive.google.com/drive/folders/1v-LmqAgKGpYYeA1C7aT-rlODTa2OfulT", 
            "drive.google.com")
            
            imgui.Text(u8"Больше информации по возможностям тулкита:")
            imgui.SameLine()
            imgui.Link("https://github.com/ins1x/MappingToolkit/wiki/FAQ-%D0%BF%D0%BE-MappingToolkit", u8"Github-Wiki")
            
         imgui.Spacing()
         
         imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(5, 2))
         
         if tabmenu.credits == 1 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Благодарности", imgui.ImVec2(200, 30)) then tabmenu.credits = 1 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Благодарности", imgui.ImVec2(200, 30)) then tabmenu.credits = 1 end
         end
         
         imgui.SameLine()
         if tabmenu.credits == 2 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Полезные ресурсы", imgui.ImVec2(200, 30)) then tabmenu.credits = 2 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Полезные ресурсы", imgui.ImVec2(200, 30)) then tabmenu.credits = 2 end
         end
         imgui.PopStyleVar()
         
         if tabmenu.credits == 1 then
            imgui.Spacing()
            local text = [[
            Форумчанам с {696969}BLASTHACK{CDCDCD} за полезные примеры и сниппеты по Lua
            Разработчику {FF6600}FYP{CDCDCD} создавшему moonloader, lib.samp.events
            Форумчанам с TRAINING-SANDBOX {FF6600}Кокеточка, Cheater_80_LVL, LINCOLN, qxlies{CDCDCD}
            за помощь в тестировании, и предложениям по улучшению
            ]]
            text = string.gsub(text, "   ", "")
            imgui.TextColoredRGB(text)
            
         elseif tabmenu.credits == 2 then
            imgui.Spacing()
            imgui.TextColoredRGB("TRAINING-{dc143c}CHECKER:")
            imgui.SameLine()
            imgui.Link("https://trainingchecker.vercel.app/", "trainingchecker.vercel.app")
            
            imgui.TextColoredRGB("{90ee90}I{dc143c}D{CDCDCD} моделей объектов в SA-MP и GTA San Andreas:")
            imgui.SameLine()
            imgui.Link("https://dev.prineside.com/ru/gtasa_samp_model_id/", "dev.prineside.com")
            
            imgui.TextColoredRGB("{1e90ff}PawnoKit{CDCDCD} набор инструментов, справочников, каталогов и списков:")
            imgui.SameLine()
            imgui.Link("https://pawnokit.ru/", "pawnokit.ru")
            
            imgui.TextColoredRGB("{1ae4c2}encycolorpedia{CDCDCD} удобная палитра цветов:")
            imgui.SameLine()
            imgui.Link("https://encycolorpedia.ru/", "encycolorpedia.ru")            
            
            
         elseif tabmenu.credits == 3 then
            imgui.Spacing()
            local text = [[Если вы обнаружили ошибку сообщите о ней на форуме.
            Опишите, как и когда появляется ошибка и в чём именно она заключается.
            Чем подробнее будет описание, тем быстрее выйдет исправление этой ошибки.
            При краше тулкита будет полезна информация из moonloader.log.
            Так же вы можете приложить скриншот/видеозапись с воспроизведением ошибки.
            
            Перед публикацией убедитесь что ошибка относится к работе тулкита.
            Вы можете выгрузить тулкит и попробовать воспроизвести проблему без тулкита.
            ]] 
            text = string.gsub(text, "   ", "")
            imgui.Text(u8(text))

            
            imgui.Text(u8"Контакты для связи со мной")
            imgui.SameLine()
            imgui.TextColoredRGB("{6e2aad}Discord:")
            imgui.SameLine()
            imgui.Link("https://discordapp.com/users/625192705772748821", "1NS")
            imgui.SameLine()
            imgui.TextColoredRGB("{1e90ff}Telegram:")
            imgui.SameLine()
            imgui.Link("https://t.me/ins1x", "ins1x")
            
            if imgui.TooltipButton(u8"Сообщить на форуме TRAINING", imgui.ImVec2(200, 25), u8"Нашли баг? сообщите на форуме") then
               sampAddChatMessage("Сейчас вас перенаправит на форум TRAINING SANDBOX", -1)
               os.execute('explorer "https://forum.training-server.com/d/19708-luamappingtoolkit/"')
            end
            imgui.SameLine()
            if imgui.TooltipButton(u8"Сообщить на форуме Blast.hk", imgui.ImVec2(200, 25), u8"Нашли баг? сообщите на форуме") then
               sampAddChatMessage("Сейчас вас перенаправит на форум blast.hk", -1)
               os.execute('explorer "https://www.blast.hk/threads/220636/#post-1540364"')
            end
            -- imgui.Text(u8"Showroom маппинга на")
            -- imgui.SameLine()
            -- imgui.TextColoredRGB("{FFFFFF}You{FF0000}Tube:")
            -- imgui.SameLine()
            -- imgui.Link("https://www.youtube.com/@1nsanemapping/featured", "1nsanemapping")
         end
         imgui.Spacing()
         imgui.Spacing()
         
         if imgui.TooltipButton(u8"Проверить обновления", imgui.ImVec2(180, 25), u8"Проверить наличие обновлений") then
            if not checkScriptUpdates() then
               sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Установлена актуальная версия {696969}"..thisScript().version, -1)
               --os.execute('explorer https://github.com/ins1x/MappingToolkit/releases')
            end
         end
         imgui.SameLine()
         if imgui.Checkbox(u8("Проверять обновления автоматически"), checkbox.checkupdates) then
            ini.settings.checkupdates = checkbox.checkupdates.v
            inicfg.save(ini, configIni)
         end
         if imgui.TooltipButton(u8"Сообщить о ошибке", imgui.ImVec2(180, 25), u8"Жми не стесняйся") then
            tabmenu.credits = 3
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"Управление", imgui.ImVec2(160, 25), u8"Дополнительные возможности") then
            dialog.toolkitmanage.v = not dialog.toolkitmanage.v
         end
         imgui.Spacing()
         imgui.Spacing()
      elseif tabmenu.info == 3 then
         
         imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2, 2))
         if isTrainingSanbox then
            imgui.TextNotify("На TRAINING используется ARGB формат цвета 0xAARRGGBB", 
            u8"Текст чата или цвет игрока выглядит следующим образом: 0xRRGGBBAA.\nFF - цвет будет отображаться без прозрачности, если используется 00 он будет невидимым")
         else
            imgui.TextNotify("Текст чата или цвет игрока выглядит следующим образом: 0xRRGGBBAA.",
            u8"FF - цвет будет отображаться без прозрачности, если используется 00 он будет невидимым")
         end
         imgui.Text(u8"RR - красная часть цвета, GG - зеленая, BB - синяя, AA - альфа")
         imgui.PopStyleVar()
         
         imgui.PushItemWidth(175)
         if tabmenu.colorformat == 1 then
            imgui.ColorPicker4("##ColorPicker4", input.colorpicker, imgui.ColorEditFlags.HEX)
         elseif tabmenu.colorformat == 2 then
            imgui.ColorPicker4("##ColorPicker4", input.colorpicker, imgui.ColorEditFlags.RGB)
         else
            imgui.ColorPicker4("##ColorPicker4", input.colorpicker, imgui.ColorEditFlags.NoInputs)
         end
         -- imgui.SameLine()
         -- local hexcolor = tostring(intToHexRgb(join_argb(input.colorpicker.v[4] * 255,
         -- input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)))
         -- if imgui.Selectable("HEX: " .. string.upper(hexcolor), false, 0, imgui.ImVec2(80, 15)) then
            -- setClipboardText(string.upper(hexcolor))
            -- textbuffer.colorsearch.v = string.upper(hexcolor)
            -- sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
         -- end
         -- imgui.SameLine()
         -- imgui.TextQuestion("( ? )", u8"Нажмите чтобы скопировать цвет в буффер обмена")
         -- imgui.PopItemWidth()
         
         if tabmenu.colorformat == 3 then
            imgui.Button(string.format("A:%i", input.colorpicker.v[4]*255))
            imgui.SameLine()
            imgui.Button(string.format("R:%i", input.colorpicker.v[1]*255))
            imgui.SameLine()
            imgui.Button(string.format("G:%i", input.colorpicker.v[2]*255))
            imgui.SameLine()
            imgui.Button(string.format("B:%i", input.colorpicker.v[3]*255))
         elseif tabmenu.colorformat == 4 then
            imgui.Button(string.format("R:%.2f", input.colorpicker.v[1]))
            imgui.SameLine()
            imgui.Button(string.format("G:%.2f", input.colorpicker.v[2]))
            imgui.SameLine()
            imgui.Button(string.format("B:%.2f", input.colorpicker.v[3]))
            imgui.SameLine()
            imgui.Button(string.format("A:%.2f", input.colorpicker.v[4]))
         elseif tabmenu.colorformat == 5 then
            imgui.Button(string.format("A:%i", input.colorpicker.v[4]*255))
            imgui.SameLine()
            imgui.Button(string.format("B:%i", input.colorpicker.v[3]*255))
            imgui.SameLine()
            imgui.Button(string.format("G:%i", input.colorpicker.v[2]*255))
            imgui.SameLine()
            imgui.Button(string.format("R:%i", input.colorpicker.v[1]*255))
         elseif tabmenu.colorformat == 6 then
            imgui.Button(string.format("A:%i", input.colorpicker.v[4]*255))
            imgui.SameLine()
            imgui.Button(string.format("R:%i", input.colorpicker.v[1]*255))
            imgui.SameLine()
            imgui.Button(string.format("G:%i", input.colorpicker.v[2]*255))
            imgui.SameLine()
            imgui.Button(string.format("B:%i", input.colorpicker.v[3]*255))
         end
         
           --imgui.SameLine()
         if tabmenu.colorformat == 1 then
            local hexcolor = tostring(intToHexRgb(join_argb(input.colorpicker.v[4] * 255,
            input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)))
            imgui.Text("HEX:")
            imgui.SameLine()
            if imgui.Selectable(string.upper(hexcolor), false, 0, imgui.ImVec2(110, 15)) then
               setClipboardText(string.upper(hexcolor))
               textbuffer.colorsearch.v = string.upper(hexcolor)
               sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
            end
         end
         if tabmenu.colorformat == 2 then
            local color = tostring(intToHexArgb(join_argb(input.colorpicker.v[1] * 255,
            input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255, input.colorpicker.v[4] * 255)))
            imgui.Text("RGBA:")
            imgui.SameLine()
            if imgui.Selectable(string.upper(color), false, 0, imgui.ImVec2(100, 15)) then
               setClipboardText(string.upper(color))
               textbuffer.colorsearch.v = string.upper(color)
               sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
            end
         end
         if tabmenu.colorformat == 3 then
            local color = tostring(intToHexArgb(join_argb(input.colorpicker.v[4] * 255,
            input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)))
            imgui.Text("ARGB:")
            imgui.SameLine()
            if imgui.Selectable(string.upper(color), false, 0, imgui.ImVec2(100, 15)) then
               setClipboardText(string.upper(color))
               textbuffer.colorsearch.v = string.upper(color)
               sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
            end
         end
         if tabmenu.colorformat == 4 then
            local color = string.format("%.2f %.2f %.2f %.2f", 
            input.colorpicker.v[1], input.colorpicker.v[2], 
            input.colorpicker.v[3], input.colorpicker.v[4])
            imgui.Text("Float:")
            imgui.SameLine()
            if imgui.Selectable(tostring(color), false, 0, imgui.ImVec2(110, 15)) then
               setClipboardText(string.upper(color))
               textbuffer.colorsearch.v = string.upper(color)
               sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
            end
         end
         if tabmenu.colorformat == 5 then
            local color = tostring(intToHexArgb(join_argb(input.colorpicker.v[4] * 255,
            input.colorpicker.v[3] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[1] * 255)))
            imgui.Text("ABGR:")
            imgui.SameLine()
            if imgui.Selectable(string.upper(color), false, 0, imgui.ImVec2(100, 15)) then
               setClipboardText(string.upper(color))
               textbuffer.colorsearch.v = string.upper(color)
               sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
            end
         end
         if tabmenu.colorformat == 6 then
            -- input.colorpicker.v[4] * 255
            local color = join_argb(input.colorpicker.v[4] * 255,
            input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)
            imgui.Text("INT32:")
            imgui.SameLine()
            if imgui.Selectable(tostring(color), false, 0, imgui.ImVec2(100, 15)) then
               setClipboardText(tostring(color))
               textbuffer.colorsearch.v = string.upper(color)
               sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
            end
         end
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Нажмите чтобы скопировать цвет в буффер обмена")
         imgui.PopItemWidth()
         
         if tabmenu.colorformat == 2 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"RGBA", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 2 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"RGBA", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 2 end
         end
         imgui.SameLine()
         if tabmenu.colorformat == 3 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"ARGB", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 3 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"ARGB", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 3 end
         end
         imgui.SameLine()
         if tabmenu.colorformat == 5 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"ABGR", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 5 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"ABGR", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 5 end
         end
         
         if tabmenu.colorformat == 1 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"HEX", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 1 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"HEX", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 1 end
         end
         imgui.SameLine()
         if tabmenu.colorformat == 6 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Int32", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 6 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Int32", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 6 end
         end
         imgui.SameLine()
         if tabmenu.colorformat == 4 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Float", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 4 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Float", imgui.ImVec2(55, 25)) then tabmenu.colorformat = 4 end
         end
         
         imgui.SameLine()
         imgui.Text(u8" Поиск произвольного цвета:")
         imgui.SameLine()
         imgui.TextQuestion("( ? )", u8"Поиск в палитре по имени,коду,значению на сайте encycolorpedia.ru")
         
         if imgui.TooltipButton(u8"Скопировать", imgui.ImVec2(115, 25), u8"Скопировать цвет в буффер обмена") then
            local color = ""
            if tabmenu.colorformat == 1 then
               local hexcolor = tostring(intToHexRgb(join_argb(input.colorpicker.v[4] * 255,
               input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)))
               color = string.upper(hexcolor)
            elseif tabmenu.colorformat == 2 then
               color = string.format("%i %i %i %.i", 
               input.colorpicker.v[1]*255, input.colorpicker.v[2]*255, 
               input.colorpicker.v[3]*255, input.colorpicker.v[4]*255)
            elseif tabmenu.colorformat == 3 then
               color = string.format("%i %i %i %.i", 
               input.colorpicker.v[4]*255, input.colorpicker.v[1]*255, 
               input.colorpicker.v[2]*255, input.colorpicker.v[3]*255)
            elseif tabmenu.colorformat == 4 then
               color = string.format("%.2f %.2f %.2f %.2f", 
               input.colorpicker.v[1], input.colorpicker.v[2], 
               input.colorpicker.v[3], input.colorpicker.v[4])
            elseif tabmenu.colorformat == 5 then
               color = tostring(intToHexArgb(join_argb(input.colorpicker.v[4] * 255,
               input.colorpicker.v[3] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[1] * 255)))
            elseif tabmenu.colorformat == 6 then
               color = join_argb(input.colorpicker.v[4] * 255,
               input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)
            end
            setClipboardText(color)
            local hexcolor = tostring(intToHexRgb(join_argb(input.colorpicker.v[4] * 255,
            input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)))
            textbuffer.colorsearch.v = string.upper(hexcolor)
            sampAddChatMessage("Цвет скопирован в буффер обмена", -1)
         end
         imgui.SameLine()
         if imgui.TooltipButton(u8"Инфо", imgui.ImVec2(55, 25), 
         u8"Покажет полную информацию по цвету через сайт encycolorpedia.ru") then
            local color = tostring(intToHexRgb(join_argb(input.colorpicker.v[4] * 255,
            input.colorpicker.v[1] * 255, input.colorpicker.v[2] * 255, input.colorpicker.v[3] * 255)))
            color = string.upper(color)
            local link = 'explorer "https://encycolorpedia.ru/search?q='..color..'"'
            os.execute(link)
         end
         
         imgui.SameLine()
         imgui.PushItemWidth(170)
         if imgui.InputText("##colorsearch", textbuffer.colorsearch) then
         end
         imgui.PopItemWidth()
         imgui.SameLine()
         if imgui.TooltipButton(u8"Найти", imgui.ImVec2(60, 25), 
         u8"Найти цвет на сайте encycolorpedia.ru") then
            if string.len(textbuffer.colorsearch.v) > 2 then
               local link = 'explorer "https://encycolorpedia.ru/search?q='..tostring(textbuffer.colorsearch.v..'"')
               os.execute(link)
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите цвет для поиска!", 0x0FF6600)
            end
         end
         imgui.Spacing()
         
         if imgui.CollapsingHeader(u8"Стандартные RGB цвета") then
            imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(1, 1))
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
            if imgui.Button("{FF0000}  RED    ", imgui.ImVec2(120, 24)) then
               setClipboardText("{FF0000}")
               sampAddChatMessage("Цвет {FF0000}RED{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(1.0, 0.0, 0.0, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.0, 1.0))
            imgui.SameLine()
            if imgui.Button("{008000}  GREEN ", imgui.ImVec2(120, 24)) then 
               setClipboardText("{008000}")
               sampAddChatMessage("Цвет {008000}GREEN{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.0, 0.5, 0.0, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 1.0, 1.0))
            imgui.SameLine()
            if imgui.Button("{0000FF}  BLUE  ", imgui.ImVec2(120, 24)) then
               setClipboardText("{0000FF}")
               sampAddChatMessage("Цвет {0000FF}BLUE{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.0, 0.0, 1.0, 1.0)
            end
            imgui.PopStyleColor()
            
       --    next line
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 0.0, 1.0))
            if imgui.Button("{FFFF00}  YELLOW", imgui.ImVec2(120, 24)) then
               setClipboardText("{FFFF00}")
               sampAddChatMessage("Цвет {FFFF00}YELLOW{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(1.0, 1.0, 0.0, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.0, 1.0, 1.0))
            imgui.SameLine()
            if imgui.Button("{FF00FF}  PINK  ", imgui.ImVec2(120, 24)) then
               setClipboardText("{FF00FF}")
               sampAddChatMessage("Цвет {FF00FF}PINK{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(1.0, 0.0, 1.0, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 1.0, 1.0))
            imgui.SameLine()
            if imgui.Button("{00FFFF}  AQUA  ", imgui.ImVec2(120, 24)) then
               setClipboardText("{00FFFF}")
               sampAddChatMessage("Цвет {00FFFF}AQUA{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.0, 1.0, 1.0, 1.0)
            end
            imgui.PopStyleColor()
            
       --    next line
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 1.0, 0.0, 1.0))
            if imgui.Button("{00FF00}  LIME  ", imgui.ImVec2(120, 24)) then 
               setClipboardText("{00FF00}")
               sampAddChatMessage("Цвет {00FF00}LIME{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.0, 1.0, 0.0, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.5, 1.0))
            imgui.SameLine()
            if imgui.Button("{800080}  PURPLE", imgui.ImVec2(120, 24)) then
               setClipboardText("{800080}")
               sampAddChatMessage("Цвет {800080}PURPLE{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.5, 0.0, 0.5, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.0, 0.0, 1.0))
            imgui.SameLine()
            if imgui.Button("{800000}  MAROON", imgui.ImVec2(120, 24)) then
               setClipboardText("{800000}")
               sampAddChatMessage("Цвет {800000}MAROON{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.5, 0.0, 0.0, 1.0)
            end
            imgui.PopStyleColor()
            
       --    next line
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.0, 1.0))
            if imgui.Button("{808000}  OLIVE ", imgui.ImVec2(120, 24)) then
               setClipboardText("{808000}")
               sampAddChatMessage("Цвет {808000}OLIVE{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.5, 0.5, 0.0, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.5, 0.5, 1.0))
            imgui.SameLine()
            if imgui.Button("{008080}  TEAL  ", imgui.ImVec2(120, 24)) then
               setClipboardText("{008080}")
               sampAddChatMessage("Цвет {008080}TEAL{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.0, 0.5, 0.5, 1.0)
            end     
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 0.6, 0.0, 1.0))
            imgui.SameLine()
            if imgui.Button("{FF9900}  ORANGE", imgui.ImVec2(120, 24)) then
               setClipboardText("{FF9900}")
               sampAddChatMessage("Цвет {FF9900}ORANGE{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(1.0, 0.6, 0.0, 1.0)
            end
            imgui.PopStyleColor()
            
            -- next line
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
            if imgui.Button("{FFFFFF}  WHITE ", imgui.ImVec2(120, 24)) then 
               setClipboardText("{FFFFFF}")
               sampAddChatMessage("Цвет WHITE скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(1.0, 1.0, 1.0, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
            imgui.SameLine()
            if imgui.Button("{808080}  GREY  ", imgui.ImVec2(120, 24)) then 
               setClipboardText("{808080}")
               sampAddChatMessage("Цвет {808080}GREY{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.5, 0.5, 0.5, 1.0)
            end
            imgui.PopStyleColor()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
            imgui.SameLine()
            if imgui.Button("{000000}  BLACK ", imgui.ImVec2(120, 24)) then
               setClipboardText("{000000}")
               sampAddChatMessage("Цвет {000000}BLACK{FFFFFF} скопирован в буффер обмена", -1)
               input.colorpicker = imgui.ImFloat4(0.0, 0.0, 0.0, 1.0)
            end
            
            imgui.PopStyleVar()
            imgui.PopStyleColor()
         end

         if imgui.CollapsingHeader(u8"Тест RGB текста") then
            imgui.Text(u8"Тест RGB текста, например введите: {00FF00}Текст")
            imgui.PushItemWidth(375)
            if imgui.InputText("##RGBtext", textbuffer.rgb) then
            end
            imgui.PopItemWidth()
            imgui.TextColoredRGB(u8:decode(textbuffer.rgb.v))
            
            if imgui.Button(u8"Скопировать") then
               setClipboardText(textbuffer.rgb.v)
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Текст скопирован в буффер обмена", 0x0FF6600)
            end
            imgui.SameLine()
            if imgui.Button(u8"Сбросить") then
               textbuffer.rgb.v = ""
               imgui.resetIO()
            end
            imgui.SameLine()
            if imgui.Button(u8"Отправить в чат") then
               sampSetChatInputEnabled(true)
               sampSetChatInputText(u8:decode(textbuffer.rgb.v))
            end
            imgui.SameLine()
            if imgui.Button(u8"Протестировать") then
               sampAddChatMessage(u8:decode(textbuffer.rgb.v), -1)
            end
         end
         
         if imgui.CollapsingHeader(u8"Тест GameText") then
            imgui.TextColoredRGB("Пример: {FFFFFF}~w~Hello this is {0000FF}~b~blue {FFFFFF}~w~and this is {FF0000}~r~red")
            imgui.SameLine()
            imgui.TextQuestion(u8" [ ] ", u8"Вставить текст из примера")
            if imgui.IsItemClicked() then
               textbuffer.gametextclr.v = "~w~Hello this is ~b~blue ~w~and this is ~r~red"
            end

            local gametextstyles = {
               "Style 0", "Style 1", "Style 2", "Style 3", "Style 4", "Style 5", "Style 6"
            }
            
            imgui.PushItemWidth(100)
            imgui.Combo(u8'##GameTextStylesCombo', combobox.gametextstyles, gametextstyles)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.PushItemWidth(55)
            imgui.InputInt('ms.##GameTextTime', input.gametexttime, 0)
            imgui.PopItemWidth()
            imgui.SameLine()
            imgui.TextQuestion(u8"   Подсказка по цветам", [[
            ~r~    red
            ~g~    green
            ~b~    blue
            ~w~    white
            ~y~    yellow
            ~p~    purple
            ~l~    black
            ~h~    lighter color
            ]])
            imgui.PushItemWidth(375)
            if imgui.InputText("##GameTextClr", textbuffer.gametextclr) then
            end
            imgui.PopItemWidth()
            
            if imgui.Button(u8"Скопировать") then
               setClipboardText(textbuffer.gametextclr.v)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Текст скопирован в буффер обмена", 0x0FF6600)
            end
            imgui.SameLine()
            if imgui.Button(u8"Сбросить") then
               textbuffer.gametextclr.v = ""
               imgui.resetIO()
            end
            imgui.SameLine()
            if imgui.Button(u8"Протестировать") then
               if string.len(textbuffer.gametextclr.v) <= 1 then
                  printStyledString("~y~Style "..combobox.gametextstyles.v.."~n~~<~ ~>~", 5000, combobox.gametextstyles.v)
               else
                  local style = combobox.gametextstyles.v - 1
                  printStyledString(u8:decode(textbuffer.gametextclr.v), input.gametexttime.v, style)
               end
            end
         end
         
      elseif tabmenu.info == 4 then
         
         local id = getLocalPlayerId()
         local score
         if sampGetPlayerScore(id) then
            score = sampGetPlayerScore(id)
         end
         local ip, port = sampGetCurrentServerAddress()
         local major, minor, majorRev, minorRev, game, region, steam, cracked = getGameVersion()
         local scriptParams = thisScript()
         local sampversion = getSampVersionId()
         
         imgui.TextColoredRGB("script: {FF6600}"..scriptParams.name.."{CDCDCD} version {FF6600}"..scriptParams.version)
         if sampversion then
            imgui.SameLine()
            imgui.TextColoredRGB("sa-mp:")
            imgui.SameLine()
            imgui.TextColoredRGB(tostring("{FF6600}0.3.7 R"..sampversion))
         end
         imgui.TextColoredRGB("path: {FF6600}"..scriptParams.path)
         --imgui.Text(u8"directory: "..scriptParams.directory)
         --imgui.Text(u8"filename: "..scriptParams.filename)
         --imgui.Text(u8"scriptid: "..scriptParams.id.." dead: "..tostring(scriptParams.dead).." frozen: "..tostring(scriptParams.frozen))
         
         if not isGameVersionOriginal() then
            imgui.TextColoredRGB(string.format("{FF0000}Not original game version %s.%s.%s.%s", major, minor, majorRev, minorRev))
         end
         if steam then
            imgui.TextColoredRGB(string.format("{FF0000}Steam game version %s.%s.%s.%s", major, minor, majorRev, minorRev))
         end
         
         if imgui.CollapsingHeader(u8"Состояние:") then
            
            local cursormode = sampGetCursorMode()
            local cursormodesList = {
               u8"0 - Отключен",
               u8"1 - Управление клавиатурой заблокировано, курсор отключен",
               u8"2 - Управление клавиатурой и мышкой заблокировано, курсор включен",
               u8"3 - Управление мышкой заблокировано, курсор включен",
               u8"4 - Управление мышкой заблокировано, курсор отключен"
            }
            
            imgui.Text(string.format(u8"В игре: %.0f сек.", localClock()))
            imgui.Text(playerdata.isPlayerSpectating and u8('В наблюдении: Да') or u8('В наблюдении: Нет'))
            imgui.Text(playerdata.flymode and u8('В режиме полета: Да') or u8('В режиме полета: Нет'))
            imgui.Text(isPlayerControlLocked(playerPed) and u8('Управление: Заблокированно') or u8('Управление: Доступно'))
            imgui.Text(sampIsLocalPlayerSpawned() and u8('Заспавнен: Да') or u8('Заспавнен: Нет'))
            imgui.Text(string.format(u8"Курсор: %s", cursormodesList[cursormode+1]))
            imgui.Spacing()
            if imgui.Button(u8'Выйти из спектатора', imgui.ImVec2(180, 25)) then
               local bs = raknetNewBitStream()
               raknetBitStreamWriteInt32(bs, 0)
               raknetEmulRpcReceiveBitStream(124, bs)
               raknetDeleteBitStream(bs)
            end   
                  
            imgui.SameLine()
            if imgui.Button(u8'Войти в спектатор', imgui.ImVec2(180, 25)) then
               local bs = raknetNewBitStream()
               raknetBitStreamWriteInt32(bs, 1)
               raknetEmulRpcReceiveBitStream(124, bs)
               raknetDeleteBitStream(bs)
            end            
            imgui.SameLine()
            if imgui.Button(u8'Режим полета', imgui.ImVec2(120, 25)) then
               toggleFlyMode()
               
               if ini.settings.hotkeystips and playerdata.flymode then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Управление в режиме полета:", 0x0FF6600)
                  sampAddChatMessage("[SCRIPT]: Пробел{FFFFFF} - Вверх, {FF6600}левый SHIFT{FFFFFF} - Вниз.", 0x0FF6600)
                  sampAddChatMessage("[SCRIPT]: WASD{FFFFFF} - перемещение по координатам.", 0x0FF6600)
                  sampAddChatMessage("[SCRIPT]: Кнопки мыши{FFFFFF} - ускорение/замедление.", 0x0FF6600)
                  sampAddChatMessage("[SCRIPT]: F/ENTER{FFFFFF} - выйти из режима полета.", 0x0FF6600)
               end
            end

            if imgui.Button(u8'Заморозить на позиции', imgui.ImVec2(180, 25)) then
               freezeCharPosition(playerPed, true)
            end
            imgui.SameLine()
            if imgui.Button(u8'Разморозить', imgui.ImVec2(180, 25)) then
               freezeCharPosition(playerPed, false)
               setPlayerControl(PLAYER_HANDLE, true)
               lockPlayerControl(false)
               clearCharTasksImmediately(playerPed)
            end
            imgui.SameLine()
            if imgui.Button(u8'ForceSync', imgui.ImVec2(120, 25)) then
               sampForceAimSync()
               sampForceOnfootSync()
               sampForceStatsSync()
               sampForceWeaponsSync()
            end
            
            if imgui.Button(u8'Взять Jetpack', imgui.ImVec2(120, 25)) then
               taskJetpack(playerPed)
            end
            imgui.SameLine()
            if imgui.Button(u8'Выбор класса', imgui.ImVec2(120, 25)) then
               local skin = getCharModel(playerPed)
               sampRequestClass(skin)
               --setPlayerModel(skin)
            end
         end
         
         if imgui.CollapsingHeader(u8"Logging:") then

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
            imgui.Spacing()
            imgui.Text(u8"Логгировать в консоли:")
            imgui.Checkbox(u8'Логгировать в консоли обработку текстдравов', checkbox.logtextdraws)
            imgui.Checkbox(u8'Логгировать в консоли поднятые пикапы', checkbox.pickeduppickups)
            imgui.Checkbox(u8'Логгировать в консоли ответы на диалоги', checkbox.logdialogresponse)
            imgui.Checkbox(u8'Логгировать в консоли выбранные объекты', checkbox.logobjects)
            imgui.Checkbox(u8'Логгировать в консоли 3d тексты', checkbox.log3dtexts)
            imgui.Checkbox(u8'Логгировать в консоли Gametexts', checkbox.loggametexts)
            imgui.Checkbox(u8'Логгировать в консоли установку текстуры', checkbox.logtxd)
            imgui.Checkbox(u8'Логгировать в консоли изменение камеры', checkbox.logcamset)
            imgui.Checkbox(u8'Логгировать в консоли сообщения в чате', checkbox.logmessages)
            imgui.Checkbox(u8'Логгировать в консоли изменение границ мира', checkbox.logworlddouns)
            imgui.Checkbox(u8'Логгировать в консоли изменение позиции игрока', checkbox.logsetplayerpos)
            
         end
         
         if imgui.CollapsingHeader(u8"NOP's:") then
            imgui.TextColoredRGB("{FF0000}Использование данных функций может триггерить античит!")
            imgui.Checkbox(u8'TogglePlayerSpectating', nops.spectator)
            imgui.SameLine()
            imgui.Checkbox(u8'SetPlayerHealth    ', nops.health)
            imgui.SameLine()
            imgui.Checkbox(u8'GivePlayerWeapon', nops.givegun)
            imgui.Checkbox(u8'ResetPlayerWeapons    ', nops.resetgun)
            imgui.SameLine()
            imgui.Checkbox(u8'ShowDialog            ', nops.showdialog)
            imgui.SameLine()
            imgui.Checkbox(u8'ApplyAnimation', nops.applyanimation)
            imgui.Checkbox(u8'ClearAnimation            ', nops.clearanimation)
            imgui.SameLine()
            imgui.Checkbox(u8'SetArmedWeapon  ', nops.setgun)
            imgui.SameLine()
            imgui.Checkbox(u8'Spawn', nops.spawn)
            imgui.Checkbox(u8'Death                           ', nops.death)
            imgui.SameLine()
            imgui.Checkbox(u8'Player Sync            ', nops.psync)
            imgui.SameLine()
            imgui.Checkbox(u8'RequestClass', nops.requestclass)
            imgui.Checkbox(u8'RequestSpawn              ', nops.requestspawn)
            imgui.SameLine()
            imgui.Checkbox(u8'ClickTextdraw       ', nops.clicktextdraw)
            imgui.SameLine()
            imgui.Checkbox(u8'SelectTextdraw', nops.selecttextdraw)
            imgui.Checkbox(u8'ForceClassSelection      ', nops.forceclass)
            imgui.SameLine()
            imgui.Checkbox(u8'ToggleControllable', nops.togglecontrol)
            imgui.SameLine()
            imgui.Checkbox(u8'FacingAngle', nops.facingangle)
            imgui.Checkbox(u8'SetPlayerSkin                ', nops.setskin)
            imgui.SameLine()
            imgui.Checkbox(u8'SetDrunkLevel      ', nops.setdrunk)
            imgui.SameLine()
            imgui.Checkbox(u8'SetSpecialAction', nops.setspecialaction)
         end
         
         if imgui.CollapsingHeader(u8"Dialogs:") then
            dialogStyles = {
            "DIALOG_STYLE_MSGBOX",
            "DIALOG_STYLE_INPUT", 
            "DIALOG_STYLE_LIST",
            "DIALOG_STYLE_PASSWORD",
            "DIALOG_STYLE_TABLIST",
            "DIALOG_STYLE_TABLIST_HEADERS"
            }
            if LastData.lastDialogInput then
               if LastData.lastDialogStyle == 3 then
                  local newtext = LastData.lastDialogInput:gsub("(.*)", "*")
                  imgui.TextColoredRGB("DialogInput: "..newtext)
               else
                  imgui.TextColoredRGB("DialogInput: "..LastData.lastDialogInput)
                  imgui.SameLine()
                  imgui.TextQuestion("[]", u8"Скопировать текст в буффер обмена")
                  if imgui.IsItemClicked() then
                     sampAddChatMessage("Текст скопирован в буффер обмена", -1)
                     setClipboardText(LastData.lastDialogInput)
                  end
               end
            end
            if LastData.lastDialogButton then
               imgui.Text(u8"DialogButton: "..LastData.lastDialogButton)
            end
            if LastData.lastDialogStyle then
               imgui.TextColoredRGB(("DialogStyle: %i {696969}(%s)"):format(LastData.lastDialogStyle, dialogStyles[LastData.lastDialogStyle+1]))
            end
            if LastData.lastListboxId then
               imgui.Text(u8"ListboxId: "..LastData.lastListboxId)
            end
            if sampGetCurrentDialogId() ~= 0 then
               imgui.Text(u8"ListboxItemsCount: "..sampGetListboxItemsCount())
               imgui.Text(u8"DialogListItem: "..sampGetCurrentDialogListItem())
            end
            if imgui.Button(u8'Текст диалога', imgui.ImVec2(130, 25)) then
               if LastData.lastDialogText then
                  textbuffer.dialogtext.v = tostring(LastData.lastDialogText)
                  dialog.dialogtext.v = not dialog.dialogtext.v
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Нет информации по последнему диалогу!", 0x0FF6600)
               end
            end            
            imgui.SameLine()
            if imgui.Button(u8'Скрыть диалог', imgui.ImVec2(130, 25)) then
               enableDialog(false)
            end
            imgui.SameLine()
            imgui.Text(u8'Последний ID диалога: ' .. sampGetCurrentDialogId())
         end
         
      elseif tabmenu.info == 5 then
         
         local symbols = 0
         local lines = 1
         local filepath = nil
         
         if tabmenu.favorites == 1 then
            filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//favorites//objects.txt"
            symbols = string.len(textbuffer.favobjects.v)/2
            for s in string.gmatch(textbuffer.favobjects.v, "\n" ) do
               lines = lines + 1
            end
         elseif tabmenu.favorites == 2 then
            filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//favorites//textures.txt"
            symbols = string.len(textbuffer.favtxd.v)/2
            for s in string.gmatch(textbuffer.favtxd.v, "\n" ) do
               lines = lines + 1
            end
         elseif tabmenu.favorites == 3 then
            filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//favorites//textsurfaces.txt"
            symbols = string.len(textbuffer.favtxt.v)/2
            for s in string.gmatch(textbuffer.favtxt.v, "\n" ) do
               lines = lines + 1
            end
         end
         
         imgui.Spacing()
         
         imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2, 0))
         if tabmenu.favorites == 1 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Объекты", imgui.ImVec2(120, 25)) then tabmenu.favorites = 1 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Объекты", imgui.ImVec2(120, 25)) then tabmenu.favorites = 1 end
         end
         imgui.SameLine()
         if tabmenu.favorites == 2 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Текстуры", imgui.ImVec2(120, 25)) then tabmenu.favorites = 2 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Текстуры", imgui.ImVec2(120, 25)) then tabmenu.favorites = 2 end
         end
         imgui.SameLine()
         if tabmenu.favorites == 3 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Поверхности", imgui.ImVec2(120, 25)) then tabmenu.favorites = 3 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Поверхности", imgui.ImVec2(120, 25)) then tabmenu.favorites = 3 end
         end
         imgui.PopStyleVar()
         
         if tabmenu.favorites == 1 then
            imgui.PushFont(fonts.multilinetextfont)
            if input.readonly then
               imgui.InputTextMultiline('##favobjects', textbuffer.favobjects, imgui.ImVec2(490, 340),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
            else 
               imgui.InputTextMultiline('##favobjects', textbuffer.favobjects, imgui.ImVec2(490, 340),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
            end
            imgui.PopFont()
         elseif tabmenu.favorites == 2 then            
            imgui.PushFont(fonts.multilinetextfont)
            if input.readonly then
               imgui.InputTextMultiline('##favtxd', textbuffer.favtxd, imgui.ImVec2(490, 340),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
            else 
               imgui.InputTextMultiline('##favtxd', textbuffer.favtxd, imgui.ImVec2(490, 340),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
            end
            imgui.PopFont()
         elseif tabmenu.favorites == 3 then
            imgui.PushFont(fonts.multilinetextfont)
            if input.readonly then
               imgui.InputTextMultiline('##favtxt', textbuffer.favtxt, imgui.ImVec2(490, 300),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
            else 
               imgui.InputTextMultiline('##favtxt', textbuffer.favtxt, imgui.ImVec2(490, 300),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
            end
            imgui.Spacing()
            imgui.PushItemWidth(170)
            if imgui.Combo(u8'< Выбор шрифта##comboboxfontname', combobox.fonts, PopularFonts) then
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.TooltipButton(u8"Просмотреть", imgui.ImVec2(120, 25), u8"Превью набора символов в шрифте (онлайн)") then
               local fontlink = string.format('explorer "https://flamingtext.ru/Font-Search?q=%s"', tostring(PopularFonts[combobox.fonts.v+1]))
               os.execute(fontlink)
            end
            
            -- local fontlink
            -- imgui.Spacing()
            -- for k, fontname in pairs(PopularFonts) do
               -- fontlink = string.format("https://flamingtext.ru/Font-Search?q=%s", fontname)
               -- if k%2 == 0 then
                  -- imgui.SameLine()
               -- end
               -- imgui.Link(fontlink, fontname)
            -- end
            
            -- imgui.Spacing()
            -- imgui.Text(u8"Пример использования:")
            -- imgui.TextColoredRGB(u8'SetObjectMaterialText(string, "TEST", 0, 140, "webdings", 150, 0, -65536, 0, 1);')
            -- imgui.TextColoredRGB("Максимальный размер шрифта 255")
            
            imgui.PopFont()
            -- --imgui.SameLine()
            -- if imgui.Selectable(input.readonly and "RO" or "W", false, 0, imgui.ImVec2(25, 15)) then
               -- input.readonly = not input.readonly
            -- end
            -- imgui.SameLine()
            -- if imgui.Selectable("Unlock IO", false, 0, imgui.ImVec2(50, 15)) then
               -- imgui.resetIO()
            -- end
            -- imgui.SameLine()
            -- imgui.TextQuestion("( ? )", u8"RO - Включить режим ReadOnly\nUnlock IO - разблокировать инпут если курсор забагался")
         end
         
         if tabmenu.favorites == 1 then
            imgui.TextColoredRGB("Не нашли нужный объект? вам сюда")
            imgui.SameLine()
            imgui.Link("https://dev.prineside.com/ru/gtasa_samp_model_id/", "dev.prineside.com")
         elseif tabmenu.favorites == 2 then
            imgui.TextColoredRGB("Топлист текстур онлайн:")
            imgui.SameLine()
            imgui.Link("https://textures.xyin.ws/?page=toplist", "https://textures.xyin.ws/?page=toplist")
         elseif tabmenu.favorites == 3 then
            imgui.TextColoredRGB("Список всех спецсимволов:")
            imgui.SameLine()
            imgui.Link("https://pawnokit.ru/ru/spec_symbols", "pawnokit.ru")
         end
         
         --if tabmenu.favorites ~= 3 then
         if imgui.TooltipButton(u8"Обновить", imgui.ImVec2(80, 25), u8:encode("Повторно загрузить текст из файла")) then
            local file = io.open(filepath, "r")
            if tabmenu.favorites == 1 then
               textbuffer.favobjects.v = file:read('*a')
            elseif tabmenu.favorites == 2 then
               textbuffer.favtxd.v = file:read('*a')
            elseif tabmenu.favorites == 3 then
               textbuffer.favtxt.v = file:read('*a')
            end
            file:close()
         end
         imgui.SameLine()
         if input.readonly then
            if imgui.TooltipButton(u8"Изменить", imgui.ImVec2(80, 25), u8:encode("Разблокировать для редактирования")) then
               input.readonly = false
            end
         else
            if imgui.TooltipButton(u8"Сохранить", imgui.ImVec2(80, 25), u8:encode("Завершить редактирование")) then
               input.readonly = true
               local file = io.open(filepath, "w")
               if tabmenu.favorites == 1 then
                  file:write(textbuffer.favobjects.v)
               elseif tabmenu.favorites == 2 then
                  file:write(textbuffer.favtxd.v)
               elseif tabmenu.favorites == 3 then
                  file:write(textbuffer.favtxt.v)
               end
               file:close()
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Сохранено в файл: {696969}"..filepath, 0x0FF6600)
            end
         end

         -- if not input.readonly then
            -- imgui.SameLine()
            -- if imgui.TooltipButton(u8"Сохранить", imgui.ImVec2(80, 25), u8:encode("Сохранить избранные")) then
               -- if not input.readonly then
                  -- local file = io.open(filepath, "w")
                  -- file:write(textbuffer.favobjects.v)
                  -- file:close()
                  -- sampAddChatMessage("Сохранено в файл: /moonloader/resource/mappingtoolkit/favorites/objects.txt", -1)
               -- else
                  -- sampAddChatMessage("Недоступно в режмие для чтения. Снимте режим RO (Readonly)", -1)
               -- end
            -- end
         -- end
         imgui.SameLine()
         imgui.PushItemWidth(200)
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
         
         
      elseif tabmenu.info == 6 then
         local filepath = nil
         
         if tabmenu.cmds ~= 3 then
            if tabmenu.cmds == 1 then
               filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//cmdlist.txt"
               if imgui.TooltipButton("/cmds", imgui.ImVec2(75, 25), u8"Стандартный список серверных команд") then
                  sampSendChat("/cmds")
                  dialog.main.v = false
               end
            elseif tabmenu.cmds == 2 then
               filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//anims.txt"
               if imgui.TooltipButton("/animlist", imgui.ImVec2(75, 25), u8"Стандартный список серверных анимаций") then
                  sampSendChat("/animlist")
                  dialog.main.v = false
               end
            end
            
            imgui.SameLine()
            imgui.PushItemWidth(190)
            imgui.InputText("##search", textbuffer.searchbar)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.TooltipButton(u8"Поиск##Search", imgui.ImVec2(60, 25), u8:encode("Поиск по списку")) then
               local results = 0
               local resultline = 0
               if string.len(textbuffer.searchbar.v) > 0 then
                  -- ini.tmp.searchbar = textbuffer.searchbar.v
                  -- inicfg.save(ini, configIni)
                  for line in io.lines(filepath) do
                     resultline = resultline + 1
                     if line:find(textbuffer.searchbar.v, 1, true) then
                        results = results + 1
                        --sampAddChatMessage("Строка "..resultline.." : "..u8:decode(line), -1)
                        sampAddChatMessage(u8:decode(line), -1)
                     end
                  end
               end
               if not results then
                  sampAddChatMessage("Результат поиска: Не найдено", -1)
               end
            end
            imgui.SameLine()
            if tabmenu.cmds == 1 then
               imgui.TextQuestion("( ? )", u8"Найти необходимую команду можно /findcmd <text>")
            elseif tabmenu.cmds == 2 then
               imgui.TextQuestion("( ? )", u8"Найти необходимую анимацию можно командой /findanim <text>")
            end
         end
         
         imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2, 0))
         if tabmenu.cmds == 1 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Список команд", imgui.ImVec2(120, 25)) then tabmenu.cmds = 1 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Список команд", imgui.ImVec2(120, 25)) then tabmenu.cmds = 1 end
         end
         imgui.SameLine()
         if tabmenu.cmds == 2 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Анимации", imgui.ImVec2(120, 25)) then tabmenu.cmds = 2 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Анимации", imgui.ImVec2(120, 25)) then tabmenu.cmds = 2 end
         end
         imgui.PopStyleVar()
            
         if tabmenu.cmds == 1 then         
            imgui.PushFont(fonts.multilinetextfont)
            if input.readonly then
               imgui.InputTextMultiline('##cmdlist', textbuffer.cmdlist, imgui.ImVec2(490, 330),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
            else 
               imgui.InputTextMultiline('##cmdlist', textbuffer.cmdlist, imgui.ImVec2(490, 330),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
            end
            imgui.PopFont()
            
            imgui.Spacing()
            if imgui.CollapsingHeader(u8"Больше:") then
               imgui.TextColoredRGB("Команды SAMPFUNCS")
               imgui.SameLine()
               imgui.Link("https://wiki.blast.hk/sampfuncs/console", "https://wiki.blast.hk/sampfuncs/console")
               
               if isTrainingSanbox then
                  imgui.TextColoredRGB("Команды сервера TRAINING-SANDBOX")
                  imgui.SameLine()
                  imgui.Link("https://forum.training-server.com/d/3679-vse-komandy-servera", "forum.training-server.com")
               
                  imgui.TextColoredRGB("Все команды для анимаций")
                  imgui.SameLine()
                  imgui.Link("https://forum.training-server.com/d/427", "forum.training-server.com")            
               end
               
               if not isTrainingSanbox then
                  imgui.TextColoredRGB("Команды RCON")
                  imgui.SameLine()
                  imgui.Link("https://www.open.mp/docs/server/ControllingServer", "https://www.open.mp/docs/")
               end
               
               if not isTrainingSanbox then
                  imgui.TextColoredRGB("Texture Studio Commands")
                  imgui.SameLine()
                  imgui.Link("https://github.com/ins1x/mtools/wiki/Texture-Studio-Commands", "Git wiki")
               end
            end
    
         elseif tabmenu.cmds == 2 then
            imgui.PushFont(fonts.multilinetextfont)
            if input.readonly then
               imgui.InputTextMultiline('##animlist', textbuffer.animlist, imgui.ImVec2(490, 330),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
            else
               imgui.InputTextMultiline('##animlist', textbuffer.animlist, imgui.ImVec2(490, 330),
               imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
            end
            imgui.PopFont()
            
            imgui.Spacing()
            if imgui.CollapsingHeader(u8"Больше:") then
               imgui.TextColoredRGB("Список всех анимаций SA-MP")
               imgui.SameLine()
               imgui.Link("https://www.open.mp/docs/scripting/resources/animations", "https://www.open.mp/docs/scripting/resources/animations")
            end
         end
         
         imgui.Spacing()
         
      elseif tabmenu.info == 2 then
         imgui.resetIO()
         
         if tabmenu.onlinesearch == 1 then
            imgui.Text(u8"В этом разделе вы можете найти объекты через сайт")
            imgui.SameLine()
            imgui.Link("https://dev.prineside.com/ru/gtasa_samp_model_id/", "dev.prineside.com")
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Все запросы перенаправляет в ваш браузер")
            imgui.Spacing()
         elseif tabmenu.onlinesearch == 2 then
            imgui.Text(u8"В этом разделе вы можете найти текстуры через сайт")
            imgui.SameLine()
            imgui.Link("https://textures.xyin.ws/?page=textures&limit=100", "textures.xyin.ws")
            imgui.SameLine()
            imgui.TextQuestion("( ? )", u8"Все запросы перенаправляет в ваш браузер")
            imgui.Spacing()
         end
         
         if tabmenu.onlinesearch == 1 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Объекты", imgui.ImVec2(125, 25)) then tabmenu.onlinesearch = 1 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Объекты", imgui.ImVec2(125, 25)) then tabmenu.onlinesearch = 1 end
         end
         imgui.SameLine()
         if tabmenu.onlinesearch == 2 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"Текстуры", imgui.ImVec2(125, 25)) then tabmenu.onlinesearch = 2 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"Текстуры", imgui.ImVec2(125, 25)) then tabmenu.onlinesearch = 2 end
         end
         
         imgui.Spacing()
         imgui.Spacing()
            
         if tabmenu.onlinesearch == 1 then
         
            imgui.Text(u8"Введите ключевое слово, ID или название модели:")
            imgui.PushItemWidth(220)
            if imgui.InputText("##CheckObject", textbuffer.objectid) then
            end
            imgui.PopItemWidth()
            
            imgui.SameLine()
            if imgui.Button(u8"Найти",imgui.ImVec2(72, 25)) then
               if string.len(textbuffer.objectid.v) > 3 then
                  local link = 'explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/search/?q='.. u8:decode(textbuffer.objectid.v)..'"'
                  os.execute(link)
                  if string.len(textbuffer.objectid.v) <= 24 then
                     ini.tmp.osearch = textbuffer.objectid.v
                     inicfg.save(ini, configIni)
                  end
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите больше 3-х символов для поиска",0x0FF6600)
               end
            end
            if isTrainingSanbox then       
               imgui.SameLine()
               if imgui.Button(u8"/osearch",imgui.ImVec2(72, 25)) then
                  if string.len(textbuffer.objectid.v) > 3 then
                     sampSendChat("/osearch "..u8:decode(textbuffer.objectid.v))
                     if string.len(textbuffer.objectid.v) <= 24 then
                        ini.tmp.osearch = textbuffer.objectid.v
                        inicfg.save(ini, configIni)
                     end
                     dialog.main.v = false
                  else
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите больше 3-х символов для поиска",0x0FF6600)
                  end
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
                  local posX, posY, posZ = getCharCoordinates(playerPed)
                  local link = string.format('explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/mapsearch/?x=%i&y=%i', posX, posY)
                  os.execute(link)
               end
            end
            
            if isTrainingSanbox then
               imgui.TextColoredRGB("Найти объект можно командой: {696969}/osearch <text>")
               imgui.TextColoredRGB("Просмотреть список использованных объектов: {696969}/olist")
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
            
            imgui.TextColoredRGB("Локации с текстурными багами в карте")
            imgui.SameLine()
            imgui.Link("https://pawn.wiki/index.php?showtopic=28682", "pawn.wiki")
            
            imgui.TextColoredRGB("Объекты которые не видны в редакторе карт")
            imgui.SameLine()
            imgui.Link("https://pawn.wiki/index.php?showtopic=31763", "pawn.wiki")
            
            imgui.TextColoredRGB("Объекты для декораций")
            imgui.SameLine()
            imgui.Link("https://www.adv-rp.com/decor/", "adv-rp")
            
         elseif tabmenu.onlinesearch == 2 then
            
            imgui.Text(u8"Введите ключевое слово для поиска (на латинице):")
            imgui.PushItemWidth(220)
            if imgui.InputText("##CheckObject", textbuffer.objectid) then
            end
            imgui.PopItemWidth()
            
            imgui.SameLine()
            if imgui.Button(u8"Найти",imgui.ImVec2(65, 25)) then
               if string.len(textbuffer.objectid.v) > 3 then
                  local link = 'explorer "https://textures.xyin.ws/?page=textures&limit=100&search='.. u8:decode(textbuffer.objectid.v)..'"'
                  os.execute(link)
                  if string.len(textbuffer.objectid.v) <= 24 then
                     ini.tmp.osearch = textbuffer.objectid.v
                     inicfg.save(ini, configIni)
                  end
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите больше 3-х символов для поиска",0x0FF6600)
               end
            end 
            if isTrainingSanbox then
               imgui.SameLine()
               if imgui.Button(u8"/tsearch",imgui.ImVec2(72, 25)) then
                  if LastObject.txdid ~= nil and LastObject.txdslot ~= nil then
                     if string.len(textbuffer.objectid.v) > 3 then
                        sampSendChat(string.format("/tsearch %d %d %s", 
                        LastObject.txdid, LastObject.txdslot, u8:decode(textbuffer.objectid.v)))
                        dialog.main.v = false
                     else
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите больше 3-х символов для поиска",0x0FF6600)
                     end
                  else
                     if string.len(textbuffer.objectid.v) > 3 then
                        sampSendChat("/tsearch "..tostring(u8:decode(textbuffer.objectid.v)))
                     else
                        sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите больше 3-х символов для поиска",0x0FF6600)
                     end
                  end
               end
            end
            if LastObject.txdid ~= nil then
               local txdtable = sampTextureList[LastObject.txdid+1]
               local txdname = tostring(txdtable[3])
               imgui.TextColoredRGB("Последняя использованная текстура: {007DFF}"..txdname.."("..LastObject.txdid..")")
               if imgui.IsItemClicked() then
                  textbuffer.objectid.v = txdname
               end
            end
            
            local txdSearchFilters = {
               "Wood", 
               "- door", "- floor", "- board", 
               "Metal", 
               "- rust", "- fence",  "- beam", 
               "Window", 
               "- glass",
               "Block",
               "- brick", "- tile", "- panel", "- wall", "- box",
               "Land",
               "- rock", "- stone", "- grass", "- tree",
               "- veg", "- sand", "- line",
               "Indust",
               "- fact", "- wires",
               --"etc",
               "barr", "light", "house", "sign"
            }
            
            imgui.Spacing()
            imgui.Text(u8"Выберите категорию")
            imgui.PushItemWidth(170)
            imgui.SameLine()
            if imgui.Combo(u8'##Gamestates', combobox.txdsearchfilter, txdSearchFilters) then
               local rawstring = tostring(txdSearchFilters[combobox.txdsearchfilter.v+1])
               rawstring = string.gsub(rawstring, "-", "")
               rawstring = string.gsub(rawstring, " ", "")
               textbuffer.objectid.v = rawstring
            end
            imgui.PopItemWidth()
            imgui.Spacing()
            
            if isTrainingSanbox then
               imgui.TextColoredRGB("Найти нужную текстуру можно командой: {696969}/tsearch <objectid> <slot> <name>")
            else
               imgui.TextColoredRGB("Найти нужную текстуру можно командой: {696969}/tsearch <text>")
            end
            imgui.TextColoredRGB("Посмотреть индексы(слои): {696969}/sindex")
            imgui.TextColoredRGB("Покрасить каждый слой объекта отдельным цветом: {696969}/cindex")
            imgui.TextColoredRGB("Показать использованные за сеанс текстуры: {696969}/tlist")
            imgui.Spacing()
         end
         
      elseif tabmenu.info == 7 then
         local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//cblist.txt"
         
         -- if imgui.TooltipButton(u8"Unlock IO", imgui.ImVec2(80, 25), u8:encode("разблокировать инпут если курсор забагался")) then
            -- imgui.resetIO()
         -- end
         --imgui.SameLine()

         imgui.PushFont(fonts.multilinetextfont)
         imgui.InputTextMultiline('##cblist', textbuffer.cblist, imgui.ImVec2(490, 350),
         imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput + imgui.InputTextFlags.ReadOnly)
         imgui.PopFont()
         
         
         if imgui.TooltipButton("/cblist", imgui.ImVec2(75, 25), u8"Список комадных блоков") then
            sampSendChat("/cblist")
            dialog.main.v = false
         end
         imgui.SameLine()
         if imgui.TooltipButton("/tb", imgui.ImVec2(75, 25), u8"Список триггер-блоков в мире") then
            sampSendChat("/tb")
            dialog.main.v = false
         end
         imgui.SameLine()
         if imgui.TooltipButton("/timers", imgui.ImVec2(75, 25), u8"Список таймеров мира") then
            sampSendChat("/timers")
            dialog.main.v = false
         end
         imgui.SameLine()
         if imgui.TooltipButton("/server", imgui.ImVec2(75, 25), u8"Список серверных массивов мира") then
            sampSendChat("/server")
            dialog.main.v = false
         end
         imgui.SameLine()
         if imgui.TooltipButton("/varlist", imgui.ImVec2(75, 25), u8"Список серверных переменных мира") then
            sampSendChat("/varlist")
            dialog.main.v = false
         end
         imgui.SameLine()
         if imgui.TooltipButton("/pvarlist", imgui.ImVec2(75, 25), u8"Список пользовательских переменных мира") then
            sampSendChat("/pvarlist")
            dialog.main.v = false
         end
         
         imgui.Text(u8"Найти по описанию")
         imgui.SameLine()
         imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(4, 4))
         imgui.PushItemWidth(200)
         imgui.InputText("##search", textbuffer.searchbar)
         imgui.PopItemWidth()
         imgui.SameLine()
         if imgui.TooltipButton(u8"Поиск##Search", imgui.ImVec2(60, 25), u8:encode("Поиск по тексту (Регистрозависим)")) then
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
         if imgui.Selectable("Unlock IO", false, 0, imgui.ImVec2(55, 15)) then
            imgui.resetIO()
         end
         if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
            imgui.TextUnformatted(u8"Unlock IO - разблокировать инпут если курсор забагался")
            imgui.PopTextWrapPos()
            imgui.EndTooltip()
         end
         imgui.PopStyleVar()
      end -- end tabmenu.info
         
      imgui.NextColumn()
      
      if tabmenu.info == 2 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Поиск", imgui.ImVec2(105, 30)) then tabmenu.info = 2 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Поиск", imgui.ImVec2(105, 30)) then tabmenu.info = 2 end
      end
      
      -- if tabmenu.info == 4 then reserved for debug menu
      if tabmenu.info == 5 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Избранные", imgui.ImVec2(105, 30)) then tabmenu.info = 5 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Избранные", imgui.ImVec2(105, 30)) then tabmenu.info = 5 end
      end
      
      if tabmenu.info == 3 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Палитра", imgui.ImVec2(105, 30)) then tabmenu.info = 3 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Палитра", imgui.ImVec2(105, 30)) then tabmenu.info = 3 end
      end  
      
      if tabmenu.info == 6 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"Команды", imgui.ImVec2(105, 30)) then tabmenu.info = 6 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"Команды", imgui.ImVec2(105, 30)) then tabmenu.info = 6 end
      end
      
      if isTrainingSanbox then
         if tabmenu.info == 7 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
            if imgui.Button(u8"КБ", imgui.ImVec2(105, 30)) then tabmenu.info = 7 end
            imgui.PopStyleColor()
         else
            if imgui.Button(u8"КБ", imgui.ImVec2(105, 30)) then tabmenu.info = 7 end
         end
      end
      
      if tabmenu.info == 1 then
         imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
         if imgui.Button(u8"About", imgui.ImVec2(105, 30)) then tabmenu.info = 1 end
         imgui.PopStyleColor()
      else
         if imgui.Button(u8"About", imgui.ImVec2(105, 30)) then tabmenu.info = 1 end
      end
      

      imgui.Columns(1)
      end  -- tabmenu.main

      imgui.End()
   end
   
   -- Child dialogs
   
   if dialog.playerstat.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.25, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Статистика игрока", dialog.playerstat)
      
      local nickname = sampGetPlayerNickname(chosen.player)
      local ucolor = sampGetPlayerColor(chosen.player)
      local health = sampGetPlayerHealth(chosen.player)
      local armor = sampGetPlayerArmor(chosen.player)
      local ping = sampGetPlayerPing(chosen.player)
      local animid = sampGetPlayerAnimationId(chosen.player)
      local animlib, animname = sampGetAnimationNameAndFile(animid)
      local weapon, ammo, skin
      local pX, pY, pZ, distance
      local zone = nil
      
      for k, handle in ipairs(getAllChars()) do
         local res, id = sampGetPlayerIdByCharHandle(handle)
         if res then
            if id == chosen.player then
                pX, pY, pZ = getCharCoordinates(handle)
                skinid = getCharModel(handle)
                weapon = getCurrentCharWeapon(handle)
                ammo = getAmmoInCharWeapon(handle, weapon)
                zone = getZoneName(pX, pY, pZ)
            end
         end
      end
      
      if sampIsPlayerPaused(chosen.player) then
         imgui.TextColoredRGB("{FF0000}[AFK]")
         imgui.SameLine()
      end
      
      imgui.TextColoredRGB(string.format("Ник: {%0.6x}%s",
      bit.band(ucolor,0xffffff), nickname))
      if imgui.IsItemClicked() then
         setClipboardText(nickname)
         sampAddChatMessage("Ник скопирован в буффер обмена", -1)
      end
      imgui.SameLine()
      imgui.Text(string.format("id: [%d]",chosen.player))
      if imgui.IsItemClicked() then
         setClipboardText(chosen.player)
         sampAddChatMessage("ID скопирован в буффер обмена", -1)
      end
      
      imgui.TextColoredRGB(string.format("Хп: %.1f  броня: %.1f", 
      health, armor))
      
      imgui.Text(u8"Score: ".. sampGetPlayerScore(chosen.player))
      
      if (ping > 90) then
         imgui.TextColoredRGB(string.format("Пинг: {FF0000}%i", ping))
      else
         imgui.TextColoredRGB(string.format("Пинг: %i", ping))
      end
      
      imgui.Text(tostring(u8"Скин: ".. skinid))
      imgui.TextColoredRGB(string.format("Анимация: %i {696969}(%s)", animid, animname))
      if imgui.IsItemClicked() then
         setClipboardText(string.format(u8"%s, %s", animlib, animname))
         sampAddChatMessage("Параметры анимации скопированы в буффер обмена", -1)
      end
      
      if weapon == 0 then 
         imgui.Text(u8"Нет оружия на руках")
      else
         if ammo then 
            imgui.TextColoredRGB(string.format("Оружие: %s (id: %d)", 
            weaponNames[weapon], weapon))
            if weapon > 15 and weapon < 44 then
               imgui.TextColoredRGB(string.format("Патроны: %d", ammo)) 
            end
         end
      end
      
      local posX, posY, posZ = getCharCoordinates(playerPed)
      distance = getDistanceBetweenCoords3d(posX, posY, posZ, pX, pY, pZ)
      imgui.TextColoredRGB(string.format("Дистанция: %.1f m.", distance))
      
      if zone then 
         imgui.TextColoredRGB(string.format("Район: {696969}%s", zone))
      end
      
      if imgui.TooltipButton(u8"Статистика", imgui.ImVec2(100, 25), u8"Открыть серверную статистику игрока") then
         sampSendChat("/stats " .. chosen.player)
         dialog.main.v = false
      end
      imgui.SameLine()
      if imgui.TooltipButton(u8"Меню игрока", imgui.ImVec2(100, 25), u8"Открыть серверное меню взаимодействия с игроком") then
         if isTrainingSanbox then
            sampSendChat("/data " .. chosen.player)
         end
         dialog.main.v = false
      end

      if imgui.TooltipButton(u8"Наблюдать", imgui.ImVec2(100, 25), u8"Наблюдать за игроком") then      
         if isTrainingSanbox then
            sampSendChat("/sp " .. chosen.player)
         else
            sampSendChat("/spec " .. chosen.player)
         end
      end
      imgui.SameLine()
      if imgui.TooltipButton(u8"ТП к Игроку", imgui.ImVec2(100, 25), u8"Телепортироваться к игроку") then
         for k, v in ipairs(getAllChars()) do
            local res, id = sampGetPlayerIdByCharHandle(v)
            if res then
               if id == chosen.player then
                  local pposX, pposY, pposZ = getCharCoordinates(v)
                  if isTrainingSanbox then
                     sampSendChat(string.format("/xyz %f %f %f",
                     pposX+0.5, pposY+0.5, pposZ), -1)
                  else
                     setCharCoordinates(playerPed, posX+0.5, posY+0.5, posZ)
                  end
                end
            else
               sampAddChatMessage("Доступно только в редакторе карт", -1)
            end
          end
       end
       
       if isTrainingSanbox then
          if imgui.TooltipButton(u8"Пробить игрока", imgui.ImVec2(205, 25), u8"Проверка игрока на TRAINING-Checker (online)") then
             local link = 'explorer "https://trainingchecker.vercel.app/player?nickname='..nickname..'"'
             os.execute(link)
          end
       end
       
       if imgui.TooltipButton(u8(chosen.playerMarker and 'Снять' or 'Установить')..u8" метку", imgui.ImVec2(205, 25), u8"Установить/Снять метку с игрока") then
          if chosen.playerMarker ~= nil then
             removeBlip(chosen.playerMarker)
             chosen.playerMarker = nil
             sampAddChatMessage("[SCRIPT]: {FFFFFF}Метка удалена с игрока", 0x0FF6600)
          else
             for k, v in ipairs(getAllChars()) do
                local res, id = sampGetPlayerIdByCharHandle(v)
                if res then
                   if id == chosen.player then
                      chosen.playerMarker = addBlipForChar(v)
                      sampAddChatMessage("[SCRIPT]: {FFFFFF}Метка установлена на игрока", 0x0FF6600)
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
      
      if chosen.vehicle and doesVehicleExist(chosen.vehicle) then
         local health = getCarHealth(chosen.vehicle)
         local carmodel = getCarModel(chosen.vehicle)
         local streamed, id = sampGetVehicleIdByCarHandle(chosen.vehicle)
         local ped = getDriverOfCar(chosen.vehicle)
         local res, pid = sampGetPlayerIdByCharHandle(ped)
         local passengers, valPassengers = getNumberOfPassengers(chosen.vehicle)
         local maxPassengers = getMaximumNumberOfPassengers(chosen.vehicle)
         local engineon = isCarEngineOn(chosen.vehicle)
         local primaryColor, secondaryColor = getCarColours(chosen.vehicle)
         local paintjob = getCurrentVehiclePaintjob(chosen.vehicle)
         local availablePaintjobs = getNumAvailablePaintjobs(chosen.vehicle)
         local siren = isCarSirenOn(chosen.vehicle)
         --local onscreen = isCarOnScreen(chosen.vehicle)
         
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
            LastData.lastVehinfoModelid = carmodel
         end
         
         imgui.TextColoredRGB(string.format("Хп: %i", health))
         
         imgui.Text(u8"Водитель:")
         imgui.SameLine()
         if res then 
            imgui.Selectable(string.format(u8"%s", sampGetPlayerNickname(pid)))
            if imgui.IsItemClicked() then
               chosen.player = pid
               printStringNow("You have chosen a player ".. sampGetPlayerNickname(pid), 1000)
               if not dialog.playerstat.v then dialog.playerstat.v = true end
            end
         else
            imgui.Text(u8"Нет")
         end
         
         imgui.Text(string.format(u8"Скорость: %.0f", getCarSpeed(chosen.vehicle)))
         
         if passengers then
            imgui.Text(string.format(u8"Пассажиров в транспорте: %i (max %i)", valPassengers, maxPassengers))
         else
            imgui.Text(string.format(u8"Пассажиров в транспорте: нет (max %i)", maxPassengers))
         end
         
         imgui.Text(engineon and u8('Двигатель: Работает') or u8('Двигатель: Заглушен'))
         imgui.Text(siren and u8('Сигнализация: Работает') or u8('Сигнализация: Отключена'))
         
         imgui.Text(string.format(u8"Цвет 1: %i  Цвет 2: %i", primaryColor, secondaryColor))
         
         imgui.Text(string.format(u8"Покраска: %i/%i", paintjob, availablePaintjobs))
         
         if imgui.Button(u8"Меню транспорта", imgui.ImVec2(250, 25)) then         
            if isTrainingSanbox then
               dialog.main.v = not dialog.main.v
               sampSendChat("/vmenu "..id)
            else
               sampAddChatMessage("Недоступно для этого сервера!", -1)
            end
         end
         
         if imgui.Button(u8"Информация о модели (онлайн)", imgui.ImVec2(250, 25)) then
            if LastData.lastVehinfoModelid then
               if LastData.lastVehinfoModelid > 400 and LastData.lastVehinfoModelid < 611 then 
                  os.execute(string.format('explorer "https://gtaundergroundmod.com/pages/ug-mp/documentation/vehicle/%d/details"', LastData.lastVehinfoModelid))
               else
                  sampAddChatMessage("Некорректный ид транспорта", -1)
               end
            end
         end
                  
         if imgui.Button(u8"Предпросмотр 3D модели (онлайн)", imgui.ImVec2(250, 25)) then
            if LastData.lastVehinfoModelid then
               if LastData.lastVehinfoModelid > 400 and LastData.lastVehinfoModelid < 611 then 
                  os.execute(string.format('explorer "http://gta.rockstarvision.com/vehicleviewer/#sa/%d"', LastData.lastVehinfoModelid))
               else
                  sampAddChatMessage("Некорректный ид транспорта", -1)
               end
            end
         end
         
         if imgui.Button(u8"Таблица цветов транспорта (онлайн)", imgui.ImVec2(250, 25)) then
            os.execute(string.format('explorer "https://www.open.mp/docs/scripting/resources/vehiclecolorid"'))
         end
      else
         dialog.vehstat.v = false
         sampAddChatMessage("Транспорт несуществует либо был отправлен на спавн", -1)
      end
      
      imgui.End()
   end
   
   if dialog.extendedtab.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 16, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Дополнительные параметры", dialog.extendedtab)
      
      imgui.End()
   end
   
   if dialog.dialogtext.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 8, sizeY / 3),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.SetNextWindowSize(imgui.ImVec2(345, 250))
      imgui.Begin(u8"Диалог - ID:"..sampGetCurrentDialogId(), dialog.dialogtext)
      
      if LastData.lastDialogTitle then
         if string.len(LastData.lastDialogTitle) > 1 then
            imgui.TextColoredRGB(LastData.lastDialogTitle)
         else
            imgui.TextColoredRGB("{696969}Диалог без заголовка")
         end
      else
         imgui.TextColoredRGB("{696969}Диалог без заголовка")
      end
      
      imgui.InputTextMultiline('##dialogtext', textbuffer.dialogtext, imgui.ImVec2(320, 180),
      imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.AllowTabInput)
               
      imgui.End()
   end
   
   if dialog.toolkitmanage.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 1.3, sizeY / 4),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.Begin(u8"Управление", dialog.toolkitmanage)
      
      if imgui.Button(u8"Перегрузить тулкит",imgui.ImVec2(150, 25)) then
         sampAddChatMessage("{696969}Mapping Toolkit{FFFFFF}  перезагружается.", -1)
         --sampAddChatMessage("Для перезапуска можно использовтаь комбинацию клавиш {696969}CTRL + R.", -1)
         thisScript():reload()
      end
      
      if imgui.Button(u8"Выгрузить тулкит",imgui.ImVec2(150, 25)) then
         sampAddChatMessage("{696969}Mapping Toolkit{FFFFFF}  успешно выгружен.", -1)
         sampAddChatMessage("Для повторного запуска используйте комбинацию клавиш {696969}CTRL + R.", -1)
         thisScript():unload()
      end
      
      local thisscript = thisScript()
      if thisscript.frozen then
         if imgui.Button(u8"Снять с паузы",imgui.ImVec2(150, 25)) then
            thisScript():resume()
            dialog.main.v = true
            sampAddChatMessage("{696969}Mapping Toolkit{FFFFFF}  поставлен на паузу.", -1)
         end
      else
         if imgui.Button(u8"Поставить на паузу",imgui.ImVec2(150, 25)) then
            thisScript():pause()
            sampAddChatMessage("{696969}Mapping Toolkit{FFFFFF}  снят с паузы.", -1)
         end
      end
      
      if imgui.TooltipButton(u8"Сообщить о ошибке", imgui.ImVec2(150, 25), u8"Жми не стесняйся") then
         tabmenu.main = 3
         tabmenu.info = 1
         tabmenu.credits = 3
      end
      -- if imgui.Button(u8"Проверить обновления",imgui.ImVec2(150, 25)) then
         -- if not checkScriptUpdates() then
            -- sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Установлена актуальная версия {696969}"..thisScript().version, -1)
            -- --os.execute('explorer https://github.com/ins1x/MappingToolkit/releases')
         -- end
      -- end
      -- imgui.SameLine()
      if imgui.TooltipButton(u8"Сбросить настройки",imgui.ImVec2(150, 25),u8"Сбросит настройки предварительно сохранив копию текущих настроек") then
         os.rename(getGameDirectory().."//moonloader//config//mappingtoolkit.ini", getGameDirectory().."//moonloader//config//backup_mappingtoolkit.ini")
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Настройки были сброшены на стандартные. Тулкит автоматически перезагрузится.",0x0FF6600)
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Резервную копию ваших предыдущих настроек можно найти в {696969}moonloader/config.",0x0FF6600)
         reloadScripts()
      end

      if imgui.Button(u8"Открыть конфиг",imgui.ImVec2(150, 25)) then
         folder = getGameDirectory().. "\\moonloader\\config\\"
         os.execute('explorer "'..folder..'"')
      end
      if imgui.TooltipButton(u8"Обновление", imgui.ImVec2(150, 25), u8"Проверить наличие обновлений") then
         if not checkScriptUpdates() then
            sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Установлена актуальная версия {696969}"..thisScript().version, -1)
            --os.execute('explorer https://github.com/ins1x/MappingToolkit/releases')
         end
      end
      if imgui.TooltipButton(u8"Отладка", imgui.ImVec2(150, 25), u8"Открыть инструменты для отлдаки") then
         tabmenu.main = 3
         tabmenu.info = 4
      end
      if imgui.TooltipButton(u8" << ", imgui.ImVec2(150, 25), u8"Свернуть") then
         dialog.toolkitmanage.v = false
      end
      imgui.End()
   end
   
   if dialog.txdlist.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 3),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.SetNextWindowSize(imgui.ImVec2(260, 250))
      imgui.Begin(u8"Список TextDraws", dialog.txdlist)
      
      local row = 0
      
      for id = 1, 2048 do
         if sampTextdrawIsExists(id) then
            local text = sampTextdrawGetString(id)
            imgui.TextColoredRGB("{696969}"..id)
            imgui.SameLine()
            if imgui.Selectable(("%s"):format(text)) then
               input.txdid.v = id
            end
            row = row + 1
         end
      end
      
      if row == 0 then
         imgui.TextColoredRGB("{696969}Не найдено текстдравов")
      end
      
      imgui.End()
   end
   
   if dialog.objectinfo.v then
      imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 7, sizeY / 2),
      imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
      imgui.SetNextWindowSize(imgui.ImVec2(270, 300))
      
      if not chosen.object then
         if LastObject.handle and doesObjectExist(LastObject.handle) then
            chosen.object = LastObject.handle
         end
      end
      
      local modelid = getObjectModel(chosen.object)
      local objectid = sampGetObjectSampIdByHandle(chosen.object)
      
      if objectid then
         imgui.Begin(u8"Информация о объекте id:"..objectid, dialog.objectinfo)
      else
         imgui.Begin(u8"Информация о объекте", dialog.objectinfo)
      end
      
      if isTrainingSanbox and chosen.object == LastObject.handle then
         if LastObject.localid then
            imgui.TextColoredRGB("localid: {007DFF}"..LastObject.localid)
         end
      end
      
      imgui.TextColoredRGB("modelid: {007DFF}".. modelid)
      if imgui.IsItemClicked() then
         setClipboardText(tostring(modelid))
         sampAddChatMessage("modelid скопирован в буффер обмена", -1)
      end
      imgui.TextColoredRGB("name: {007DFF}".. tostring(sampObjectModelNames[modelid]))
      if imgui.IsItemClicked() then
         setClipboardText(tostring(sampObjectModelNames[modelid]))
         sampAddChatMessage("modelname скопирован в буффер обмена", -1)
      end
      --imgui.TextColoredRGB("id: {007DFF}".. objectid)
      
      if chosen.object == LastObject.handle then
         if not LastObject.position.x ~= nil then
            imgui.TextColoredRGB(string.format("{007DFF}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f",
            LastObject.position.x, LastObject.position.y, LastObject.position.z))
            if imgui.IsItemClicked() then
               setClipboardText(string.format("%.2f, %.2f, %.2f", LastObject.position.x, LastObject.position.y, LastObject.position.z))
               sampAddChatMessage("Координаты скопированы в буффер обмена", -1)
            end
            imgui.SameLine()
            imgui.TextQuestion(" [=] ", u8"Копировать координаты в буффер")
            if imgui.IsItemClicked() then
               setClipboardText(string.format("%.2f, %.2f, %.2f", x, y, z))
               sampAddChatMessage("Координаты скопированы в буффер обмена", -1)
            end
         end   
         if not LastObject.rotation.x ~= nil then
            imgui.TextColoredRGB(string.format("{007DFF}rx: %.2f, {f0364e}ry: %.2f, {36b85d}rz: %.2f",
            LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z))
         end
      else
         local result, x, y, z = getObjectCoordinates(chosen.object)
         if result then
            imgui.TextColoredRGB(string.format("{007DFF}x: %.2f, {e0364e}y: %.2f, {26b85d}z: %.2f", x, y, z))
            if imgui.IsItemClicked() then
               setClipboardText(string.format("%.2f, %.2f, %.2f", x, y, z))
               sampAddChatMessage("Координаты скопированы в буффер обмена", -1)
            end
         end
         imgui.SameLine()
         imgui.TextQuestion(" [=] ", u8"Копировать координаты в буффер")
         if imgui.IsItemClicked() then
            setClipboardText(string.format("%.2f, %.2f, %.2f", x, y, z))
            sampAddChatMessage("Координаты скопированы в буффер обмена", -1)
         end
         
      end
      imgui.TextColoredRGB(string.format("angle: {007DFF}%.1f", getObjectHeading(chosen.object)))
      
      if chosen.object == LastObject.handle and isTrainingSanbox
      and LastObject.txdid ~= nil then
         local txdtable = sampTextureList[LastObject.txdid+1]
         local txdname = tostring(txdtable[3])
         imgui.TextColoredRGB("txd: {007DFF}"..txdname.."("..LastObject.txdid..")")
         if imgui.IsItemClicked() then
            textbuffer.objectid.v = txdname
         end
      end
      
      -- incorrect format fix later
      -- if getMDO(objectid) then
         -- imgui.TextColoredRGB("drawdistance: {007DFF}"..getMDO(objectid))
      -- end
      
      if isObjectOnScreen(chosen.object) then 
         imgui.TextColoredRGB("{696969}объект на экране")
      else
         imgui.TextColoredRGB("{ff0000}объект вне зоны прямой видимости")
      end
      
      if isObjectDestructible(modelid) then
         imgui.TextColoredRGB("{FF6600}объект разрушаемый")
      end
      
      if isObjectWithAnimation(modelid) then
         imgui.TextColoredRGB("{FF6600}объект содержит анимацию")
      end
      
      if isObjectAttached(chosen.object) then 
         imgui.TextColoredRGB("{FFFF00}object attached")
      end
      local result, errorString = checkBuggedObject(modelid)
      if result then
         imgui.TextColoredRGB("{FF0000}object bugged!")
         imgui.SameLine()
         imgui.TextQuestion(" (?) ", u8(errorString))
      end
      
      imgui.Spacing()
      imgui.Spacing()
      
      if imgui.TooltipButton(u8"Инфо (online)", imgui.ImVec2(120, 25), u8"Посмотреть подробную информацию по объекту на Prineside DevTools") then            
         local link = 'explorer "https://dev.prineside.com/ru/gtasa_samp_model_id/search/?q='..modelid..'"'
         os.execute(link)
      end
      
      if isTrainingSanbox then
         imgui.SameLine()
         if imgui.TooltipButton(u8"Инфо (/oinfo)", imgui.ImVec2(120, 25), u8"Посмотреть подробную информацию по объекту (серверной командой)") then            
            if LastObject.localid then
               sampSendChat("/oinfo")
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден последний объект!", 0x0FF6600)
            end
         end
      end
      
      if imgui.TooltipButton(u8"В избранное", imgui.ImVec2(120, 25), u8"Добавит объект в список избранных") then
         favfile = io.open(getGameDirectory() ..
         "//moonloader//resource//mappingtoolkit//favorites//objects.txt", "a")
         favfile:write(" ,"..modelid.."("..tostring(sampObjectModelNames[modelid])..")")
         favfile:close()
         sampAddChatMessage("Объект {696969}"..modelid.."{FFFFFF} добавлен в файл избранных {696969}(favorites.txt)", -1)
      end
      imgui.SameLine()
      if imgui.TooltipButton(u8"Похожие объекты", imgui.ImVec2(120, 25), u8"Найти похожие объекты (/osearch)") then
         local modelName = tostring(sampObjectModelNames[LastObject.modelid])
         local searchobj = string.match(modelName, "%a*")
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
            
            sampSendChat(tostring("/osearch "..searchobj))
            dialog.main.v = false
         end
      end
      
      if imgui.TooltipButton(u8"ТП к объекту", imgui.ImVec2(120, 25), u8"Телепорт к объекту (системный)") then
         local result, x, y, z
         if chosen.object == LastObject.handle then
            result = true
            x = LastObject.position.x
            y = LastObject.position.y
            z = LastObject.position.z
         else
            result, x, y, z = getObjectCoordinates(chosen.object)
         end
         
         if result and x ~= 0 and doesObjectExist(chosen.object) then
            if isTrainingSanbox then
               sampSendChat(string.format("/xyz %f %f %f", x, y, z), 0x0FFFFFF)
               sampAddChatMessage("Вы телепортировались на координаты к объекту {696969}"..objectid.." ("..modelid..")", -1)
            else
               --setCharCoordinates(playerPed, LastObject.position.x, LastObject.position.x, LastObject.position.z+0.2)
               sampAddChatMessage("Недоступно для этого сервера!", -1)
            end  
         else
            if isTrainingSanbox then
               sampSendChat("/tpo")
            else
               sampAddChatMessage("Не найден объект", -1)
            end
         end
      end
      imgui.SameLine()
      if chosen.object == LastObject.handle then
         if imgui.TooltipButton(u8"Экспортировать", imgui.ImVec2(120, 25), u8"Выведет строчку в формате создания объекта для filterscript") then
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
      end
      
      imgui.Spacing()
      
      if dialog.objectinfo.v then 
         if imgui.TooltipButton(u8"(Скрыть >>)", imgui.ImVec2(245, 25), u8"Скрыть дополнительные параметры объекта") then
            dialog.objectinfo.v = not dialog.objectinfo.v
         end
      else
         if imgui.TooltipButton("(<<)", imgui.ImVec2(250, 25), u8"Показать дополнительные параметры объекта") then
            dialog.objectinfo.v = not dialog.objectinfo.v
            if LastObject.handle and doesObjectExist(LastObject.handle) then
               chosen.object = LastObject.handle
            end
         end
      end             
      
      imgui.Spacing()
      imgui.End()
   end
   imgui.PopFont()
end

-------------- SAMP hooks -----------
function sampev.onSetWeather(weatherId)
   LastData.lastWeather = weatherId
   if ini.settings.weatherinformer then
      if weatherId ~= 0 and sampIsLocalPlayerSpawned() and not playerdata.firstSpawn then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Сервером выставлена погода "..weatherId, 0x0FF6600)
      end
   end
   if ini.settings.lockserverweather then
      forceWeatherNow(slider.weather.v)
   end
end

function sampev.onSetPlayerTime(hour, minute)
   if ini.settings.lockserverweather then
      setTimeOfDay(slider.time.v, 0)
   end
end
   
function sampev.onSetPlayerPos(position)
   if checkbox.logsetplayerpos.v then
      --printHelpString(string.format("x:%.2f y:%.2f z:%.2f", position.x, position.y, position.z))
      print(string.format("Server change player position: %.2f %.2f %.2f", position.x, position.y, position.z))
   end
end

function sampev.onSetWorldBounds(maxX, minX, maxY, minY)
   if checkbox.logworlddouns.v then
      print(string.format("Server change world bounds: maxX:%.2f, mixX:%.2f, maxY:%.2f, mixY:%.2f", 
      maxX, minX, maxY, minY))
   end
   if checkbox.noworldbounds.v then
      -- A player's world boundaries reset to default (doesn't work in interiors)
      return {20000.0000, -20000.0000, 20000.0000, -20000.0000}
   end
end

function sampev.onSetGravity(gravity)
   if ini.settings.cberrorwarnings then
      if gravity > 0.2 then
         sampAddChatMessage("[WARNING]: {FFFFFF}Попытка установить некорректную гравитацию отклонена (SetGravity: "..gravity..")", 0x0FF6600)
         return false
      end
   end
   if checkbox.nogravity.v then
      print(string.format("Server try change gravity to: %.2f", gravity)) 
      return false
   end
end

function sampev.onPlayerStreamIn()
   if checkbox.hideplayers.v then
      return false
   end
end

function sampev.onVehicleStreamIn(vehId, data)
   if ini.settings.cberrorwarnings then
      if data.type < 400 or data.type > 611 then
         sampAddChatMessage("[WARNING]: {FFFFFF}Попытка отобразить несуществующую модель транспорта отклонена (onSendEnterVehicle vehid:"..vehId.." model:"..data.type..")", 0x0FF6600)
         return false
      end
   end
   
   if checkbox.hidevehicles.v then
      return false
   end
end

function sampev.onSendEnterVehicle(vehicleId, passenger)

   if ini.settings.cberrorwarnings then
      if isCharInAnyCar(playerPed) then
         sampAddChatMessage("[WARNING]: {FFFFFF}Попытка посадить в транспорт игрока который уже в транспорте отклонена (onSendEnterVehicle vehid:"..vehicleId..")", 0x0FF6600)
         return false
      end
   end
   
   if playerdata.flymode then
      toggleFlyMode(false)
   end
end

function sampev.onPutPlayerInVehicle(vehicleId, seatId)  
   if ini.settings.cberrorwarnings then
      if isCharInAnyCar(playerPed) then
         sampAddChatMessage("[WARNING]: {FFFFFF}Попытка посадить в транспорт игрока который уже в транспорте отклонена (PutPlayerInVehicle vehid:"..vehicleId..")", 0x0FF6600)
         return false
      end
   end
   
   -- reject put player into trailers and spec vehicles
   if ini.settings.trailerspawnfix then
      local result, carhandle = sampGetCarHandleBySampVehicleId(vehicleId)
      if result then
         local carmodel = getCarModel(carhandle)
         local buggedVehs = {435, 450, 584, 590, 591, 606, 607, 608, 610, 611}
         for k, v in ipairs(buggedVehs) do
            if carmodel == v then
               return false
            end
         end
      end
   end
   
   if playerdata.flymode then
      toggleFlyMode(false)
   end
end

function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
   LastData.lastDialogInput = input
   LastData.lastListboxId = listboxId
   LastData.lastDialogButton = button
   --print(LastData.lastDialogTitle, LastData.lastDialogStyle, LastData.lastDialogInput)
   
   if checkbox.logdialogresponse.v then
      print(string.format("dialogId: %d, button: %d, listboxId: %d, input: %s", dialogId, button, listboxId, input))
   end
   
   -- TIP: All Training dialogId has id 32700
   if isTrainingSanbox and dialogId == 32700 then
      
      if button == 0 then 
         dialoghook.editdialog = false
         dialoghook.animlist = false
         dialoghook.attachcode = false
         dialoghook.setsadstext = false
         dialoghook.setworldname = false
         dialoghook.setworlddescription = false
      end
      
      if button == 1 and dialoghook.attachcode then
         dialoghook.attachcode = false
      end
      
      if button == 1 and dialoghook.action then
         dialoghook.action = false
         if string.len(input) > 1 then 
            LastData.lastTextBuffer = input
         end
      end
      
      if button == 1 and dialoghook.otext then
         dialoghook.otext = false
         if string.len(input) > 1 then 
            LastData.lastOtext = input
         end
      end
      
      if button == 1 and dialoghook.setworldname then
         dialoghook.setworldname = false
         ini.tmp.worldname = tostring(input)
         inicfg.save(ini, configIni)
      end
      
      if button == 1 and dialoghook.setsadstext then
         dialoghook.setsadstext = false
         ini.tmp.sadstext = tostring(input)
         inicfg.save(ini, configIni)
      end
      
      if button == 1 and dialoghook.setworlddescription then
         dialoghook.setworlddescription = false
         ini.tmp.worlddescription = tostring(input)
         inicfg.save(ini, configIni)
      end
      
      if button == 0 and ini.settings.skipomenu then
         local caption = sampGetDialogCaption()
         if LastData.lastDialogTitle then
            --print(LastData.lastDialogTitle, caption)
            if caption:find("Редактирование объекта") then
               lua_thread.create(function()
                  wait(5)
                  sampSendClickTextdraw(2118)
               end)
            end
         end
      end
      
      -- Покинуть данный мир? 
      if button == 1 and dialoghook.exitdialog then
         playerdata.isWorldHoster = false
         ini.tmp.worldhoster = false
         inicfg.save(ini, configIni)
         lua_thread.create(function()
            wait(250)
            sampSendChat("/clearzone")
            wait(1000)
            dialoghook.exitdialog = false
         end)
      end
      
      if ini.settings.cbvalautocomplete then
         if input:find("- Значение #") then
            if button == 1 then
               dialoghook.cbvalue = true
            else
               dialoghook.cbvalue = false
               LastData.lastCbvaluebuffer = nil
            end
         end
         
         if input:find("Значение:") then
            if button == 1 then
               dialoghook.tbvalue = true
            else
               dialoghook.tbvalue = false
               LastData.lastTbvaluebuffer = nil
            end
         end
         
         if dialoghook.modelinfo then
            dialoghook.modelinfo = false
            sampTextdrawDelete(const.txdmodelinfoid)
         end
      end
      
      if button == 1 then -- if dialog response
         -- Corrects spawn item on /world menu
         if listboxId == 3 and input:find("Вернуться в свой мир") then
            if not playerdata.isWorldJoinUnavailable then
               if worldspawnpos.x and worldspawnpos.x ~= 0 then
                  sampSendChat(string.format("/xyz %f %f %f",
                  worldspawnpos.x, worldspawnpos.y, worldspawnpos.z), 0x0FFFFFF)
               else
                  sampSendChat("/spawnme")
               end
            end
         end
         
         if listboxId == 3 and input:find("Вернуться в свой статичный мир") then
            if not playerdata.isWorldJoinUnavailable then
               if worldspawnpos.x and worldspawnpos.x ~= 0 then
                  sampSendChat(string.format("/xyz %f %f %f",
                  worldspawnpos.x, worldspawnpos.y, worldspawnpos.z), 0x0FFFFFF)
               end
               playerdata.isWorldHoster = true
               ini.tmp.worldhoster = true
               inicfg.save(ini, configIni)
            end
         end
         -- if input:find("Список пользовательских миров") then
         -- end
         -- if listboxId == 2 and input:find("Создать игровой мир") then
         -- end
         -- if listboxId == 3 and input:find("Создать пробный VIP мир") then
         -- end
         if listboxId == 4 and input:find("Отправиться на спаун") then
            edit.mode = 0
            if not playerdata.isWorldHoster and ini.settings.saveskin then
               restorePlayerSkin()
            end
         end
         
         -- Added new features to /omenu
         if listboxId == 0 and input:find("Редактировать") then 
            if LastObject.localid then 
               edit.mode = 1
               sampSendChat("/oedit "..LastObject.localid)
            end
         end
         if listboxId == 1 and input:find("Клонировать") then 
            lua_thread.create(function()
               wait(500)
               edit.mode = 2
               sampSendChat("/clone "..LastObject.localid) 
            end)
            return false
         end
         if listboxId == 2 and input:find("Удалить") then 
            edit.mode = 3
         end
         if listboxId == 3 and input:find("Повернуть на 90") then
            sampSendChat("/rz 90")
         end
         -- if listboxId == 4 and button == 1 and input:find("Выровнять по координатам") then
            -- if LastObject.localid and LastObject.handle and doesObjectExist(LastObject.handle) then
               -- local angle = getObjectHeading(LastObject.handle)
               -- if angle then
                  -- --enterEditObject()
                  -- --sampSendChat("/oedit")
                  -- --setObjectHeading(LastObject.handle, getCorrectAngle(angle))
                  -- --sampSendChat("/oedit")
                  -- --setObjectRotation(LastObject.handle, float rotationX, float rotationY, float rotationZ)
                  -- lua_thread.create(function()
                     -- wait(500)
                     -- sampSendChat(string.format("/rz %i %.1f", LastObject.localid, getCorrectAngle(angle)))
                     -- sampAddChatMessage("old"..angle..">"..getCorrectAngle(angle), -1)
                  -- end)
                  -- --print(getCorrectAngle(angle))
               -- end
            -- end
         -- end
         if listboxId == 4 and input:find("Наложить текст") then
            sampSendChat("/otext -1")
         end
         if listboxId == 5 and input:find("Наложить текстуру") then
            if LastObject.localid then 
               edit.mode = 4
               showRetextureKeysHelp()
               sampSendChat("/texture 0")
            else 
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Не выбран объект. Попробуйте /omenu <id>", 0x0FF6600)
            end
         end
         if listboxId == 6 and input:find("Показать индексы") then
            sampSendChat("/sindex")
         end
         if listboxId == 7 and input:find("Очистить текстуры") then
            sampSendChat("/untexture")
         end
         if listboxId == 8 and input:find("Затемнить") then
            if LastObject.localid then 
               sampSendChat("/ocolor "..LastObject.localid.." 0xFFFFFFFF")
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект "..LastObject.localid.." был затемнен", 0x0FF6600)
            else 
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Не выбран объект. Попробуйте /omenu <id>", 0x0FF6600)
            end
         end
         if listboxId == 9 and input:find("Сделать прозрачным") then
            if LastObject.localid then 
               sampSendChat("/stexture "..LastObject.localid.." 0 8660")
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект "..LastObject.localid.." сделан прозрачным", 0x0FF6600)
            else 
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Не выбран объект. Попробуйте /omenu <id>", 0x0FF6600)
            end
         end
         if listboxId == 10 and input:find("Телепортироваться") then
            sampSendChat("/tpo")
         end
         if listboxId == 11 and input:find("Информация") then
            lua_thread.create(function()
               wait(500)
               sampSendChat("/oinfo")
            end)
         end
         
         -- Extend main /menu
         if input:find("Взять Jetpack") then
            sampSendChat("/jetpack")
         end
         if input:find("Взять оружие") then
            sampSendChat("/weapon")
         end
         if input:find("Сменить скин") then
            sampSendChat("/skin")
         end
         if input:find("Очистить чат") then
            ClearChat()
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Чат был очищен!", 0x0FF6600)
            --sampAddChatMessage("[SCRIPT]: {FFFFFF}Чат был очищен!", 0x0FF6600)
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
            lua_thread.create(function()
               wait(200)
               sampSendChat("/team")
            end)
         end
         if input:find("Интерьеры") then
            sampSendChat("/int")
         end
         -- Extend world manage menu
         if input:find("Список командных блоков") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/cblist")
            end)
         end
         if input:find("Список триггер блоков") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/tb")
            end)
         end
         if input:find("Список таймеров") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/timers")
            end)
         end
         if input:find("Список объектов в мире") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/olist")
            end)
         end
         if input:find("Список перемещаемых объектов") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/gate")
            end)
         end
         if input:find("Список переменных") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/varlist")
            end)
         end
         if input:find("Список переменных игрока") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/pvarlist")
            end)
         end
         if input:find("Список аудиостримов") then
            lua_thread.create(function()
               wait(100)
               sampSendChat("/stream")
            end)
         end
         
         -- /vmenu
         if input:find("Удалить транспорт") then
            if LastData.lastVehicle then
               sampSendChat("/delveh "..LastData.lastVehicle)
            end
         end
         if input:find("Тп к транспорту") then
            if LastData.lastVehicle then
               sampSendChat("/tpveh "..LastData.lastVehicle)
            end
         end
         if input:find("Тп транспорт к себе") then
            if LastData.lastVehicle then
               sampSendChat("/vgethere "..LastData.lastVehicle)
            end
         end
         
         if ini.settings.cbnewactivation then
            if input:find("Вход") then
               dialoghook.suspendcbactivation = true
            end
         end
         
         if input:find("Телепортировать к себе") 
         or input:find("Телепортироваться к актёру") then
            if sampIsLocalPlayerSpawned() then
               lua_thread.create(function()
                  wait(1000)
                  local x, y, z = getCharCoordinates(playerPed)   
                  setCharCoordinates(playerPed, x + 0.5, y, z)
               end)
            end
         end
         
         -- autocomplete animation set dialog
         if ini.settings.dialogautocomplete then
            if dialoghook.animdata then
               if string.match(input, "%a%s") then
                  ini.tmp.animationdata = input
                  inicfg.save(ini, configIni)
                  dialoghook.animdata = false
               end
            end
         end
         -- /animlist fix
         if dialoghook.animlist then
            if button == 1 then
               if not input:find(">>>") and not input:find("<<<") then
                  local result = string.match(input, "/.*%s")
                  if result then
                     sampSendChat(string.format("%s 1", result))
                  else
                     sampSendChat(input)
                  end
                  dialoghook.animlist = false
               end
            end
            if button == 0 then
               dialoghook.animlist = false
            end
         end
      end
      
      if ini.settings.cberrorwarnings and
      listboxId == 65535 and button == 1 then
         local textcmd = input:find("#")
         local length = input:len()
         local blockCounter = 0
         local subCounter = 0
         
         if textcmd then
            for idx = 1, length do
               local symbol = string.sub(input, idx, idx)
               --print(idx, symbol)
               if symbol:find("#") then
                  blockCounter = blockCounter + 1
               end
               if symbol:find("`") then
                  subCounter = subCounter + 1
               end
            end
            if blockCounter % 2 ~= 0 then -- if not odd #
               sampAddChatMessage("[WARNING]: {FFFFFF}Нечетное кол-во символов # в текстовой функции, возможно пропущен закрывающий символ #", 0x0FF6600)
            end
            if subCounter % 2 ~= 0 then -- if not odd ` 
               sampAddChatMessage("[WARNING]: {FFFFFF}Нечетное кол-во символов ` (Ё в англ. регистре) в текстовой подфункции, возможно пропущен закрывающий символ `", 0x0FF6600)
            end
         end
      end
   end
   
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
   -- Dialog styles from scripting referense:
   -- DIALOG_STYLE_MXGBOX   0
   -- DIALOG_STYLE_INPUT    1
   -- DIALOG_STYLE_LIST     2
   -- DIALOG_STYLE_PASSWORD 3
   -- DIALOG_STYLE_TABLIST  4
   -- DIALOG_STYLE_TABLIST_HEADERS 5
   
   if checkbox.logdialogresponse.v then
      print(dialogId, style, title, button1, button2, text)
   end
   
   if dialogId ~= 65535 then
      LastData.lastDialogTitle = title
      LastData.lastDialogStyle = style
      LastData.lastDialogText = u8:encode(text)
   end
   
   if isTrainingSanbox and dialogId == 32700 then
      -- TRAINING Skip cmdbinds dialog
      if ini.settings.skiprules then
         if text:find('1. Общее положение') and style == 0 and button1 == "Принимаю" then
            sampSendDialogResponse(32700, 1, nil)
            sampCloseCurrentDialogWithButton(1)
         end
      end
      
      if title:find('Меню актера') then
         LastData.lastActor = title:match('Меню актера #(%d+)')
      end
      
      if title:find("Загрузка мира") then
         if LastData.lastLoadedWorldNumber then
            lua_thread.create(function()
               sampSendDialogResponse(32700, 1, LastData.lastLoadedWorldNumber)
               sampCloseCurrentDialogWithButton(1)
               dialoghook.loadworld = false
            end)
         end
      end
      
      if title:find('Редактор актера') then
         if text:find('Укажите ID скина') then
            LastData.lastLink = 'https://pawnokit.ru/ru/skins_id'
            local newtext = "{FFFFFF}".. text .. "{CDCDCD}\n"..
            "\nРабочие: 8, 16, 27, 50, 153, 260"..
            "\nЖители средний-класс: 15, 22, 44, 48, 58, 60, 170"..
            "\nЖители бизнес-класс: 46, 59, 98, 185, 186, 221, 228, 240"..
            "\nМалоимущие: 77, 78, 79, 134-137, 212, 230, 239"..
            "\nСельские жители: 157-162, 196-200"..
            "\nЖенщины: 11-13, 40, 41, 55, 56, 65, 76, 91, 93, 169, 150, 216, 219"..
            "\nГосники: 61, 70, 71, 76, 141, 147, 163-166, 187, 253, 255, 274-279"..
            "\nПреступники: 21, 28-30, 47-100, 181, 254"..
            "\nЧлены банд: 102-110, 114-116, 173-175"..
            "\nМафия: 111-113, 117-127"..
            "\nКопы: 280-288, 300-307, 309-311"..
            "\nПляжные: 18, 45, 97, 138-140, 154, 251"..
            "\n\n{007FFF}".. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
      end
      
      if title:find('Выбор анимации') then
         if text:find('Введите анимацию в такой последовательности') then
            LastData.lastLink = 'https://www.open.mp/docs/scripting/resources/animations'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}".. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            
            if ini.settings.dialogautocomplete then
               dialoghook.animdata = true
               if ini.tmp.animationdata then
                  if ini.tmp.animationdata:len() > 1 then
                     lua_thread.create(function()
                        wait(200)
                        sampSetCurrentDialogEditboxText(tostring(ini.tmp.animationdata))
                     end)
                  end
               end
            end
            return {dialogId, style, title, button1, button2, newtext}
         end
      end
      
      if style == 0 or style == 1 then -- if MsgBox or Input Dialog
         if text:find('Укажите желаемую погоду мира:') 
         or text:find('Установить погоду мира:')
         or text:find('Установить игровую погоду игроку:') then
            LastData.lastLink = 'https://pawnokit.ru/ru/weather_id'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}".. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Установить ID интерьера игроку:') then
            LastData.lastLink = 'https://pawnokit.ru/ru/interiors_id'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Перекрасить транспорт:') then
            LastData.lastLink = 'https://sampwiki.blast.hk/wiki/Colors_List'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Игровой текст.*GameTextStyle') then
            LastData.lastLink = 'https://www.open.mp/docs/scripting/resources/gametextstyles'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Создать актера.*Узнать свои координаты') then
            local px, py, pz = getCharCoordinates(playerPed)
            LastData.lastTextBuffer = ("%i %.3f %.3f %.3f %.3f"):format(getCharModel(playerPed), px, py, pz, getCharHeading(playerPed))
            local newtext = "{FFFFFF}".. text .. 
            "\n{696969}Нажмите CTRL + SHIFT + V чтобы вставить текущие данные скина, позиции, и поворота\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Воспроизвести игровой звук:') then
            LastData.lastLink = 'https://pawnokit.ru/en/sounds'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Создать взрыв:') then
            LastData.lastLink = 'https://pawnokit.ru/ru/explosions_id'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Установить игроку иконку:') then
            LastData.lastLink = 'https://www.open.mp/docs/scripting/resources/mapicons'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Выдать игроку оружие/патроны:') then
            LastData.lastLink = 'https://www.open.mp/docs/scripting/resources/weaponids'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Укажите URL потока') then
            --LastData.lastLink = 'https://www.open.mp/docs/scripting/resources/weaponids'
            local newtext = "{FFFFFF}Вы можете залить audio файл на {3369e8}G{d50f25}o{eeb211}o{3369e8}g{009925}l{d50f25}e {FFFFFF}Drive\n"..
            "или воспользоваться внешними аудиострим-ресурсами.\n"..
            "Поддерживаются форматы {696969}WAV / AIFF / MP3 / OGG.\n\n"..text 
            -- "\n{007FFF}" .. LastData.lastLink ..
            -- "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Укажите желаемую погоду мира') then
            LastData.lastLink = 'https://dev.prineside.com/en/gtasa_weather_id/'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Показать гангзону игроку') then
            LastData.lastLink = 'https://dev.prineside.com/gtasa_gangzone_editor/'
            local newtext = "{FFFFFF}".. text .. 
            "\n{007FFF}" .. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('Укажите текст') then
            if dialoghook.action then
               local newtext = text ..
               "\n\n{696969}Нажмите CTRL + SHIFT + V чтобы вставить последнее значение\n"
               return {dialogId, style, title, button1, button2, newtext}
            end
         end
         
         if text:find('Укажите два цвета для двух слотов в формате AARRGGBB') then
            local newtext = text ..
            "\n\n{FF0000}R - красный, {00FF00}G - зелёный, {0000FF}B - синий\n"..
            "{FFFFFF}Пример некоторых цветов:\n"..
            "{FFFFFF}FFFFFFFF, {363636}FF000000, {FF0000}FFFF0000\n"..
            "{00FF00}FF00FF00, {0000FF}FF0000FF, {FFFF00}FFFFFF00\n"..
            "{FF00FF}FFFF00FF, {00FFFF}FF00FFFF{FFFFFF}, и т.д.\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if text:find('{80BCFF}Модель.+{FFFFFF}') then
            dialoghook.modelinfo = true
            LastData.lastModelinfo = text:match('{80BCFF}Модель.+{FFFFFF}(%d+)\n')
            if LastData.lastModelinfo ~= 0 then
               sampTextdrawCreate(const.txdmodelinfoid, LastData.lastModelinfo, 20.0, 170.0)
               sampTextdrawSetStyle(const.txdmodelinfoid, 5)
               sampTextdrawSetBoxColorAndSize(const.txdmodelinfoid, 1, 0, 150.0, 150.0)
               sampTextdrawSetModelRotationZoomVehColor(const.txdmodelinfoid, 
               LastData.lastModelinfo, -10.0, 0, 45.0, 1.25, -1, -1)
               sampTextdrawSetShadow(const.txdmodelinfoid, 0, 1)
            end
         end
      end
      
      if ini.settings.cbvalautocomplete and dialoghook.cbvalue then
         if not text:find("N/A") then
            local lines = {}
            for line in string.gmatch(text, "([^\n]*)") do
               table.insert(lines, line)
            end
            
            local result = tostring(lines[#lines - 1])
            if result and string.len(result) >= 1 then
               LastData.lastCbvaluebuffer = result
            else
               LastData.lastCbvaluebuffer = nil
            end
            dialoghook.cbvalue = false
            
            if style == 0 or style == 1 then -- if MsgBox or Input Dialog
               local newtext = text ..
               "\n{696969}Нажмите CTRL + SHIFT + V чтобы вставить текущее значение\n"
               return {dialogId, style, title, button1, button2, newtext}
            end
         else
            dialoghook.cbvalue = false
            LastData.lastCbvaluebuffer = nil
         end
      end
      -- TODO optimise and split blocks later
      if ini.settings.cbvalautocomplete and dialoghook.tbvalue then
         if not text:find("N/A") then
            local lines = {}
            for line in string.gmatch(text, "([^\n]*)") do
               table.insert(lines, line)
            end
            
            local result = tostring(lines[#lines - 1])
            if result and string.len(result) >= 1 then
               LastData.lastTbvaluebuffer = result
            else
               LastData.lastTbvaluebuffer = nil
            end
            dialoghook.tbvalue = false
            
            if style == 0 or style == 1 then -- if MsgBox or Input Dialog
               local newtext = text ..
               "\n{696969}Нажмите CTRL + SHIFT + V чтобы вставить текущее значение\n"
               return {dialogId, style, title, button1, button2, newtext}
            end
         else
            dialoghook.tbvalue = false
            LastData.lastTbvaluebuffer = nil
         end
      end
      
      if ini.settings.backtoworld and dialoghook.backtoworld then
         if text:find('Вернуться в свой мир.* сек') then
            sampSendDialogResponse(32700, 1, 3, "Вернуться в свой мир")
            dialoghook.backtoworld = false
         end
      end
      
      if text:find('Введите код') then
         if dialoghook.autoattach and dialoghook.attachcode then
            lua_thread.create(function()
               wait(200)
               sampSetCurrentDialogEditboxText(textbuffer.attachcode.v)
               wait(50)
               sampCloseCurrentDialogWithButton(1)
            end)
         else
            dialoghook.attachcode = true
            LastData.lastTextBuffer = "CC49-45A5-1EC8-4A50"
            local newtext = "\
            Например: сет аттачей - Пикачу {cdcdcd}CC49-45A5-1EC8-4A50\
            Нажмите CTRL + SHIFT + V чтобы вставить этот пример."
            return {dialogId, style, title, button1, button2, text..newtext}
         end
      end
      
      if title:find("Покинуть данный мир") then
         dialoghook.backtoworld = false
      end
      
      if text:find("Создать игровой мир") then
         if text:find("сек") then
            playerdata.isWorldJoinUnavailable = true
         else
            playerdata.isWorldJoinUnavailable = false
         end
      end
      
      if text:find("После подтверждения Вы отправитесь в") then
         dialoghook.exitdialog = true
         dialoghook.backtoworld = false
         if playerdata.isWorldHoster then
            sampSendDialogResponse(32700, 1, nil, nil)
            sampCloseCurrentDialogWithButton(1)
         else
            restorePlayerSkin()
         end
      end
      
      if ini.settings.extendedmenues then
         if title:find('Поиск') then
            local newtext = text ..
            "\nИскать можно так же через /cbsearch <text>\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         if title:find('Редактирование') then
            if text:find("скина, который будет использован") then
               local skin = getCharModel(playerPed)
               if skin then
                  local newtext = "\n{696969}Ваш текущий скин: "..tostring(skin)
                  return {dialogId, style, title, button1, button2, text..newtext}
               end
            end
         end
         
         -- Added new features to /omenu
         if title:find("Редактирование / Клонирование") then
            dialoghook.editdialog = true
            
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
            "Очистить текстуры\n"..
            "Затемнить\n"..
            "Сделать прозрачным\n"..
            "Телепортироваться\n"..
            "Информация\n"
            return {dialogId, style, newtitle, button1, button2, newitems}
         end
         
         if title:find("Master Text Textures") then
            -- Automatic ID substitution for /otext
            if text:find("Укажите ID") then
               if LastObject.localid and dialoghook.editdialog then
                  sampSendDialogResponse(32700, 1, nil, LastObject.localid)
                  sampCloseCurrentDialogWithButton(0)
               end
            end
            if text:find("Укажите цвет шрифта") or text:find("Укажите цвет фона") then
               if ini.settings.dialogautocomplete then
                  lua_thread.create(function()
                     wait(200)
                     sampSetCurrentDialogEditboxText("0xFFFFFFFF")
                  end)
               end
               local newtext = text ..
               " - {FF0000}R - красный, {00FF00}G - зелёный, {0000FF}B - синий\n"..
               "{FFFFFF}Пример некоторых цветов:\n"..
               "{FFFFFF}0xFFFFFFFF, {363636}0xFF000000, {FF0000}0xFFFF0000\n"..
               "{00FF00}0xFF00FF00, {0000FF}0xFF0000FF, {FFFF00}0xFFFFFF00\n"..
               "{FF00FF}0xFFFF00FF, {00FFFF}0xFF00FFFF{FFFFFF}, и т.д.\n"
               return {dialogId, style, title, button1, button2, newtext}
            end
            if text:find("Укажите текст объекта от 1 до 144 символов") then
               dialoghook.otext = true
               local newtext = "{FFFFFF}Используйте символ {FF6600}@{FFFFFF} - для переноса текста на след. строку\n"..
               "{FFFFFF}Чтобы экранировать спецсимвол, перед символом нужно поставить символ {FF6600}\\{FFFFFF}\n"..
               "{FFFFFF}Например: input: 2\\ + 2 = 4 | output: 2 + 2 = 4\n"..
               "\nМожно указать тег цвета в формате {RRGGBB}\n"..
               "{FFFFFF}FFFFFF, {363636}363636, {FF0000}FF0000, "..
               "{00FF00}00FF00, {0000FF}0000FF, {FFFF00}FFFF00, "..
               "{FF00FF}FF00FF, {00FFFF}00FFFF{FFFFFF}, и т.д.\n"..
               "\n{FFFFFF}Укажите текст объекта от 1 до 144 символов"

               if string.len(LastData.lastOtext) > 1 then 
                  newtext = newtext.."\nПоследний текст: "..LastData.lastOtext.."\n"..
                  "{696969}Нажмите CTRL + SHIFT + V чтобы вставить последний текст\n"
               end
               
               return {dialogId, style, title, button1, button2, newtext}
            end
         end
         
         -- Extend cb set components dialog
         if text:find("Выдать компонент транспорту") and style == 1 then
            LastData.lastLink = 'https://sampwiki.blast.hk/wiki/Car_Component_ID'
            local newtext = "{FFFFFF}Выдать компонент транспорту\n".. 
            "\n1008, 1009, 1010 - Nitro (5,2,10 times)\n"..
            "1025 - Offroad wheels\n"..
            "1087 - Hydraulics\n"..
            "\n{007FFF}".. LastData.lastLink ..
            "\n{696969}Нажмите CTRL + SHIFT + L чтобы открыть ссылку в браузере\n"
            return {dialogId, style, title, button1, button2, newtext}
         end
         
         -- Extend main /vmenu
         if text:find("Доступ к транспорту") and style == 4 then
            local newtitle = title
            
            local newitems = 
            "{FF0000}Удалить транспорт\n"..
            "Тп к транспорту\n"..
            "Тп транспорт к себе\n"
            
            if LastData.lastVehicle then
               local result, carhandle = sampGetCarHandleBySampVehicleId(LastData.lastVehicle)
               local health = getCarHealth(carhandle)
               newtitle = " Vmenu - {696969}Id: "..LastData.lastVehicle.."{FF0000} hp: "..health
            else
               if isCharInAnyCar(playerPed) then
                  local carhandle = storeCarCharIsInNoSave(playerPed) 
                  if carhandle then
                     local health = getCarHealth(carhandle)
                     newtitle = " Vmenu - {696969}Id:"..carhandle.."{FF0000} hp: "..getCarHealth(carhandle)
                  end
               end
            end
            
            return {dialogId, style, newtitle, button1, button2, text..newitems}
         end
         
         -- Extend main /vw menu
         if text:find("Название мира") and style == 4 then
            if dialoghook.devmenutoggle then
               lua_thread.create(function()
                  wait(200)
                  sampSendDialogResponse(32700, 1, 11, "- Режим разработки")
                  sampCloseCurrentDialogWithButton(0)
                  dialoghook.devmenutoggle = false
               end)
            end
            
            if dialoghook.logstoggle then
               lua_thread.create(function()
                  wait(200)
                  sampSendDialogResponse(32700, 1, 7, "- Логи")
                  sampCloseCurrentDialogWithButton(0)
                  dialoghook.logstoggle = false
               end)
            end
            
            if dialoghook.saveworld then
               lua_thread.create(function()
                  wait(50)
                  sampSendDialogResponse(32700, 1, 15, "- Управление игровым миром")
                  wait(50)
                  sampSendDialogResponse(32700, 1, 8, "- Сохранить виртуальный мир")
                  dialoghook.saveworld = false
               end)
            end
            
            if dialoghook.spcars then
               lua_thread.create(function()
                  wait(5)
                  sampSendDialogResponse(32700, 1, 15, "- Управление игровым миром")
                  wait(5)
                  sampSendDialogResponse(32700, 1, 11, "- Респаун свободного транспорта")
                  dialoghook.spcars = false
                  wait(5)
                  sampCloseCurrentDialogWithButton(0)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Весь незанятый транспорт был отправлен на спавн!", 0x0FF6600)
               end)
            end
            
            if dialoghook.resetguns then
               lua_thread.create(function()
                  wait(5)
                  sampSendDialogResponse(32700, 1, 15, "- Управление игровым миром")
                  wait(5)
                  sampSendDialogResponse(32700, 1, 0, "- Обнулить все оружие")
                  dialoghook.resetguns = false
                  wait(5)
                  sampCloseCurrentDialogWithButton(0)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Все оружие у игроков было сброшено!", 0x0FF6600)
               end)
            end
            
            if dialoghook.resetvehs then
               lua_thread.create(function()
                  wait(5)
                  sampSendDialogResponse(32700, 1, 15, "- Управление игровым миром")
                  wait(5)
                  sampSendDialogResponse(32700, 1, 10, "- Обнулить свободный транспорт")
                  dialoghook.resetvehs = false
                  wait(5)
                  sampCloseCurrentDialogWithButton(0)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Весь незанятый транспорт был обнулен!", 0x0FF6600)
               end)
            end
            
            if dialoghook.vkickall then
               lua_thread.create(function()
                  wait(5)
                  sampSendDialogResponse(32700, 1, 15, "- Управление игровым миром")
                  wait(5)
                  sampSendDialogResponse(32700, 1, 7, "- Выкинуть всех игроков")
                  dialoghook.vkickall = false
                  wait(5)
                  sampCloseCurrentDialogWithButton(0)
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Все игроки были кикнуты из мира!", 0x0FF6600)
               end)
            end
            
            local newitems = 
            " - Настройки для команд\n"..
            " - Интерьеры\n"
            return {dialogId, style, title, button1, button2, text..newitems}
         end
         
         if dialoghook.saveworldname then
           if title:find("Сохранения шаг 2") then
               for line in string.gmatch(text, "([^\n]*)") do
                  local worldname = string.match(line, "сохранения: {FFFFFF}(.+)")
                  if worldname then
                     lua_thread.create(function()
                        wait(200)
                        sampSetCurrentDialogEditboxText(worldname)
                     end)
                  end
                  dialoghook.saveworldname = false
               end
            end
         end
         
         -- Extend world manage menu
         if text:find("Обнулить все оружие") and style == 4 then
            local newitems = "\n"..
            "{696969}- Список командных блоков\n"..
            "{696969}- Список триггер блоков\n"..
            "{696969}- Список таймеров\n"..
            "{696969}- Список объектов в мире\n"..
            "{696969}- Список перемещаемых объектов\n"..
            "{696969}- Список переменных\n"..
            "{696969}- Список переменных игрока\n"..
            "{696969}- Список аудиостримов\n"
            return {dialogId, style, title, button1, button2, text..newitems}
         end
         -- -- Extend main /menu
         if title:match("^Меню$") then
            local newitems = "\n"..
            "Заспавнить себя\n"..
            "Слапнуть себя\n"..
            "Взять Jetpack\n"..
            "Взять оружие\n"..
            "Список друзей\n"..
            "Ачивки\n"
            return {dialogId, style, title, button1, button2, text..newitems}
         end
         if title:find("Настройки игрока") then
            local newitems = "\n"..
            "15. Сменить скин\n"
            return {dialogId, style, title, button1, button2, text..newitems}
         end
      end
      
      -- cblist dialogs autocomplete
      if ini.settings.dialogautocomplete then
         if text:find("Установить игроку чекпоинт") then
            lua_thread.create(function()
               wait(200)
               local px, py, pz = getCharCoordinates(playerPed)
               sampSetCurrentDialogEditboxText(string.format("%.1f %.1f %.1f 3.0", px, py, pz))
            end)
         end
         if text:find("Создать 3D текст") then
            lua_thread.create(function()
               wait(200)
               local px, py, pz = getCharCoordinates(playerPed)
               sampSetCurrentDialogEditboxText(string.format("%.1f %.1f %.1f", px, py, pz))
            end)
         end
         if text:find("Укажите желаемое время удержания мира") then
            lua_thread.create(function()
               wait(200)
               sampSetCurrentDialogEditboxText("300")
            end)
         end
         if text:find("Укажите желаемую гравитацию мира") then
            lua_thread.create(function()
               wait(200)
               sampSetCurrentDialogEditboxText("0.008")
            end)
         end
         if text:find('Установить поворот игроку:') then
            local angle = getCharHeading(playerPed)
            lua_thread.create(function()
               wait(200)
               sampSetCurrentDialogEditboxText(("%.2f"):format(angle))
            end)
         end
         
         if text:find("Укажите желаемое название мира") then
            dialoghook.setworldname = true
            if ini.tmp.worldname then
               if ini.tmp.worldname:len() > 1 then
                  lua_thread.create(function()
                     wait(200)
                     sampSetCurrentDialogEditboxText(tostring(ini.tmp.worldname))
                  end)
               end
            end
         end
         
         
         if title:find("ADS текст") then
            dialoghook.setsadstext = true
            if ini.tmp.sadstext then
               if ini.tmp.sadstext:len() > 1 then
                  lua_thread.create(function()
                     wait(200)
                     sampSetCurrentDialogEditboxText(tostring(ini.tmp.sadstext))
                  end)
               end
            end
         end
         
         if text:find("Укажите желаемое описание мира") then
            dialoghook.setworlddescription = true
            if text:find("Текущее описание") then
               lua_thread.create(function()
                  for line in string.gmatch(text, "([^\n]*)") do
                     if line:len() > 1 then
                        LastData.lastWorldDescription = line
                     end
                  end
                  wait(200)
                  sampSetCurrentDialogEditboxText(LastData.lastWorldDescription)
               end)
            else
               if ini.tmp.worlddescription then
                  if ini.tmp.worlddescription:len() > 1 then
                     lua_thread.create(function()
                        wait(200)
                        sampSetCurrentDialogEditboxText(tostring(ini.tmp.worlddescription))
                     end)
                  end
               end
            end
         end
      end
      
      -- Auto set activation mode for new cb's
      if ini.settings.cbnewactivation then
         if text:find("- Значение #") and text:find("Активация.*Вход") then
            dialoghook.cbnewactivation = true
            if not dialoghook.suspendcbactivation then
               --dialoghook.cbnewactivation = true
               sampSendDialogResponse(32700, 1, 11, "Активация")
               if text:find("Вход") and dialoghook.cbnewactivation then
                  sampSendDialogResponse(32700, 1, ini.settings.cbnewactivationitem,
                  cbActivationItemsList[ini.settings.cbnewactivationitem])
                  dialoghook.cbnewactivation = false
               end
            end
         end
      end
   end
      
   -- Skip olist when exit from /omenu
   if isTrainingSanbox and dialogId == 65535 and ini.settings.skipomenu then      
      if LastData.lastDialogInput then
         if not LastData.lastDialogInput:find("Слот") -- /att fix
         and not LastData.lastDialogInput:find("Скин по умолчанию") -- team skin fix
         and not LastData.lastDialogInput:find("Модель входа") -- /pass fix
         and not LastData.lastDialogInput:find("Модель выхода") -- /pass fix
         and not LastData.lastDialogInput:find("Редактировать") -- /pass fix
         and not LastData.lastDialogInput:find("Клонировать") -- /pass fix
         then
            if LastData.lastDialogTitle then
               if not LastData.lastDialogTitle:find("Выберите часть тела") 
               and not LastData.lastDialogTitle:find("Выбор слота") 
               then -- /new att fix
                  lua_thread.create(function()
                     wait(5)
                     sampSendClickTextdraw(2118)
                  end)
               end
            else
               lua_thread.create(function()
                  wait(5)
                  sampSendClickTextdraw(2118)
               end)
            end
         end
      end
   end
end

function sampev.onServerMessage(color, text)
   --HEX to dec example:
   --local hex = ('%x'):format(4289003775)
   --local dec = tonumber('FFA500FF', 16)
   local id = getLocalPlayerId()
   local nickname = sampGetPlayerNickname(id)
   
   if checkbox.logmessages.v then
      print(string.format("%s, %s", color, text))
   end
   
   if color == -65281 and text:find('PM от') or text:find('PM к') then -- -65281 Yellow color
      if ini.settings.savepmmessages then
         local file = io.open(getGameDirectory()..
         "/moonloader/resource/mappingtoolkit/history/pmmessages.txt", "a")
         file:write(("[%s] %s \n"):format(tostring(os.date("%d.%m.%Y %X")), text))
         file:close()
      end
   end
   -- Corrects erroneous recieving of empty chat messages
   -- if text:match("^%s.*$") and text:len() <= 1 then
      -- return false
   -- end
   -- new version ignore erroneous recieving of empty chat messages
   -- local chatsymbol = text:find(":")
   -- local timestamp = text:match("%d%d:%d%d:%d%d")
   -- if chatsymbol then
      -- local chatmessage = text
      -- if timestamp then
         -- chatmessage = string.sub(text, 11+2, text:len()) --timestamp 11 symb + 2 spaces
      -- else
         -- chatmessage = string.sub(chatmessage, chatsymbol+1, chatmessage:len())
      -- end
      
      -- -- local hexcolor = chatmessage:find("{FFA500}.*")
      -- -- if isTrainingSanbox and hexcolor then
         -- -- chatmessage = string.sub(chatmessage, hexcolor+8, chatmessage:len())
         -- -- print(chatmessage, hexcolor)
      -- -- end
   
      -- if chatmessage:match("^%s.+$") then
         -- if not chatmessage:find("[а-Я%d%w]+") then
            -- chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
            -- chatlog:write(os.date("[%H:%M:%S] ")..text.."\r\n")
            -- chatlog:close()
            -- return false
         -- end
      -- end
   -- end
   
   if checkbox.allchatoff.v then
      -- disable global chat, but write information to chatlog
      chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
      chatlog:write(os.date("[%H:%M:%S] ")..text.."\r\n")
      chatlog:close()
      return false
   end
   
   if playerdata.isChatFreezed then
      table.insert(chatbuffer, {color = color, text = text})
      return false
   end
   
   -- if text:find("Официальный сайт сервера training") then
   -- end
   
   if isTrainingSanbox then
      if text:find("Хочешь смешную шутку? А она тебя нет. Куда ты возращаться собрался ты и так тут") then
         playerdata.isWorldHoster = true
         ini.tmp.worldhoster = true
         inicfg.save(ini, configIni)
      end
      if text:find("Невозможно создать новый мир, за вами уже есть закрепленный мир") then
         -- "Создать игровой мир"
         if not playerdata.isWorldJoinUnavailable then
            playerdata.isWorldHoster = true
            ini.tmp.worldhoster = true
            inicfg.save(ini, configIni)
            sampSendChat("/vw")
         end
         return false
      end
      if text:find("Меню управления миром") then
         playerdata.isWorldHoster = true
         ini.tmp.worldhoster = true
         inicfg.save(ini, configIni)
         if ini.settings.hotkeys then
            sampAddChatMessage("[SERVER]: {FFFFFF}Меню управления миром - /vw или клавиша - M", 0x0FF6600)
         end
         return false
      end
   end
   
   if ini.settings.antiads then
      if text:match(".+ADS*") or text:match(".+SALE*") then
         chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
         chatlog:write(os.date("[%H:%M:%S] [ADBlock] ")..text.."\r\n")
         chatlog:close()
         return false
      end
   end
   
   if ini.settings.antichatbot then
      if text:match(".+bot.*") then
         chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
         chatlog:write(os.date("[%H:%M:%S] [ADBlock] ")..text.."\r\n")
         chatlog:close()
         return false
      end
      if isTrainingSanbox then
         if text:match(".+CZ00.*") or text:match(".+czo.*") then
            chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
            chatlog:write(os.date("[%H:%M:%S] [ADBlock] ")..text.."\r\n")
            chatlog:close()
            return false
         end
      end
   end
   
   if ini.settings.chathiderp then 
      if color == -793842689 then
         return false
      end
   end
   
   if ini.settings.chatonlysystem then
      if isTrainingSanbox then
         local tag = string.match(text, "%[.*%]")
         if not tag then
            return false
         end
      end
   end
   
   if isTrainingSanbox then
   
      if text:find("SERVER: Unknown command") then
         sampAddChatMessage("[ERROR]: {FFFFFF}Команда не найдена. Просмотреть список доступных команд {696969}/cmdlist", 0x0CC0000)
         return false
      end
      
      if color == -872414977 and text:find("[ERROR].+Указан неверный ID предмета!") then
         input.error = true
      end
      
      if text:find("Мир успешно загружен") then
         dialoghook.loadworld = false
         LastData.lastLoadedWorldNumber = nil
         LastData.lastMinigame = nil
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Используйте /tpo или метку на карте чтобы телепортироваться.", 0x0FF6600)
      end
      
      if text:find("Виртуальный мир успешно создан") 
      or text:find("Вы создали пробный VIP мир") then
         --LastData.lastWorldName = "{696969}Виртуальный мир"
         WorldJoinInit()
      end
      
      if text:find("[SERVER].+Вы присоединились к лобби") then
         LastData.lastMinigame = 4
      end
      
      -- if text:find("[ERROR].+Вы находитесь не в статичном мире") then
      -- end
      
      if text:find("Не используйте данную функцию часто") then
         dialoghook.loadworld = false
         LastData.lastLoadedWorldNumber = nil
      end
      
      if text:find("Хост "..nickname..".+"..id..".+ вернулся в мир") then
         dialoghook.backtoworld = false
         WorldJoinInit()
      end
      
      if text:find('Создан объект: (%d+)') then
         LastObject.localid = text:match('Создан объект: (%d+)')
         if LastData.lastModel then
            local objectName = tostring(sampObjectModelNames[LastData.lastModel])
            local newtext = ("%s (%s)"):format(text, objectName)
            return {color, newtext}
         end
      end
      
      if text:find('Создан action: (%d+)') then
         LastData.lastAction = text:match('Создан action: (%d+)')
      end
      
      if text:find('Данный объект запрещен или не существует') then
         lua_thread.create(function()
            wait(500)
            if LastObject.modelid then
               sampAddChatMessage("Последний использованный объект: {696969}"..LastObject.modelid, -1)
            end
            local closestObjectId = getClosestObjectId()
            if closestObjectId then
               sampAddChatMessage("Ближайший объект: {696969}"..getObjectModel(closestObjectId).." ("..tostring(sampObjectModelNames[getObjectModel(closestObjectId)])..") ", -1)
            end
            sampAddChatMessage(("Можете попробовать объект: {696969}%d {FFFFFF}(%s)"):format(getSafeObjectModel(), tostring(sampObjectModelNames[getSafeObjectModel()])), -1)
         end)
      end
      
      if text:find('Выбран предмет: (%d+)') then
         LastObject.localid = text:match('Выбран предмет: (%d+)')
      end
      
      if text:find('Установлен комадный блок: (%d+)') then
         LastData.lastCb = text:match('Установлен комадный блок: (%d+)')
      end
      
      if text:find('Создан актер ID (%d+)') then
         LastData.lastActor = text:match('Создан актер ID (%d+)')
      end
      
      if text:find('Вы отправлены на спаун!') then
         sampSendChat("/spawnme")
         playerdata.isWorldHoster = false
         ini.tmp.worldhoster = false
         inicfg.save(ini, configIni)
      end
      
      if text:find('Удален объект: (%d+)') then
         LastObject.localid = nil
         if LastRemovedObject.modelid then
            local objectName = tostring(sampObjectModelNames[LastRemovedObject.modelid])
            local newtext = ("%s (%s)"):format(text, objectName)
            return {color, newtext}
         end
      end
      
      if text:find('Проход (%d+) успешно создан') then
         LastData.lastPass = text:match('Проход (%d+) успешно создан')
      end
      
      if text:find('Проход (%d+) удален') then
         LastData.lastPass = nil
      end
      
      if text:find('На объект (%d+)') then
         LastObject.localid = text:match('.+На объект (%d+)')
         if text:find('слот (%d+)') then
            LastObject.txdslot = text:match('.+слот (%d+)')
         end
         if text:find('применена текстура: (%d+)') then
            local txdid = text:match('.+применена текстура: (%d+)')
            if tonumber(txdid) >= 0 and tonumber(txdid) <= 8704 then
               LastObject.txdid = tonumber(txdid)
               dialoghook.textureslist = false
               
               local txdtable = sampTextureList[LastObject.txdid+1]
               local txdname = tostring(txdtable[3])
               
               local file = io.open(getGameDirectory()..
               "/moonloader/resource/mappingtoolkit/history/texture.txt", "a")
               file:write(("[%s] id: %d slot: %d txdid: %d(%s)\n")
               :format(tostring(os.date("%d.%m.%Y %X")), 
               LastObject.localid, LastObject.txdslot, txdid, txdname))
               file:close()
            end
         end
      end
      
      if text:find('[SERVER].+Данный аккаунт зарегистрирован') then
         ini.tmp.worldhoster = false
         playerdata.isWorldHoster = false
         playerdata.flymode = false
         inicfg.save(ini, configIni)
      end
      
      if text:find('[SERVER].+/accept (%d+)') then
         LastData.lastAccept = text:match('[SERVER].+/accept (%d+)')
      end
      
      if text:find('[SERVER].+Прорисовку стрима: (%d+)') then
         input.streamdist.v = text:match('[SERVER].+Прорисовку стрима: (%d+)')
      end
      
      if text:find('[SERVER].+Ваш мир был успешно удалён') then
         ini.tmp.worldhoster = false
         inicfg.save(ini, configIni)
         playerdata.isWorldHoster = false
         LastData.lastLoadedWorldNumber = nil
      end
      
      -- ignore message if called for gangzonefix
      if text:find('Все гангзоны были удалены для вас') then
         return false
      end
      
      --if text:find('[ERROR]:{FFFFFF} Недоступно!') then
      if text:find('Недоступно!') then
         dialoghook.error = true
      end
      
      if text:find('Вы присоеденились к миру') then
         LastData.lastWorldName = string.match(text, "Вы присоеденились к миру: (.+)")
         worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(playerPed)
      end
      
      if text:find('[SERVER].+Хост.+вернулся в мир!') then
         LastData.lastMinigame = nil
      end
      
      if text:find("контент доступен только со сборки") then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Ссылка на скачивание была скопирована в буффер обмена. Подробнее: https://discord.gg/MZQm9kFMAZ", 0x0FF6600)
         setClipboardText('https://forum.training-server.com/d/20472-chto-takoe-ssmp-i-gde-ego-skachat')
      end
      -- [CB] Hook 
      -- if text:find('%[CB%]%:.+') and color == -10092289 then
         -- if text:find('вошел') or text:find('вошёл') 
         -- or text:find('зашел') or text:find('зашёл') 
         -- or text:find('присоединился') then
         -- end
      -- end
   end
   
   if ini.settings.blockhamster and isTrainingSanbox then
      if text:find("Hamster:") then
         input.isbot = true
         chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
         chatlog:write(os.date("[%H:%M:%S] ")..text.."\r\n")
         chatlog:close()
         return false
      elseif text:find("{FFA500}%p%p%p") and input.isbot then
         chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
         chatlog:write(os.date("[%H:%M:%S] ")..text.."\r\n")
         chatlog:close()
         return false
      else
         input.isbot = false
      end
   end
   
   if checkbox.chatmentions.v then
      -- ignore system messages by color
      if color ~= -10092289 --orange color training
      and color ~= 993737727 --black system color
      --and color ~= -1 then
      then
         -- mentions by nickname
         if text:find(nickname) then
            if text:find(":") then
               local pointpos = text:find(":")
               local cleartext = text:sub(pointpos, string.len(text))
               if cleartext:find(nickname) then
                  if ini.mentions.usegametext then
                     printStyledString('You were mentioned in the chat', 2000, 4)
                  end
                  if ini.mentions.usesound then
                     addOneOffSound(0.0, 0.0, 0.0, ini.mentions.sound) -- CHECKPOINT_GREEN
                  end
                  if ini.mentions.usecolor then
                     return {color, "{"..ini.mentions.color.."}"..text}
                  end
               end
            else
               if ini.mentions.usegametext then
                  printStyledString('You were mentioned in the chat', 2000, 4)
               end
               if ini.mentions.usesound then
                  addOneOffSound(0.0, 0.0, 0.0, ini.mentions.sound) -- CHECKPOINT_GREEN
               end
               if ini.mentions.usecolor then
                  return {color, "{"..ini.mentions.color.."}"..text}
               end
            end
         end
         
         -- mentions by id
         if not text:find("ADS") and not text:find("мин") then
            if text:match("[^/:]".."%s"..id.."%s(.+)") -- id text mention
            or text:match("@"..id.."%s") then -- @id mention
            --or text:match("(%s"..id.."%s)") then
               if ini.mentions.usegametext then
                  printStyledString('You were mentioned in the chat', 2000, 4)
               end
               if ini.mentions.usesound then
                  addOneOffSound(0.0, 0.0, 0.0, ini.mentions.sound) -- CHECKPOINT_GREEN
               end
               if ini.mentions.usecolor then
                  return {color, "{"..ini.mentions.color.."}"..text}
               end
            end
         end
      end
   end
   
   if ini.settings.chatfilter then
      for i = 1, #chatfilter do
         if text:find(chatfilter[i]) then
            chatlog = io.open(getFolderPath(5).."\\GTA San Andreas User Files\\SAMP\\chatlog.txt", "a")
            chatlog:write(os.date("[%H:%M:%S] [Chat-filter] ")..text.."\r\n")
            chatlog:close()
            return false
         end
      end
   end
   
   local formatChat = false
   local newtext = text
   
   if checkbox.anticaps.v then
      if isTrainingSanbox then
         local globalmessage = text:match(":{FFA500}.+")
         local nearmessage = text:match(":%s.+")
         local worldmessage = text:match(":{91FF00}.+")
         
         if globalmessage then
            local pos = text:find(":{FFA500}")
            newtext = string.lower(string.sub(globalmessage, 2, globalmessage:len()))
            newtext = ("%s %s"):format(string.sub(text, 0, pos), newtext)
            formatChat = true
         elseif worldmessage then
            local pos = text:find(":{91FF00}")
            newtext = string.lower(string.sub(worldmessage, 2, worldmessage:len()))
            newtext = ("%s %s"):format(string.sub(text, 0, pos), newtext)
            formatChat = true
         elseif nearmessage then
            local pos = text:find(":%s")
            newtext = string.lower(string.sub(nearmessage, 3, nearmessage:len()))
            newtext = ("%s %s"):format(string.sub(text, 0, pos), newtext)
            formatChat = true
         end
      else
         newtext = string.nlower(newtext)
         formatChat = true
      end
   end
   
   if checkbox.chathidecb.v and color == -10092289 then
      if newtext:find("%[CB%]%:.*") then
         newtext = newtext:gsub("%[CB%]%:.", "")
         formatChat = true
      end
   end
   
   -- if text:find("%") then
      -- newtext = newtext:gsub("%", "#")
      -- formatChat = true
      -- return false
   -- end
   
   if formatChat then 
      return {color, newtext}
   end
   
end

function sampev.onSendCommand(command)
   LastData.lastCommand = command
   
   -- ignore triggering on world custom commands like //menu
   if isTrainingSanbox and command:find("//") then
      return {command}
   end
   
   if isTrainingSanbox then
      -- Automatic substitution of the last object ID for some commands
      if not command:find('(/%a+) (.+)') then
         if LastObject.localid then            
            if command:find("^/ogh$") then
               sampSendChat("/ogh "..LastObject.localid)
               return false
            end
            
            if command:find("^/untexture$") then
               sampSendChat("/untexture "..LastObject.localid)
               return false
            end
            
            if command:find("^/delveh$") then
               local closestcarhandle, closestcarid = getClosestCar()
               if closestcarhandle then 
                  sampSendChat("/delveh "..closestcarid)
               end
               return false
            end
            
            if command:find("^/stexture$") then
               if not command:find('(/%a+) (.+)') then
                  if LastObject.txdid ~= nil then
                     sampAddChatMessage("[SCRIPT]: {FFFFFF}Последняя использованная текстура: " .. LastObject.txdid, 0x0FF6600)
                  end
               end
            end
            
         end
      end
   end
   
   if isTrainingSanbox then
      if command:find("^/dm") then
         LastData.lastMinigame = 1
      elseif command:find("^/gungame") or command:find("^/gg") then
         LastData.lastMinigame = 3
      -- elseif command:find("^/copchase") or command:find("^/ch") then
         -- LastData.lastMinigame = 4
      elseif command:find("^/wot") then
         LastData.lastMinigame = 2
      elseif command:find("^/derby") then
         LastData.lastMinigame = 5
      end
   end
   
   if not isTrainingSanbox then
      if command:find("^/setweather") then
         if command:find('(/%a+) (.+)') then
            local cmd, arg = command:match('(/%a+) (.+)')
            local id = tonumber(arg)
            if type(id) == "number" then
               if id >= 0 and id <= 45 then
                  ini.settings.lockserverweather = true
                  patch_samp_time_set(true)
                  slider.weather.v = id
                  setWeather(slider.weather.v)
                  sampAddChatMessage("Вы установили погоду - "..id, 0x000FF00)
               end
            end
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Укажите верный ид погоды от 0 до 45", 0x0FF6600)
         end
         return false
      end
      
      if command:find("^/settime") then
         if command:find('(/%a+) (.+)') then
            local cmd, arg = command:match('(/%a+) (.+)')
            local id = tonumber(arg)
            if type(id) == "number" then
               if id >= 0 and id <= 12 then
                  ini.settings.lockserverweather = true
                  patch_samp_time_set(true)
                  slider.time.v = id
                  setTime(slider.time.v)
                  sampAddChatMessage("Вы установили время - "..id, 0x000FF00)
               end
            end
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Укажите время от 0 до 12", 0x0FF6600)
         end
         return false
      end
   end
   
   if isTrainingSanbox then
      if command:find("^/jp$") then
         sampSendChat("/jetpack")
      end
   end
   
   if command:find("^/id$") then
      local playersTotal = 0
      for k, v in ipairs(getAllChars()) do
         local res, id = sampGetPlayerIdByCharHandle(v)
         if res then
            sampAddChatMessage(("  %s - ID:(%d)"):format(sampGetPlayerNickname(id), id), -1)
            playersTotal = playersTotal + 1
         end
      end
      -- if playersTotal ~= 0 then
         -- sampAddChatMessage("Найдено "..playersTotal.." игроков", -1)
      -- end
   end
   
   if isTrainingSanbox then
      if command:find("^/spec$") then
         if getClosestPlayerId() ~= -1 then
            if sampIsPlayerConnected(getClosestPlayerId()) then
               sampSendChat("/sp "..getClosestPlayerId())
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Игрок не подключен либо вышел", 0x0FF6600) 
            end
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найдено игроков рядом", 0x0FF6600)
            sampSendChat("/sp")
         end
         return false
      end
   end
   
   if command:find("^/hp") then
      if command:find('(/%a+) (.+) (.+)') then
         local cmd, id, hp = command:match('(/%a+) (.+) (.+)')
         local id = tonumber(id)
         local hp = tonumber(hp)
         if type(id) == "number" and type(hp) == "number" then
            if sampIsPlayerConnected(id) or id == getLocalPlayerId() then
               if hp >= 0 and hp <= 100 then
                  sampSendChat("/sethp "..id.." "..hp)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Допустимые значения хп 0-100", 0x0FF6600)   
               end
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Игрок не подключен либо вышел", 0x0FF6600)   
            end
         end
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Используйте /hp <id> <кол-во>", 0x0FF6600)
      end
      return false
   end
   
   if command:find("^/arm") then
      if command:find('(/%a+) (.+) (.+)') then
         local cmd, id, arm = command:match('(/%a+) (.+) (.+)')
         local id = tonumber(id)
         local arm = tonumber(arm)
         if type(id) == "number" and type(arm) == "number" then
            if sampIsPlayerConnected(id) or id == getLocalPlayerId() then
               if arm >= 0 and arm <= 100 then
                  sampSendChat("/setarm "..id.." "..arm)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Допустимые значения брони 0-100", 0x0FF6600)   
               end
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Игрок не подключен либо вышел", 0x0FF6600)   
            end
         end
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Используйте /arm <id> <кол-во>", 0x0FF6600)
      end
      return false
   end
   
   if command:find("^/ближ") or command:find("^/nearest") then
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
   
   if command:find("^/коорд") or command:find("^/coord") then
      local posX, posY, posZ = getCharCoordinates(playerPed)
      local posA = getCharHeading(playerPed)
      sampAddChatMessage(string.format("Ваши координаты: {696969}%.2f %.2f %.2f {FFFFFF}Угол поворота: {696969}%.2f", posX, posY, posZ, posA), -1)
      if isTrainingSanbox and playerdata.isWorldHoster then
         sampAddChatMessage(string.format("Используйте: /xyz {696969}%.2f %.2f %.2f", posX, posY, posZ), -1)
      end
      return false
   end
   
   if command:find("^/отсчет") or command:find("^/countdown") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local time = tonumber(arg)
         if type(time) == "number" then
            if time >= 1 and time <= 10 then 
               lua_thread.create(function()
                  while time ~= 0 do
                     time = time - 1
                     if time > 0 then
                        if isTrainingSanbox then
                           sampSendChat("/s "..time)
                        else
                           sampSendChat(""..time)
                        end
                     else
                        if isTrainingSanbox then
                           sampSendChat("/s GO!")
                        else
                           sampSendChat("GO!")
                        end
                     end
                     wait(1000)
                  end
               end)
            else
               sampAddChatMessage("Используйте /count <1-10>", -1)
               return false
            end
         else
            sampAddChatMessage("Используйте /count <1-10>", -1)
            return false
         end
      end
      return false
   end
   
   if command:find("^/exit") or command:find("^/выход") then
      playerdata.isWorldHoster = false
      ini.tmp.worldhoster = false
      inicfg.save(ini, configIni)
      edit.mode = 0
      LastData.lastMinigame = nil
      LastData.lastWorldNumber = 0
      LastData.lastWorldName = ""
      worldspawnpos.x = 0
      worldspawnpos.y = 0
      worldspawnpos.z = 0
      -- fix audiostream 
      if isTrainingSanbox then
         -- send StopAudioStream()
         local bs = raknetNewBitStream()
         raknetEmulRpcReceiveBitStream(42,bs)         
         raknetDeleteBitStream(bs)
      end
      
   end
   
   if command:find("^/time$") and isTrainingSanbox then
      if not command:find('(/%a+) (.+)') then
         sampAddChatMessage("Сегодня "..os.date("%x %X"), -1)
      end
   end
            
   if command:find("^/savepos") then
      if sampIsLocalPlayerSpawned() then
         tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(playerPed)
         setClipboardText(string.format("%.2f %.2f %.2f", tpcpos.x, tpcpos.y, tpcpos.z))
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Позиция скопирована в буффер обмена", 0x0FF6600)
      end
      if not isTrainingSanbox then
         return false
      end
   end
   
   if command:find("^/actor$") then
      -- fix stuck on actor
      if isTrainingSanbox and not command:find('(/%a+) (.+)') then
         if sampIsLocalPlayerSpawned() then
            local x, y, z = getCharCoordinates(playerPed)   
            setCharCoordinates(playerPed, x + 0.2, y, z)
         end
      end
   end
   
   if command:find("^/gopos") then
      if sampIsLocalPlayerSpawned() then
         if tpcpos.x and tpcpos.x ~= 0 then
            if isTrainingSanbox then
               sampSendChat(string.format("/xyz %f %f %f",
               tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
               sampAddChatMessage(string.format("[SCRIPT]: {FFFFFF}Вы телепортировались на координаты: %.2f %.2f %.2f",
               tpcpos.x, tpcpos.y, tpcpos.z), 0x0FF6600)
            else
               --setCharCoordinates(playerPed, tpcpos.x, tpcpos.y, tpcpos.z)
               sampAddChatMessage("Недоступно для вашего сервера.", -1)
            end
         else
            sampAddChatMessage("Сперва сохраните позицию через /savepos.", -1)
         end
      end
      return false
   end
   
   if command:find("^/jump") then
      if sampIsLocalPlayerSpawned() then
         JumpForward()
      end
      return false
   end
   
   if command:find("^/skin") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local skinid = tonumber(arg)
         if type(skinid) == "number" then
            if isValidSkin(skinid) then
               local currentskin = getCharModel(playerPed)
               if currentskin ~= skinid then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы сменили скин {696969}"..currentskin.."{FFFFFF} на {696969}"..skinid, 0x0FF6600)
               end
            end
         end
      end
   end
   
   if isTrainingSanbox then 
      if command:find("^/flymode") then
         if isTrainingSanbox then
            if not playerdata.isWorldHoster then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы не хостер в мире!", 0x0FF6600)
               return false
            end
         end
         
         if isCharInAnyCar(playerPed) then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно в транспорте!", 0x0FF6600)
            return false
         end
         
         toggleFlyMode()
         
         if ini.settings.hotkeystips and playerdata.flymode then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Управление в режиме полета:", 0x0FF6600)
            sampAddChatMessage("[SCRIPT]: Пробел{FFFFFF} - Вверх, {FF6600}левый SHIFT{FFFFFF} - Вниз.", 0x0FF6600)
            sampAddChatMessage("[SCRIPT]: WASD{FFFFFF} - перемещение по координатам.", 0x0FF6600)
            sampAddChatMessage("[SCRIPT]: Кнопки мыши{FFFFFF} - ускорение/замедление.", 0x0FF6600)
            sampAddChatMessage("[SCRIPT]: F/ENTER{FFFFFF} - выйти из режима полета.", 0x0FF6600)
         end
         return false
      end
   end
   
   if command:find("^/slapme") and not isTrainingSanbox then
      if sampIsLocalPlayerSpawned() then
         local posX, posY, posZ = getCharCoordinates(playerPed)
         setCharCoordinates(playerPed, posX, posY, posZ+1.0)
      end
      return false
   end
   
   if command:find("^/spawnme") and not isTrainingSanbox  then
      local posX, posY, posZ = getCharCoordinates(playerPed)
      setCharCoordinates(playerPed, posX, posY, posZ+0.2)
      freezeCharPosition(playerPed, false)
      setPlayerControl(PLAYER_HANDLE, true)
      restoreCameraJumpcut()
      clearCharTasksImmediately(playerPed)
      return false
   end
   
   -- editmodes hook
   if command:find("^/csel") or command:find("^/editobject") and not isTrainingSanbox then
      sampAddChatMessage("Включен режим редактирования объекта", 0x000FF00)
      enterEditObject()
      return false
   end
   
   if isTrainingSanbox and command:find("^/action") then
      -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Рекомендуется использовать /otext вместо /action", 0x0FF6600)
      dialoghook.action = true
      
      if LastData.lastAction then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Последний созданный action "..LastData.lastAction, 0x0FF6600)
      end
   end
   
   if isTrainingSanbox 
   and command:find("^/pickuplist$") 
   or command:find("^/passlist$") then
      local pickupcounter = 0
      for i = 1, 4096 do
          local pickup = sampGetPickupHandleBySampId(i)
          local pool = sampGetPickupPoolPtr()
          local mdid = (i * 20) + 61444 + pool
          local pickupmodel = readMemory(mdid, 4, false)
          
          local x, y, z = getPickupCoordinates(pickup)
          local px, py, pz = getCharCoordinates(playerPed)
          local dist = getDistanceBetweenCoords3d(px, py, pz, x, y, z)
          
          if mdid and pickupmodel then
             if pickupmodel ~= 0 and dist <= 1000 then
                pickupcounter = pickupcounter + 1
                sampAddChatMessage(("Pickup id(internal):{696969} %i, {FFFFFF}distance:{696969} %.1f {FFFFFF}m., model: {696969}%i(%s)")
                :format(i, dist, pickupmodel, tostring(sampObjectModelNames[pickupmodel])), -1)
             end
          end
       end
       if pickupcounter == 0 then
          sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найдено элементов в зоне стрима!", 0x0FF6600)
       end
       return false
    end
   
   if isTrainingSanbox and command:find("^/editpass") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            sampSendChat("/pass "..id)
         end
      else
         sampSendChat("/passinfo")
         --sampAddChatMessage("[SYNTAX]: {FFFFFF}/pass <id>", 0x09A9999)
      end
   end
   
   if isTrainingSanbox and command:find("^/vmenu") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            LastData.lastVehicle = id
         end
      else
         local closestcarhandle, closestcarid = getClosestCar()
         if closestcarhandle then
            sampSendChat("/vmenu "..closestcarid)
         end
      end
   end
   
   if isTrainingSanbox then
      if command:find("^/actionlist") or command:find("^/alist$") then
         sampAddChatMessage("[SCRIPT]: {FFFFFF} Обратите внимание что internalid не совпадает с id сервера!", 0x0FF6600)
         sampAddChatMessage("Список 3d текстов (/action):", -1)
         for id = 1024, 2048 do -- on Training started 1024 
            if sampIs3dTextDefined(id) then
               local text, color, posX, posY, posZ, streamdistance, ignoreWalls, playerId, vehicleId = sampGet3dTextInfoById(id)
               if playerId == 65535 and vehicleId == 65535 and streamdistance == 10 then
                  local pX, pY, pZ = getCharCoordinates(playerPed)
                  local distance = getDistanceBetweenCoords3d(posX, posY, posZ, pX, pY, pZ)
                  sampAddChatMessage(("Action id(internal): %i, distance: %.1f m., text: %s"):format(id-1024, distance, text), color)
               end
            end
         end
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Для редактирования используйте /editaction <id>, или телепортируйтесь /tpaction <id>", 0x0FF6600)
         return false
      end
   end
   
   if isTrainingSanbox then
      if command:find("^/actorlist") or command:find("^/actors") then
         sampAddChatMessage("Список актеров:", -1)
         local actorsCount = 0
         for id = 1024, 2048 do -- on Training started 1024 
            if sampIs3dTextDefined(id) then
               local text, color, posX, posY, posZ, streamdistance, ignoreWalls, playerId, vehicleId = sampGet3dTextInfoById(id)
               if playerId == 65535 and vehicleId == 65535 and streamdistance == 9 then
                  local pX, pY, pZ = getCharCoordinates(playerPed)
                  local distance = getDistanceBetweenCoords3d(posX, posY, posZ, pX, pY, pZ)
                  sampAddChatMessage(("%s, distance: %.1f m."):format(text, distance), -1)
                  actorsCount = actorsCount + 1
               end
            end
         end
         if actorsCount == 0 then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Актеры в стриме не обнаружены, либо вы не задали им имена", 0x0FF6600)
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Для редактирования используйте /actor <id>", 0x0FF6600)         
         end
         return false
      end
   end
   
   if isTrainingSanbox and command:find("^/rdell") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local radius = tonumber(arg)
         local findedObjects = 0
         if type(radius) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Для радиусного удаления используйте /rdell <radius>", 0x0FF6600)
            return false
         end
         if radius > 0 and radius <= ini.settings.devmodelabeldist then
            --sampAddChatMessage("Список удаленных объектов:", -1)
            lua_thread.create(function()
               for id = 1024, 2048 do -- on Training started 1024 
                  if sampIs3dTextDefined(id) then
                     local text, color, posX, posY, posZ, streamdistance, ignoreWalls, playerId, vehicleId = sampGet3dTextInfoById(id)
                     if color == 4278223036 and text:find('id:') then--and streamdistance == 18 then
                        local localid = text:match('id:(%d+)')
                        local pX, pY, pZ = getCharCoordinates(playerPed)
                        local distance = getDistanceBetweenCoords3d(posX, posY, posZ, pX, pY, pZ)
                        if distance <= radius then
                           findedObjects = findedObjects + 1
                           sampSendChat("/odell "..localid)
                           wait(500)
                           --sampAddChatMessage(("delete id: %i, distance: %.1f m."):format(localid, distance), -1)
                        end
                     end
                  end
               end
               if findedObjects > 0 then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Всего удалено объектов: "..findedObjects..", в радиусе "..radius.." m.", 0x0FF6600)
               else
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найдены объекты в заданном радиусе (Возможно у вас в мире не включен режим разработки)", 0x0FF6600)
               end
             end)
          else
             sampAddChatMessage("[SCRIPT]: {FFFFFF}Неверное значение радиуса, введите от 0 до "..ini.settings.devmodelabeldist.." (/rdell <radius>)", 0x0FF6600)
             sampAddChatMessage("[SCRIPT]: {FFFFFF}Найти все объекты в заданном радиусе, можно командой /radius <m>", 0x0FF6600)
          end
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Для радиусного удаления используйте /rdell <radius>", 0x0FF6600)
      end
      return false
   end
   
   if isTrainingSanbox then
      if command:find("^/oc$") or command:find("^/copy$") then
         sampSendChat("/clone")
         edit.mode = 2
         return false
      end
      
      if command:find("^/oc%s") or command:find("^/copy%s") then
         if command:find('(/%a+) (.+)') then
            local cmd, arg = command:match('(/%a+) (.+)')
            local id = tonumber(arg)
            if type(id) == "number" then
               sampSendChat("/clone "..id)
               edit.mode = 2
            end
         end
         return false
      end
   end
   
   if isTrainingSanbox and command:find("^/clone") then
      if command:find('(/%a+) (.+)') then
         --local cmd, arg = command:match('(/%a+) (%d+)')
         --local id = tonumber(arg)
         LastData.lastModel = nil
         LastRemovedObject.modelid = nil
      end
   end
      
   if isTrainingSanbox and command:find("^/tblist") then
      sampSendChat("/tb")
      return false
   end
   
   if isTrainingSanbox and command:find("^/mn") then
      sampSendChat("/menu")
      return false
   end
   
   -- if isTrainingSanbox and command:find("^/accept") then
      -- if not command:find('(/%a+) (.+)') then
         -- if LastData.lastAccept then
            -- lua_thread.create(function()
               -- wait(1000)
               -- sampSendChat(tostring("/accept"..LastData.lastAccept))
            -- end)
         -- end
      -- end
   -- end
   
   if isTrainingSanbox and command:find("^/gotocar") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            sampSendChat("/tpveh "..id)
            if sampIsLocalPlayerSpawned() then
               lua_thread.create(function()
                  wait(1000)
                  local x, y, z = getCharCoordinates(playerPed)   
                  setCharCoordinates(playerPed, x, y, z+1.0)
               end)
            end
            return false
         end         
      else
         sampSendChat("/tpveh")
      end
      return false
   end
   
   if isTrainingSanbox and command:match("^/cb$") then
      if ini.settings.cbnewactivation then
         dialoghook.suspendcbactivation = false
      end
      if ini.settings.cbdefaultradius ~= 0 then
         lua_thread.create(function()
            wait(200)
            sampSetCurrentDialogEditboxText(ini.settings.cbdefaultradius)
         end)
      end
   end
   
   if isTrainingSanbox and command:match("^/cbedit") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            LastData.lastCb = id
            return true
         end         
      else
         if LastData.lastCb then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Последний комадный блок: "..tostring(LastData.lastCb), 0x0FF6600)
         end
      end
   end
   
   if isTrainingSanbox and command:find("^/olist") then
      dialoghook.olist = true
   end
   
   if isTrainingSanbox and command:find("^/omenu") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            LastObject.localid = id
            return true
         end         
      else
         if LastObject.localid then
            if command:find("^/omenu") then
               sampSendChat("/omenu "..LastObject.localid)
               return false
            end
         end
      end
   end
   
   if isTrainingSanbox and command:find("^/odell") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите корректный id!", 0x0FF6600)
            return false
         end
         if id == LastObject.localid then
            LastRemovedObject.modelid = LastObject.modelid
            LastRemovedObject.position.x = LastObject.position.x
            LastRemovedObject.position.y = LastObject.position.y
            LastRemovedObject.position.z = LastObject.position.z
            LastRemovedObject.rotation.x = LastObject.position.x
            LastRemovedObject.rotation.y = LastObject.position.y
            LastRemovedObject.rotation.z = LastObject.position.z
         --else
         --local result, positionX, positionY, positionZ = getObjectCoordinates()
         end
      end
      return true
   end
   
   if isTrainingSanbox and command:find("^/od$") then
      edit.mode = 3
   end
   
   if isTrainingSanbox and command:find("^/ao") then -- /ao to /oa
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            if isValidObjectModel(id) then
               LastRemovedObject.modelid = id
               LastData.lastModel = id            
               sampSendChat("/oa "..id)
               return false
            end
         end
      end
   end
   
   if isTrainingSanbox and command:find("^/oa") then -- /oadd
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            if isValidObjectModel(id) then 
               LastRemovedObject.modelid = id
               LastData.lastModel = id
               local result, errorString = checkBuggedObject(id)
               if result then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF}"..errorString, 0x0FF0000)
               end
            end
         end
      else
        lua_thread.create(function()
            wait(500)
            if LastObject.modelid then
               sampAddChatMessage("Последний использованный объект: {696969}"..LastObject.modelid, -1)
            end
            local closestObjectId = getClosestObjectId()
            if closestObjectId then
               sampAddChatMessage("Ближайший объект: {696969}"..getObjectModel(closestObjectId).." ("..tostring(sampObjectModelNames[getObjectModel(closestObjectId)])..") ", -1)
            end
            sampAddChatMessage(("Можете попробовать объект: {696969}%d {FFFFFF}(%s)"):format(getSafeObjectModel(), tostring(sampObjectModelNames[getSafeObjectModel()])), -1)
         end)
      end
   end
   
   if isTrainingSanbox and command:find("^/oswap") then
      if command:find('(/%a+) (.+) (.+)') then
         local cmd, localid, modelid = command:match('(/%a+) (.+) (.+)')
         local id = tonumber(localid)
         local model = tonumber(modelid)
         if type(id) == "number" and type(model) then
            if model and isValidObjectModel(model) then 
               -- LastRemovedObject.modelid = model
               -- LastData.lastModel = model
               local objectName = tostring(sampObjectModelNames[model])
               sampAddChatMessage(("[SCRIPT]: {FFFFFF}Модель объекта %d заменена на %d (%s)"):format(id, model, objectName), 0x0FF6600)
            end
         end
      end
   end
   
   if isTrainingSanbox and command:find("^/mtexture") then
      sampAddChatMessage("[SYNTAX]: {FFFFFF}/texture <object> <slot> <page*>", 0x09A9999)
      return false
   end
   
   if isTrainingSanbox and command:find("^/texture") then
      -- if command:find('(/%a+) (.+) (.+) (.+)') then
         -- local cmd, id, slot, page = command:match('(/%a+) (.+) (.+) (.+)')
         -- local id = tonumber(id)
         -- local page = tonumber(page)
      if command:find('(/%a+) (.+) (.+)') then
         local cmd, id, slot = command:match('(/%a+) (%d+) (%d+)')
         local id = tonumber(id)
         local slot = tonumber(slot)
         
         if type(id) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите корректный id!", 0x0FF6600)
            return false
         end
         
         if type(slot) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите корректный slot!", 0x0FF6600)
            return false
         end
         
         if ini.settings.cberrorwarnings and slot >= 16 then
            sampAddChatMessage("[WARNING]: {FFFFFF}Не указывайте индекс выше 15-го при ретекстуре", 0x0FF6600)
         end
         
         if not LastObject.localid then
            LastObject.localid = id
         end
         if not LastObject.txdslot then
            LastObject.txdslot = slot
         end
         edit.mode = 4
         if id ~= 0 then
            showRetextureKeysHelp()
         end
         dialoghook.textureslist = true
         
         if LastData.lastTextureListPage ~= 0 then
            return {command.." "..LastData.lastTextureListPage}
         end
      else
         if LastObject.txdid ~= nil then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Последняя использованная текстура: " .. LastObject.txdid, 0x0FF6600)
         end
      end
   end
      
   if isTrainingSanbox and command:find("^/stexture") then
      if command:find('(/%a+) (.+) (.+) (.+)') then
         local cmd, objectid, slot, texture = command:match('(/%a+) (.+) (.+) (.+)')
         if ini.settings.cberrorwarnings then
            if tonumber(slot) >= 16 then
               sampAddChatMessage("[WARNING]: {FFFFFF}Текстуры с индексои выше 15 могут вызывать глитчи", 0x0FF6600)
            end
         end
         
         if type(texture) == "string" then
            if texture:find("invis") then 
               local newcommand = string.gsub(command, texture, "8660")
               return {newcommand}
            end
         end
         if type(texture) == "string" then
            if texture:find("none") then 
               local newcommand = string.gsub(command, texture, "16")
               return {newcommand}
            end
         end
         if type(texture) == number then
            if tonumber(texture) < 0 or tonumber(texture) > 8704 then
               sampAddChatMessage("[ERROR]: {FFFFFF}Неверный номер текстуры", 0x0CC0000)
               return false
            end
         end
         
      end
   end
   
   if isTrainingSanbox and command:find("^/stextureall") then
      if command:find('(/%a+) (.+) (.+)') then
         local cmd, objectid, texture = command:match('(/%a+) (.+) (.+)')
         local objectid = tonumber(objectid)
         local texture = tonumber(texture)
         if type(objectid) == "number" and type(texture) == "number" then
            if tonumber(texture) < 0 or tonumber(texture) > 8704 then
               sampAddChatMessage("[ERROR]: {FFFFFF}Неверный номер текстуры", 0x0CC0000)
               return false
            end
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Ожидайте завершения ретекстура на все индексы..", 0x0FF6600)
            lua_thread.create(function()
               for index = 0, 15 do
                  wait(500)
                  sampSendChat("/stexture "..objectid.." "..index.." "..texture)
               end
               wait(500)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Ретекстур завершен. Сбросить текстуры можно через /untexture <objectid>", 0x0FF6600)
            end)
         else
            sampAddChatMessage("[SYNTAX]: {FFFFFF}/stextureall <objectid> <texture>", 0x09A9999)
         end
      else
         sampAddChatMessage("[SYNTAX]: {FFFFFF}/stextureall <objectid> <texture>", 0x09A9999)
      end
      return false
   end
   
   if command:find("^/tlist") or command:find("^/textures") then

      local counter = 0
      local totallines = 0
      local maxlines = 25
      
      local filepath = getGameDirectory()..
      "//moonloader//resource//mappingtoolkit//history//texture.txt"
      
      if not doesFileExist(filepath) then
         local file = io.open(filepath, "w")
         file:write("")
         file:close()
      end
      
      for line in io.lines(filepath) do
         totallines = totallines + 1
      end
      
      if totallines >= 1 then
         sampAddChatMessage("Использованные текстуры за сессию:", -1)
      end
      
      if totallines > maxlines then
         local limit = totallines - maxlines
         for line in io.lines(filepath) do
            counter = counter + 1
            if counter > limit then
               sampAddChatMessage(line, -1)
            end
         end
      else
         for line in io.lines(filepath) do
            counter = counter + 1
            sampAddChatMessage(line, -1)
         end
      end
      
      if counter == 0 then
         sampAddChatMessage("Список использованных за сеанс текстур - пуст", -1)
      end
      return false
   end
   
   if command:find("^/pmh") then
      if not ini.settings.savepmmessages then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Сохранение истории сообщений отключено в настройках!", 0x0FF6600)
         return false
      end
      local counter = 0
      local totallines = 0
      local maxlines = 15
      
      local filepath = getGameDirectory()..
      "//moonloader//resource//mappingtoolkit//history//pmmessages.txt"
      
      if not doesFileExist(filepath) then
         local file = io.open(filepath, "w")
         file:write("")
         file:close()
      end
      
      for line in io.lines(filepath) do
         totallines = totallines + 1
      end
      
      if totallines >= 1 then
         sampAddChatMessage("Лог персональных сообщений (PM):", -1)
      end
      
      if totallines > maxlines then
         local limit = totallines - maxlines
         for line in io.lines(filepath) do
            counter = counter + 1
            if counter > limit then
               sampAddChatMessage(line, 0x0FFFF00)
            end
         end
      else
         for line in io.lines(filepath) do
            counter = counter + 1
            sampAddChatMessage(line, 0x0FFFF00)
         end
      end
      
      if counter == 0 then
         sampAddChatMessage("Список сообщений - пуст", -1)
      end
      return false
   end
   
   if isTrainingSanbox and command:find("^/tcopy") then
      sampAddChatMessage("[SYNTAX]: {FFFFFF}Используйте /texture чтобы установить текстуру, а затем /tpaste <id> чтобы применить на выбранный объект", 0x09A9999)
      return false
   end
   
   if isTrainingSanbox and command:find("^/tpaste") then
      if not LastObject.txdid or not LastObject.txdslot then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Нет последней использованной текстуры. Сперва наложите текстуру через /texture", 0x0FF6600)
         return false
      end
      
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите корректный id!", 0x0FF6600)
            return false
         end
         sampSendChat("/stexture "..id.." "..LastObject.txdslot.." "..LastObject.txdid)
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите ID объекта на который наложить текстуру", 0x0FF6600)
      end
      return false
   end
   
   if command:find("^/undo") then
      if LastRemovedObject.modelid then
         if isTrainingSanbox then
            if LastRemovedObject.position.x ~= 0 then
               sampSendChat(("/oadd %i %.3f %.3f %.3f"):format(
               LastRemovedObject.modelid, LastRemovedObject.position.x, LastRemovedObject.position.y, LastRemovedObject.position.z))
               sampAddChatMessage(("[SCRIPT]: {FFFFFF}Восстановлен последний удаленный объект: %i на координатах: %.3f %.3f %.3f"):format(
               LastRemovedObject.modelid, LastRemovedObject.position.x, LastRemovedObject.position.y, LastRemovedObject.position.z), 0x0FF6600)
            else            
               sampSendChat("/oadd ".. LastRemovedObject.modelid)
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Восстановлен последний удаленный объект: "..LastRemovedObject.modelid, 0x0FF6600)
            end
         end
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найден последний удаленный объект", 0x0FF6600)
      end
      return false
   end
   
   if isTrainingSanbox and command:find("^/oedit") then
      edit.mode = 1
      return true
   end
   
   if isTrainingSanbox and command:find("^/spint") then
      if playerdata.isWorldHoster then
         sampSendChat("/int")
         return false
      end
   end
   
   if command:find("^/panel$") then
      checkbox.showpanel.v = not checkbox.showpanel.v
      if checkbox.showpanel.v then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы показали нижнюю панель", 0x0FF6600)
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы скрыли нижнюю панель", 0x0FF6600)
      end
      return false
   end
   
   if isTrainingSanbox and command:find("^/rot") then      
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local degreees = tonumber(arg)
         if type(degreees) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите корректое значение!", 0x0FF6600)
            sampAddChatMessage("[SYNTAX]: {FFFFFF}Используйте /rot <значение поворота>", 0x09A9999)
            return false
         end
         if LastObject.localid then
            sampSendChat("/rz "..LastObject.localid.." "..degreees)
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект "..LastObject.localid.." повернут на "..degreees.." градусов", 0x0FF6600)
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект не выбран!", 0x0FF6600)
         end
      else
         if LastObject.localid then
            sampSendChat("/rz "..LastObject.localid.." 90")
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект "..LastObject.localid.." повернут на 90 градусов", 0x0FF6600)
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект не выбран!", 0x0FF6600)
         end
      end
      return false
   end
   
   if isTrainingSanbox and command:find("^/healme") then
      sampSendChat("/health 100")
      if getCharHealth(playerPed) > 90.0 then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы вылечили себя", 0x0FF6600)
      end
      return false
   end
   
   if command:find("^/killme") then
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Если вы остались живы, отключите режим бога {696969}/gm ", 0x0FF6600)
      setCharHealth(playerPed, 0.0)
      return false
   end
   
   if command:find("^/delgun") then
      removeWeaponFromChar(playerPed, getCurrentCharWeapon(playerPed))
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Оружие которое вы держали в руках успешно удалено.", 0x0FF6600)
      return false
   end
   
   if command:find("^/delallgun") then
      for i = 1, 46 do
         removeWeaponFromChar(playerPed, i)
      end
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Все оружие убрано (только для вас)", 0x0FF6600)
      return false
   end
   
   if command:find("^/cindex") then
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
         --setMaterialObjectText(LastObject.id, 2, 0, 100, "Arial", 255, 0, 0xFFFFFF00, 0xFF00FF00, 1, "0"))
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Режим визуального просмотра индексов включен.", 0x0FF6600)
         sampAddChatMessage("{FFFFFF}Каждый индекс соответсвует цвету с таблицы:", 0x0FF6600)
         sampAddChatMessage("{FF0000}0 {008000}1 {0000FF}2 {FFFF00}3 {00FFFF}4 {FF4FF0}5 {dc143c}6 {808080}7 {FFFFFF}8 {800080}9 {006400}10", -1)
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Последний созданный объект не найден", 0x0FF6600)
      end
      return false
   end
   
   if command:find("^/rindex") then
      if isTrainingSanbox then
         sampSendChat("/untexture")
         return false
      end
      if LastObject.handle and doesObjectExist(LastObject.handle) then
         for index = 0, 15 do 
            setMaterialObject(LastObject.id, 1, index, LastObject.modelid, "none", "none", 0xFFFFFFFF)
         end
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Режим визуального просмотра индексов отключен", 0x000FF00)
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Последний созданный объект не найден", -1)
      end
      return false
   end
   
   if command:find("^/odist") then
      if checkbox.drawlinetomodelid.v then
         checkbox.drawlinetomodelid.v = false
      else
         if LastObject.modelid then 
            input.rendselectedmodelid.v = LastObject.modelid
            checkbox.drawlinetomodelid.v = true
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Последний созданный объект не найден", 0x0FF6600)
         end
      end
      return false
   end
   
   if command:find("^/collision") then
      playerdata.disableObjectCollision = not playerdata.disableObjectCollision
      checkbox.objectcollision.v = playerdata.disableObjectCollision
      if not playerdata.disableObjectCollision then 
         find_obj_x, find_obj_y, find_obj_z = getCharCoordinates(playerPed)
         result, objectHandle = findAllRandomObjectsInSphere(find_obj_x, find_obj_y, find_obj_z, 25, true)
         if result then
            for k, v in pairs(objectsCollisionDel) do
               if doesObjectExist(v) then 
                  setObjectCollision(v, true)
               end
            end
         end
      end
      sampAddChatMessage(playerdata.disableObjectCollision and "[SCRIPT]: {FFFFFF}Коллизия объектов: Отключена" or "[SCRIPT]: {FFFFFF}Коллизия объектов: Включена", 0x0FF6600)
      return false
   end 
   
   if command:find("^/oalpha") then
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
   
   if command:find("^/ocolor") and not isTrainingSanbox then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
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
   
   if command:find("^/ocolor") and isTrainingSanbox then
      if command:find('(/%a+) (.+) (.+) (.+)') then
         local cmd, object, slot, ocolor = command:match('(/%a+) (.+) (.+) (.+)')
         local object = tonumber(object)
         local slot = tonumber(slot)
         if type(slot) ~= "number" and type(object) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Некорректный формат!", 0x0FF6600)
         else
            if string.len(ocolor) ~= 8 or ocolor:find("0x") then
               sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите цвет в формате AARRGGBB", 0x0FF6600)
            else
               sampAddChatMessage("[SCRIPT]: {FFFFFF}На объект "..tostring(object).." слот "..tostring(slot).." установлен цвет "..ocolor, 0x0FF6600)
            end
         end
      end
   end
   
   -- if command:find("^/rx") or command:find("^/ry") or command:find("^/rz") then
      -- lua_thread.create(function()
         -- wait(500)
         -- if not input.error then
            -- if command:find('(/%a+) (.+) (.+)') then
               -- local cmd, id, arg = command:match('(/%a+) (.+) (.+)')
               -- local id = tonumber(id)
               -- local arg = tonumber(arg)
               -- if type(id) == "number" and type(arg) == "number" then
                  -- sampAddChatMessage("[SCRIPT]: {FFFFFF}Объект "..id.." повернут на "..arg.." градусов ( "..cmd.." )", 0x0FF6600)
               -- end
            -- end
         -- else
            -- input.error = false
         -- end
      -- end)
   -- end
   
   if command:find("^/tpo") then
      if playerdata.flymode then
         toggleFlyMode(false)
         --sampAddChatMessage("[SCRIPT]: {FFFFFF}Сперва выйдите из режима полета", 0x0FF6600)
         lua_thread.create(function()
            wait(500)
            toggleFlyMode(true)
         end)
      end
   end
   
   if command:find("^/ogoto") then
      if LastObject.handle and doesObjectExist(LastObject.handle) then
         if isTrainingSanbox then
            sampSendChat(string.format("/xyz %f %f %f",
            LastObject.position.x, LastObject.position.y, LastObject.position.z), 0x0FFFFFF)   
         else
            setCharCoordinates(playerPed, LastObject.position.x, LastObject.position.x, LastObject.position.z+0.2)
         end
         sampAddChatMessage("Вы телепортировались на координаты к послед.объекту "..LastObject.modelid, 0x000FF00)
      else
         if isTrainingSanbox then
            sampAddChatMessage("[SYNTAX]: {FFFFFF}Используйте /tpo <id>", 0x09A9999)
         else
            sampAddChatMessage("Последний созданный объект не найден", -1)
         end
      end
      return false
   end
   
   if command:find("^/searchveh") or command:find("^/findveh") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            if id > 400 and id < 611 then
               sampAddChatMessage("[SCRIPT]: {FFFFFF} По id "..id..
               " найден транспорт - "..VehicleNames[id-399], 0x0FF6600)
            else
               sampAddChatMessage("[ERROR]: {FFFFFF}Указан неверный ID транспорта", 0x0CC0000)
            end
         else
            for k, v in pairs(VehicleNames) do
               local model = string.lower(v)
               if model:find(arg) then
                  sampAddChatMessage("[SCRIPT]: {FFFFFF} Найдено совпадение ".. k+399 ..
                  " транспорт - "..VehicleNames[k], 0x0FF6600)
               end
            end
         end
      end
      return false
   end
   
   if command:find("^/cmdsearch") or command:find("^/findcmd") 
   or command:find("^/cmdfind") and isTrainingSanbox then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local searchcmd = tostring(arg)
         local results = 0
         local resultline = 0
         local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//cmdlist.txt"
         
         if string.len(searchcmd) > 0 then
            for line in io.lines(filepath) do
               resultline = resultline + 1
               if line:find(searchcmd, 1, true) then
                  results = results + 1
                  sampAddChatMessage(u8:decode(line), -1)
               end
            end
         end
         if not results then
            sampAddChatMessage("[ERROR]: {FFFFFF}Результат поиска: Не обнаружено. Просмотреть список доступных команд {696969}/cmdlist", 0x0CC0000)
         end  
      else
         sampAddChatMessage("[SYNTAX]: {FFFFFF}/findcmd <command>", 0x09A9999)
      end
      return false
   end
   
   if command:find("^/animsearch") or command:find("^/findanim") 
   and isTrainingSanbox then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local searchcmd = tostring(arg)
         local results = 0
         local resultline = 0
         local filepath = getGameDirectory().."//moonloader//resource//mappingtoolkit//anims.txt"
         
         if string.len(searchcmd) > 0 then
            for line in io.lines(filepath) do
               resultline = resultline + 1
               if line:find(searchcmd, 1, true) then
                  results = results + 1
                  sampAddChatMessage(u8:decode(line), -1)
               end
            end
         end
         if not results then
            sampAddChatMessage("[ERROR]: {FFFFFF}Результат поиска: Не обнаружено. Просмотреть список доступных команд {696969}/animlist", 0x0CC0000)
         end  
      else
         sampAddChatMessage("[SYNTAX]: {FFFFFF}/findanim <command>", 0x09A9999)
      end
      return false
   end
   
   if command:find("^/tsearch") and isTrainingSanbox then
      if LastObject.txdid ~= nil then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Последняя использованная текстура: " .. LastObject.txdid, 0x0FF6600)
      end
      if not command:find('(/%a+) (.+) (.+)') then
         sampAddChatMessage("[SYNTAX]: {FFFFFF}/tsearch <objectid> <slot> <name>", 0x09A9999)
         if command:find('(/%a+) (.+)') then
            local cmd, arg = command:match('(/%a+) (.+)')
            local searchtxd = tostring(arg)
            if string.len(searchtxd) < 2 then
               sampAddChatMessage("Минимальное кол-во символов для поиска текстуры = 2", -1)
               return false
            end
            local findedtxd = 0
            if searchtxd and searchtxd ~= nil then 
               for k, v in ipairs(sampTextureList) do
                  if v[3]:find(searchtxd) then
                     findedtxd = findedtxd + 1
                     sampAddChatMessage(string.format("{696969}%d. {FFFFFF}%s", k-1, v[3]), -1)
                     if findedtxd >= 20 then -- 20 is maxresults
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
         end
         return false
      else
         showRetextureKeysHelp()
         dialoghook.textureslist = true
      end
   end
   
   if command:find("^/cbsearch") and isTrainingSanbox then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
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
         if results == 0 then
            sampAddChatMessage("Результат поиска: Совпадений для "..tostring(arg).." не найдено", -1)
         end
         return false
      else 
         sampAddChatMessage("[SCRIPT]: Введите информацию для поиска", 0x0FF6600)
         sampAddChatMessage("[SYNTAX]: {FFFFFF}/cbsearch tick", 0x09A9999)
         return false
      end
   end
   
   if command:find("^/osearch") and not isTrainingSanbox then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
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
   
   if isTrainingSanbox and command:find("^/лс") then
      if command:find('(/%a+) (.+) (.+)') then
         local cmd, id, message = command:match('(/%a+) (.+) (.+)')
         if message then
            sampSendChat("/pm "..id.." "..message)
         end
      end
   end
   
   if command:find("^/last") then
      if isTrainingSanbox and LastObject.localid then
         sampAddChatMessage("Последний локальный ид объекта: {696969}"..LastObject.localid, -1)
      end
      if isTrainingSanbox and LastData.lastCb then
         sampAddChatMessage("Последний командный блок: {696969}"..LastData.lastCb, -1)
      end
      if isTrainingSanbox and LastData.lastActor then
         sampAddChatMessage("Последний актер: {696969}"..LastData.lastActor, -1)
      end
      if isTrainingSanbox and LastData.lastPass then
         sampAddChatMessage("Последний проход: {696969}"..LastData.lastPass, -1)
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
      
      if ini.settings.devmode and LastData.lastClickedTextdrawId then
         sampAddChatMessage("Последний нажатый текстдрав: {696969}"..LastData.lastClickedTextdrawId, -1)
      end
   
      return false
   end
   
   if command:find("^/restream") then
      if isCharInAnyCar(playerPed) then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно в транспорте", 0x0FF6600)
         return false
      end
      if not isCharOnFoot(playerPed) then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Недоступно. Попробуйте сперва заспавниться", 0x0FF6600)
         return false
      end
      Restream()
      return false
   end 
   
   if isTrainingSanbox and command:find("^/afkkick") then
      local counter = 0
      if next(playersTable) == nil then 
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Сперва обнови список игроков!", 0x0FF6600) 
         return false
      end
      
      if not playerdata.isWorldHoster then 
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы не находитесь в вирутальном в мире!", 0x0FF6600) 
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
         sampAddChatMessage("[SCRIPT]: {FFFFFF}АФКашники не найдены", 0x0FF6600)
      end
      
      return false
   end 
   
   if command:find("^/retcam") or command:find("^/restorecam") then
      if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
      if checkbox.fixcampos.v then checkbox.fixcampos.v = false end
      setCameraBehindPlayer()
      restoreCamera()  
      return false
   end 
   
   if command:find("^/fixcam") then
      checkbox.fixcampos.v = not checkbox.fixcampos.v
      local camX, camY, camZ = getActiveCameraCoordinates()
      if checkbox.fixcampos.v then
         fixcam.x = camX
         fixcam.y = camY           
         fixcam.z = camZ
         textbuffer.fixcamx.v = string.format("%.1f", fixcam.x)
         textbuffer.fixcamy.v = string.format("%.1f", fixcam.y)
         textbuffer.fixcamz.v = string.format("%.1f", fixcam.z)
      else 
         restoreCamera()
      end
      return false
   end
   
   if isTrainingSanbox and command:find("^/loadvw") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local id = tonumber(arg)
         if type(id) == "number" then
            LastData.lastLoadedWorldNumber = id
            dialoghook.loadworld = true
         end
      end
   end
   
   if isTrainingSanbox and command:find("^/loadworld") or command:find("^/worldload") then
      sampSendChat("/loadvw")
      return false
   end
   
   if isTrainingSanbox and command:find("^/saveworld") or command:find("^/worldsave") then
      dialoghook.saveworld = true
      dialoghook.saveworldname = true
      sampSendChat("/vw")
      return false
   end
   
   -- hook world name
   if isTrainingSanbox and command:find("^/savevw")then
      dialoghook.saveworldname = true
      if checkbox.worldsavereminder.v then
         threads.savereminder:terminate()
         threads.savereminder = nil
         SaveReminder()
      end
      -- count dyn objects at stream to prevent save empty world
      local dynobjectsCounter = 0 
      for _, v in pairs(getAllObjects()) do
         if isObjectOnScreen(v) then
            local objectid = sampGetObjectSampIdByHandle(v)
            if objectid ~= -1 then
               dynobjectsCounter = dynobjectsCounter + 1
            end
         end
      end
      if dynobjectsCounter == 0 then
         sampAddChatMessage("[WARNING]: {FFFFFF}Похоже мир пустой! не найдено объектов рядом, вы точно хотите его сохранить?", 0x0CC0000)
         printStyledString('~r~ WARNING ~w~Attempt to save an empty world ~r~', 7000, 4)         
      end
   end
   
   if isTrainingSanbox and command:find("^/spcar") then
      dialoghook.spcars = true
      sampSendChat("/vw")
      return false
   end
   
   if isTrainingSanbox and command:find("^/resetgun") then
      dialoghook.resetguns = true
      sampSendChat("/vw")
      return false
   end
   
   if isTrainingSanbox and command:find("^/resetveh") then
      dialoghook.resetvehs = true
      sampSendChat("/vw")
      return false
   end
   
   if isTrainingSanbox and command:find("^/vkickall$") then
      dialoghook.vkickall = true
      sampSendChat("/vw")
      return false
   end
   
   if isTrainingSanbox and command:find("^/cc$") then
      ClearChat()
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Чат был очищен!", 0x0FF6600)
      return false
   end
   
   if isTrainingSanbox and command:find("^/tpp") then
      if not command:find('(/%a+) (.+)') then
         if LastData.lastPass then
            sampSendChat("/tpp "..LastData.lastPass)
            return false
         end
      end
   end
   
   if command:find("^/picker") then
      if not dialog.main.v then
         dialog.main.v = true 
      end
      tabmenu.main = 3
      tabmenu.info = 3
      return false
   end
   
   if command:find("^/favlist") then
      if not dialog.main.v then
         dialog.main.v = true 
      end
      tabmenu.main = 3
      tabmenu.info = 5
      return false
   end
   
   if command:find("^/cmdlist") then
      if not dialog.main.v then
         dialog.main.v = true 
      end
      tabmenu.main = 3
      tabmenu.info = 6
      return false
   end
   
   if command:find("^/animlist") then
      dialoghook.animlist = true
   end
   
   if command:find("^/radius") then
      if command:find('(/%a+) (.+)') then
         local cmd, arg = command:match('(/%a+) (.+)')
         local radius = tonumber(arg)
         if type(radius) ~= "number" then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Введите корректный radius!", 0x0FF6600)
            return false
         end
         if radius then 
            local px, py, pz = getCharCoordinates(playerPed)
            Draw3DCircle(px, py, pz-1, radius, 0xFFD00000)
            for _, v in ipairs(getAllObjects()) do
               local _, x, y, z = getObjectCoordinates(v)
               local dist = getDistanceBetweenCoords3d(x, y, z, px, py, pz)
               if dist <= radius then
                  sampAddChatMessage("Объект id: "..v.." model: {696969}"..getObjectModel(v).."("..tostring(sampObjectModelNames[getObjectModel(v)]).."){FFFFFF} входит в радиус ("..radius..")", -1)
               end
            end
         else
            sampAddChatMessage("[SCRIPT]: {FFFFFF}укажите радиус (в метрах)!", 0x0FF6600)
         end
      else
         sampAddChatMessage("[SYNTAX]: {FFFFFF}Используйте /radius <радиус в метрах>!", 0x09A9999)
      end
      return false
   end
   
   if ini.settings.devmode and command:find("^/test") then   
      -- allowPauseInWidescreen(true)
      -- sampAddChatMessage("Test", -1)
      -- local rotationX, rotationY, rotationZ = 0.0
      -- local rotationX, rotationY, rotationZ = getObjectRotationVelocity(LastObject.handle)
      -- local posX, posY, posZ = getObjectCoordinates(LastObject.handle)
      
      -- sampAddChatMessage(string.format("%.2f, %.2f, %.2f", LastObject.rotation.x, LastObject.rotation.y, LastObject.rotation.z), -1)
      -- local movex = 360 - LastObject.rotation.x
      -- local movey = 360 - LastObject.rotation.y
      -- local movez = 360 - LastObject.rotation.z
      -- sampAddChatMessage(string.format("%.2f, %.2f, %.2f", movex, movey, movez), -1)
      -- lua_thread.create(function()
         -- wait(50)
         -- sampSendChat(string.format("/rx %.2f", movex))
         -- wait(50)
         -- sampSendChat(string.format("/ry %.2f", movey))
         -- wait(50)
         -- sampSendChat(string.format("/rz %.2f", movez))
      -- end)
      
      -- setObjectRotation(LastObject.handle, rotationX, rotationY, rotationZ)
      return false
   end
   
end

function sampev.onSendChat(message)
   -- Corrects erroneous sending of empty chat messages
   -- if message:match("^%s.*$") and message:len() <= 1 then
      -- return false
   -- end
   
   -- new version ignore erroneous recieving of empty chat messages
   local chatsymbol = message:find(":")
   local timestamp = message:match("%d%d:%d%d:%d%d")
   if chatsymbol then
      local chatmessage = message
      if timestamp then
         chatmessage = string.sub(message, 11+2, message:len()) --timestamp 11 symb + 2 spaces
      else
         chatmessage = string.sub(chatmessage, chatsymbol+1, chatmessage:len())
      end
      
      local hexcolor = chatmessage:find("{FFA500}.*")
      if isTrainingSanbox and hexcolor then
         chatmessage = string.sub(chatmessage, hexcolor+8, chatmessage:len())
      end
      
      if chatmessage:match("^%s.+$") then
         if not chatmessage:find("%w") then
            return false
         end
      end
   end
   
   if ini.settings.txtmacros then
      -- Text macros in TRAINING style format
      -- https://forum.training-server.com/d/10021-tekstovye-komandy-funktsii-kb
      local text = message
      local formatted = false
      local posX, posY, posZ = getCharCoordinates(playerPed)
      
      if message:match("#skin#") then
         formatted = true
         text = text:gsub("#skin#", tostring(getCharModel(playerPed)))
      end
      
      if message:match("#playerid#") then
         formatted = true
         text = text:gsub("#playerid#", tostring(getLocalPlayerId()))
      end
      
      if message:match("#nickname#") then
         formatted = true
         text = text:gsub("#nickname#", tostring(sampGetPlayerNickname(getLocalPlayerId())))
      end
      
      if message:match("#name#") then
         formatted = true
         text = text:gsub("#name#", tostring(sampGetPlayerNickname(getLocalPlayerId())))
      end
      
      if message:match("#x#") then
         formatted = true
         text = text:gsub("#x#", string.format("%.2f", posX))
      end
      
      if message:match("#y#") then
         formatted = true
         text = text:gsub("#y#", string.format("%.2f", posY))
      end
      
      if message:match("#z#") then
         formatted = true
         text = text:gsub("#z#", string.format("%.2f", posZ))
      end
      
      if message:match("#xyz#") then
         formatted = true
         text = text:gsub("#xyz#", string.format("%.2f %.2f %.2f", posX, posY, posZ))
      end
      
      if message:match("#fa#") then
         formatted = true
         local angle = math.ceil(getCharHeading(playerPed))
         text = text:gsub("#fa#", string.format("%.2f", angle))
      end
      
      if message:match("#speed#") then
         formatted = true
         if isCharInAnyCar(playerPed) then
            local vehicle = storeCarCharIsInNoSave(playerPed)
            local speed = getCarSpeed(vehicle)
            text = text:gsub("#speed#", tostring(speed))
         else
            local speed = getCharSpeed(playerPed)
            text = text:gsub("#speed#", string.format("%.1f", speed))
         end
      end
      
      if message:match("#gun#") then
         formatted = true
         text = text:gsub("#gun#", tostring(getCurrentCharWeapon(playerPed)))
      end
      
      if message:match("#health#") then
         formatted = true
         text = text:gsub("#health#", tostring(sampGetPlayerHealth(playerPed)))
      end
      
      if message:match("#armor#") then
         formatted = true
         text = text:gsub("#armor#", tostring(sampGetPlayerArmor(playerPed)))
      end
      
      if message:match("#ping#") then
         formatted = true
         text = text:gsub("#ping#", tostring(sampGetPlayerPing(playerPed)))
      end
      
      if message:match("#score#") then
         formatted = true
         text = text:gsub("#score#", tostring(sampGetPlayerScore(playerPed)))
      end
      
      if message:match("#time#") then
         formatted = true
         local hours, mins = getTimeOfDay()
         text = text:gsub("#time#", string.format("%d", hours))
      end
      
      if message:match("#weather#") then
         formatted = true
         text = text:gsub("#weather#", string.format("%d", LastData.lastWeather))
      end
      
      if message:match("#wanted#") then
         formatted = true
         local result, level = storeWantedLevel(playerPed)
         text = text:gsub("#wanted#", tostring(level))
      end
      
      if message:match("#vehicle#") then
         formatted = true
         if isCharInAnyCar(playerPed) then
            local carhandle = storeCarCharIsInNoSave(playerPed)
            local streamed, carId = sampGetVehicleIdByCarHandle(carhandle)
            text = text:gsub("#vehicle#", tostring(carId))
         end
      end
      
      if message:match("#vehModel#") then
         formatted = true
         if isCharInAnyCar(playerPed) then
            local carhandle = storeCarCharIsInNoSave(playerPed)
            text = text:gsub("#vehModel#", tostring(getCarModel(carhandle)))
         end
      end
      
      if message:match("#vehName#") then
         formatted = true
         if isCharInAnyCar(playerPed) then
            local carhandle = storeCarCharIsInNoSave(playerPed)
            text = text:gsub("#vehName#", 
            tostring(VehicleNames[getCarModel(carhandle)-399]))
         end
      end
      
      if message:match("#vehHealth#") then
         formatted = true
         if isCharInAnyCar(playerPed) then
            local carhandle = storeCarCharIsInNoSave(playerPed)
            text = text:gsub("#vehHealth#", tostring(getCarHealth(carhandle)))
         end
      end
      
      if message:match("#zone#") then
         formatted = true
         zone = getZoneName(posX, posY, posZ)
         text = text:gsub("#zone#", tostring(zone))
      end
      
      if message:match("#timestamp#") then
         formatted = true
         text = text:gsub("#timestamp#", tostring(os.time(os.date("!*t"))))
      end
      
      if message:match("#date#") then
         formatted = true
         text = text:gsub("#date#", tostring(os.date("%d.%m.%Y")))
      end
      
      if message:match("#hour#") then
         formatted = true
         text = text:gsub("#hour#", tostring(os.date("%H")))
      end
      
      if message:match("#min#") then
         formatted = true
         text = text:gsub("#min#", tostring(os.date("%M")))
      end
      
      if message:match("#sec#") then
         formatted = true
         text = text:gsub("#sec#", tostring(os.date("%S")))
      end
      
      if message:match("#online#") then
         formatted = true
         local tmpplayers = {}
         for i = 0, sampGetMaxPlayerId(false) do
            if sampIsPlayerConnected(i) then
               table.insert(tmpplayers, i)
            end
         end
         local online = tonumber(#tmpplayers)
         text = text:gsub("#online#", tostring(online))
      end
      
      if message:match("#randomPlayer#") then
         formatted = true
         local tmpplayers = {}
         for i = 0, sampGetMaxPlayerId(false) do
            if sampIsPlayerConnected(i) then
               table.insert(tmpplayers, i)
            end
         end
         local rand = math.random(tonumber(#tmpplayers))
         local player = tmpplayers[rand]
         text = text:gsub("#randomPlayer#", tostring(player))
      end
      
      if message:match("#random.(%d.*).#") then
         formatted = true
         local result = message:match("#random.(%d.*).#")
         local tmp = {}
         for token in string.gmatch(result, "[%d]+") do
            table.insert(tmp, token)
         end
         local randomnum = math.random(tmp[1], tmp[2])
         text = text:gsub("#random.(.*).#", tostring(randomnum))
      end
      
       if message:match("#gunName#") then
         formatted = true
         local weapon = getCurrentCharWeapon(playerPed)
         text = text:gsub("#gunName#", tostring(weaponNames[weapon]))
      end
      
      if message:match("#getGunName.(%d.*).#") then
         formatted = true
         local result = message:match("#getGunName.(%d.*).#")
         text = text:gsub("#getGunName.(%d.*).#", 
         tostring(weaponNames[tonumber(result)]))
      end
      
      if message:match("#getVehName.(%d.*).#") then
         formatted = true
         local result = message:match("#getVehName.(%d.*).#")
         local res, carhandle = sampGetCarHandleBySampVehicleId(tonumber(result))
         text = text:gsub("#getVehName.(%d.*).#", 
         tostring(VehicleNames[getCarModel(carhandle)-399]))
      end
      
      if message:match("#getPlayerName.(%d.*).#") then
         formatted = true
         local result = message:match("#getPlayerName.(%d.*).#")
         text = text:gsub("#getPlayerName.(%d.*).#", 
         tostring(sampGetPlayerNickname(result)))
      end
      
      if ini.settings.chatprefix > 0 then
         formatted = true
         text = chatPrefixList[combobox.chatprefix.v+1].." "..text
         if ini.settings.chatprefix >= 4 then
            sampSendChat(text)
            formatted = false
            return false
         end
      end
      
      if formatted then
         return {text}
      end
      formatted = false
      
   end
end

function sampev.onSetVehicleVelocity(turn, velocity)
   if ini.settings.cberrorwarnings then
      if velocity.x ~= velocity.x or velocity.y ~= velocity.y or velocity.z ~= velocity.z then
         sampAddChatMessage("[WARNING]: {FFFFFF}Ignoring invalid SetVehicleVelocity", 0x0FF6600)
         return false
      end
   end
end

function sampev.onApplyActorAnimation(actorId, lib, name)
   -- prevent bad animation crashes
   if name == "null" then
      return false
   end
end

function sampev.onApplyPlayerAnimation(playerId, animLib, animName, frameDelta, loop, lockX, lockY ,freeze, time)
   -- prevent bad animation crashes
   if name == "null" then
      return false
   end
   -- Fixes knocking down the jetpack by calling animation
   if isTrainingSanbox then   
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
   toggleFlyMode(false)
end

function sampev.onCreateObject(objectId, data)
   -- Prevent crash the game when creating a crane object 1382
   if data.modelId == 1382 then return false end
   
   if checkbox.nosnow.v then
      if data.modelId == 18664 or data.modelId == 18663 then 
         return false
      end
   end
   
   -- Hide objects from hiddenObjects list
   if hiddenObjects[1] ~= nil then
      for i = 1, #hiddenObjects do
         if data.modelId == hiddenObjects[i] then return false end
      end
   end
end

function sampev.onSetObjectMaterial(id, data)
   local objecthandle = sampGetObjectHandleBySampId(id)
   --local print(getObjectModel(objecthandle))
   if id == LastObject.id then 
      LastObject.txdlibname = data.libraryName
      LastObject.txdname = data.textureName
      LastObject.txdmodel = data.modelId
   end
   
   if checkbox.logtxd.v then
      print(id, data.materialId, data.modelId, data.libraryName, data.textureName, data.color)
   end
   
   -- get local texture id from txdtable
   local txdlocalid = -1
   for k, v in ipairs(sampTextureList) do
      local result = string.match(tostring(v[3]), tostring(data.textureName))
      if result then
         txdlocalid = k-1
         break
      end
   end
   
   if streamedTextures[#streamedTextures] then
      -- ignore /texture menu blocks (Texture Studio and TRAINING)
      if getObjectModel(objecthandle) ~= 2661 then 
         -- format color to readable format
         local hexcolor = string.format("%X", data.color)
         local hexcolor = string.sub(hexcolor, 9, string.len(hexcolor))
         local hexcolor = string.reverse(hexcolor)
         -- convert to ARGB format
         local RGB = string.sub(hexcolor, 0, string.len(hexcolor)-2)
         local Alpha = string.sub(hexcolor, string.len(hexcolor)-1, string.len(hexcolor))
         local hexcolor = string.format("%s%s", Alpha, RGB)
         
         if string.len(hexcolor) <= 1 then
            hexcolor = "none"
         end
         local newdata = string.format("%i,%i,%i,%s,%s,%s", 
         txdlocalid, data.materialId, data.modelId, data.textureName, data.libraryName, hexcolor)
         table.remove(streamedTextures, 1)
         table.insert(streamedTextures, #streamedTextures+1, newdata)
      end
   end

end

function sampev.onSetObjectMaterialText(id, data)
   	
   -- if streamedTexts[#streamedTexts] then
      -- local newdata = string.format("%i,%s,%i,%s,%s,%i,%i,%s,%s,%i", 
      -- id, data.text, data.materialId, data.materialSize, data.fontName, 
      -- data.fontSize, data.bold, data.fontColor, data.backGroundColor, data.align)
      -- table.remove(streamedTexts, 1)
      -- table.insert(streamedTexts, #streamedTexts+1, newdata)
   -- end
   
   if checkbox.hidematerialtext.v then
      return false
   end
end

function sampev.onSendEditObject(playerObject, objectId, response, position, rotation)
   -- response: 0 - exit edit, 1 - save, 2 - move
   -- bug: playerObject always return true state
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
   
   if LastRemovedObject.modelid == modelId then
      LastRemovedObject.position.x = position.x
      LastRemovedObject.position.y = position.y
      LastRemovedObject.position.z = position.z
   end
   
   -- Disable collision for edit object
   if ini.settings.editnocol then
      if response < 2 then
         setObjectCollision(object, true)
      else
         setObjectCollision(object, false)
      end
   end
   
   -- Auto open /omenu on save object 
   -- if isTrainingSanbox and response == 1 then
      -- if LastObject.localid then
         -- sampSendChat("/omenu "..LastObject.localid)
      -- end
   -- end
   
   -- Returns the object to its initial position when exiting editing
   -- TODO restore object angle too
   edit.response = response
   
   if ini.settings.restoreobjectpos and not playerdata.isPlayerEditAttachedObject then
      if isTrainingSanbox and response == 0 then
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
   -- if ini.settings.showobjectcoord then
      -- printStringNow(string.format("x:~b~~h~%0.2f, ~w~y:~r~~h~%0.2f, ~w~z:~g~~h~%0.2f~n~ ~w~rx:~b~~h~%0.2f, ~w~ry:~r~~h~%0.2f, ~w~rz:~g~~h~%0.2f",
      -- position.x, position.y, position.z, rotation.x, rotation.y, rotation.z), 1000)
   -- end
   
   if response ~= 2 then
      playerdata.isPlayerEditObject = true
   else
      playerdata.isPlayerEditObject = false
   end
end

function sampev.onSendEnterEditObject(type, objectId, model, position)
   LastObject.id = objectId
   LastObject.modelid = model
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
   
   LastData.lastModel = model
   
   if edit.mode == 3 then 
      LastRemovedObject.modelid = model
   end
      
   if not isTrainingSanbox then
      --checkBuggedObject(model)
      local result, errorString = checkBuggedObject(model)
      if result then
         sampAddChatMessage("[SCRIPT]: {FFFFFF}"..errorString, 0x0FF0000)
      end
   end
   
   if checkbox.logobjects.v then
      print(("SendEnterEditObject type:%i, id:%i, model:%i"):format(type, objectId, model))
   end
end

function sampev.onCancelEdit()
   edit.response = 0
end

function sampev.onSendPickedUpPickup(pickupId)
   if checkbox.pickupinfo.v then
      sampAddChatMessage(tostring("Вы подобрали pickup: "..pickupId), -1)
   end
end

function sampev.onCreatePickup(id, model, pickupType, position)
   if streamedPickups[#streamedPickups] then
      local newdata = string.format("%i,%i,%i,%.2f,%.2f,%.2f", 
      id, model, pickupType, position.x, position.y, position.z)
      table.remove(streamedPickups, 1)
      table.insert(streamedPickups, #streamedPickups+1, newdata)
   end
   
   if ini.settings.cberrorwarnings then
      if position.x > 4096 or position.x < -4094 then
         sampAddChatMessage(("[WARNING]: {FFFFFF}Pickup ID:%i не будет отображаться из-за неккоректной координаты по оси X!"):format(id), 0x0FF6600)
      end
      if position.y > 4096 or position.y < -4094 then
         sampAddChatMessage(("[WARNING]: {FFFFFF}Pickup ID:%i не будет отображаться из-за неккоректной координаты по оси Y!"):format(id), 0x0FF6600)
      end
   end
end

function sampev.onDisplayGameText(style, time, text)
   if checkbox.loggametexts.v then
      print(("Gametext: %s style: %i, time: %i ms"):format(text, style, time))
   end
end

function sampev.onCreate3DText(id, color, position, distance, testLOS,
attachedPlayerId, attachedVehicleId, text)
   if checkbox.log3dtexts.v then
      print(id, color, position.x, position.y, position.z, distance, testLOS,
      attachedPlayerId, attachedVehicleId, text)
   end
   
   if streamed3dTexts[#streamed3dTexts] then
      local clr
      if tonumber(color) ~= -1 then
         clr = string.format("%X", color)
         clr = string.sub(clr, 9, string.len(clr))
         local clr = string.reverse(clr)
         -- convert to ARGB format
         local RGB = string.sub(clr, 0, string.len(clr)-2)
         local Alpha = string.sub(clr, string.len(clr)-1, string.len(clr))
         clr = string.format("%s%s", Alpha, RGB)
      else
         clr = color
      end
      if string.len(clr) <= 1 then
         clr = "none"
      end
      
      local newtext = text
      local newtext = newtext:gsub(",", "  ")
      local newtext = newtext:gsub("'", " ")
      local newtext = newtext:gsub("%s%s%s", "")
      
      local newdata = string.format('%i,"%s",%s,%.2f,%.2f,%.2f', 
      id, newtext, clr, position.x, position.y, position.z)
      table.remove(streamed3dTexts, 1)
      if isTrainingSanbox then
         if not text:find("obj:") then -- ignore system 3d text
            table.insert(streamed3dTexts, #streamed3dTexts+1, newdata)
         end
      else
         table.insert(streamed3dTexts, #streamed3dTexts+1, newdata)
      end
   end
   -- Get local id from textdraw info
   if isTrainingSanbox then
      --if color == 8436991 or color == 16211740 then
      if text:find("obj:") then
         -- Bugged instruction, remove later
         -- LastObject.localid = text:match('id:(%d+)')
         if ini.settings.fixobjinfotext then
            return {id, 8436991, position, ini.settings.devmodelabeldist, testLOS, attachedPlayerId, attachedVehicleId, text}
         else
            return {id, color, position, ini.settings.devmodelabeldist, testLOS, attachedPlayerId, attachedVehicleId, text}
         end
      end
   end
   
   if checkbox.hide3dtexts.v then 
      return {id, color, position, 0.5, testLOS, attachedPlayerId, attachedVehicleId, text}
   else
      return {id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text}
   end
end

function sampev.onTogglePlayerSpectating(state)
   playerdata.isPlayerSpectating = state
end

function sampev.onTogglePlayerControllable(controllable)
   playerdata.isLockPlayerControl = controllable
end

function sampev.onSetCameraLookAt(lookAtPosition, cutType)
   if checkbox.logcamset.v then
      print(("Set camera look at: %.2f, %.2f, %.2f cutType: %i"):format(lookAtPosition.x, lookAtPosition.y, lookAtPosition.z, cutType))
   end
   if checkbox.lockcamchange.v then
      return false
   end
end

function sampev.onSetCameraPosition(position)
   if checkbox.logcamset.v then
      print(("Set camera pos: %.2f, %.2f, %.2f"):format(position.x, position.y, position.z))
   end
   if checkbox.lockcamchange.v then
      return false
   end
end

function sampev.onSetCameraBehind()
   if checkbox.logcamset.v then
      print("Server set camera behind player")
   end
   if checkbox.lockcamchange.v then
      return false
   end
end

function sampev.onInterpolateCamera(setPos, fromPos, destPos, time, mode)
   if checkbox.logcamset.v then
      print(("InterpolateCamera from: %.2f, %.2f, %.2f dest: %.2f, %.2f, %.2f time:%i mode:%i"
      ):format(fromPos.x, fromPos.y, fromPos.z, destPos.x, destPos.y, destPos.z, time, mode))
   end
   if checkbox.lockcamchange.v then
      return false
   end
end

function sampev.onSendClickPlayer(playerId, source)
   -- if scoreboard.lua installed  - this code do nothing
   chosen.tabselectedplayer = playerId
   if checkbox.tabclickcopy.v then
      local nickname = sampGetPlayerNickname(playerId)
      local buffer = string.format("%s[%d]", nickname, playerId)
      setClipboardText(buffer)
      sampAddChatMessage("Ник {696969}"..nickname.." {FFFFFF}кликнутого в TAB игрока {696969}".. playerId.."{FFFFFF} скопирован в буффер", -1)
   end
   if ini.settings.tabclickstat then
      lua_thread.create(function()
         wait(250)
         sampSendChat("/stats "..playerId)
      end)
   end
end

function sampev.onShowTextDraw(id, data)
   -- Additional Information: global textdraws use IDs 0-2047 and per-player use IDs 2048-2303.
   lastShowedTextdrawId = id
  
   if checkbox.logtextdraws.v then
      local posX, posY = sampTextdrawGetPos(id)
      print(("Show Textdraw ID: %s, at position x : %.2f, y: %.2f text:"):format(id, posX, posY))
      print(data.text)
   end
   
   if checkbox.txdparamsonshow.v then
      local posX, posY = sampTextdrawGetPos(id)
      local align = sampTextdrawGetAlign(id)
      local prop = sampTextdrawGetProportional(id)
      local style = sampTextdrawGetStyle(id)
      local shadow, shadowColor = sampTextdrawGetShadowColor(id)
      local outline, outlineColor = sampTextdrawGetOutlineColor(id)
      local model, rotX, rotY, rotZ, zoom, clr1, clr2 = sampTextdrawGetModelRotationZoomVehColor(id)
      local letSizeX, letSizeY, letColor = sampTextdrawGetLetterSizeAndColor(id)
      local box, boxColor, boxSizeX, boxSizeY = sampTextdrawGetBoxEnabledColorAndSize(id)
      sampAddChatMessage(("show textdraw ID: %i, at position x: %.2f, y: %.2f"):format(id, posX, posY), -1)
      sampAddChatMessage(("proportional: %i style: %i align: %i"):format(prop, style, align), -1)
      sampAddChatMessage(("shadow: %i color: %i"):format(shadow, shadowColor), -1)
      sampAddChatMessage(("outline: %i color: %i"):format(outline, outlineColor), -1)
      sampAddChatMessage(("letSizeX: %f letSizeY: %f color: %i"):format(letSizeX, letSizeY, letColor), -1)
      sampAddChatMessage(("box: %i, color %i, boxSizeX: %f boxSizeY: %f"):format(box, boxColor, boxSizeX, boxSizeY), -1)
      sampAddChatMessage(("model: %i, rotX: %f, rotY: %f, rotZ: %f, zoom: %f, clr1: %i, clr2: %X"):format(model, rotX, rotY, rotZ, zoom, clr1, clr2), -1)
      if data.text then
         sampAddChatMessage("text: "..data.text, -1)
      end
      sampAddChatMessage("                 ", -1)
   end
   
   if isTrainingSanbox then
      if id == 2070 then
         dialoghook.previewdialog = true
      end
   end
   
   if isTrainingSanbox and ini.settings.skipvehnotify then
      if id == 2125 then
         return false
      end
   end
   
   if checkbox.hidealltextdraws.v then
      return false
   end
end

function sampev.onTextDrawSetString(id, text)
   if isTrainingSanbox then
      if id == 2055 then
         LastData.lastTextureListIndex = text:match('Index: (%d+)')
         LastData.lastTextureListPage = text:match('Page: (%d+)')
      end
      
      -- write world logs
      -- if id >= 2058 or id <= 2069 then
      if ini.settings.worldsavelogs then
         if id == 2069 then
            local file = io.open(getGameDirectory()..
            "/moonloader/resource/mappingtoolkit/history/worldlogs.txt", "a")
            file:write(("[%s] %s \n"):format(tostring(os.date("%d.%m.%Y %X")), text))
            file:close()
         end
      end
   end
   
end

function sampev.onSetMapIcon(iconId, position, type, color, style)
   local MAX_SAMP_MARKERS = 63
   if type > MAX_SAMP_MARKERS then
      if ini.settings.cberrorwarnings then
         sampAddChatMessage(("[WARNING]: {FFFFFF}Mapicon %i указан несуществующий тип иконки, возможен краш клиента"):format(iconId), 0x0FF6600)
      end
      return false
   end
   -- 1,2,4,56 map icons cause crashes
   if (type == 1 or type == 2 or type == 4 or type == 56) then
      if ini.settings.cberrorwarnings then
         sampAddChatMessage(("[WARNING]: {FFFFFF}Mapicon %i указан багнутый тип иконки %i, возможен краш клиента"):format(iconId, type), 0x0FF6600)
      end
      return {iconId, position, 57, color, style}
   end
end

function sampev.onSendClickTextDraw(textdrawId)
   LastData.lastClickedTextdrawId = textdrawId
   if checkbox.logtextdraws.v then
      local posX, posY = sampTextdrawGetPos(textdrawId)
      print(("Click Textdraw ID: %s, Model: %s, x : %.2f, y: %.2f"):format(textdrawId, sampTextdrawGetModelRotationZoomVehColor(textdrawId), posX, posY))
      if textdrawId == 65535 then
         print("Close Textdraws")
         sampAddChatMessage("Close Textdraws", -1)
      else
         print(("Click Textdraw ID: %s, Model: %s, x : %.2f, y: %.2f"):format(textdrawId, sampTextdrawGetModelRotationZoomVehColor(textdrawId), posX, posY))
         sampAddChatMessage("Click Textdraw ID: "..textdrawId, -1)
      end
   end
   
   if checkbox.txdparamsonclick.v then
      local id = textdrawId
      local posX, posY = sampTextdrawGetPos(id)
      local align = sampTextdrawGetAlign(id)
      local prop = sampTextdrawGetProportional(id)
      local style = sampTextdrawGetStyle(id)
      local shadow, shadowColor = sampTextdrawGetShadowColor(id)
      local outline, outlineColor = sampTextdrawGetOutlineColor(id)
      local model, rotX, rotY, rotZ, zoom, clr1, clr2 = sampTextdrawGetModelRotationZoomVehColor(id)
      local letSizeX, letSizeY, letColor = sampTextdrawGetLetterSizeAndColor(id)
      local box, boxColor, boxSizeX, boxSizeY = sampTextdrawGetBoxEnabledColorAndSize(id)
      local text = sampTextdrawGetString(id)
      sampAddChatMessage(("click textdraw ID: %i, at position x: %.2f, y: %.2f"):format(id, posX, posY), -1)
      sampAddChatMessage(("proportional: %i style: %i align: %i"):format(prop, style, align), -1)
      sampAddChatMessage(("shadow: %i color: %i"):format(shadow, shadowColor), -1)
      sampAddChatMessage(("outline: %i color: %i"):format(outline, outlineColor), -1)
      sampAddChatMessage(("letSizeX: %f letSizeY: %f color: %i"):format(letSizeX, letSizeY, letColor), -1)
      sampAddChatMessage(("box: %i, color %i, boxSizeX: %f boxSizeY: %f"):format(box, boxColor, boxSizeX, boxSizeY), -1)
      sampAddChatMessage(("model: %i, rotX: %f, rotY: %f, rotZ: %f, zoom: %f, clr1: %i, clr2: %X"):format(model, rotX, rotY, rotZ, zoom, clr1, clr2), -1)
      if text then
         sampAddChatMessage("text: "..text, -1)
      end
      sampAddChatMessage("                 ", -1)
   end
   -- onTextdraw closed
   if textdrawId == 65535 then
      dialoghook.olist = false
      dialoghook.previewdialog = false
   end
   
   if dialoghook.olist then
      if textdrawId >= 2071 and textdrawId <= 2091 then
         local id = sampTextdrawGetString(textdrawId+26)
         if id and string.len(id) >= 1 then
            LastObject.localid = id
         end
      end
   end

   -- if textdrawId >= 2053 and textdrawId <= 2099 then
      -- local model, rotX, rotY, rotZ, zoom, clr1, clr2 = sampTextdrawGetModelRotationZoomVehColor(textdrawId)
      -- sampTextdrawSetModelRotationZoomVehColor(textdrawId, model, rotX, rotY, rotZ+90.0, zoom, clr1, clr2)
   -- end   
end

function sampev.onSendPickedUpPickup(id)
   if checkbox.pickeduppickups.v then
      print('Pickup: ' .. id)
      sampAddChatMessage("You have picked up: "..id, -1)
   end
end

-- bugged and don't hook anything 
-- fixed: changed by RPC, var playerdata.isPlayerEditAttachedObject
-- function onSendEditAttachedObject(response, index, model, bone, position, rotation, scale, color1, color2)
-- function onEditAttachedObject(index)

function sampev.onSetPlayerAttachedObject(playerId, index, create, object)  
   
   if checkbox.hooksetattachedobject.v then
      if create then
         sampAddChatMessage(string.format("slot: %d object: %d bone: %d", 
         index, object.modelId, object.bone), -1)
      end
   end
   
   if checkbox.hideattaches.v and playerId ~= getLocalPlayerId() then
      return false
   end
end

function sampev.onInitGame(playerId, hostName, settings, vehicleModels)
   ini.tmp.worldhoster = false
   inicfg.save(ini, configIni)
   if hostName:find("TRAINING") then
      dialoghook.backtoworld = true
   end
end

function sampev.onSendRequestSpawn()
   -- clear streamed data tables
   streamedTextures = {}
   streamedPickups = {}
   streamed3dTexts = {}
   streamedTexts = {}
   for i = 1, ini.settings.maxtableitems do
      table.insert(streamedTextures, "")
      table.insert(streamedPickups, "")
      table.insert(streamed3dTexts, "")
      table.insert(streamedTexts, "")
   end
end

function sampev.onSendSpawn()
   
   if isCharInAnyCar(playerPed) then
      if ini.settings.cberrorwarnings then
         sampAddChatMessage("[WARNING]: {FFFFFF}Попытка спавна игрока в машине!", 0x0FF6600)
      end
   end
   
   if playerdata.firstSpawn and ini.settings.allchatoff then
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Глобальный чат отключен!", 0x0FF6600)
   end
   if playerdata.firstSpawn and isTrainingSanbox then 
      playerdata.firstSpawn = false
      if sampIsLocalPlayerSpawned() then 
         if ini.settings.saveskin and isValidSkin(ini.settings.skinid) then
            sampSendChat("/skin "..ini.settings.skinid)
         end
      end
   end
   
   if ini.settings.backtoworld and dialoghook.backtoworld then
      local delta = tonumber(os.time()) - tonumber(ini.tmp.disconnecttime)
      if delta < 300 then
         lua_thread.create(function()
            wait(1000)
            sampSendChat("/world")
         end)
      end
   end
   
   local pid = getLocalPlayerId()
   if isTrainingSanbox and pid == 0 then
      sampAddChatMessage("[SCRIPT]: {FFFFFF}У вас багнутый ID перезайдите на сервер!", 0x0FF6600)
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Если не перезайти вас будут кикать с большинства миров!", 0x0FF6600)
   end
   
   toggleFlyMode(false)
end

-- FlyMode
function toggleFlyMode(mode)
   if isCharInAnyCar(playerPed) then
      return false
   end
   
   if mode == nil then
      playerdata.flymode = not playerdata.flymode
      mode = playerdata.flymode
   end
   flyCoords = {getCharCoordinates(playerPed)} 
   --flymode = not flymode
   --printStringNow(flymode and '~w~FlyMode: ~g~Activated' or '~w~FlyMode: ~r~Disabled', 3000)
   if mode then 
      hidePED(true)
      playerdata.flymode=true
      freezeCharPosition(playerPed, true)
      setCharCollision(playerPed, false)
      -- hide player attaches
      for i, objid in pairs(getAllObjects()) do
         pX, pY, pZ = getCharCoordinates(playerPed)
         _, objX, objY, objZ = getObjectCoordinates(objid)
         local ddist = getDistanceBetweenCoords3d(pX, pY, pZ, objX, objY, objZ)
         if ddist < 1 and playerAtachedObjects[objid] ~= false then
            setObjectVisible(objid, false)
            playerAtachedObjects[objid] = false
         end
      end
      return true
   else
      hidePED(false)
      playerdata.flymode=false
      freezeCharPosition(playerPed, false)
      setCharCollision(playerPed, true)
      -- show player attaches
      for i, objid in pairs(getAllObjects()) do
         if playerAtachedObjects[objid] == false then
            pX, pY, pZ = getCharCoordinates(playerPed)
            _, objX, objY, objZ = getObjectCoordinates(objid)
            local ddist = getDistanceBetweenCoords3d(pX, pY, pZ, objX, objY, objZ)
            if playerAtachedObjects[objid] == false then
               setObjectVisible(objid, true)
               playerAtachedObjects[objid] = true
            end
         end
      end
      return false
   end
end

function sampev.onSendPlayerSync(data)
   local speed_player_sync = 1.8
   if not playerdata.flymode then return end
   local sync = getMoveSpeed(getCharHeading(playerPed), speed_player_sync)
   data.moveSpeed = {sync.x, sync.y, data.moveSpeed.z}
   return data
end

function onScriptTerminate(script, quit)
   local thisscript = thisScript()
   local scriptname = thisscript.name

   if script.name == scriptname then
      -- Save last exit datetime
      ini.tmp.disconnecttime = os.time()
      inicfg.save(ini, configIni)
      
      toggleFlyMode(false)
      if isTrainingSanbox then
         sampTextdrawDelete(const.txdmodelinfoid)
      end
   end
end

function onWindowMessage(msg, wparam, lparam)
   if ini.settings.noaltenter then
      if msg == 261 and wparam == 13 then 
         consumeWindowMessage(true, true)
      end
   end
end

function onReceiveRpc(id, bs)
   -- NOP's
   if nops.selecttextdraw.v and id == 83 then return false end
   if nops.health.v and id == 14 then return false end
   if nops.position.v and id == 12 then return false end
   if nops.givegun.v and id == 22 then return false end
   if nops.resetgun.v and id == 21 then return false end
   if nops.setgun.v and id == 67 then return false end
   if nops.spectator.v and id == 124 then return false end
   if nops.requestclass.v and id == 128 then return false end
   if nops.requestspawn.v and id == 129 then return false end
   if nops.applyanimation.v and id == 86 then return false end
   if nops.clearanimation.v and id == 87 then return false end
   if nops.showdialog.v and id == 61 then return false end
   if nops.forceclass.v and id == 74 then return false end
   if nops.facingangle.v and id == 19 then return false end
   if nops.togglecontrol.v and id == 15 then return false end
   if nops.audiostream.v and id == 41 then return false end
   if nops.setskin.v and id == 153 then return false end
   if nops.setdrunk.v and id == 35 then return false end
   if nops.setspecialaction.v and id == 88 then return false end
   if nops.setplayerattachedobject.v and id == 113 then return false end
   if checkbox.hideattaches.v and id == 75 then return false end
   
   if id == 116 then -- onEditAttachedObject
      playerdata.isPlayerEditAttachedObject = true
   end
   if id == 88 and playerdata.flymode then -- onSetPlayerSpecialAction
      return false
   end
   
end

function onSendRpc(id, bs, priority, reliability, channel, shiftTimestamp)
   -- NOP's
   if nops.requestclass.v and id == 128 then return false end
   if nops.requestspawn.v and id == 129 then return false end
   if nops.spawn.v and id == 52 then return false end
   if nops.death.v and id == 55 then return false end
   if nops.clicktextdraw.v and id == 83 then return false end
   --Fix ClickMap height detection when setting a placemark on the game map
   if id == 119 then
      local posX, posY, posZ = raknetBitStreamReadFloat(bs), raknetBitStreamReadFloat(bs), raknetBitStreamReadFloat(bs)
      requestCollision(posX, posY)
      loadScene(posX, posY, posZ)
      local res, x, y, z = getTargetBlipCoordinates()
      if res then
        local new_bs = raknetNewBitStream()
        raknetBitStreamWriteFloat(new_bs, x)
        raknetBitStreamWriteFloat(new_bs, y)
        raknetBitStreamWriteFloat(new_bs, z + 0.5)
        raknetSendRpcEx(119, new_bs, priority, reliability, channel, shiftTimestamp)
        raknetDeleteBitStream(new_bs)
      end
      return false
   end

   if id == 116 then -- EditAttachedObject 
      playerdata.isPlayerEditAttachedObject = false
   end

   if ini.settings.cberrorwarnings then
      -- Thanks Heroku for this function on !SAPatcher
      if id == 153 then
         local playerId = raknetBitStreamReadInt32(bs)
         local modelId = raknetBitStreamReadInt32(bs)
         
         -- Fixes a SAMP crash related to the installation of an invalid player skin model.
         -- works only on the R1 version of the client, Kalcor has already built this fix into R3.
         if modelId < 0 or modelId == 65535 then
            sampAddChatMessage("[WARNING]: The server is trying to set invalid skin model (model: "
            .. modelId .. ")", 0x0FF6600)
            return false
         end
         
         -- Fixes the crash of SA-MP (0x006E3D17) associated with the installation of the skin in the car.	  
         local result, myId = sampGetPlayerIdByCharHandle(playerPed)
         if result then
            if playerId == myId then
               if isCharInAnyCar(playerPed) then
                  sampAddChatMessage("[WARNING]: The server is trying to set the skin in the car.", 0x0FF6600)
                  return false
               end
            end
         end
      end
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

function getLocalPlayerId()
   local result, id = sampGetPlayerIdByCharHandle(playerPed)
   if result then
      return id
   end
end

-- function ltrim(s)
   -- return s:match'^%s*(.*)'
-- end

-- function trim(s)
   -- return (s:gsub("^%s*(.-)%s*$", "%1"))
-- end

function hotkeyActionInit()
   if ini.hotkeyactions.keyJ ~= nil and string.len(ini.hotkeyactions.keyJ) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyJ)) then
            combobox.hotkeyJaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyI ~= nil and string.len(ini.hotkeyactions.keyI) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyI)) then
            combobox.hotkeyIaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyK ~= nil and string.len(ini.hotkeyactions.keyK) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyK)) then
            combobox.hotkeyKaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyL ~= nil and string.len(ini.hotkeyactions.keyL) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyL)) then
            combobox.hotkeyLaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyN ~= nil and string.len(ini.hotkeyactions.keyN) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyN)) then
            combobox.hotkeyNaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyB ~= nil and string.len(ini.hotkeyactions.keyB) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyB)) then
            combobox.hotkeyBaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyR ~= nil and string.len(ini.hotkeyactions.keyR) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyR)) then
            combobox.hotkeyRaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyZ ~= nil and string.len(ini.hotkeyactions.keyZ) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyZ)) then
            combobox.hotkeyZaction.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyU ~= nil and string.len(ini.hotkeyactions.keyU) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyU)) then
            combobox.hotkeyUaction.v = index-1
         end
      end
   end
   
   -- F keys
   
   if ini.hotkeyactions.keyF2 ~= nil and string.len(ini.hotkeyactions.keyF2) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF2)) then
            combobox.hotkeyF2action.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyF3 ~= nil and string.len(ini.hotkeyactions.keyF3) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF3)) then
            combobox.hotkeyF3action.v = index-1
         end
      end
   end
   
   if ini.hotkeyactions.keyF4 ~= nil and string.len(ini.hotkeyactions.keyF4) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF4)) then
            combobox.hotkeyF4action.v = index-1
         end
      end
   end

   if ini.hotkeyactions.keyF5 ~= nil and string.len(ini.hotkeyactions.keyF5) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF5)) then
            combobox.hotkeyF5action.v = index-1
         end
      end
   end

   if ini.hotkeyactions.keyF7 ~= nil and string.len(ini.hotkeyactions.keyF7) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF7)) then
            combobox.hotkeyF7action.v = index-1
         end
      end
   end   

   if ini.hotkeyactions.keyF9 ~= nil and string.len(ini.hotkeyactions.keyF9) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF9)) then
            combobox.hotkeyF9action.v = index-1
         end
      end
   end

   if ini.hotkeyactions.keyF10 ~= nil and string.len(ini.hotkeyactions.keyF10) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF10)) then
            combobox.hotkeyF10action.v = index-1
         end
      end
   end

   if ini.hotkeyactions.keyF11 ~= nil and string.len(ini.hotkeyactions.keyF11) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF11)) then
            combobox.hotkeyF11action.v = index-1
         end
      end
   end   

   if ini.hotkeyactions.keyF12 ~= nil and string.len(ini.hotkeyactions.keyF12) > 1 then
      for index, value in pairs(hotkeysActivationCmds) do
         if value:find(tostring(ini.hotkeyactions.keyF12)) then
            combobox.hotkeyF12action.v = index-1
         end
      end
   end
   
end

function checkBuggedObject(model)
   local bugged = false
   local errorString = nil
   
   if model == 3586 or model == 3743 then
      bugged = true
      errorString = "Багнутый объект "..model.." пропадет только после релога (баг SAMP)"
   end
   if model == 8979 or model == 8980 then
      bugged = true 
      errorString = "Багнутый объект "..model.." пропадет только после релога (баг SAMP)"
   end
   if model == 1269 or model == 1270 then 
      bugged = true
      errorString = "Из багнутого объекта "..model.." визуально выпадают деньги как в оригинальной игре (баг SAMP)"
   end
   if model == 16637 then
      bugged = true
      errorString = "Создание/удаление багнутого объекта "..model.." может привести к крашу 0x0044A503 (баг SAMP)"
   end
   if model == 3426 then
      bugged = true
      errorString = "Багнутый объект "..model.." неккоректно отображается под поверхностью, в воде, либо при повороте (баг SAMP)"
   end
   if model == 11694 or model == 11695 or model == 11696 then
      bugged = true
      errorString = "Багнутый объект "..model.." может вызывать аномалии при множественном использовании (баг Streamer)"
   end

   return bugged, errorString
end

function direction()
   if sampIsLocalPlayerSpawned() then
      local angle = math.ceil(getCharHeading(playerPed))
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
      local posX, posY, posZ = getCharCoordinates(playerPed)
      local angle = math.ceil(getCharHeading(playerPed))
      local dist = 2.0
      if angle then
         if (angle >= 0 and angle <= 30 or (angle <= 360 and angle >= 330)) then
            setCharCoordinates(playerPed, posX, posY+dist, posZ)
         elseif (angle > 80 and angle < 100) then
            setCharCoordinates(playerPed, posX-dist, posY+dist, posZ)
         elseif (angle > 260 and angle < 280) then
            setCharCoordinates(playerPed, posX+dist, posY, posZ)
         elseif (angle >= 170 and angle <= 190) then
            setCharCoordinates(playerPed, posX-dist, posY-dist, posZ)
         elseif (angle >= 31 and angle <= 79) then
            setCharCoordinates(playerPed, posX, posY-dist, posZ) 
         elseif (angle >= 191 and angle <= 259) then
            setCharCoordinates(playerPed, posX+dist, posY-dist, posZ)
         elseif (angle >= 81 and angle <= 169) then
            setCharCoordinates(playerPed, posX-dist, posY, posZ)
         elseif (angle >= 259 and angle <= 329) then
            setCharCoordinates(playerPed, posX+dist, posY+dist, posZ)
         end
      end
   end
end

function getClosestObjectId()
   local closestId = nil
   mydist = 20
   local px, py, pz = getCharCoordinates(playerPed)
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
   local x, y, z = getCharCoordinates(playerPed)
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
   local x, y, z = getCharCoordinates(playerPed)
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
   local A = { getCharCoordinates(playerPed) }
   local B = { getClosestStraightRoad(A[1], A[2], A[3], 0, radius or 600) }
   if B[1] ~= 0 and B[2] ~= 0 and B[3] ~= 0 then
       return true, B[1], B[2], B[3]
   end
   return false
end

function getCorrectAngle(angle)
   return 360/8 * math.floor(angle/45)
end

function setCameraDistanceActivated(activated)
   memory.setuint8(0xB6F028 + 0x38, activated)
   memory.setuint8(0xB6F028 + 0x39, activated)
end

function setCameraDistance(distance) 
   memory.setfloat(0xB6F028 + 0xD4, distance)
   memory.setfloat(0xB6F028 + 0xD8, distance)
   memory.setfloat(0xB6F028 + 0xC0, distance)
   memory.setfloat(0xB6F028 + 0xC4, distance)
end

function DisableUnderWaterEffects(bState) 
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
            if getCharModel(playerPed) ~= ini.settings.skinid then 
               sampSendChat("/skin "..ini.settings.skinid)
            end
         end
      end
   end)
end

function timelap(delay)
   threads.timelap = lua_thread.create(function()
      while true do
         if slider.time.v <= 23 then
            slider.time.v = slider.time.v + 1
         else
            slider.time.v = 0
         end
         wait(1000*delay)
         ini.settings.time = slider.time.v
         setTime(slider.time.v)
      end
   end)
end

function SaveReminder()
   threads.savereminder = lua_thread.create(function()
      while checkbox.worldsavereminder.v do
         local delay = tonumber(ini.settings.reminderdelay)
         wait(1000*60*delay)
         if playerdata.isWorldHoster then
            sampAddChatMessage("[SCRIPT]: {FFFFFF}Вы давно не сохраняли мир. Сохраните его во избежание потери прогресса. ( /savevw )", 0x0FF6600)
         end
      end
   end)
end

function WorldJoinInit()
   playerdata.isWorldHoster = true
   ini.tmp.worldhoster = true
   inicfg.save(ini, configIni)
   worldspawnpos.x, worldspawnpos.y, worldspawnpos.z = getCharCoordinates(playerPed)
   lua_thread.create(function()
      setPlayerControl(PLAYER_HANDLE, false)
      wait(100)
      if ini.settings.saveweather then
         sampSendChat("/time "..ini.settings.time)
         wait(500)
         sampSendChat("/weather "..ini.settings.weather)
         wait(500)
      end
      if ini.settings.autodevmode then
         dialoghook.devmenutoggle = true
         sampSendChat("/vw")
         wait(500)
      end
      if ini.settings.setgm then 
         sampSendChat("/gm")
         wait(500)
      end
      
      if sampIsLocalPlayerSpawned() then
         if ini.settings.saveskin and isValidSkin(ini.settings.skinid) then
            if getCharModel(playerPed) ~= ini.settings.skinid then 
               sampSendChat("/skin "..ini.settings.skinid)
            end
         end
      end
      wait(500)
      
      freezeCharPosition(playerPed, false)
      setPlayerControl(PLAYER_HANDLE, true)
      if isPlayerControlLocked(playerPed) then
         lockPlayerControl(false)
      end
      
      -- clean streamed textures list after world spawn
      for k, v in pairs(streamedTextures) do
         streamedTextures[k] = ""
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

function Restream()
   lua_thread.create(function()
   lockPlayerControl(true)

   if isTrainingSanbox then
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Начинается процесс рестрима. Ожидайте несколько секунд", 0x0FF6600)
   else
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Начинается процесс рестрима. Ожидайте чуть более 5 секунд", 0x0FF6600)
   end
   
   tpcpos.x, tpcpos.y, tpcpos.z = getCharCoordinates(playerPed)
   if isTrainingSanbox then
      sampSendChat(string.format("/xyz %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z+10000.0), 0x0FFFFFF)
   else
      setCharCoordinates(playerPed, tpcpos.x, tpcpos.y, tpcpos.z+10000.0)
   end
   
   if isTrainingSanbox then
      wait(750)
      sampSendChat(string.format("/xyz %f %f %f",
      tpcpos.x, tpcpos.y, tpcpos.z), 0x0FFFFFF)
   else
      wait(5000)
      setCharCoordinates(playerPed, tpcpos.x, tpcpos.y, tpcpos.z)
   end
   lockPlayerControl(false)
   
   -- clean stream memory (cause crashes)
   -- callFunction(0x40D7C0, 1, 1, -1) --restream
   
   wait(750)
   if dialoghook.error then
      if isTrainingSanbox then
         setCharCoordinates(playerPed, tpcpos.x, tpcpos.y, tpcpos.z+10000.0)
         wait(750)
         setCharCoordinates(playerPed, tpcpos.x, tpcpos.y, tpcpos.z+0.5)
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Рестрим завершен", 0x0FF6600)
         dialoghook.error = false
      else
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Произошла ошибка, рестрим не завершен!", 0x0FF6600)
         sampAddChatMessage("[SCRIPT]: {FFFFFF}Возможно вы не в своем мире, либо не на ногах.", 0x0FF6600)
      end
   else
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Рестрим завершен", 0x0FF6600)
   end
   end)
end

function copyNearestPlayersToClipboard()
   local tmpPlayers = {}
   local resulstring
   local totalplayers = 0
   for k, v in ipairs(getAllChars()) do
      local res, id = sampGetPlayerIdByCharHandle(v)
      local pid = getLocalPlayerId()
      if res and id ~= pid then
         totalplayers = totalplayers + 1
         local nickname = sampGetPlayerNickname(id)
         table.insert(tmpPlayers, string.format("%s[%d] ", nickname, id))
      end
   end
   if totalplayers > 0 then
      resulstring = table.concat(tmpPlayers)
      setClipboardText(resulstring)
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Ид и ники "..totalplayers.." игроков рядом скопированы в буффер обмена", 0x0FF6600)
      --return resulstring
   else 
      sampAddChatMessage("[SCRIPT]: {FFFFFF}Не найдено игроков рядом", 0x0FF6600)
   end
end

function checkScriptUpdates()
   -- Updates check function require request lua module 
   if doesFileExist(getGameDirectory() .. "\\moonloader\\lib\\requests.lua") then
      local result, response = pcall(require('requests').get, 'https://raw.githubusercontent.com/ins1x/MappingToolkit/main/version.dat')
      if result then
         if response.status_code == 200 then
            local text = response.text
            local version = text:gsub("[.]", "")
            local installedversion = tostring(thisScript().version)
            installedversion = installedversion:gsub("[.]", "")
            if tonumber(version) > tonumber(installedversion) then
               sampAddChatMessage("{696969}Mapping Toolkit  {FFFFFF}Доступно обновление до версии {696969}"..text, -1)
               return true
            end
         else
            print("Mapping Toolkit: Check updates failed server not responded")
            return false
         end
      else
         print("Mapping Toolkit: Check updates failed server unavailable")
         return false
      end
   else
      print("Updates check: module <requests> not found.")
      print("Install module from: https://luarocks.org/modules/jakeg/lua-requests")
      return false
   end
   return true
end

function enableDialog(bool)
   memory.setint32(sampGetDialogInfoPtr()+40, bool and 1 or 0, true)
   sampToggleCursor(bool)
end

function sampGetPlayerIdByNickname(nick)
   local id = getLocalPlayerId()
   if nick == sampGetPlayerNickname(id) then return id end
   for i = 0, sampGetMaxPlayerId(false) do
      if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then return i end
   end
end

function showPlayerAttachedObjects()
   if next(hiddenPlayerObjects) then
      for _, v in pairs(hiddenPlayerObjects) do
         if doesObjectExist(v) then
            setObjectVisible(v, true)
         end
      end
      hiddenPlayerObjects = {}
   end
end

function hidePED(state)
   local address = memory.read(0xB6F5F0, 4)
   if state then
      memory.setuint8(address + 0x474, 2, true)
   else
      memory.setuint8(address + 0x474, 1, true)
   end
end

function hidePlayerAttachedObjects()
   for _, v in pairs(getAllObjects()) do
      local _, objPosX, objPosY, objPosZ = getObjectCoordinates(v)
      local charPosX, charPosY, charPosZ = getCharCoordinates(playerPed)
      if getDistanceBetweenCoords3d(objPosX, objPosY, objPosZ, 
      charPosX, charPosY, charPosZ) <= 0.9 then
         table.insert(hiddenPlayerObjects, v)
         setObjectVisible(v, false)
      end
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

function cleanStreamMemory()
   local callfunc0 = callFunction(0x53C500, 2, 2, true, true)
   local callfunc1 = callFunction(0x53C810, 1, 1, true)
   local callfunc2 = callFunction(0x40CF80, 0, 0)
   local callfunc3 = callFunction(0x4090A0, 0, 0)
   local callfunc4 = callFunction(0x5A18B0, 0, 0)
   local callfunc5 = callFunction(0x707770, 0, 0)
   
   local pX, pY, pZ = getCharCoordinates(playerPed)
   requestCollision(pX, pY)
   loadScene(pX, pY, pZ)
end

function Draw3DCircle(x, y, z, radius, color)
   -- color as 0xARGB format
   local screen_x_line_old, screen_y_line_old
   for rot=0, 360 do
      local rot_temp = math.rad(rot)
      local lineX, lineY, lineZ = radius * math.cos(rot_temp) + x, radius * math.sin(rot_temp) + y, z
      local screen_x_line, screen_y_line = convert3DCoordsToScreen(lineX, lineY, lineZ)
      if screen_x_line ~=nil and screen_x_line_old ~= nil then 
         renderDrawLine(screen_x_line, screen_y_line, screen_x_line_old, screen_y_line_old, 3, color) 
      end
      screen_x_line_old, screen_y_line_old = screen_x_line, screen_y_line
   end
end

-- filesystem functions
function getFileSize(path)
   local file=io.open(path,"r")
   local current = file:seek()      -- get current position
   local size = file:seek("end")    -- get file size
   file:seek("set", current)        -- restore position
   return size
end

function doesFileExist(path)
   local f=io.open(path,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- FlyMode
function getFullSpeed(speed, ping, min_ping) 
   local fps = require('memory').getfloat(0xB7CB50, true) 
   local result = (speed / (fps / 60))
   if ping == 1 then 
      local ping = sampGetPlayerPing(select(2, sampGetPlayerIdByCharHandle(playerPed)))
      if min_ping < ping then 
         result = (result / (min_ping / ping)) 
      end
   end
   return result 
end 

function getMoveSpeed(heading, speed)
   moveSpeed = {x = math.sin(-math.rad(heading)) * (speed), y = math.cos(-math.rad(heading)) * (speed), z = 0} 
   return moveSpeed
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

function hex_to_argb(hex)
   local a, r, g, b = explode_argb(tonumber(hex, 16))
   return a, r, g, b
end

function intToHexRgb(int)
   return string.sub(bit.tohex(int), 3, 8)
end

function intToHexArgb(int)
   return string.sub(bit.tohex(int), 1, 8)
end

function showRetextureKeysHelp()
   sampAddChatMessage("[SCRIPT]: {FFFFFF}Управление: {FF6600}Y{FFFFFF} - Текстура наверх {FF6600}N{FFFFFF} - Текстура вниз", 0x0FF6600)
   if ini.settings.remapnum then
      sampAddChatMessage("[SCRIPT]: {FF6600}Num4{FFFFFF} - Предыдущая страница, {FF6600}Num6{FFFFFF} - Следующая страница", 0x0FF6600)
   else
      sampAddChatMessage("[SCRIPT]: {FF6600}PgUp{FFFFFF} - Предыдущая страница, {FF6600}PgDown{FFFFFF} - Следующая страница", 0x0FF6600)
   end
   sampAddChatMessage("[SCRIPT]: {FF6600}Backspace{FFFFFF} - Вернуться на стартовую страницу", 0x0FF6600)
   sampAddChatMessage("[SCRIPT]: {FF6600}Клавиша бега{FFFFFF} - Принять", 0x0FF6600)
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

function getMDO(id_obj)
   -- get mem obj distance by Gorskin 
   return callFunction(0x403DA0, 1, 1, id_obj) + 24 
end

function getSampVersionId()
   local versionid = 0
   sampdllHandle = getModuleHandle('samp.dll')
   sampdllHandle = sampdllHandle + 0x128
   versionData = readMemory(sampdllHandle, 4, true)
   if versionData == 0x5542F47A then
      versionid = 1 -- r1
   end
   if versionData == 0x59C30C94 then
      versionid = 2 -- r2
   end

   sampdllHandle = sampdllHandle - 8
   versionData = readMemory(sampdllHandle, 4, true)
   if versionData == 0x5C0B4243 then
      versionid = 3 -- r3
   end
   if versionData == 0x5DD606CD then
      versionid = 4 -- R4
   end
   -- if versionData == 0x6094ACAB then
       -- versionid = 42 -- R4-2
   -- end
   if versionData == 0x6372C39E then
      versionid = 5 --R5
   end
   return versionid
end

-- imgui fuctions
function imgui.ToggleButton(str_id, bool)
   -- this function is not same imgui_addons lib ToggleButton
   local rBool = false

   if LastActiveTime == nil then
      LastActiveTime = {}
   end
   if LastActive == nil then
      LastActive = {}
   end

   local function ImSaturate(f)
      return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
   end
 
   local p = imgui.GetCursorScreenPos()
   local draw_list = imgui.GetWindowDrawList()

   local height = imgui.GetTextLineHeightWithSpacing() + (imgui.GetStyle().FramePadding.y / 2)
   local width = height * 1.55
   local radius = height * 0.50
   local ANIM_SPEED = 0.15

   if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
      bool.v = not bool.v
      rBool = true
      LastActiveTime[tostring(str_id)] = os.clock()
      LastActive[str_id] = true
   end

   local t = bool.v and 1.0 or 0.0

   if LastActive[str_id] then
      local time = os.clock() - LastActiveTime[tostring(str_id)]
      if time <= ANIM_SPEED then
         local t_anim = ImSaturate(time / ANIM_SPEED)
         t = bool.v and t_anim or 1.0 - t_anim
      else
         LastActive[str_id] = false
      end
   end

   local col_bg
   if imgui.IsItemHovered() then
      col_bg = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.FrameBgHovered])
   else
      col_bg = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.FrameBg])
   end

   draw_list:AddRectFilled(p, imgui.ImVec2(p.x + width, p.y + height), col_bg, height * 0.5)
   draw_list:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 1.5, imgui.GetColorU32(bool.v and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.GetStyle().Colors[imgui.Col.Button]))
   
   imgui.SameLine()
   imgui.AlignTextToFramePadding()
   imgui.Text(tostring(str_id))
   
   return rBool
end

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
   if imgui.InvisibleButton("##" .. link, tSize) then os.execute('explorer "' .. link ..'"') end
   local color = imgui.IsItemHovered() and col[1] or col[2]
   DL:AddText(p, color, text)
   DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)

   if imgui.IsItemHovered() then
      imgui.BeginTooltip()
      imgui.PushTextWrapPos(500)
      imgui.TextUnformatted(link)
      imgui.PopTextWrapPos()
      imgui.EndTooltip()
   end
end

function imgui.TextNotify(label, description)
   imgui.TextColoredRGB(label)
   if imgui.IsItemHovered() then
      imgui.BeginTooltip()
         imgui.PushTextWrapPos(600)
            imgui.TextUnformatted(description)
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

function imgui.resetIO()
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

function isObjectDestructible(modelid)
   local destructibleObjects = {
      625,626,627,628,629,630,631,632,633,642,643,644,646,650,716,717,737,
      738,792,858,881,882,883,884,885,886,887,888,889,890,891,892,893,894,
      895,904,905,941,955,956,959,961,990,993,996,1209,1211,1213,1219,1220,
      1221,1223,1224,1225,1226,1227,1228,1229,1230,1231,1232,1235,1238,1244,
      1251,1255,1257,1262,1264,1265,1270,1280,1281,1282,1283,1284,1285,1286,
      1287,1288,1289,1290,1291,1293,1294,1297,1300,1302,1315,1328,1329,1330,
      1338,1350,1351,1352,1370,1373,1374,1375,1407,1408,1409,1410,1411,1412,
      1413,1414,1415,1417,1418,1419,1420,1421,1422,1423,1424,1425,1426,1428,
      1429,1431,1432,1433,1436,1437,1438,1440,1441,1443,1444,1445,1446,1447,
      1448,1449,1450,1451,1452,1456,1457,1458,1459,1460,1461,1462,1463,1464,
      1465,1466,1467,1468,1469,1470,1471,1472,1473,1474,1475,1476,1477,1478,
      1479,1480,1481,1482,1483,1514,1517,1520,1534,1543,1544,1545,1551,1553,
      1554,1558,1564,1568,1582,1583,1584,1588,1589,1590,1591,1592,1645,1646,
      1647,1649,1654,1664,1666,1667,1668,1669,1670,1672,1676,1684,1686,1775,
      1776,1949,1950,1951,1960,1961,1962,1975,1976,1977,2647,2663,2682,2683,
      2885,2886,2887,2900,2918,2920,2925,2932,2933,2942,2943,2945,2947,2958,
      2959,2966,2968,2971,2977,2987,2988,2989,2991,2994,3006,3018,3019,3020,
      3021,3022,3023,3024,3029,3032,3036,3058,3059,3067,3083,3091,3221,3260,
      3261,3262,3263,3264,3265,3267,3275,3276,3278,3280,3281,3282,3302,3374,
      3409,3460,3516,3794,3795,3797,3851,3853,3855,3857,3858,3859,3864,3872,
      3884,11103,12840,16627,16628,16629,16630,16631,16632,16633,16634,16635,
      16636,16732,17968,19023
   }

   for k, v in ipairs(destructibleObjects) do
      if modelid == tonumber(v) then
         return true
      end
   end
   return false
end

function isObjectWithAnimation(modelid)
   local animatedObjects = {
      2873,2875,2876,2877,2780,2878,2879,3425,3515,3525,3528,
      3426,3427,6010,6257,6965,7387,7388,7389,7390,7391,7392,
      7916,7971,7972,7973,9192,9193,9831,9898,9899,
      10310,10744,11417,11677,11701,13562,13594,14642,16368,
      16776,16777,16778,16779,16780,16781,18642,19128,19129,
      19159,19419,19620,19632,19797,19841,19842
   }

   for k, v in ipairs(animatedObjects) do
      if modelid == tonumber(v) then
         return true
      end
   end
   return false
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

function getSafeObjectModel()
   local safeobjects = {
       19353, 19383, 19399, 19426, 19445, -- walls
       18762, 18763, 18764, 18765, 18766, -- concrete block
       19789, 19790, 19791 -- square blocks
    }
   return safeobjects[math.random(#safeobjects)]
end

function getStreamedObjects(all) 
-- param all - count all objects static and dynamic
   local streamedObjectsOnScreen = 0
   for _, v in pairs(getAllObjects()) do
      if isObjectOnScreen(v) then
         local objectid = sampGetObjectSampIdByHandle(v)
         if all then
            streamedObjectsOnScreen = streamedObjectsOnScreen + 1
         else
            if objectid ~= -1 then -- count only dynamic objects
               streamedObjectsOnScreen = streamedObjectsOnScreen + 1
            end
         end
      end
   end
   return streamedObjectsOnScreen 
end

function getZoneName(x, y, z)
    -- modified code snippet by ШPEK
    local streets = {
    {"Avispa Country Club", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
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
   style.ItemSpacing = imgui.ImVec2(6, 4)
   style.ItemInnerSpacing = imgui.ImVec2(8, 6)
   style.IndentSpacing = 20.0
   style.ScrollbarSize = 12.0
   style.ScrollbarRounding = 9.0
   style.GrabMinSize = 5.0
   style.GrabRounding = 3.0
   
   --imgui.SetColorEditOptions(imgui.ColorEditFlags.HEX)
  
   -- STYLE 1 Dark
   if ini.settings.imguitheme == 0 then
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
   -- STYLE 2 Grey-Blue
   elseif ini.settings.imguitheme == 1 then
      colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
      colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
      colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
      colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
      colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
      colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
      colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
      colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
      colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
      colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
      colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
      colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
      colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
      colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
      colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
      colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
      colors[clr.ComboBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.CheckMark] = ImVec4(0.28, 0.56, 1.00, 1.00)
      colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1.00, 1.00)
      colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1.00, 1.00)
      colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
      colors[clr.ButtonHovered] = ImVec4(0.28, 0.56, 1.00, 1.00)
      colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1.00)
      colors[clr.Header] = ImVec4(0.20, 0.25, 0.29, 0.55)
      colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.80)
      colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1.00)
      colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
      colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
      colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
      colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
      colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
      colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
      colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
      colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
      colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
      colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
      colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
      colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
      -- STYLE 3 Brutal
   elseif ini.settings.imguitheme == 2 then
      colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
      colors[clr.TextDisabled] = ImVec4(0.29, 0.29, 0.29, 1.00)
      colors[clr.WindowBg] = ImVec4(0.14, 0.14, 0.14, 1.00)
      colors[clr.ChildWindowBg]= ImVec4(0.12, 0.12, 0.12, 1.00)
      colors[clr.PopupBg]= ImVec4(0.08, 0.08, 0.08, 0.94)
      colors[clr.Border] = ImVec4(0.14, 0.14, 0.14, 1.00)
      colors[clr.BorderShadow] = ImVec4(1.00, 1.00, 1.00, 0.10)
      colors[clr.FrameBg]= ImVec4(0.22, 0.22, 0.22, 1.00)
      colors[clr.FrameBgHovered] = ImVec4(0.18, 0.18, 0.18, 1.00)
      colors[clr.FrameBgActive]= ImVec4(0.09, 0.12, 0.14, 1.00)
      colors[clr.TitleBg]= ImVec4(0.14, 0.14, 0.14, 0.81)
      colors[clr.TitleBgActive]= ImVec4(0.14, 0.14, 0.14, 1.00)
      colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
      colors[clr.MenuBarBg]= ImVec4(0.20, 0.20, 0.20, 1.00)
      colors[clr.ScrollbarBg]= ImVec4(0.02, 0.02, 0.02, 0.39)
      colors[clr.ScrollbarGrab]= ImVec4(0.36, 0.36, 0.36, 1.00)
      colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
      colors[clr.ScrollbarGrabActive]= ImVec4(0.24, 0.24, 0.24, 1.00)
      colors[clr.ComboBg]= ImVec4(0.24, 0.24, 0.24, 1.00)
      colors[clr.CheckMark]= ImVec4(1.00, 0.28, 0.28, 1.00)
      colors[clr.SliderGrab] = ImVec4(1.00, 0.28, 0.28, 1.00)
      colors[clr.SliderGrabActive] = ImVec4(1.00, 0.28, 0.28, 1.00)
      colors[clr.Button] = ImVec4(1.00, 0.28, 0.28, 1.00)
      colors[clr.ButtonHovered]= ImVec4(1.00, 0.39, 0.39, 1.00)
      colors[clr.ButtonActive] = ImVec4(1.00, 0.21, 0.21, 1.00)
      colors[clr.Header] = ImVec4(1.00, 0.28, 0.28, 1.00)
      colors[clr.HeaderHovered]= ImVec4(1.00, 0.39, 0.39, 1.00)
      colors[clr.HeaderActive] = ImVec4(1.00, 0.21, 0.21, 1.00)
      colors[clr.ResizeGrip] = ImVec4(1.00, 0.28, 0.28, 1.00)
      colors[clr.ResizeGripHovered]= ImVec4(1.00, 0.39, 0.39, 1.00)
      colors[clr.ResizeGripActive] = ImVec4(1.00, 0.19, 0.19, 1.00)
      colors[clr.CloseButton]= ImVec4(0.40, 0.39, 0.38, 0.16)
      colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
      colors[clr.CloseButtonActive]= ImVec4(0.40, 0.39, 0.38, 1.00)
      colors[clr.PlotLines]= ImVec4(0.61, 0.61, 0.61, 1.00)
      colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
      colors[clr.PlotHistogram]= ImVec4(1.00, 0.21, 0.21, 1.00)
      colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.18, 0.18, 1.00)
      colors[clr.TextSelectedBg] = ImVec4(1.00, 0.32, 0.32, 1.00)
      colors[clr.ModalWindowDarkening] = ImVec4(0.26, 0.26, 0.26, 0.60)
      -- STYLE 4: TRAINING Colors theme
   elseif ini.settings.imguitheme == 3 then
      colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
      colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
      colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
      colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
      colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
      colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
      colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
      colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.FrameBgHovered] = ImVec4(0.56, 0.56, 0.58, 1.0)
      colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
      colors[clr.TitleBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
      colors[clr.TitleBgActive] = ImVec4(0.56, 0.42, 0.01, 1.00)
      colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
      colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.42, 0.01, 1.00)
      colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
      colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
      colors[clr.CheckMark] = ImVec4(0.56, 0.42, 0.01, 1.00)
      colors[clr.SliderGrab] = ImVec4(1.00, 0.42, 0.00, 0.53)
      colors[clr.SliderGrabActive] = ImVec4(1.00, 0.42, 0.00, 1.00)
      colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.ButtonHovered] = ImVec4(0.56, 0.42, 0.01, 1.00)
      colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
      colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.HeaderHovered] = ImVec4(0.56, 0.42, 0.01, 1.00)
      colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
      colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
      colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
      colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
      colors[clr.CloseButton] = ImVec4(0.06, 0.05, 0.07, 0.25)
      colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
      colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
      colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
      colors[clr.PlotLinesHovered] = ImVec4(0.56, 0.42, 0.01, 1.00)
      colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
      colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
      colors[clr.TextSelectedBg] = ImVec4(0.56, 0.42, 0.01, 1.00)
      colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
   -- STYLE 5: Halloween Colors theme
   elseif ini.settings.imguitheme == 4 then 
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
      colors[clr.TitleBg] = ImVec4(0.76, 0.31, 0.00, 1.00)
      colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
      colors[clr.TitleBgActive] = ImVec4(0.80, 0.33, 0.00, 1.00)
      colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
      colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
      colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
      colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
      colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
      colors[clr.CheckMark] = ImVec4(1.00, 0.42, 0.00, 0.53)
      colors[clr.SliderGrab] = ImVec4(1.00, 0.42, 0.00, 0.53)
      colors[clr.SliderGrabActive] = ImVec4(1.00, 0.42, 0.00, 1.00)
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
end
apply_custom_style()

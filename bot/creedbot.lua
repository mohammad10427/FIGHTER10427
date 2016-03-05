package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

VERSION = '1.0'

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  local receiver = get_receiver(msg)
  print (receiver)

  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
  --   mark_read(receiver, ok_cb, false)
    end
  end
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < now then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
  	local login_group_id = 1
  	--It will send login codes to this chat
    send_large_msg('chat#id'..login_group_id, msg.text)
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Allowed user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "onservice",
    "ownservicefa",
    "inrealm",
    "inrealmfa",
    "ingroup",
    "ingroupfa",
    "inpm",
    "inpmfa",
    "banhammer",
    "banhammberfa",
    "Boobs",
    "Feedback",
    "plugins",
    "lock_join",
    "lock_joinfa",
    "antitagfa",
    "antilink",
    "antilinkfa",
    "yoda",
    "danbooru",
    "dogify",
    "expand",
    "face",
    "isX",
    "allfa",
    "magic8ball",
    "pili",
    "qr",
    "quotes",
    "trivia",
    "vote",
    "foshlock",
    "weather",
    "antitag",
    "gps",
    "auto_leave",
    "auto_leavefa",
    "wiki",
    "channels",
    "img_google",
    "inviteme",
    "location",
    "giphy",
    "dogify",
    "chuck_norris",
    "search_youtube",
    "translate",
    "cpu",
    "calc",
    "add-plugins",
    "chatbot",
    "music",
    "bin",
    "tagall",
    "salam",
    "text",
    "textfa",
    "info",
    "infofa",
    "bot_on_off",
    "welcome",
    "echo",
    "webshot",
    "webshotfa",
    "leave",
    "leave_banfa",
    "sl",
    "filter",
    "botphoto",
    "addplug",
    "google",
    "sms",
    "anti_spam",
    "anti-spemfa",
    "add_bot",
    "time",
    "owners",
    "ownersfa",
    "welcome",
    "welcomefa",
    "set",
    "setfa",
    "get",
    "getfa",
    "tagallfa",
    "music",
    "wikifa",
    "lock_eng",
    "broadcast",
    "broadcastfa",
    "download_media",
    "invite",
    "invitefa",
    "all",
    "allfa",
    "share_acant",
    "leave_ban"
    },
    sudo_users = {214877832,137791771},--Sudo users
    disabled_chann144152859els = {},
    realm = {},--Realms Id
    moderation = {data = 'data/moderation.json'},
    about_text = [[Eagle bot
    
     Hello my Good friends 
     
    ‼️ this bot is made by : @shayan123hacker
   〰〰〰〰〰〰〰〰
   ߔࠀ   our admins are : 
   ߔࠀ   @mehdijockers_@Xx_shah2_kings_Xx 〰〰〰〰〰〰〰〰
  ♻️ You can send your Ideas and messages to Us By sending them into bots account by this command :
   تمامی درخواست ها و همه ی انتقادات و حرفاتونو با دستور زیر بفرستین به ما
   !feedback (your ideas and messages)
]],
    help_text_realm = [[
   دستورات ریلم :
!creategroup [Name]
[ساخت گروه [نام گروه
!createrealm [Name]
[ساخت ریلم [نام ریلم
!setname [Name]
[تنظیم نام [نام
!setabout [GroupID] [Text]
[تنظیم درباره گروه [ایدی گروه ][متن
!setrules [GroupID] [Text]
[تنظیم  قوانین گروه [ایدی گروه ][ متن
!lock [GroupID] [setting]
[قفل گروه[ایدی گروه][تنظیمات
!unlock [GroupID] [setting]
[بازکردن گروه [ایدی گروه ][تنظیمات
!wholist
 لیست اعضای گروه/ریلم به صورت متن
!who
لیست اعضای گروه/ریلم درفایل زیپ
!type
نوع گروه 
!kill chat [GroupID]
[حذف گروه [ایدی گروه
!kill realm [RealmID]
[حذف ریلم [ایدی ریلم 
!addadmin [id|username]
[ادمین  اصلی[ایدی |یوزرنیم
!removeadmin [id|username]
[حذف ادمین اصلی [ایدی|یوزرنیم
!banall [id|username]
[سوپر بن کردن افراد[ایدی][یوزرنیم
!unbanall [id|username]
[دراوردن از سوپر بن [ایدی][یوزرنیم
!list groups
لیست گروهای ربات
!list realms
لیست ریلم های ربات
!plugins 
دریافت پلاگین های ربات 
!plugins + name 
[فعال کردن پلاگین  [نام پلاگین
!plugins - name 
[غیر فعال کردن پلاگین [نام پلاگین
!addplugin [cd plugin]+[name+.lua
[.lua+اضافه کردن پلاگین [کدهای پلاگین][نام پلاگین
!log
دریافت وردی های گروه و ریلم
!broadcast [text]
[ارسال یک پیام به تمام گروه ها[متن پیام
!br [group_id] [text]
[ارسال دستور به گروه[ایدی گروه][متن
    
شما میتوانید از دستورات زیر استفاده کنید👇🏻  
"!" "/" 



]],
    help_text = [[
Creed bots Help for mods : Plugins
Shayan123 : 

     Help For Banhammer 
 
     دستورات گروه : 
!kick [ایدی فرد و یا ریپلی پیام او]
کیک کردن فردی
!ban [ایدی فرد و یا ریپلی پیام او]
کیک دائمی فردی
!unban [ایدی فرد و یا ریپلی پیام او]
خلاص شدن از کیک دائمی فردی.
!who
لیست اعضا در فایل زیپ
!wholist
دریافت لیست اعضا به صورت متن
!modlist
لیست مدیران گروه
!promote [ایدی فرد و یا ریپلی پیام او]
اضافه کردن مدیری به گروه
!demote [ایدی فرد و یا ریپلی پیام او.]
حذف کردن فردی از مدیریت در گروه
!kickme
خروج از گروه
!about
درباره گروه
!setphoto
تنظیم عکس  و قفل کردن ان
!setname [نام]
تنظیم نام گروه به : نام
!rules
قوانین گروه
!id
ایدی گروه و با ریپلی کردن پیام فردی ایدی او را نشان میدهد
!lock [member|name|bots|leave|link|tag|flood]
 بستن :اعضا-نام-ورود ربات ها-خروج اعضا-لینک-تگ-اسپم
!unlock [member|name|bots|leave|link|tag|flood]
بازکردن : اعضا - نام - ورود ربات ها - خروج اعضا-لینک-تگ-اسپم
!set rules <متن>
تنظیم قوانین گروه به : متن
!set about <متن>
تنظیم درباره گروه به : متن
!settings
تنظیمات گروه
!newlink
لینک جدید
!link
لینک گروه
!linkpv
لینک گروه در شخصی

!filter + کیر
ممنوع کردن استفاده  از کلمه ای در گروه 

!filter - کیر
ازاد کردن استفاده از کلمه ای در گروه
!بگو سلام 
تکرار حرف توسط ربات
!time tehran
نشان دهنده ساعت
!celc 2+3
ماشین حساب
!lock arabic
قفل زبان فارسی در گروه
!unlock arabic
ازاد کردن زبان فارسی درگروه
!google بازی 
سرچ کردن در گوگل 
!webshot https://google.com
شات گرفتن از سایت
!wikifa شاه
درباره چیزی
!info [username][reply]
 [دریافت اطلاعات[یوزرنیم][با ریپلای
!support
دعوت ادمین ربات 
!owner
ایدی صاحب گروه
!setowner [ایدی فرد و یا ریپلی پیام او]
تنظیم صاحب گروه
!setflood [عدد]
تنظیم مقدار اسپم : میتواند از عدد 5 شروع شود.
!lock link
قفل کردن لینک گذاشتن درگروه
!stats
نمایش تعداد پیام ها
!save [نام دستور] <متن>
ساختن دستور جدید : نام دستور - متن
!get [نام دستور]
دریافن دستور
!clean [modlist|rules|about]
پاک کردن : لیست مدیران - قوانین - درباره گروه
!res [username]
دریافت نام و ایدی فردی. مثال👇
"!res @mehdijokers"
!log
دریافت ورودی های گروه
!banlist
لیست افراد بن شده
شما میتوانید از دستورات زیر استفاده کنید👇
"!" "/" 
 سازنده ها: @mehdijokers__@Xx_shah2_kings_Xx  
ادرس کانال ربات:@kingsunion    


]]

  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)

end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
      print('\27[31m'..err..'\27[39m')
    end

  end
end


-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false

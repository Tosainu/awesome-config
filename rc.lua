-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

local beautiful = require("beautiful")
local menubar = require("menubar")
local naughty = require("naughty")
local wibox = require("wibox")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- https://github.com/pavouk/lgi
local lgi = require("lgi")
local Gio = lgi.Gio

-- https://github.com/vicious-widgets/vicious
local vicious = require("vicious")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({
    preset  = naughty.config.presets.critical,
    title   = "Oops, there were errors during startup!",
    text    = awesome.startup_errors
  })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal("debug::error", function(err)
    -- Make sure we don't go into an endless error loop
    if in_error then return end
    in_error = true

    naughty.notify({
      preset  = naughty.config.presets.critical,
      title   = "Oops, an error happened!",
      text    = tostring(err)
    })

    in_error = false
  end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(gears.filesystem.get_dir("config") .. "/theme.lua")

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
  awful.layout.suit.floating,
  awful.layout.suit.tile,
  -- awful.layout.suit.tile.left,
  -- awful.layout.suit.tile.bottom,
  -- awful.layout.suit.tile.top,
  awful.layout.suit.fair,
  awful.layout.suit.fair.horizontal,
  -- awful.layout.suit.spiral,
  -- awful.layout.suit.spiral.dwindle,
  -- awful.layout.suit.max,
  -- awful.layout.suit.max.fullscreen,
  awful.layout.suit.corner.nw,
  -- awful.layout.suit.corner.ne,
  -- awful.layout.suit.corner.sw,
  -- awful.layout.suit.corner.se,
  awful.layout.suit.magnifier,
}

local editor        = os.getenv("EDITOR") or "vim"
local file_manager  = "nautilus"
local image_editor  = "gimp"
local manual        = "man awesome"
local terminal      = "alacritty"
local web_browser   = "chromium"

local battery         = "BAT1"
local thermal_zone    = "thermal_zone0"
local wifi_interface  = "wlp2s0"
-- }}}

-- {{{ Helper functions
local function run_in_terminal(command)
  return terminal .. " -e '" .. tostring(command) .. "'"
end

local function path_exists(filepath)
  local gfile = Gio.File.new_for_path(filepath)
  return gfile:query_exists()
end
-- }}}

-- {{{ Screenshot
local screenshot_mode = {
  screen    = 1,
  curwin    = 2,
  selection = 4,
}

local function notify_screenshot_result(filepath, err)
  naughty.notify(err and {
    preset = naughty.config.presets.critical,
    title = "Failed to save screenshot",
    text = err,
  } or {
    title = "Screenshot saved!",
    text = filepath,
    icon = filepath,
    actions = {
      ["Open file"] = function() awful.spawn({ "xdg-open", filepath }) end
    },
  })
end

local function take_screenshot(mode)
  local savedir = os.getenv("HOME") .. "/Pictures/"
  local basename = os.date("Screenshot_%Y-%m-%d-%H%M%S")
  local filepath = savedir .. basename .. ".png"
  local idx = 0
  while path_exists(filepath) do
    idx = idx + 1
    filepath = savedir .. string.format("%s_%d.png", basename, idx)
  end

  if mode == screenshot_mode.curwin then
    local surface = gears.surface.load(client.focus.content)
    if surface then
      local r = surface:write_to_png(filepath)
      notify_screenshot_result(filepath, r ~= "SUCCESS" and r or nil)
    else
      notify_screenshot_result(filepath, "Error occurred during loading the surface")
    end
  else
    local cmd = { "maim", "-u", filepath }
    if mode == screenshot_mode.selection then
      table.insert(cmd, "-s")
    end
    awful.spawn.easy_async(cmd, function(_, err, _, code)
      notify_screenshot_result(filepath, code ~= 0 and err or nil)
    end)
  end
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
local mymainmenu = awful.menu({
  items = {
    { "awesome", {
      { "hotkeys",      function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
      { "manual",       run_in_terminal(manual) },
      { "edit config",  run_in_terminal(editor .. " " .. awesome.conffile) },
      { "restart",      awesome.restart },
    }, beautiful.awesome_icon },
    { "logout",   function() awesome.quit() end},
    { "lock",     "xautolock -locknow"},
    { "suspend",  "systemctl suspend" },
    { "reboot",   "systemctl reboot" },
    { "halt",     "systemctl poweroff" }
  }
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Widgets {{{
local function fa(s)
  return "<span face=\"Font Awesome 5 Free\">" .. s .. "</span>"
end

local clock_widget = wibox.widget.textclock("%a, %b %d, %H:%M")

local calendar_widget = awful.widget.calendar_popup.month({ start_sunday = true });
calendar_widget:attach(clock_widget)

local battery_widget = wibox.widget.textbox()
vicious.register(battery_widget, vicious.widgets.bat, function(_, args)
  local icon = (args[1]:find("^[⌁↯+]$") and fa("\u{f1e6} ")) or fa("\u{f241} ")
  return string.format("%s%d%%", icon, args[2])
end, 61, battery)

local cputemp_widget = wibox.widget.textbox()
vicious.register(cputemp_widget, vicious.widgets.thermal,
                 fa("\u{f2ca} ") .. "$1°C", 7, thermal_zone)
local cputemp_tooltip = awful.tooltip {
  objects = { cputemp_widget },
  mode = "outside",
  timer_function = function()
    local l = {}
    for idx, pct in pairs(vicious.widgets.cpu()) do
      if idx >= 2 then
        local cpuidx = idx - 2
        local freq = vicious.widgets.cpufreq("", string.format("cpu%d", cpuidx))
        local freq_ghz = freq[2]
        table.insert(l, string.format("Core%2d: %.2f GHz %3d %%", cpuidx + 1, freq_ghz, pct))
      end
    end
    return table.concat(l, "\n")
  end,
}
vicious.cache(vicious.widgets.cpu)
vicious.cache(vicious.widgets.cpufreq)

local memory_widget = wibox.widget.textbox()
vicious.register(memory_widget, vicious.widgets.mem,
                 fa("\u{f538} ") .. "$1% / $5%", 5)
local memory_tooltip = awful.tooltip {
  objects = { memory_widget },
  mode = "outside",
  timer_function = function()
    local l = {}
    local mem = vicious.widgets.mem()
    table.insert(l, string.format("RAM:  %d/%d MiB", mem[2], mem[3]))
    table.insert(l, string.format("SWAP: %d/%d MiB", mem[6], mem[7]))
    return table.concat(l, "\n")
  end,
}
vicious.cache(vicious.widgets.mem)

local wifi_widget = wibox.widget.textbox()
vicious.register(wifi_widget, vicious.widgets.wifi,
                 fa("\u{f1eb} ") .. "${ssid} ${linp}%", 37, wifi_interface)

local volume_widget = wibox.widget.textbox()
vicious.register(volume_widget, vicious.widgets.volume, function(_, args)
  local icon = (args[2] == "♫" and fa("\u{f028} ")) or fa("\u{f6a9} ")
  return string.format("%s%d%%", icon, args[1])
end, 11, "Master")
-- }}}

-- {{{ Wibar
-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
  awful.button({},         1, function(t) t:view_only() end),
  awful.button({ modkey }, 1, function(t)
    if client.focus then
      client.focus:move_to_tag(t)
    end
  end),
  awful.button({},         3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, function(t)
    if client.focus then
      client.focus:toggle_tag(t)
    end
  end),
  awful.button({},         4, function(t) awful.tag.viewnext(t.screen) end),
  awful.button({},         5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
  awful.button({},         1, function(c)
    if c == client.focus then
      c.minimized = true
    else
      c:emit_signal("request::activate", "tasklist", { raise = true })
    end
  end),
  awful.button({},         3, function()
    awful.menu.client_list({ theme = { width = 250 } })
  end),
  awful.button({},         4, function() awful.client.focus.byidx( 1) end),
  awful.button({},         5, function() awful.client.focus.byidx(-1) end)
)

local function set_wallpaper(s)
  -- Wallpaper
  if beautiful.wallpaper then
    local wallpaper = beautiful.wallpaper
    -- If wallpaper is a function, call it with the screen
    if type(wallpaper) == "function" then
      wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s)
  end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local function is_primary_screen(s)
  return s.index == screen.primary.index
end

awful.screen.connect_for_each_screen(function(s)
  -- Wallpaper
  set_wallpaper(s)

  -- Each screen has its own tag table.
  awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
            s, awful.layout.layouts[2])

  -- Create a promptbox for each screen
  s.mypromptbox = awful.widget.prompt()
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  s.mylayoutbox = awful.widget.layoutbox(s)
  s.mylayoutbox:buttons(gears.table.join(
    awful.button({}, 1, function() awful.layout.inc( 1) end),
    awful.button({}, 3, function() awful.layout.inc(-1) end),
    awful.button({}, 4, function() awful.layout.inc( 1) end),
    awful.button({}, 5, function() awful.layout.inc(-1) end)
  ))

  -- Create a taglist widget
  s.mytaglist = awful.widget.taglist {
    screen  = s,
    filter  = awful.widget.taglist.filter.all,
    widget_template = {
      id = 'background_role',
      widget = wibox.container.background,
      {
        widget = wibox.container.margin,
        left = beautiful.wibar_separator_width / 2,
        right = beautiful.wibar_separator_width / 2,
        {
          id = 'text_role',
          widget = wibox.widget.textbox,
        },
      },
    },
    buttons = taglist_buttons
  }

  -- Create a tasklist widget
  s.mytasklist = awful.widget.tasklist {
    screen  = s,
    filter  = awful.widget.tasklist.filter.currenttags,
    buttons = tasklist_buttons
  }

  -- Create the wibox
  s.mywibox = awful.wibar({ position = "top", screen = s })

  -- Add widgets to the wibox
  s.mywibox:setup {
    layout = wibox.layout.align.horizontal,
    -- Left widgets
    {
      layout = wibox.layout.fixed.horizontal,
      s.mytaglist,
      s.mypromptbox,
    },
    -- Middle widget
    s.mytasklist,
    -- Right widgets
    gears.table.join({
      layout = wibox.layout.fixed.horizontal,
      spacing = beautiful.wibar_separator_width,
    }, is_primary_screen(s) and {
      wibox.widget.systray(),
      wifi_widget,
      cputemp_widget,
      memory_widget,
      battery_widget,
      volume_widget,
      clock_widget,
      s.mylayoutbox,
    } or {
      s.mylayoutbox,
    }),
  }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
  awful.button({}, 3, function() mymainmenu:toggle() end),
  awful.button({}, 4, awful.tag.viewnext),
  awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
local globalkeys = gears.table.join(
  awful.key({ modkey,           }, "s",       hotkeys_popup.show_help,
            { description = "show help", group = "awesome" }),
  awful.key({ modkey,           }, "Left",    awful.tag.viewprev,
            { description = "view previous", group = "tag" }),
  awful.key({ modkey,           }, "Right",   awful.tag.viewnext,
            { description = "view next", group = "tag" }),
  awful.key({ modkey,           }, "Escape",  awful.tag.history.restore,
            { description = "go back", group = "tag" }),

  awful.key({ modkey,           }, "j",       function() awful.client.focus.byidx( 1) end,
            { description = "focus next by index", group = "client" }),
  awful.key({ modkey,           }, "k",       function() awful.client.focus.byidx(-1) end,
            { description = "focus previous by index", group = "client" }),
  awful.key({ modkey,           }, "w",       function() mymainmenu:show() end,
            { description = "show main menu", group = "awesome" }),

  -- Layout manipulation
  awful.key({ modkey, "Shift"   }, "j",       function() awful.client.swap.byidx(  1) end,
            { description = "swap with next client by index", group = "client" }),
  awful.key({ modkey, "Shift"   }, "k",       function() awful.client.swap.byidx( -1) end,
            { description = "swap with previous client by index", group = "client" }),
  awful.key({ modkey, "Control" }, "j",       function() awful.screen.focus_relative( 1) end,
            { description = "focus the next screen", group = "screen" }),
  awful.key({ modkey, "Control" }, "k",       function() awful.screen.focus_relative(-1) end,
            { description = "focus the previous screen", group = "screen" }),
  awful.key({ modkey,           }, "u",       awful.client.urgent.jumpto,
            { description = "jump to urgent client", group = "client" }),
  awful.key({ modkey,           }, "Tab",     function()
    awful.client.focus.history.previous()
    if client.focus then
      client.focus:raise()
    end
  end,      { description = "go back", group = "client" }),

  -- Standard program
  awful.key({ modkey,           }, "Return",  function() awful.spawn(terminal) end,
            { description = "open a terminal", group = "launcher" }),
  awful.key({ modkey, "Control" }, "r",       awesome.restart,
            { description = "reload awesome", group = "awesome" }),
  awful.key({ modkey, "Shift"   }, "q",       awesome.quit,
            { description = "quit awesome", group = "awesome" }),

  awful.key({ modkey,           }, "l",       function() awful.tag.incmwfact( 0.02) end,
            { description = "increase master width factor", group = "layout" }),
  awful.key({ modkey,           }, "h",       function() awful.tag.incmwfact(-0.02) end,
            { description = "decrease master width factor", group = "layout" }),
  awful.key({ modkey, "Shift"   }, "h",       function() awful.tag.incnmaster( 1, nil, true) end,
            { description = "increase the number of master clients", group = "layout" }),
  awful.key({ modkey, "Shift"   }, "l",       function() awful.tag.incnmaster(-1, nil, true) end,
            { description = "decrease the number of master clients", group = "layout" }),
  awful.key({ modkey, "Control" }, "h",       function() awful.tag.incncol( 1, nil, true) end,
            { description = "increase the number of columns", group = "layout" }),
  awful.key({ modkey, "Control" }, "l",       function() awful.tag.incncol(-1, nil, true) end,
            { description = "decrease the number of columns", group = "layout" }),
  awful.key({ modkey,           }, "space",   function() awful.layout.inc( 1) end,
            { description = "select next", group = "layout" }),
  awful.key({ modkey, "Shift"   }, "space",   function() awful.layout.inc(-1) end,
            { description = "select previous", group = "layout" }),

  awful.key({ modkey, "Control" }, "n",       function()
    local c = awful.client.restore()
    -- Focus restored client
    if c then
      c:emit_signal("request::activate", "key.unminimize", { raise = true })
    end
  end,      { description = "restore minimized", group = "client" }),

  -- Prompt
  awful.key({ modkey }, "r",      function() awful.screen.focused().mypromptbox:run() end,
            { description = "run prompt", group = "launcher" }),

  awful.key({ modkey }, "x",      function()
    awful.prompt.run {
      prompt       = "Run Lua code: ",
      textbox      = awful.screen.focused().mypromptbox.widget,
      exe_callback = awful.util.eval,
      history_path = gears.filesystem.get_cache_dir() .. "/history_eval"
    }
  end,      { description = "lua execute prompt", group = "awesome" }),

  -- Menubar
  awful.key({ modkey }, "p",      function() menubar.show() end,
            { description = "show the menubar", group = "launcher" }),

  -- User programs
  awful.key({ modkey }, "[",      function() awful.spawn(run_in_terminal(editor)) end,
            { description = "open a text editor", group = "launcher" }),
  awful.key({ modkey }, "]",      function() awful.spawn(file_manager) end,
            { description = "open a file manager", group = "launcher" }),
  awful.key({ modkey }, "\\",     function() awful.spawn(web_browser) end,
            { description = "open a web browser", group = "launcher" }),
  awful.key({ modkey }, "/",      function() awful.spawn(image_editor) end,
            { description = "open an image editor", group = "launcher" }),

  awful.key({},            "Print", function() take_screenshot(screenshot_mode.screen) end,
            { description = "capture a screen shot", group = "launcher" }),
  awful.key({ "Control" }, "Print", function() take_screenshot(screenshot_mode.curwin) end,
            { description = "capture a screen shot (current window)", group = "launcher" }),
  awful.key({ "Shift" },   "Print", function() take_screenshot(screenshot_mode.selection) end,
            { description = "capture a screen shot (selection mode)", group = "launcher" })
)

local clientkeys = gears.table.join(
  awful.key({ modkey,           }, "f",       function(c)
    c.fullscreen = not c.fullscreen
    c:raise()
  end,      { description = "toggle fullscreen", group = "client" }),
  awful.key({ modkey, "Shift"   }, "c",       function(c) c:kill() end,
            { description = "close", group = "client" }),
  awful.key({ modkey, "Control" }, "space",   awful.client.floating.toggle,
            { description = "toggle floating", group = "client" }),
  awful.key({ modkey, "Control" }, "Return",  function(c) c:swap(awful.client.getmaster()) end,
            { description = "move to master", group = "client" }),
  awful.key({ modkey,           }, "o",       function(c) c:move_to_screen() end,
            { description = "move to screen", group = "client" }),
  awful.key({ modkey, "Control" }, "s",       function(c) c.sticky = not c.sticky end,
            { description = "toggle sticky",  group = "client" }),
  awful.key({ modkey,           }, "t",       function(c) c.ontop = not c.ontop end,
            { description = "toggle keep on top", group = "client" }),
  awful.key({ modkey, "Shift"   }, "t",       function(c) awful.titlebar.toggle(c) end,
            { description = "toggle titlebar", group = "client" }),
  awful.key({ modkey,           }, "n",       function(c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
  end,      { description = "minimize", group = "client" }),
  awful.key({ modkey,           }, "m",       function(c)
    c.maximized = not c.maximized
    c:raise()
  end,      { description = "(un)maximize", group = "client" }),
  awful.key({ modkey, "Control" }, "m",       function (c)
    c.maximized_vertical = not c.maximized_vertical
    c:raise()
  end, { description = "(un)maximize vertically", group = "client" }),
  awful.key({ modkey, "Shift"   }, "m",       function (c)
    c.maximized_horizontal = not c.maximized_horizontal
    c:raise()
  end, { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 12 do
  globalkeys = gears.table.join(globalkeys,
    -- View tag only.
    awful.key({ modkey }, "#" .. i + 9, function()
      local screen = awful.screen.focused()
      local tag = screen.tags[i]
      if tag then
        tag:view_only()
      end
    end, { description = "view tag #"..i, group = "tag" }),
    -- Toggle tag display.
    awful.key({ modkey, "Control" }, "#" .. i + 9, function()
      local screen = awful.screen.focused()
      local tag = screen.tags[i]
      if tag then
        awful.tag.viewtoggle(tag)
      end
    end, { description = "toggle tag #" .. i, group = "tag" }),
    -- Move client to tag.
    awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
      if client.focus then
        local tag = client.focus.screen.tags[i]
        if tag then
          client.focus:move_to_tag(tag)
        end
      end
    end, { description = "move focused client to tag #"..i, group = "tag" }),
    -- Toggle tag on focused client.
    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
      if client.focus then
        local tag = client.focus.screen.tags[i]
        if tag then
          client.focus:toggle_tag(tag)
        end
      end
    end, { description = "toggle focused client on tag #" .. i, group = "tag" })
  )
end

local clientbuttons = gears.table.join(
  awful.button({},         1, function(c)
    c:emit_signal("request::activate", "mouse_click", { raise = true })
  end),
  awful.button({ modkey }, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", { raise = true })
    awful.mouse.client.move(c)
  end),
  awful.button({ modkey }, 3, function(c)
    c:emit_signal("request::activate", "mouse_click", { raise = true })
    awful.mouse.client.resize(c)
  end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = {},
    properties = {
      border_color = beautiful.border_normal,
      border_width = beautiful.border_width,
      buttons      = clientbuttons,
      focus        = awful.client.focus.filter,
      keys         = clientkeys,
      placement    = awful.placement.no_overlap + awful.placement.no_offscreen,
      raise        = true,
      screen       = awful.screen.preferred,
    }
  },

  -- Floating clients.
  {
    rule_any = {
      instance = {
        "DTA",  -- Firefox addon DownThemAll.
        "copyq",  -- Includes session name in class.
        "pinentry",
      },
      class = {
        "Blueman-manager",
        "Gnome-mplayer",
        "Kruler",
        "MPlayer",
        "MessageWin",  -- kalarm.
        "Sxiv",
        "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
        "Wpa_gui",
        "mpv",
        "veromix",
        "xtightvncviewer"
      },
      name = {
        "Event Tester",  -- xev.
      },
      role = {
        "AlarmWindow",  -- Thunderbird's calendar.
        "ConfigManager",  -- Thunderbird's about:config.
        "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
      }
    },
    properties = { floating = true }
  },

  -- Teminal enulators
  {
    rule_any = {
      class = {
        "Gvim",
        "Temite",
        "XTerm",
      },
    },
    properties = { size_hints_honor = false }
  },

  -- Set Gimp to always map on the tag named "7" on screen 1.
  {
    rule       = { class = "Gimp" },
    properties = { screen = 1, tag = "7" }
  },

  {
    rule       = { class = "Virt-manager" },
    except     = { name = "Virtual Machine Manager" },
    properties = { floating = true }
  },

  {
    rule       = { class = "Inkscape", type = "normal" },
    properties = { floating = false }
  },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
  -- Set the windows at the slave,
  -- i.e. put it at the end of others instead of setting it master.
  -- if not awesome.startup then awful.client.setslave(c) end

  if awesome.startup and
    not c.size_hints.user_position
    and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- buttons for the titlebar
  local buttons = gears.table.join(
    awful.button({}, 1, function()
      c:emit_signal("request::activate", "titlebar", { raise = true })
      awful.mouse.client.move(c)
    end),
    awful.button({}, 3, function()
      c:emit_signal("request::activate", "titlebar", { raise = true })
      awful.mouse.client.resize(c)
    end)
  )

  awful.titlebar(c, { size = beautiful.wibar_height }):setup {
    -- Left
    {
      awful.titlebar.widget.iconwidget(c),
      buttons = buttons,
      layout  = wibox.layout.fixed.horizontal
    },
    -- Middle
    {
      -- Title
      {
        align  = "center",
        widget = awful.titlebar.widget.titlewidget(c)
      },
      buttons = buttons,
      layout  = wibox.layout.flex.horizontal
    },
    -- Right
    {
      awful.titlebar.widget.floatingbutton (c),
      awful.titlebar.widget.maximizedbutton(c),
      awful.titlebar.widget.stickybutton   (c),
      awful.titlebar.widget.ontopbutton    (c),
      awful.titlebar.widget.closebutton    (c),
      layout = wibox.layout.fixed.horizontal()
    },
    layout = wibox.layout.align.horizontal
  }
end)

-- Show titlebar on floating window
client.connect_signal("property::floating", function(c)
  if c.floating then
    awful.titlebar.show(c)
  else
    awful.titlebar.hide(c)
  end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
  c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- vim:set foldmethod=marker:

-- {{{ Required Libraries
local awful         = require("awful")
                      require("awful.autofocus")
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")
local beautiful     = require("beautiful")
local gears         = require("gears")
local menubar       = require("menubar")
local naughty       = require("naughty")
local vicious       = require("vicious")
local wibox         = require("wibox")
--- }}}

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
beautiful.init(awful.util.getdir("config") .. "/theme.lua")

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
  awful.layout.suit.magnifier,
  -- awful.layout.suit.corner.nw,
  -- awful.layout.suit.corner.ne,
  -- awful.layout.suit.corner.sw,
  -- awful.layout.suit.corner.se,
}

local editor        = os.getenv("EDITOR") or "vim"
local file_manager  = "nautilus"
local image_editor  = "gimp"
local manual        = "man awesome"
local screen_shot   = "scrot -e 'mv $f ~/Pictures/ 2>/dev/null'"
local terminal      = "termite"
local web_browser   = "chromium"

local battery         = "BAT1"
local thermal_zone    = "thermal_zone0"
local wifi_interface  = "wlp2s0"
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
  local instance = nil

  return function()
    if instance and instance.wibox.visible then
      instance:hide()
      instance = nil
    else
      instance = awful.menu.clients({ theme = { width = 250 } })
    end
  end
end

local function markup(color, text)
  return "<span foreground=\"" .. tostring(color) .. "\">" .. tostring(text) .. "</span>"
end

local function run_in_terminal(command)
  return terminal .. " -e '" .. tostring(command) .. "'"
end

local function set_wallpaper(s)
  -- Wallpaper
  if beautiful.wallpaper then
    local wallpaper = beautiful.wallpaper
    -- If wallpaper is a function, call it with the screen
    if type(wallpaper) == "function" then
      wallpaper = wallpaper(s)
    end
    gears.wallpaper.centered(wallpaper, s)
  end
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
local mymainmenu = awful.menu({
  items = {
    { "awesome", {
      { "hotkeys",      function() return false, hotkeys_popup.show_help end },
      { "manual",       run_in_terminal(manual) },
      { "edit config",  run_in_terminal(editor .. " " .. awesome.conffile) },
      { "restart",      awesome.restart },
    }, beautiful.awesome_icon },
    { "logout",   function() awesome.quit() end},
    { "lock",     "light-locker-command -l"},
    { "suspend",  "systemctl suspend" },
    { "reboot",   "systemctl reboot" },
    { "halt",     "systemctl poweroff" }
  }
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Widgets {{{
-- color
local red    = "#e81c4f"
local yellow = "#ffe100"
local gray   = "#9699a0"

local mywidgets = {}

-- Separator
mywidgets.separator = wibox.widget.textbox(markup(gray, " | "))

-- clock
mywidgets.clock = wibox.widget.textclock("%a, %b %d, %H:%M ")

-- calendar
mywidgets.calendar = awful.widget.calendar_popup.month({ start_sunday = true });
mywidgets.calendar:attach(mywidgets.clock)

-- battery
mywidgets.battery = wibox.widget.textbox()
vicious.register(mywidgets.battery, vicious.widgets.bat, function(widget, args)
  local level = args[2]
  local state = args[1]
  local value = tostring(level) .. "%"

  if level <= 15 then
    value = markup(red, value)
  elseif level <= 30 then
    value = markup(yellow, value)
  end

  if state == "⌁" or state == "↯" or state == "+" then
    value = value .. " AC"
  end

  return markup(gray, "Bat ") .. value
end, 60, battery)

-- temp
mywidgets.cputemp = wibox.widget.textbox()
vicious.register(mywidgets.cputemp, vicious.widgets.thermal, function(widget, args)
  local cputemp = args[1]
  local value   = tostring(cputemp) .. "°C"

  if cputemp >= 80 then
    value =  markup(red, value)
  elseif cputemp >= 70 then
    value =  markup(yellow, value)
  end

  return markup(gray, "CPU ") .. value
end, 7, thermal_zone)

-- memory
mywidgets.memory = wibox.widget.textbox()
vicious.register(mywidgets.memory, vicious.widgets.mem,
                 markup(gray, "Mem ") .. "$1%", 37)

-- wifi
mywidgets.wifi = wibox.widget.textbox()
vicious.register(mywidgets.wifi, vicious.widgets.wifi,
                 markup(gray, "Wifi ") .. "${ssid} ${linp}%", 17, wifi_interface)

-- volume
mywidgets.volume = wibox.widget.textbox()
vicious.register(mywidgets.volume, vicious.widgets.volume, function(widget, args)
  local level = args[1]
  local state = args[2]
  local label = { ["♫"] = "", ["♩"] = " [Muted]" }
  return markup(gray, "Vol ") .. level .. "%" .. label[state]
end, 123, "Master")
-- }}}

-- {{{ Wibar
-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
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

local tasklist_buttons = awful.util.table.join(
  awful.button({},         1, function(c)
    if c == client.focus then
      c.minimized = true
    else
      -- Without this, the following
      -- :isvisible() makes no sense
      c.minimized = false
      if not c:isvisible() and c.first_tag then
        c.first_tag:view_only()
      end
      -- This will also un-minimize
      -- the client, if needed
      client.focus = c
      c:raise()
    end
  end),
  awful.button({},         3, client_menu_toggle_fn()),
  awful.button({},         4, function() awful.client.focus.byidx( 1) end),
  awful.button({},         5, function() awful.client.focus.byidx(-1) end)
)

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

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
  s.mylayoutbox:buttons(awful.util.table.join(
    awful.button({}, 1, function() awful.layout.inc( 1) end),
    awful.button({}, 3, function() awful.layout.inc(-1) end),
    awful.button({}, 4, function() awful.layout.inc( 1) end),
    awful.button({}, 5, function() awful.layout.inc(-1) end)
  ))

  -- Create a taglist widget
  s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

  -- Create a tasklist widget
  s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

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
    {
      layout = wibox.layout.fixed.horizontal,
      wibox.widget.systray(),
      mywidgets.separator,
      mywidgets.wifi,
      mywidgets.separator,
      mywidgets.cputemp,
      mywidgets.separator,
      mywidgets.memory,
      mywidgets.separator,
      mywidgets.battery,
      mywidgets.separator,
      mywidgets.volume,
      mywidgets.separator,
      mywidgets.clock,
      s.mylayoutbox,
    },
  }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
  awful.button({}, 3, function() mymainmenu:toggle() end),
  awful.button({}, 4, awful.tag.viewnext),
  awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
local globalkeys = awful.util.table.join(
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
      client.focus = c
      c:raise()
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
      history_path = awful.util.get_cache_dir() .. "/history_eval"
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
  awful.key({},         "Print",  function() awful.spawn(screen_shot) end,
            { description = "capture a screen shot", group = "launcher" })
)

local clientkeys = awful.util.table.join(
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
  awful.key({ modkey,           }, "n",       function(c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
  end,      { description = "minimize", group = "client" }),
  awful.key({ modkey,           }, "m",       function(c)
    c.maximized = not c.maximized
    c:raise()
  end,      { description = "maximize", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 12 do
  globalkeys = awful.util.table.join(globalkeys,
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

local clientbuttons = awful.util.table.join(
  awful.button({},         1, function(c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize)
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
      class = {
        "Gnome-mplayer",
        "MPlayer",
        "mpv",
      },
      name = {
        "Event Tester",  -- xev.
      },
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

  -- Add titlebars to normal clients and dialogs
  {
    rule_any = {
      type = { "normal", "dialog" }
    },
    properties = { titlebars_enabled = true }
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
  local buttons = awful.util.table.join(
    awful.button({}, 1, function()
      client.focus = c
      c:raise()
      awful.mouse.client.move(c)
    end),
    awful.button({}, 3, function()
      client.focus = c
      c:raise()
      awful.mouse.client.resize(c)
    end)
  )

  awful.titlebar(c):setup {
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

  -- Hide the titlebar if the client is not floating
  if not c.floating then
    awful.titlebar.hide(c)
  end
end)

-- Toggle titlebar
client.connect_signal("property::floating", function(c)
  if c.floating then
    awful.titlebar.show(c)
  else
    awful.titlebar.hide(c)
  end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
  if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
    and awful.client.focus.filter(c) then
    client.focus = c
  end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- vim:set foldmethod=marker:

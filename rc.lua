-- {{{ Required Libraries
local gears           = require('gears')
local awful           = require('awful')
      awful.rules     = require('awful.rules')
                        require('awful.autofocus')
local wibox           = require('wibox')
local beautiful       = require('beautiful')
local naughty         = require('naughty')
local menubar         = require('menubar')
local vicious         = require('vicious')
--- }}}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({
    preset  = naughty.config.presets.critical,
    title   = 'Oops, there were errors during startup!',
    text    = awesome.startup_errors
  })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal('debug::error', function(err)
    -- Make sure we don't go into an endless error loop
    if in_error then return end
    in_error = true

    naughty.notify({
      preset  = naughty.config.presets.critical,
      title   = 'Oops, an error happened!',
      text    = tostring(err)
    })

    in_error = false
  end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir('config') .. '/theme.lua')

-- This is used later as the default terminal and editor to run.
local terminal = 'termite'

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = 'Mod4'

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts = {
  awful.layout.suit.floating,
  awful.layout.suit.tile
}
-- }}}

-- {{{ Wallpaper
for s = 1, screen.count() do
  local wallpaper = beautiful.wallpaper
  if screen[s].workarea.height > screen[s].workarea.width then
    wallpaper = beautiful.wallpaper_vertical
  end
  gears.wallpaper.centered(wallpaper, s)
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
local tags = {}
for s = 1, screen.count() do
  -- Each screen has its own tag table.
  tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[2])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
local mymainmenu = awful.menu({
  items = {
    { 'awesome', { { 'restart', awesome.restart } } , beautiful.awesome_icon },
    { 'logout',   awesome.quit },
    { 'suspend',  'systemctl suspend' },
    { 'reboot',   'systemctl reboot' },
    { 'halt',     'systemctl poweroff' }
  }
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Widgets {{{
-- color
local red    = '#ff3000'
local yellow = '#ffe100'
local gray   = '#777777'
local function markup(color, text)
  return '<span foreground="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end

-- Separator
local separator = wibox.widget.textbox()
separator:set_markup(markup(gray, ' | '))

-- clock
local mytextclock = awful.widget.textclock('%a, %b %d, %H:%M ', 60)

-- battery
local battery = wibox.widget.textbox()
vicious.register(battery, vicious.widgets.bat, function(widgets, args)
  local value = tostring(args[2]) .. '%'

  if args[2] <= 15 then
    value = markup(red, value)
  elseif args[2] <= 30 then
    value = markup(yellow, value)
  end

  if args[1] == '⌁' or args[1] == '↯' or args[1] == '+' then
    value = value .. ' AC'
  end

  return markup(gray, 'Bat ') .. value
end, 60, 'BAT1')

-- temp
local coretemp = wibox.widget.textbox()
vicious.register(coretemp, vicious.widgets.thermal, function(widget, args)
  local value = tostring(args[1]) .. '°C'

  if args[1] >= 80 then
    value =  markup(red, value)
  elseif args[1] >= 70 then
    value =  markup(yellow, value)
  end

  return markup(gray, 'CPU ') .. value
end, 7, 'thermal_zone0')

-- memory
local memwidget = wibox.widget.textbox()
vicious.register(memwidget, vicious.widgets.mem, markup(gray, 'Mem ') .. '$1%', 37)

-- wifi
local wifi = wibox.widget.textbox()
vicious.register(wifi, vicious.widgets.wifi, markup(gray, 'Wifi ') .. '${ssid} ${linp}%', 17, 'wlp2s0')

-- volume
local volume = wibox.widget.textbox()
vicious.register(volume, vicious.widgets.volume, function(widget, args)
  local value = tostring(args[1]) .. '%'

  if args[2] == '♩' then
    value = value .. ' [Muted]'
  end

  return markup(gray, 'Vol ') .. value
end, 123, 'Master')
-- }}}

-- {{{ Wibox
-- Create a wibox for each screen and add it
local mywibox = {}
local mypromptbox = {}
local mylayoutbox = {}
local mytaglist = {}
mytaglist.buttons = awful.util.table.join(
  awful.button({}, 1, awful.tag.viewonly),
  awful.button({ modkey }, 1, awful.client.movetotag),
  awful.button({}, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, awful.client.toggletag),
  awful.button({}, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
  awful.button({}, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
)
local mytasklist = {}
mytasklist.buttons = awful.util.table.join(
  awful.button({}, 1, function(c)
    if c == client.focus then
      c.minimized = true
    else
      -- Without this, the following
      -- :isvisible() makes no sense
      c.minimized = false
      if not c:isvisible() then
        awful.tag.viewonly(c:tags()[1])
      end
      -- This will also un-minimize
      -- the client, if needed
      client.focus = c
      c:raise()
    end
  end),
  awful.button({}, 3, function()
    if instance then
      instance:hide()
      instance = nil
    else
      instance = awful.menu.clients({ width = 250 })
    end
  end),
  awful.button({}, 4, function()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
  end),
  awful.button({}, 5, function()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
  end)
)

for s = 1, screen.count() do
  -- Create a promptbox for each screen
  mypromptbox[s] = awful.widget.prompt()
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  mylayoutbox[s] = awful.widget.layoutbox(s)
  mylayoutbox[s]:buttons(awful.util.table.join(
    awful.button({}, 1, function() awful.layout.inc(layouts, 1) end),
    awful.button({}, 3, function() awful.layout.inc(layouts, -1) end),
    awful.button({}, 4, function() awful.layout.inc(layouts, 1) end),
    awful.button({}, 5, function() awful.layout.inc(layouts, -1) end)
  ))
  -- Create a taglist widget
  mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

  -- Create a tasklist widget
  mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

  -- Create the wibox
  mywibox[s] = awful.wibox({ position = 'top', screen = s })

  -- Widgets that are aligned to the left
  local left_layout = wibox.layout.fixed.horizontal()
  left_layout:add(mytaglist[s])
  left_layout:add(mypromptbox[s])

  -- Widgets that are aligned to the right
  local right_layout = wibox.layout.fixed.horizontal()
  if s == 1 then
    right_layout:add(wibox.widget.systray())
    right_layout:add(separator)
    right_layout:add(wifi)
    right_layout:add(separator)
    right_layout:add(coretemp)
    right_layout:add(separator)
    right_layout:add(memwidget)
    right_layout:add(separator)
    right_layout:add(battery)
    right_layout:add(separator)
    right_layout:add(volume)
  end
  right_layout:add(separator)
  right_layout:add(mytextclock)
  right_layout:add(mylayoutbox[s])

  -- Now bring it all together (with the tasklist in the middle)
  local layout = wibox.layout.align.horizontal()
  layout:set_left(left_layout)
  layout:set_middle(mytasklist[s])
  layout:set_right(right_layout)

  mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Key bindings
local globalkeys = awful.util.table.join(
  awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
            { description = "view previous", group = "tag" }),
  awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
            { description = "view next", group = "tag" }),
  awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
            { description = "go back", group = "tag" }),

  awful.key({ modkey,           }, "j",
    function ()
      awful.client.focus.byidx( 1)
    end,
    { description = "focus next by index", group = "client" }),
  awful.key({ modkey,           }, "k",
    function ()
      awful.client.focus.byidx(-1)
    end,
    { description = "focus previous by index", group = "client" }),
  awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
            { description = "show main menu", group = "awesome" }),

  -- Layout manipulation
  awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
            { description = "swap with next client by index", group = "client" }),
  awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
            { description = "swap with previous client by index", group = "client" }),
  awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
            { description = "focus the next screen", group = "screen" }),
  awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
            { description = "focus the previous screen", group = "screen" }),
  awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
            { description = "jump to urgent client", group = "client" }),
  awful.key({ modkey,           }, "Tab",
    function ()
      awful.client.focus.history.previous()
      if client.focus then
        client.focus:raise()
      end
    end,
    { description = "go back", group = "client" }),

  -- Standard program
  awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
            { description = "open a terminal", group = "launcher" }),
  awful.key({ modkey, "Control" }, "r", awesome.restart,
            { description = "reload awesome", group = "awesome" }),
  awful.key({ modkey, "Shift"   }, "q", awesome.quit,
            { description = "quit awesome", group = "awesome" }),

  awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.02)          end,
            { description = "increase master width factor", group = "layout" }),
  awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.02)          end,
            { description = "decrease master width factor", group = "layout" }),
  awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
            { description = "increase the number of master clients", group = "layout" }),
  awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
            { description = "decrease the number of master clients", group = "layout" }),
  awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
            { description = "increase the number of columns", group = "layout" }),
  awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
            { description = "decrease the number of columns", group = "layout" }),
  awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
            { description = "select next", group = "layout" }),
  awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
            { description = "select previous", group = "layout" }),

  awful.key({ modkey, "Control" }, "n",
    function ()
      local c = awful.client.restore()
      -- Focus restored client
      if c then
        client.focus = c
        c:raise()
      end
    end,
    { description = "restore minimized", group = "client" }),

  -- Prompt
  awful.key({ modkey },            "r",
    function ()
      awful.screen.focused().mypromptbox:run()
    end,
    { description = "run prompt", group = "launcher" }),

  awful.key({ modkey }, "x",
    function ()
      awful.prompt.run {
        prompt       = "Run Lua code: ",
        textbox      = awful.screen.focused().mypromptbox.widget,
        exe_callback = awful.util.eval,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
      }
    end,
    { description = "lua execute prompt", group = "awesome" }),

  -- Menubar
  awful.key({ modkey }, "p", function() menubar.show() end,
            { description = "show the menubar", group = "launcher" }),

  -- User programs
  awful.key({ modkey }, ']',     function() awful.util.spawn('nautilus') end),
  awful.key({ modkey }, '\\',    function() awful.util.spawn('chromium') end),
  awful.key({ modkey }, '/',     function() awful.util.spawn('gimp') end),
  awful.key({},         'Print', function() awful.util.spawn('scrot -e "mv $f ~/Pictures/ 2>/dev/null"') end)
)

local clientkeys = awful.util.table.join(
  awful.key({ modkey,           }, "f",
    function (c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    { description = "toggle fullscreen", group = "client" }),
  awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
            { description = "close", group = "client" }),
  awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
            { description = "toggle floating", group = "client" }),
  awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
            { description = "move to master", group = "client" }),
  awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
            { description = "move to screen", group = "client" }),
  awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
            { description = "toggle keep on top", group = "client" }),
  awful.key({ modkey,           }, "n",
    function (c)
      -- The client currently has the input focus, so it cannot be
      -- minimized, since minimized clients can't have the focus.
      c.minimized = true
    end ,
    { description = "minimize", group = "client" }),
  awful.key({ modkey,           }, "m",
    function (c)
      c.maximized = not c.maximized
      c:raise()
    end ,
    { description = "maximize", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  globalkeys = awful.util.table.join(globalkeys,
    -- View tag only.
    awful.key({ modkey }, "#" .. i + 9, function ()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          tag:view_only()
        end
      end,
      { description = "view tag #"..i, group = "tag" }),
    -- Toggle tag display.
    awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          awful.tag.viewtoggle(tag)
        end
      end,
      { description = "toggle tag #" .. i, group = "tag" }),
    -- Move client to tag.
    awful.key({ modkey, "Shift" }, "#" .. i + 9, function ()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:move_to_tag(tag)
          end
        end
      end,
      { description = "move focused client to tag #"..i, group = "tag" }),
    -- Toggle tag on focused client.
    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function ()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:toggle_tag(tag)
          end
        end
      end,
      { description = "toggle focused client on tag #" .. i, group = "tag" })
  )
end

local clientbuttons = awful.util.table.join(
  awful.button({}, 1, function(c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {{
  -- All clients will match this rule.
  rule = {}, properties = {
    border_color = beautiful.border_normal,
    border_width = beautiful.border_width,
    buttons      = clientbuttons,
    focus        = awful.client.focus.filter,
    keys         = clientkeys,
  }}, {
    rule       = { class = 'Gimp' },
    properties = { tag = tags[1][7] }
  }, {
    rule       = { class = 'MPlayer' },
    properties = { floating = true }
  }, {
    rule       = { class = 'Virt-manager' },
    properties = { floating = true }
  },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal('manage', function(c, startup)
  -- Enable sloppy focus
  c:connect_signal('mouse::enter', function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
      and awful.client.focus.filter(c) then
      client.focus = c
    end
  end)

  if not startup then
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- awful.client.setslave(c)

    -- Put windows in a smart way, only if they does not set an initial position.
    if not c.size_hints.user_position and not c.size_hints.program_position then
      awful.placement.no_overlap(c)
      awful.placement.no_offscreen(c)
    end
  end

  local titlebars_enabled = false
  if titlebars_enabled and (c.type == 'normal' or c.type == 'dialog') then
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

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(awful.titlebar.widget.iconwidget(c))
    left_layout:buttons(buttons)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(awful.titlebar.widget.floatingbutton(c))
    right_layout:add(awful.titlebar.widget.maximizedbutton(c))
    right_layout:add(awful.titlebar.widget.stickybutton(c))
    right_layout:add(awful.titlebar.widget.ontopbutton(c))
    right_layout:add(awful.titlebar.widget.closebutton(c))

    -- The title goes in the middle
    local middle_layout = wibox.layout.flex.horizontal()
    local title = awful.titlebar.widget.titlewidget(c)
    title:set_align('center')
    middle_layout:add(title)
    middle_layout:buttons(buttons)

    -- Now bring it all together
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)
    layout:set_middle(middle_layout)

    awful.titlebar(c):set_widget(layout)
  end
end)

client.connect_signal('focus', function(c) c.border_color = beautiful.border_focus end)
client.connect_signal('unfocus', function(c) c.border_color = beautiful.border_normal end)
-- }}}

local filesystem    = require("gears.filesystem")
local theme_assets  = require("beautiful.theme_assets")
local xresources    = require("beautiful.xresources")

local dpi = xresources.apply_dpi

-- inherit default theme
local theme = dofile(filesystem.get_themes_dir() .. "default/theme.lua")

-- default fonts
local defult_font = "sans-serif medium"
local defult_font_mono = "monospace medium"

local function font(name, size)
  return string.format("%s %d", name, size)
end

-- colors
local bg = "#2f343f"
local fg = "#e6e6e6"
local dark_fg = "#898f9b"
local red = "#e06c75"
local blue = "#5294e2"
local light_gray = "#4c5466"
local mid_gray = "#3f424e"
local dark_gray = "#262a33"

-- main
theme.font = font(defult_font, 11)

theme.bg_normal     = bg
theme.bg_focus      = light_gray
theme.bg_urgent     = red
theme.bg_minimize   = mid_gray
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = fg
theme.fg_focus      = theme.fg_normal
theme.fg_urgent     = fg
theme.fg_minimize   = dark_fg

theme.border_normal = dark_gray
theme.border_focus  = theme.bg_focus
theme.border_marked = theme.border_focus

-- notifications
theme.notification_font = font(defult_font, 10)
theme.notification_width = dpi(448)
theme.notification_icon_size = dpi(64)

-- menu
theme.menu_font = font(defult_font, 9)
theme.menu_height = dpi(18)

-- wibar
theme.wibar_height = dpi(20)
theme.wibar_separator_width = dpi(10)

-- 	hotkeys widget
theme.hotkeys_font = font(defult_font_mono, 10)
theme.hotkeys_bg = bg
theme.hotkeys_fg = fg
theme.hotkeys_modifiers_fg = dark_fg
theme.hotkeys_border_color = dark_gray

-- tag list
theme.taglist_bg_focus    = blue
theme.taglist_fg_empty    = dark_fg
theme.taglist_fg_occupied = theme.taglist_fg_empty

local taglist_square_size = dpi(5)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
  taglist_square_size, fg
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
  taglist_square_size, dark_fg
)

-- systray
theme.systray_icon_spacing = dpi(2)

-- wallpaper
local wallpaper = os.getenv("HOME") .. "/Pictures/wall.png"
if filesystem.file_readable(wallpaper) then
  theme.wallpaper = wallpaper
end

return theme
-- vim:set foldmethod=marker:

local filesystem    = require("gears.filesystem")
local theme_assets  = require("beautiful.theme_assets")
local xresources    = require("beautiful.xresources")

-- inherit default theme
local theme = dofile(filesystem.get_themes_dir() .. "default/theme.lua")

-- fonts
theme.font              = "xos4 Terminus 8"
theme.notification_font = "Sans 9"

-- colors
theme.bg_normal     = "#131619"
theme.bg_focus      = "#444448"
theme.bg_urgent     = "#e81c4f"
theme.bg_minimize   = "#292f33"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#e6e6e6"
theme.fg_focus      = "#ffffff"
theme.fg_urgent     = "#ffffff"
theme.fg_minimize   = theme.fg_normal

theme.border_normal = "#222426"
theme.border_focus  = "#222426"
theme.border_marked = "#222426"

-- Generate taglist squares:
local taglist_square_size = xresources.apply_dpi(5)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
  taglist_square_size, theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
  taglist_square_size, theme.fg_normal
)

theme.systray_icon_spacing = xresources.apply_dpi(2)

local wallpaper = os.getenv("HOME") .. "/Pictures/wall.png"
if filesystem.file_readable(wallpaper) then
  theme.wallpaper = wallpaper
end

return theme
-- vim:set foldmethod=marker:
